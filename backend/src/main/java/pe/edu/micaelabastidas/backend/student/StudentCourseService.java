package pe.edu.micaelabastidas.backend.student;

import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class StudentCourseService {
    private final JdbcTemplate jdbc;
    private final StudentProfileService profiles;

    public StudentCourseService(JdbcTemplate jdbc, StudentProfileService profiles) {
        this.jdbc = jdbc;
        this.profiles = profiles;
    }

    public record Course(long asignacionId, long cursoId, String nombre, String descripcion,
            boolean activo, String docente, String periodo, String nivel, String grado, String seccion) {}
    public static class MissingCourse extends RuntimeException {}

    private static final String SELECT = """
            SELECT a.id AS asignacion_id, c.id AS curso_id, c.nombre, c.descripcion, c.activo,
                   du.nombres, du.apellidos, p.nombre AS periodo, g.nivel,
                   g.nombre AS grado, s.nombre AS seccion
            FROM matricula m
            JOIN estudiante e ON e.id = m.estudiante_id
            JOIN usuario u ON u.id = e.usuario_id
            JOIN asignacion_docente a ON a.periodo_academico_id = m.periodo_academico_id
                                    AND a.seccion_id = m.seccion_id
            JOIN curso c ON c.id = a.curso_id
            JOIN docente d ON d.id = a.docente_id
            JOIN usuario du ON du.id = d.usuario_id
            JOIN periodo_academico p ON p.id = m.periodo_academico_id
            JOIN seccion s ON s.id = m.seccion_id
            JOIN grado g ON g.id = s.grado_id
            WHERE e.usuario_id = ? AND u.activo = TRUE AND m.id = ?
            """;

    public List<Course> courses(long usuarioId, long matriculaId) {
        requireEnrollment(usuarioId, matriculaId);
        return query(SELECT + " ORDER BY c.nombre, a.id", usuarioId, matriculaId);
    }

    public Course course(long usuarioId, long matriculaId, long asignacionId) {
        requireEnrollment(usuarioId, matriculaId);
        var courses = query(SELECT + " AND a.id = ?", usuarioId, matriculaId, asignacionId);
        if (courses.isEmpty()) throw new MissingCourse();
        return courses.getFirst();
    }

    private void requireEnrollment(long usuarioId, long matriculaId) {
        profiles.profile(usuarioId);
        Long count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM matricula m JOIN estudiante e ON e.id = m.estudiante_id
                WHERE e.usuario_id = ? AND m.id = ?
                """, Long.class, usuarioId, matriculaId);
        if (count == null || count == 0) throw new MissingCourse();
    }

    private List<Course> query(String sql, Object... parameters) {
        return jdbc.query(sql, (rs, row) -> new Course(rs.getLong("asignacion_id"),
                rs.getLong("curso_id"), rs.getString("nombre"), rs.getString("descripcion"),
                rs.getBoolean("activo"), rs.getString("nombres") + " " + rs.getString("apellidos"),
                rs.getString("periodo"), rs.getString("nivel"), rs.getString("grado"),
                rs.getString("seccion")), parameters);
    }
}
