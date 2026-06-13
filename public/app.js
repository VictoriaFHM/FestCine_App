const API = "";

let asistentes = [];
let proyecciones = [];
let tarifas = [];
let peliculas = [];
let salas = [];

let ventasSesion = [];
let chartOcupacion = null;
let chartFunciones = null;
let chartVentas = null;

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
        renderCartelera();
        renderCharts();

        document.getElementById("statAsistentes").textContent = asistentes.length;
        document.getElementById("statProyecciones").textContent = proyecciones.length;
        document.getElementById("statPeliculas").textContent = peliculas.length;
        document.getElementById("statSalas").textContent = salas.length;

        mostrarToast("Datos cargados correctamente.", "success");

    } catch (error) {
        mostrarToast(error.message, "error");
    }
}

function badgeAforo(cupos) {
    let clase = "badge-alta";
    let texto = "Alta";

    if (cupos <= 0) {
        clase = "badge-lleno";
        texto = "Lleno";
    } else if (cupos < 15) {
        clase = "badge-baja";
        texto = "Baja";
    } else if (cupos < 40) {
        clase = "badge-media";
        texto = "Media";
    }

    return `<span class="badge ${clase}">${cupos} · ${texto}</span>`;
}

function colorFromString(texto) {
    let hash = 0;
    for (let i = 0; i < texto.length; i++) {
        hash = (hash << 5) - hash + texto.charCodeAt(i);
        hash |= 0;
    }

    const hue = Math.abs(hash) % 360;
    return `linear-gradient(135deg, hsl(${hue}, 55%, 32%), hsl(${(hue + 40) % 360}, 60%, 16%))`;
}

function renderCartelera() {
    const grid = document.getElementById("carteleraGrid");
    grid.innerHTML = "";

    proyecciones.slice(0, 12).forEach(item => {
        const card = document.createElement("div");
        card.className = "poster-card";
        card.dataset.id = String(item.IdProyeccion);

        const fechaCorta = new Date(item.FechaHoraInicio)
            .toLocaleDateString("es-BO", { day: "2-digit", month: "short" })
            .replace(".", "");

        card.innerHTML = `
            <div class="poster-art" style="background: ${colorFromString(item.Pelicula)}">
                <span class="poster-date">${fechaCorta}</span>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="20" rx="2.18" ry="2.18"/><line x1="7" y1="2" x2="7" y2="22"/><line x1="17" y1="2" x2="17" y2="22"/><line x1="2" y1="12" x2="22" y2="12"/><line x1="2" y1="7" x2="7" y2="7"/><line x1="2" y1="17" x2="7" y2="17"/><line x1="17" y1="17" x2="22" y2="17"/><line x1="17" y1="7" x2="22" y2="7"/></svg>
            </div>
            <div class="poster-info">
                <h4>${item.Pelicula}</h4>
                <p>${item.NombreSala} · ${formatearFecha(item.FechaHoraInicio)}</p>
                ${badgeAforo(item.AforoDisponibleActual)}
            </div>
        `;

        card.addEventListener("click", () => seleccionarProyeccion(item.IdProyeccion));
        grid.appendChild(card);
    });

    marcarProyeccionSeleccionada();
}

function seleccionarProyeccion(idProyeccion) {
    const select = document.getElementById("selectProyeccion");
    select.value = String(idProyeccion);
    marcarProyeccionSeleccionada();
    select.scrollIntoView({ behavior: "smooth", block: "center" });
    mostrarToast("Función seleccionada. Completa los datos de compra.", "success");
}

function marcarProyeccionSeleccionada() {
    const idSeleccionado = document.getElementById("selectProyeccion").value;

    document.querySelectorAll(".poster-card").forEach(card => {
        card.classList.toggle("is-selected", card.dataset.id === idSeleccionado);
    });
}

function configurarChartDefaults() {
    if (typeof Chart === "undefined") return;

    Chart.defaults.font.family = "'Outfit', sans-serif";
    Chart.defaults.color = "#948da0";
    Chart.defaults.borderColor = "#3a3542";
}

function renderCharts() {
    if (typeof Chart === "undefined") return;

    renderChartOcupacion();
    renderChartFunciones();
    renderChartVentas();
}

function renderChartOcupacion() {
    const ctx = document.getElementById("chartOcupacion");
    if (!ctx) return;

    const porSala = {};
    proyecciones.forEach(item => {
        if (!item.CapacidadAsientos) return;

        if (!porSala[item.NombreSala]) {
            porSala[item.NombreSala] = { ocupados: 0, capacidad: 0 };
        }

        porSala[item.NombreSala].ocupados += item.CapacidadAsientos - item.AforoDisponibleActual;
        porSala[item.NombreSala].capacidad += item.CapacidadAsientos;
    });

    const labels = Object.keys(porSala);
    const data = labels.map(sala => {
        const { ocupados, capacidad } = porSala[sala];
        return capacidad > 0 ? Math.round((ocupados / capacidad) * 100) : 0;
    });

    if (chartOcupacion) chartOcupacion.destroy();

    chartOcupacion = new Chart(ctx, {
        type: "bar",
        data: {
            labels,
            datasets: [{
                label: "Ocupación promedio (%)",
                data,
                backgroundColor: "#9b2c3e",
                borderRadius: 4,
                maxBarThickness: 36
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    max: 100,
                    ticks: { callback: valor => valor + "%" }
                }
            },
            plugins: { legend: { display: false } }
        }
    });
}

function renderChartFunciones() {
    const ctx = document.getElementById("chartFunciones");
    if (!ctx) return;

    const conteo = {};
    proyecciones.forEach(item => {
        conteo[item.NombreSala] = (conteo[item.NombreSala] || 0) + 1;
    });

    const labels = Object.keys(conteo);
    const data = labels.map(sala => conteo[sala]);
    const colores = ["#9b2c3e", "#c1a36c", "#84a07c", "#c99a5b", "#948da0", "#742333"];

    if (chartFunciones) chartFunciones.destroy();

    chartFunciones = new Chart(ctx, {
        type: "doughnut",
        data: {
            labels,
            datasets: [{
                data,
                backgroundColor: labels.map((_, i) => colores[i % colores.length]),
                borderColor: "#1c1a23",
                borderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { position: "bottom", labels: { boxWidth: 12, font: { size: 11 } } }
            }
        }
    });
}

function renderChartVentas() {
    const ctx = document.getElementById("chartVentas");
    const vacio = document.getElementById("chartVentasEmpty");
    if (!ctx) return;

    if (ventasSesion.length === 0) {
        ctx.hidden = true;
        if (vacio) vacio.hidden = false;
        return;
    }

    ctx.hidden = false;
    if (vacio) vacio.hidden = true;

    const conteo = {};
    ventasSesion.forEach(venta => {
        conteo[venta.metodoPago] = (conteo[venta.metodoPago] || 0) + venta.monto;
    });

    const labels = Object.keys(conteo);
    const data = labels.map(metodo => Number(conteo[metodo].toFixed(2)));
    const colores = ["#9b2c3e", "#c1a36c", "#84a07c", "#c99a5b"];

    if (chartVentas) chartVentas.destroy();

    chartVentas = new Chart(ctx, {
        type: "doughnut",
        data: {
            labels,
            datasets: [{
                data,
                backgroundColor: labels.map((_, i) => colores[i % colores.length]),
                borderColor: "#1c1a23",
                borderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { position: "bottom", labels: { boxWidth: 12, font: { size: 11 } } },
                tooltip: {
                    callbacks: {
                        label: contexto => `${contexto.label}: Bs ${contexto.parsed.toFixed(2)}`
                    }
                }
            }
        }
    });
}

function mostrarTicketDigital(compra, idProyeccion, metodoPago) {
    const proyeccion = proyecciones.find(item => item.IdProyeccion === idProyeccion);
    const ticket = document.getElementById("ticketDigital");

    document.getElementById("ticketPelicula").textContent = proyeccion ? proyeccion.Pelicula : "Función";
    document.getElementById("ticketDetalle").textContent = proyeccion
        ? `${proyeccion.NombreSala} · ${formatearFecha(proyeccion.FechaHoraInicio)} · ${metodoPago}`
        : metodoPago;
    document.getElementById("ticketCodigo").textContent = `Código: ${compra.CodigoAcceso}`;

    const qrContenedor = document.getElementById("ticketQR");
    qrContenedor.innerHTML = "";

    if (typeof QRCode !== "undefined") {
        new QRCode(qrContenedor, {
            text: compra.CodigoAcceso,
            width: 96,
            height: 96,
            colorDark: "#141219",
            colorLight: "#efe8da"
        });
    }

    ticket.hidden = false;
}

function descargarTicket() {
    const qrImagen = document.querySelector("#ticketQR canvas, #ticketQR img");

    if (!qrImagen) {
        mostrarToast("No hay un boleto generado para descargar.", "error");
        return;
    }

    const codigo = document.getElementById("ticketCodigo").textContent.replace("Código: ", "");

    const enlace = document.createElement("a");
    enlace.download = `FestCine_${codigo}.png`;
    enlace.href = qrImagen.tagName === "CANVAS" ? qrImagen.toDataURL("image/png") : qrImagen.src;
    enlace.click();
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
            <td>${badgeAforo(item.AforoDisponibleActual)}</td>
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

        ventasSesion.push({ metodoPago, monto: Number(compra.MontoPagado) });
        mostrarTicketDigital(compra, idProyeccion, metodoPago);

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
    configurarChartDefaults();

    document.getElementById("selectProyeccion").addEventListener("change", marcarProyeccionSeleccionada);

    cargarDatos();
});


