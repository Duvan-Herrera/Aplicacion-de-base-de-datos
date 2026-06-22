USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'CondominioDB')
BEGIN
    ALTER DATABASE CondominioDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CondominioDB;
END
GO

CREATE DATABASE CondominioDB;
GO
USE CondominioDB;
GO

-- TABLAS 

CREATE TABLE TipoPropiedad (
    IdTipoPropiedad INT          IDENTITY(1,1) PRIMARY KEY,
    Descripcion     NVARCHAR(50) NOT NULL
);

CREATE TABLE Persona (
    IdPersona     INT           IDENTITY(1,1) PRIMARY KEY,
    Cedula        NVARCHAR(20)  NOT NULL UNIQUE,
    Nombre        NVARCHAR(100) NOT NULL,
    Apellidos     NVARCHAR(100) NOT NULL,
    Telefono      NVARCHAR(20)  NULL,
    Email         NVARCHAR(150) NULL,
    Tipo          NVARCHAR(20)  NOT NULL  
);

CREATE TABLE Propiedad (
    IdPropiedad        INT            IDENTITY(1,1) PRIMARY KEY,
    Codigo             NVARCHAR(20)   NOT NULL UNIQUE,
    IdTipoPropiedad    INT            NOT NULL REFERENCES TipoPropiedad(IdTipoPropiedad),
    AreaM2             DECIMAL(10,2)  NOT NULL CHECK (AreaM2 > 0),
    CantResidentes     INT            NOT NULL DEFAULT 0 CHECK (CantResidentes >= 0),
    CuotaMantenimiento DECIMAL(10,2)  NOT NULL DEFAULT 0
);

CREATE TABLE PropiedadPropietario (
    IdPropiedadPropietario INT IDENTITY(1,1) PRIMARY KEY,
    IdPropiedad            INT NOT NULL REFERENCES Propiedad(IdPropiedad),
    IdPersona              INT NOT NULL REFERENCES Persona(IdPersona),
    EsPrincipal            BIT NOT NULL DEFAULT 0,
    UNIQUE (IdPropiedad, IdPersona)
);

CREATE TABLE AreaComun (
    IdAreaComun     INT            IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(100)  NOT NULL,
    CapacidadMaxima INT            NOT NULL CHECK (CapacidadMaxima > 0),
    HoraApertura    TIME           NOT NULL,
    HoraCierre      TIME           NOT NULL,
    TarifaUso       DECIMAL(10,2)  NOT NULL DEFAULT 0
);

CREATE TABLE Reserva (
    IdReserva      INT           IDENTITY(1,1) PRIMARY KEY,
    IdAreaComun    INT           NOT NULL REFERENCES AreaComun(IdAreaComun),
    IdPropiedad    INT           NOT NULL REFERENCES Propiedad(IdPropiedad),
    IdPersona      INT           NOT NULL REFERENCES Persona(IdPersona),
    FechaReserva   DATE          NOT NULL,
    HoraInicio     TIME          NOT NULL,
    HoraFin        TIME          NOT NULL CHECK (HoraFin > HoraInicio),
    NumPersonas    INT           NOT NULL CHECK (NumPersonas > 0),
    Estado         NVARCHAR(20)  NOT NULL DEFAULT 'Pendiente',
    MotivoRechazo  NVARCHAR(200) NULL,
    FechaCreacion  DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE CodigoAcceso (
    IdCodigoAcceso   INT          IDENTITY(1,1) PRIMARY KEY,
    IdPersona        INT          NOT NULL REFERENCES Persona(IdPersona),
    Codigo           NVARCHAR(50) NOT NULL UNIQUE,
    FechaVencimiento DATETIME     NOT NULL,
    Activo           BIT          NOT NULL DEFAULT 1
);

CREATE TABLE RegistroVisita (
    IdVisita         INT           IDENTITY(1,1) PRIMARY KEY,
    NombreVisitante  NVARCHAR(150) NOT NULL,
    CedulaVisitante  NVARCHAR(20)  NULL,
    IdPropiedad      INT           NOT NULL REFERENCES Propiedad(IdPropiedad),
    IdCodigoAcceso   INT           NULL REFERENCES CodigoAcceso(IdCodigoAcceso),
    FechaEntrada     DATETIME      NOT NULL DEFAULT GETDATE(),
    FechaSalida      DATETIME      NULL
);
GO

-- DATOS DE EJEMPLO 

INSERT INTO TipoPropiedad (Descripcion) VALUES
('Apartamento'), ('Casa'), ('Local Comercial');

INSERT INTO Persona (Cedula, Nombre, Apellidos, Telefono, Email, Tipo) VALUES
('111111111', 'Carlos',  'Mora Jiménez',    '8888-0001', 'carlos@mail.com',  'Propietario'),
('222222222', 'María',   'Rodríguez Solís', '8888-0002', 'maria@mail.com',   'Propietario'),
('333333333', 'José',    'Vargas Campos',   '8888-0003', 'jose@mail.com',    'Ambos'),
('444444444', 'Laura',   'Quesada López',   '8888-0004', 'laura@mail.com',   'Residente'),
('555555555', 'Andrés',  'Castro Pérez',    '7777-0001', 'andres@mail.com',  'Residente');

INSERT INTO Propiedad (Codigo, IdTipoPropiedad, AreaM2, CantResidentes, CuotaMantenimiento) VALUES
('A-101', 1,  80.00, 2, 41000),
('A-102', 1,  95.00, 3, 47750),
('B-101', 2, 120.00, 4, 59000),
('B-102', 2, 200.00, 2, 95000);


INSERT INTO PropiedadPropietario (IdPropiedad, IdPersona, EsPrincipal) VALUES
(1, 1, 1),  -- A-101: Carlos (principal)
(1, 2, 0),  -- A-101: María  (co-propietaria)
(2, 2, 1),  -- A-102: María  (principal)
(3, 3, 1),  -- B-101: José   (principal)
(3, 1, 0),  -- B-101: Carlos (co-propietario)
(4, 3, 1);  -- B-102: José   (principal)

INSERT INTO AreaComun (Nombre, CapacidadMaxima, HoraApertura, HoraCierre, TarifaUso) VALUES
('Salón Comunal',   50, '08:00', '22:00', 15000),
('Piscina',         30, '07:00', '20:00',  5000),
('Cancha de Tenis',  4, '06:00', '21:00',  3000),
('Gimnasio',        15, '05:00', '22:00',     0);
GO

-- ============================================================
-- EJERCICIO 1: PROPIEDADES
-- ============================================================

-- Función: calcular cuota de mantenimiento
-- Fórmula: (AreaM2 x 450) + 5000
CREATE OR ALTER FUNCTION dbo.fn_CuotaMantenimiento(@AreaM2 DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN (@AreaM2 * 450) + 5000
END;
GO

-- SP: Crear propiedad (sin INSERT directo, con validaciones)
CREATE OR ALTER PROCEDURE dbo.sp_CrearPropiedad
    @Codigo           NVARCHAR(20),
    @IdTipoPropiedad  INT,
    @AreaM2           DECIMAL(10,2),
    @CantResidentes   INT,
    @IdPropietario    INT,
    @IdPropiedad      INT           OUTPUT,
    @Mensaje          NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar código
    IF NULLIF(LTRIM(@Codigo), '') IS NULL
    BEGIN SET @Mensaje = 'ERROR: El código es obligatorio.'; RETURN; END

    -- Validar que no exista
    IF EXISTS (SELECT 1 FROM Propiedad WHERE Codigo = @Codigo)
    BEGIN SET @Mensaje = 'ERROR: Ya existe una propiedad con el código ' + @Codigo; RETURN; END

    -- Validar área
    IF @AreaM2 IS NULL OR @AreaM2 <= 0
    BEGIN SET @Mensaje = 'ERROR: El área debe ser mayor a cero.'; RETURN; END

    -- Validar residentes
    IF @CantResidentes < 0
    BEGIN SET @Mensaje = 'ERROR: La cantidad de residentes no puede ser negativa.'; RETURN; END

    -- Validar tipo propiedad
    IF NOT EXISTS (SELECT 1 FROM TipoPropiedad WHERE IdTipoPropiedad = @IdTipoPropiedad)
    BEGIN SET @Mensaje = 'ERROR: El tipo de propiedad no existe.'; RETURN; END

    -- Validar propietario
    IF NOT EXISTS (SELECT 1 FROM Persona WHERE IdPersona = @IdPropietario AND Tipo IN ('Propietario','Ambos'))
    BEGIN SET @Mensaje = 'ERROR: La persona no existe o no es propietario.'; RETURN; END

    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @Cuota DECIMAL(10,2) = dbo.fn_CuotaMantenimiento(@AreaM2);

        INSERT INTO Propiedad (Codigo, IdTipoPropiedad, AreaM2, CantResidentes, CuotaMantenimiento)
        VALUES (@Codigo, @IdTipoPropiedad, @AreaM2, @CantResidentes, @Cuota);

        SET @IdPropiedad = SCOPE_IDENTITY();

        INSERT INTO PropiedadPropietario (IdPropiedad, IdPersona, EsPrincipal)
        VALUES (@IdPropiedad, @IdPropietario, 1);

        COMMIT;
        SET @Mensaje = 'OK: Propiedad ' + @Codigo + ' creada. Cuota: ₡' + FORMAT(@Cuota,'N0');
    END TRY
    BEGIN CATCH
        ROLLBACK;
        SET @Mensaje = 'ERROR: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- SP: Agregar otro propietario a una propiedad existente
CREATE OR ALTER PROCEDURE dbo.sp_AgregarPropietario
    @IdPropiedad INT,
    @IdPersona   INT,
    @Mensaje     NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Propiedad WHERE IdPropiedad = @IdPropiedad)
    BEGIN SET @Mensaje = 'ERROR: La propiedad no existe.'; RETURN; END

    IF NOT EXISTS (SELECT 1 FROM Persona WHERE IdPersona = @IdPersona AND Tipo IN ('Propietario','Ambos'))
    BEGIN SET @Mensaje = 'ERROR: La persona no existe o no es propietario.'; RETURN; END

    IF EXISTS (SELECT 1 FROM PropiedadPropietario WHERE IdPropiedad = @IdPropiedad AND IdPersona = @IdPersona)
    BEGIN SET @Mensaje = 'ERROR: Esa persona ya es propietaria de esta propiedad.'; RETURN; END

    INSERT INTO PropiedadPropietario (IdPropiedad, IdPersona, EsPrincipal)
    VALUES (@IdPropiedad, @IdPersona, 0);

    SET @Mensaje = 'OK: Propietario agregado.';
END;
GO

-- SP: Reporte de propiedades
-- Filtros opcionales: por código, por dueño
CREATE OR ALTER PROCEDURE dbo.sp_ReportePropiedades
    @Codigo        NVARCHAR(20) = NULL,
    @IdPropietario INT          = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.Codigo                                                AS [Código],
        tp.Descripcion                                          AS [Tipo],
        p.AreaM2                                                AS [Tamaño m²],
        FORMAT(p.CuotaMantenimiento, 'N0')                      AS [Cuota ₡],
        -- Propietarios concatenados con FOR XML PATH
        STUFF((
            SELECT ', ' + pe.Nombre + ' ' + pe.Apellidos
            FROM PropiedadPropietario pp
            INNER JOIN Persona pe ON pe.IdPersona = pp.IdPersona
            WHERE pp.IdPropiedad = p.IdPropiedad
            FOR XML PATH('')
        ), 1, 2, '')                                            AS [Propietarios]
    FROM Propiedad p
    INNER JOIN TipoPropiedad tp ON tp.IdTipoPropiedad = p.IdTipoPropiedad
    WHERE (@Codigo        IS NULL OR p.Codigo LIKE '%' + @Codigo + '%')
      AND (@IdPropietario IS NULL OR EXISTS (
              SELECT 1 FROM PropiedadPropietario pp
              WHERE pp.IdPropiedad = p.IdPropiedad
                AND pp.IdPersona   = @IdPropietario))
    ORDER BY p.Codigo;
END;
GO

-- ============================================================
-- EJERCICIO 2: RESERVAS
-- ============================================================

-- SP: Crear reserva (sin INSERT directo, con validaciones)
CREATE OR ALTER PROCEDURE dbo.sp_CrearReserva
    @IdAreaComun  INT,
    @IdPropiedad  INT,
    @IdPersona    INT,
    @Fecha        DATE,
    @HoraInicio   TIME,
    @HoraFin      TIME,
    @NumPersonas  INT,
    @IdReserva    INT           OUTPUT,
    @Mensaje      NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar área
    IF NOT EXISTS (SELECT 1 FROM AreaComun WHERE IdAreaComun = @IdAreaComun)
    BEGIN SET @Mensaje = 'ERROR: El área común no existe.'; RETURN; END

    -- Validar propiedad
    IF NOT EXISTS (SELECT 1 FROM Propiedad WHERE IdPropiedad = @IdPropiedad)
    BEGIN SET @Mensaje = 'ERROR: La propiedad no existe.'; RETURN; END

    -- Persona debe ser propietario o residente
    IF NOT EXISTS (SELECT 1 FROM Persona WHERE IdPersona = @IdPersona AND Tipo IN ('Propietario','Residente','Ambos'))
    BEGIN SET @Mensaje = 'ERROR: La persona no tiene permiso para reservar.'; RETURN; END

    -- Fecha no puede ser en el pasado
    IF @Fecha < CAST(GETDATE() AS DATE)
    BEGIN SET @Mensaje = 'ERROR: La fecha no puede ser en el pasado.'; RETURN; END

    -- Validar horario lógico
    IF @HoraInicio >= @HoraFin
    BEGIN SET @Mensaje = 'ERROR: La hora inicio debe ser menor a la hora fin.'; RETURN; END

    -- Validar dentro del horario del área
    DECLARE @Apertura TIME, @Cierre TIME, @CapMax INT;
    SELECT @Apertura = HoraApertura, @Cierre = HoraCierre, @CapMax = CapacidadMaxima
    FROM AreaComun WHERE IdAreaComun = @IdAreaComun;

    IF @HoraInicio < @Apertura OR @HoraFin > @Cierre
    BEGIN
        SET @Mensaje = 'ERROR: Horario fuera del rango del área (' +
            FORMAT(@Apertura,'hh\:mm') + ' - ' + FORMAT(@Cierre,'hh\:mm') + ').';
        RETURN;
    END

    -- Validar capacidad
    IF @NumPersonas > @CapMax
    BEGIN
        SET @Mensaje = 'ERROR: Supera la capacidad máxima de ' + CAST(@CapMax AS NVARCHAR) + ' personas.';
        RETURN;
    END

    -- Validar traslape de horario
    IF EXISTS (
        SELECT 1 FROM Reserva
        WHERE IdAreaComun  = @IdAreaComun
          AND FechaReserva = @Fecha
          AND Estado IN ('Pendiente','Confirmada')
          AND @HoraInicio  < HoraFin
          AND @HoraFin     > HoraInicio
    )
    BEGIN SET @Mensaje = 'ERROR: El área no está disponible en ese horario.'; RETURN; END

    -- Insertar
    INSERT INTO Reserva (IdAreaComun, IdPropiedad, IdPersona, FechaReserva, HoraInicio, HoraFin, NumPersonas)
    VALUES (@IdAreaComun, @IdPropiedad, @IdPersona, @Fecha, @HoraInicio, @HoraFin, @NumPersonas);

    SET @IdReserva = SCOPE_IDENTITY();
    SET @Mensaje   = 'OK: Reserva creada (Pendiente). ID: ' + CAST(@IdReserva AS NVARCHAR);
END;
GO

-- SP: Aprobar o rechazar una reserva
CREATE OR ALTER PROCEDURE dbo.sp_GestionarReserva
    @IdReserva INT,
    @Aprobar   BIT,
    @Motivo    NVARCHAR(200) = NULL,
    @Mensaje   NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Reserva WHERE IdReserva = @IdReserva AND Estado = 'Pendiente')
    BEGIN SET @Mensaje = 'ERROR: La reserva no existe o no está pendiente.'; RETURN; END

    IF @Aprobar = 0 AND NULLIF(LTRIM(@Motivo), '') IS NULL
    BEGIN SET @Mensaje = 'ERROR: Debe indicar el motivo del rechazo.'; RETURN; END

    UPDATE Reserva
    SET Estado        = CASE WHEN @Aprobar = 1 THEN 'Confirmada' ELSE 'Rechazada' END,
        MotivoRechazo = CASE WHEN @Aprobar = 0 THEN @Motivo ELSE NULL END
    WHERE IdReserva = @IdReserva;

    SET @Mensaje = 'OK: Reserva ' + CASE WHEN @Aprobar = 1 THEN 'confirmada.' ELSE 'rechazada.' END;
END;
GO

-- SP: Reporte de reservas
-- Filtros opcionales: por propiedad, por persona que reservó
CREATE OR ALTER PROCEDURE dbo.sp_ReporteReservas
    @IdPropiedad INT = NULL,
    @IdPersona   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.Nombre                                             AS [Área Reservada],
        CAST(r.FechaReserva AS NVARCHAR(10))                AS [Fecha],
        FORMAT(r.HoraInicio,'hh\:mm') + ' - ' +
        FORMAT(r.HoraFin,'hh\:mm')                          AS [Horario],
        r.Estado                                             AS [Estado],
        pe.Nombre + ' ' + pe.Apellidos                      AS [Quién Reservó],
        p.Codigo                                             AS [Propiedad]
    FROM Reserva r
    INNER JOIN AreaComun a  ON a.IdAreaComun = r.IdAreaComun
    INNER JOIN Propiedad p  ON p.IdPropiedad = r.IdPropiedad
    INNER JOIN Persona   pe ON pe.IdPersona  = r.IdPersona
    WHERE (@IdPropiedad IS NULL OR r.IdPropiedad = @IdPropiedad)
      AND (@IdPersona   IS NULL OR r.IdPersona   = @IdPersona)
    ORDER BY r.FechaReserva DESC;
END;
GO

-- ============================================================
-- EJERCICIO 3: CONTROL DE ACCESO
-- ============================================================

-- SP: Generar código único de acceso por usuario
CREATE OR ALTER PROCEDURE dbo.sp_GenerarCodigoAcceso
    @IdPersona    INT,
    @DiasVigencia INT           = 365,
    @Codigo       NVARCHAR(50)  OUTPUT,
    @Mensaje      NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Persona WHERE IdPersona = @IdPersona)
    BEGIN SET @Mensaje = 'ERROR: La persona no existe.'; RETURN; END

    -- Desactivar código anterior de esa persona
    UPDATE CodigoAcceso SET Activo = 0
    WHERE IdPersona = @IdPersona AND Activo = 1;

    -- Generar código único: CA-AAAAMM-NNNN-XXXXXX
    DECLARE @Nuevo NVARCHAR(50);
    DECLARE @Intentos INT = 0;

    WHILE @Intentos < 10
    BEGIN
        SET @Nuevo = 'CA-' + FORMAT(GETDATE(),'yyyyMM') + '-' +
                     RIGHT('0000' + CAST(@IdPersona AS NVARCHAR), 4) + '-' +
                     UPPER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), '-', ''), 6));

        IF NOT EXISTS (SELECT 1 FROM CodigoAcceso WHERE Codigo = @Nuevo)
            BREAK;

        SET @Intentos += 1;
    END;

    INSERT INTO CodigoAcceso (IdPersona, Codigo, FechaVencimiento)
    VALUES (@IdPersona, @Nuevo, DATEADD(DAY, @DiasVigencia, GETDATE()));

    SET @Codigo  = @Nuevo;
    SET @Mensaje = 'OK: Código generado → ' + @Nuevo;
END;
GO

-- Trigger: valida el código QR antes de registrar la visita
CREATE OR ALTER TRIGGER trg_ValidarAcceso
ON RegistroVisita
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Si viene con código QR, verificar que sea válido
    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE i.IdCodigoAcceso IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM CodigoAcceso ca
              WHERE ca.IdCodigoAcceso   = i.IdCodigoAcceso
                AND ca.Activo           = 1
                AND ca.FechaVencimiento >= GETDATE()
          )
    )
    BEGIN
        RAISERROR('Acceso denegado: código QR inválido o vencido.', 16, 1);
        RETURN;
    END;

    -- Si todo está bien, insertar
    INSERT INTO RegistroVisita (NombreVisitante, CedulaVisitante, IdPropiedad, IdCodigoAcceso, FechaEntrada)
    SELECT NombreVisitante, CedulaVisitante, IdPropiedad, IdCodigoAcceso, FechaEntrada
    FROM inserted;
END;
GO

-- SP: Registrar entrada de visita (sin INSERT directo)
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarEntrada
    @NombreVisitante NVARCHAR(150),
    @CedulaVisitante NVARCHAR(20)  = NULL,
    @IdPropiedad     INT,
    @CodigoQR        NVARCHAR(50)  = NULL,
    @IdVisita        INT           OUTPUT,
    @Mensaje         NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NULLIF(LTRIM(@NombreVisitante), '') IS NULL
    BEGIN SET @Mensaje = 'ERROR: El nombre del visitante es obligatorio.'; RETURN; END

    IF NOT EXISTS (SELECT 1 FROM Propiedad WHERE IdPropiedad = @IdPropiedad)
    BEGIN SET @Mensaje = 'ERROR: La propiedad no existe.'; RETURN; END

    -- Buscar el ID del código si se presentó QR
    DECLARE @IdCodigo INT = NULL;
    IF @CodigoQR IS NOT NULL
    BEGIN
        SELECT @IdCodigo = IdCodigoAcceso
        FROM CodigoAcceso
        WHERE Codigo = @CodigoQR AND Activo = 1 AND FechaVencimiento >= GETDATE();

        IF @IdCodigo IS NULL
        BEGIN SET @Mensaje = 'ERROR: Código QR inválido o vencido.'; RETURN; END
    END;

    BEGIN TRY
        INSERT INTO RegistroVisita (NombreVisitante, CedulaVisitante, IdPropiedad, IdCodigoAcceso)
        VALUES (@NombreVisitante, @CedulaVisitante, @IdPropiedad, @IdCodigo);

        SET @IdVisita = SCOPE_IDENTITY();
        SET @Mensaje  = 'OK: Entrada registrada. ID: ' + CAST(@IdVisita AS NVARCHAR) +
                        CASE WHEN @CodigoQR IS NOT NULL THEN ' (con QR).' ELSE ' (sin QR).' END;
    END TRY
    BEGIN CATCH
        SET @IdVisita = NULL;
        SET @Mensaje  = 'ERROR: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- SP: Registrar salida
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarSalida
    @IdVisita INT,
    @Mensaje  NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM RegistroVisita WHERE IdVisita = @IdVisita)
    BEGIN SET @Mensaje = 'ERROR: La visita no existe.'; RETURN; END

    IF EXISTS (SELECT 1 FROM RegistroVisita WHERE IdVisita = @IdVisita AND FechaSalida IS NOT NULL)
    BEGIN SET @Mensaje = 'ERROR: La salida ya fue registrada.'; RETURN; END

    UPDATE RegistroVisita SET FechaSalida = GETDATE() WHERE IdVisita = @IdVisita;
    SET @Mensaje = 'OK: Salida registrada.';
END;
GO

-- SP: Historial de visitas con filtro por propiedad
CREATE OR ALTER PROCEDURE dbo.sp_HistorialVisitas
    @IdPropiedad INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        rv.IdVisita,
        rv.NombreVisitante,
        ISNULL(rv.CedulaVisitante, '-')                          AS [Cédula],
        p.Codigo                                                  AS [Propiedad],
        CONVERT(NVARCHAR(16), rv.FechaEntrada, 120)              AS [Entrada],
        ISNULL(CONVERT(NVARCHAR(16), rv.FechaSalida, 120),
               'Aún dentro')                                      AS [Salida],
        CASE WHEN rv.IdCodigoAcceso IS NOT NULL
             THEN 'Con QR' ELSE 'Sin QR'
        END                                                       AS [Modo]
    FROM RegistroVisita rv
    INNER JOIN Propiedad p ON p.IdPropiedad = rv.IdPropiedad
    WHERE (@IdPropiedad IS NULL OR rv.IdPropiedad = @IdPropiedad)
    ORDER BY rv.FechaEntrada DESC;
END;
GO

-- ============================================================
-- PRUEBAS
-- ============================================================

PRINT '=== EJERCICIO 1: PROPIEDADES ===';

DECLARE @Id INT, @Msg NVARCHAR(200);

-- Crear propiedades nuevas
EXEC dbo.sp_CrearPropiedad 'C-301', 1, 110, 2, 1, @Id OUTPUT, @Msg OUTPUT; PRINT @Msg;
EXEC dbo.sp_AgregarPropietario @Id, 2, @Msg OUTPUT;                         PRINT @Msg;

-- Errores esperados
EXEC dbo.sp_CrearPropiedad 'A-101', 1, 80, 0, 1, @Id OUTPUT, @Msg OUTPUT;  PRINT @Msg; -- código duplicado
EXEC dbo.sp_CrearPropiedad 'X-999', 1, -5, 0, 1, @Id OUTPUT, @Msg OUTPUT;  PRINT @Msg; -- área inválida
GO

PRINT '-- Reporte completo';          EXEC dbo.sp_ReportePropiedades;
PRINT '-- Filtrar por código A-101';  EXEC dbo.sp_ReportePropiedades @Codigo = 'A-101';
PRINT '-- Filtrar por dueño ID=1';    EXEC dbo.sp_ReportePropiedades @IdPropietario = 1;
GO

PRINT '=== EJERCICIO 2: RESERVAS ===';

DECLARE @IdRes INT, @Msg NVARCHAR(200);

-- Reserva válida
EXEC dbo.sp_CrearReserva 1, 1, 1, '2026-07-15', '10:00', '14:00', 20, @IdRes OUTPUT, @Msg OUTPUT; PRINT @Msg;
-- Traslape de horario
EXEC dbo.sp_CrearReserva 1, 2, 2, '2026-07-15', '11:00', '13:00', 10, @IdRes OUTPUT, @Msg OUTPUT; PRINT @Msg;
-- Excede capacidad (cancha tenis cap=4)
EXEC dbo.sp_CrearReserva 3, 1, 1, '2026-07-20', '08:00', '10:00', 10, @IdRes OUTPUT, @Msg OUTPUT; PRINT @Msg;

-- Aprobar reserva 1
DECLARE @R1 INT = 1;
EXEC dbo.sp_GestionarReserva @R1, 1, NULL, @Msg OUTPUT; PRINT @Msg;
GO

PRINT '-- Reporte completo';           EXEC dbo.sp_ReporteReservas;
PRINT '-- Filtrar por propiedad 1';    EXEC dbo.sp_ReporteReservas @IdPropiedad = 1;
PRINT '-- Filtrar por persona 1';      EXEC dbo.sp_ReporteReservas @IdPersona = 1;
GO

PRINT '=== EJERCICIO 3: CONTROL DE ACCESO ===';

DECLARE @Cod NVARCHAR(50), @Msg NVARCHAR(200);

-- Generar códigos
EXEC dbo.sp_GenerarCodigoAcceso 1, 365, @Cod OUTPUT, @Msg OUTPUT; PRINT @Msg; PRINT 'Código: ' + @Cod;
EXEC dbo.sp_GenerarCodigoAcceso 4, 180, @Cod OUTPUT, @Msg OUTPUT; PRINT @Msg;
-- Persona inexistente
EXEC dbo.sp_GenerarCodigoAcceso 999, 365, @Cod OUTPUT, @Msg OUTPUT; PRINT @Msg;
GO

DECLARE @CodQR NVARCHAR(50), @IdVis INT, @Msg NVARCHAR(200);
SELECT TOP 1 @CodQR = Codigo FROM CodigoAcceso WHERE IdPersona = 1 AND Activo = 1;

-- Entrada con QR válido
EXEC dbo.sp_RegistrarEntrada 'Pedro Ramírez', '205670001', 1, @CodQR, @IdVis OUTPUT, @Msg OUTPUT; PRINT @Msg;
-- Entrada sin QR
EXEC dbo.sp_RegistrarEntrada 'Ana Torres', NULL, 1, NULL, @IdVis OUTPUT, @Msg OUTPUT; PRINT @Msg;
-- QR falso
EXEC dbo.sp_RegistrarEntrada 'Intruso', NULL, 1, 'CODIGO-FALSO', @IdVis OUTPUT, @Msg OUTPUT; PRINT @Msg;
-- Registrar salida
EXEC dbo.sp_RegistrarSalida 1, @Msg OUTPUT; PRINT @Msg;
GO

PRINT '-- Historial de visitas';
EXEC dbo.sp_HistorialVisitas;
GO
