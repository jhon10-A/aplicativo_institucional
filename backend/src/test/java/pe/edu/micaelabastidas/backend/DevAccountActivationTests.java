package pe.edu.micaelabastidas.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import pe.edu.micaelabastidas.backend.dev.DevAccountInitializer;
import pe.edu.micaelabastidas.backend.repository.UsuarioRepository;
import pe.edu.micaelabastidas.backend.repository.RolRepository;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class DevAccountActivationTests {
    private final ApplicationContextRunner runner = new ApplicationContextRunner()
            .withUserConfiguration(DevAccountInitializer.class)
            .withBean(UsuarioRepository.class, () -> mock(UsuarioRepository.class))
            .withBean(RolRepository.class, () -> mock(RolRepository.class))
            .withBean(PasswordEncoder.class, () -> new BCryptPasswordEncoder(4));

    @Test
    void enabledFlagWithoutDevProfileDoesNotActivateInitializer() {
        runner.withPropertyValues("app.dev.seed-enabled=true")
                .run(context -> assertThat(context).doesNotHaveBean(DevAccountInitializer.class));
    }

    @Test
    void devProfileWithoutExplicitFlagDoesNotActivateInitializer() {
        runner.withInitializer(context -> context.getEnvironment().setActiveProfiles("dev"))
                .run(context -> assertThat(context).doesNotHaveBean(DevAccountInitializer.class));
    }

    @Test
    void bothDevProfileAndExplicitFlagAreRequired() {
        runner.withInitializer(context -> context.getEnvironment().setActiveProfiles("dev"))
                .withPropertyValues("app.dev.seed-enabled=true")
                .run(context -> assertThat(context).hasSingleBean(DevAccountInitializer.class));
    }
}
