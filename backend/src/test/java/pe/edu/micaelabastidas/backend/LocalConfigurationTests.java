package pe.edu.micaelabastidas.backend;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.boot.test.context.ConfigDataApplicationContextInitializer;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import static org.junit.jupiter.api.Assertions.*;

class LocalConfigurationTests {
    @TempDir Path temporaryDirectory;

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
