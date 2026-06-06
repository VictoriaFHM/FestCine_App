USE FestCine;
GO

/* ============================================================
   04B_PRUEBAS_BACKEND.SQL
   Sistema: FestCine
   Objetivo:
   - Verificar que existen las vistas, procedimientos y trigger.
   - Probar P1_ComprarEntrada.
   - Probar T1_VenderAbono.
   - Probar ROLLBACK de T1_VenderAbono.
   - Probar TR1_ControlAgenda.
   
   NOTA:
   Las pruebas exitosas están dentro de transacciones con ROLLBACK
   para no modificar permanentemente tus datos de prueba.
   ============================================================ */


/* ============================================================
   1. VERIFICAR QUE EXISTEN LOS OBJETOS DEL BACKEND
   Si algún IdObjeto sale NULL, ese objeto no existe.
   ============================================================ */

SELECT 'vw_PeliculasDisponibles' AS Objeto, OBJECT_ID('vw_PeliculasDisponibles', 'V') AS IdObjeto
UNION ALL
SELECT 'vw_ProyeccionesDisponibles', OBJECT_ID('vw_ProyeccionesDisponibles', 'V')
UNION ALL
SELECT 'vw_TarifasDisponibles', OBJECT_ID('vw_TarifasDisponibles', 'V')
UNION ALL
SELECT 'vw_Asistentes', OBJECT_ID('vw_Asistentes', 'V')
UNION ALL
SELECT 'vw_SalasDisponibles', OBJECT_ID('vw_SalasDisponibles', 'V')
UNION ALL
SELECT 'vw_TiposAbono', OBJECT_ID('vw_TiposAbono', 'V')
UNION ALL
SELECT 'P1_ComprarEntrada', OBJECT_ID('P1_ComprarEntrada', 'P')
UNION ALL
SELECT 'T1_VenderAbono', OBJECT_ID('T1_VenderAbono', 'P')
UNION ALL
SELECT 'TR1_ControlAgenda', OBJECT_ID('TR1_ControlAgenda', 'TR');
GO


/* ============================================================
   2. VERIFICAR VISTAS PARA LA INTERFAZ
   Estas vistas serán usadas luego en VS Code.
   ============================================================ */

SELECT TOP 10 *
FROM vw_PeliculasDisponibles;
GO

SELECT TOP 10 *
FROM vw_ProyeccionesDisponibles;
GO

SELECT TOP 10 *
FROM vw_TarifasDisponibles;
GO

SELECT TOP 10 *
FROM vw_Asistentes;
GO

SELECT TOP 10 *
FROM vw_SalasDisponibles;
GO

SELECT TOP 10 *
FROM vw_TiposAbono;
GO


/* ============================================================
   3. CONTADORES INICIALES
   Sirven para comparar antes de probar.
   ============================================================ */

SELECT COUNT(*) AS VentasIniciales
FROM Venta;
GO

SELECT COUNT(*) AS EntradasIniciales
FROM Entrada;
GO

SELECT COUNT(*) AS AbonosIniciales
FROM Abono;
GO

SELECT COUNT(*) AS AbonoProyeccionIniciales
FROM AbonoProyeccion;
GO

SELECT 
    IdProyeccion,
    IdSala,
    FechaHoraInicio,
    AforoDisponibleActual
FROM Proyeccion
WHERE IdProyeccion IN (1, 2, 3)
ORDER BY IdProyeccion;
GO


/* ============================================================
   4. PRUEBA EXITOSA DE P1_COMPRARENTRADA
   Debe:
   - Crear una Venta
   - Crear un Pago
   - Crear una Factura
   - Crear una Entrada
   - Reducir el aforo en 1

   Esta prueba hace ROLLBACK al final.
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT 
        'ANTES DE P1' AS Momento,
        P.IdProyeccion,
        P.AforoDisponibleActual
    FROM Proyeccion P
    WHERE P.IdProyeccion = 1;

    EXEC P1_ComprarEntrada
        @IdAsistente = 1,
        @IdProyeccion = 1,
        @IdTarifa = 1,
        @MetodoPago = 'Efectivo';

    SELECT 
        'DESPUES DE P1 - DENTRO DE LA PRUEBA' AS Momento,
        P.IdProyeccion,
        P.AforoDisponibleActual
    FROM Proyeccion P
    WHERE P.IdProyeccion = 1;

    SELECT TOP 1 *
    FROM Venta
    ORDER BY IdVenta DESC;

    SELECT TOP 1 *
    FROM Entrada
    ORDER BY IdEntrada DESC;

    ROLLBACK TRANSACTION;

    SELECT 'Prueba P1 exitosa. Se hizo ROLLBACK para no modificar datos permanentes.' AS Resultado;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT
        'Error en prueba P1' AS Resultado,
        ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO


/* ============================================================
   5. PRUEBA DE P1 SIN AFORO
   Esta prueba DEBE FALLAR de forma controlada.
   Fuerza temporalmente el aforo a 0 y luego prueba la compra.
   El cambio se revierte con ROLLBACK.
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE Proyeccion
    SET AforoDisponibleActual = 0
    WHERE IdProyeccion = 2;

    EXEC P1_ComprarEntrada
        @IdAsistente = 1,
        @IdProyeccion = 2,
        @IdTarifa = 1,
        @MetodoPago = 'Efectivo';

    ROLLBACK TRANSACTION;

    SELECT 'ERROR: La compra pasó, pero debía fallar por falta de aforo.' AS Resultado;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT
        'P1 bloqueó correctamente la compra sin aforo.' AS Resultado,
        ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO


/* ============================================================
   6. PRUEBA EXITOSA DE T1_VENDERABONO
   Debe:
   - Crear una Venta
   - Crear un Pago
   - Crear una Factura
   - Crear un Abono
   - Crear registros en AbonoProyeccion
   - Reducir aforo en las proyecciones seleccionadas

   Esta prueba hace ROLLBACK al final.
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT 
        'ANTES DE T1' AS Momento,
        IdProyeccion,
        AforoDisponibleActual
    FROM Proyeccion
    WHERE IdProyeccion IN (1, 2, 3)
    ORDER BY IdProyeccion;

    EXEC T1_VenderAbono
        @IdAsistente = 2,
        @IdTipoAbono = 2,
        @IdTarifa = 1,
        @MetodoPago = 'Tarjeta',
        @ProyeccionesCSV = '1,2,3',
        @ForzarFallo = 0;

    SELECT 
        'DESPUES DE T1 - DENTRO DE LA PRUEBA' AS Momento,
        IdProyeccion,
        AforoDisponibleActual
    FROM Proyeccion
    WHERE IdProyeccion IN (1, 2, 3)
    ORDER BY IdProyeccion;

    SELECT TOP 1 *
    FROM Venta
    ORDER BY IdVenta DESC;

    SELECT TOP 1 *
    FROM Abono
    ORDER BY IdAbono DESC;

    SELECT TOP 10 *
    FROM AbonoProyeccion
    ORDER BY IdAbono DESC;

    ROLLBACK TRANSACTION;

    SELECT 'Prueba T1 exitosa. Se hizo ROLLBACK para no modificar datos permanentes.' AS Resultado;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT
        'Error en prueba T1' AS Resultado,
        ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO


/* ============================================================
   7. PRUEBA DE ROLLBACK EN T1_VENDERABONO
   Esta prueba DEBE FALLAR de forma controlada.
   Se fuerza un fallo de pasarela con @ForzarFallo = 1.
   ============================================================ */

DECLARE @VentasAntes INT;
DECLARE @AbonosAntes INT;
DECLARE @AbonoProyAntes INT;

SELECT @VentasAntes = COUNT(*) FROM Venta;
SELECT @AbonosAntes = COUNT(*) FROM Abono;
SELECT @AbonoProyAntes = COUNT(*) FROM AbonoProyeccion;

BEGIN TRY
    EXEC T1_VenderAbono
        @IdAsistente = 3,
        @IdTipoAbono = 2,
        @IdTarifa = 1,
        @MetodoPago = 'QR',
        @ProyeccionesCSV = '4,5,6',
        @ForzarFallo = 1;

    SELECT 'ERROR: El abono pasó, pero debía fallar por pasarela.' AS Resultado;
END TRY
BEGIN CATCH
    SELECT
        'T1 ejecutó ROLLBACK correctamente ante fallo simulado.' AS Resultado,
        ERROR_MESSAGE() AS MensajeError;
END CATCH;

SELECT
    @VentasAntes AS VentasAntes,
    (SELECT COUNT(*) FROM Venta) AS VentasDespues,
    @AbonosAntes AS AbonosAntes,
    (SELECT COUNT(*) FROM Abono) AS AbonosDespues,
    @AbonoProyAntes AS AbonoProyeccionAntes,
    (SELECT COUNT(*) FROM AbonoProyeccion) AS AbonoProyeccionDespues;
GO


/* ============================================================
   8. PRUEBA DEL TRIGGER TR1: INSERCIÓN VÁLIDA
   Esta prueba debe funcionar.
   Se hace ROLLBACK al final para no agregar una proyección extra.
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO Proyeccion
    (
        IdPeliculaEdicion,
        IdSala,
        FechaHoraInicio,
        TieneQA,
        AforoDisponibleActual
    )
    VALUES
    (
        1,
        1,
        '2026-09-09T22:00:00',
        1,
        0
    );

    SELECT TOP 1
        'TR1 permitió correctamente una proyección válida.' AS Resultado,
        *
    FROM Proyeccion
    ORDER BY IdProyeccion DESC;

    ROLLBACK TRANSACTION;

    SELECT 'Prueba TR1 válida completada. Se hizo ROLLBACK.' AS Resultado;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT
        'Error en prueba válida de TR1' AS Resultado,
        ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO


/* ============================================================
   9. PRUEBA DEL TRIGGER TR1: CRUCE DE HORARIO
   Esta prueba DEBE FALLAR de forma controlada.
   Intenta insertar una proyección en una sala y horario ya ocupado.
   ============================================================ */

DECLARE @IdSalaOcupada INT;
DECLARE @FechaOcupada DATETIME;
DECLARE @IdPeliculaEdicionValida INT;

SELECT TOP 1
    @IdSalaOcupada = IdSala,
    @FechaOcupada = FechaHoraInicio
FROM Proyeccion
ORDER BY IdProyeccion;

SELECT TOP 1
    @IdPeliculaEdicionValida = PE.IdPeliculaEdicion
FROM PeliculaEdicion PE
INNER JOIN Edicion E
    ON PE.IdEdicion = E.IdEdicion
WHERE
    E.Anio = (SELECT MAX(Anio) FROM Edicion)
    AND PE.EstadoFestival IN ('Seleccionada', 'Premiada')
ORDER BY PE.IdPeliculaEdicion DESC;

BEGIN TRY
    INSERT INTO Proyeccion
    (
        IdPeliculaEdicion,
        IdSala,
        FechaHoraInicio,
        TieneQA,
        AforoDisponibleActual
    )
    VALUES
    (
        @IdPeliculaEdicionValida,
        @IdSalaOcupada,
        @FechaOcupada,
        0,
        0
    );

    SELECT 'ERROR: La proyección cruzada se insertó, revisar TR1.' AS Resultado;
END TRY
BEGIN CATCH
    SELECT
        'TR1 bloqueó correctamente el cruce de horario.' AS Resultado,
        ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO


/* ============================================================
   10. PRUEBA DEL TRIGGER TR1: FECHA FUERA DE LA EDICIÓN
   Esta prueba DEBE FALLAR de forma controlada.
   ============================================================ */

BEGIN TRY
    INSERT INTO Proyeccion
    (
        IdPeliculaEdicion,
        IdSala,
        FechaHoraInicio,
        TieneQA,
        AforoDisponibleActual
    )
    VALUES
    (
        1,
        1,
        '2030-01-01T10:00:00',
        0,
        0
    );

    SELECT 'ERROR: La proyección fuera de fecha se insertó, revisar TR1.' AS Resultado;
END TRY
BEGIN CATCH
    SELECT
        'TR1 bloqueó correctamente una fecha fuera de la edición.' AS Resultado,
        ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO


/* ============================================================
   11. CONTADORES FINALES
   Si las pruebas con ROLLBACK funcionaron, tus datos deberían
   mantenerse estables salvo que hayas ejecutado pruebas externas.
   ============================================================ */

SELECT COUNT(*) AS VentasFinales
FROM Venta;
GO

SELECT COUNT(*) AS EntradasFinales
FROM Entrada;
GO

SELECT COUNT(*) AS AbonosFinales
FROM Abono;
GO

SELECT COUNT(*) AS AbonoProyeccionFinales
FROM AbonoProyeccion;
GO

SELECT 
    IdProyeccion,
    IdSala,
    FechaHoraInicio,
    AforoDisponibleActual
FROM Proyeccion
WHERE IdProyeccion IN (1, 2, 3)
ORDER BY IdProyeccion;
GO