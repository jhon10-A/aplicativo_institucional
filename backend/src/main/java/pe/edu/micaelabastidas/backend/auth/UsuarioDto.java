package pe.edu.micaelabastidas.backend.auth;

import java.util.Set;

public record UsuarioDto(Long id, String nombreUsuario, String nombres,
                         String apellidos, Set<String> roles) {
    public UsuarioDto { roles = Set.copyOf(roles); }
}
