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
    public StudentController(StudentProfileService service) { this.service = service; }

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
