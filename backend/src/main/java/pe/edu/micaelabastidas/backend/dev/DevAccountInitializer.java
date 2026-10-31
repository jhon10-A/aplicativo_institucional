package pe.edu.micaelabastidas.backend.dev;

import java.nio.charset.StandardCharsets;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.micaelabastidas.backend.entity.Rol;
import pe.edu.micaelabastidas.backend.entity.Usuario;
import pe.edu.micaelabastidas.backend.repository.RolRepository;
import pe.edu.micaelabastidas.backend.repository.UsuarioRepository;

@Component
@Profile("dev")
@ConditionalOnProperty(name = "app.dev.seed-enabled", havingValue = "true", matchIfMissing = false)
public class DevAccountInitializer implements ApplicationRunner {
    private final UsuarioRepository usuarios;
    private final RolRepository roles;
    private final PasswordEncoder passwords;
    private final Environment environment;

    public DevAccountInitializer(UsuarioRepository usuarios, RolRepository roles,
                                 PasswordEncoder passwords, Environment environment) {
        this.usuarios = usuarios;
        this.roles = roles;
        this.passwords = passwords;
        this.environment = environment;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments arguments) {
        String username = environment.getProperty("DEV_ACCOUNT_USERNAME");
        if (username == null || username.isBlank() || username.length() > 60) {
            throw new IllegalStateException("Configura DEV_ACCOUNT_USERNAME (1 a 60 caracteres)");
        }
        if (usuarios.findByNombreUsuario(username).isPresent()) { return; }
        String password = environment.getProperty("DEV_ACCOUNT_PASSWORD");
        if (password == null || password.isBlank() || password.length() < 12
                || password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new IllegalStateException("Configura DEV_ACCOUNT_PASSWORD (mínimo 12 caracteres, máximo 72 bytes UTF-8)");
        }
        Rol role = roles.findByNombre("ESTUDIANTE").orElseThrow(
                () -> new IllegalStateException("Debe existir el rol ESTUDIANTE del script SQL"));
        Usuario usuario = new Usuario();
        usuario.setNombreUsuario(username);
        usuario.setPasswordHash(passwords.encode(password));
        usuario.setNombres("Cuenta");
        usuario.setApellidos("Desarrollo");
        usuario.setActivo(true);
        usuario.getRoles().add(role);
        usuarios.save(usuario);
    }
}
