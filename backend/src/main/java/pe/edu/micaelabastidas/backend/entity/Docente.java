package pe.edu.micaelabastidas.backend.entity;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "docente")
public class Docente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Relación 1 a 1 con la tabla Usuario según tu base de datos
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", referencedColumnName = "id", nullable = false, unique = true)
    private Usuario usuario;

    @Column(name = "documento_identidad", length = 20, unique = true)
    private String documentoIdentidad;

    @Column(length = 150)
    private String especialidad;
}