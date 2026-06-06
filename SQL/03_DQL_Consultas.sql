USE FestCine;
GO

SELECT
    E.Anio AS Edicion,
    P.IdPelicula,
    P.Titulo AS Pelicula,
    COUNT(DISTINCT PR.IdProyeccion) AS CantidadProyecciones,

    SUM(S.CapacidadAsientos) AS CapacidadTotalProgramada,

    ISNULL(SUM(A.AsistentesReales), 0) AS AsistentesReales,

    CAST(
        ISNULL(SUM(A.AsistentesReales), 0) * 100.0
        / NULLIF(SUM(S.CapacidadAsientos), 0)
        AS DECIMAL(10,2)
    ) AS PorcentajeOcupacion

FROM Edicion E
INNER JOIN PeliculaEdicion PE
    ON E.IdEdicion = PE.IdEdicion
INNER JOIN Pelicula P
    ON PE.IdPelicula = P.IdPelicula
INNER JOIN Proyeccion PR
    ON PE.IdPeliculaEdicion = PR.IdPeliculaEdicion
INNER JOIN Sala S
    ON PR.IdSala = S.IdSala

LEFT JOIN
(
    SELECT
        X.IdProyeccion,
        SUM(X.AsistentesReales) AS AsistentesReales
    FROM
    (
        SELECT
            IdProyeccion,
            COUNT(*) AS AsistentesReales
        FROM Entrada
        WHERE Asistio = 1
        GROUP BY IdProyeccion

        UNION ALL

        SELECT
            IdProyeccion,
            COUNT(*) AS AsistentesReales
        FROM AbonoProyeccion
        WHERE Asistio = 1
        GROUP BY IdProyeccion
    ) X
    GROUP BY X.IdProyeccion
) A
    ON PR.IdProyeccion = A.IdProyeccion

WHERE E.Anio = (SELECT MAX(Anio) FROM Edicion)

GROUP BY
    E.Anio,
    P.IdPelicula,
    P.Titulo

ORDER BY
    AsistentesReales DESC,
    PorcentajeOcupacion DESC;
GO

SELECT
    E.Anio AS Edicion,
    C.NombreCategoria AS Categoria,
    P.Titulo AS PeliculaGanadora,
    PE.EstadoFestival,
    PR.DescripcionPremio,

    CAST(AVG(EV.Puntuacion) AS DECIMAL(10,2)) AS PromedioVotacion,

    COUNT(EV.IdEvaluacion) AS CantidadEvaluaciones

FROM Premio PR
INNER JOIN Edicion E 
    ON PR.IdEdicion = E.IdEdicion
INNER JOIN CategoriaComp C 
    ON PR.IdCategoria = C.IdCategoria
INNER JOIN PeliculaEdicion PE 
    ON PR.IdPeliculaEdicion = PE.IdPeliculaEdicion
INNER JOIN Pelicula P 
    ON PE.IdPelicula = P.IdPelicula

LEFT JOIN Evaluacion EV 
    ON PR.IdPeliculaEdicion = EV.IdPeliculaEdicion
    AND PR.IdCategoria = EV.IdCategoria

WHERE E.Anio = (SELECT MAX(Anio) FROM Edicion)

GROUP BY
    E.Anio,
    C.NombreCategoria,
    P.Titulo,
    PE.EstadoFestival,
    PR.DescripcionPremio

ORDER BY
    C.NombreCategoria;
GO


SELECT
    CASE 
        WHEN V.TipoVenta IN ('Entrada', 'Evento') THEN 'Entradas individuales'
        ELSE 'Abonos'
    END AS TipoAcceso,

    COUNT(*) AS CantidadVentas,
    SUM(V.Total) AS TotalRecaudado

FROM Venta V
INNER JOIN Pago P 
    ON V.IdVenta = P.IdVenta

WHERE 
    V.EstadoVenta = 'Completada'
    AND P.EstadoPago = 'Aprobado'

GROUP BY
    CASE 
        WHEN V.TipoVenta IN ('Entrada', 'Evento') THEN 'Entradas individuales'
        ELSE 'Abonos'
    END

ORDER BY
    TipoAcceso;
GO


SELECT
    Datos.TipoVentaAgrupado,
    Datos.DetalleVenta,
    Datos.TipoTarifa,
    COUNT(*) AS CantidadVentas,
    SUM(Datos.MontoRecaudado) AS TotalRecaudado

FROM
(
    SELECT
        CASE 
            WHEN V.TipoVenta IN ('Entrada', 'Evento') THEN 'Entrada individual'
            ELSE 'Abono'
        END AS TipoVentaAgrupado,

        CASE 
            WHEN V.TipoVenta = 'Entrada' THEN 'Entrada para proyección'
            WHEN V.TipoVenta = 'Evento' THEN 'Entrada para evento paralelo'
            ELSE 'Abono'
        END AS DetalleVenta,

        T.TipoTarifa,
        V.Total AS MontoRecaudado

    FROM Venta V
    INNER JOIN Pago PA 
        ON V.IdVenta = PA.IdVenta
    INNER JOIN Entrada EN 
        ON V.IdVenta = EN.IdVenta
    INNER JOIN Tarifa T 
        ON EN.IdTarifa = T.IdTarifa
    WHERE 
        V.EstadoVenta = 'Completada'
        AND PA.EstadoPago = 'Aprobado'

    UNION ALL

    SELECT
        'Entrada individual' AS TipoVentaAgrupado,
        'Entrada para evento paralelo' AS DetalleVenta,
        T.TipoTarifa,
        V.Total AS MontoRecaudado

    FROM Venta V
    INNER JOIN Pago PA 
        ON V.IdVenta = PA.IdVenta
    INNER JOIN EntradaEvento EE 
        ON V.IdVenta = EE.IdVenta
    INNER JOIN Tarifa T 
        ON EE.IdTarifa = T.IdTarifa
    WHERE 
        V.EstadoVenta = 'Completada'
        AND PA.EstadoPago = 'Aprobado'

    UNION ALL

    SELECT
        'Abono' AS TipoVentaAgrupado,
        TA.NombreTipoAbono AS DetalleVenta,
        T.TipoTarifa,
        V.Total AS MontoRecaudado

    FROM Venta V
    INNER JOIN Pago PA 
        ON V.IdVenta = PA.IdVenta
    INNER JOIN Abono A 
        ON V.IdVenta = A.IdVenta
    INNER JOIN Tarifa T 
        ON A.IdTarifa = T.IdTarifa
    INNER JOIN TipoAbono TA 
        ON A.IdTipoAbono = TA.IdTipoAbono
    WHERE 
        V.EstadoVenta = 'Completada'
        AND PA.EstadoPago = 'Aprobado'

) AS Datos

GROUP BY
    Datos.TipoVentaAgrupado,
    Datos.DetalleVenta,
    Datos.TipoTarifa

ORDER BY
    Datos.TipoVentaAgrupado,
    Datos.TipoTarifa;
GO