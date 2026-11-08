package pe.edu.micaelabastidas.backend.student;

import java.util.Map;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/estudiante/matriculas/{matriculaId}")
public class StudentAttendanceController {
    private final StudentAttendanceService service;
    public StudentAttendanceController(StudentAttendanceService service) { this.service=service; }

    @GetMapping({"/asistencias", "/cursos/{asignacionId}/asistencias"})
    public ResponseEntity<StudentAttendanceService.Page> attendance(@AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId,@PathVariable(required=false) Long asignacionId,
            @RequestParam(required=false) String desde,@RequestParam(required=false) String hasta) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(service.attendance(Long.parseLong(jwt.getSubject()),matriculaId,asignacionId,desde,hasta));
    }

    @GetMapping("/asistencias/{asistenciaId}")
    public ResponseEntity<StudentAttendanceService.Attendance> detail(@AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId,@PathVariable long asistenciaId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(service.detail(Long.parseLong(jwt.getSubject()),matriculaId,asistenciaId));
    }

    @ExceptionHandler(StudentAttendanceService.InvalidFilters.class)
    public ResponseEntity<Map<String,String>> invalidFilters() {
        return ResponseEntity.badRequest().cacheControl(CacheControl.noStore())
                .body(Map.of("codigo","FILTROS_INVALIDOS","mensaje","Usa fechas válidas AAAA-MM-DD con desde anterior o igual a hasta."));
    }
    @ExceptionHandler({StudentAttendanceService.MissingAttendance.class,StudentCourseService.MissingCourse.class})
    public ResponseEntity<Map<String,String>> missing() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo","NO_DISPONIBLE","mensaje","La matrícula, el curso o la asistencia no está disponible."));
    }
    @ExceptionHandler(StudentProfileService.MissingProfile.class)
    public ResponseEntity<Map<String,String>> missingProfile() {
        return ResponseEntity.status(404).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo","SIN_PERFIL","mensaje","No tienes un perfil de estudiante registrado."));
    }
}
