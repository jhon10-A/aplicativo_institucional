package pe.edu.micaelabastidas.backend;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.WebApplicationContext;
import pe.edu.micaelabastidas.backend.auth.AuthService;
import pe.edu.micaelabastidas.backend.auth.LoginRequest;
import pe.edu.micaelabastidas.backend.auth.LoginResponse;
import pe.edu.micaelabastidas.backend.entity.Rol;
import pe.edu.micaelabastidas.backend.entity.Usuario;
import pe.edu.micaelabastidas.backend.repository.RolRepository;
import pe.edu.micaelabastidas.backend.repository.UsuarioRepository;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:auth-tests;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa", "spring.datasource.password=",
        "spring.jpa.hibernate.ddl-auto=none", "spring.sql.init.mode=never",
        "app.dev.seed-enabled=false", "app.cors.allowed-origin=http://localhost:5173", "debug=false", "logging.level.root=WARN"})
@Import(BackendApplicationTests.ProbeConfiguration.class)
class BackendApplicationTests {
    @DynamicPropertySource
    static void isolatedSigningKey(DynamicPropertyRegistry registry) {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        String key = Base64.getEncoder().encodeToString(bytes);
        registry.add("JWT_SECRET_BASE64", () -> key);
    }

    @MockitoBean UsuarioRepository usuarios;
    @MockitoBean RolRepository roles;
    @Autowired WebApplicationContext context;
    @Autowired PasswordEncoder passwords;
    @Autowired JwtEncoder encoder;
    @Autowired JwtDecoder decoder;
    @Autowired ObjectMapper mapper;
    MockMvc mvc;
    Usuario usuario;
    final String testPassword = "Isolated-test-password";

    @BeforeEach
    void setup() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        usuario = new Usuario();
        ReflectionTestUtils.setField(usuario, "id", 7L);
        usuario.setNombreUsuario("cuenta-aislada");
        usuario.setNombres("Prueba");
        usuario.setApellidos("Aislada");
        usuario.setPasswordHash(passwords.encode(testPassword));
        Rol rol = new Rol();
        rol.setNombre("ESTUDIANTE");
        usuario.getRoles().add(rol);
        when(usuarios.findByNombreUsuario("cuenta-aislada")).thenReturn(Optional.of(usuario));
    }

    @Test
    void contextLoads() { assertNotNull(context); }

    private String body(String username, String password) {
        return mapper.writeValueAsString(new LoginRequest(username, password));
    }

    @Test
    void correctLoginReturnsSignedExpiringTokenAndSafeDto() throws Exception {
        String response = mvc.perform(post("/api/auth/login").contentType("application/json")
                        .content(body("cuenta-aislada", testPassword)))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.usuario.id").value(7))
                .andExpect(jsonPath("$.usuario.nombreUsuario").value("cuenta-aislada"))
                .andExpect(jsonPath("$.usuario.nombres").value("Prueba"))
                .andExpect(jsonPath("$.usuario.apellidos").value("Aislada"))
                .andExpect(jsonPath("$.usuario.roles[0]").value("ESTUDIANTE"))
                .andExpect(jsonPath("$.usuario.passwordHash").doesNotExist())
                .andExpect(jsonPath("$.usuario.password_hash").doesNotExist())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andReturn().getResponse().getContentAsString();
        JsonNode result = mapper.readTree(response);
        String token = result.path("accessToken").asText();
        Jwt jwt = decoder.decode(token);
        assertEquals("7", jwt.getSubject());
        assertTrue(jwt.getExpiresAt().isAfter(Instant.now()));
        assertEquals(3600, jwt.getExpiresAt().getEpochSecond() - jwt.getIssuedAt().getEpochSecond());
        mvc.perform(get("/api/test/protected").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
        verify(usuarios, never()).save(any());
    }

    @Test
    void incorrectPasswordReturnsGeneric401() throws Exception {
        denied("cuenta-aislada", "wrong-password");
    }

    @Test
    void missingUserReturnsSameGeneric401() throws Exception {
        denied("inexistente", testPassword);
    }

    @Test
    void inactiveUserReturnsSameGeneric401() throws Exception {
        usuario.setActivo(false);
        denied("cuenta-aislada", testPassword);
    }

    private void denied(String username, String password) throws Exception {
        mvc.perform(post("/api/auth/login").contentType("application/json").content(body(username, password)))
                .andExpect(status().isUnauthorized())
                .andExpect(content().json("{\"mensaje\":\"Credenciales inválidas\"}"));
        verify(usuarios, never()).save(any());
    }

    @Test
    void invalidInputAndMalformedJsonReturn400() throws Exception {
        for (String body : new String[] {body("", ""), body("x".repeat(61), testPassword),
                body("cuenta-aislada", "é".repeat(37)), "{"}) {
            mvc.perform(post("/api/auth/login").contentType("application/json").content(body))
                    .andExpect(status().isBadRequest())
                    .andExpect(content().json("{\"mensaje\":\"Datos de solicitud inválidos\"}"));
        }
        verify(usuarios, never()).findByNombreUsuario(any());
    }

    @Test
    void publicStatusAndProtectedRoutes() throws Exception {
        mvc.perform(get("/api/estado")).andExpect(status().isOk()).andExpect(jsonPath("$.estado").value("ok"));
        mvc.perform(get("/api/test/protected")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/otra-ruta")).andExpect(status().isUnauthorized());
    }

    @Test
    void malformedJwtIsRejected() throws Exception {
        mvc.perform(get("/api/test/protected").header("Authorization", "Bearer invalid-token"))
                .andExpect(status().isUnauthorized()).andExpect(content().json("{\"mensaje\":\"No autorizado\"}"));
    }

    private String signedToken(Instant expiration, String issuer) {
        JwtClaimsSet claims = JwtClaimsSet.builder().issuer(issuer).subject("7")
                .issuedAt(Instant.now().minusSeconds(300)).expiresAt(expiration).build();
        return encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
                .getTokenValue();
    }

    @Test
    void expiredJwtIsRejected() throws Exception {
        mvc.perform(get("/api/test/protected").header("Authorization", "Bearer " +
                        signedToken(Instant.now().minusSeconds(120), AuthService.ISSUER)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void wrongIssuerAndTamperedSignatureAreRejected() throws Exception {
        String token = signedToken(Instant.now().plusSeconds(300), AuthService.ISSUER);
        String[] parts = token.split("\\.");
        byte[] signature = Base64.getUrlDecoder().decode(parts[2]);
        signature[0] ^= 1;
        String altered = parts[0] + "." + parts[1] + "." + Base64.getUrlEncoder().withoutPadding().encodeToString(signature);
        for (String invalid : new String[] {altered, signedToken(Instant.now().plusSeconds(300), "otro")}) {
            mvc.perform(get("/api/test/protected").header("Authorization", "Bearer " + invalid))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Test
    void sensitiveObjectsDoNotExposeCredentials() {
        String serialized = mapper.writeValueAsString(usuario);
        assertFalse(serialized.contains("password"));
        assertFalse(serialized.contains(usuario.getPasswordHash()));
        assertFalse(usuario.toString().contains(usuario.getPasswordHash()));
        assertFalse(new LoginRequest("x", testPassword).toString().contains(testPassword));
        assertFalse(new LoginResponse("sensitive-value", "Bearer", Instant.now(), null)
                .toString().contains("sensitive-value"));
    }

    @Test
    void corsAllowsOnlyConfiguredLocalOrigin() throws Exception {
        mvc.perform(options("/api/auth/login").header("Origin", "http://localhost:5173")
                        .header("Access-Control-Request-Method", "POST")
                        .header("Access-Control-Request-Headers", "content-type"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5173"));
        mvc.perform(options("/api/auth/login").header("Origin", "http://localhost:5174")
                        .header("Access-Control-Request-Method", "POST"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
        mvc.perform(post("/api/auth/login").header("Origin", "http://localhost:5173")
                        .contentType("application/json").content(body("cuenta-aislada", "wrong-password")))
                .andExpect(status().isUnauthorized())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5173"));
    }
    @TestConfiguration
    static class ProbeConfiguration {
        @Bean ProbeController probeController() { return new ProbeController(); }
    }

    @RestController
    static class ProbeController {
        @GetMapping("/api/test/protected")
        public String protectedRoute() { return "ok"; }
    }
}
