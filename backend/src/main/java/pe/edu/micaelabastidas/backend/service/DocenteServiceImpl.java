package pe.edu.micaelabastidas.backend.service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.micaelabastidas.backend.dto.*;
import pe.edu.micaelabastidas.backend.entity.Docente;
import pe.edu.micaelabastidas.backend.entity.Usuario;
import pe.edu.micaelabastidas.backend.repository.DocenteRepository;
import pe.edu.micaelabastidas.backend.repository.UsuarioRepository;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class DocenteServiceImpl implements DocenteService {

    @Autowired
    private DocenteRepository docenteRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    public List<DocenteResponseDto> obtenerTodos() {
        return docenteRepository.findAll().stream()
                .map(this::convertirADto)
                .collect(Collectors.toList());
    }

    @Override
    public DocenteResponseDto obtenerPorId(Long id) {
        Docente docente = docenteRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Docente no encontrado con ID: " + id));
        return convertirADto(docente);
    }

    @Override
    public DocenteResponseDto obtenerPorNombreUsuario(String identificador) {
        Docente docente = docenteRepository.findByUsuarioNombreUsuario(identificador)
                .or(() -> {
                    try {
                        return docenteRepository.findByUsuarioId(Long.parseLong(identificador));
                    } catch (NumberFormatException e) {
                        return Optional.empty();
                    }
                })
                .orElseThrow(() -> new RuntimeException("Perfil docente no encontrado para: " + identificador));
        return convertirADto(docente);
    }

    @Override
    public DocenteResponseDto crear(DocenteRequestDto dto) {
        if (docenteRepository.existsByDocumentoIdentidad(dto.getDocumentoIdentidad())) {
            throw new RuntimeException("Ya existe un docente con el documento de identidad: " + dto.getDocumentoIdentidad());
        }
        if (docenteRepository.existsByUsuarioId(dto.getUsuarioId())) {
            throw new RuntimeException("El usuario ya tiene un perfil docente asignado");
        }

        Usuario usuario = usuarioRepository.findById(dto.getUsuarioId())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado con ID: " + dto.getUsuarioId()));

        Docente docente = new Docente();
        docente.setUsuario(usuario);
        docente.setDocumentoIdentidad(dto.getDocumentoIdentidad());
        docente.setEspecialidad(dto.getEspecialidad());

        Docente guardado = docenteRepository.save(docente);
        return convertirADto(guardado);
    }

    @Override
    public DocenteResponseDto actualizar(Long id, DocenteRequestDto dto) {
        Docente docente = docenteRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Docente no encontrado con ID: " + id));

        Usuario usuario = usuarioRepository.findById(dto.getUsuarioId())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado con ID: " + dto.getUsuarioId()));

        docente.setUsuario(usuario);
        docente.setDocumentoIdentidad(dto.getDocumentoIdentidad());
        docente.setEspecialidad(dto.getEspecialidad());

        Docente actualizado = docenteRepository.save(docente);
        return convertirADto(actualizado);
    }

    @Override
    public void cambiarEstado(Long id, boolean activo) {
        Docente docente = docenteRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Docente no encontrado con ID: " + id));

        Usuario usuario = docente.getUsuario();
        if (usuario == null) {
            throw new RuntimeException("El docente no tiene un usuario asociado");
        }

        usuario.setActivo(activo);
        usuarioRepository.save(usuario);
    }

    @Override
    @SuppressWarnings("unchecked")
    public List<AsignacionDocenteDto> obtenerMisAsignaciones(String identificador) {
        DocenteResponseDto docente = obtenerPorNombreUsuario(identificador);
        List<Object[]> rows = entityManager.createNativeQuery("""
            SELECT ad.id, c.id, c.nombre, c.descripcion,
                   p.id, p.nombre, p.activo,
                   s.id, s.nombre, g.nombre, g.nivel
            FROM asignacion_docente ad
            JOIN curso c ON c.id = ad.curso_id
            JOIN periodo_academico p ON p.id = ad.periodo_academico_id
            JOIN seccion s ON s.id = ad.seccion_id
            JOIN grado g ON g.id = s.grado_id
            WHERE ad.docente_id = :docenteId
            ORDER BY p.activo DESC, g.nivel, g.nombre, s.nombre, c.nombre
            """)
            .setParameter("docenteId", docente.getId())
            .getResultList();

        return rows.stream().map(r -> new AsignacionDocenteDto(
            ((Number) r[0]).longValue(),
            ((Number) r[1]).longValue(),
            (String) r[2],
            (String) r[3],
            ((Number) r[4]).longValue(),
            (String) r[5],
            Boolean.TRUE.equals(r[6]) || (r[6] instanceof Number n && n.intValue() == 1),
            ((Number) r[7]).longValue(),
            (String) r[8],
            (String) r[9],
            (String) r[10]
        )).toList();
    }

    @Override
    @SuppressWarnings("unchecked")
    public List<EstudianteSeccionDto> obtenerEstudiantesDeAsignacion(String identificador, Long asignacionId) {
        DocenteResponseDto docente = obtenerPorNombreUsuario(identificador);
        List<Object[]> rows = entityManager.createNativeQuery("""
            SELECT m.id, e.id, e.codigo_estudiante, u.nombres, u.apellidos, m.estado
            FROM asignacion_docente ad
            JOIN matricula m ON m.periodo_academico_id = ad.periodo_academico_id
                            AND m.seccion_id = ad.seccion_id
            JOIN estudiante e ON e.id = m.estudiante_id
            JOIN usuario u ON u.id = e.usuario_id
            WHERE ad.id = :asignacionId AND ad.docente_id = :docenteId AND m.estado = 'ACTIVA'
            ORDER BY u.apellidos, u.nombres
            """)
            .setParameter("asignacionId", asignacionId)
            .setParameter("docenteId", docente.getId())
            .getResultList();

        return rows.stream().map(r -> new EstudianteSeccionDto(
            ((Number) r[0]).longValue(),
            ((Number) r[1]).longValue(),
            (String) r[2],
            (String) r[3],
            (String) r[4],
            (String) r[5]
        )).toList();
    }

    @Override
    @Transactional
    public void registrarAsistencia(String identificador, Long asignacionId, AsistenciaRequestDto dto) {
        DocenteResponseDto docente = obtenerPorNombreUsuario(identificador);
        int updated = entityManager.createNativeQuery("""
            INSERT INTO asistencia (matricula_id, asignacion_docente_id, periodo_academico_id, seccion_id, fecha, estado, observacion)
            SELECT m.id, ad.id, ad.periodo_academico_id, ad.seccion_id, :fecha, :estado, :observacion
            FROM asignacion_docente ad
            JOIN matricula m ON m.id = :matriculaId
                            AND m.periodo_academico_id = ad.periodo_academico_id
                            AND m.seccion_id = ad.seccion_id
            WHERE ad.id = :asignacionId AND ad.docente_id = :docenteId
            ON DUPLICATE KEY UPDATE estado = VALUES(estado), observacion = VALUES(observacion)
            """)
            .setParameter("fecha", dto.fecha())
            .setParameter("estado", dto.estado().toUpperCase())
            .setParameter("observacion", dto.observacion())
            .setParameter("matriculaId", dto.matriculaId())
            .setParameter("asignacionId", asignacionId)
            .setParameter("docenteId", docente.getId())
            .executeUpdate();

        if (updated == 0) {
            throw new IllegalArgumentException("No se pudo registrar asistencia: asignación o matrícula inválida.");
        }
    }

    @Override
    @Transactional
    public void registrarCalificacion(String identificador, Long asignacionId, CalificacionRequestDto dto) {
        DocenteResponseDto docente = obtenerPorNombreUsuario(identificador);
        int inserted = entityManager.createNativeQuery("""
            INSERT INTO calificacion (matricula_id, asignacion_docente_id, periodo_academico_id, seccion_id, etapa, concepto, nota, observacion)
            SELECT m.id, ad.id, ad.periodo_academico_id, ad.seccion_id, :etapa, :concepto, :nota, :observacion
            FROM asignacion_docente ad
            JOIN matricula m ON m.id = :matriculaId
                            AND m.periodo_academico_id = ad.periodo_academico_id
                            AND m.seccion_id = ad.seccion_id
            WHERE ad.id = :asignacionId AND ad.docente_id = :docenteId
            """)
            .setParameter("etapa", dto.etapa())
            .setParameter("concepto", dto.concepto())
            .setParameter("nota", dto.nota())
            .setParameter("observacion", dto.observacion())
            .setParameter("matriculaId", dto.matriculaId())
            .setParameter("asignacionId", asignacionId)
            .setParameter("docenteId", docente.getId())
            .executeUpdate();

        if (inserted == 0) {
            throw new IllegalArgumentException("No se pudo registrar calificación: asignación o matrícula inválida.");
        }
    }

    private DocenteResponseDto convertirADto(Docente docente) {
        DocenteResponseDto dto = new DocenteResponseDto();
        dto.setId(docente.getId());
        dto.setDocumentoIdentidad(docente.getDocumentoIdentidad());
        dto.setEspecialidad(docente.getEspecialidad());

        if (docente.getUsuario() != null) {
            dto.setUsuarioId(docente.getUsuario().getId());
            dto.setNombreUsuario(docente.getUsuario().getNombreUsuario());
            dto.setNombres(docente.getUsuario().getNombres());
            dto.setApellidos(docente.getUsuario().getApellidos());
            dto.setActivo(docente.getUsuario().isActivo());
        }
        return dto;
    }
}