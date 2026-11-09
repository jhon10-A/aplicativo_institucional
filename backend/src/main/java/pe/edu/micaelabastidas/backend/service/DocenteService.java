package pe.edu.micaelabastidas.backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import pe.edu.micaelabastidas.backend.entity.Docente;
import pe.edu.micaelabastidas.backend.repository.DocenteRepository;

import java.util.List;

@Service
public class DocenteService {

    @Autowired
    private DocenteRepository docenteRepository;

    public List<Docente> obtenerTodos() {
        return docenteRepository.findAll();
    }

    public Docente guardarDocente(Docente docente) {
        return docenteRepository.save(docente);
    }

    public Docente buscarPorDocumento(String documento) {
        return docenteRepository.findByDocumentoIdentidad(documento);
    }
}