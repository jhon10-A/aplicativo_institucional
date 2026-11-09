package pe.edu.micaelabastidas.backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import pe.edu.micaelabastidas.backend.dto.DocenteRequestDto;
import pe.edu.micaelabastidas.backend.dto.DocenteResponseDto;
import pe.edu.micaelabastidas.backend.entity.Docente;
import pe.edu.micaelabastidas.backend.repository.DocenteRepository;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class DocenteServiceImpl implements DocenteService {

    @Autowired
    private DocenteRepository docenteRepository;

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
        Docente docente = new Docente();
        docente.setDni(dto.getDni());
        docente.setEspecialidad(dto.getEspecialidad());
        docente.setTelefono(dto.getTelefono());
        docente.setActivo(true);
        
        Docente guardado = docenteRepository.save(docente);
        return convertirADto(guardado);
    }

    @Override
    public DocenteResponseDto actualizar(Long id, DocenteRequestDto dto) {
        Docente docente = docenteRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Docente no encontrado con ID: " + id));
        
        docente.setDni(dto.getDni());
        docente.setEspecialidad(dto.getEspecialidad());
        docente.setTelefono(dto.getTelefono());

        Docente actualizado = docenteRepository.save(docente);
        return convertirADto(actualizado);
    }

    @Override
    public void cambiarEstado(Long id, boolean activo) {
        Docente docente = docenteRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Docente no encontrado con ID: " + id));
        docente.setActivo(activo);
        docenteRepository.save(docente);
    }

    private DocenteResponseDto convertirADto(Docente docente) {
        DocenteResponseDto dto = new DocenteResponseDto();
        dto.setId(docente.getId());
        dto.setDni(docente.getDni());
        dto.setEspecialidad(docente.getEspecialidad());
        dto.setTelefono(docente.getTelefono());
        dto.setActivo(docente.isActivo());
        return dto;
    }
}