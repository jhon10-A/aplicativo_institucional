package pe.edu.micaelabastidas.backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import pe.edu.micaelabastidas.backend.dto.DocenteRequestDto;
import pe.edu.micaelabastidas.backend.dto.DocenteResponseDto;
import pe.edu.micaelabastidas.backend.entity.Docente;
import pe.edu.micaelabastidas.backend.entity.Usuario;
import pe.edu.micaelabastidas.backend.repository.DocenteRepository;
import pe.edu.micaelabastidas.backend.repository.UsuarioRepository;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class DocenteServiceImpl implements DocenteService {

    @Autowired
    private DocenteRepository docenteRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

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