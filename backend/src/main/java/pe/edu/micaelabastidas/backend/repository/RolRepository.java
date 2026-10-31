package pe.edu.micaelabastidas.backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.edu.micaelabastidas.backend.entity.Rol;

public interface RolRepository extends JpaRepository<Rol, Long> {
    Optional<Rol> findByNombre(String nombre);
}
