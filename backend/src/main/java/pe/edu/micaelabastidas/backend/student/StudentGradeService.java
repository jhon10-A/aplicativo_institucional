package pe.edu.micaelabastidas.backend.student;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class StudentGradeService {
    private final JdbcTemplate jdbc;
    private final StudentProfileService profiles;
    private final StudentCourseService courses;

    public StudentGradeService(JdbcTemplate jdbc, StudentProfileService profiles, StudentCourseService courses) {
        this.jdbc = jdbc;
        this.profiles = profiles;
        this.courses = courses;
    }

    public record Grade(long id, long matriculaId, long asignacionId, long cursoId, String curso,
            String docente, long periodoId, String periodo, String nivel, String grado, String seccion,
            String etapa, String concepto, BigDecimal nota, String observacion, LocalDateTime registradoEn) {}
    public static class MissingGrade extends RuntimeException {}

    private static final String SELECT = """
            SELECT n.id, m.id AS matricula_id, a.id AS asignacion_id, c.id AS curso_id,
                   c.nombre AS curso, du.nombres, du.apellidos, p.id AS periodo_id, p.nombre AS periodo,
                   g.nivel, g.nombre AS grado, s.nombre AS seccion,
                   n.etapa, n.concepto, n.nota, n.observacion, n.registrado_en
            FROM calificacion n
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

    public List<Grade> grades(long user, long enrollment, Long assignment) {
        requireEnrollment(user, enrollment);
        if (assignment != null) {
            courses.course(user, enrollment, assignment);
            return query(SELECT + " AND a.id = ? ORDER BY n.registrado_en DESC, n.id DESC", user, enrollment, assignment);
        }
        return query(SELECT + " ORDER BY n.registrado_en DESC, n.id DESC", user, enrollment);
    }

    public Grade grade(long user, long enrollment, long grade) {
        requireEnrollment(user, enrollment);
        var results = query(SELECT + " AND n.id = ?", user, enrollment, grade);
        if (results.isEmpty()) throw new MissingGrade();
        return results.getFirst();
    }

    private void requireEnrollment(long user, long enrollment) {
        profiles.profile(user);
        Long count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM matricula m JOIN estudiante e ON e.id=m.estudiante_id
                WHERE e.usuario_id=? AND m.id=?
                """, Long.class, user, enrollment);
        if (count == null || count == 0) throw new MissingGrade();
    }

    private List<Grade> query(String sql, Object... parameters) {
        return jdbc.query(sql, (rs, row) -> new Grade(rs.getLong("id"), rs.getLong("matricula_id"),
                rs.getLong("asignacion_id"), rs.getLong("curso_id"), rs.getString("curso"),
                rs.getString("nombres")+" "+rs.getString("apellidos"), rs.getLong("periodo_id"), rs.getString("periodo"),
                rs.getString("nivel"), rs.getString("grado"), rs.getString("seccion"), rs.getString("etapa"),
                rs.getString("concepto"), rs.getBigDecimal("nota"), rs.getString("observacion"),
                rs.getObject("registrado_en", LocalDateTime.class)), parameters);
    }
}
