package pe.edu.micaelabastidas.backend.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record CalificacionRequestDto(
    @NotNull Long matriculaId,
    @NotBlank String etapa,
    @NotBlank String concepto,
    @NotNull @DecimalMin("0.00") @DecimalMax("20.00") BigDecimal nota,
    String observacion
) {}
