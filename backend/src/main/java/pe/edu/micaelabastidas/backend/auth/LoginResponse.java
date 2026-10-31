package pe.edu.micaelabastidas.backend.auth;

import java.time.Instant;

public record LoginResponse(String accessToken, String tokenType,
                            Instant expiresAt, UsuarioDto usuario) {
    @Override
    public String toString() { return "LoginResponse[REDACTED]"; }
}
