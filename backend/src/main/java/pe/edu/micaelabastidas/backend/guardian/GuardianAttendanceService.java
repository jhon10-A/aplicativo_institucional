package pe.edu.micaelabastidas.backend.guardian;

import java.time.LocalDate;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class GuardianAttendanceService {
    private final JdbcTemplate jdbc;
    private final GuardianAccess access;

    public GuardianAttendanceService(JdbcTemplate jdbc, GuardianAccess access) {
        this.jdbc = jdbc;
        this.access = access;
    }

    /** Registro de asistencia de un curso. La fecha va como texto ISO (aaaa-mm-dd). */
    public record Attendance(long id, String fecha, String periodo, String curso, String estado,
            String observacion) {}

    public List<Attendance> attendance(long usuarioId, long estudianteId) {
        access.requireChild(usuarioId, estudianteId);
        return jdbc.query("""
                SELECT a.id, a.fecha, p.nombre AS periodo, cu.nombre AS curso,
                       a.estado, a.observacion
                FROM asistencia a
                JOIN matricula m ON m.id = a.matricula_id
                JOIN periodo_academico p ON p.id = a.periodo_academico_id
                JOIN asignacion_docente ad ON ad.id = a.asignacion_docente_id
                JOIN curso cu ON cu.id = ad.curso_id
                WHERE m.estudiante_id = ?
                ORDER BY a.fecha DESC, cu.nombre, a.id DESC
                LIMIT 200
                """, (rs, row) -> new Attendance(rs.getLong("id"),
                rs.getObject("fecha", LocalDate.class).toString(), rs.getString("periodo"),
                rs.getString("curso"), rs.getString("estado"), rs.getString("observacion")),
                estudianteId);
    }
}
