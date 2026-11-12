-- Requiere db_institucional creada con database/01_estructura.sql.
-- Ejecutar una sola vez; no volver a ejecutar 01_estructura.sql.
USE db_institucional;

CREATE TABLE horario_clase (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    asignacion_docente_id BIGINT NOT NULL,
    dia_semana TINYINT NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    aula VARCHAR(80),
    CONSTRAINT chk_horario_dia_semana
        CHECK (dia_semana BETWEEN 1 AND 5),
    CONSTRAINT chk_horario_horas
        CHECK (
            hora_inicio >= '00:00:00'
            AND hora_fin <= '23:59:59'
            AND hora_inicio < hora_fin
        ),
    CONSTRAINT fk_horario_asignacion_docente
        FOREIGN KEY (asignacion_docente_id)
        REFERENCES asignacion_docente(id),
    INDEX idx_horario_asignacion_dia_inicio
        (asignacion_docente_id, dia_semana, hora_inicio)
) ENGINE=InnoDB;
