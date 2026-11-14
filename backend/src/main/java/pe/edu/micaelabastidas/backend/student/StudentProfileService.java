package pe.edu.micaelabastidas.backend.student;

import java.time.LocalDate;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class StudentProfileService {
    private final JdbcTemplate jdbc;
    public StudentProfileService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public record Profile(long id, long usuarioId, String nombreUsuario, String nombres, String apellidos,
            String correo, String telefono, String fotoUrl, String codigoEstudiante,
            String documentoIdentidad, LocalDate fechaNacimiento) {}
    public record Period(long id, String nombre, LocalDate fechaInicio, LocalDate fechaFin, boolean activo) {}
    public record Grade(long id, String nivel, String nombre) {}
    public record Section(long id, String nombre, Grade grado) {}
    public record Enrollment(long id, LocalDate fechaMatricula, String estado, Period periodo, Section seccion) {}
    public static class MissingProfile extends RuntimeException {}

    public Profile profile(long usuarioId) {
        List<Profile> profiles = jdbc.query("""
                SELECT e.id, e.usuario_id, u.nombre_usuario, u.nombres, u.apellidos,
                       u.correo, u.telefono, u.foto_url, e.codigo_estudiante,
                       e.documento_identidad, e.fecha_nacimiento
                FROM estudiante e JOIN usuario u ON u.id = e.usuario_id
                WHERE e.usuario_id = ? AND u.activo = TRUE
                """, (rs, row) -> new Profile(rs.getLong("id"), rs.getLong("usuario_id"),
                rs.getString("nombre_usuario"), rs.getString("nombres"), rs.getString("apellidos"),
                rs.getString("correo"), rs.getString("telefono"), rs.getString("foto_url"),
                rs.getString("codigo_estudiante"), rs.getString("documento_identidad"),
                rs.getObject("fecha_nacimiento", LocalDate.class)), usuarioId);
        if (profiles.isEmpty()) throw new MissingProfile();
        return profiles.getFirst(); // usuario_id is UNIQUE in estudiante.
    }

    public List<Enrollment> enrollments(long usuarioId) {
        profile(usuarioId); // Distinguish missing profile from an empty enrollment history.
        return jdbc.query("""
                SELECT m.id, m.fecha_matricula, m.estado,
                       p.id AS periodo_id, p.nombre AS periodo_nombre,
                       p.fecha_inicio, p.fecha_fin, p.activo AS periodo_activo,
                       s.id AS seccion_id, s.nombre AS seccion_nombre,
                       g.id AS grado_id, g.nivel, g.nombre AS grado_nombre
                FROM matricula m JOIN estudiante e ON e.id = m.estudiante_id
                JOIN usuario u ON u.id = e.usuario_id
                JOIN periodo_academico p ON p.id = m.periodo_academico_id
                JOIN seccion s ON s.id = m.seccion_id JOIN grado g ON g.id = s.grado_id
                WHERE e.usuario_id = ? AND u.activo = TRUE
                ORDER BY p.fecha_inicio DESC, p.id DESC, m.id DESC
                """, (rs, row) -> new Enrollment(rs.getLong("id"),
                rs.getObject("fecha_matricula", LocalDate.class), rs.getString("estado"),
                new Period(rs.getLong("periodo_id"), rs.getString("periodo_nombre"),
                        rs.getObject("fecha_inicio", LocalDate.class), rs.getObject("fecha_fin", LocalDate.class),
                        rs.getBoolean("periodo_activo")),
                new Section(rs.getLong("seccion_id"), rs.getString("seccion_nombre"),
                        new Grade(rs.getLong("grado_id"), rs.getString("nivel"), rs.getString("grado_nombre")))), usuarioId);
    }
}
