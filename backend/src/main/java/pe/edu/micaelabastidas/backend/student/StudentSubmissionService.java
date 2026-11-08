package pe.edu.micaelabastidas.backend.student;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.multipart.MultipartFile;

@Service
public class StudentSubmissionService {
    private final JdbcTemplate jdbc;
    private final SubmissionFiles files;
    public StudentSubmissionService(JdbcTemplate jdbc, SubmissionFiles files) { this.jdbc = jdbc; this.files = files; }
    public static class Rejected extends RuntimeException {
        final String code;
        final int status;
        public Rejected(String code, int status) { this.code = code; this.status = status; }
    }
    public record Delivery(long id, String comentario, String archivoUrl, LocalDateTime fechaEntrega,
            String estadoEntrega, BigDecimal puntaje, String retroalimentacion, LocalDateTime fechaRevision) {}
    private static final String OWN = """
            FROM matricula m JOIN estudiante e ON e.id=m.estudiante_id
            JOIN usuario u ON u.id=e.usuario_id
            JOIN asignacion_docente a ON a.periodo_academico_id=m.periodo_academico_id AND a.seccion_id=m.seccion_id
            JOIN tarea t ON t.asignacion_docente_id=a.id
            WHERE u.id=? AND u.activo=TRUE AND m.id=? AND t.id=?
            AND EXISTS (SELECT 1 FROM usuario_rol ur JOIN rol r ON r.id=ur.rol_id
                        WHERE ur.usuario_id=u.id AND r.nombre='ESTUDIANTE')
            """;

    @Transactional
    public Delivery submit(long user, long enrollment, long task, String comment, MultipartFile file) {
        // Serialize submissions and deadline/task changes, using database time rather than the device clock.
        var allowed = jdbc.query("SELECT t.activo,t.fecha_publicacion,t.fecha_limite,m.estado " + OWN + " FOR UPDATE",
                (rs, n) -> new Object[] {rs.getBoolean(1),rs.getObject(2,LocalDateTime.class),
                        rs.getObject(3,LocalDateTime.class),rs.getString(4)},user,enrollment,task);
        if (allowed.isEmpty()) throw new Rejected("NO_DISPONIBLE",404);
        Object[] row = allowed.getFirst();
        if (!(Boolean)row[0] || !"ACTIVA".equals(row[3])) throw new Rejected("ENTREGA_CERRADA",409);
        if (jdbc.queryForObject("SELECT COUNT(*) FROM entrega_tarea WHERE tarea_id=? AND matricula_id=?",Long.class,task,enrollment)>0)
            throw new Rejected("ENTREGA_DUPLICADA",409);
        String text = comment == null ? "" : comment.strip();
        if (text.codePointCount(0,text.length()) > 10000 || text.indexOf('\0') >= 0) throw new Rejected("RESPUESTA_INVALIDA",400);
        SubmissionFiles.Upload upload = files.validate(file);
        if (text.isEmpty() && upload == null) throw new Rejected("ENTREGA_VACIA",400);
        String reference = upload == null ? null : files.write(upload);
        if (reference != null) TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCompletion(int status) {
                if (status != STATUS_COMMITTED) files.delete(reference);
            }
        });
        LocalDateTime now = jdbc.queryForObject("SELECT CURRENT_TIMESTAMP",LocalDateTime.class);
        if (now.isBefore((LocalDateTime)row[1]) || now.isAfter((LocalDateTime)row[2])) throw new Rejected("FUERA_DE_PLAZO",409);
        try {
            jdbc.update("INSERT INTO entrega_tarea (tarea_id,matricula_id,comentario,archivo_url,fecha_entrega) VALUES (?,?,?,?,?)",
                    task,enrollment,text.isEmpty()?null:text,reference,now);
        } catch (DuplicateKeyException e) { throw new Rejected("ENTREGA_DUPLICADA",409); }
        return detail(user,enrollment,task);
    }

    private String reference(long user, long enrollment, long task) {
        var references = jdbc.query("SELECT et.archivo_url FROM entrega_tarea et WHERE et.matricula_id=? AND et.tarea_id=? AND EXISTS (SELECT 1 " + OWN + ")",
                (rs,n) -> rs.getString(1),enrollment,task,user,enrollment,task);
        if (references.isEmpty()) throw new Rejected("NO_DISPONIBLE",404);
        return references.getFirst();
    }

    @Transactional(readOnly = true)
    public Delivery detail(long user, long enrollment, long task) {
        var deliveries = jdbc.query("""
                SELECT et.* FROM entrega_tarea et WHERE et.matricula_id=? AND et.tarea_id=?
                AND EXISTS (SELECT 1
                """ + OWN + ")", (rs,n) -> {
                    String ref = rs.getString("archivo_url");
                    LocalDateTime reviewed = rs.getObject("fecha_revision",LocalDateTime.class);
                    return new Delivery(rs.getLong("id"),rs.getString("comentario"),SubmissionFiles.managed(ref)?downloadPath(enrollment,task):null,
                            rs.getObject("fecha_entrega",LocalDateTime.class),reviewed==null?"ENTREGADA":"REVISADA",
                            rs.getBigDecimal("puntaje"),rs.getString("retroalimentacion"),reviewed);
                },enrollment,task,user,enrollment,task);
        if (deliveries.isEmpty()) throw new Rejected("NO_DISPONIBLE",404);
        return deliveries.getFirst();
    }
    public static String downloadPath(long enrollment, long task) {
        return "/api/estudiante/matriculas/"+enrollment+"/tareas/"+task+"/entrega/archivo";
    }
    @Transactional(readOnly = true)
    public SubmissionFiles.Download download(long user, long enrollment, long task) {
        return files.read(reference(user,enrollment,task));
    }
}
