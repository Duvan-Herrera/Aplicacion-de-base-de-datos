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

CREATE TABLE Contacto (
    IdContacto    INT           IDENTITY(1,1) PRIMARY KEY,
    Cedula        NVARCHAR(20)  NOT NULL UNIQUE,
    Nombre        NVARCHAR(150) NOT NULL,
    Telefono      NVARCHAR(20)  NULL,
    Email         NVARCHAR(150) NULL,
    EsPropietario BIT           NOT NULL DEFAULT 0,
    EsResidente   BIT           NOT NULL DEFAULT 0,
    PuedeReservar BIT           NOT NULL DEFAULT 0,
    EsFactura     BIT           NOT NULL DEFAULT 0
);

CREATE TABLE Propiedad (
    IdPropiedad        INT           IDENTITY(1,1) PRIMARY KEY,
    Codigo             NVARCHAR(20)  NOT NULL UNIQUE,
    IdTipoPropiedad    INT           NOT NULL REFERENCES TipoPropiedad(IdTipoPropiedad),
    AreaM2             DECIMAL(10,2) NOT NULL CHECK (AreaM2 > 0),
    CuotaMantenimiento DECIMAL(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE PropiedadContacto (
    IdPropiedadContacto INT IDENTITY(1,1) PRIMARY KEY,
    IdPropiedad         INT NOT NULL REFERENCES Propiedad(IdPropiedad),
    IdContacto          INT NOT NULL REFERENCES Contacto(IdContacto),
    UNIQUE (IdPropiedad, IdContacto)
);

CREATE TABLE AreaComun (
    IdAreaComun     INT           IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(100) NOT NULL,
    CapacidadMaxima INT           NOT NULL CHECK (CapacidadMaxima > 0),
    HoraApertura    TIME          NOT NULL,
    HoraCierre      TIME          NOT NULL
);

CREATE TABLE Reserva (
    IdReserva     INT           IDENTITY(1,1) PRIMARY KEY,
    IdAreaComun   INT           NOT NULL REFERENCES AreaComun(IdAreaComun),
    IdPropiedad   INT           NOT NULL REFERENCES Propiedad(IdPropiedad),
    IdContacto    INT           NOT NULL REFERENCES Contacto(IdContacto),
    FechaReserva  DATE          NOT NULL,
    HoraInicio    TIME          NOT NULL,
    HoraFin       TIME          NOT NULL ,
    NumPersonas   INT           NOT NULL CHECK (NumPersonas > 0),
    Estado        NVARCHAR(20)  NOT NULL DEFAULT 'Pendiente',
    MotivoRechazo NVARCHAR(200) NULL,
    CONSTRAINT CK_Reserva_Horario CHECK (HoraFin > HoraInicio)
);

CREATE TABLE CodigoAcceso (
    IdCodigoAcceso   INT           IDENTITY(1,1) PRIMARY KEY,
    IdContacto       INT           NOT NULL REFERENCES Contacto(IdContacto),
    TipoUsuario      NVARCHAR(20)  NOT NULL,  -- Propietario, Residente, Invitado
    Codigo           NVARCHAR(50)  NOT NULL UNIQUE,
    FechaVencimiento DATETIME      NOT NULL,
    Activo           BIT           NOT NULL DEFAULT 1
);

CREATE TABLE RegistroAcceso (
    IdAcceso        INT           IDENTITY(1,1) PRIMARY KEY,
    IdCodigoAcceso  INT           NOT NULL REFERENCES CodigoAcceso(IdCodigoAcceso),
    IdPropiedad     INT           NULL REFERENCES Propiedad(IdPropiedad),
    NombreVisitante NVARCHAR(150) NOT NULL,
    FechaIngreso    DATETIME      NOT NULL DEFAULT GETDATE(),
    FechaSalida     DATETIME      NULL
);
GO

-- DATOS DE EJEMPLO
INSERT INTO TipoPropiedad (Descripcion) VALUES
('Apartamento'), ('Casa'), ('Local Comercial');

INSERT INTO Contacto (Cedula, Nombre, EsPropietario, EsResidente, PuedeReservar, EsFactura) VALUES
('111111111', 'Juan Lopez',      1, 0, 0, 1),  -- Prop1, Propietario, Factura
('222222222', 'Vanesa Alfaro',   1, 0, 0, 0),  -- Prop1, Propietario
('333333333', 'Luis Lopez',      0, 1, 1, 0),  -- Prop1, Residente, puede reservar
('444444444', 'Pedro Lopez',     0, 1, 1, 0),  -- Prop1, Residente, puede reservar
('555555555', 'Victor Perez',    1, 0, 0, 0),  -- Prop2, Propietario
('666666666', 'Maria Aguilar',   1, 0, 0, 1),  -- Prop2, Propietario, Factura
('777777777', 'Carlos Perez',    0, 1, 1, 0),  -- Prop2, Residente, puede reservar
('888888888', 'Wendy Perez',     0, 1, 1, 0),  -- Prop2, Residente, puede reservar
('999999999', 'Melissa Aguilar', 1, 0, 0, 1);  -- Prop3, Propietario, Factura

INSERT INTO Propiedad (Codigo, IdTipoPropiedad, AreaM2, CuotaMantenimiento) VALUES
('A05B', 1, 250, 117500),
('A07A', 1, 225, 106250),
('A08A', 1, 185,  88250);

INSERT INTO PropiedadContacto (IdPropiedad, IdContacto) VALUES
(1,1),(1,2),(1,3),(1,4),
(2,5),(2,6),(2,7),(2,8),
(3,9);

INSERT INTO AreaComun (Nombre, CapacidadMaxima, HoraApertura, HoraCierre) VALUES
('Parrilla A05H',      20, '08:00', '22:00'),
('Cancha Futbol A07L', 22, '06:00', '22:00'),
('Salón Comunal',      50, '08:00', '22:00'),
('Piscina',            30, '07:00', '20:00');

INSERT INTO Reserva (IdAreaComun, IdPropiedad, IdContacto, FechaReserva, HoraInicio, HoraFin, NumPersonas, Estado) VALUES
(1, 1, 3, '2026-06-05', '18:00', '21:00', 10, 'Confirmada'),  
(2, 2, 8, '2026-06-07', '10:00', '12:00',  8, 'Confirmada'); 

INSERT INTO CodigoAcceso (IdContacto, TipoUsuario, Codigo, FechaVencimiento) VALUES
(3, 'Residente',   'CA-202606-0003-AB12CD', '2027-01-01'),
(1, 'Propietario', 'CA-202606-0001-IJ56KL', '2027-01-01');

INSERT INTO RegistroAcceso (IdCodigoAcceso, IdPropiedad, NombreVisitante, FechaIngreso, FechaSalida) VALUES
(1, 1, 'Luis Lopez', '2026-06-05 18:00:00', '2026-06-05 21:05:00'),
(2, 1, 'Juan Lopez', '2026-06-10 08:00:00', '2026-06-10 10:30:00');
GO

-- EJERCICIO 1: PROPIEDADES

-- Función: calcula cuota (AreaM2 x 450) + 5000
CREATE OR ALTER FUNCTION dbo.fn_CuotaMantenimiento(@AreaM2 DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN (@AreaM2 * 450) + 5000
END;
GO

-- SP: Crear propiedad
CREATE OR ALTER PROCEDURE dbo.sp_CrearPropiedad
    @Codigo          NVARCHAR(20),
    @IdTipoPropiedad INT,
    @AreaM2          DECIMAL(10,2),
    @IdContacto      INT,
    @IdPropiedad     INT           OUTPUT,
    @Mensaje         NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NULLIF(LTRIM(@Codigo), '') IS NULL
    BEGIN SET @Mensaje = 'ERROR: El código es obligatorio.'; RETURN; END

    IF EXISTS (SELECT 1 FROM Propiedad WHERE Codigo = @Codigo)
    BEGIN SET @Mensaje = 'ERROR: Ya existe una propiedad con el código ' + @Codigo; RETURN; END

    IF @AreaM2 IS NULL OR @AreaM2 <= 0
    BEGIN SET @Mensaje = 'ERROR: El área debe ser mayor a cero.'; RETURN; END

    IF NOT EXISTS (SELECT 1 FROM TipoPropiedad WHERE IdTipoPropiedad = @IdTipoPropiedad)
    BEGIN SET @Mensaje = 'ERROR: El tipo de propiedad no existe.'; RETURN; END

    IF NOT EXISTS (SELECT 1 FROM Contacto WHERE IdContacto = @IdContacto AND EsPropietario = 1)
    BEGIN SET @Mensaje = 'ERROR: El contacto no existe o no es propietario.'; RETURN; END

    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @Cuota DECIMAL(10,2) = dbo.fn_CuotaMantenimiento(@AreaM2);

        INSERT INTO Propiedad (Codigo, IdTipoPropiedad, AreaM2, CuotaMantenimiento)
        VALUES (@Codigo, @IdTipoPropiedad, @AreaM2, @Cuota);

        SET @IdPropiedad = SCOPE_IDENTITY();

        INSERT INTO PropiedadContacto (IdPropiedad, IdContacto)
        VALUES (@IdPropiedad, @IdContacto);

        COMMIT;
        SET @Mensaje = 'OK: Propiedad ' + @Codigo + ' creada. Cuota: ₡' + FORMAT(@Cuota, 'N0');
    END TRY
    BEGIN CATCH
        ROLLBACK;
        SET @Mensaje = 'ERROR: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- SP: Agregar contacto a propiedad
CREATE OR ALTER PROCEDURE dbo.sp_AgregarContactoPropiedad
    @IdPropiedad INT,
    @IdContacto  INT,
    @Mensaje     NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Propiedad WHERE IdPropiedad = @IdPropiedad)
    BEGIN SET @Mensaje = 'ERROR: La propiedad no existe.'; RETURN; END

    IF NOT EXISTS (SELECT 1 FROM Contacto WHERE IdContacto = @IdContacto)
    BEGIN SET @Mensaje = 'ERROR: El contacto no existe.'; RETURN; END

    IF EXISTS (SELECT 1 FROM PropiedadContacto WHERE IdPropiedad = @IdPropiedad AND IdContacto = @IdContacto)
    BEGIN SET @Mensaje = 'ERROR: Ese contacto ya está en esta propiedad.'; RETURN; END

    INSERT INTO PropiedadContacto (IdPropiedad, IdContacto) VALUES (@IdPropiedad, @IdContacto);
    SET @Mensaje = 'OK: Contacto agregado a la propiedad.';
END;
GO

-- SP: Reporte de propiedades
-- Filtros: por código de propiedad, por dueño
CREATE OR ALTER PROCEDURE dbo.sp_ReportePropiedades
    @Codigo     NVARCHAR(20) = NULL,
    @IdContacto INT          = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.Codigo                                        AS [Código],
        tp.Descripcion                                  AS [Tipo],
        CAST(p.AreaM2 AS NVARCHAR) + ' m²'             AS [Tamaño],
        '₡' + FORMAT(p.CuotaMantenimiento, 'N0')       AS [Cuota],
        STUFF((
            SELECT ', ' + c.Nombre +
                   CASE WHEN c.EsFactura = 1 THEN ' (Factura)' ELSE '' END
            FROM PropiedadContacto pc
            INNER JOIN Contacto c ON c.IdContacto = pc.IdContacto
            WHERE pc.IdPropiedad   = p.IdPropiedad
              AND c.EsPropietario  = 1
            FOR XML PATH('')
        ), 1, 2, '')                                    AS [Propietarios],
        ISNULL(STUFF((
            SELECT ', ' + c.Nombre +
                   CASE WHEN c.PuedeReservar = 1 THEN ' (puede reservar)' ELSE '' END
            FROM PropiedadContacto pc
            INNER JOIN Contacto c ON c.IdContacto = pc.IdContacto
            WHERE pc.IdPropiedad = p.IdPropiedad
              AND c.EsResidente  = 1
            FOR XML PATH('')
        ), 1, 2, ''), '-')                              AS [Residentes]
    FROM Propiedad p
    INNER JOIN TipoPropiedad tp ON tp.IdTipoPropiedad = p.IdTipoPropiedad
    WHERE (@Codigo     IS NULL OR p.Codigo LIKE '%' + @Codigo + '%')
      AND (@IdContacto IS NULL OR EXISTS (
              SELECT 1 FROM PropiedadContacto pc
              INNER JOIN Contacto c ON c.IdContacto = pc.IdContacto
              WHERE pc.IdPropiedad  = p.IdPropiedad
                AND pc.IdContacto   = @IdContacto
                AND c.EsPropietario = 1))
    ORDER BY p.Codigo;
END;
GO

-- EJERCICIO 2: RESERVAS
-- SP: Crear reserva
CREATE OR ALTER PROCEDURE dbo.sp_CrearReserva
    @IdAreaComun INT,
    @IdPropiedad INT,
    @IdContacto  INT,
    @Fecha       DATE,
    @HoraInicio  TIME,
    @HoraFin     TIME,
    @NumPersonas INT,
    @IdReserva   INT           OUTPUT,
    @Mensaje     NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM AreaComun WHERE IdAreaComun = @IdAreaComun)
    BEGIN SET @Mensaje = 'ERROR: El área común no existe.'; RETURN; END

    IF NOT EXISTS (SELECT 1 FROM Propiedad WHERE IdPropiedad = @IdPropiedad)
    BEGIN SET @Mensaje = 'ERROR: La propiedad no existe.'; RETURN; END

    -- Debe pertenecer a la propiedad y tener permiso de reservar
    IF NOT EXISTS (
        SELECT 1 FROM PropiedadContacto pc
        INNER JOIN Contacto c ON c.IdContacto = pc.IdContacto
        WHERE pc.IdPropiedad  = @IdPropiedad
          AND pc.IdContacto   = @IdContacto
          AND c.PuedeReservar = 1
    )
    BEGIN SET @Mensaje = 'ERROR: El contacto no tiene permiso para reservar en esta propiedad.'; RETURN; END

    IF @Fecha < CAST(GETDATE() AS DATE)
    BEGIN SET @Mensaje = 'ERROR: La fecha no puede ser en el pasado.'; RETURN; END

    IF @HoraInicio >= @HoraFin
    BEGIN SET @Mensaje = 'ERROR: La hora inicio debe ser menor a la hora fin.'; RETURN; END

    DECLARE @Apertura TIME, @Cierre TIME, @CapMax INT;
    SELECT @Apertura = HoraApertura, @Cierre = HoraCierre, @CapMax = CapacidadMaxima
    FROM AreaComun WHERE IdAreaComun = @IdAreaComun;

    IF @HoraInicio < @Apertura OR @HoraFin > @Cierre
    BEGIN
        SET @Mensaje = 'ERROR: Horario fuera del rango del área (' +
            FORMAT(@Apertura,'hh\:mm') + ' - ' + FORMAT(@Cierre,'hh\:mm') + ').';
        RETURN;
    END

    IF @NumPersonas > @CapMax
    BEGIN
        SET @Mensaje = 'ERROR: Supera la capacidad máxima de ' + CAST(@CapMax AS NVARCHAR) + ' personas.';
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM Reserva
        WHERE IdAreaComun  = @IdAreaComun
          AND FechaReserva = @Fecha
          AND Estado IN ('Pendiente','Confirmada')
          AND @HoraInicio  < HoraFin
          AND @HoraFin     > HoraInicio
    )
    BEGIN SET @Mensaje = 'ERROR: El área no está disponible en ese horario.'; RETURN; END

    INSERT INTO Reserva (IdAreaComun, IdPropiedad, IdContacto, FechaReserva, HoraInicio, HoraFin, NumPersonas)
    VALUES (@IdAreaComun, @IdPropiedad, @IdContacto, @Fecha, @HoraInicio, @HoraFin, @NumPersonas);

    SET @IdReserva = SCOPE_IDENTITY();
    SET @Mensaje   = 'OK: Reserva creada (Pendiente). ID: ' + CAST(@IdReserva AS NVARCHAR);
END;
GO

-- SP: Aprobar o rechazar reserva
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
-- Filtros: por propiedad, por contacto que reservó
CREATE OR ALTER PROCEDURE dbo.sp_ReporteReservas
    @IdPropiedad INT = NULL,
    @IdContacto  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.Nombre                                        AS [Área Reservada],
        CAST(r.FechaReserva AS NVARCHAR(10))           AS [Fecha],
        FORMAT(r.HoraInicio,'hh\:mm') + ' - ' +
        FORMAT(r.HoraFin,'hh\:mm')                     AS [Horario],
        r.Estado                                        AS [Estado],
        c.Nombre                                        AS [Quién Reservó],
        p.Codigo                                        AS [Propiedad]
    FROM Reserva r
    INNER JOIN AreaComun a ON a.IdAreaComun = r.IdAreaComun
    INNER JOIN Propiedad p ON p.IdPropiedad = r.IdPropiedad
    INNER JOIN Contacto  c ON c.IdContacto  = r.IdContacto
    WHERE (@IdPropiedad IS NULL OR r.IdPropiedad = @IdPropiedad)
      AND (@IdContacto  IS NULL OR r.IdContacto  = @IdContacto)
    ORDER BY r.FechaReserva DESC;
END;
GO

-- EJERCICIO 3: CONTROL DE ACCESO

-- SP: Generar código único por contacto
CREATE OR ALTER PROCEDURE dbo.sp_GenerarCodigoAcceso
    @IdContacto   INT,
    @TipoUsuario  NVARCHAR(20),
    @DiasVigencia INT           = 365,
    @Codigo       NVARCHAR(50)  OUTPUT,
    @Mensaje      NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Contacto WHERE IdContacto = @IdContacto)
    BEGIN SET @Mensaje = 'ERROR: El contacto no existe.'; RETURN; END

    IF @TipoUsuario NOT IN ('Propietario','Residente','Invitado')
    BEGIN SET @Mensaje = 'ERROR: Tipo inválido. Use: Propietario, Residente o Invitado.'; RETURN; END

    -- Desactivar código anterior
    UPDATE CodigoAcceso SET Activo = 0
    WHERE IdContacto = @IdContacto AND Activo = 1;

    -- Generar código único CA-AAAAMM-NNNN-XXXXXX
    DECLARE @Nuevo NVARCHAR(50);
    DECLARE @Intentos INT = 0;

    WHILE @Intentos < 10
    BEGIN
        SET @Nuevo = 'CA-' + FORMAT(GETDATE(),'yyyyMM') + '-' +
                     RIGHT('0000' + CAST(@IdContacto AS NVARCHAR), 4) + '-' +
                     UPPER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), '-', ''), 6));

        IF NOT EXISTS (SELECT 1 FROM CodigoAcceso WHERE Codigo = @Nuevo)
            BREAK;

        SET @Intentos += 1;
    END;

    INSERT INTO CodigoAcceso (IdContacto, TipoUsuario, Codigo, FechaVencimiento)
    VALUES (@IdContacto, @TipoUsuario, @Nuevo, DATEADD(DAY, @DiasVigencia, GETDATE()));

    SET @Codigo  = @Nuevo;
    SET @Mensaje = 'OK: Código → ' + @Nuevo + ' | Tipo: ' + @TipoUsuario +
                   ' | Vence: ' + CONVERT(NVARCHAR(10), DATEADD(DAY, @DiasVigencia, GETDATE()), 23);
END;
GO

-- Trigger: valida código antes de registrar ingreso
CREATE OR ALTER TRIGGER trg_ValidarCodigoAcceso
ON RegistroAcceso
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM CodigoAcceso ca
            WHERE ca.IdCodigoAcceso   = i.IdCodigoAcceso
              AND ca.Activo           = 1
              AND ca.FechaVencimiento >= GETDATE()
        )
    )
    BEGIN
        RAISERROR('Acceso denegado: código inválido o vencido.', 16, 1);
        RETURN;
    END;

    INSERT INTO RegistroAcceso (IdCodigoAcceso, IdPropiedad, NombreVisitante, FechaIngreso)
    SELECT IdCodigoAcceso, IdPropiedad, NombreVisitante, FechaIngreso
    FROM inserted;
END;
GO

-- SP: Registrar ingreso
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarIngreso
    @CodigoQR        NVARCHAR(50),
    @IdPropiedad     INT           = NULL,
    @NombreVisitante NVARCHAR(150) = NULL,
    @IdAcceso        INT           OUTPUT,
    @Mensaje         NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdCodigo INT, @Nombre NVARCHAR(150), @Tipo NVARCHAR(20);

    SELECT @IdCodigo = ca.IdCodigoAcceso,
           @Nombre   = c.Nombre,
           @Tipo     = ca.TipoUsuario
    FROM CodigoAcceso ca
    INNER JOIN Contacto c ON c.IdContacto = ca.IdContacto
    WHERE ca.Codigo = @CodigoQR AND ca.Activo = 1 AND ca.FechaVencimiento >= GETDATE();

    IF @IdCodigo IS NULL
    BEGIN SET @Mensaje = 'ERROR: Código inválido o vencido. Acceso denegado.'; RETURN; END

    IF @NombreVisitante IS NULL SET @NombreVisitante = @Nombre;

    BEGIN TRY
        INSERT INTO RegistroAcceso (IdCodigoAcceso, IdPropiedad, NombreVisitante)
        VALUES (@IdCodigo, @IdPropiedad, @NombreVisitante);

        SET @IdAcceso = SCOPE_IDENTITY();
        SET @Mensaje  = 'OK: Ingreso registrado. ID: ' + CAST(@IdAcceso AS NVARCHAR) +
                        ' | ' + @Tipo + ': ' + @Nombre;
    END TRY
    BEGIN CATCH
        SET @IdAcceso = NULL;
        SET @Mensaje  = 'ERROR: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- SP: Registrar salida
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarSalida
    @IdAcceso INT,
    @Mensaje  NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM RegistroAcceso WHERE IdAcceso = @IdAcceso)
    BEGIN SET @Mensaje = 'ERROR: El registro no existe.'; RETURN; END

    IF EXISTS (SELECT 1 FROM RegistroAcceso WHERE IdAcceso = @IdAcceso AND FechaSalida IS NOT NULL)
    BEGIN SET @Mensaje = 'ERROR: La salida ya fue registrada.'; RETURN; END

    UPDATE RegistroAcceso SET FechaSalida = GETDATE() WHERE IdAcceso = @IdAcceso;
    SET @Mensaje = 'OK: Salida registrada.';
END;
GO

-- SP: Reporte de ingresos
-- Filtros: por contacto, por fecha de ingreso
CREATE OR ALTER PROCEDURE dbo.sp_ReporteIngresos
    @IdContacto   INT  = NULL,
    @FechaIngreso DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Nombre                                                 AS [Contacto],
        ca.TipoUsuario                                          AS [Tipo],
        ra.NombreVisitante                                      AS [Visitante],
        ISNULL(p.Codigo, '-')                                   AS [Propiedad],
        CONVERT(NVARCHAR(16), ra.FechaIngreso, 120)             AS [Fecha Ingreso],
        ISNULL(CONVERT(NVARCHAR(16), ra.FechaSalida, 120),
               'Aún dentro')                                     AS [Fecha Salida]
    FROM RegistroAcceso ra
    INNER JOIN CodigoAcceso ca ON ca.IdCodigoAcceso = ra.IdCodigoAcceso
    INNER JOIN Contacto     c  ON c.IdContacto      = ca.IdContacto
    LEFT  JOIN Propiedad    p  ON p.IdPropiedad     = ra.IdPropiedad
    WHERE (@IdContacto   IS NULL OR ca.IdContacto             = @IdContacto)
      AND (@FechaIngreso IS NULL OR CAST(ra.FechaIngreso AS DATE) = @FechaIngreso)
    ORDER BY ra.FechaIngreso DESC;
END;
GO

-- ============================================================
-- PRUEBAS
-- ============================================================

PRINT '=== EJERCICIO 1: PROPIEDADES ===';
EXEC dbo.sp_ReportePropiedades;

PRINT '-- Filtrar por código A05B';
EXEC dbo.sp_ReportePropiedades @Codigo = 'A05B';

PRINT '-- Filtrar por dueño Juan Lopez (ID=1)';
EXEC dbo.sp_ReportePropiedades @IdContacto = 1;

DECLARE @Id INT, @Msg NVARCHAR(200);
EXEC dbo.sp_CrearPropiedad 'C-301', 1, 150, 1, @Id OUTPUT, @Msg OUTPUT; PRINT @Msg;
EXEC dbo.sp_CrearPropiedad 'A05B',  1, 100, 1, @Id OUTPUT, @Msg OUTPUT; PRINT @Msg; -- duplicado
EXEC dbo.sp_CrearPropiedad 'X-999', 1,  -5, 1, @Id OUTPUT, @Msg OUTPUT; PRINT @Msg; -- área inválida
GO

PRINT '';
PRINT '=== EJERCICIO 2: RESERVAS ===';
EXEC dbo.sp_ReporteReservas;

PRINT '-- Filtrar por propiedad 1 (A05B)';
EXEC dbo.sp_ReporteReservas @IdPropiedad = 1;

PRINT '-- Filtrar por Luis Lopez (ID=3)';
EXEC dbo.sp_ReporteReservas @IdContacto = 3;

DECLARE @IdRes INT, @Msg NVARCHAR(200);
EXEC dbo.sp_CrearReserva 4, 1, 4, '2026-07-20', '09:00', '12:00', 5, @IdRes OUTPUT, @Msg OUTPUT; PRINT @Msg;
EXEC dbo.sp_CrearReserva 1, 1, 1, '2026-07-25', '10:00', '14:00', 5, @IdRes OUTPUT, @Msg OUTPUT; PRINT @Msg; -- sin permiso
GO

PRINT '';
PRINT '=== EJERCICIO 3: CONTROL DE ACCESO ===';

DECLARE @Cod NVARCHAR(50), @Msg NVARCHAR(200);
EXEC dbo.sp_GenerarCodigoAcceso 3, 'Residente',   365, @Cod OUTPUT, @Msg OUTPUT; PRINT @Msg;
EXEC dbo.sp_GenerarCodigoAcceso 1, 'Propietario', 365, @Cod OUTPUT, @Msg OUTPUT; PRINT @Msg;
EXEC dbo.sp_GenerarCodigoAcceso 4, 'Invitado',     30, @Cod OUTPUT, @Msg OUTPUT; PRINT @Msg;
GO

DECLARE @CodQR NVARCHAR(50), @IdAcc INT, @Msg NVARCHAR(200);
SELECT TOP 1 @CodQR = Codigo FROM CodigoAcceso WHERE IdContacto = 3 AND Activo = 1;

EXEC dbo.sp_RegistrarIngreso @CodQR, 1, NULL, @IdAcc OUTPUT, @Msg OUTPUT;     PRINT @Msg;
EXEC dbo.sp_RegistrarSalida  @IdAcc, @Msg OUTPUT;                              PRINT @Msg;
EXEC dbo.sp_RegistrarIngreso 'CODIGO-FALSO', 1, NULL, @IdAcc OUTPUT, @Msg OUTPUT; PRINT @Msg;
GO

PRINT '-- Reporte de ingresos completo';
EXEC dbo.sp_ReporteIngresos;

PRINT '-- Filtrar por Luis Lopez (ID=3)';
EXEC dbo.sp_ReporteIngresos @IdContacto = 3;

PRINT '-- Filtrar por fecha de hoy';
EXEC dbo.sp_ReporteIngresos @FechaIngreso = '2026-06-22';
GO
