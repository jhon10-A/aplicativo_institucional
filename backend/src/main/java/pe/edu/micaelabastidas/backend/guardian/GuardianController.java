package pe.edu.micaelabastidas.backend.guardian;

import java.util.List;
import java.util.Map;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/apoderado")
public class GuardianController {
    private final GuardianChildrenService children;

    public GuardianController(GuardianChildrenService children) {
        this.children = children;
    }

    @GetMapping("/hijos")
    public ResponseEntity<List<GuardianChildrenService.Child>> children(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(children.children(Long.parseLong(jwt.getSubject())));
    }

    @ExceptionHandler(GuardianAccess.NotGuardian.class)
    public ResponseEntity<Map<String, String>> notGuardian() {
        return ResponseEntity.status(403).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo", "SIN_PERFIL",
                        "mensaje", "No tienes un perfil de apoderado registrado."));
    }

    @ExceptionHandler(GuardianAccess.MissingChild.class)
    public ResponseEntity<Map<String, String>> missingChild() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo", "NO_DISPONIBLE", "mensaje", "El estudiante no está disponible."));
    }
}
