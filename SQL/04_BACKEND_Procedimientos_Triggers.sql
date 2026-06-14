    USE FestCine;
    GO

    SET ANSI_NULLS ON;
    GO
    SET QUOTED_IDENTIFIER ON;
    GO

    IF COL_LENGTH('Entrada', 'Asiento') IS NULL
    BEGIN
        ALTER TABLE Entrada
        ADD Asiento VARCHAR(10) NULL;
    END;
    GO

    IF COL_LENGTH('AbonoProyeccion', 'Asiento') IS NULL
    BEGIN
        ALTER TABLE AbonoProyeccion
        ADD Asiento VARCHAR(10) NULL;
    END;
    GO

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'UX_Entrada_Proyeccion_Asiento'
        AND object_id = OBJECT_ID('Entrada')
    )
    BEGIN
        CREATE UNIQUE INDEX UX_Entrada_Proyeccion_Asiento
        ON Entrada (IdProyeccion, Asiento)
        WHERE Asiento IS NOT NULL;
    END;
    GO

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'UX_AbonoProyeccion_Proyeccion_Asiento'
        AND object_id = OBJECT_ID('AbonoProyeccion')
    )
    BEGIN
        CREATE UNIQUE INDEX UX_AbonoProyeccion_Proyeccion_Asiento
        ON AbonoProyeccion (IdProyeccion, Asiento)
        WHERE Asiento IS NOT NULL;
    END;
    GO

    CREATE OR ALTER TRIGGER TR1_ControlAgenda
    ON Proyeccion
    INSTEAD OF INSERT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF EXISTS
        (
            SELECT 1
            FROM inserted I
            LEFT JOIN Sala S
                ON I.IdSala = S.IdSala
            WHERE S.IdSala IS NULL
        )
        BEGIN
            THROW 51000,
                'No se puede programar la proyección: la sala indicada no existe.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM inserted I
            LEFT JOIN PeliculaEdicion PE
                ON I.IdPeliculaEdicion = PE.IdPeliculaEdicion
            WHERE PE.IdPeliculaEdicion IS NULL
        )
        BEGIN
            THROW 51001,
                'No se puede programar la proyección: la película indicada no existe en esa edición.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM inserted I
            INNER JOIN PeliculaEdicion PE
                ON I.IdPeliculaEdicion = PE.IdPeliculaEdicion
            WHERE PE.EstadoFestival NOT IN ('Seleccionada', 'Premiada')
        )
        BEGIN
            THROW 51002,
                'No se puede programar la proyección: la película no está Seleccionada ni Premiada en esta edición.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM inserted I
            INNER JOIN PeliculaEdicion PE
                ON I.IdPeliculaEdicion = PE.IdPeliculaEdicion
            INNER JOIN Edicion E
                ON PE.IdEdicion = E.IdEdicion
            WHERE
                I.FechaHoraInicio < CAST(E.FechaInicio AS DATETIME)
                OR
                I.FechaHoraInicio >= DATEADD(DAY, 1, CAST(E.FechaFin AS DATETIME))
        )
        BEGIN
            THROW 51003,
                'No se puede programar la proyección: la fecha y hora están fuera del rango de la edición del festival.',
                1;
        END;


        IF EXISTS
        (
            SELECT 1
            FROM inserted Nueva

            INNER JOIN PeliculaEdicion PENueva
                ON Nueva.IdPeliculaEdicion = PENueva.IdPeliculaEdicion
            INNER JOIN Pelicula PelNueva
                ON PENueva.IdPelicula = PelNueva.IdPelicula

            INNER JOIN Proyeccion Existente WITH (UPDLOCK, HOLDLOCK)
                ON Nueva.IdSala = Existente.IdSala
            INNER JOIN PeliculaEdicion PEExistente
                ON Existente.IdPeliculaEdicion = PEExistente.IdPeliculaEdicion
            INNER JOIN Pelicula PelExistente
                ON PEExistente.IdPelicula = PelExistente.IdPelicula

            WHERE
                Nueva.FechaHoraInicio <
                    DATEADD(MINUTE, PelExistente.DuracionMin + 30, Existente.FechaHoraInicio)
                AND
                DATEADD(MINUTE, PelNueva.DuracionMin + 30, Nueva.FechaHoraInicio) >
                    Existente.FechaHoraInicio
        )
        BEGIN
            THROW 51004,
                'No se puede programar la proyección: la sala ya está ocupada en ese rango horario, considerando duración y 30 minutos de limpieza.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM
            (
                SELECT
                    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Fila,
                    I.IdPeliculaEdicion,
                    I.IdSala,
                    I.FechaHoraInicio,
                    P.DuracionMin
                FROM inserted I
                INNER JOIN PeliculaEdicion PE
                    ON I.IdPeliculaEdicion = PE.IdPeliculaEdicion
                INNER JOIN Pelicula P
                    ON PE.IdPelicula = P.IdPelicula
            ) A
            INNER JOIN
            (
                SELECT
                    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Fila,
                    I.IdPeliculaEdicion,
                    I.IdSala,
                    I.FechaHoraInicio,
                    P.DuracionMin
                FROM inserted I
                INNER JOIN PeliculaEdicion PE
                    ON I.IdPeliculaEdicion = PE.IdPeliculaEdicion
                INNER JOIN Pelicula P
                    ON PE.IdPelicula = P.IdPelicula
            ) B
                ON A.Fila < B.Fila
                AND A.IdSala = B.IdSala

            WHERE
                A.FechaHoraInicio <
                    DATEADD(MINUTE, B.DuracionMin + 30, B.FechaHoraInicio)
                AND
                DATEADD(MINUTE, A.DuracionMin + 30, A.FechaHoraInicio) >
                    B.FechaHoraInicio
        )
        BEGIN
            THROW 51005,
                'No se puede programar la proyección: existen cruces de horario entre las nuevas proyecciones insertadas.',
                1;
        END;

        INSERT INTO Proyeccion
        (
            IdPeliculaEdicion,
            IdSala,
            FechaHoraInicio,
            TieneQA,
            AforoDisponibleActual
        )
        SELECT
            I.IdPeliculaEdicion,
            I.IdSala,
            I.FechaHoraInicio,
            I.TieneQA,
            S.CapacidadAsientos
        FROM inserted I
        INNER JOIN Sala S
            ON I.IdSala = S.IdSala;

    END;
    GO


    CREATE OR ALTER VIEW vw_PeliculasDisponibles
    AS
    SELECT
        PE.IdPeliculaEdicion,
        P.IdPelicula,
        P.Titulo,
        P.AnioProduccion,
        P.DuracionMin,
        P.PaisOrigen,
        P.ClasifEdades,
        P.FormatoProyeccion,
        E.IdEdicion,
        E.Anio AS AnioEdicion,
        PE.EstadoFestival
    FROM PeliculaEdicion PE
    INNER JOIN Pelicula P
        ON PE.IdPelicula = P.IdPelicula
    INNER JOIN Edicion E
        ON PE.IdEdicion = E.IdEdicion
    WHERE
        E.Anio = (SELECT MAX(Anio) FROM Edicion)
        AND PE.EstadoFestival IN ('Seleccionada', 'Premiada');
    GO


    CREATE OR ALTER VIEW vw_ProyeccionesDisponibles
    AS
    SELECT
        PR.IdProyeccion,
        PE.IdPeliculaEdicion,
        P.Titulo AS Pelicula,
        P.DuracionMin,
        S.IdSala,
        S.NombreSala,
        SE.NombreSede,
        PR.FechaHoraInicio,
        PR.TieneQA,
        S.CapacidadAsientos,
        PR.AforoDisponibleActual
    FROM Proyeccion PR
    INNER JOIN PeliculaEdicion PE
        ON PR.IdPeliculaEdicion = PE.IdPeliculaEdicion
    INNER JOIN Pelicula P
        ON PE.IdPelicula = P.IdPelicula
    INNER JOIN Edicion E
        ON PE.IdEdicion = E.IdEdicion
    INNER JOIN Sala S
        ON PR.IdSala = S.IdSala
    INNER JOIN Sede SE
        ON S.IdSede = SE.IdSede
    WHERE
        E.Anio = (SELECT MAX(Anio) FROM Edicion)
        AND PR.AforoDisponibleActual > 0;
    GO


    CREATE OR ALTER VIEW vw_TarifasDisponibles
    AS
    SELECT
        IdTarifa,
        TipoTarifa,
        Monto
    FROM Tarifa;
    GO


    CREATE OR ALTER VIEW vw_Asistentes
    AS
    SELECT
        IdAsistente,
        NombreCompleto,
        Email,
        Telefono,
        TipoAsistente
    FROM Asistente;
    GO


    CREATE OR ALTER VIEW vw_SalasDisponibles
    AS
    SELECT
        SA.IdSala,
        SA.NombreSala,
        SA.CapacidadAsientos,
        SE.NombreSede,
        SE.Ciudad
    FROM Sala SA
    INNER JOIN Sede SE
        ON SA.IdSede = SE.IdSede;
    GO


    CREATE OR ALTER VIEW vw_TiposAbono
    AS
    SELECT
        IdTipoAbono,
        NombreTipoAbono,
        Descripcion,
        CantidadMaxProyecciones,
        PrecioBase
    FROM TipoAbono;
    GO


    CREATE OR ALTER VIEW vw_JuradosCategoria
    AS
    SELECT
        JC.IdJuradoCategoria,
        E.Anio AS AnioEdicion,
        CC.IdCategoria,
        CC.NombreCategoria,
        JC.NombreJurado,
        STRING_AGG(PC.NombreCompleto, ', ') AS Miembros
    FROM JuradoCategoria JC
    INNER JOIN CategoriaComp CC
        ON JC.IdCategoria = CC.IdCategoria
    INNER JOIN Edicion E
        ON JC.IdEdicion = E.IdEdicion
    LEFT JOIN MiembroJurado MJ
        ON MJ.IdJuradoCategoria = JC.IdJuradoCategoria
    LEFT JOIN PersonalCine PC
        ON PC.IdPersonal = MJ.IdPersonal
    GROUP BY
        JC.IdJuradoCategoria, E.Anio, CC.IdCategoria, CC.NombreCategoria, JC.NombreJurado;
    GO


    CREATE OR ALTER VIEW vw_MiembrosJurado
    AS
    SELECT
        MJ.IdMiembro,
        PC.NombreCompleto,
        JC.IdCategoria,
        CC.NombreCategoria,
        JC.IdEdicion,
        E.Anio AS AnioEdicion
    FROM MiembroJurado MJ
    INNER JOIN PersonalCine PC
        ON MJ.IdPersonal = PC.IdPersonal
    INNER JOIN JuradoCategoria JC
        ON MJ.IdJuradoCategoria = JC.IdJuradoCategoria
    INNER JOIN CategoriaComp CC
        ON JC.IdCategoria = CC.IdCategoria
    INNER JOIN Edicion E
        ON JC.IdEdicion = E.IdEdicion;
    GO


    CREATE OR ALTER VIEW vw_PeliculasCompetencia
    AS
    SELECT
        PCat.IdCategoria,
        CC.NombreCategoria,
        PE.IdPeliculaEdicion,
        P.Titulo,
        PE.IdEdicion,
        E.Anio AS AnioEdicion
    FROM PeliculaCategoria PCat
    INNER JOIN CategoriaComp CC
        ON PCat.IdCategoria = CC.IdCategoria
    INNER JOIN PeliculaEdicion PE
        ON PCat.IdPeliculaEdicion = PE.IdPeliculaEdicion
    INNER JOIN Pelicula P
        ON PE.IdPelicula = P.IdPelicula
    INNER JOIN Edicion E
        ON PE.IdEdicion = E.IdEdicion;
    GO


    CREATE OR ALTER VIEW vw_Evaluaciones
    AS
    SELECT
        EV.IdEvaluacion,
        E.Anio AS AnioEdicion,
        CC.NombreCategoria,
        P.Titulo AS Pelicula,
        PCine.NombreCompleto AS Jurado,
        EV.Puntuacion,
        EV.Comentario,
        EV.FechaEvaluacion
    FROM Evaluacion EV
    INNER JOIN MiembroJurado MJ
        ON EV.IdMiembro = MJ.IdMiembro
    INNER JOIN PersonalCine PCine
        ON MJ.IdPersonal = PCine.IdPersonal
    INNER JOIN CategoriaComp CC
        ON EV.IdCategoria = CC.IdCategoria
    INNER JOIN PeliculaEdicion PE
        ON EV.IdPeliculaEdicion = PE.IdPeliculaEdicion
    INNER JOIN Pelicula P
        ON PE.IdPelicula = P.IdPelicula
    INNER JOIN Edicion E
        ON PE.IdEdicion = E.IdEdicion;
    GO


    CREATE OR ALTER VIEW vw_Premios
    AS
    SELECT
        PR.IdPremio,
        E.Anio AS AnioEdicion,
        CC.NombreCategoria,
        P.Titulo AS PeliculaGanadora,
        PR.DescripcionPremio
    FROM Premio PR
    INNER JOIN Edicion E
        ON PR.IdEdicion = E.IdEdicion
    INNER JOIN CategoriaComp CC
        ON PR.IdCategoria = CC.IdCategoria
    INNER JOIN PeliculaEdicion PE
        ON PR.IdPeliculaEdicion = PE.IdPeliculaEdicion
    INNER JOIN Pelicula P
        ON PE.IdPelicula = P.IdPelicula;
    GO


    CREATE OR ALTER VIEW vw_PeliculaDetalle
    AS
    SELECT
        P.IdPelicula,
        P.Titulo,
        P.AnioProduccion,
        P.DuracionMin,
        P.PaisOrigen,
        P.Sinopsis,
        P.ClasifEdades,
        P.FormatoProyeccion,
        STRING_AGG(G.NombreGenero, ', ') AS Generos
    FROM Pelicula P
    LEFT JOIN PeliculaGenero PG
        ON P.IdPelicula = PG.IdPelicula
    LEFT JOIN Genero G
        ON PG.IdGenero = G.IdGenero
    GROUP BY
        P.IdPelicula, P.Titulo, P.AnioProduccion, P.DuracionMin, P.PaisOrigen,
        P.Sinopsis, P.ClasifEdades, P.FormatoProyeccion;
    GO


    CREATE OR ALTER VIEW vw_RepartoPelicula
    AS
    SELECT
        RP.IdPelicula,
        PC.IdPersonal,
        PC.NombreCompleto,
        PC.Nacionalidad,
        RP.Rol,
        RP.PersonajeActuado
    FROM RolPelicula RP
    INNER JOIN PersonalCine PC
        ON RP.IdPersonal = PC.IdPersonal;
    GO


    CREATE OR ALTER VIEW vw_HistorialPelicula
    AS
    SELECT
        PE.IdPelicula,
        E.Anio AS AnioEdicion,
        PE.EstadoFestival
    FROM PeliculaEdicion PE
    INNER JOIN Edicion E
        ON PE.IdEdicion = E.IdEdicion;
    GO


    CREATE OR ALTER VIEW vw_Alojamientos
    AS
    SELECT
        A.IdAlojamiento,
        PC.NombreCompleto,
        A.NombreHotel,
        A.NroHabitacion,
        A.CheckIn,
        A.CheckOut,
        E.Anio AS AnioEdicion
    FROM Alojamiento A
    INNER JOIN PersonalCine PC
        ON A.IdPersonal = PC.IdPersonal
    INNER JOIN Edicion E
        ON A.IdEdicion = E.IdEdicion;
    GO


    CREATE OR ALTER VIEW vw_Traslados
    AS
    SELECT
        T.IdTraslado,
        PC.NombreCompleto,
        T.TipoTraslado,
        T.Origen,
        T.Destino,
        T.FechaHora,
        T.NroVuelo,
        E.Anio AS AnioEdicion
    FROM Traslado T
    INNER JOIN PersonalCine PC
        ON T.IdPersonal = PC.IdPersonal
    INNER JOIN Edicion E
        ON T.IdEdicion = E.IdEdicion;
    GO


    CREATE OR ALTER VIEW vw_Patrocinios
    AS
    SELECT
        P.IdPatrocinio,
        PD.NombreEmpresa,
        PD.Contacto,
        PD.Email,
        P.TipoAportacion,
        P.MontoEconomico,
        P.DescripcionEspecie,
        E.Anio AS AnioEdicion
    FROM Patrocinio P
    INNER JOIN Patrocinador PD
        ON P.IdPatrocinador = PD.IdPatrocinador
    INNER JOIN Edicion E
        ON P.IdEdicion = E.IdEdicion;
    GO


    CREATE OR ALTER VIEW vw_EventosParalelos
    AS
    SELECT
        EP.IdEvento,
        EP.TipoEvento,
        EP.Titulo,
        S.NombreSala,
        SE.NombreSede,
        EP.FechaHora,
        EP.AforoMax,
        EP.AforoDisponible,
        EP.CostoInscripcion,
        E.Anio AS AnioEdicion,
        STRING_AGG(
            PC.NombreCompleto + ' (' + ISNULL(EE.RolExpositor, 'Expositor') + ')',
            ', '
        ) AS Expositores
    FROM EventoParalelo EP
    INNER JOIN Edicion E
        ON EP.IdEdicion = E.IdEdicion
    LEFT JOIN Sala S
        ON EP.IdSala = S.IdSala
    LEFT JOIN Sede SE
        ON S.IdSede = SE.IdSede
    LEFT JOIN ExpositorEvento EE
        ON EE.IdEvento = EP.IdEvento
    LEFT JOIN PersonalCine PC
        ON PC.IdPersonal = EE.IdPersonal
    WHERE
        E.Anio = (SELECT MAX(Anio) FROM Edicion)
    GROUP BY
        EP.IdEvento, EP.TipoEvento, EP.Titulo, S.NombreSala, SE.NombreSede,
        EP.FechaHora, EP.AforoMax, EP.AforoDisponible, EP.CostoInscripcion, E.Anio;
    GO



    CREATE OR ALTER PROCEDURE P1_ComprarEntrada
        @IdAsistente INT,
        @IdProyeccion INT,
        @IdTarifa INT,
        @MetodoPago VARCHAR(20)
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @AforoDisponible INT;
        DECLARE @Monto DECIMAL(10,2);
        DECLARE @IdVenta INT;
        DECLARE @IdEntrada INT;
        DECLARE @CodigoAcceso VARCHAR(20);
        DECLARE @NroFactura VARCHAR(20);

        BEGIN TRY

            IF NOT EXISTS (SELECT 1 FROM Asistente WHERE IdAsistente = @IdAsistente)
            BEGIN
                THROW 52001, 'El asistente indicado no existe.', 1;
            END;

            IF NOT EXISTS (SELECT 1 FROM Proyeccion WHERE IdProyeccion = @IdProyeccion)
            BEGIN
                THROW 52002, 'La proyección indicada no existe.', 1;
            END;

            IF @MetodoPago NOT IN ('Efectivo', 'Tarjeta', 'Transferencia', 'QR')
            BEGIN
                THROW 52003, 'El método de pago indicado no es válido.', 1;
            END;

            SELECT @Monto = Monto
            FROM Tarifa
            WHERE IdTarifa = @IdTarifa;

            IF @Monto IS NULL
            BEGIN
                THROW 52004, 'La tarifa indicada no existe.', 1;
            END;

            BEGIN TRANSACTION;

                SELECT @AforoDisponible = AforoDisponibleActual
                FROM Proyeccion WITH (UPDLOCK, HOLDLOCK)
                WHERE IdProyeccion = @IdProyeccion;

                IF @AforoDisponible <= 0
                BEGIN
                    THROW 52005, 'Lo sentimos, no hay aforo disponible para esta función.', 1;
                END;

                INSERT INTO Venta
                (
                    IdAsistente,
                    FechaVenta,
                    TipoVenta,
                    Total,
                    EstadoVenta
                )
                VALUES
                (
                    @IdAsistente,
                    GETDATE(),
                    'Entrada',
                    @Monto,
                    'Completada'
                );

                SET @IdVenta = CAST(SCOPE_IDENTITY() AS INT);

                INSERT INTO Pago
                (
                    IdVenta,
                    MetodoPago,
                    MontoPagado,
                    EstadoPago,
                    FechaPago
                )
                VALUES
                (
                    @IdVenta,
                    @MetodoPago,
                    @Monto,
                    'Aprobado',
                    GETDATE()
                );

                SET @NroFactura = CONCAT('FAC-', RIGHT('000000' + CAST(@IdVenta AS VARCHAR(6)), 6));

                INSERT INTO Factura
                (
                    IdVenta,
                    NroFactura,
                    FechaEmision,
                    MontoTotal
                )
                VALUES
                (
                    @IdVenta,
                    @NroFactura,
                    GETDATE(),
                    @Monto
                );

                SET @CodigoAcceso = CONCAT('ENT-', RIGHT('000000' + CAST(@IdVenta AS VARCHAR(6)), 6));

                INSERT INTO Entrada
                (
                    IdVenta,
                    IdProyeccion,
                    IdTarifa,
                    FechaCompra,
                    CodigoAcceso,
                    Asistio
                )
                VALUES
                (
                    @IdVenta,
                    @IdProyeccion,
                    @IdTarifa,
                    GETDATE(),
                    @CodigoAcceso,
                    0
                );

                SET @IdEntrada = CAST(SCOPE_IDENTITY() AS INT);

                UPDATE Proyeccion
                SET AforoDisponibleActual = AforoDisponibleActual - 1
                WHERE IdProyeccion = @IdProyeccion;

            COMMIT TRANSACTION;

            SELECT
                'Compra registrada correctamente.' AS Mensaje,
                @IdVenta AS IdVenta,
                @IdEntrada AS IdEntrada,
                @CodigoAcceso AS CodigoAcceso,
                @NroFactura AS NroFactura,
                @Monto AS MontoPagado;

        END TRY
        BEGIN CATCH

            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            THROW;

        END CATCH;
    END;
    GO


    CREATE OR ALTER PROCEDURE P1_ComprarEntradas
        @IdAsistente INT,
        @IdProyeccion INT,
        @IdTarifa INT,
        @MetodoPago VARCHAR(20),
        @AsientosCSV VARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @AforoDisponible INT;
        DECLARE @CapacidadSala INT;
        DECLARE @MontoUnitario DECIMAL(10,2);
        DECLARE @Cantidad INT;
        DECLARE @Total DECIMAL(10,2);
        DECLARE @IdVenta INT;
        DECLARE @NroFactura VARCHAR(20);

        DECLARE @Asientos TABLE
        (
            Asiento VARCHAR(10) NOT NULL PRIMARY KEY
        );

        DECLARE @EntradasGeneradas TABLE
        (
            IdEntrada INT,
            Asiento VARCHAR(10),
            CodigoAcceso VARCHAR(20)
        );

        BEGIN TRY

            IF NOT EXISTS (SELECT 1 FROM Asistente WHERE IdAsistente = @IdAsistente)
            BEGIN
                THROW 52101, 'El asistente indicado no existe.', 1;
            END;

            IF NOT EXISTS (SELECT 1 FROM Proyeccion WHERE IdProyeccion = @IdProyeccion)
            BEGIN
                THROW 52102, 'La proyección indicada no existe.', 1;
            END;

            IF @MetodoPago NOT IN ('Efectivo', 'Tarjeta', 'Transferencia', 'QR')
            BEGIN
                THROW 52103, 'El método de pago indicado no es válido.', 1;
            END;

            SELECT @MontoUnitario = Monto
            FROM Tarifa
            WHERE IdTarifa = @IdTarifa;

            IF @MontoUnitario IS NULL
            BEGIN
                THROW 52104, 'La tarifa indicada no existe.', 1;
            END;

            INSERT INTO @Asientos (Asiento)
            SELECT DISTINCT UPPER(LTRIM(RTRIM(value)))
            FROM STRING_SPLIT(@AsientosCSV, ',')
            WHERE LTRIM(RTRIM(value)) <> '';

            SELECT @Cantidad = COUNT(*)
            FROM @Asientos;

            IF @Cantidad = 0
            BEGIN
                THROW 52105, 'Debe elegir al menos un asiento para completar la compra.', 1;
            END;

            IF @Cantidad > 10
            BEGIN
                THROW 52106, 'No se pueden comprar más de 10 boletos en una sola operación.', 1;
            END;

            SET @Total = @MontoUnitario * @Cantidad;

            BEGIN TRANSACTION;

                SELECT
                    @AforoDisponible = PR.AforoDisponibleActual,
                    @CapacidadSala = S.CapacidadAsientos
                FROM Proyeccion PR WITH (UPDLOCK, HOLDLOCK)
                INNER JOIN Sala S
                    ON PR.IdSala = S.IdSala
                WHERE PR.IdProyeccion = @IdProyeccion;

                IF @AforoDisponible < @Cantidad
                BEGIN
                    THROW 52107, 'Lo sentimos, no hay suficientes cupos disponibles para esa cantidad de boletos.', 1;
                END;

                IF EXISTS
                (
                    SELECT 1
                    FROM @Asientos A
                    WHERE
                        TRY_CAST(A.Asiento AS INT) IS NULL
                        OR TRY_CAST(A.Asiento AS INT) < 1
                        OR TRY_CAST(A.Asiento AS INT) > @CapacidadSala
                )
                BEGIN
                    THROW 52108, 'Uno o más asientos seleccionados no existen en la sala de esta función.', 1;
                END;

                IF EXISTS
                (
                    SELECT 1
                    FROM Entrada E WITH (UPDLOCK, HOLDLOCK)
                    INNER JOIN @Asientos A
                        ON E.Asiento = A.Asiento
                    WHERE E.IdProyeccion = @IdProyeccion

                    UNION ALL

                    SELECT 1
                    FROM AbonoProyeccion AP WITH (UPDLOCK, HOLDLOCK)
                    INNER JOIN @Asientos A
                        ON AP.Asiento = A.Asiento
                    WHERE AP.IdProyeccion = @IdProyeccion
                )
                BEGIN
                    THROW 52109, 'Uno o más asientos seleccionados ya fueron vendidos para esta función.', 1;
                END;

                INSERT INTO Venta
                (
                    IdAsistente,
                    FechaVenta,
                    TipoVenta,
                    Total,
                    EstadoVenta
                )
                VALUES
                (
                    @IdAsistente,
                    GETDATE(),
                    'Entrada',
                    @Total,
                    'Completada'
                );

                SET @IdVenta = CAST(SCOPE_IDENTITY() AS INT);

                INSERT INTO Pago
                (
                    IdVenta,
                    MetodoPago,
                    MontoPagado,
                    EstadoPago,
                    FechaPago
                )
                VALUES
                (
                    @IdVenta,
                    @MetodoPago,
                    @Total,
                    'Aprobado',
                    GETDATE()
                );

                SET @NroFactura = CONCAT('FAC-', RIGHT('000000' + CAST(@IdVenta AS VARCHAR(6)), 6));

                INSERT INTO Factura
                (
                    IdVenta,
                    NroFactura,
                    FechaEmision,
                    MontoTotal
                )
                VALUES
                (
                    @IdVenta,
                    @NroFactura,
                    GETDATE(),
                    @Total
                );

                INSERT INTO Entrada
                (
                    IdVenta,
                    IdProyeccion,
                    IdTarifa,
                    Asiento,
                    FechaCompra,
                    CodigoAcceso,
                    Asistio
                )
                OUTPUT inserted.IdEntrada, inserted.Asiento, inserted.CodigoAcceso
                INTO @EntradasGeneradas (IdEntrada, Asiento, CodigoAcceso)
                SELECT
                    @IdVenta,
                    @IdProyeccion,
                    @IdTarifa,
                    A.Asiento,
                    GETDATE(),
                    CONCAT(
                        'ENT-',
                        RIGHT('000000' + CAST(@IdVenta AS VARCHAR(6)), 6),
                        '-',
                        RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY A.Asiento) AS VARCHAR(3)), 3)
                    ),
                    0
                FROM @Asientos A;

                UPDATE Proyeccion
                SET AforoDisponibleActual = AforoDisponibleActual - @Cantidad
                WHERE IdProyeccion = @IdProyeccion;

            COMMIT TRANSACTION;

            SELECT
                'Compra registrada correctamente.' AS Mensaje,
                @IdVenta AS IdVenta,
                EG.IdEntrada,
                EG.Asiento,
                EG.CodigoAcceso,
                @NroFactura AS NroFactura,
                @MontoUnitario AS MontoUnitario,
                @Total AS TotalPagado,
                @Cantidad AS CantidadBoletos
            FROM @EntradasGeneradas EG
            ORDER BY EG.Asiento;

        END TRY
        BEGIN CATCH

            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            THROW;

        END CATCH;
    END;
    GO


    CREATE OR ALTER PROCEDURE T1_VenderAbono
        @IdAsistente INT,
        @IdTipoAbono INT,
        @IdTarifa INT,
        @MetodoPago VARCHAR(20),
        @ProyeccionesCSV VARCHAR(MAX),
        @ForzarFallo BIT = 0,
        @AsientosCSV VARCHAR(MAX) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @PrecioBase DECIMAL(10,2);
        DECLARE @MontoTarifa DECIMAL(10,2);
        DECLARE @Total DECIMAL(10,2);
        DECLARE @CantidadMax INT;
        DECLARE @CantidadProyecciones INT;
        DECLARE @IdVenta INT;
        DECLARE @IdAbono INT;
        DECLARE @NroFactura VARCHAR(20);
        DECLARE @UsaAsientos BIT = 0;

        DECLARE @Proyecciones TABLE
        (
            IdProyeccion INT PRIMARY KEY
        );

        DECLARE @ProyeccionAsientos TABLE
        (
            IdProyeccion INT PRIMARY KEY,
            Asiento VARCHAR(10) NOT NULL
        );

        BEGIN TRY

            IF NOT EXISTS (SELECT 1 FROM Asistente WHERE IdAsistente = @IdAsistente)
            BEGIN
                THROW 53001, 'El asistente indicado no existe.', 1;
            END;

            SELECT
                @PrecioBase = PrecioBase,
                @CantidadMax = CantidadMaxProyecciones
            FROM TipoAbono
            WHERE IdTipoAbono = @IdTipoAbono;

            IF @PrecioBase IS NULL
            BEGIN
                THROW 53002, 'El tipo de abono indicado no existe.', 1;
            END;

            SELECT @MontoTarifa = Monto
            FROM Tarifa
            WHERE IdTarifa = @IdTarifa;

            IF @MontoTarifa IS NULL
            BEGIN
                THROW 53003, 'La tarifa indicada no existe.', 1;
            END;

            IF @MetodoPago NOT IN ('Efectivo', 'Tarjeta', 'Transferencia', 'QR')
            BEGIN
                THROW 53004, 'El método de pago indicado no es válido.', 1;
            END;

            INSERT INTO @Proyecciones (IdProyeccion)
            SELECT DISTINCT TRY_CAST(value AS INT)
            FROM STRING_SPLIT(@ProyeccionesCSV, ',')
            WHERE TRY_CAST(value AS INT) IS NOT NULL;

            IF NULLIF(LTRIM(RTRIM(ISNULL(@AsientosCSV, ''))), '') IS NOT NULL
            BEGIN
                SET @UsaAsientos = 1;

                ;WITH Pares AS
                (
                    SELECT
                        TRY_CAST(LEFT(value, CHARINDEX(':', value) - 1) AS INT) AS IdProyeccion,
                        UPPER(LTRIM(RTRIM(SUBSTRING(value, CHARINDEX(':', value) + 1, 20)))) AS Asiento
                    FROM STRING_SPLIT(@AsientosCSV, ',')
                    WHERE CHARINDEX(':', value) > 1
                )
                INSERT INTO @ProyeccionAsientos (IdProyeccion, Asiento)
                SELECT
                    IdProyeccion,
                    MAX(Asiento) AS Asiento
                FROM Pares
                WHERE IdProyeccion IS NOT NULL
                AND Asiento <> ''
                GROUP BY IdProyeccion;
            END;

            SELECT @CantidadProyecciones = COUNT(*)
            FROM @Proyecciones;

            IF @CantidadProyecciones = 0
            BEGIN
                THROW 53005, 'Debe indicar al menos una proyección para el abono.', 1;
            END;

            IF @CantidadProyecciones > @CantidadMax
            BEGIN
                THROW 53006, 'La cantidad de proyecciones supera el límite permitido para este tipo de abono.', 1;
            END;

            IF @UsaAsientos = 1
            AND (SELECT COUNT(*) FROM @ProyeccionAsientos) <> @CantidadProyecciones
            BEGIN
                THROW 53007, 'Debe elegir un asiento para cada proyección incluida en el abono.', 1;
            END;

            IF EXISTS
            (
                SELECT 1
                FROM @Proyecciones P
                WHERE NOT EXISTS
                (
                    SELECT 1
                    FROM Proyeccion PR
                    WHERE PR.IdProyeccion = P.IdProyeccion
                )
            )
            BEGIN
                THROW 53008, 'Una o más proyecciones indicadas no existen.', 1;
            END;

            IF @UsaAsientos = 1
            AND EXISTS
            (
                SELECT 1
                FROM @ProyeccionAsientos PA
                WHERE NOT EXISTS
                (
                    SELECT 1
                    FROM @Proyecciones P
                    WHERE P.IdProyeccion = PA.IdProyeccion
                )
            )
            BEGIN
                THROW 53009, 'Los asientos enviados no coinciden con las proyecciones del abono.', 1;
            END;

            SET @Total =
                CASE
                    WHEN @MontoTarifa = 0 THEN 0
                    ELSE @PrecioBase
                END;

            BEGIN TRANSACTION;

                IF EXISTS
                (
                    SELECT 1
                    FROM Proyeccion PR WITH (UPDLOCK, HOLDLOCK)
                    INNER JOIN @Proyecciones P
                        ON PR.IdProyeccion = P.IdProyeccion
                    WHERE PR.AforoDisponibleActual <= 0
                )
                BEGIN
                    THROW 53010, 'Una o más proyecciones del abono no tienen aforo disponible.', 1;
                END;

                IF @UsaAsientos = 1
                AND EXISTS
                (
                    SELECT 1
                    FROM @ProyeccionAsientos PA
                    INNER JOIN Proyeccion PR
                        ON PA.IdProyeccion = PR.IdProyeccion
                    INNER JOIN Sala S
                        ON PR.IdSala = S.IdSala
                    WHERE
                        TRY_CAST(PA.Asiento AS INT) IS NULL
                        OR TRY_CAST(PA.Asiento AS INT) < 1
                        OR TRY_CAST(PA.Asiento AS INT) > S.CapacidadAsientos
                )
                BEGIN
                    THROW 53011, 'Uno o más asientos seleccionados no existen en la sala correspondiente.', 1;
                END;

                IF @UsaAsientos = 1
                AND EXISTS
                (
                    SELECT 1
                    FROM @ProyeccionAsientos PA
                    INNER JOIN Entrada E WITH (UPDLOCK, HOLDLOCK)
                        ON PA.IdProyeccion = E.IdProyeccion
                        AND PA.Asiento = E.Asiento

                    UNION ALL

                    SELECT 1
                    FROM @ProyeccionAsientos PA
                    INNER JOIN AbonoProyeccion AP WITH (UPDLOCK, HOLDLOCK)
                        ON PA.IdProyeccion = AP.IdProyeccion
                        AND PA.Asiento = AP.Asiento
                )
                BEGIN
                    THROW 53012, 'Uno o más asientos seleccionados ya fueron reservados.', 1;
                END;

                INSERT INTO Venta
                (
                    IdAsistente,
                    FechaVenta,
                    TipoVenta,
                    Total,
                    EstadoVenta
                )
                VALUES
                (
                    @IdAsistente,
                    GETDATE(),
                    'Abono',
                    @Total,
                    'Completada'
                );

                SET @IdVenta = CAST(SCOPE_IDENTITY() AS INT);

                INSERT INTO Pago
                (
                    IdVenta,
                    MetodoPago,
                    MontoPagado,
                    EstadoPago,
                    FechaPago
                )
                VALUES
                (
                    @IdVenta,
                    @MetodoPago,
                    @Total,
                    'Aprobado',
                    GETDATE()
                );

                IF @ForzarFallo = 1
                BEGIN
                    THROW 53013, 'Fallo simulado de pasarela de pago. Se ejecuta ROLLBACK.', 1;
                END;

                INSERT INTO Abono
                (
                    IdVenta,
                    IdTarifa,
                    IdTipoAbono,
                    FechaCompra,
                    MontoTotal
                )
                VALUES
                (
                    @IdVenta,
                    @IdTarifa,
                    @IdTipoAbono,
                    GETDATE(),
                    @Total
                );

                SET @IdAbono = CAST(SCOPE_IDENTITY() AS INT);

                INSERT INTO AbonoProyeccion
                (
                    IdAbono,
                    IdProyeccion,
                    Asiento,
                    CodigoAcceso,
                    Asistio,
                    FechaUso
                )
                SELECT
                    @IdAbono,
                    P.IdProyeccion,
                    PA.Asiento,
                    CONCAT(
                        'ABO-',
                        RIGHT('000000' + CAST(@IdAbono AS VARCHAR(6)), 6),
                        '-',
                        RIGHT('000' + CAST(P.IdProyeccion AS VARCHAR(3)), 3)
                    ),
                    0,
                    NULL
                FROM @Proyecciones P
                LEFT JOIN @ProyeccionAsientos PA
                    ON P.IdProyeccion = PA.IdProyeccion;

                UPDATE PR
                SET PR.AforoDisponibleActual = PR.AforoDisponibleActual - 1
                FROM Proyeccion PR
                INNER JOIN @Proyecciones P
                    ON PR.IdProyeccion = P.IdProyeccion;

                SET @NroFactura = CONCAT('FAC-', RIGHT('000000' + CAST(@IdVenta AS VARCHAR(6)), 6));

                INSERT INTO Factura
                (
                    IdVenta,
                    NroFactura,
                    FechaEmision,
                    MontoTotal
                )
                VALUES
                (
                    @IdVenta,
                    @NroFactura,
                    GETDATE(),
                    @Total
                );

            COMMIT TRANSACTION;

            SELECT
                'Abono vendido correctamente.' AS Mensaje,
                @IdVenta AS IdVenta,
                @IdAbono AS IdAbono,
                AP.IdProyeccion,
                AP.Asiento,
                AP.CodigoAcceso,
                @NroFactura AS NroFactura,
                @Total AS TotalPagado,
                @CantidadProyecciones AS CantidadProyecciones
            FROM AbonoProyeccion AP
            WHERE AP.IdAbono = @IdAbono
            ORDER BY AP.IdProyeccion;

        END TRY
        BEGIN CATCH

            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            THROW;

        END CATCH;
    END;
    GO


    CREATE OR ALTER PROCEDURE P3_InscribirEvento
        @IdAsistente INT,
        @IdEvento INT,
        @MetodoPago VARCHAR(20)
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @AforoDisponible INT;
        DECLARE @Costo DECIMAL(10,2);
        DECLARE @IdVenta INT;
        DECLARE @IdEntradaEvento INT;
        DECLARE @CodigoAcceso VARCHAR(20);
        DECLARE @NroFactura VARCHAR(20);
        DECLARE @IdTarifaGeneral INT;

        BEGIN TRY

            IF NOT EXISTS (SELECT 1 FROM Asistente WHERE IdAsistente = @IdAsistente)
            BEGIN
                THROW 53001, 'El asistente indicado no existe.', 1;
            END;

            IF NOT EXISTS (SELECT 1 FROM EventoParalelo WHERE IdEvento = @IdEvento)
            BEGIN
                THROW 53002, 'El evento indicado no existe.', 1;
            END;

            IF @MetodoPago NOT IN ('Efectivo', 'Tarjeta', 'Transferencia', 'QR')
            BEGIN
                THROW 53003, 'El método de pago indicado no es válido.', 1;
            END;

            SELECT @IdTarifaGeneral = IdTarifa
            FROM Tarifa
            WHERE TipoTarifa = 'General';

            BEGIN TRANSACTION;

                SELECT @AforoDisponible = AforoDisponible, @Costo = CostoInscripcion
                FROM EventoParalelo WITH (UPDLOCK, HOLDLOCK)
                WHERE IdEvento = @IdEvento;

                IF @AforoDisponible <= 0
                BEGIN
                    THROW 53004, 'Lo sentimos, no hay cupos disponibles para este evento.', 1;
                END;

                INSERT INTO Venta
                (
                    IdAsistente,
                    FechaVenta,
                    TipoVenta,
                    Total,
                    EstadoVenta
                )
                VALUES
                (
                    @IdAsistente,
                    GETDATE(),
                    'Evento',
                    @Costo,
                    'Completada'
                );

                SET @IdVenta = CAST(SCOPE_IDENTITY() AS INT);

                INSERT INTO Pago
                (
                    IdVenta,
                    MetodoPago,
                    MontoPagado,
                    EstadoPago,
                    FechaPago
                )
                VALUES
                (
                    @IdVenta,
                    @MetodoPago,
                    @Costo,
                    'Aprobado',
                    GETDATE()
                );

                SET @NroFactura = CONCAT('FAC-', RIGHT('000000' + CAST(@IdVenta AS VARCHAR(6)), 6));

                INSERT INTO Factura
                (
                    IdVenta,
                    NroFactura,
                    FechaEmision,
                    MontoTotal
                )
                VALUES
                (
                    @IdVenta,
                    @NroFactura,
                    GETDATE(),
                    @Costo
                );

                SET @CodigoAcceso = CONCAT('EVT-', RIGHT('000000' + CAST(@IdVenta AS VARCHAR(6)), 6));

                INSERT INTO EntradaEvento
                (
                    IdVenta,
                    IdEvento,
                    IdTarifa,
                    FechaCompra,
                    CodigoAcceso,
                    Asistio
                )
                VALUES
                (
                    @IdVenta,
                    @IdEvento,
                    @IdTarifaGeneral,
                    GETDATE(),
                    @CodigoAcceso,
                    0
                );

                SET @IdEntradaEvento = CAST(SCOPE_IDENTITY() AS INT);

                UPDATE EventoParalelo
                SET AforoDisponible = AforoDisponible - 1
                WHERE IdEvento = @IdEvento;

            COMMIT TRANSACTION;

            SELECT
                'Inscripción registrada correctamente.' AS Mensaje,
                @IdVenta AS IdVenta,
                @IdEntradaEvento AS IdEntradaEvento,
                @CodigoAcceso AS CodigoAcceso,
                @NroFactura AS NroFactura,
                @Costo AS MontoPagado;

        END TRY
        BEGIN CATCH

            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            THROW;

        END CATCH;
    END;
    GO

