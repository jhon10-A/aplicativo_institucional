package pe.edu.micaelabastidas.backend;

import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import pe.edu.micaelabastidas.backend.dev.DevAccountInitializer;
import pe.edu.micaelabastidas.backend.entity.Rol;
import pe.edu.micaelabastidas.backend.entity.Usuario;
import pe.edu.micaelabastidas.backend.repository.RolRepository;
import pe.edu.micaelabastidas.backend.repository.UsuarioRepository;
import org.mockito.ArgumentCaptor;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class DevAccountInitializerTests {
    @Test
    void createsOnlyStudentWithBcryptUsingMocks() {
        UsuarioRepository usuarios = mock(UsuarioRepository.class);
        RolRepository roles = mock(RolRepository.class);
        Rol estudiante = new Rol();
        estudiante.setNombre("ESTUDIANTE");
        when(roles.findByNombre("ESTUDIANTE")).thenReturn(Optional.of(estudiante));
        MockEnvironment env = new MockEnvironment().withProperty("DEV_ACCOUNT_USERNAME", "aislado")
                .withProperty("DEV_ACCOUNT_PASSWORD", "isolated-dev-password");
        BCryptPasswordEncoder passwords = new BCryptPasswordEncoder(4);
        new DevAccountInitializer(usuarios, roles, passwords, env).run(new DefaultApplicationArguments());
        ArgumentCaptor<Usuario> saved = ArgumentCaptor.forClass(Usuario.class);
        verify(usuarios).save(saved.capture());
        Usuario usuario = saved.getValue();
        assertTrue(passwords.matches("isolated-dev-password", usuario.getPasswordHash()));
        assertEquals(1, usuario.getRoles().size());
        assertTrue(usuario.getRoles().contains(estudiante));
    }

    @Test
    void neverOverwritesExistingAccount() {
        UsuarioRepository usuarios = mock(UsuarioRepository.class);
        RolRepository roles = mock(RolRepository.class);
        when(usuarios.findByNombreUsuario("existente")).thenReturn(Optional.of(new Usuario()));
        MockEnvironment env = new MockEnvironment().withProperty("DEV_ACCOUNT_USERNAME", "existente");
        new DevAccountInitializer(usuarios, roles, new BCryptPasswordEncoder(4), env)
                .run(new DefaultApplicationArguments());
        verify(usuarios, never()).save(any());
        verifyNoInteractions(roles);
    }

    @Test
    void missingCredentialsOrRoleNeverWrite() {
        UsuarioRepository usuarios = mock(UsuarioRepository.class);
        RolRepository roles = mock(RolRepository.class);
        MockEnvironment env = new MockEnvironment();
        DevAccountInitializer initializer = new DevAccountInitializer(usuarios, roles, new BCryptPasswordEncoder(4), env);
        assertThrows(IllegalStateException.class, () -> initializer.run(new DefaultApplicationArguments()));
        env.withProperty("DEV_ACCOUNT_USERNAME", "aislado");
        assertThrows(IllegalStateException.class, () -> initializer.run(new DefaultApplicationArguments()));
        env.withProperty("DEV_ACCOUNT_PASSWORD", "isolated-dev-password");
        assertThrows(IllegalStateException.class, () -> initializer.run(new DefaultApplicationArguments()));
        verify(usuarios, never()).save(any());
    }
}
