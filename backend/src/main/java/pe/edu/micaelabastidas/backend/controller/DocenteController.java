package pe.edu.micaelabastidas.backend.controller;

import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import pe.edu.micaelabastidas.backend.dto.*;
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

    @GetMapping("/perfil")
    public ResponseEntity<DocenteResponseDto> obtenerMiPerfil(Authentication authentication) {
        return ResponseEntity.ok(docenteService.obtenerPorNombreUsuario(authentication.getName()));
    }

    @GetMapping("/asignaciones")
    public ResponseEntity<List<AsignacionDocenteDto>> listarMisAsignaciones(Authentication authentication) {
        return ResponseEntity.ok(docenteService.obtenerMisAsignaciones(authentication.getName()));
    }

    @GetMapping("/asignaciones/{asignacionId}/estudiantes")
    public ResponseEntity<List<EstudianteSeccionDto>> listarEstudiantesPorAsignacion(
            Authentication authentication,
            @PathVariable Long asignacionId) {
        return ResponseEntity.ok(docenteService.obtenerEstudiantesDeAsignacion(authentication.getName(), asignacionId));
    }

    @PostMapping("/asignaciones/{asignacionId}/asistencias")
    public ResponseEntity<Void> registrarAsistencia(
            Authentication authentication,
            @PathVariable Long asignacionId,
            @Valid @RequestBody AsistenciaRequestDto dto) {
        docenteService.registrarAsistencia(authentication.getName(), asignacionId, dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @PostMapping("/asignaciones/{asignacionId}/calificaciones")
    public ResponseEntity<Void> registrarCalificacion(
            Authentication authentication,
            @PathVariable Long asignacionId,
            @Valid @RequestBody CalificacionRequestDto dto) {
        docenteService.registrarCalificacion(authentication.getName(), asignacionId, dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
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