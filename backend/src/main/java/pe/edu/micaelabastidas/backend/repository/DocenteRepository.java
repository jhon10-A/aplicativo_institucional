package pe.edu.micaelabastidas.backend.repository;


import pe.edu.micaelabastidas.backend.entity.Docente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DocenteRepository extends JpaRepository<Docente, Long> {
    
    // Método para buscar un docente por su documento de identidad
    Docente findByDocumentoIdentidad(String documentoIdentidad);
    
    // Método para buscar el perfil de docente asociado a un ID de usuario específico
    Docente findByUsuarioId(Long usuarioId);
}