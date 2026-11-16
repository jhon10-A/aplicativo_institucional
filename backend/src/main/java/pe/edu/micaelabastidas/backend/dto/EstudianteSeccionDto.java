package pe.edu.micaelabastidas.backend.dto;

public record EstudianteSeccionDto(
    Long matriculaId,
    Long estudianteId,
    String codigoEstudiante,
    String nombres,
    String apellidos,
    String estadoMatricula
) {}
