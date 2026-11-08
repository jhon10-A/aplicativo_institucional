package pe.edu.micaelabastidas.backend;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;
import java.util.Map;
import org.springframework.core.env.SystemEnvironmentPropertySource;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.boot.test.context.ConfigDataApplicationContextInitializer;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import static org.junit.jupiter.api.Assertions.*;

class LocalConfigurationTests {
    @TempDir Path temporaryDirectory;

    @Test
    @EnabledIfEnvironmentVariable(named = "LOCAL_ENV_PROCESS_TEST", matches = "true")
    void readsPowerShellEnvironmentWithoutStartingDatabase() throws Exception {
        Path local = temporaryDirectory.resolve("process-local.properties");
        Files.writeString(local, "spring.datasource.username=local-marker\napp.test.fallback=retained\n");
        new ApplicationContextRunner()
                .withInitializer(new ConfigDataApplicationContextInitializer())
                .withPropertyValues("spring.config.location=classpath:/application.properties",
                        "spring.config.import=" + local.toUri())
                .run(context -> {
                    assertNull(context.getStartupFailure());
                    var env = context.getEnvironment();
                    assertEquals("env-fixture-user", env.getProperty("spring.datasource.username"));
                    assertEquals("fixture-only-not-a-secret", env.getProperty("spring.datasource.password"));
                    assertEquals("jdbc:mysql://127.0.0.1:1/unused", env.getProperty("spring.datasource.url"));
                    assertEquals("fixture-only-not-a-key", env.getProperty("JWT_SECRET_BASE64"));
                    assertEquals("http://localhost:18091", env.getProperty("app.cors.allowed-origin"));
                    assertEquals(1800L, env.getProperty("app.jwt.ttl-seconds", Long.class));
                    assertEquals(18091, env.getProperty("server.port", Integer.class));
                    assertEquals("retained", env.getProperty("app.test.fallback"));
                    assertEquals("validate", env.getProperty("spring.jpa.hibernate.ddl-auto"));
                    assertFalse(context.containsBean("dataSource"));
                    assertFalse(context.containsBean("entityManagerFactory"));
                });
    }

    @Test
    void processEnvironmentOverridesLocalFileWithoutStartingDatabase() throws Exception {
        Path local = temporaryDirectory.resolve("migration.properties");
        Files.writeString(local, "spring.datasource.username=local-marker\napp.test.fallback=retained\n");
        new ApplicationContextRunner()
                .withInitializer(context -> context.getEnvironment().getPropertySources().replace(
                        "systemEnvironment", new SystemEnvironmentPropertySource("systemEnvironment", Map.of(
                                "SPRING_DATASOURCE_USERNAME", "environment-marker",
                                "JWT_SECRET_BASE64", "configuration-marker-only",
                                "APP_JWT_TTL_SECONDS", "1800"))))
                .withInitializer(new ConfigDataApplicationContextInitializer())
                .withPropertyValues("spring.config.location=classpath:/application.properties",
                        "spring.config.import=" + local.toUri())
                .run(context -> {
                    assertNull(context.getStartupFailure());
                    var env = context.getEnvironment();
                    assertTrue("environment-marker".equals(env.getProperty("spring.datasource.username")));
                    assertTrue("configuration-marker-only".equals(env.getProperty("JWT_SECRET_BASE64")));
                    assertEquals(1800L, env.getProperty("app.jwt.ttl-seconds", Long.class));
                    assertEquals("retained", env.getProperty("app.test.fallback"));
                    assertFalse(context.containsBean("dataSource"));
                });
    }

    @Test
    void importsLocalConfigurationWithoutStartingApplicationOrDatabase() throws Exception {
        Properties shared = new Properties();
        try (InputStream input = getClass().getResourceAsStream("/application.properties")) {
            assertNotNull(input);
            shared.load(input);
        }
        assertEquals("optional:file:./config/application-local.properties",
                shared.getProperty("spring.config.import"));
        Path local = temporaryDirectory.resolve("application-local.properties");
        Files.writeString(local, "app.test.local-marker=loaded\n");
        new ApplicationContextRunner()
                .withInitializer(context -> context.getEnvironment().getPropertySources().replace(
                        "systemEnvironment", new SystemEnvironmentPropertySource("systemEnvironment", Map.of())))
                .withInitializer(new ConfigDataApplicationContextInitializer())
                .withPropertyValues("spring.config.location=classpath:/application.properties",
                        "spring.config.import=" + local.toUri())
                .run(context -> {
                    assertNull(context.getStartupFailure());
                    var env = context.getEnvironment();
                    assertEquals("loaded", env.getProperty("app.test.local-marker"));
                    assertEquals("validate", env.getProperty("spring.jpa.hibernate.ddl-auto"));
                    assertEquals("com.mysql.cj.jdbc.Driver", env.getProperty("spring.datasource.driver-class-name"));
                    assertEquals("jdbc:mysql://localhost:3307/db_institucional", env.getProperty("spring.datasource.url"));
                    assertFalse(context.containsBean("dataSource"));
                    assertFalse(context.containsBean("devAccountInitializer"));
                });
    }
}
