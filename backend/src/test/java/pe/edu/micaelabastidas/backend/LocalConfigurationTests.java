package pe.edu.micaelabastidas.backend;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Objects;
import java.util.Properties;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.ConfigDataApplicationContextInitializer;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import static org.junit.jupiter.api.Assertions.*;

class LocalConfigurationTests {
    @Test
    void importsLocalConfigurationWithoutStartingApplicationOrDatabase() {
        new ApplicationContextRunner()
                .withInitializer(new ConfigDataApplicationContextInitializer())
                .withPropertyValues("spring.config.location=classpath:/application.properties")
                .run(context -> {
                    assertNull(context.getStartupFailure());
                    var env = context.getEnvironment();
                    assertEquals("optional:file:./config/application-local.properties",
                            env.getProperty("spring.config.import"));
                    assertEquals("none", env.getProperty("spring.jpa.hibernate.ddl-auto"));
                    assertEquals("org.mariadb.jdbc.Driver", env.getProperty("spring.datasource.driver-class-name"));
                    Path local = Path.of("config", "application-local.properties");
                    if (Files.exists(local)) {
                        Properties expected = new Properties();
                        try (InputStream input = Files.newInputStream(local)) {
                            expected.load(input);
                        }
                        // Boolean assertions deliberately avoid exposing values on failure.
                        for (String key : new String[] {"spring.datasource.username", "spring.datasource.password"}) {
                            assertTrue(Objects.equals(expected.getProperty(key), env.getProperty(key)),
                                    "External local configuration must load without a profile");
                        }
                    }
                    assertFalse(context.containsBean("dataSource"));
                    assertFalse(context.containsBean("devAccountInitializer"));
                });
    }
}
