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
public class StudentNoticeController {
    private final StudentNoticeService service;
    public StudentNoticeController(StudentNoticeService service) { this.service=service; }

    @GetMapping({"/comunicados","/matriculas/{matriculaId}/comunicados"})
    public ResponseEntity<List<StudentNoticeService.Notice>> notices(@AuthenticationPrincipal Jwt jwt,
            @PathVariable(required=false) Long matriculaId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(service.notices(Long.parseLong(jwt.getSubject()),matriculaId));
    }
    @GetMapping({"/comunicados/{comunicadoId}","/matriculas/{matriculaId}/comunicados/{comunicadoId}"})
    public ResponseEntity<StudentNoticeService.Notice> detail(@AuthenticationPrincipal Jwt jwt,
            @PathVariable(required=false) Long matriculaId,@PathVariable long comunicadoId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(service.detail(Long.parseLong(jwt.getSubject()),matriculaId,comunicadoId));
    }
    @ExceptionHandler(StudentNoticeService.MissingNotice.class)
    public ResponseEntity<Map<String,String>> missing() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo","NO_DISPONIBLE","mensaje","La matrícula o el comunicado no está disponible."));
    }
    @ExceptionHandler(StudentProfileService.MissingProfile.class)
    public ResponseEntity<Map<String,String>> missingProfile() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo","SIN_PERFIL","mensaje","No tienes un perfil de estudiante registrado."));
    }
}
