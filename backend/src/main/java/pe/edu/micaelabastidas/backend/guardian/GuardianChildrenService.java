package pe.edu.micaelabastidas.backend.guardian;

import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class GuardianChildrenService {
    private final JdbcTemplate jdbc;
    private final GuardianAccess access;

    public GuardianChildrenService(JdbcTemplate jdbc, GuardianAccess access) {
        this.jdbc = jdbc;
        this.access = access;
    }

    /** Hijo vinculado con su matrícula más reciente (los datos de matrícula pueden ser nulos). */
    public record Child(long id, String nombres, String apellidos, String codigoEstudiante,
            String parentesco, boolean contactoPrincipal, Long matriculaId, String estado,
            String periodo, String nivel, String grado, String seccion) {}

    public List<Child> children(long usuarioId) {
        long guardianId = access.guardianId(usuarioId);
        return jdbc.query("""
                SELECT e.id, u.nombres, u.apellidos, e.codigo_estudiante,
                       ea.parentesco, ea.contacto_principal,
                       m.id AS matricula_id, m.estado, p.nombre AS periodo,
                       g.nivel, g.nombre AS grado, s.nombre AS seccion
                FROM estudiante_apoderado ea
                JOIN estudiante e ON e.id = ea.estudiante_id
                JOIN usuario u ON u.id = e.usuario_id AND u.activo = TRUE
                LEFT JOIN matricula m ON m.id = (
                    SELECT m2.id FROM matricula m2
                    JOIN periodo_academico p2 ON p2.id = m2.periodo_academico_id
                    WHERE m2.estudiante_id = e.id
                    ORDER BY p2.fecha_inicio DESC, m2.id DESC
                    LIMIT 1)
                LEFT JOIN periodo_academico p ON p.id = m.periodo_academico_id
                LEFT JOIN seccion s ON s.id = m.seccion_id
                LEFT JOIN grado g ON g.id = s.grado_id
                WHERE ea.apoderado_id = ?
                ORDER BY u.apellidos, u.nombres
                """, (rs, row) -> new Child(rs.getLong("id"), rs.getString("nombres"),
                rs.getString("apellidos"), rs.getString("codigo_estudiante"),
                rs.getString("parentesco"), rs.getBoolean("contacto_principal"),
                rs.getObject("matricula_id", Long.class), rs.getString("estado"),
                rs.getString("periodo"), rs.getString("nivel"), rs.getString("grado"),
                rs.getString("seccion")), guardianId);
    }
}
