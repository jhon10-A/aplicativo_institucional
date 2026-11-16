package pe.edu.micaelabastidas.backend.dto;

public record AsignacionDocenteDto(
    Long id,
    Long cursoId,
    String cursoNombre,
    String cursoDescripcion,
    Long periodoAcademicoId,
    String periodoNombre,
    boolean periodoActivo,
    Long seccionId,
    String seccionNombre,
    String gradoNombre,
    String gradoNivel
) {}
