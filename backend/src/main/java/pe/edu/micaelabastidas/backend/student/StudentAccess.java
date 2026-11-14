package pe.edu.micaelabastidas.backend.student;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Service;

/** Revalidates the current account and role without reading password columns. */
@Service
public class StudentAccess {
    private final JdbcTemplate jdbc;

    public StudentAccess(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public boolean allowed(Authentication authentication) {
        if (!(authentication instanceof JwtAuthenticationToken jwt) || !jwt.isAuthenticated()
                || jwt.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_ESTUDIANTE"))) {
            return false;
        }
        try {
            long id = Long.parseLong(jwt.getToken().getSubject());
            if (id < 1) return false;
            Long count = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM usuario u
                    JOIN usuario_rol ur ON ur.usuario_id = u.id
                    JOIN rol r ON r.id = ur.rol_id
                    WHERE u.id = ? AND u.activo = TRUE AND r.nombre = 'ESTUDIANTE'
                    """, Long.class, id);
            return count != null && count > 0;
        } catch (NumberFormatException | NullPointerException exception) {
            return false;
        }
    }
}
