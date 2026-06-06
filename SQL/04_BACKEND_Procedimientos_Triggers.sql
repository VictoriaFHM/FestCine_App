USE FestCine;
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


CREATE OR ALTER PROCEDURE T1_VenderAbono
    @IdAsistente INT,
    @IdTipoAbono INT,
    @IdTarifa INT,
    @MetodoPago VARCHAR(20),
    @ProyeccionesCSV VARCHAR(MAX),
    @ForzarFallo BIT = 0
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

    DECLARE @Proyecciones TABLE
    (
        IdProyeccion INT PRIMARY KEY
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
            THROW 53007, 'Una o más proyecciones indicadas no existen.', 1;
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
                THROW 53008, 'Una o más proyecciones del abono no tienen aforo disponible.', 1;
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
                THROW 53009, 'Fallo simulado de pasarela de pago. Se ejecuta ROLLBACK.', 1;
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
                CodigoAcceso,
                Asistio,
                FechaUso
            )
            SELECT
                @IdAbono,
                P.IdProyeccion,
                CONCAT(
                    'ABO-',
                    RIGHT('000000' + CAST(@IdAbono AS VARCHAR(6)), 6),
                    '-',
                    RIGHT('000' + CAST(P.IdProyeccion AS VARCHAR(3)), 3)
                ),
                0,
                NULL
            FROM @Proyecciones P;

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
            @NroFactura AS NroFactura,
            @Total AS TotalPagado,
            @CantidadProyecciones AS CantidadProyecciones;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO