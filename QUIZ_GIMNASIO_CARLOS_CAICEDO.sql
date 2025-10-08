-- Ejercicio Procedimientos y Vistas 
-- Contexto:
-- Un sistema de gestión de un GIMNASIO con varias sedes necesita administrar instructores,
-- clientes, clases grupales y reservas. Se requiere el diseño básico de la base de datos
-- y la implementación de 3 procedimientos almacenados y 2 vistas para apoyar la operación.

-- ------------------------------------------------------------
-- Creación del esquema base (MySQL 8+)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS Reservas;
DROP TABLE IF EXISTS Clases;
DROP TABLE IF EXISTS Clientes;
DROP TABLE IF EXISTS Instructores;
DROP TABLE IF EXISTS Sedes;

CREATE TABLE Sedes (
    id_sede INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(150) NOT NULL
);

CREATE TABLE Instructores (
    id_instructor INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    especialidad VARCHAR(80),
    correo VARCHAR(120) UNIQUE NOT NULL
);

CREATE TABLE Clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(120) UNIQUE NOT NULL,
    membresia ENUM('BASICA','PREMIUM') NOT NULL DEFAULT 'BASICA'
);

CREATE TABLE Clases (
    id_clase INT PRIMARY KEY AUTO_INCREMENT,
    id_sede INT NOT NULL,
    id_instructor INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    cupo INT NOT NULL CHECK (cupo > 0),
    fecha_hora DATETIME NOT NULL,
    duracion_min INT NOT NULL CHECK (duracion_min > 0),
    FOREIGN KEY (id_sede) REFERENCES Sedes(id_sede),
    FOREIGN KEY (id_instructor) REFERENCES Instructores(id_instructor)
);

CREATE TABLE Reservas (
    id_reserva INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    id_clase INT NOT NULL,
    fecha_reserva DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('RESERVADA','CANCELADA','ASISTIDA') NOT NULL DEFAULT 'RESERVADA',
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente),
    FOREIGN KEY (id_clase) REFERENCES Clases(id_clase),
    UNIQUE KEY uq_reserva_unica (id_cliente, id_clase) -- un cliente no puede reservar dos veces la misma clase
);

-- ------------------------------------------------------------
-- Inserción de datos mínimos de prueba 
-- ------------------------------------------------------------
INSERT INTO Sedes (nombre, direccion) VALUES
('Centro', 'Calle 10 #5-20'),
('Norte', 'Av. 3N #45-12'),
('Sur', 'Cra. 80 #30-55'),
('Occidente', 'Transv. 5 #72-10'),
('Oriente', 'Calle 50 #12-34');

INSERT INTO Instructores (nombre, especialidad, correo) VALUES
('Laura Díaz', 'Spinning', 'laura.diaz@gym.com'),
('Carlos Rojas', 'CrossFit', 'carlos.rojas@gym.com'),
('Andrea Méndez', 'Yoga', 'andrea.mendez@gym.com'),
('Diego Pardo', 'HIIT', 'diego.pardo@gym.com'),
('Sofía Martínez', 'Pilates', 'sofia.martinez@gym.com');

INSERT INTO Clientes (nombre, correo, membresia) VALUES
('Juan Pérez', 'juan.perez@correo.com', 'BASICA'),
('María López', 'maria.lopez@correo.com', 'PREMIUM'),
('Pedro Gómez', 'pedro.gomez@correo.com', 'BASICA'),
('Ana Torres', 'ana.torres@correo.com', 'PREMIUM'),
('Luis Fernández', 'luis.fernandez@correo.com', 'BASICA');

-- Clases próximas (fechas de ejemplo)
INSERT INTO Clases (id_sede, id_instructor, nombre, cupo, fecha_hora, duracion_min) VALUES
(1, 1, 'Spinning AM', 10, '2025-10-10 07:00:00', 60),
(2, 2, 'CrossFit Power', 12, '2025-10-10 18:00:00', 50),
(3, 3, 'Yoga Flow', 15, '2025-10-11 08:00:00', 70),
(4, 4, 'HIIT Express', 8,  '2025-10-11 19:00:00', 30),
(5, 5, 'Pilates Core', 10, '2025-10-12 06:30:00', 55);

-- Reservas iniciales
INSERT INTO Reservas (id_cliente, id_clase, estado) VALUES
(1, 1, 'RESERVADA'),
(2, 1, 'ASISTIDA'),
(3, 2, 'RESERVADA'),
(4, 3, 'RESERVADA'),
(5, 4, 'CANCELADA');


-- ------------------------------------------------------------
-- Ejercicios 
-- (3 procedimientos + 2 vistas ya implementados)
-- ------------------------------------------------------------
-- E1 (SP): Usa sp_reservar_clase para intentar reservar la clase 1 para el cliente 3.
--     Muestra el valor de p_cupos_restantes. Luego intenta reservar de nuevo y observa el error por duplicado.

-- E2 (SP): Marca una reserva existente como CANCELADA con sp_cancelar_reserva y
--     verifica el cambio consultando la vista vw_clases_con_aforo antes y después.

-- E3 (SP): Calcula el porcentaje de asistencia del instructor 1 usando sp_porcentaje_asistencia_instructor.
--     Registra algunas reservas como ASISTIDA y vuelve a calcular para comparar.

-- E4 (VIEW): Consulta vw_clases_con_aforo para listar las clases con sus cupos disponibles
--     ordenadas por menor cupo disponible primero.

-- E5 (VIEW): Consulta vw_resumen_reservas_cliente para identificar qué clientes PREMIUM
--     presentan mayor número de cancelaciones.

-- ------------------------------------------------------------
-- Entregable:
-- archivo en TXT  BD2_QUIZ_juanitoperez.txt
-- Sube el script a un repositorio público y envía el enlace al correo diego.prado.o@uniautonoma.edu.co
-- Asunto: Quiz - Procedimientos y Vistas (Gimnasio)
-- ------------------------------------------------------------

-- ejercicio 1


DELIMITER //
create procedure sp_reservar_clase (
  in id_cliente INT,
  in id_clase INT,
  out cupos_restantes INT
)
begin
declare cupo INT;
declare reservadas INT;
declare  existe INT;

SELECT cupo INTO cupo FROM Clases WHERE id_clase = id_clase;
IF cupo IS NULL THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La clase no existe';
END IF;

SELECT COUNT(*) INTO existe
FROM Reservas
WHERE id_cliente = id_cliente AND id_clase = id_clase AND estado <> 'CANCELADA';

IF existe > 0 THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente ya tiene una reserva para esta clase';
END IF;

SELECT COUNT(*) INTO reservadas
FROM Reservas
WHERE id_clase = id_clase AND estado <> 'CANCELADA';

IF reservadas >= cupo THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay cupos disponibles';
END IF;

INSERT INTO Reservas (id_cliente, id_clase, estado)
VALUES (id_cliente, id_clase, 'RESERVADA');

SET cupos_restantes = cupo - (reservadas + 1);
END
//
DELIMITER ;


-- ejercicio 2

DELIMITER //
create procedure sp_cancelar_reserva (
in id_reserva INT,
out filas_afectadas INT
)
begin
update Reservas
set estado = 'cancelada'
where id_reserva = id_reserva AND estado <> 'cancelada';

set filas_afectadas = row_count();

if filas_afectadas = 0 then
SET MESSAGE_TEXT = 'Reserva no encontrada o ya esta cancekada';
end if;
end //
DELIMITER ;

-- ejercicio 3

DELIMITER //
create procedure sp_porcentaje_asistencia_instructor (
in id_instructor INT,
out porcentaje DECIMAL(5,2)
)
begin
declare total_reservas int;
declare asistidas int;

select COUNT(id_reserva)
into total_reservas
from Reservas
join Clases On id_clase = id_clase
where  id_instructor = id_instructor;

select COUNT(r.id_reserva)
into asistidas
from Reservas 
join Clases on id_clase = id_clase
where id_instructor = id_instructor
and estado = 'ASISTIDA';

if total_reservas = 0 then
set porcentaje = 0;
else
set porcentaje = ROUND((asistidas / total_reservas) * 100, 2);
end if;
end
//
DELIMITER ;

-- ejercicio 4
create view vw_clases_con_aforo as
Select
c.id_clase,
c.nombre As clase,
s.nombre As sede,
i.nombre As instructor,
c.cupo,
COUNT(r.id_reserva) As reservas_activas,
(c.cupo - COUNT(r.id_reserva)) As cupos_disponibles,
c.fecha_hora
from Clases c
join Sedes s on c.id_sede = s.id_sede
join Instructores i on c.id_instructor = i.id_instructor
left join Reservas r on c.id_clase = r.id_clase and r.estado <> 'CANCELADA'
group by c.id_clase, c.nombre, s.nombre, i.nombre, c.cupo, c.fecha_hora
order by cupos_disponibles asc;


-- ejercicio 5
create view vw_resumen_reservas_cliente as
select
c.id_cliente,
c.nombre as cliente,
c.membresia,
COUNT(r.id_reserva) as total_reservas,
SUM(r.estado = 'Cancelada') as canceladas,
SUM(r.estado = 'Asistida') as asistidas,
case
when COUNT(r.id_reserva) = 0 then 0
else ROUND((SUM(r.estado = 'Cancelada') / COUNT(r.id_reserva)) * 100, 2)
end as porcentaje_canceladas
from Clientes c
left join  Reservas r on c.id_cliente = r.id_cliente
group by c.id_cliente, c.nombre, c.membresia;



