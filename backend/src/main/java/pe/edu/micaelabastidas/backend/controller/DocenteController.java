package pe.edu.micaelabastidas.backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import pe.edu.micaelabastidas.backend.entity.Docente;
import pe.edu.micaelabastidas.backend.service.DocenteService;

import java.util.List;

@RestController
@RequestMapping("/api/docentes")
public class DocenteController {

    @Autowired
    private DocenteService docenteService;

    @GetMapping
    public List<Docente> listarDocentes() {
        return docenteService.obtenerTodos();
    }

    @PostMapping
    public ResponseEntity<Docente> registrarDocente(@RequestBody Docente docente) {
        Docente nuevoDocente = docenteService.guardarDocente(docente);
        return ResponseEntity.ok(nuevoDocente);
    }
}
