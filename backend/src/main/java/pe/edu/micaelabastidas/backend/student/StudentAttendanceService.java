package pe.edu.micaelabastidas.backend.student;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class StudentAttendanceService {
    private final JdbcTemplate jdbc;
    private final StudentProfileService profiles;
    private final StudentCourseService courses;

    public StudentAttendanceService(JdbcTemplate jdbc, StudentProfileService profiles, StudentCourseService courses) {
        this.jdbc = jdbc;
        this.profiles = profiles;
        this.courses = courses;
    }

    public record Attendance(long id, long matriculaId, long asignacionId, long cursoId, String curso,
            String docente, long periodoId, String periodo, String nivel, String grado, String seccion,
            LocalDate fecha, String estado, String observacion, LocalDateTime registradoEn) {}
    public static class MissingAttendance extends RuntimeException {}

    private static final String SELECT = """
            SELECT n.id, m.id AS matricula_id, a.id AS asignacion_id, c.id AS curso_id,
                   c.nombre AS curso, du.nombres, du.apellidos, p.id AS periodo_id, p.nombre AS periodo,
                   g.nivel, g.nombre AS grado, s.nombre AS seccion,
                   n.fecha, n.estado, n.observacion, n.registrado_en
            FROM asistencia n
            JOIN matricula m ON m.id = n.matricula_id AND m.periodo_academico_id = n.periodo_academico_id
                            AND m.seccion_id = n.seccion_id
            JOIN estudiante e ON e.id = m.estudiante_id
            JOIN usuario u ON u.id = e.usuario_id
            JOIN asignacion_docente a ON a.id = n.asignacion_docente_id
                                    AND a.periodo_academico_id = m.periodo_academico_id AND a.seccion_id = m.seccion_id
            JOIN curso c ON c.id = a.curso_id
            JOIN docente d ON d.id = a.docente_id
            JOIN usuario du ON du.id = d.usuario_id
            JOIN periodo_academico p ON p.id = m.periodo_academico_id
            JOIN seccion s ON s.id = m.seccion_id
            JOIN grado g ON g.id = s.grado_id
            WHERE e.usuario_id = ? AND u.activo = TRUE AND m.id = ?
            """;

    public record Summary(long total, long presente, long falta, long tardanza, long justificada) {}
    public record Page(List<Attendance> registros, Summary resumen) {}
    public static class InvalidFilters extends RuntimeException {}

    public Page attendance(long user, long enrollment, Long assignment, String from, String to) {
        LocalDate start = date(from), end = date(to);
        if (start != null && end != null && start.isAfter(end)) throw new InvalidFilters();
        requireEnrollment(user, enrollment);
        var parameters = new java.util.ArrayList<Object>();
        parameters.add(user); parameters.add(enrollment);
        String sql = SELECT;
        if (assignment != null) {
            courses.course(user, enrollment, assignment);
            sql += " AND a.id = ?"; parameters.add(assignment);
        }
        if (start != null) { sql += " AND n.fecha >= ?"; parameters.add(start); }
        if (end != null) { sql += " AND n.fecha <= ?"; parameters.add(end); }
        var records = query(sql + " ORDER BY n.fecha DESC, n.id DESC", parameters.toArray());
        return new Page(records, new Summary(records.size(), count(records,"PRESENTE"), count(records,"FALTA"),
                count(records,"TARDANZA"), count(records,"JUSTIFICADA")));
    }

    private long count(List<Attendance> records, String state) {
        return records.stream().filter(record -> record.estado().equals(state)).count();
    }

    private LocalDate date(String value) {
        if (value == null) return null;
        if (!value.matches("[0-9]{4}-[0-9]{2}-[0-9]{2}")) throw new InvalidFilters();
        try {
            LocalDate date = LocalDate.parse(value);
            if (date.getYear() < 1000) throw new InvalidFilters();
            return date;
        } catch (java.time.format.DateTimeParseException e) { throw new InvalidFilters(); }
    }

    public Attendance detail(long user, long enrollment, long attendance) {
        requireEnrollment(user, enrollment);
        var results = query(SELECT + " AND n.id = ?", user, enrollment, attendance);
        if (results.isEmpty()) throw new MissingAttendance();
        return results.getFirst();
    }

    private void requireEnrollment(long user, long enrollment) {
        profiles.profile(user);
        Long count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM matricula m JOIN estudiante e ON e.id=m.estudiante_id
                WHERE e.usuario_id=? AND m.id=?
                """, Long.class, user, enrollment);
        if (count == null || count == 0) throw new MissingAttendance();
    }

    private List<Attendance> query(String sql, Object... parameters) {
        return jdbc.query(sql, (rs,row) -> new Attendance(rs.getLong("id"),rs.getLong("matricula_id"),
                rs.getLong("asignacion_id"),rs.getLong("curso_id"),rs.getString("curso"),
                rs.getString("nombres")+" "+rs.getString("apellidos"),rs.getLong("periodo_id"),rs.getString("periodo"),
                rs.getString("nivel"),rs.getString("grado"),rs.getString("seccion"),
                rs.getObject("fecha",LocalDate.class),rs.getString("estado"),rs.getString("observacion"),
                rs.getObject("registrado_en",LocalDateTime.class)),parameters);
    }
}
