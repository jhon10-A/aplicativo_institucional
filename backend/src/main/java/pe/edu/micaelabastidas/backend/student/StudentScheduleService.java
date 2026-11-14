package pe.edu.micaelabastidas.backend.student;

import java.sql.Time;
import java.time.LocalTime;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class StudentScheduleService {
    private final JdbcTemplate jdbc;
    private final StudentProfileService profiles;

    public StudentScheduleService(JdbcTemplate jdbc, StudentProfileService profiles) {
        this.jdbc = jdbc;
        this.profiles = profiles;
    }

    public record Schedule(
            long id,
            long matriculaId,
            long asignacionId,
            long cursoId,
            String curso,
            String docente,
            long periodoId,
            String periodo,
            String nivel,
            String grado,
            String seccion,
            int diaSemana,
            LocalTime horaInicio,
            LocalTime horaFin,
            String aula) {}

    public static class MissingSchedule extends RuntimeException {}

    private static final String SELECT = """
            SELECT h.id, m.id AS matricula_id, a.id AS asignacion_id,
                   c.id AS curso_id, c.nombre AS curso,
                   du.nombres, du.apellidos,
                   p.id AS periodo_id, p.nombre AS periodo,
                   g.nivel, g.nombre AS grado, s.nombre AS seccion,
                   h.dia_semana, h.hora_inicio, h.hora_fin, h.aula
            FROM matricula m
            JOIN estudiante e ON e.id = m.estudiante_id
            JOIN usuario u ON u.id = e.usuario_id
            JOIN periodo_academico p ON p.id = m.periodo_academico_id
            JOIN seccion s ON s.id = m.seccion_id
            JOIN grado g ON g.id = s.grado_id
            JOIN asignacion_docente a
              ON a.periodo_academico_id = m.periodo_academico_id
             AND a.seccion_id = m.seccion_id
            JOIN horario_clase h ON h.asignacion_docente_id = a.id
            JOIN curso c ON c.id = a.curso_id
            JOIN docente d ON d.id = a.docente_id
            JOIN usuario du ON du.id = d.usuario_id
            WHERE e.usuario_id = ? AND u.activo = TRUE AND m.id = ?
            ORDER BY h.dia_semana, h.hora_inicio, h.id
            """;

    public List<Schedule> schedule(long usuarioId, long matriculaId) {
        profiles.profile(usuarioId);
        Long enrollmentCount = jdbc.queryForObject("""
                SELECT COUNT(*)
                FROM matricula m
                JOIN estudiante e ON e.id = m.estudiante_id
                WHERE e.usuario_id = ? AND m.id = ?
                """, Long.class, usuarioId, matriculaId);
        if (enrollmentCount == null || enrollmentCount == 0) {
            throw new MissingSchedule();
        }

        return jdbc.query(SELECT, (rs, row) -> new Schedule(
                rs.getLong("id"),
                rs.getLong("matricula_id"),
                rs.getLong("asignacion_id"),
                rs.getLong("curso_id"),
                rs.getString("curso"),
                rs.getString("nombres") + " " + rs.getString("apellidos"),
                rs.getLong("periodo_id"),
                rs.getString("periodo"),
                rs.getString("nivel"),
                rs.getString("grado"),
                rs.getString("seccion"),
                rs.getInt("dia_semana"),
                localTime(rs.getTime("hora_inicio")),
                localTime(rs.getTime("hora_fin")),
                rs.getString("aula")), usuarioId, matriculaId);
    }

    private LocalTime localTime(Time time) {
        return time == null ? null : time.toLocalTime();
    }
}
