const express = require("express");
const cors = require("cors");
const { sql, getConnection } = require("./db");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static("public"));

function limpiarMensajeError(error) {
  if (!error) return "Error desconocido.";

  const limpiarTexto = (mensaje) => {
    if (!mensaje) return mensaje;
    const marcaSqlServer = "[SQL Server]";
    const indice = mensaje.lastIndexOf(marcaSqlServer);
    return indice >= 0
      ? mensaje.slice(indice + marcaSqlServer.length).trim()
      : mensaje;
  };

  if (error.originalError?.info?.message) {
    return limpiarTexto(error.originalError.info.message);
  }

  if (error.precedingErrors && error.precedingErrors.length > 0) {
    return limpiarTexto(error.precedingErrors.map(e => e.message).join(" "));
  }

  if (error.message) {
    return limpiarTexto(error.message);
  }

  return String(error);
}

/* ============================================================
   PRUEBA DE CONEXIÓN
   ============================================================ */

app.get("/api/probar-conexion", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT 
        DB_NAME() AS BaseDatos,
        @@SERVERNAME AS Servidor;
    `);

    res.json({
      ok: true,
      mensaje: "Conexión exitosa con SQL Server.",
      data: result.recordset[0]
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      mensaje: limpiarMensajeError(error)
    });
  }
});

/* ============================================================
   VISTAS PARA CARGAR DATOS EN LA INTERFAZ
   ============================================================ */

app.get("/api/edicion-actual", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT IdEdicion, Anio, FechaInicio, FechaFin
      FROM Edicion
      WHERE Anio = (SELECT MAX(Anio) FROM Edicion);
    `);

    res.json(result.recordset[0]);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/asistentes", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT IdAsistente, NombreCompleto, Email, Telefono, TipoAsistente
      FROM vw_Asistentes
      ORDER BY IdAsistente;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.post("/api/asistentes", async (req, res) => {
  try {
    const nombreCompleto = (req.body.nombreCompleto || "").trim();
    const email = (req.body.email || "").trim().toLowerCase();
    const telefono = req.body.telefono ? req.body.telefono.trim() : null;
    const tipoAsistente = req.body.tipoAsistente || "PublicoGeneral";

    if (!nombreCompleto || !email) {
      return res.status(400).json({
        ok: false,
        mensaje: "Debe indicar nombre completo y email del asistente."
      });
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return res.status(400).json({
        ok: false,
        mensaje: "El email del asistente no tiene un formato válido."
      });
    }

    const pool = await getConnection();

    const result = await pool.request()
      .input("NombreCompleto", sql.VarChar(80), nombreCompleto)
      .input("Email", sql.VarChar(80), email)
      .input("Telefono", sql.VarChar(20), telefono)
      .input("TipoAsistente", sql.VarChar(20), tipoAsistente)
      .query(`
        IF EXISTS (SELECT 1 FROM Asistente WHERE LOWER(Email) = @Email)
        BEGIN
          SELECT
            IdAsistente,
            NombreCompleto,
            Email,
            Telefono,
            TipoAsistente,
            CAST(0 AS BIT) AS FueCreado
          FROM Asistente
          WHERE LOWER(Email) = @Email;

          RETURN;
        END;

        INSERT INTO Asistente (NombreCompleto, Email, Telefono, TipoAsistente)
        VALUES (@NombreCompleto, @Email, @Telefono, @TipoAsistente);

        SELECT
          CAST(SCOPE_IDENTITY() AS INT) AS IdAsistente,
          @NombreCompleto AS NombreCompleto,
          @Email AS Email,
          @Telefono AS Telefono,
          @TipoAsistente AS TipoAsistente,
          CAST(1 AS BIT) AS FueCreado;
      `);

    const asistente = result.recordset[0];

    res.json({
      ok: true,
      mensaje: asistente.FueCreado
        ? "Asistente registrado correctamente."
        : "El asistente ya estaba registrado; se usarán sus datos guardados.",
      data: asistente
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      mensaje: limpiarMensajeError(error)
    });
  }
});

app.get("/api/proyecciones", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT
        IdProyeccion,
        IdSala,
        Pelicula,
        NombreSala,
        FechaHoraInicio,
        CapacidadAsientos,
        AforoDisponibleActual
      FROM vw_ProyeccionesDisponibles
      ORDER BY FechaHoraInicio;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/proyecciones/:id/asientos", async (req, res) => {
  try {
    const idProyeccion = Number(req.params.id);

    if (!idProyeccion) {
      return res.status(400).json({ mensaje: "Debe indicar una proyección válida." });
    }

    const pool = await getConnection();

    const result = await pool.request()
      .input("IdProyeccion", sql.Int, idProyeccion)
      .query(`
        SELECT
          PR.IdProyeccion,
          P.Titulo AS Pelicula,
          S.NombreSala,
          S.CapacidadAsientos,
          PR.AforoDisponibleActual
        FROM Proyeccion PR
        INNER JOIN PeliculaEdicion PE ON PR.IdPeliculaEdicion = PE.IdPeliculaEdicion
        INNER JOIN Pelicula P ON PE.IdPelicula = P.IdPelicula
        INNER JOIN Sala S ON PR.IdSala = S.IdSala
        WHERE PR.IdProyeccion = @IdProyeccion;

        SELECT Asiento
        FROM
        (
          SELECT Asiento
          FROM Entrada
          WHERE IdProyeccion = @IdProyeccion
            AND Asiento IS NOT NULL

          UNION

          SELECT Asiento
          FROM AbonoProyeccion
          WHERE IdProyeccion = @IdProyeccion
            AND Asiento IS NOT NULL
        ) Ocupados;

        SELECT COUNT(*) AS VendidasSinAsiento
        FROM
        (
          SELECT IdProyeccion
          FROM Entrada
          WHERE IdProyeccion = @IdProyeccion
            AND Asiento IS NULL

          UNION ALL

          SELECT IdProyeccion
          FROM AbonoProyeccion
          WHERE IdProyeccion = @IdProyeccion
            AND Asiento IS NULL
        ) SinAsiento;
      `);

    const proyeccion = result.recordsets[0][0];

    if (!proyeccion) {
      return res.status(404).json({ mensaje: "La proyección indicada no existe." });
    }

    const ocupados = new Set(result.recordsets[1].map(item => item.Asiento));
    let vendidasSinAsiento = result.recordsets[2][0].VendidasSinAsiento || 0;

    const asientos = [];

    for (let i = 1; i <= proyeccion.CapacidadAsientos; i++) {
      const codigo = String(i).padStart(3, "0");
      let estado = ocupados.has(codigo) ? "ocupado" : "disponible";

      if (estado === "disponible" && vendidasSinAsiento > 0) {
        estado = "ocupado";
        vendidasSinAsiento--;
      }

      asientos.push({ codigo, estado });
    }

    res.json({
      ...proyeccion,
      asientos
    });
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/tarifas", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT IdTarifa, TipoTarifa, Monto
      FROM vw_TarifasDisponibles
      ORDER BY IdTarifa;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/peliculas", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT 
        IdPeliculaEdicion,
        Titulo,
        DuracionMin,
        FormatoProyeccion
      FROM vw_PeliculasDisponibles
      ORDER BY IdPeliculaEdicion;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/salas", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT
        IdSala,
        NombreSala,
        NombreSede,
        Ciudad,
        CapacidadAsientos
      FROM vw_SalasDisponibles
      ORDER BY IdSala;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/tipos-abono", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT IdTipoAbono, NombreTipoAbono, Descripcion, CantidadMaxProyecciones, PrecioBase
      FROM vw_TiposAbono
      ORDER BY IdTipoAbono;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/eventos-paralelos", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT
        IdEvento,
        TipoEvento,
        Titulo,
        NombreSala,
        NombreSede,
        FechaHora,
        AforoMax,
        AforoDisponible,
        CostoInscripcion,
        AnioEdicion,
        Expositores
      FROM vw_EventosParalelos
      ORDER BY FechaHora;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

/* ============================================================
   MÓDULO JURADO Y PREMIACIÓN
   ============================================================ */

app.get("/api/jurados-categoria", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT IdJuradoCategoria, AnioEdicion, IdCategoria, NombreCategoria, NombreJurado, Miembros
      FROM vw_JuradosCategoria
      ORDER BY AnioEdicion DESC, NombreCategoria;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/miembros-jurado", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT IdMiembro, NombreCompleto, IdCategoria, NombreCategoria, IdEdicion, AnioEdicion
      FROM vw_MiembrosJurado
      ORDER BY AnioEdicion DESC, NombreCategoria, NombreCompleto;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/peliculas-competencia", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT IdCategoria, NombreCategoria, IdPeliculaEdicion, Titulo, IdEdicion, AnioEdicion
      FROM vw_PeliculasCompetencia
      ORDER BY AnioEdicion DESC, NombreCategoria, Titulo;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/evaluaciones", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT IdEvaluacion, AnioEdicion, NombreCategoria, Pelicula, Jurado, Puntuacion, Comentario, FechaEvaluacion
      FROM vw_Evaluaciones
      ORDER BY AnioEdicion DESC, NombreCategoria, FechaEvaluacion DESC;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.post("/api/evaluaciones", async (req, res) => {
  try {
    const { idMiembro, idPeliculaEdicion, idCategoria, puntuacion, comentario } = req.body;

    if (!idMiembro || !idPeliculaEdicion || !idCategoria || puntuacion === undefined) {
      return res.status(400).json({
        ok: false,
        mensaje: "Debe seleccionar el miembro del jurado, la película y la puntuación."
      });
    }

    const pool = await getConnection();

    const result = await pool.request()
      .input("IdMiembro", sql.Int, idMiembro)
      .input("IdPeliculaEdicion", sql.Int, idPeliculaEdicion)
      .input("IdCategoria", sql.Int, idCategoria)
      .input("Puntuacion", sql.Decimal(4, 1), puntuacion)
      .input("Comentario", sql.VarChar(sql.MAX), comentario || null)
      .query(`
        INSERT INTO Evaluacion (IdMiembro, IdPeliculaEdicion, IdCategoria, Puntuacion, Comentario)
        OUTPUT INSERTED.IdEvaluacion, INSERTED.FechaEvaluacion
        VALUES (@IdMiembro, @IdPeliculaEdicion, @IdCategoria, @Puntuacion, @Comentario);
      `);

    res.json({
      ok: true,
      mensaje: "Evaluación registrada correctamente.",
      data: result.recordset[0]
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      mensaje: limpiarMensajeError(error)
    });
  }
});

app.get("/api/premios", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT IdPremio, AnioEdicion, NombreCategoria, PeliculaGanadora, DescripcionPremio
      FROM vw_Premios
      ORDER BY AnioEdicion DESC, NombreCategoria;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/peliculas-todas", async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query(`
      SELECT IdPelicula, Titulo, AnioProduccion
      FROM Pelicula
      ORDER BY Titulo;
    `);
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/ficha-pelicula/:id", async (req, res) => {
  try {
    const idPelicula = Number(req.params.id);
    const pool = await getConnection();

    const detalle = await pool.request()
      .input("IdPelicula", sql.Int, idPelicula)
      .query(`
        SELECT IdPelicula, Titulo, AnioProduccion, DuracionMin, PaisOrigen, Sinopsis, ClasifEdades, FormatoProyeccion, Generos
        FROM vw_PeliculaDetalle
        WHERE IdPelicula = @IdPelicula;
      `);

    if (detalle.recordset.length === 0) {
      return res.status(404).json({ mensaje: "Película no encontrada." });
    }

    const reparto = await pool.request()
      .input("IdPelicula", sql.Int, idPelicula)
      .query(`
        SELECT IdPersonal, NombreCompleto, Nacionalidad, Rol, PersonajeActuado
        FROM vw_RepartoPelicula
        WHERE IdPelicula = @IdPelicula
        ORDER BY Rol, NombreCompleto;
      `);

    const historial = await pool.request()
      .input("IdPelicula", sql.Int, idPelicula)
      .query(`
        SELECT AnioEdicion, EstadoFestival
        FROM vw_HistorialPelicula
        WHERE IdPelicula = @IdPelicula
        ORDER BY AnioEdicion DESC;
      `);

    res.json({
      detalle: detalle.recordset[0],
      reparto: reparto.recordset,
      historial: historial.recordset
    });
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/alojamientos", async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query(`
      SELECT IdAlojamiento, NombreCompleto, NombreHotel, NroHabitacion, CheckIn, CheckOut, AnioEdicion
      FROM vw_Alojamientos
      ORDER BY AnioEdicion DESC, CheckIn;
    `);
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/traslados", async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query(`
      SELECT IdTraslado, NombreCompleto, TipoTraslado, Origen, Destino, FechaHora, NroVuelo, AnioEdicion
      FROM vw_Traslados
      ORDER BY AnioEdicion DESC, FechaHora;
    `);
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/patrocinios", async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query(`
      SELECT IdPatrocinio, NombreEmpresa, Contacto, Email, TipoAportacion, MontoEconomico, DescripcionEspecie, AnioEdicion
      FROM vw_Patrocinios
      ORDER BY AnioEdicion DESC, NombreEmpresa;
    `);
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

/* ============================================================
   MÓDULO 1: TAQUILLA
   Llama al procedimiento P1_ComprarEntrada
   ============================================================ */

app.post("/api/comprar-entrada", async (req, res) => {
  try {
    const { idAsistente, idProyeccion, idTarifa, metodoPago, asientos } = req.body;

    const pool = await getConnection();

    const asientosSeleccionados = Array.isArray(asientos)
      ? asientos.map(asiento => String(asiento).trim()).filter(Boolean)
      : [];

    if (asientosSeleccionados.length > 0) {
      const result = await pool.request()
        .input("IdAsistente", sql.Int, idAsistente)
        .input("IdProyeccion", sql.Int, idProyeccion)
        .input("IdTarifa", sql.Int, idTarifa)
        .input("MetodoPago", sql.VarChar(20), metodoPago)
        .input("AsientosCSV", sql.VarChar(sql.MAX), asientosSeleccionados.join(","))
        .execute("P1_ComprarEntradas");

      const entradas = result.recordset;
      const primera = entradas[0];

      return res.json({
        ok: true,
        mensaje: "Compra registrada correctamente.",
        data: {
          IdVenta: primera.IdVenta,
          NroFactura: primera.NroFactura,
          MontoUnitario: primera.MontoUnitario,
          TotalPagado: primera.TotalPagado,
          CantidadBoletos: primera.CantidadBoletos,
          entradas
        }
      });
    }

    const result = await pool.request()
      .input("IdAsistente", sql.Int, idAsistente)
      .input("IdProyeccion", sql.Int, idProyeccion)
      .input("IdTarifa", sql.Int, idTarifa)
      .input("MetodoPago", sql.VarChar(20), metodoPago)
      .execute("P1_ComprarEntrada");

    res.json({
      ok: true,
      mensaje: "Compra registrada correctamente.",
      data: result.recordset[0]
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      mensaje: limpiarMensajeError(error)
    });
  }
});

app.post("/api/inscribir-evento", async (req, res) => {
  try {
    const { idAsistente, idEvento, metodoPago } = req.body;

    const pool = await getConnection();

    const result = await pool.request()
      .input("IdAsistente", sql.Int, idAsistente)
      .input("IdEvento", sql.Int, idEvento)
      .input("MetodoPago", sql.VarChar(20), metodoPago)
      .execute("P3_InscribirEvento");

    res.json({
      ok: true,
      mensaje: "Inscripción registrada correctamente.",
      data: result.recordset[0]
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      mensaje: limpiarMensajeError(error)
    });
  }
});

/* ============================================================
   MÓDULO 2: AGENDA
   Hace INSERT en Proyeccion para que se active TR1_ControlAgenda
   ============================================================ */

app.post("/api/programar-proyeccion", async (req, res) => {
  try {
    const { idPeliculaEdicion, idSala, fechaHoraInicio, tieneQA } = req.body;

    const pool = await getConnection();

    await pool.request()
      .input("IdPeliculaEdicion", sql.Int, idPeliculaEdicion)
      .input("IdSala", sql.Int, idSala)
      .input("FechaHoraInicio", sql.DateTime, fechaHoraInicio)
      .input("TieneQA", sql.Bit, tieneQA)
      .query(`
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
          @IdPeliculaEdicion,
          @IdSala,
          @FechaHoraInicio,
          @TieneQA,
          0
        );
      `);

    res.json({
      ok: true,
      mensaje: "Proyección programada correctamente. El trigger permitió la inserción."
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      mensaje: limpiarMensajeError(error)
    });
  }
});

/* ============================================================
   MÓDULO 3: ABONOS
   Llama al procedimiento T1_VenderAbono (transacción con posible ROLLBACK)
   ============================================================ */

app.post("/api/vender-abono", async (req, res) => {
  try {
    const { idAsistente, idTipoAbono, idTarifa, metodoPago, proyecciones, asientos, forzarFallo } = req.body;

    const pool = await getConnection();
    const asientosCSV = asientos && typeof asientos === "object"
      ? Object.entries(asientos)
        .map(([idProyeccion, asiento]) => `${idProyeccion}:${String(asiento).trim()}`)
        .join(",")
      : null;

    const result = await pool.request()
      .input("IdAsistente", sql.Int, idAsistente)
      .input("IdTipoAbono", sql.Int, idTipoAbono)
      .input("IdTarifa", sql.Int, idTarifa)
      .input("MetodoPago", sql.VarChar(20), metodoPago)
      .input("ProyeccionesCSV", sql.VarChar(sql.MAX), (proyecciones || []).join(","))
      .input("ForzarFallo", sql.Bit, forzarFallo ? 1 : 0)
      .input("AsientosCSV", sql.VarChar(sql.MAX), asientosCSV)
      .execute("T1_VenderAbono");

    const filas = result.recordset;
    const primera = filas[0];

    res.json({
      ok: true,
      mensaje: "Abono vendido correctamente.",
      data: {
        IdVenta: primera.IdVenta,
        IdAbono: primera.IdAbono,
        NroFactura: primera.NroFactura,
        TotalPagado: primera.TotalPagado,
        CantidadProyecciones: primera.CantidadProyecciones,
        proyecciones: filas
      }
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      mensaje: limpiarMensajeError(error)
    });
  }
});

/* ============================================================
   MÓDULO 1: TAQUILLA
   Check-in: marca Asistio = 1 para un boleto o abono
   ============================================================ */

app.post("/api/marcar-asistencia", async (req, res) => {
  try {
    const codigoAcceso = (req.body.codigoAcceso || "").trim().toUpperCase();

    if (!codigoAcceso) {
      return res.status(400).json({
        ok: false,
        mensaje: "Debe indicar un código de acceso."
      });
    }

    const pool = await getConnection();

    const entrada = await pool.request()
      .input("CodigoAcceso", sql.VarChar(20), codigoAcceso)
      .query(`
        UPDATE Entrada
        SET Asistio = 1
        OUTPUT inserted.CodigoAcceso, inserted.Asistio
        WHERE CodigoAcceso = @CodigoAcceso AND Asistio = 0;

        SELECT CodigoAcceso, Asistio
        FROM Entrada
        WHERE CodigoAcceso = @CodigoAcceso;
      `);

    let registro = entrada.recordsets[0][0];
    let yaRegistrado = false;

    if (!registro && entrada.recordsets[1][0]) {
      registro = entrada.recordsets[1][0];
      yaRegistrado = true;
    }

    if (!registro) {
      const abono = await pool.request()
        .input("CodigoAcceso", sql.VarChar(20), codigoAcceso)
        .query(`
          UPDATE AbonoProyeccion
          SET Asistio = 1, FechaUso = GETDATE()
          OUTPUT inserted.CodigoAcceso, inserted.Asistio
          WHERE CodigoAcceso = @CodigoAcceso AND Asistio = 0;

          SELECT CodigoAcceso, Asistio
          FROM AbonoProyeccion
          WHERE CodigoAcceso = @CodigoAcceso;
        `);

      registro = abono.recordsets[0][0];

      if (!registro && abono.recordsets[1][0]) {
        registro = abono.recordsets[1][0];
        yaRegistrado = true;
      }
    }

    if (!registro) {
      return res.status(404).json({
        ok: false,
        mensaje: "No se encontró ninguna entrada o abono con ese código de acceso."
      });
    }

    res.json({
      ok: true,
      mensaje: yaRegistrado
        ? "Este código ya tenía la asistencia registrada."
        : "Asistencia registrada correctamente.",
      data: registro
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      mensaje: limpiarMensajeError(error)
    });
  }
});

/* ============================================================
   MÓDULO 5: INFORMES
   Consultas DQL de 03_DQL_Consultas.sql
   ============================================================ */

app.get("/api/informes/ranking-peliculas", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
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
      INNER JOIN PeliculaEdicion PE ON E.IdEdicion = PE.IdEdicion
      INNER JOIN Pelicula P ON PE.IdPelicula = P.IdPelicula
      INNER JOIN Proyeccion PR ON PE.IdPeliculaEdicion = PR.IdPeliculaEdicion
      INNER JOIN Sala S ON PR.IdSala = S.IdSala
      LEFT JOIN
      (
        SELECT
          X.IdProyeccion,
          SUM(X.AsistentesReales) AS AsistentesReales
        FROM
        (
          SELECT IdProyeccion, COUNT(*) AS AsistentesReales
          FROM Entrada
          WHERE Asistio = 1
          GROUP BY IdProyeccion

          UNION ALL

          SELECT IdProyeccion, COUNT(*) AS AsistentesReales
          FROM AbonoProyeccion
          WHERE Asistio = 1
          GROUP BY IdProyeccion
        ) X
        GROUP BY X.IdProyeccion
      ) A ON PR.IdProyeccion = A.IdProyeccion
      WHERE E.Anio = (SELECT MAX(Anio) FROM Edicion)
      GROUP BY E.Anio, P.IdPelicula, P.Titulo
      ORDER BY AsistentesReales DESC, PorcentajeOcupacion DESC;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/informes/acta-premiacion", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT
        E.Anio AS Edicion,
        C.NombreCategoria AS Categoria,
        P.Titulo AS PeliculaGanadora,
        PE.EstadoFestival,
        PR.DescripcionPremio,
        CAST(AVG(EV.Puntuacion) AS DECIMAL(10,2)) AS PromedioVotacion,
        COUNT(EV.IdEvaluacion) AS CantidadEvaluaciones
      FROM Premio PR
      INNER JOIN Edicion E ON PR.IdEdicion = E.IdEdicion
      INNER JOIN CategoriaComp C ON PR.IdCategoria = C.IdCategoria
      INNER JOIN PeliculaEdicion PE ON PR.IdPeliculaEdicion = PE.IdPeliculaEdicion
      INNER JOIN Pelicula P ON PE.IdPelicula = P.IdPelicula
      LEFT JOIN Evaluacion EV
        ON PR.IdPeliculaEdicion = EV.IdPeliculaEdicion
        AND PR.IdCategoria = EV.IdCategoria
      WHERE E.Anio = (SELECT MAX(Anio) FROM Edicion)
      GROUP BY E.Anio, C.NombreCategoria, P.Titulo, PE.EstadoFestival, PR.DescripcionPremio
      ORDER BY C.NombreCategoria;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/informes/financiero-resumen", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT
        CASE
          WHEN V.TipoVenta IN ('Entrada', 'Evento') THEN 'Entradas individuales'
          ELSE 'Abonos'
        END AS TipoAcceso,
        COUNT(*) AS CantidadVentas,
        SUM(V.Total) AS TotalRecaudado
      FROM Venta V
      INNER JOIN Pago P ON V.IdVenta = P.IdVenta
      WHERE V.EstadoVenta = 'Completada'
        AND P.EstadoPago = 'Aprobado'
      GROUP BY
        CASE
          WHEN V.TipoVenta IN ('Entrada', 'Evento') THEN 'Entradas individuales'
          ELSE 'Abonos'
        END
      ORDER BY TipoAcceso;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/informes/financiero-detalle", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT
        Datos.TipoVentaAgrupado,
        Datos.DetalleVenta,
        Datos.TipoTarifa,
        COUNT(*) AS CantidadVentas,
        SUM(Datos.MontoRecaudado) AS TotalRecaudado
      FROM
      (
        SELECT
          CASE WHEN V.TipoVenta IN ('Entrada', 'Evento') THEN 'Entrada individual' ELSE 'Abono' END AS TipoVentaAgrupado,
          CASE
            WHEN V.TipoVenta = 'Entrada' THEN 'Entrada para proyección'
            WHEN V.TipoVenta = 'Evento' THEN 'Entrada para evento paralelo'
            ELSE 'Abono'
          END AS DetalleVenta,
          T.TipoTarifa,
          V.Total AS MontoRecaudado
        FROM Venta V
        INNER JOIN Pago PA ON V.IdVenta = PA.IdVenta
        INNER JOIN Entrada EN ON V.IdVenta = EN.IdVenta
        INNER JOIN Tarifa T ON EN.IdTarifa = T.IdTarifa
        WHERE V.EstadoVenta = 'Completada' AND PA.EstadoPago = 'Aprobado'

        UNION ALL

        SELECT
          'Entrada individual' AS TipoVentaAgrupado,
          'Entrada para evento paralelo' AS DetalleVenta,
          T.TipoTarifa,
          V.Total AS MontoRecaudado
        FROM Venta V
        INNER JOIN Pago PA ON V.IdVenta = PA.IdVenta
        INNER JOIN EntradaEvento EE ON V.IdVenta = EE.IdVenta
        INNER JOIN Tarifa T ON EE.IdTarifa = T.IdTarifa
        WHERE V.EstadoVenta = 'Completada' AND PA.EstadoPago = 'Aprobado'

        UNION ALL

        SELECT
          'Abono' AS TipoVentaAgrupado,
          TA.NombreTipoAbono AS DetalleVenta,
          T.TipoTarifa,
          V.Total AS MontoRecaudado
        FROM Venta V
        INNER JOIN Pago PA ON V.IdVenta = PA.IdVenta
        INNER JOIN Abono A ON V.IdVenta = A.IdVenta
        INNER JOIN Tarifa T ON A.IdTarifa = T.IdTarifa
        INNER JOIN TipoAbono TA ON A.IdTipoAbono = TA.IdTipoAbono
        WHERE V.EstadoVenta = 'Completada' AND PA.EstadoPago = 'Aprobado'
      ) AS Datos
      GROUP BY Datos.TipoVentaAgrupado, Datos.DetalleVenta, Datos.TipoTarifa
      ORDER BY Datos.TipoVentaAgrupado, Datos.TipoTarifa;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.listen(PORT, () => {
  console.log(`Servidor FestCine ejecutándose en http://localhost:${PORT}`);
});
