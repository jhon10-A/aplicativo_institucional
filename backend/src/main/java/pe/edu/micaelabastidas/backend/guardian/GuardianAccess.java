package pe.edu.micaelabastidas.backend.guardian;

import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * Revalida en cada petición que la cuenta está activa, tiene el rol APODERADO
 * y que el estudiante consultado es realmente su hijo. No lee contraseñas.
 */
@Service
public class GuardianAccess {
    private final JdbcTemplate jdbc;

    public GuardianAccess(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    /** La cuenta no es un apoderado activo con perfil registrado. */
    public static class NotGuardian extends RuntimeException {}

    /** El estudiante no existe o no está vinculado a este apoderado. */
    public static class MissingChild extends RuntimeException {}

    /** Devuelve el id de la tabla apoderado para el usuario autenticado. */
    public long guardianId(long usuarioId) {
        List<Long> ids = jdbc.query("""
                SELECT a.id
                FROM apoderado a
                JOIN usuario u ON u.id = a.usuario_id
                JOIN usuario_rol ur ON ur.usuario_id = u.id
                JOIN rol r ON r.id = ur.rol_id
                WHERE a.usuario_id = ? AND u.activo = TRUE AND r.nombre = 'APODERADO'
                """, (rs, row) -> rs.getLong("id"), usuarioId);
        if (ids.isEmpty()) throw new NotGuardian();
        return ids.getFirst();
    }

    /** Comprueba que el estudiante es hijo del apoderado; si no, lanza MissingChild. */
    public long requireChild(long usuarioId, long estudianteId) {
        long guardianId = guardianId(usuarioId);
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM estudiante_apoderado
                WHERE apoderado_id = ? AND estudiante_id = ?
                """, Integer.class, guardianId, estudianteId);
        if (count == null || count < 1) throw new MissingChild();
        return estudianteId;
    }
}
