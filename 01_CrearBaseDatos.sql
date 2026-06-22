-- ============================================================
-- SISTEMA DE ADMINISTRACIÓN DE CONDOMINIOS
-- ISW-522 Aplicación de Base de Datos
-- Script 01: Creación de Base de Datos y Tablas
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'CondominioDB')
BEGIN
    ALTER DATABASE CondominioDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CondominioDB;
END
GO

CREATE DATABASE CondominioDB
    COLLATE Modern_Spanish_CI_AS;
GO

USE CondominioDB;
GO

-- ============================================================
-- MÓDULO: CATÁLOGOS BASE
-- ============================================================

CREATE TABLE Provincia (
    IdProvincia     INT           NOT NULL IDENTITY(1,1),
    Nombre          NVARCHAR(50)  NOT NULL,
    CONSTRAINT PK_Provincia PRIMARY KEY CLUSTERED (IdProvincia),
    CONSTRAINT UQ_Provincia_Nombre UNIQUE (Nombre)
);
GO

CREATE TABLE TipoIdentificacion (
    IdTipoIdentificacion    INT           NOT NULL IDENTITY(1,1),
    Descripcion             NVARCHAR(50)  NOT NULL,   -- Nacional, Pasaporte, DIMEX
    Patron                  NVARCHAR(100) NULL,        -- Expresión regular de validación
    CONSTRAINT PK_TipoIdentificacion PRIMARY KEY CLUSTERED (IdTipoIdentificacion)
);
GO

CREATE TABLE TipoPropiedad (
    IdTipoPropiedad INT           NOT NULL IDENTITY(1,1),
    Descripcion     NVARCHAR(50)  NOT NULL,   -- Apartamento, Casa, Local, Bodega
    CONSTRAINT PK_TipoPropiedad PRIMARY KEY CLUSTERED (IdTipoPropiedad)
);
GO

CREATE TABLE TipoCargoFacturable (
    IdTipoCargo INT           NOT NULL IDENTITY(1,1),
    Descripcion NVARCHAR(50)  NOT NULL,   -- Cuota Mantenimiento, Multa, Extraordinaria, Reserva
    AplicaIVA   BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_TipoCargoFacturable PRIMARY KEY CLUSTERED (IdTipoCargo)
);
GO

CREATE TABLE EstadoReserva (
    IdEstadoReserva INT           NOT NULL IDENTITY(1,1),
    Descripcion     NVARCHAR(30)  NOT NULL,  -- Pendiente, Confirmada, Rechazada, Cancelada
    CONSTRAINT PK_EstadoReserva PRIMARY KEY CLUSTERED (IdEstadoReserva)
);
GO

CREATE TABLE EstadoPago (
    IdEstadoPago    INT           NOT NULL IDENTITY(1,1),
    Descripcion     NVARCHAR(30)  NOT NULL,  -- Pendiente, Pagado, Vencido, Anulado
    CONSTRAINT PK_EstadoPago PRIMARY KEY CLUSTERED (IdEstadoPago)
);
GO

CREATE TABLE Rol (
    IdRol       INT           NOT NULL IDENTITY(1,1),
    Nombre      NVARCHAR(50)  NOT NULL,   -- Administrador, Propietario, Residente, Seguridad
    Descripcion NVARCHAR(200) NULL,
    Activo      BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_Rol PRIMARY KEY CLUSTERED (IdRol),
    CONSTRAINT UQ_Rol_Nombre UNIQUE (Nombre)
);
GO

-- ============================================================
-- MÓDULO: CONFIGURACIÓN DEL CONDOMINIO
-- ============================================================

CREATE TABLE ConfiguracionCondominio (
    IdConfiguracion     INT             NOT NULL IDENTITY(1,1),
    TarifaM2            DECIMAL(10,2)   NOT NULL DEFAULT 450.00,   -- Tarifa por metro cuadrado
    CargoFijo           DECIMAL(10,2)   NOT NULL DEFAULT 5000.00,  -- Cargo fijo mensual
    PorcentajeFondo     DECIMAL(5,2)    NOT NULL DEFAULT 10.00,    -- % fondo de reserva
    TasaMorosidadMensual DECIMAL(5,2)  NOT NULL DEFAULT 2.00,      -- Tasa interés morosidad
    PorcentajeIVA       DECIMAL(5,2)   NOT NULL DEFAULT 13.00,     -- IVA Costa Rica
    Vigente             BIT             NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_ConfiguracionCondominio PRIMARY KEY CLUSTERED (IdConfiguracion)
);
GO

-- ============================================================
-- MÓDULO: PERSONAS (PROPIETARIOS Y RESIDENTES)
-- ============================================================

CREATE TABLE Persona (
    IdPersona               INT             NOT NULL IDENTITY(1,1),
    IdTipoIdentificacion    INT             NOT NULL,
    NumeroIdentificacion    NVARCHAR(20)    NOT NULL,
    Nombre                  NVARCHAR(100)   NOT NULL,
    PrimerApellido          NVARCHAR(100)   NOT NULL,
    SegundoApellido         NVARCHAR(100)   NULL,
    Sexo                    CHAR(1)         NOT NULL,     -- M / F
    Telefono                NVARCHAR(20)    NULL,
    Email                   NVARCHAR(150)   NULL,
    DireccionExacta         NVARCHAR(300)   NULL,
    IdProvincia             INT             NULL,
    Fotografia              VARBINARY(MAX)  NULL,
    EsMoroso                BIT             NOT NULL DEFAULT 0,
    Activo                  BIT             NOT NULL DEFAULT 1,
    FechaCreacion           DATETIME        NOT NULL DEFAULT GETDATE(),
    FechaModificacion       DATETIME        NULL,
    CONSTRAINT PK_Persona PRIMARY KEY CLUSTERED (IdPersona),
    CONSTRAINT UQ_Persona_Identificacion UNIQUE (IdTipoIdentificacion, NumeroIdentificacion),
    CONSTRAINT FK_Persona_TipoIdentificacion FOREIGN KEY (IdTipoIdentificacion)
        REFERENCES TipoIdentificacion (IdTipoIdentificacion),
    CONSTRAINT FK_Persona_Provincia FOREIGN KEY (IdProvincia)
        REFERENCES Provincia (IdProvincia),
    CONSTRAINT CK_Persona_Sexo CHECK (Sexo IN ('M', 'F')),
    CONSTRAINT CK_Persona_Email CHECK (Email LIKE '%@%.%' OR Email IS NULL)
);
GO

-- ============================================================
-- MÓDULO: PROPIEDADES
-- ============================================================

CREATE TABLE Propiedad (
    IdPropiedad         INT             NOT NULL IDENTITY(1,1),
    Codigo              NVARCHAR(20)    NOT NULL,    -- Ej: A-101, B-202
    IdTipoPropiedad     INT             NOT NULL,
    AreaM2              DECIMAL(10,2)   NOT NULL,
    CantidadResidentes  INT             NOT NULL DEFAULT 0,
    CuotaMantenimiento  DECIMAL(10,2)   NOT NULL DEFAULT 0,  -- Calculada automáticamente
    Activa              BIT             NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME        NOT NULL DEFAULT GETDATE(),
    FechaModificacion   DATETIME        NULL,
    CONSTRAINT PK_Propiedad PRIMARY KEY CLUSTERED (IdPropiedad),
    CONSTRAINT UQ_Propiedad_Codigo UNIQUE (Codigo),
    CONSTRAINT FK_Propiedad_TipoPropiedad FOREIGN KEY (IdTipoPropiedad)
        REFERENCES TipoPropiedad (IdTipoPropiedad),
    CONSTRAINT CK_Propiedad_AreaM2 CHECK (AreaM2 > 0),
    CONSTRAINT CK_Propiedad_CantidadResidentes CHECK (CantidadResidentes >= 0)
);
GO

-- Relación muchos a muchos: una propiedad puede tener varios propietarios
CREATE TABLE PropiedadPropietario (
    IdPropiedadPropietario  INT         NOT NULL IDENTITY(1,1),
    IdPropiedad             INT         NOT NULL,
    IdPersona               INT         NOT NULL,
    EsPropietarioPrincipal  BIT         NOT NULL DEFAULT 0,
    FechaAsignacion         DATETIME    NOT NULL DEFAULT GETDATE(),
    FechaDesasignacion      DATETIME    NULL,
    Activo                  BIT         NOT NULL DEFAULT 1,
    CONSTRAINT PK_PropiedadPropietario PRIMARY KEY CLUSTERED (IdPropiedadPropietario),
    CONSTRAINT UQ_PropiedadPropietario UNIQUE (IdPropiedad, IdPersona),
    CONSTRAINT FK_PP_Propiedad FOREIGN KEY (IdPropiedad)
        REFERENCES Propiedad (IdPropiedad),
    CONSTRAINT FK_PP_Persona FOREIGN KEY (IdPersona)
        REFERENCES Persona (IdPersona)
);
GO

-- Residentes asignados a una propiedad
CREATE TABLE PropiedadResidente (
    IdPropiedadResidente    INT         NOT NULL IDENTITY(1,1),
    IdPropiedad             INT         NOT NULL,
    IdPersona               INT         NOT NULL,
    FechaIngreso            DATETIME    NOT NULL DEFAULT GETDATE(),
    FechaSalida             DATETIME    NULL,
    Activo                  BIT         NOT NULL DEFAULT 1,
    CONSTRAINT PK_PropiedadResidente PRIMARY KEY CLUSTERED (IdPropiedadResidente),
    CONSTRAINT FK_PR_Propiedad FOREIGN KEY (IdPropiedad)
        REFERENCES Propiedad (IdPropiedad),
    CONSTRAINT FK_PR_Persona FOREIGN KEY (IdPersona)
        REFERENCES Persona (IdPersona)
);
GO

-- ============================================================
-- MÓDULO: FACTURACIÓN
-- ============================================================

CREATE TABLE CargoFacturable (
    IdCargo             INT             NOT NULL IDENTITY(1,1),
    IdPropiedad         INT             NOT NULL,
    IdTipoCargo         INT             NOT NULL,
    Descripcion         NVARCHAR(200)   NOT NULL,
    MontoBase           DECIMAL(12,2)   NOT NULL,
    PorcentajeIVA       DECIMAL(5,2)    NOT NULL DEFAULT 13.00,
    MontoIVA            DECIMAL(12,2)   NOT NULL DEFAULT 0,
    MontoTotal          DECIMAL(12,2)   NOT NULL DEFAULT 0,
    IdEstadoPago        INT             NOT NULL DEFAULT 1,   -- Pendiente por defecto
    FechaEmision        DATETIME        NOT NULL DEFAULT GETDATE(),
    FechaVencimiento    DATETIME        NOT NULL,
    FechaPago           DATETIME        NULL,
    Observaciones       NVARCHAR(500)   NULL,
    CONSTRAINT PK_CargoFacturable PRIMARY KEY CLUSTERED (IdCargo),
    CONSTRAINT FK_CF_Propiedad FOREIGN KEY (IdPropiedad)
        REFERENCES Propiedad (IdPropiedad),
    CONSTRAINT FK_CF_TipoCargo FOREIGN KEY (IdTipoCargo)
        REFERENCES TipoCargoFacturable (IdTipoCargo),
    CONSTRAINT FK_CF_EstadoPago FOREIGN KEY (IdEstadoPago)
        REFERENCES EstadoPago (IdEstadoPago),
    CONSTRAINT CK_CF_MontoBase CHECK (MontoBase > 0)
);
GO

CREATE TABLE Factura (
    IdFactura           INT             NOT NULL IDENTITY(1,1),
    NumeroFactura       NVARCHAR(30)    NOT NULL,
    IdPropiedad         INT             NOT NULL,
    IdPersona           INT             NOT NULL,   -- A quién se emite
    FechaEmision        DATETIME        NOT NULL DEFAULT GETDATE(),
    MontoSubtotal       DECIMAL(12,2)   NOT NULL,
    MontoIVA            DECIMAL(12,2)   NOT NULL,
    MontoTotal          DECIMAL(12,2)   NOT NULL,
    MontoTotalDolares   DECIMAL(12,2)   NULL,
    TipoCambioDolar     DECIMAL(10,4)   NULL,
    XMLFactura          NVARCHAR(MAX)   NULL,   -- XML completo almacenado
    IdEstadoPago        INT             NOT NULL DEFAULT 1,
    FechaPago           DATETIME        NULL,
    Observaciones       NVARCHAR(500)   NULL,
    CONSTRAINT PK_Factura PRIMARY KEY CLUSTERED (IdFactura),
    CONSTRAINT UQ_Factura_Numero UNIQUE (NumeroFactura),
    CONSTRAINT FK_Factura_Propiedad FOREIGN KEY (IdPropiedad)
        REFERENCES Propiedad (IdPropiedad),
    CONSTRAINT FK_Factura_Persona FOREIGN KEY (IdPersona)
        REFERENCES Persona (IdPersona),
    CONSTRAINT FK_Factura_EstadoPago FOREIGN KEY (IdEstadoPago)
        REFERENCES EstadoPago (IdEstadoPago)
);
GO

CREATE TABLE FacturaDetalle (
    IdFacturaDetalle    INT             NOT NULL IDENTITY(1,1),
    IdFactura           INT             NOT NULL,
    IdCargo             INT             NOT NULL,
    Descripcion         NVARCHAR(200)   NOT NULL,
    MontoBase           DECIMAL(12,2)   NOT NULL,
    PorcentajeIVA       DECIMAL(5,2)    NOT NULL,
    MontoIVA            DECIMAL(12,2)   NOT NULL,
    MontoTotal          DECIMAL(12,2)   NOT NULL,
    CONSTRAINT PK_FacturaDetalle PRIMARY KEY CLUSTERED (IdFacturaDetalle),
    CONSTRAINT FK_FD_Factura FOREIGN KEY (IdFactura)
        REFERENCES Factura (IdFactura),
    CONSTRAINT FK_FD_Cargo FOREIGN KEY (IdCargo)
        REFERENCES CargoFacturable (IdCargo)
);
GO

-- ============================================================
-- MÓDULO: ÁREAS COMUNES Y RESERVAS
-- ============================================================

CREATE TABLE AreaComun (
    IdAreaComun         INT             NOT NULL IDENTITY(1,1),
    Nombre              NVARCHAR(100)   NOT NULL,
    Descripcion         NVARCHAR(300)   NULL,
    CapacidadMaxima     INT             NOT NULL,
    HoraApertura        TIME            NOT NULL DEFAULT '06:00',
    HoraCierre          TIME            NOT NULL DEFAULT '22:00',
    TarifaUso           DECIMAL(10,2)   NOT NULL DEFAULT 0,   -- 0 si es gratis
    RequiereAprobacion  BIT             NOT NULL DEFAULT 1,
    Activa              BIT             NOT NULL DEFAULT 1,
    CONSTRAINT PK_AreaComun PRIMARY KEY CLUSTERED (IdAreaComun),
    CONSTRAINT CK_AreaComun_Capacidad CHECK (CapacidadMaxima > 0),
    CONSTRAINT CK_AreaComun_Horario CHECK (HoraApertura < HoraCierre)
);
GO

CREATE TABLE Reserva (
    IdReserva               INT             NOT NULL IDENTITY(1,1),
    IdAreaComun             INT             NOT NULL,
    IdPropiedad             INT             NOT NULL,
    IdPersona               INT             NOT NULL,   -- Quien reserva
    FechaReserva            DATE            NOT NULL,
    HoraInicio              TIME            NOT NULL,
    HoraFin                 TIME            NOT NULL,
    NumeroPersonas          INT             NOT NULL,
    IdEstadoReserva         INT             NOT NULL DEFAULT 1,  -- Pendiente
    MotivoRechazo           NVARCHAR(300)   NULL,
    MotivoCancelacion       NVARCHAR(300)   NULL,
    MontoReserva            DECIMAL(10,2)   NOT NULL DEFAULT 0,
    IdCargoFacturable       INT             NULL,    -- Cargo generado al confirmar
    FechaCreacion           DATETIME        NOT NULL DEFAULT GETDATE(),
    FechaModificacion       DATETIME        NULL,
    CONSTRAINT PK_Reserva PRIMARY KEY CLUSTERED (IdReserva),
    CONSTRAINT FK_Reserva_AreaComun FOREIGN KEY (IdAreaComun)
        REFERENCES AreaComun (IdAreaComun),
    CONSTRAINT FK_Reserva_Propiedad FOREIGN KEY (IdPropiedad)
        REFERENCES Propiedad (IdPropiedad),
    CONSTRAINT FK_Reserva_Persona FOREIGN KEY (IdPersona)
        REFERENCES Persona (IdPersona),
    CONSTRAINT FK_Reserva_Estado FOREIGN KEY (IdEstadoReserva)
        REFERENCES EstadoReserva (IdEstadoReserva),
    CONSTRAINT FK_Reserva_Cargo FOREIGN KEY (IdCargoFacturable)
        REFERENCES CargoFacturable (IdCargo),
    CONSTRAINT CK_Reserva_Horario CHECK (HoraInicio < HoraFin),
    CONSTRAINT CK_Reserva_Personas CHECK (NumeroPersonas > 0)
);
GO

-- ============================================================
-- MÓDULO: CONTROL DE ACCESO
-- ============================================================

CREATE TABLE CodigoAcceso (
    IdCodigoAcceso      INT             NOT NULL IDENTITY(1,1),
    IdPersona           INT             NOT NULL,
    Codigo              NVARCHAR(50)    NOT NULL,   -- Código único generado
    QRDatos             NVARCHAR(500)   NULL,       -- Datos codificados en QR
    FechaGeneracion     DATETIME        NOT NULL DEFAULT GETDATE(),
    FechaVencimiento    DATETIME        NULL,
    Activo              BIT             NOT NULL DEFAULT 1,
    CONSTRAINT PK_CodigoAcceso PRIMARY KEY CLUSTERED (IdCodigoAcceso),
    CONSTRAINT UQ_CodigoAcceso_Codigo UNIQUE (Codigo),
    CONSTRAINT FK_CodigoAcceso_Persona FOREIGN KEY (IdPersona)
        REFERENCES Persona (IdPersona)
);
GO

CREATE TABLE RegistroVisita (
    IdVisita            INT             NOT NULL IDENTITY(1,1),
    -- Visitante (puede no estar registrado en el sistema)
    NombreVisitante     NVARCHAR(200)   NOT NULL,
    IdentificacionVisitante NVARCHAR(20) NULL,
    -- A quién visita
    IdPropiedad         INT             NOT NULL,
    IdPersonaAnfitrion  INT             NOT NULL,
    -- Control
    IdCodigoAcceso      INT             NULL,   -- Si usa QR
    FechaHoraEntrada    DATETIME        NOT NULL DEFAULT GETDATE(),
    FechaHoraSalida     DATETIME        NULL,
    Observaciones       NVARCHAR(300)   NULL,
    RegistradoPor       INT             NOT NULL,   -- IdPersona del guardia/admin
    CONSTRAINT PK_RegistroVisita PRIMARY KEY CLUSTERED (IdVisita),
    CONSTRAINT FK_Visita_Propiedad FOREIGN KEY (IdPropiedad)
        REFERENCES Propiedad (IdPropiedad),
    CONSTRAINT FK_Visita_Anfitrion FOREIGN KEY (IdPersonaAnfitrion)
        REFERENCES Persona (IdPersona),
    CONSTRAINT FK_Visita_CodigoAcceso FOREIGN KEY (IdCodigoAcceso)
        REFERENCES CodigoAcceso (IdCodigoAcceso),
    CONSTRAINT FK_Visita_RegistradoPor FOREIGN KEY (RegistradoPor)
        REFERENCES Persona (IdPersona)
);
GO

-- ============================================================
-- MÓDULO: SEGURIDAD Y USUARIOS
-- ============================================================

CREATE TABLE Usuario (
    IdUsuario       INT             NOT NULL IDENTITY(1,1),
    IdPersona       INT             NOT NULL,
    NombreUsuario   NVARCHAR(50)    NOT NULL,
    PasswordHash    NVARCHAR(256)   NOT NULL,   -- SHA-256 o BCrypt
    Activo          BIT             NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME        NOT NULL DEFAULT GETDATE(),
    UltimoAcceso    DATETIME        NULL,
    IntentosFallidos INT            NOT NULL DEFAULT 0,
    Bloqueado       BIT             NOT NULL DEFAULT 0,
    CONSTRAINT PK_Usuario PRIMARY KEY CLUSTERED (IdUsuario),
    CONSTRAINT UQ_Usuario_NombreUsuario UNIQUE (NombreUsuario),
    CONSTRAINT FK_Usuario_Persona FOREIGN KEY (IdPersona)
        REFERENCES Persona (IdPersona)
);
GO

CREATE TABLE UsuarioRol (
    IdUsuarioRol    INT         NOT NULL IDENTITY(1,1),
    IdUsuario       INT         NOT NULL,
    IdRol           INT         NOT NULL,
    FechaAsignacion DATETIME    NOT NULL DEFAULT GETDATE(),
    Activo          BIT         NOT NULL DEFAULT 1,
    CONSTRAINT PK_UsuarioRol PRIMARY KEY CLUSTERED (IdUsuarioRol),
    CONSTRAINT UQ_UsuarioRol UNIQUE (IdUsuario, IdRol),
    CONSTRAINT FK_UsuarioRol_Usuario FOREIGN KEY (IdUsuario)
        REFERENCES Usuario (IdUsuario),
    CONSTRAINT FK_UsuarioRol_Rol FOREIGN KEY (IdRol)
        REFERENCES Rol (IdRol)
);
GO

-- ============================================================
-- MÓDULO: AUDITORÍA Y BITÁCORAS
-- ============================================================

CREATE TABLE Bitacora (
    IdBitacora      INT             NOT NULL IDENTITY(1,1),
    IdUsuario       INT             NULL,
    Accion          NVARCHAR(100)   NOT NULL,    -- INSERT, UPDATE, DELETE, LOGIN, etc.
    Tabla           NVARCHAR(100)   NULL,
    IdRegistro      INT             NULL,
    DatosAnteriores NVARCHAR(MAX)   NULL,
    DatosNuevos     NVARCHAR(MAX)   NULL,
    FechaHora       DATETIME        NOT NULL DEFAULT GETDATE(),
    IP              NVARCHAR(50)    NULL,
    Resultado       NVARCHAR(20)    NOT NULL DEFAULT 'OK',  -- OK / ERROR
    Detalle         NVARCHAR(500)   NULL,
    CONSTRAINT PK_Bitacora PRIMARY KEY CLUSTERED (IdBitacora),
    CONSTRAINT FK_Bitacora_Usuario FOREIGN KEY (IdUsuario)
        REFERENCES Usuario (IdUsuario)
);
GO

-- ============================================================
-- ÍNDICES ADICIONALES (NonClustered)
-- ============================================================

CREATE NONCLUSTERED INDEX IX_Persona_Identificacion
    ON Persona (NumeroIdentificacion);

CREATE NONCLUSTERED INDEX IX_Propiedad_Codigo
    ON Propiedad (Codigo);

CREATE NONCLUSTERED INDEX IX_CargoFacturable_Propiedad
    ON CargoFacturable (IdPropiedad, IdEstadoPago);

CREATE NONCLUSTERED INDEX IX_Reserva_Fecha
    ON Reserva (IdAreaComun, FechaReserva, HoraInicio, HoraFin);

CREATE NONCLUSTERED INDEX IX_RegistroVisita_Propiedad
    ON RegistroVisita (IdPropiedad, FechaHoraEntrada);

CREATE NONCLUSTERED INDEX IX_CodigoAcceso_Persona
    ON CodigoAcceso (IdPersona, Activo);

CREATE NONCLUSTERED INDEX IX_Bitacora_Fecha
    ON Bitacora (FechaHora, IdUsuario);

PRINT 'Base de datos y tablas creadas exitosamente.';
GO
