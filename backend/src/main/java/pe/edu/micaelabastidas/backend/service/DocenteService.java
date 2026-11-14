package pe.edu.micaelabastidas.backend.service;

import pe.edu.micaelabastidas.backend.dto.*;

import java.util.List;

public interface DocenteService {
    List<DocenteResponseDto> obtenerTodos();
    DocenteResponseDto obtenerPorId(Long id);
    DocenteResponseDto obtenerPorNombreUsuario(String nombreUsuario);
    DocenteResponseDto crear(DocenteRequestDto dto);
    DocenteResponseDto actualizar(Long id, DocenteRequestDto dto);
    void cambiarEstado(Long id, boolean activo);

    List<AsignacionDocenteDto> obtenerMisAsignaciones(String identificador);
    List<EstudianteSeccionDto> obtenerEstudiantesDeAsignacion(String identificador, Long asignacionId);
    void registrarAsistencia(String identificador, Long asignacionId, AsistenciaRequestDto dto);
    void registrarCalificacion(String identificador, Long asignacionId, CalificacionRequestDto dto);
}