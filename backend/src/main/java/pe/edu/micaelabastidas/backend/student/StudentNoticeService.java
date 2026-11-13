package pe.edu.micaelabastidas.backend.student;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class StudentNoticeService {
    private final JdbcTemplate jdbc;
    private final StudentProfileService profiles;
    public StudentNoticeService(JdbcTemplate jdbc, StudentProfileService profiles) { this.jdbc=jdbc; this.profiles=profiles; }
    public record Section(long id,String nombre,String grado,String nivel) {}
    public record Notice(long id,String titulo,String contenido,String remitente,LocalDateTime publicadoEn,
            LocalDateTime fechaVencimiento,String rolDestino,Section seccionDestino) {}
    public static class MissingNotice extends RuntimeException {}

    private static final String SELECT = """
            SELECT c.id,c.titulo,c.contenido,autor.nombres,autor.apellidos,c.publicado_en,c.fecha_vencimiento,
                   r.nombre AS rol_destino,s.id AS seccion_id,s.nombre AS seccion_nombre,g.nombre AS grado,g.nivel
            FROM comunicado c JOIN usuario autor ON autor.id=c.autor_id
            LEFT JOIN rol r ON r.id=c.rol_destino_id
            LEFT JOIN seccion s ON s.id=c.seccion_destino_id LEFT JOIN grado g ON g.id=s.grado_id
            WHERE c.activo=TRUE AND c.publicado_en<=CURRENT_TIMESTAMP
              AND (c.fecha_vencimiento IS NULL OR c.fecha_vencimiento>CURRENT_TIMESTAMP)
              AND (c.rol_destino_id IS NULL OR r.nombre='ESTUDIANTE')
            """;

    public List<Notice> notices(long user,Long enrollment) {
        return find(user,enrollment,null);
    }
    public Notice detail(long user,Long enrollment,long notice) {
        var notices=find(user,enrollment,notice);
        if(notices.isEmpty()) throw new MissingNotice();
        return notices.getFirst();
    }
    private List<Notice> find(long user,Long enrollment,Long notice) {
        String sql=SELECT;
        var parameters=new ArrayList<Object>();
        if(enrollment==null) {
            sql+=" AND c.seccion_destino_id IS NULL";
        } else {
            profiles.profile(user);
            Long section=jdbc.query("""
                    SELECT m.seccion_id FROM matricula m JOIN estudiante e ON e.id=m.estudiante_id
                    JOIN usuario u ON u.id=e.usuario_id
                    WHERE m.id=? AND e.usuario_id=? AND u.activo=TRUE
                    """,(rs,row)->rs.getLong(1),enrollment,user).stream().findFirst().orElseThrow(MissingNotice::new);
            sql+=" AND (c.seccion_destino_id IS NULL OR c.seccion_destino_id=?)";
            parameters.add(section);
        }
        if(notice!=null) { sql+=" AND c.id=?"; parameters.add(notice); }
        return jdbc.query(sql+" ORDER BY c.publicado_en DESC,c.id DESC",(rs,row)->new Notice(
                rs.getLong("id"),rs.getString("titulo"),rs.getString("contenido"),
                rs.getString("nombres")+" "+rs.getString("apellidos"),rs.getObject("publicado_en",LocalDateTime.class),
                rs.getObject("fecha_vencimiento",LocalDateTime.class),rs.getString("rol_destino"),
                rs.getObject("seccion_id")==null?null:new Section(rs.getLong("seccion_id"),rs.getString("seccion_nombre"),
                        rs.getString("grado"),rs.getString("nivel"))),parameters.toArray());
    }
}
