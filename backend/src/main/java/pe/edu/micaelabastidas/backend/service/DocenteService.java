package pe.edu.micaelabastidas.backend.service;

import pe.edu.micaelabastidas.backend.dto.DocenteRequestDto;
import pe.edu.micaelabastidas.backend.dto.DocenteResponseDto;

import java.util.List;

public interface DocenteService {
    List<DocenteResponseDto> obtenerTodos();
    DocenteResponseDto obtenerPorId(Long id);
    DocenteResponseDto crear(DocenteRequestDto dto);
    DocenteResponseDto actualizar(Long id, DocenteRequestDto dto);
    void cambiarEstado(Long id, boolean activo);
}