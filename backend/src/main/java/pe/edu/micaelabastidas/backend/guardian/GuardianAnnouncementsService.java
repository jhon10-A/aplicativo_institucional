package pe.edu.micaelabastidas.backend.guardian;

import java.time.LocalDateTime;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class GuardianAnnouncementsService {
    private final JdbcTemplate jdbc;
    private final GuardianAccess access;

    public GuardianAnnouncementsService(JdbcTemplate jdbc, GuardianAccess access) {
        this.jdbc = jdbc;
        this.access = access;
    }

    /** Comunicado visible para el apoderado. La fecha va como texto ISO (aaaa-mm-dd). */
    public record Announcement(long id, String titulo, String contenido, String autor,
            String fecha) {}

    /**
     * Comunicados activos y vigentes dirigidos a todos, al rol APODERADO o a la
     * sección de alguno de sus hijos con matrícula activa.
     */
    public List<Announcement> announcements(long usuarioId) {
        long guardianId = access.guardianId(usuarioId);
        return jdbc.query("""
                SELECT c.id, c.titulo, c.contenido, c.publicado_en,
                       au.nombres AS autor_nombres, au.apellidos AS autor_apellidos
                FROM comunicado c
                JOIN usuario au ON au.id = c.autor_id
                WHERE c.activo = TRUE
                  AND (c.fecha_vencimiento IS NULL OR c.fecha_vencimiento > NOW())
                  AND (c.rol_destino_id IS NULL
                       OR c.rol_destino_id = (SELECT id FROM rol WHERE nombre = 'APODERADO'))
                  AND (c.seccion_destino_id IS NULL
                       OR c.seccion_destino_id IN (
                           SELECT m.seccion_id
                           FROM matricula m
                           JOIN estudiante_apoderado ea ON ea.estudiante_id = m.estudiante_id
                           WHERE ea.apoderado_id = ? AND m.estado = 'ACTIVA'))
                ORDER BY c.publicado_en DESC, c.id DESC
                LIMIT 100
                """, (rs, row) -> new Announcement(rs.getLong("id"), rs.getString("titulo"),
                rs.getString("contenido"),
                rs.getString("autor_nombres") + " " + rs.getString("autor_apellidos"),
                rs.getObject("publicado_en", LocalDateTime.class).toLocalDate().toString()),
                guardianId);
    }
}
