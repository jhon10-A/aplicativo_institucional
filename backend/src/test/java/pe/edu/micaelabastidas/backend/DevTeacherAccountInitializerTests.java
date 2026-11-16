package pe.edu.micaelabastidas.backend;

import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import pe.edu.micaelabastidas.backend.dev.DevTeacherAccountInitializer;
import pe.edu.micaelabastidas.backend.entity.Docente;
import pe.edu.micaelabastidas.backend.entity.Rol;
import pe.edu.micaelabastidas.backend.entity.Usuario;
import pe.edu.micaelabastidas.backend.repository.DocenteRepository;
import pe.edu.micaelabastidas.backend.repository.RolRepository;
import pe.edu.micaelabastidas.backend.repository.UsuarioRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class DevTeacherAccountInitializerTests {
    private static final String USERNAME = "docente01";
    private static final String DOCUMENT = "DOCENTE-TEST-0001";
    private static final String SPECIALTY = "Matemática";

    @Test
    void createsActiveTeacherWithBcryptAndLinkedProfile() {
        UsuarioRepository usuarios = mock(UsuarioRepository.class);
        RolRepository roles = mock(RolRepository.class);
        DocenteRepository docentes = mock(DocenteRepository.class);
        BCryptPasswordEncoder passwords = new BCryptPasswordEncoder(4);
        Rol docenteRole = role("DOCENTE");
        String password = UUID.randomUUID().toString();
        when(usuarios.findByNombreUsuario(USERNAME)).thenReturn(Optional.empty());
        when(roles.findByNombre("DOCENTE")).thenReturn(Optional.of(docenteRole));
        when(usuarios.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(docentes.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        initializer(usuarios, roles, docentes, passwords, password)
                .run(new DefaultApplicationArguments());

        var savedUser = org.mockito.ArgumentCaptor.forClass(Usuario.class);
        verify(usuarios).save(savedUser.capture());
        Usuario usuario = savedUser.getValue();
        assertEquals(USERNAME, usuario.getNombreUsuario());
        assertTrue(usuario.isActivo());
        assertEquals(1, usuario.getRoles().size());
        assertTrue(usuario.getRoles().contains(docenteRole));
        assertNotEquals(password, usuario.getPasswordHash());
        assertTrue(passwords.matches(password, usuario.getPasswordHash()));

        var savedProfile = org.mockito.ArgumentCaptor.forClass(Docente.class);
        verify(docentes).save(savedProfile.capture());
        Docente profile = savedProfile.getValue();
        assertSame(usuario, profile.getUsuario());
        assertEquals(DOCUMENT, profile.getDocumentoIdentidad());
        assertEquals(SPECIALTY, profile.getEspecialidad());
    }

    @Test
    void leavesAlreadyProvisionedAccountUntouchedWithoutPassword() {
        UsuarioRepository usuarios = mock(UsuarioRepository.class);
        RolRepository roles = mock(RolRepository.class);
        DocenteRepository docentes = mock(DocenteRepository.class);
        Usuario existingUser = new Usuario();
        existingUser.setNombreUsuario(USERNAME);
        existingUser.setActivo(true);
        existingUser.getRoles().add(role("DOCENTE"));
        Docente existingProfile = new Docente();
        existingProfile.setUsuario(existingUser);
        existingProfile.setDocumentoIdentidad(DOCUMENT);
        existingProfile.setEspecialidad(SPECIALTY);
        when(usuarios.findByNombreUsuario(USERNAME)).thenReturn(Optional.of(existingUser));
        when(docentes.findByUsuarioId(null)).thenReturn(Optional.of(existingProfile));

        initializer(usuarios, roles, docentes, new BCryptPasswordEncoder(4), null)
                .run(new DefaultApplicationArguments());

        verify(usuarios, never()).save(any());
        verify(docentes, never()).save(any());
        verifyNoInteractions(roles);
    }

    @Test
    void refusesToModifyAnExistingIncompatibleUsername() {
        UsuarioRepository usuarios = mock(UsuarioRepository.class);
        RolRepository roles = mock(RolRepository.class);
        DocenteRepository docentes = mock(DocenteRepository.class);
        Usuario existingUser = new Usuario();
        existingUser.setNombreUsuario(USERNAME);
        when(usuarios.findByNombreUsuario(USERNAME)).thenReturn(Optional.of(existingUser));

        assertThrows(
                IllegalStateException.class,
                () -> initializer(
                        usuarios, roles, docentes, new BCryptPasswordEncoder(4), null)
                        .run(new DefaultApplicationArguments()));

        verify(usuarios, never()).save(any());
        verify(docentes, never()).save(any());
        verifyNoInteractions(roles, docentes);
    }

    @Test
    void refusesDocumentCollisionWithoutSavingEitherRecord() {
        UsuarioRepository usuarios = mock(UsuarioRepository.class);
        RolRepository roles = mock(RolRepository.class);
        DocenteRepository docentes = mock(DocenteRepository.class);
        when(usuarios.findByNombreUsuario(USERNAME)).thenReturn(Optional.empty());
        when(roles.findByNombre("DOCENTE")).thenReturn(Optional.of(role("DOCENTE")));
        when(docentes.existsByDocumentoIdentidad(DOCUMENT)).thenReturn(true);

        assertThrows(
                IllegalStateException.class,
                () -> initializer(
                        usuarios,
                        roles,
                        docentes,
                        new BCryptPasswordEncoder(4),
                        UUID.randomUUID().toString())
                        .run(new DefaultApplicationArguments()));

        verify(usuarios, never()).save(any());
        verify(docentes, never()).save(any());
    }

    @Test
    void rejectsMissingShortOrOverlongPasswordWithoutSaving() {
        assertInvalidPassword(null);
        assertInvalidPassword("short");
        assertInvalidPassword("a".repeat(73));
    }

    @Test
    void refusesToCreateAccountWhenTeacherRoleIsMissing() {
        UsuarioRepository usuarios = mock(UsuarioRepository.class);
        RolRepository roles = mock(RolRepository.class);
        DocenteRepository docentes = mock(DocenteRepository.class);
        when(usuarios.findByNombreUsuario(USERNAME)).thenReturn(Optional.empty());
        when(roles.findByNombre("DOCENTE")).thenReturn(Optional.empty());

        assertThrows(
                IllegalStateException.class,
                () -> initializer(
                        usuarios,
                        roles,
                        docentes,
                        new BCryptPasswordEncoder(4),
                        UUID.randomUUID().toString())
                        .run(new DefaultApplicationArguments()));

        verify(usuarios, never()).save(any());
        verify(docentes, never()).save(any());
    }

    private static void assertInvalidPassword(String password) {
        UsuarioRepository usuarios = mock(UsuarioRepository.class);
        RolRepository roles = mock(RolRepository.class);
        DocenteRepository docentes = mock(DocenteRepository.class);
        when(usuarios.findByNombreUsuario(USERNAME)).thenReturn(Optional.empty());
        MockEnvironment environment = new MockEnvironment();
        if (password != null) {
            environment.setProperty("DEV_TEACHER_PASSWORD", password);
        }

        assertThrows(
                IllegalStateException.class,
                () -> new DevTeacherAccountInitializer(
                        usuarios, roles, docentes, new BCryptPasswordEncoder(4), environment)
                        .run(new DefaultApplicationArguments()));

        verify(usuarios, never()).save(any());
        verify(docentes, never()).save(any());
        verifyNoInteractions(roles);
    }

    private static DevTeacherAccountInitializer initializer(
            UsuarioRepository usuarios,
            RolRepository roles,
            DocenteRepository docentes,
            BCryptPasswordEncoder passwords,
            String password) {
        MockEnvironment environment = new MockEnvironment();
        if (password != null) {
            environment.setProperty("DEV_TEACHER_PASSWORD", password);
        }
        return new DevTeacherAccountInitializer(
                usuarios, roles, docentes, passwords, environment);
    }

    private static Rol role(String name) {
        Rol role = new Rol();
        role.setNombre(name);
        return role;
    }
}
