package pe.edu.micaelabastidas.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record AsistenciaRequestDto(
    @NotNull Long matriculaId,
    @NotNull LocalDate fecha,
    @NotBlank String estado,
    String observacion
) {}
