package pe.edu.micaelabastidas.backend.student;

import java.nio.file.Files;
import java.nio.file.Path;
import java.security.SecureRandom;
import java.util.Base64;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import tools.jackson.databind.ObjectMapper;
import pe.edu.micaelabastidas.backend.auth.LoginRequest;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {"spring.config.import=", "spring.datasource.url=jdbc:h2:mem:student-notices;MODE=MySQL;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
        "spring.datasource.password=", "spring.jpa.hibernate.ddl-auto=none", "spring.sql.init.mode=never",
        "app.dev.seed-enabled=false", "debug=false", "logging.level.root=WARN"})
class StudentNoticeTests {
    @DynamicPropertySource static void key(DynamicPropertyRegistry registry) {
        byte[] bytes = new byte[32]; new SecureRandom().nextBytes(bytes);
        registry.add("JWT_SECRET_BASE64", () -> Base64.getEncoder().encodeToString(bytes));
    }
    @Autowired JdbcTemplate jdbc;
    @Autowired WebApplicationContext context;
    @Autowired PasswordEncoder passwords;
    @Autowired ObjectMapper mapper;
    MockMvc mvc;
    RequestPostProcessor student(String id) {
        return jwt().jwt(j -> j.subject(id)).authorities(new SimpleGrantedAuthority("ROLE_ESTUDIANTE"));
    }
    String list(long enrollment) { return "/api/estudiante/matriculas/" + enrollment + "/comunicados"; }

    @BeforeEach void setup() throws Exception {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        try (var connection = jdbc.getDataSource().getConnection()) {
            assertEquals("H2", connection.getMetaData().getDatabaseProductName());
        }
        jdbc.execute("DROP ALL OBJECTS"); // This context uses only the H2 database above.
        String sql = Files.readString(Path.of("..", "database", "01_estructura.sql"))
                .replaceAll("(?m)^\\s*--.*$", "");
        for (String part : sql.split(";")) {
            String statement = part.trim();
            if (statement.startsWith("CREATE TABLE") || statement.startsWith("INSERT INTO rol")) jdbc.execute(statement);
        }
        jdbc.update("""
                INSERT INTO usuario (id,nombre_usuario,password_hash,nombres,apellidos) VALUES
                (1,'fixture1','NOT_A_PASSWORD_HASH','Estudiante','Uno'),
                (2,'fixture2','NOT_A_PASSWORD_HASH','Estudiante','Dos'),
                (3,'fixture3','NOT_A_PASSWORD_HASH','Sin','Perfil'),
                (4,'fixture4','NOT_A_PASSWORD_HASH','Docente','Prueba')
                """);
        jdbc.update("INSERT INTO usuario_rol SELECT u.id,r.id FROM usuario u CROSS JOIN rol r WHERE r.nombre='ESTUDIANTE' AND u.id<4");
        jdbc.update("INSERT INTO estudiante (id,usuario_id,codigo_estudiante) VALUES (11,1,'E1'),(22,2,'E2')");
        jdbc.update("INSERT INTO docente (id,usuario_id) VALUES (41,4)");
        jdbc.update("INSERT INTO periodo_academico VALUES (1,'2025','2025-03-01','2025-12-31',FALSE),(2,'2026','2026-03-01','2026-12-31',TRUE),(3,'2027','2027-03-01','2027-12-31',TRUE)");
        jdbc.update("INSERT INTO grado VALUES (1,'SECUNDARIA','Primero')");
        jdbc.update("INSERT INTO seccion VALUES (1,1,'A'),(2,1,'B')");
        jdbc.update("INSERT INTO matricula VALUES (101,11,1,1,'2025-03-01','FINALIZADA'),(102,11,2,1,'2026-03-01','ACTIVA'),(103,11,3,1,'2027-03-01','ACTIVA'),(202,22,2,2,'2026-03-01','ACTIVA')");
        jdbc.update("INSERT INTO curso VALUES (1,'Matemática','Descripción de prueba',TRUE),(2,'Arte',NULL,FALSE),(3,'Curso ajeno',NULL,TRUE)");
        jdbc.update("INSERT INTO asignacion_docente VALUES (501,41,1,2,1),(502,41,2,2,1),(503,41,1,1,1),(504,41,3,2,2)");
        jdbc.update("UPDATE matricula SET seccion_id=2 WHERE id=103");
        for(int id=1;id<=12;id++) {
            String role=switch(id) {case 2,4,5,9,10,11,12->"ESTUDIANTE";case 6,8->"DOCENTE";case 7->"APODERADO";default->null;};
            Integer section=switch(id) {case 3,4,8->1;case 5->2;default->null;};
            jdbc.update("""
                    INSERT INTO comunicado (id,autor_id,titulo,contenido,rol_destino_id,seccion_destino_id,publicado_en,activo)
                    VALUES (?,4,?,?,(SELECT id FROM rol WHERE nombre=?),?,DATEADD('DAY',-1,CURRENT_TIMESTAMP),TRUE)
                    """,id,"Comunicado "+id,"Contenido "+id,role,section);
        }
        jdbc.update("UPDATE comunicado SET fecha_vencimiento=DATEADD('DAY',1,CURRENT_TIMESTAMP) WHERE id=2");
        jdbc.update("UPDATE comunicado SET activo=FALSE WHERE id=9");
        jdbc.update("UPDATE comunicado SET publicado_en=DATEADD('DAY',1,CURRENT_TIMESTAMP) WHERE id=10");
        jdbc.update("UPDATE comunicado SET fecha_vencimiento=DATEADD('HOUR',-1,CURRENT_TIMESTAMP) WHERE id=11");
        jdbc.update("UPDATE comunicado SET publicado_en=DATEADD('DAY',1,CURRENT_TIMESTAMP),fecha_vencimiento=DATEADD('HOUR',-1,CURRENT_TIMESTAMP) WHERE id=12");
        // Notifications are per-user messages, not an override of the comunicado audience.
        jdbc.update("INSERT INTO notificacion (usuario_id,comunicado_id,titulo,mensaje) VALUES (1,6,'Privada docente','No conceder acceso'),(2,5,'Solo usuario dos','Mensaje privado ajeno')");
    }

    String general(){return "/api/estudiante/comunicados";}

    @Test void generalFeedHonorsRoleScopeAndDoesNotRequireAcademicProfile() throws Exception {
        for(String user:new String[]{"1","2","3"}) {
            mvc.perform(get(general()).with(student(user))).andExpect(status().isOk())
                    .andExpect(header().string("Cache-Control","no-store"))
                    .andExpect(jsonPath("$.length()").value(2)).andExpect(jsonPath("$[0].id").value(2))
                    .andExpect(jsonPath("$[1].id").value(1)).andExpect(jsonPath("$[0].seccionDestino").isEmpty())
                    .andExpect(jsonPath("$[0].rolDestino").value("ESTUDIANTE"))
                    .andExpect(jsonPath("$[1].rolDestino").isEmpty());
        }
    }

    @Test void selectedEnrollmentIncludesGeneralAndOnlyItsSectionWithIntersectedRole() throws Exception {
        mvc.perform(get(list(102)+"?usuarioId=2&seccionId=2").with(student("1"))).andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(4)).andExpect(jsonPath("$[0].id").value(4))
                .andExpect(jsonPath("$[1].id").value(3)).andExpect(jsonPath("$[2].id").value(2))
                .andExpect(jsonPath("$[0].seccionDestino.nombre").value("A"))
                .andExpect(jsonPath("$[0].seccionDestino.grado").value("Primero"));
        mvc.perform(get(list(202)).with(student("2"))).andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3)).andExpect(jsonPath("$[0].id").value(5));
        mvc.perform(get(list(102)+"/8").with(student("1"))).andExpect(status().isNotFound());
    }

    @Test void detailRepeatsVisibilityChecksAndReturnsOnlyRealNoticeFields() throws Exception {
        mvc.perform(get(list(102)+"/4").with(student("1"))).andExpect(status().isOk())
                .andExpect(header().string("Cache-Control","no-store"))
                .andExpect(jsonPath("$.titulo").value("Comunicado 4")).andExpect(jsonPath("$.contenido").value("Contenido 4"))
                .andExpect(jsonPath("$.remitente").value("Docente Prueba"))
                .andExpect(jsonPath("$.publicadoEn").exists()).andExpect(jsonPath("$.periodoId").doesNotExist())
                .andExpect(jsonPath("$.passwordHash").doesNotExist()).andExpect(jsonPath("$.notificaciones").doesNotExist());
        for(String path:new String[]{general()+"/4",list(102)+"/5",list(202),list(999),list(102)+"/999",general()+"/6",general()+"/7"}) {
            mvc.perform(get(path).with(student("1"))).andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.codigo").value("NO_DISPONIBLE"));
        }
        mvc.perform(get(list(202)+"/4").with(student("2"))).andExpect(status().isNotFound());
        mvc.perform(get(list(102)).with(student("3"))).andExpect(status().isNotFound())
                .andExpect(jsonPath("$.codigo").value("SIN_PERFIL"));
    }

    @Test void enrollmentPeriodSelectsSectionWithoutInventingNoticePeriodOrDateRange() throws Exception {
        // 2025 and 2026 use the same section: comunicado has no period FK, so the audience is identical.
        String old=mvc.perform(get(list(101)).with(student("1"))).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String current=mvc.perform(get(list(102)).with(student("1"))).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertEquals(old,current);
        mvc.perform(get(list(103)).with(student("1"))).andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3)).andExpect(jsonPath("$[0].id").value(5));
    }

    @Test void publicationExpirationAndActiveStateAreRecheckedOnDetail() throws Exception {
        for(int id:new int[]{9,10,11,12}) {
            mvc.perform(get(general()+"/"+id).with(student("1"))).andExpect(status().isNotFound());
            mvc.perform(get(list(102)+"/"+id).with(student("1"))).andExpect(status().isNotFound());
        }
        // DATETIME rounds fractional seconds; use a definitely expired instant.
        jdbc.update("UPDATE comunicado SET fecha_vencimiento=DATEADD('SECOND',-1,CURRENT_TIMESTAMP) WHERE id=2");
        mvc.perform(get(general()+"/2").with(student("1"))).andExpect(status().isNotFound());
        jdbc.update("UPDATE comunicado SET publicado_en=DATEADD('SECOND',-1,CURRENT_TIMESTAMP) WHERE id=1");
        mvc.perform(get(general()+"/1").with(student("1"))).andExpect(status().isOk());
        jdbc.update("UPDATE comunicado SET activo=FALSE WHERE id=1");
        mvc.perform(get(general()+"/1").with(student("1"))).andExpect(status().isNotFound());
    }

    @Test void protectsAllRoutesAndChecksCurrentRoleAndActiveAccount() throws Exception {
        for(String path:new String[]{general(),general()+"/1",list(102),list(102)+"/4"}) {
            mvc.perform(get(path)).andExpect(status().isUnauthorized());
            mvc.perform(get(path).header("Authorization","Bearer invalid")).andExpect(status().isUnauthorized());
            for(String role:new String[]{"DOCENTE","APODERADO"}) {
                mvc.perform(get(path).with(jwt().jwt(j->j.subject("1"))
                        .authorities(new SimpleGrantedAuthority("ROLE_"+role)))).andExpect(status().isForbidden());
            }
            jdbc.update("UPDATE usuario SET activo=FALSE WHERE id=1");
            mvc.perform(get(path).with(student("1"))).andExpect(status().isForbidden());
            jdbc.update("UPDATE usuario SET activo=TRUE WHERE id=1");
        }
        jdbc.update("DELETE FROM usuario_rol WHERE usuario_id=1");
        mvc.perform(get(general()).with(student("1"))).andExpect(status().isForbidden());
    }

    @Test void noNotificationsAreLeakedAndEmptyFeedDoesNotCreateOrMarkData() throws Exception {
        jdbc.update("UPDATE comunicado SET activo=FALSE");
        mvc.perform(get(general()).with(student("1"))).andExpect(status().isOk()).andExpect(content().json("[]"));
        mvc.perform(get(list(102)).with(student("1"))).andExpect(status().isOk()).andExpect(content().json("[]"));
        assertEquals(12,jdbc.queryForObject("SELECT COUNT(*) FROM comunicado",Integer.class));
        assertEquals(2,jdbc.queryForObject("SELECT COUNT(*) FROM notificacion WHERE leido_en IS NULL",Integer.class));
    }

    @Test void realLoginTokenCanReadOwnAudienceAndNoWritesExist() throws Exception {
        String password=java.util.UUID.randomUUID().toString();
        jdbc.update("UPDATE usuario SET password_hash=? WHERE id=1",passwords.encode(password));
        String login=mvc.perform(post("/api/auth/login").contentType("application/json")
                .content(mapper.writeValueAsString(new LoginRequest("fixture1",password))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String token=mapper.readTree(login).path("accessToken").asText();
        mvc.perform(get(general()).header("Authorization","Bearer "+token)).andExpect(status().isOk());
        mvc.perform(get(list(102)+"/4").header("Authorization","Bearer "+token)).andExpect(status().isOk());
        mvc.perform(get(list(202)+"/5").header("Authorization","Bearer "+token)).andExpect(status().isNotFound());
        mvc.perform(post(general()).with(student("1"))).andExpect(status().isMethodNotAllowed());
        mvc.perform(put(list(102)+"/4").with(student("1"))).andExpect(status().isMethodNotAllowed());
    }
}
