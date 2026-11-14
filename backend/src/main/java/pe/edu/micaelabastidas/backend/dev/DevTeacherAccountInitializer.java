package pe.edu.micaelabastidas.backend.dev;

import java.nio.charset.StandardCharsets;
import java.util.Objects;
import java.util.Optional;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.micaelabastidas.backend.entity.Docente;
import pe.edu.micaelabastidas.backend.entity.Rol;
import pe.edu.micaelabastidas.backend.entity.Usuario;
import pe.edu.micaelabastidas.backend.repository.DocenteRepository;
import pe.edu.micaelabastidas.backend.repository.RolRepository;
import pe.edu.micaelabastidas.backend.repository.UsuarioRepository;

@Component
@Profile("dev")
@ConditionalOnProperty(
        name = "app.dev.teacher-seed-enabled",
        havingValue = "true",
        matchIfMissing = false)
public class DevTeacherAccountInitializer implements ApplicationRunner {
    private static final String USERNAME = "docente01";
    private static final String DOCUMENT = "DOCENTE-TEST-0001";
    private static final String SPECIALTY = "Matemática";

    private final UsuarioRepository usuarios;
    private final RolRepository roles;
    private final DocenteRepository docentes;
    private final PasswordEncoder passwords;
    private final Environment environment;

    public DevTeacherAccountInitializer(
            UsuarioRepository usuarios,
            RolRepository roles,
            DocenteRepository docentes,
            PasswordEncoder passwords,
            Environment environment) {
        this.usuarios = usuarios;
        this.roles = roles;
        this.docentes = docentes;
        this.passwords = passwords;
        this.environment = environment;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments arguments) {
        Optional<Usuario> existing = usuarios.findByNombreUsuario(USERNAME);
        if (existing.isPresent()) {
            if (isSeededTeacher(existing.get())) {
                return;
            }
            throw new IllegalStateException(
                    "El usuario docente01 ya existe con datos incompatibles; no se modificó.");
        }

        String password = environment.getProperty("DEV_TEACHER_PASSWORD");
        if (password == null
                || password.isBlank()
                || password.length() < 12
                || password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new IllegalStateException(
                    "Configura DEV_TEACHER_PASSWORD (mínimo 12 caracteres y máximo 72 bytes UTF-8).");
        }

        Rol role = roles.findByNombre("DOCENTE").orElseThrow(
                () -> new IllegalStateException(
                        "Debe existir el rol DOCENTE del script SQL."));
        if (docentes.existsByDocumentoIdentidad(DOCUMENT)) {
            throw new IllegalStateException(
                    "El documento de prueba ya está asociado a otro docente; no se modificó ningún usuario.");
        }

        Usuario usuario = new Usuario();
        usuario.setNombreUsuario(USERNAME);
        usuario.setPasswordHash(passwords.encode(password));
        usuario.setNombres("Docente");
        usuario.setApellidos("Prueba");
        usuario.setActivo(true);
        usuario.getRoles().add(role);
        Usuario savedUser = usuarios.save(usuario);

        Docente docente = new Docente();
        docente.setUsuario(savedUser);
        docente.setDocumentoIdentidad(DOCUMENT);
        docente.setEspecialidad(SPECIALTY);
        docentes.save(docente);
    }

    private boolean isSeededTeacher(Usuario usuario) {
        if (!usuario.isActivo()
                || usuario.getRoles().size() != 1
                || usuario.getRoles().stream().noneMatch(
                        role -> "DOCENTE".equals(role.getNombre()))) {
            return false;
        }
        return docentes.findByUsuarioId(usuario.getId())
                .filter(docente -> docente.getUsuario() != null
                        && Objects.equals(docente.getUsuario().getId(), usuario.getId())
                        && DOCUMENT.equals(docente.getDocumentoIdentidad())
                        && SPECIALTY.equals(docente.getEspecialidad()))
                .isPresent();
    }
}
