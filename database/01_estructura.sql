CREATE DATABASE IF NOT EXISTS db_institucional
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE db_institucional;
-- 1. USUARIOS Y PERMISOS

CREATE TABLE rol (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE usuario (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(60) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    correo VARCHAR(150) UNIQUE,
    telefono VARCHAR(25),
    foto_url VARCHAR(500),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE usuario_rol (
    usuario_id BIGINT NOT NULL,
    rol_id BIGINT NOT NULL,
    PRIMARY KEY (usuario_id, rol_id),
    FOREIGN KEY (usuario_id) REFERENCES usuario(id),
    FOREIGN KEY (rol_id) REFERENCES rol(id)
) ENGINE=InnoDB;

INSERT INTO rol (nombre) VALUES
('ADMINISTRADOR'),
('DOCENTE'),
('ESTUDIANTE'),
('APODERADO');


-- 2. PERFILES

CREATE TABLE estudiante (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT NOT NULL UNIQUE,
    codigo_estudiante VARCHAR(30) NOT NULL UNIQUE,
    documento_identidad VARCHAR(20) UNIQUE,
    fecha_nacimiento DATE,
    FOREIGN KEY (usuario_id) REFERENCES usuario(id)
) ENGINE=InnoDB;

CREATE TABLE docente (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT NOT NULL UNIQUE,
    documento_identidad VARCHAR(20) UNIQUE,
    especialidad VARCHAR(150),
    FOREIGN KEY (usuario_id) REFERENCES usuario(id)
) ENGINE=InnoDB;

CREATE TABLE apoderado (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT NOT NULL UNIQUE,
    documento_identidad VARCHAR(20) UNIQUE,
    direccion VARCHAR(250),
    FOREIGN KEY (usuario_id) REFERENCES usuario(id)
) ENGINE=InnoDB;

CREATE TABLE estudiante_apoderado (
    estudiante_id BIGINT NOT NULL,
    apoderado_id BIGINT NOT NULL,
    parentesco VARCHAR(40) NOT NULL,
    contacto_principal BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (estudiante_id, apoderado_id),
    FOREIGN KEY (estudiante_id) REFERENCES estudiante(id),
    FOREIGN KEY (apoderado_id) REFERENCES apoderado(id)
) ENGINE=InnoDB;


-- 3. ORGANIZACION ACADEMICA

CREATE TABLE periodo_academico (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE TABLE grado (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nivel VARCHAR(30) NOT NULL,
    nombre VARCHAR(40) NOT NULL,
    UNIQUE (nivel, nombre)
) ENGINE=InnoDB;

CREATE TABLE seccion (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    grado_id BIGINT NOT NULL,
    nombre VARCHAR(20) NOT NULL,
    UNIQUE (grado_id, nombre),
    FOREIGN KEY (grado_id) REFERENCES grado(id)
) ENGINE=InnoDB;

CREATE TABLE matricula (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    estudiante_id BIGINT NOT NULL,
    periodo_academico_id BIGINT NOT NULL,
    seccion_id BIGINT NOT NULL,
    fecha_matricula DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVA',
    UNIQUE (estudiante_id, periodo_academico_id),
    UNIQUE (id, periodo_academico_id, seccion_id),
    CHECK (estado IN ('ACTIVA', 'RETIRADA', 'FINALIZADA')),
    FOREIGN KEY (estudiante_id) REFERENCES estudiante(id),
    FOREIGN KEY (periodo_academico_id) REFERENCES periodo_academico(id),
    FOREIGN KEY (seccion_id) REFERENCES seccion(id)
) ENGINE=InnoDB;

CREATE TABLE curso (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE asignacion_docente (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    docente_id BIGINT NOT NULL,
    curso_id BIGINT NOT NULL,
    periodo_academico_id BIGINT NOT NULL,
    seccion_id BIGINT NOT NULL,
    UNIQUE (curso_id, periodo_academico_id, seccion_id),
    UNIQUE (id, periodo_academico_id, seccion_id),
    FOREIGN KEY (docente_id) REFERENCES docente(id),
    FOREIGN KEY (curso_id) REFERENCES curso(id),
    FOREIGN KEY (periodo_academico_id) REFERENCES periodo_academico(id),
    FOREIGN KEY (seccion_id) REFERENCES seccion(id)
) ENGINE=InnoDB;


-- 4. TAREAS Y ENTREGAS

CREATE TABLE tarea (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    asignacion_docente_id BIGINT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    archivo_url VARCHAR(500),
    fecha_publicacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_limite DATETIME NOT NULL,
    puntaje_maximo DECIMAL(6,2) NOT NULL DEFAULT 20,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (puntaje_maximo > 0),
    CHECK (fecha_limite >= fecha_publicacion),
    FOREIGN KEY (asignacion_docente_id) REFERENCES asignacion_docente(id)
) ENGINE=InnoDB;

CREATE TABLE entrega_tarea (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tarea_id BIGINT NOT NULL,
    matricula_id BIGINT NOT NULL,
    comentario TEXT,
    archivo_url VARCHAR(500),
    fecha_entrega DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    puntaje DECIMAL(6,2),
    retroalimentacion TEXT,
    fecha_revision DATETIME,
    UNIQUE (tarea_id, matricula_id),
    CHECK (puntaje IS NULL OR puntaje >= 0),
    FOREIGN KEY (tarea_id) REFERENCES tarea(id),
    FOREIGN KEY (matricula_id) REFERENCES matricula(id)
) ENGINE=InnoDB;


-- 5. CALIFICACIONES Y ASISTENCIA

CREATE TABLE calificacion (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    matricula_id BIGINT NOT NULL,
    asignacion_docente_id BIGINT NOT NULL,
    periodo_academico_id BIGINT NOT NULL,
    seccion_id BIGINT NOT NULL,
    etapa VARCHAR(30) NOT NULL,
    concepto VARCHAR(150) NOT NULL,
    nota DECIMAL(4,2) NOT NULL,
    observacion TEXT,
    registrado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (nota BETWEEN 0 AND 20),
    FOREIGN KEY (matricula_id, periodo_academico_id, seccion_id)
        REFERENCES matricula(id, periodo_academico_id, seccion_id),
    FOREIGN KEY (
        asignacion_docente_id, periodo_academico_id, seccion_id
    ) REFERENCES asignacion_docente(
        id, periodo_academico_id, seccion_id
    )
) ENGINE=InnoDB;

CREATE TABLE asistencia (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    matricula_id BIGINT NOT NULL,
    asignacion_docente_id BIGINT NOT NULL,
    periodo_academico_id BIGINT NOT NULL,
    seccion_id BIGINT NOT NULL,
    fecha DATE NOT NULL,
    estado VARCHAR(20) NOT NULL,
    observacion VARCHAR(500),
    registrado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (matricula_id, asignacion_docente_id, fecha),
    CHECK (estado IN (
        'PRESENTE', 'FALTA', 'TARDANZA', 'JUSTIFICADA'
    )),
    FOREIGN KEY (matricula_id, periodo_academico_id, seccion_id)
        REFERENCES matricula(id, periodo_academico_id, seccion_id),
    FOREIGN KEY (
        asignacion_docente_id, periodo_academico_id, seccion_id
    ) REFERENCES asignacion_docente(
        id, periodo_academico_id, seccion_id
    )
) ENGINE=InnoDB;


-- 6. COMUNICACION

CREATE TABLE comunicado (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    autor_id BIGINT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    contenido TEXT NOT NULL,
    archivo_url VARCHAR(500),
    rol_destino_id BIGINT,
    seccion_destino_id BIGINT,
    publicado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento DATETIME,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (autor_id) REFERENCES usuario(id),
    FOREIGN KEY (rol_destino_id) REFERENCES rol(id),
    FOREIGN KEY (seccion_destino_id) REFERENCES seccion(id)
) ENGINE=InnoDB;

CREATE TABLE notificacion (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    comunicado_id BIGINT,
    titulo VARCHAR(200) NOT NULL,
    mensaje TEXT NOT NULL,
    ruta_destino VARCHAR(500),
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    leido_en DATETIME,
    FOREIGN KEY (usuario_id) REFERENCES usuario(id),
    FOREIGN KEY (comunicado_id) REFERENCES comunicado(id)
) ENGINE=InnoDB;


-- 7. INFORMACION INSTITUCIONAL

CREATE TABLE institucion (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    codigo_modular VARCHAR(20) UNIQUE,
    descripcion TEXT,
    historia TEXT,
    mision TEXT,
    vision TEXT,
    direccion VARCHAR(250),
    distrito VARCHAR(100),
    provincia VARCHAR(100),
    departamento VARCHAR(100),
    telefono VARCHAR(25),
    correo VARCHAR(150),
    logo_url VARCHAR(500),
    portada_url VARCHAR(500),
    latitud DECIMAL(10,7),
    longitud DECIMAL(10,7),
    CHECK (latitud IS NULL OR latitud BETWEEN -90 AND 90),
    CHECK (longitud IS NULL OR longitud BETWEEN -180 AND 180)
) ENGINE=InnoDB;

CREATE TABLE evento (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    institucion_id BIGINT NOT NULL,
    autor_id BIGINT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    categoria VARCHAR(50) NOT NULL,
    lugar VARCHAR(250),
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME,
    imagen_url VARCHAR(500),
    publicado BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    FOREIGN KEY (institucion_id) REFERENCES institucion(id),
    FOREIGN KEY (autor_id) REFERENCES usuario(id)
) ENGINE=InnoDB;

CREATE TABLE logro (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    institucion_id BIGINT NOT NULL,
    autor_id BIGINT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    categoria VARCHAR(50) NOT NULL,
    fecha DATE NOT NULL,
    imagen_url VARCHAR(500),
    publicado BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (institucion_id) REFERENCES institucion(id),
    FOREIGN KEY (autor_id) REFERENCES usuario(id)
) ENGINE=InnoDB;

CREATE TABLE galeria (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    institucion_id BIGINT NOT NULL,
    autor_id BIGINT NOT NULL,
    evento_id BIGINT,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    categoria VARCHAR(50),
    portada_url VARCHAR(500),
    publicado BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (institucion_id) REFERENCES institucion(id),
    FOREIGN KEY (autor_id) REFERENCES usuario(id),
    FOREIGN KEY (evento_id) REFERENCES evento(id)
) ENGINE=InnoDB;

CREATE TABLE imagen_galeria (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    galeria_id BIGINT NOT NULL,
    imagen_url VARCHAR(500) NOT NULL,
    descripcion VARCHAR(500),
    orden INT NOT NULL DEFAULT 0,
    CHECK (orden >= 0),
    FOREIGN KEY (galeria_id) REFERENCES galeria(id)
) ENGINE=InnoDB;

CREATE TABLE recurso_educativo (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    autor_id BIGINT NOT NULL,
    curso_id BIGINT,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    tipo VARCHAR(30) NOT NULL,
    categoria VARCHAR(80),
    url VARCHAR(500) NOT NULL,
    miniatura_url VARCHAR(500),
    publicado BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (tipo IN (
        'VIDEO', 'DOCUMENTO', 'ENLACE',
        'APLICACION', 'JUEGO', 'OTRO'
    )),
    FOREIGN KEY (autor_id) REFERENCES usuario(id),
    FOREIGN KEY (curso_id) REFERENCES curso(id)
) ENGINE=InnoDB;


-- 8. COMPROBAR RESULTADO

SHOW TABLES;

SELECT COUNT(*) AS total_tablas
FROM information_schema.tables
WHERE table_schema = 'db_institucional'
  AND table_type = 'BASE TABLE';

SELECT * FROM rol;