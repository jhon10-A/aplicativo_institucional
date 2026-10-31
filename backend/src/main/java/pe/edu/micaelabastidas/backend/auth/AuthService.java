package pe.edu.micaelabastidas.backend.auth;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.micaelabastidas.backend.entity.Rol;
import pe.edu.micaelabastidas.backend.entity.Usuario;
import pe.edu.micaelabastidas.backend.repository.UsuarioRepository;

@Service
public class AuthService {
    public static final String ISSUER = "backend-institucional";
    private final UsuarioRepository usuarios;
    private final PasswordEncoder passwords;
    private final JwtEncoder encoder;
    private final long ttlSeconds;
    private final String dummyHash;

    public AuthService(UsuarioRepository usuarios, PasswordEncoder passwords,
                       JwtEncoder encoder, @Value("${app.jwt.ttl-seconds:3600}") long ttlSeconds) {
        if (ttlSeconds < 1 || ttlSeconds > 86400) {
            throw new IllegalArgumentException("app.jwt.ttl-seconds debe estar entre 1 y 86400");
        }
        this.usuarios = usuarios;
        this.passwords = passwords;
        this.encoder = encoder;
        this.ttlSeconds = ttlSeconds;
        byte[] random = new byte[32];
        new SecureRandom().nextBytes(random);
        this.dummyHash = passwords.encode(Base64.getEncoder().encodeToString(random));
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        Usuario usuario = usuarios.findByNombreUsuario(request.nombreUsuario()).orElse(null);
        String hash = usuario == null ? dummyHash : usuario.getPasswordHash();
        boolean matches = passwords.matches(request.password(), hash);
        if (usuario == null || !matches || !usuario.isActivo()) {
            throw new BadCredentialsException("Credenciales inválidas");
        }
        Set<String> roles = usuario.getRoles().stream().map(Rol::getNombre).collect(Collectors.toSet());
        UsuarioDto dto = new UsuarioDto(usuario.getId(), usuario.getNombreUsuario(),
                usuario.getNombres(), usuario.getApellidos(), roles);
        Instant now = Instant.now();
        Instant expiresAt = now.plusSeconds(ttlSeconds);
        JwtClaimsSet claims = JwtClaimsSet.builder().issuer(ISSUER)
                .subject(usuario.getId().toString()).issuedAt(now).notBefore(now)
                .expiresAt(expiresAt).claim("roles", roles).build();
        String token = encoder.encode(JwtEncoderParameters.from(
                JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
        return new LoginResponse(token, "Bearer", expiresAt, dto);
    }
}
