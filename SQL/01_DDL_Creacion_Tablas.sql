CREATE DATABASE FestCine;
GO
USE FestCine;
GO


CREATE TABLE Edicion
(
    IdEdicion       INT             PRIMARY KEY,
    Anio            INT             NOT NULL UNIQUE,
    FechaInicio     DATE            NOT NULL,
    FechaFin        DATE            NOT NULL,
    Ciudad          VARCHAR(60)     NOT NULL,
    Tema            VARCHAR(100),
    CONSTRAINT CK_Edicion_Fechas CHECK (FechaFin > FechaInicio)
);

CREATE TABLE Genero
(
    IdGenero        INT             PRIMARY KEY IDENTITY(1,1),
    NombreGenero    VARCHAR(40)     NOT NULL UNIQUE
);

CREATE TABLE Tarifa
(
    IdTarifa        INT             PRIMARY KEY IDENTITY(1,1),
    TipoTarifa      VARCHAR(30)     NOT NULL UNIQUE,
    Monto           DECIMAL(10,2)   NOT NULL CHECK (Monto >= 0)
);


CREATE TABLE TipoAbono
(
    IdTipoAbono             INT             PRIMARY KEY IDENTITY(1,1),
    NombreTipoAbono         VARCHAR(50)     NOT NULL UNIQUE,  
    Descripcion             VARCHAR(150),
    CantidadMaxProyecciones INT             CHECK (CantidadMaxProyecciones > 0),
    PrecioBase              DECIMAL(10,2)   NOT NULL CHECK (PrecioBase >= 0)
);

CREATE TABLE PersonalCine
(
    IdPersonal      INT             PRIMARY KEY IDENTITY(1,1),
    NombreCompleto  VARCHAR(80)     NOT NULL,
    Nacionalidad    VARCHAR(40),
    FechaNac        DATE,
    Biografia       VARCHAR(MAX),    
    Email           VARCHAR(80)     UNIQUE,
    Telefono        VARCHAR(20)
);

CREATE TABLE Sede
(
    IdSede          INT             PRIMARY KEY IDENTITY(1,1),
    NombreSede      VARCHAR(80)     NOT NULL,
    Direccion       VARCHAR(120)    NOT NULL,
    Ciudad          VARCHAR(60)     NOT NULL
);

CREATE TABLE CategoriaComp
(
    IdCategoria     INT             PRIMARY KEY IDENTITY(1,1),
    NombreCategoria VARCHAR(60)     NOT NULL UNIQUE,
    Descripcion     VARCHAR(200)
);

CREATE TABLE Patrocinador
(
    IdPatrocinador  INT             PRIMARY KEY IDENTITY(1,1),
    NombreEmpresa   VARCHAR(80)     NOT NULL,
    Contacto        VARCHAR(80),
    Email           VARCHAR(80),
    Telefono        VARCHAR(20)
);

CREATE TABLE Pelicula
(
    IdPelicula          INT             PRIMARY KEY IDENTITY(1,1),
    Titulo              VARCHAR(120)    NOT NULL,
    AnioProduccion      INT             NOT NULL CHECK (AnioProduccion >= 1888),
    DuracionMin         INT             NOT NULL CHECK (DuracionMin > 0),
    PaisOrigen          VARCHAR(60)     NOT NULL,
    Sinopsis            VARCHAR(MAX),   -- VARCHAR(MAX) reemplaza TEXT
    ClasifEdades        VARCHAR(10)     NOT NULL,
    FormatoProyeccion   VARCHAR(10)     NOT NULL
        CONSTRAINT CK_Pelicula_Formato CHECK (FormatoProyeccion IN ('Digital', '35mm', 'IMAX'))
);

CREATE TABLE PeliculaGenero
(
    IdPelicula      INT     NOT NULL,
    IdGenero        INT     NOT NULL,
    CONSTRAINT PK_PeliculaGenero    PRIMARY KEY (IdPelicula, IdGenero),
    CONSTRAINT FK_PelGen_Pel        FOREIGN KEY (IdPelicula) REFERENCES Pelicula,
    CONSTRAINT FK_PelGen_Gen        FOREIGN KEY (IdGenero)   REFERENCES Genero
);

CREATE TABLE PeliculaEdicion
(
    IdPeliculaEdicion   INT             PRIMARY KEY IDENTITY(1,1),
    IdPelicula          INT             NOT NULL,
    IdEdicion           INT             NOT NULL,
    EstadoFestival      VARCHAR(15)     NOT NULL DEFAULT 'Postulada'
        CONSTRAINT CK_PelEd_Estado CHECK (EstadoFestival IN ('Postulada','Seleccionada','Rechazada','Premiada')),
    CONSTRAINT UK_PeliculaEdicion   UNIQUE (IdPelicula, IdEdicion),
    CONSTRAINT FK_PelEd_Pel         FOREIGN KEY (IdPelicula) REFERENCES Pelicula,
    CONSTRAINT FK_PelEd_Ed          FOREIGN KEY (IdEdicion)  REFERENCES Edicion
);

CREATE TABLE RolPelicula
(
    IdPersonal          INT             NOT NULL,
    IdPelicula          INT             NOT NULL,
    Rol                 VARCHAR(30)     NOT NULL,
    PersonajeActuado    VARCHAR(60),
    CONSTRAINT PK_RolPelicula   PRIMARY KEY (IdPersonal, IdPelicula, Rol),
    CONSTRAINT FK_Rol_Personal  FOREIGN KEY (IdPersonal) REFERENCES PersonalCine,
    CONSTRAINT FK_Rol_Pelicula  FOREIGN KEY (IdPelicula) REFERENCES Pelicula
);

CREATE TABLE Sala
(
    IdSala              INT             PRIMARY KEY IDENTITY(1,1),
    IdSede              INT             NOT NULL,
    NombreSala          VARCHAR(60)     NOT NULL,
    CapacidadAsientos   INT             NOT NULL CHECK (CapacidadAsientos > 0),
    CONSTRAINT UK_Sala          UNIQUE (IdSede, NombreSala),   
    CONSTRAINT FK_Sala_Sede     FOREIGN KEY (IdSede) REFERENCES Sede
);

CREATE TABLE Proyeccion
(
    IdProyeccion            INT             PRIMARY KEY IDENTITY(1,1),
    IdPeliculaEdicion       INT             NOT NULL,
    IdSala                  INT             NOT NULL,
    FechaHoraInicio         DATETIME        NOT NULL,
    TieneQA                 BIT             NOT NULL DEFAULT 0,
    AforoDisponibleActual   INT             NOT NULL CHECK (AforoDisponibleActual >= 0),
    CONSTRAINT FK_Proy_PelEd    FOREIGN KEY (IdPeliculaEdicion) REFERENCES PeliculaEdicion,
    CONSTRAINT FK_Proy_Sala     FOREIGN KEY (IdSala)            REFERENCES Sala
);

CREATE TABLE EventoParalelo
(
    IdEvento            INT             PRIMARY KEY IDENTITY(1,1),
    IdEdicion           INT             NOT NULL,
    IdSala              INT,
    TipoEvento          VARCHAR(20)     NOT NULL
        CONSTRAINT CK_Evento_Tipo CHECK (TipoEvento IN ('Masterclass','Taller','Coctel')),
    Titulo              VARCHAR(100)    NOT NULL,
    AforoMax            INT             NOT NULL CHECK (AforoMax > 0),
    AforoDisponible     INT             NOT NULL CHECK (AforoDisponible >= 0),
    CostoInscripcion    DECIMAL(10,2)   NOT NULL DEFAULT 0 CHECK (CostoInscripcion >= 0),
    FechaHora           DATETIME        NOT NULL,
    CONSTRAINT FK_Evento_Ed     FOREIGN KEY (IdEdicion) REFERENCES Edicion,
    CONSTRAINT FK_Evento_Sala   FOREIGN KEY (IdSala)    REFERENCES Sala
);

CREATE TABLE ExpositorEvento
(
    IdEvento        INT             NOT NULL,
    IdPersonal      INT             NOT NULL,
    RolExpositor    VARCHAR(40),
    CONSTRAINT PK_ExpositorEvento   PRIMARY KEY (IdEvento, IdPersonal),
    CONSTRAINT FK_Exp_Evento        FOREIGN KEY (IdEvento)   REFERENCES EventoParalelo,
    CONSTRAINT FK_Exp_Personal      FOREIGN KEY (IdPersonal) REFERENCES PersonalCine
);

CREATE TABLE JuradoCategoria
(
    IdJuradoCategoria   INT             PRIMARY KEY IDENTITY(1,1),
    IdEdicion           INT             NOT NULL,
    IdCategoria         INT             NOT NULL,
    NombreJurado        VARCHAR(80),
    CONSTRAINT UK_JuradoCat     UNIQUE (IdEdicion, IdCategoria),
    CONSTRAINT FK_JurCat_Ed     FOREIGN KEY (IdEdicion)   REFERENCES Edicion,
    CONSTRAINT FK_JurCat_Cat    FOREIGN KEY (IdCategoria) REFERENCES CategoriaComp
);

CREATE TABLE MiembroJurado
(
    IdMiembro           INT             PRIMARY KEY IDENTITY(1,1),
    IdJuradoCategoria   INT             NOT NULL,
    IdPersonal          INT             NOT NULL,
    CONSTRAINT UK_MiembroJurado     UNIQUE (IdJuradoCategoria, IdPersonal),
    CONSTRAINT FK_Miem_JurCat       FOREIGN KEY (IdJuradoCategoria) REFERENCES JuradoCategoria,
    CONSTRAINT FK_Miem_Personal     FOREIGN KEY (IdPersonal)        REFERENCES PersonalCine
);

CREATE TABLE PeliculaCategoria
(
    IdPeliculaEdicion   INT             NOT NULL,
    IdCategoria         INT             NOT NULL,
    CONSTRAINT PK_PeliculaCategoria PRIMARY KEY (IdPeliculaEdicion, IdCategoria),
    CONSTRAINT FK_PelCat_PelEd      FOREIGN KEY (IdPeliculaEdicion) REFERENCES PeliculaEdicion,
    CONSTRAINT FK_PelCat_Cat        FOREIGN KEY (IdCategoria)       REFERENCES CategoriaComp
);

CREATE TABLE Evaluacion
(
    IdEvaluacion        INT             PRIMARY KEY IDENTITY(1,1),
    IdMiembro           INT             NOT NULL,
    IdPeliculaEdicion   INT             NOT NULL,
    IdCategoria         INT             NOT NULL,
    Puntuacion          DECIMAL(4,1)    NOT NULL
        CONSTRAINT CK_Eval_Punt CHECK (Puntuacion >= 1 AND Puntuacion <= 10),
    Comentario          VARCHAR(MAX),   -- VARCHAR(MAX) reemplaza TEXT
    FechaEvaluacion     DATE            NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UK_Evaluacion        UNIQUE (IdMiembro, IdPeliculaEdicion, IdCategoria),
    CONSTRAINT FK_Eval_Miembro      FOREIGN KEY (IdMiembro)                         REFERENCES MiembroJurado,
    CONSTRAINT FK_Eval_PelCat       FOREIGN KEY (IdPeliculaEdicion, IdCategoria)    -- FK compuesta clave
                                    REFERENCES PeliculaCategoria (IdPeliculaEdicion, IdCategoria)
);

CREATE TABLE Premio
(
    IdPremio            INT             PRIMARY KEY IDENTITY(1,1),
    IdEdicion           INT             NOT NULL,
    IdCategoria         INT             NOT NULL,
    IdPeliculaEdicion   INT             NOT NULL,
    DescripcionPremio   VARCHAR(120),
    CONSTRAINT UK_Premio            UNIQUE (IdEdicion, IdCategoria),   -- Un ganador por categoría por edición
    CONSTRAINT FK_Premio_Ed         FOREIGN KEY (IdEdicion)           REFERENCES Edicion,
    CONSTRAINT FK_Premio_Cat        FOREIGN KEY (IdCategoria)         REFERENCES CategoriaComp,
    CONSTRAINT FK_Premio_PelEd      FOREIGN KEY (IdPeliculaEdicion)   REFERENCES PeliculaEdicion
);

CREATE TABLE Asistente
(
    IdAsistente     INT             PRIMARY KEY IDENTITY(1,1),
    NombreCompleto  VARCHAR(80)     NOT NULL,
    Email           VARCHAR(80)     NOT NULL UNIQUE,
    Telefono        VARCHAR(20),
    TipoAsistente   VARCHAR(20)     NOT NULL DEFAULT 'PublicoGeneral'
        CONSTRAINT CK_Asist_Tipo CHECK (TipoAsistente IN ('PublicoGeneral','Acreditado'))
);

CREATE TABLE Acreditacion
(
    IdAcreditacion      INT             PRIMARY KEY IDENTITY(1,1),
    IdAsistente         INT             NOT NULL,
    IdEdicion           INT             NOT NULL,
    TipoAcred           VARCHAR(15)     NOT NULL
        CONSTRAINT CK_Acred_Tipo CHECK (TipoAcred IN ('Prensa','Industria','VIP','Jurado')),
    FechaVencimiento    DATE            NOT NULL,
    CONSTRAINT UK_Acreditacion  UNIQUE (IdAsistente, IdEdicion, TipoAcred),
    CONSTRAINT FK_Acred_Asist   FOREIGN KEY (IdAsistente) REFERENCES Asistente,
    CONSTRAINT FK_Acred_Ed      FOREIGN KEY (IdEdicion)   REFERENCES Edicion
);

CREATE TABLE Venta
(
    IdVenta         INT             PRIMARY KEY IDENTITY(1,1),
    IdAsistente     INT             NOT NULL,
    FechaVenta      DATETIME        NOT NULL DEFAULT GETDATE(),
    TipoVenta       VARCHAR(10)     NOT NULL
        CONSTRAINT CK_Venta_Tipo CHECK (TipoVenta IN ('Entrada','Abono','Evento')),
    Total           DECIMAL(10,2)   NOT NULL CHECK (Total >= 0),
    EstadoVenta     VARCHAR(15)     NOT NULL DEFAULT 'Completada'
        CONSTRAINT CK_Venta_Estado CHECK (EstadoVenta IN ('Completada','Anulada','Pendiente')),
    CONSTRAINT FK_Venta_Asist FOREIGN KEY (IdAsistente) REFERENCES Asistente
);

CREATE TABLE Pago
(
    IdPago          INT             PRIMARY KEY IDENTITY(1,1),
    IdVenta         INT             NOT NULL UNIQUE,
    MetodoPago      VARCHAR(20)     NOT NULL
        CONSTRAINT CK_Pago_Metodo CHECK (MetodoPago IN ('Efectivo','Tarjeta','Transferencia','QR')),
    MontoPagado     DECIMAL(10,2)   NOT NULL CHECK (MontoPagado >= 0),
    EstadoPago      VARCHAR(15)     NOT NULL DEFAULT 'Aprobado'
        CONSTRAINT CK_Pago_Estado CHECK (EstadoPago IN ('Aprobado','Rechazado','Pendiente')),
    FechaPago       DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Pago_Venta FOREIGN KEY (IdVenta) REFERENCES Venta
);

CREATE TABLE Factura
(
    IdFactura       INT             PRIMARY KEY IDENTITY(1,1),
    IdVenta         INT             NOT NULL UNIQUE,
    NroFactura      VARCHAR(20)     NOT NULL UNIQUE,
    FechaEmision    DATETIME        NOT NULL DEFAULT GETDATE(),
    MontoTotal      DECIMAL(10,2)   NOT NULL CHECK (MontoTotal >= 0),
    CONSTRAINT FK_Factura_Venta FOREIGN KEY (IdVenta) REFERENCES Venta
);

CREATE TABLE Entrada
(
    IdEntrada       INT             PRIMARY KEY IDENTITY(1,1),
    IdVenta         INT             NOT NULL,
    IdProyeccion    INT             NOT NULL,
    IdTarifa        INT             NOT NULL,
    FechaCompra     DATETIME        NOT NULL DEFAULT GETDATE(),
    CodigoAcceso    VARCHAR(20)     NOT NULL UNIQUE,
    Asistio         BIT             NOT NULL DEFAULT 0,
    CONSTRAINT FK_Entrada_Venta     FOREIGN KEY (IdVenta)       REFERENCES Venta,
    CONSTRAINT FK_Entrada_Proy      FOREIGN KEY (IdProyeccion)  REFERENCES Proyeccion,
    CONSTRAINT FK_Entrada_Tarifa    FOREIGN KEY (IdTarifa)      REFERENCES Tarifa
);

CREATE TABLE EntradaEvento
(
    IdEntradaEvento INT             PRIMARY KEY IDENTITY(1,1),
    IdVenta         INT             NOT NULL,
    IdEvento        INT             NOT NULL,
    IdTarifa        INT             NOT NULL,
    FechaCompra     DATETIME        NOT NULL DEFAULT GETDATE(),
    CodigoAcceso    VARCHAR(20)     NOT NULL UNIQUE,
    Asistio         BIT             NOT NULL DEFAULT 0,
    CONSTRAINT FK_EntEvento_Venta   FOREIGN KEY (IdVenta)   REFERENCES Venta,
    CONSTRAINT FK_EntEvento_Evento  FOREIGN KEY (IdEvento)  REFERENCES EventoParalelo,
    CONSTRAINT FK_EntEvento_Tarifa  FOREIGN KEY (IdTarifa)  REFERENCES Tarifa
);

CREATE TABLE Abono
(
    IdAbono         INT             PRIMARY KEY IDENTITY(1,1),
    IdVenta         INT             NOT NULL UNIQUE,
    IdTarifa        INT             NOT NULL,
    IdTipoAbono     INT             NOT NULL,  
    FechaCompra     DATETIME        NOT NULL DEFAULT GETDATE(),
    MontoTotal      DECIMAL(10,2)   NOT NULL CHECK (MontoTotal >= 0),
    CONSTRAINT FK_Abono_Venta       FOREIGN KEY (IdVenta)       REFERENCES Venta,
    CONSTRAINT FK_Abono_Tarifa      FOREIGN KEY (IdTarifa)      REFERENCES Tarifa,
    CONSTRAINT FK_Abono_TipoAbono   FOREIGN KEY (IdTipoAbono)   REFERENCES TipoAbono
);

CREATE TABLE AbonoProyeccion
(
    IdAbono         INT             NOT NULL,
    IdProyeccion    INT             NOT NULL,
    CodigoAcceso    VARCHAR(20)     NOT NULL UNIQUE,
    Asistio         BIT             NOT NULL DEFAULT 0,
    FechaUso        DATETIME,
    CONSTRAINT PK_AbonoProyeccion   PRIMARY KEY (IdAbono, IdProyeccion),
    CONSTRAINT FK_AbonoProy_Abono   FOREIGN KEY (IdAbono)       REFERENCES Abono,
    CONSTRAINT FK_AbonoProy_Proy    FOREIGN KEY (IdProyeccion)  REFERENCES Proyeccion
);

CREATE TABLE Alojamiento
(
    IdAlojamiento   INT             PRIMARY KEY IDENTITY(1,1),
    IdPersonal      INT             NOT NULL,
    IdEdicion       INT             NOT NULL,
    NombreHotel     VARCHAR(80)     NOT NULL,
    NroHabitacion   VARCHAR(10)     NOT NULL,
    CheckIn         DATE            NOT NULL,
    CheckOut        DATE            NOT NULL,
    CONSTRAINT CK_Aloj_Fechas   CHECK (CheckOut > CheckIn),
    CONSTRAINT FK_Aloj_Personal FOREIGN KEY (IdPersonal) REFERENCES PersonalCine,
    CONSTRAINT FK_Aloj_Ed       FOREIGN KEY (IdEdicion)  REFERENCES Edicion
);

CREATE TABLE Traslado
(
    IdTraslado      INT             PRIMARY KEY IDENTITY(1,1),
    IdPersonal      INT             NOT NULL,
    IdEdicion       INT             NOT NULL,
    TipoTraslado    VARCHAR(20)     NOT NULL
        CONSTRAINT CK_Trasl_Tipo CHECK (TipoTraslado IN ('Vuelo','Transfer','Bus','Taxi')),
    Origen          VARCHAR(80)     NOT NULL,
    Destino         VARCHAR(80)     NOT NULL,
    FechaHora       DATETIME        NOT NULL,
    NroVuelo        VARCHAR(15),
    CONSTRAINT FK_Trasl_Personal    FOREIGN KEY (IdPersonal) REFERENCES PersonalCine,
    CONSTRAINT FK_Trasl_Ed          FOREIGN KEY (IdEdicion)  REFERENCES Edicion
);

CREATE TABLE Patrocinio
(
    IdPatrocinio        INT             PRIMARY KEY IDENTITY(1,1),
    IdPatrocinador      INT             NOT NULL,
    IdEdicion           INT             NOT NULL,
    TipoAportacion      VARCHAR(10)     NOT NULL
        CONSTRAINT CK_Patron_Tipo CHECK (TipoAportacion IN ('Economica','Especie')),
    MontoEconomico      DECIMAL(12,2)   CHECK (MontoEconomico >= 0),
    DescripcionEspecie  VARCHAR(200),
    CONSTRAINT FK_Patrocinio_Pat    FOREIGN KEY (IdPatrocinador) REFERENCES Patrocinador,
    CONSTRAINT FK_Patrocinio_Ed     FOREIGN KEY (IdEdicion)      REFERENCES Edicion
);
GO



