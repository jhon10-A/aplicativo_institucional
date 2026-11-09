package pe.edu.micaelabastidas.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import pe.edu.micaelabastidas.backend.entity.Docente;

import java.util.Optional;

@Repository
public interface DocenteRepository extends JpaRepository<Docente, Long> {
    Optional<Docente> findByDni(String dni);
    boolean existsByDni(String dni);
}