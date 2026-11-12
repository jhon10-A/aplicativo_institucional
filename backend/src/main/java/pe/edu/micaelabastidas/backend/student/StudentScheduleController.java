package pe.edu.micaelabastidas.backend.student;

import java.util.List;
import java.util.Map;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/estudiante/matriculas/{matriculaId}/horario")
public class StudentScheduleController {
    private final StudentScheduleService service;

    public StudentScheduleController(StudentScheduleService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<StudentScheduleService.Schedule>> schedule(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(service.schedule(Long.parseLong(jwt.getSubject()), matriculaId));
    }

    @ExceptionHandler(StudentScheduleService.MissingSchedule.class)
    public ResponseEntity<Map<String, String>> missingSchedule() {
        return ResponseEntity.status(404)
                .cacheControl(CacheControl.noStore())
                .body(Map.of(
                        "codigo", "NO_DISPONIBLE",
                        "mensaje", "La matrícula no está disponible."));
    }

    @ExceptionHandler(StudentProfileService.MissingProfile.class)
    public ResponseEntity<Map<String, String>> missingProfile() {
        return ResponseEntity.status(404)
                .cacheControl(CacheControl.noStore())
                .body(Map.of(
                        "codigo", "SIN_PERFIL",
                        "mensaje", "No tienes un perfil de estudiante registrado."));
    }
}
