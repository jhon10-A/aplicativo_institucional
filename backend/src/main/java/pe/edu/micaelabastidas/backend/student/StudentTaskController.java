package pe.edu.micaelabastidas.backend.student;

import java.util.List;
import java.util.Map;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/estudiante/matriculas/{matriculaId}")
public class StudentTaskController {
    private final StudentTaskService service;
    public StudentTaskController(StudentTaskService service) { this.service = service; }

    @GetMapping({"/tareas", "/cursos/{asignacionId}/tareas"})
    public ResponseEntity<List<StudentTaskService.Task>> tasks(@AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId, @PathVariable(required = false) Long asignacionId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(service.tasks(Long.parseLong(jwt.getSubject()), matriculaId, asignacionId));
    }

    @GetMapping("/tareas/{tareaId}")
    public ResponseEntity<StudentTaskService.Task> task(@AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId, @PathVariable long tareaId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(service.task(Long.parseLong(jwt.getSubject()), matriculaId, tareaId));
    }

    @ExceptionHandler({StudentTaskService.MissingTask.class, StudentCourseService.MissingCourse.class})
    public ResponseEntity<Map<String, String>> missing() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo", "NO_DISPONIBLE", "mensaje", "La matrícula, el curso o la tarea no está disponible."));
    }

    @ExceptionHandler(StudentProfileService.MissingProfile.class)
    public ResponseEntity<Map<String, String>> missingProfile() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo", "SIN_PERFIL", "mensaje", "No tienes un perfil de estudiante registrado."));
    }
}
