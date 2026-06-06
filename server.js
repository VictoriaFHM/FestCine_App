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

  if (error.originalError?.info?.message) {
    return error.originalError.info.message;
  }

  if (error.precedingErrors && error.precedingErrors.length > 0) {
    return error.precedingErrors.map(e => e.message).join(" ");
  }

  if (error.message) {
    return error.message;
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

app.get("/api/asistentes", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT IdAsistente, NombreCompleto, Email, TipoAsistente
      FROM vw_Asistentes
      ORDER BY IdAsistente;
    `);

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ mensaje: limpiarMensajeError(error) });
  }
});

app.get("/api/proyecciones", async (req, res) => {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(`
      SELECT 
        IdProyeccion,
        Pelicula,
        NombreSala,
        FechaHoraInicio,
        AforoDisponibleActual
      FROM vw_ProyeccionesDisponibles
      ORDER BY FechaHoraInicio;
    `);

    res.json(result.recordset);
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

/* ============================================================
   MÓDULO 1: TAQUILLA
   Llama al procedimiento P1_ComprarEntrada
   ============================================================ */

app.post("/api/comprar-entrada", async (req, res) => {
  try {
    const { idAsistente, idProyeccion, idTarifa, metodoPago } = req.body;

    const pool = await getConnection();

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

app.listen(PORT, () => {
  console.log(`Servidor FestCine ejecutándose en http://localhost:${PORT}`);
});