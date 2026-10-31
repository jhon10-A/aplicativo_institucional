package pe.edu.micaelabastidas.backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.edu.micaelabastidas.backend.entity.Usuario;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    Optional<Usuario> findByNombreUsuario(String nombreUsuario);
}
