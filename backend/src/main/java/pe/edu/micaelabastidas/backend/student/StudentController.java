package pe.edu.micaelabastidas.backend.student;

import java.util.List;
import java.util.Map;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/estudiante")
public class StudentController {
    private final StudentProfileService service;
    private final StudentCourseService courses;
    public StudentController(StudentProfileService service, StudentCourseService courses) {
        this.service = service;
        this.courses = courses;
    }

    @GetMapping("/matriculas/{matriculaId}/cursos")
    public ResponseEntity<List<StudentCourseService.Course>> courses(@AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(courses.courses(Long.parseLong(jwt.getSubject()), matriculaId));
    }

    @GetMapping("/matriculas/{matriculaId}/cursos/{asignacionId}")
    public ResponseEntity<StudentCourseService.Course> course(@AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId, @PathVariable long asignacionId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(courses.course(Long.parseLong(jwt.getSubject()), matriculaId, asignacionId));
    }

    @ExceptionHandler(StudentCourseService.MissingCourse.class)
    public ResponseEntity<Map<String, String>> missingCourse() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo", "NO_DISPONIBLE", "mensaje", "La matrícula o el curso no está disponible."));
    }

    @GetMapping("/perfil")
    public ResponseEntity<StudentProfileService.Profile> profile(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(service.profile(Long.parseLong(jwt.getSubject())));
    }

    @GetMapping("/matriculas")
    public ResponseEntity<List<StudentProfileService.Enrollment>> enrollments(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(service.enrollments(Long.parseLong(jwt.getSubject())));
    }

    @ExceptionHandler(StudentProfileService.MissingProfile.class)
    public ResponseEntity<Map<String, String>> missing() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo", "SIN_PERFIL", "mensaje", "No tienes un perfil de estudiante registrado."));
    }
}
