package pe.edu.micaelabastidas.backend.student;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

/** Private storage: filenames supplied by the client never become filesystem paths. */
@Component
public class SubmissionFiles {
    public static final int MAX_BYTES = 5 * 1024 * 1024;
    private static final String PREFIX = "urn:entrega:";
    private static final Map<String, String> TYPES = Map.of(
            "pdf", "application/pdf", "png", "image/png", "jpg", "image/jpeg", "jpeg", "image/jpeg", "txt", "text/plain");
    private final Path root;
    public SubmissionFiles(@Value("${app.submissions.storage:./storage/entregas}") String root) {
        this.root = Path.of(root).toAbsolutePath().normalize();
    }
    public record Upload(byte[] bytes, String extension) {}
    public record Download(byte[] bytes, String contentType, String filename) {}

    public Upload validate(MultipartFile file) {
        if (file == null) return null;
        if (file.getSize() > MAX_BYTES) throw new StudentSubmissionService.Rejected("ARCHIVO_GRANDE", 413);
        String name = file.getOriginalFilename();
        if (file.isEmpty() || name == null || name.length() > 180 || name.contains("/") || name.contains("\\")
                || name.chars().anyMatch(c -> Character.isISOControl(c)) || !name.contains(".")) invalid();
        String extension = name.substring(name.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT);
        String expected = TYPES.get(extension);
        if (expected == null || !expected.equalsIgnoreCase(file.getContentType())) invalid();
        try {
            byte[] bytes;
            try (var stream = file.getInputStream()) { bytes = stream.readNBytes(MAX_BYTES + 1); }
            if (bytes.length > MAX_BYTES) throw new StudentSubmissionService.Rejected("ARCHIVO_GRANDE", 413);
            boolean valid = switch (extension) {
                case "pdf" -> bytes.length >= 5 && new String(bytes, 0, 5, StandardCharsets.US_ASCII).equals("%PDF-");
                case "png" -> bytes.length >= 8 && java.util.Arrays.equals(java.util.Arrays.copyOf(bytes, 8),
                        new byte[] {(byte)137,80,78,71,13,10,26,10});
                case "jpg", "jpeg" -> bytes.length >= 3 && (bytes[0]&255)==255 && (bytes[1]&255)==216 && (bytes[2]&255)==255;
                case "txt" -> {
                    String text = StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
                            .onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString();
                    yield !text.isEmpty() && text.chars().noneMatch(c -> Character.isISOControl(c) && c != '\n' && c != '\r' && c != '\t');
                }
                default -> false;
            };
            if (!valid) invalid();
            return new Upload(bytes, extension);
        } catch (java.nio.charset.CharacterCodingException e) { invalid(); return null; }
        catch (IOException e) { throw new StudentSubmissionService.Rejected("ARCHIVO_NO_DISPONIBLE", 503); }
    }

    private static void invalid() { throw new StudentSubmissionService.Rejected("ARCHIVO_INVALIDO", 400); }
    public static boolean managed(String reference) {
        return reference != null && reference.matches("urn:entrega:[0-9a-f-]{36}\\.(pdf|png|jpg|jpeg|txt)");
    }
    private Path path(String reference) {
        if (!managed(reference)) throw new StudentSubmissionService.Rejected("NO_DISPONIBLE", 404);
        Path path = root.resolve(reference.substring(PREFIX.length())).normalize();
        for (Path ancestor = root; ancestor != null; ancestor = ancestor.getParent()) {
            if (Files.isSymbolicLink(ancestor)) throw new StudentSubmissionService.Rejected("NO_DISPONIBLE", 404);
        }
        if (!path.getParent().equals(root) || Files.isSymbolicLink(path))
            throw new StudentSubmissionService.Rejected("NO_DISPONIBLE", 404);
        return path;
    }
    public String write(Upload upload) {
        String reference = PREFIX + UUID.randomUUID() + "." + upload.extension();
        Path path = path(reference);
        try {
            Files.createDirectories(root);
            Files.write(path, upload.bytes(), StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
            return reference;
        } catch (IOException e) {
            delete(reference);
            throw new StudentSubmissionService.Rejected("ARCHIVO_NO_DISPONIBLE", 503);
        }
    }
    public void delete(String reference) {
        try { Files.deleteIfExists(path(reference)); } catch (IOException | RuntimeException ignored) { /* No paths or contents logged. */ }
    }
    public Download read(String reference) {
        Path path = path(reference);
        try {
            if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS) || Files.size(path) > MAX_BYTES)
                throw new StudentSubmissionService.Rejected("NO_DISPONIBLE", 404);
            String extension = reference.substring(reference.lastIndexOf('.') + 1);
            try (var stream = Files.newInputStream(path, LinkOption.NOFOLLOW_LINKS)) {
                byte[] bytes=stream.readNBytes(MAX_BYTES+1);
                if (bytes.length>MAX_BYTES) throw new StudentSubmissionService.Rejected("NO_DISPONIBLE",404);
                return new Download(bytes, TYPES.get(extension), "entrega." + extension);
            }
        } catch (IOException e) { throw new StudentSubmissionService.Rejected("NO_DISPONIBLE", 404); }
    }
}
