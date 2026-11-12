package pe.edu.micaelabastidas.backend.student;

import java.util.Map;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartHttpServletRequest;

@RestController
@RequestMapping("/api/estudiante/matriculas/{matriculaId}/tareas/{tareaId}/entrega")
public class StudentSubmissionController {
    private final StudentSubmissionService service;
    public StudentSubmissionController(StudentSubmissionService service) { this.service=service; }

    @PostMapping(consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<StudentSubmissionService.Delivery> submit(@AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId,@PathVariable long tareaId,
            @RequestParam(required=false) String comentario,@RequestParam(required=false) MultipartFile archivo,
            MultipartHttpServletRequest request) {
        if (request.getMultiFileMap().values().stream().mapToInt(java.util.List::size).sum()>1
                || request.getMultiFileMap().keySet().stream().anyMatch(name -> !name.equals("archivo")))
            throw new StudentSubmissionService.Rejected("ARCHIVO_INVALIDO",400);
        return ResponseEntity.status(201).cacheControl(CacheControl.noStore())
                .body(service.submit(Long.parseLong(jwt.getSubject()),matriculaId,tareaId,comentario,archivo));
    }
    @GetMapping
    public ResponseEntity<StudentSubmissionService.Delivery> detail(@AuthenticationPrincipal Jwt jwt,
            @PathVariable long matriculaId,@PathVariable long tareaId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(service.detail(Long.parseLong(jwt.getSubject()),matriculaId,tareaId));
    }
    @GetMapping("/archivo")
    public ResponseEntity<byte[]> download(@AuthenticationPrincipal Jwt jwt,@PathVariable long matriculaId,@PathVariable long tareaId) {
        var file=service.download(Long.parseLong(jwt.getSubject()),matriculaId,tareaId);
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).contentType(MediaType.parseMediaType(file.contentType()))
                .header("Content-Disposition",ContentDisposition.attachment().filename(file.filename()).build().toString())
                .header("X-Content-Type-Options","nosniff").body(file.bytes());
    }
    @ExceptionHandler(StudentSubmissionService.Rejected.class)
    public ResponseEntity<Map<String,String>> rejected(StudentSubmissionService.Rejected e) {
        return ResponseEntity.status(e.status).cacheControl(CacheControl.noStore())
                .body(Map.of("codigo",e.code,"mensaje","No se pudo completar la operación de entrega."));
    }
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<Map<String,String>> oversized() {
        return ResponseEntity.status(413).cacheControl(CacheControl.noStore()).body(Map.of("codigo","ARCHIVO_GRANDE","mensaje","El archivo supera el límite permitido."));
    }
}
