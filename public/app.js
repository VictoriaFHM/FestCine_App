const API = "";

let asistentes = [];
let proyecciones = [];
let tarifas = [];
let peliculas = [];
let salas = [];

function mostrarModulo(idModulo, boton) {
    document.querySelectorAll(".module").forEach(modulo => {
        modulo.classList.remove("active-module");
    });

    document.querySelectorAll(".nav-btn").forEach(btn => {
        btn.classList.remove("active");
    });

    document.getElementById(idModulo).classList.add("active-module");
    boton.classList.add("active");
}

function mostrarToast(mensaje, tipo = "success") {
    const toast = document.getElementById("toast");
    toast.textContent = mensaje;
    toast.className = `toast show ${tipo}`;

    setTimeout(() => {
        toast.className = "toast";
    }, 4200);
}

function setResultado(id, texto, tipo) {
    const elemento = document.getElementById(id);
    elemento.textContent = texto;
    elemento.classList.remove("success", "error");

    if (tipo) {
        elemento.classList.add(tipo);
    }
}

function llenarSelect(idSelect, datos, crearTexto, idCampo) {
    const select = document.getElementById(idSelect);
    select.innerHTML = "";

    datos.forEach(item => {
        const option = document.createElement("option");
        option.value = item[idCampo];
        option.textContent = crearTexto(item);
        select.appendChild(option);
    });
}

function formatearFecha(fecha) {
    if (!fecha) return "";

    const date = new Date(fecha);
    return date.toLocaleString("es-BO", {
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit"
    });
}

async function obtenerJSON(url) {
    const respuesta = await fetch(url);

    if (!respuesta.ok) {
        throw new Error("No se pudo cargar información desde " + url);
    }

    return await respuesta.json();
}

async function cargarDatos() {
    try {
        asistentes = await obtenerJSON(`${API}/api/asistentes`);
        proyecciones = await obtenerJSON(`${API}/api/proyecciones`);
        tarifas = await obtenerJSON(`${API}/api/tarifas`);
        peliculas = await obtenerJSON(`${API}/api/peliculas`);
        salas = await obtenerJSON(`${API}/api/salas`);

        llenarSelect(
            "selectAsistente",
            asistentes,
            item => `${item.IdAsistente} - ${item.NombreCompleto}`,
            "IdAsistente"
        );

        llenarSelect(
            "selectProyeccion",
            proyecciones,
            item => `${item.IdProyeccion} - ${item.Pelicula} | ${item.NombreSala} | ${formatearFecha(item.FechaHoraInicio)} | Cupos: ${item.AforoDisponibleActual}`,
            "IdProyeccion"
        );

        llenarSelect(
            "selectTarifa",
            tarifas,
            item => `${item.IdTarifa} - ${item.TipoTarifa} | Bs ${Number(item.Monto).toFixed(2)}`,
            "IdTarifa"
        );

        llenarSelect(
            "selectPeliculaAgenda",
            peliculas,
            item => `${item.IdPeliculaEdicion} - ${item.Titulo} | ${item.DuracionMin} min | ${item.FormatoProyeccion}`,
            "IdPeliculaEdicion"
        );

        llenarSelect(
            "selectSalaAgenda",
            salas,
            item => `${item.IdSala} - ${item.NombreSala} | ${item.NombreSede} | Capacidad: ${item.CapacidadAsientos}`,
            "IdSala"
        );

        cargarTablaProyecciones();

        document.getElementById("statAsistentes").textContent = asistentes.length;
        document.getElementById("statProyecciones").textContent = proyecciones.length;
        document.getElementById("statPeliculas").textContent = peliculas.length;
        document.getElementById("statSalas").textContent = salas.length;

        mostrarToast("Datos cargados correctamente.", "success");

    } catch (error) {
        mostrarToast(error.message, "error");
    }
}

function cargarTablaProyecciones() {
    const tbody = document.getElementById("tablaProyecciones");
    tbody.innerHTML = "";

    proyecciones.slice(0, 20).forEach(item => {
        const fila = document.createElement("tr");

        fila.innerHTML = `
            <td>${item.IdProyeccion}</td>
            <td>${item.Pelicula}</td>
            <td>${item.NombreSala}</td>
            <td>${formatearFecha(item.FechaHoraInicio)}</td>
            <td>${item.AforoDisponibleActual}</td>
        `;

        tbody.appendChild(fila);
    });
}

async function comprarEntrada() {
    const idAsistente = Number(document.getElementById("selectAsistente").value);
    const idProyeccion = Number(document.getElementById("selectProyeccion").value);
    const idTarifa = Number(document.getElementById("selectTarifa").value);
    const metodoPago = document.getElementById("selectMetodoPago").value;

    if (!idAsistente || !idProyeccion || !idTarifa || !metodoPago) {
        mostrarToast("Debes completar todos los datos de la compra.", "error");
        return;
    }

    try {
        const respuesta = await fetch(`${API}/api/comprar-entrada`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                idAsistente,
                idProyeccion,
                idTarifa,
                metodoPago
            })
        });

        const data = await respuesta.json();

        if (!respuesta.ok || !data.ok) {
            throw new Error(data.mensaje || "No se pudo registrar la compra.");
        }

        const compra = data.data;

        setResultado(
            "resultadoCompra",
            `✅ ${data.mensaje}

IdVenta: ${compra.IdVenta}
IdEntrada: ${compra.IdEntrada}
Código de acceso: ${compra.CodigoAcceso}
Factura: ${compra.NroFactura}
Monto pagado: Bs ${Number(compra.MontoPagado).toFixed(2)}

La compra fue registrada llamando al procedimiento P1_ComprarEntrada.`,
            "success"
        );

        mostrarToast("Compra registrada correctamente.", "success");
        await cargarDatos();

    } catch (error) {
        setResultado(
            "resultadoCompra",
            `❌ Compra rechazada

${error.message}

El error fue devuelto por SQL Server y capturado por la aplicación cliente.`,
            "error"
        );

        mostrarToast(error.message, "error");
    }
}

async function programarProyeccion() {
    const idPeliculaEdicion = Number(document.getElementById("selectPeliculaAgenda").value);
    const idSala = Number(document.getElementById("selectSalaAgenda").value);
    const fechaHoraInicio = document.getElementById("inputFechaHora").value;
    const tieneQA = document.getElementById("checkQA").checked;

    if (!idPeliculaEdicion || !idSala || !fechaHoraInicio) {
        mostrarToast("Debes completar película, sala y fecha/hora.", "error");
        return;
    }

    try {
        const respuesta = await fetch(`${API}/api/programar-proyeccion`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                idPeliculaEdicion,
                idSala,
                fechaHoraInicio,
                tieneQA
            })
        });

        const data = await respuesta.json();

        if (!respuesta.ok || !data.ok) {
            throw new Error(data.mensaje || "No se pudo programar la proyección.");
        }

        setResultado(
            "resultadoAgenda",
            `✅ ${data.mensaje}

PelículaEdición: ${idPeliculaEdicion}
Sala: ${idSala}
Fecha y hora: ${fechaHoraInicio}
Q&A: ${tieneQA ? "Sí" : "No"}

La inserción fue permitida por TR1_ControlAgenda.`,
            "success"
        );

        mostrarToast("Proyección programada correctamente.", "success");
        await cargarDatos();

    } catch (error) {
        setResultado(
            "resultadoAgenda",
            `❌ Proyección rechazada

${error.message}

El trigger TR1_ControlAgenda bloqueó la operación y la interfaz mostró un mensaje amigable.`,
            "error"
        );

        mostrarToast(error.message, "error");
    }
}

function cargarEjemploCruce() {
    if (proyecciones.length === 0) {
        mostrarToast("No hay proyecciones cargadas para generar ejemplo.", "error");
        return;
    }

    const primera = proyecciones[0];

    document.getElementById("selectSalaAgenda").value = primera.IdSala;

    const fecha = new Date(primera.FechaHoraInicio);
    const yyyy = fecha.getFullYear();
    const mm = String(fecha.getMonth() + 1).padStart(2, "0");
    const dd = String(fecha.getDate()).padStart(2, "0");
    const hh = String(fecha.getHours()).padStart(2, "0");
    const min = String(fecha.getMinutes()).padStart(2, "0");

    document.getElementById("inputFechaHora").value = `${yyyy}-${mm}-${dd}T${hh}:${min}`;

    mostrarToast("Ejemplo de cruce cargado. Ahora presiona Programar proyección.", "success");
}

document.addEventListener("DOMContentLoaded", () => {
    cargarDatos();
});


