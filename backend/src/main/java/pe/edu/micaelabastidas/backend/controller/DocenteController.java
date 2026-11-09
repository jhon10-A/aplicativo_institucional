package pe.edu.micaelabastidas.backend.controller;

import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import pe.edu.micaelabastidas.backend.dto.DocenteRequestDto;
import pe.edu.micaelabastidas.backend.dto.DocenteResponseDto;
import pe.edu.micaelabastidas.backend.service.DocenteService;

import java.util.List;

@RestController
@RequestMapping("/api/docentes")
public class DocenteController {

    @Autowired
    private DocenteService docenteService;

    @GetMapping
    public ResponseEntity<List<DocenteResponseDto>> listarTodos() {
        return ResponseEntity.ok(docenteService.obtenerTodos());
    }

    @GetMapping("/{id}")
    public ResponseEntity<DocenteResponseDto> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(docenteService.obtenerPorId(id));
    }

    @PostMapping
    public ResponseEntity<DocenteResponseDto> crear(@Valid @RequestBody DocenteRequestDto dto) {
        DocenteResponseDto nuevo = docenteService.crear(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(nuevo);
    }

    @PutMapping("/{id}")
    public ResponseEntity<DocenteResponseDto> actualizar(@PathVariable Long id, @Valid @RequestBody DocenteRequestDto dto) {
        return ResponseEntity.ok(docenteService.actualizar(id, dto));
    }

    @PatchMapping("/{id}/estado")
    public ResponseEntity<Void> cambiarEstado(@PathVariable Long id, @RequestParam boolean activo) {
        docenteService.cambiarEstado(id, activo);
        return ResponseEntity.noContent().build();
    }
}