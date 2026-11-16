package pe.edu.micaelabastidas.backend.guardian;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class GuardianGradesService {
    private final JdbcTemplate jdbc;
    private final GuardianAccess access;

    public GuardianGradesService(JdbcTemplate jdbc, GuardianAccess access) {
        this.jdbc = jdbc;
        this.access = access;
    }

    /** Nota registrada por un docente. La fecha va como texto ISO (aaaa-mm-dd). */
    public record Grade(long id, String periodo, String curso, String docente, String etapa,
            String concepto, BigDecimal nota, String observacion, String fecha) {}

    public List<Grade> grades(long usuarioId, long estudianteId) {
        access.requireChild(usuarioId, estudianteId);
        return jdbc.query("""
                SELECT c.id, p.nombre AS periodo, cu.nombre AS curso,
                       du.nombres AS docente_nombres, du.apellidos AS docente_apellidos,
                       c.etapa, c.concepto, c.nota, c.observacion, c.registrado_en
                FROM calificacion c
                JOIN matricula m ON m.id = c.matricula_id
                JOIN periodo_academico p ON p.id = c.periodo_academico_id
                JOIN asignacion_docente ad ON ad.id = c.asignacion_docente_id
                JOIN curso cu ON cu.id = ad.curso_id
                JOIN docente d ON d.id = ad.docente_id
                JOIN usuario du ON du.id = d.usuario_id
                WHERE m.estudiante_id = ?
                ORDER BY p.fecha_inicio DESC, cu.nombre, c.registrado_en DESC, c.id DESC
                """, (rs, row) -> new Grade(rs.getLong("id"), rs.getString("periodo"),
                rs.getString("curso"),
                rs.getString("docente_nombres") + " " + rs.getString("docente_apellidos"),
                rs.getString("etapa"), rs.getString("concepto"), rs.getBigDecimal("nota"),
                rs.getString("observacion"),
                rs.getObject("registrado_en", LocalDateTime.class).toLocalDate().toString()),
                estudianteId);
    }
}
