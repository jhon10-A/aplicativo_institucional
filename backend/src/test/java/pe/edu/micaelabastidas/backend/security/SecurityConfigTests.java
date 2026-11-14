package pe.edu.micaelabastidas.backend.security;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import javax.crypto.SecretKey;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import pe.edu.micaelabastidas.backend.auth.AuthService;
import static org.junit.jupiter.api.Assertions.*;

class SecurityConfigTests {
    private final SecurityConfig config = new SecurityConfig();

    @Test
    void developmentCorsRequiresExplicitOptInAndAllowsOnlyLoopbackOriginsOnVariablePorts() {
        var request = new org.springframework.mock.web.MockHttpServletRequest("OPTIONS", "/api/estudiante/perfil");
        var disabled = config.corsConfigurationSource("").getCorsConfiguration(request);
        assertNull(disabled.checkOrigin("http://localhost:5173"));
        var cors = config.corsConfigurationSource("http://localhost:5173").getCorsConfiguration(request);
        for (String origin : new String[] {
                "http://localhost:5173", "http://localhost:63170", "http://127.0.0.1:5173", "http://127.0.0.1:63170"}) {
            assertEquals(origin, cors.checkOrigin(origin));
        }
        for (String invalidOrigin : new String[] {
                "http://example.invalid:63170", "http://192.168.1.10:63170", "https://localhost:63170"}) {
            assertNull(cors.checkOrigin(invalidOrigin));
        }
        assertEquals(java.util.List.of("GET", "POST", "OPTIONS"), cors.getAllowedMethods());
        assertEquals(java.util.List.of("Content-Type", "Authorization", "Accept"), cors.getAllowedHeaders());
        assertFalse(cors.getAllowCredentials());
        for (String invalid : new String[] {"*", "https://example.invalid", "http://localhost:5173/", "http://user@localhost:5173"}) {
            assertThrows(IllegalArgumentException.class, () -> config.corsConfigurationSource(invalid));
        }
    }

    @Test
    void weakEmptyAndMalformedKeysAreRejected() {
        assertThrows(IllegalArgumentException.class, () -> config.jwtKey(""));
        assertThrows(IllegalArgumentException.class, () -> config.jwtKey("not base64!"));
        byte[] bytes = new byte[31];
        new SecureRandom().nextBytes(bytes);
        assertThrows(IllegalArgumentException.class, () -> config.jwtKey(Base64.getEncoder().encodeToString(bytes)));
    }

    @Test
    void missingExpirationAndFutureNotBeforeAreRejected() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        SecretKey key = config.jwtKey(Base64.getEncoder().encodeToString(bytes));
        JwtEncoder encoder = config.jwtEncoder(key);
        JwtDecoder decoder = config.jwtDecoder(key);
        for (JwtClaimsSet claims : new JwtClaimsSet[] {
                JwtClaimsSet.builder().issuer(AuthService.ISSUER).subject("1").issuedAt(Instant.now()).build(),
                JwtClaimsSet.builder().issuer(AuthService.ISSUER).subject("1")
                        .notBefore(Instant.now().plusSeconds(300)).expiresAt(Instant.now().plusSeconds(600)).build()}) {
            String token = encoder.encode(JwtEncoderParameters.from(
                    JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
            assertThrows(JwtException.class, () -> decoder.decode(token));
        }
    }
}
