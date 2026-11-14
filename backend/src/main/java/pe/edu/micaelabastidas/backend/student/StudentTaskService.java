package pe.edu.micaelabastidas.backend.student;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class StudentTaskService {
    private final JdbcTemplate jdbc;
    private final StudentProfileService profiles;
    private final StudentCourseService courses;

    public StudentTaskService(JdbcTemplate jdbc, StudentProfileService profiles, StudentCourseService courses) {
        this.jdbc = jdbc;
        this.profiles = profiles;
        this.courses = courses;
    }

    public record Submission(long id, String comentario, String archivoUrl, LocalDateTime fechaEntrega,
            BigDecimal puntaje, String retroalimentacion, LocalDateTime fechaRevision) {}
    public record Task(long id, long asignacionId, long cursoId, String curso, String docente,
            String titulo, String descripcion, String archivoUrl, LocalDateTime fechaPublicacion,
            LocalDateTime fechaLimite, BigDecimal puntajeMaximo, String estadoEntrega, Submission entrega) {}
    public static class MissingTask extends RuntimeException {}

    private static final String SELECT = """
            SELECT t.id, m.id AS matricula_id, a.id AS asignacion_id, c.id AS curso_id, c.nombre AS curso,
                   du.nombres, du.apellidos, t.titulo, t.descripcion, t.archivo_url,
                   t.fecha_publicacion, t.fecha_limite, t.puntaje_maximo,
                   et.id AS entrega_id, et.comentario, et.archivo_url AS entrega_archivo_url,
                   et.fecha_entrega, et.puntaje, et.retroalimentacion, et.fecha_revision
            FROM matricula m
            JOIN estudiante e ON e.id = m.estudiante_id
            JOIN usuario u ON u.id = e.usuario_id
            JOIN asignacion_docente a ON a.periodo_academico_id = m.periodo_academico_id
                                    AND a.seccion_id = m.seccion_id
            JOIN curso c ON c.id = a.curso_id
            JOIN docente d ON d.id = a.docente_id
            JOIN usuario du ON du.id = d.usuario_id
            JOIN tarea t ON t.asignacion_docente_id = a.id
            LEFT JOIN entrega_tarea et ON et.tarea_id = t.id AND et.matricula_id = m.id
            WHERE e.usuario_id = ? AND u.activo = TRUE AND m.id = ? AND t.activo = TRUE
            """;

    public List<Task> tasks(long usuarioId, long matriculaId, Long asignacionId) {
        requireEnrollment(usuarioId, matriculaId);
        if (asignacionId != null) {
            courses.course(usuarioId, matriculaId, asignacionId);
            return query(SELECT + " AND a.id = ? ORDER BY t.fecha_limite, t.id", usuarioId, matriculaId, asignacionId);
        }
        return query(SELECT + " ORDER BY t.fecha_limite, t.id", usuarioId, matriculaId);
    }

    public Task task(long usuarioId, long matriculaId, long tareaId) {
        requireEnrollment(usuarioId, matriculaId);
        var tasks = query(SELECT + " AND t.id = ?", usuarioId, matriculaId, tareaId);
        if (tasks.isEmpty()) throw new MissingTask();
        return tasks.getFirst();
    }

    private void requireEnrollment(long usuarioId, long matriculaId) {
        profiles.profile(usuarioId);
        Long count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM matricula m JOIN estudiante e ON e.id = m.estudiante_id
                WHERE e.usuario_id = ? AND m.id = ?
                """, Long.class, usuarioId, matriculaId);
        if (count == null || count == 0) throw new MissingTask();
    }

    private List<Task> query(String sql, Object... parameters) {
        return jdbc.query(sql, (rs, row) -> {
            Submission submission = rs.getObject("entrega_id") == null ? null : new Submission(
                    rs.getLong("entrega_id"), rs.getString("comentario"),
                    SubmissionFiles.managed(rs.getString("entrega_archivo_url"))
                            ? StudentSubmissionService.downloadPath(rs.getLong("matricula_id"),rs.getLong("id")) : rs.getString("entrega_archivo_url"),
                    rs.getObject("fecha_entrega", LocalDateTime.class), rs.getBigDecimal("puntaje"),
                    rs.getString("retroalimentacion"), rs.getObject("fecha_revision", LocalDateTime.class));
            String state = submission == null ? "PENDIENTE" : submission.fechaRevision() == null ? "ENTREGADA" : "REVISADA";
            return new Task(rs.getLong("id"), rs.getLong("asignacion_id"), rs.getLong("curso_id"),
                    rs.getString("curso"), rs.getString("nombres") + " " + rs.getString("apellidos"),
                    rs.getString("titulo"), rs.getString("descripcion"), rs.getString("archivo_url"),
                    rs.getObject("fecha_publicacion", LocalDateTime.class), rs.getObject("fecha_limite", LocalDateTime.class),
                    rs.getBigDecimal("puntaje_maximo"), state, submission);
        }, parameters);
    }
}
