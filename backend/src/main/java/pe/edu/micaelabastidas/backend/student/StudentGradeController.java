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
public class StudentGradeController {
    private final StudentGradeService service;
    public StudentGradeController(StudentGradeService service) { this.service = service; }

    @GetMapping({"/calificaciones", "/cursos/{asignacionId}/calificaciones"})
    public ResponseEntity<List<StudentGradeService.Grade>> grades(@AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId, @PathVariable(required = false) Long asignacionId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(service.grades(Long.parseLong(jwt.getSubject()), matriculaId, asignacionId));
    }

    @GetMapping("/calificaciones/{calificacionId}")
    public ResponseEntity<StudentGradeService.Grade> grade(@AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId, @PathVariable long calificacionId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(service.grade(Long.parseLong(jwt.getSubject()), matriculaId, calificacionId));
    }

    @ExceptionHandler({StudentGradeService.MissingGrade.class, StudentCourseService.MissingCourse.class})
    public ResponseEntity<Map<String,String>> missing() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo", "NO_DISPONIBLE", "mensaje", "La matrícula, el curso o la calificación no está disponible."));
    }

    @ExceptionHandler(StudentProfileService.MissingProfile.class)
    public ResponseEntity<Map<String,String>> missingProfile() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo", "SIN_PERFIL", "mensaje", "No tienes un perfil de estudiante registrado."));
    }
}
