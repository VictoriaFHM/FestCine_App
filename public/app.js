const API = "";

let asistentes = [];
let asistenteSeleccionado = null;
let proyecciones = [];
let tarifas = [];
let peliculas = [];
let salas = [];
let tiposAbono = [];
let asientosFuncion = [];
let asientosSeleccionados = [];
let abonoAsientos = {};
let abonoMapasAsientos = {};

let ventasSesion = [];
let chartOcupacion = null;
let chartFunciones = null;
let chartVentas = null;

let miembrosJurado = [];
let peliculasCompetencia = [];
let peliculasTodas = [];
let eventosParalelos = [];

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

function formatearFechaCorta(fecha) {
    if (!fecha) return "";

    const date = new Date(fecha);
    return date.toLocaleDateString("es-BO", {
        year: "numeric",
        month: "2-digit",
        day: "2-digit"
    });
}

async function obtenerJSON(url) {
    const respuesta = await fetch(url);

    if (!respuesta.ok) {
        throw new Error("No se pudo cargar información desde " + url);
    }

    return await respuesta.json();
}

function esEmailValido(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

async function verificarConexion() {
    const dot = document.getElementById("statusDot");
    const texto = document.getElementById("statusTexto");

    try {
        const data = await obtenerJSON(`${API}/api/probar-conexion`);

        if (!data.ok) throw new Error(data.mensaje);

        dot.classList.remove("error");
        texto.textContent = `SQL Server conectado · ${data.data.Servidor}`;
    } catch (error) {
        dot.classList.add("error");
        texto.textContent = "Sin conexión a SQL Server";
    }
}

async function cargarDatos() {
    verificarConexion();

    try {
        asistentes = await obtenerJSON(`${API}/api/asistentes`);
        proyecciones = await obtenerJSON(`${API}/api/proyecciones`);
        tarifas = await obtenerJSON(`${API}/api/tarifas`);
        peliculas = await obtenerJSON(`${API}/api/peliculas`);
        salas = await obtenerJSON(`${API}/api/salas`);
        tiposAbono = await obtenerJSON(`${API}/api/tipos-abono`);

        const edicionActual = await obtenerJSON(`${API}/api/edicion-actual`);
        configurarRangoAgenda(edicionActual);

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

        llenarSelect(
            "selectAsistenteAbono",
            asistentes,
            item => `${item.IdAsistente} - ${item.NombreCompleto}`,
            "IdAsistente"
        );

        llenarSelect(
            "selectAsistenteEvento",
            asistentes,
            item => `${item.IdAsistente} - ${item.NombreCompleto}`,
            "IdAsistente"
        );

        llenarSelect(
            "selectTarifaAbono",
            tarifas,
            item => `${item.IdTarifa} - ${item.TipoTarifa} | Bs ${Number(item.Monto).toFixed(2)}`,
            "IdTarifa"
        );

        llenarSelect(
            "selectTipoAbono",
            tiposAbono,
            item => `${item.IdTipoAbono} - ${item.NombreTipoAbono} | Bs ${Number(item.PrecioBase).toFixed(2)} | máx. ${item.CantidadMaxProyecciones} proyecciones`,
            "IdTipoAbono"
        );

        cargarTablaProyecciones();
        renderCartelera();
        renderCharts();
        renderAbonoProyecciones();
        mostrarInfoTipoAbono();
        await cargarAsientosProyeccion();
        cargarInformes();
        cargarEventosParalelos();
        cargarJurado();
        cargarFichaPelicula();
        cargarLogistica();

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

    if (cupos < 15) {
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
    cargarAsientosProyeccion();
    select.scrollIntoView({ behavior: "smooth", block: "center" });
    mostrarToast("Función seleccionada. Completa los datos de compra.", "success");
}

function marcarProyeccionSeleccionada() {
    const idSeleccionado = document.getElementById("selectProyeccion").value;

    document.querySelectorAll(".poster-card").forEach(card => {
        card.classList.toggle("is-selected", card.dataset.id === idSeleccionado);
    });
}

function obtenerCantidadBoletos() {
    const input = document.getElementById("inputCantidadBoletos");
    const cantidad = Number(input.value) || 1;
    return Math.min(Math.max(cantidad, 1), 10);
}

function cambiarCantidadBoletos(delta) {
    const input = document.getElementById("inputCantidadBoletos");
    input.value = obtenerCantidadBoletos() + delta;
    normalizarCantidadBoletos();
}

function normalizarCantidadBoletos() {
    const input = document.getElementById("inputCantidadBoletos");
    const cantidad = Math.min(Math.max(Number(input.value) || 1, 1), 10);
    input.value = cantidad;

    if (asientosSeleccionados.length > cantidad) {
        asientosSeleccionados = asientosSeleccionados.slice(0, cantidad);
        renderMapaAsientos();
    }

    actualizarEstadoAsientos();
    actualizarResumenCompra();
}

async function cargarAsientosProyeccion() {
    const idProyeccion = Number(document.getElementById("selectProyeccion").value);

    asientosFuncion = [];
    asientosSeleccionados = [];
    renderMapaAsientos();

    if (!idProyeccion) {
        actualizarResumenCompra();
        return;
    }

    try {
        const data = await obtenerJSON(`${API}/api/proyecciones/${idProyeccion}/asientos`);
        asientosFuncion = data.asientos || [];
        renderMapaAsientos();
    } catch (error) {
        mostrarToast(error.message, "error");
    }

    actualizarResumenCompra();
}

function renderMapaAsientos() {
    const mapa = document.getElementById("mapaAsientos");
    if (!mapa) return;

    mapa.innerHTML = "";

    if (asientosFuncion.length === 0) {
        mapa.innerHTML = `<div class="seat-map-empty">Selecciona una función para ver los lugares.</div>`;
        actualizarEstadoAsientos();
        return;
    }

    asientosFuncion.forEach(asiento => {
        const boton = document.createElement("button");
        const seleccionado = asientosSeleccionados.includes(asiento.codigo);

        boton.type = "button";
        boton.className = `seat ${asiento.estado}`;
        boton.textContent = asiento.codigo;
        boton.disabled = asiento.estado === "ocupado";
        boton.classList.toggle("seleccionado", seleccionado);
        boton.onclick = () => alternarAsiento(asiento.codigo);

        mapa.appendChild(boton);
    });

    actualizarEstadoAsientos();
}

function alternarAsiento(codigo) {
    const cantidad = obtenerCantidadBoletos();
    const yaSeleccionado = asientosSeleccionados.includes(codigo);

    if (yaSeleccionado) {
        asientosSeleccionados = asientosSeleccionados.filter(asiento => asiento !== codigo);
    } else {
        if (asientosSeleccionados.length >= cantidad) {
            mostrarToast(`Solo puedes elegir ${cantidad} asiento(s).`, "error");
            return;
        }

        asientosSeleccionados.push(codigo);
    }

    renderMapaAsientos();
    actualizarResumenCompra();
}

function actualizarEstadoAsientos() {
    const contador = document.getElementById("asientosContador");
    const estado = document.getElementById("estadoCantidadBoletos");
    const cantidad = obtenerCantidadBoletos();

    if (contador) {
        contador.textContent = `(${asientosSeleccionados.length}/${cantidad})`;
    }

    if (estado) {
        estado.textContent = `Selecciona ${cantidad} asiento(s) en el mapa antes de confirmar la compra.`;
    }
}

function actualizarResumenCompra() {
    const resumen = document.getElementById("resumenCompra");
    if (!resumen) return;

    const selectProyeccion = document.getElementById("selectProyeccion");
    const selectTarifa = document.getElementById("selectTarifa");
    const idProyeccion = Number(selectProyeccion.value);
    let idTarifa = Number(selectTarifa.value);
    const cantidad = obtenerCantidadBoletos();
    const proyeccion = proyecciones.find(item => item.IdProyeccion === idProyeccion);
    let tarifa = tarifas.find(item => Number(item.IdTarifa) === idTarifa);

    if (!tarifa && tarifas.length > 0) {
        tarifa = tarifas[0];
        idTarifa = Number(tarifa.IdTarifa);
        selectTarifa.value = String(idTarifa);
    }

    const montoUnitario = tarifa ? Number(tarifa.Monto) : 0;
    const total = montoUnitario * cantidad;

    resumen.innerHTML = `
        <div>
            <span>Funcion</span>
            <strong>${proyeccion ? proyeccion.Pelicula : "Sin seleccionar"}</strong>
            <small>${proyeccion ? `${proyeccion.NombreSala} - ${formatearFecha(proyeccion.FechaHoraInicio)}` : "Elige una función de la cartelera."}</small>
        </div>
        <div>
            <span>Boletos</span>
            <strong>${cantidad}</strong>
            <small>Asientos: ${asientosSeleccionados.length ? asientosSeleccionados.join(", ") : "pendientes"}</small>
        </div>
        <div>
            <span>Total</span>
            <strong>Bs ${total.toFixed(2)}</strong>
            <small>${tarifa ? `Tarifa: ${tarifa.TipoTarifa}` : "Selecciona una tarifa"}</small>
        </div>
    `;
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

    const ordenadas = Object.entries(conteo)
        .sort((a, b) => b[1] - a[1]);
    const top = ordenadas.slice(0, 12);
    const otras = ordenadas.slice(12).reduce((total, item) => total + item[1], 0);

    if (otras > 0) {
        top.push(["Otras salas", otras]);
    }

    const labels = top.map(item => item[0]);
    const data = top.map(item => item[1]);

    if (chartFunciones) chartFunciones.destroy();

    chartFunciones = new Chart(ctx, {
        type: "bar",
        data: {
            labels,
            datasets: [{
                label: "Funciones programadas",
                data,
                backgroundColor: "#c1a36c",
                borderRadius: 4,
                maxBarThickness: 18
            }]
        },
        options: {
            indexAxis: "y",
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                x: {
                    beginAtZero: true,
                    ticks: { precision: 0 }
                }
            },
            plugins: { legend: { display: false } }
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
    const entradas = compra.entradas || [compra];
    const codigos = entradas
        .map(entrada => `${entrada.Asiento ? entrada.Asiento + ": " : ""}${entrada.CodigoAcceso}`)
        .join(" | ");

    document.getElementById("ticketPelicula").textContent = proyeccion ? proyeccion.Pelicula : "Función";
    document.getElementById("ticketDetalle").textContent = proyeccion
        ? `${proyeccion.NombreSala} · ${formatearFecha(proyeccion.FechaHoraInicio)} · ${metodoPago} · ${entradas.length} boleto(s)`
        : metodoPago;
    document.getElementById("ticketCodigo").textContent = `Códigos: ${codigos}`;

    const qrContenedor = document.getElementById("ticketQR");
    qrContenedor.innerHTML = "";

    if (typeof QRCode !== "undefined") {
        new QRCode(qrContenedor, {
            text: JSON.stringify({
                venta: compra.IdVenta,
                factura: compra.NroFactura,
                entradas: entradas.map(entrada => ({
                    asiento: entrada.Asiento,
                    codigo: entrada.CodigoAcceso
                }))
            }),
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

    const codigo = document.getElementById("ticketCodigo").textContent
        .replace("Código: ", "")
        .replace("Códigos: ", "")
        .split("|")[0]
        .replace(/[^a-zA-Z0-9-]/g, "");

    const enlace = document.createElement("a");
    enlace.download = `FestCine_${codigo}.png`;
    enlace.href = qrImagen.tagName === "CANVAS" ? qrImagen.toDataURL("image/png") : qrImagen.src;
    enlace.click();
}

function mostrarAbonoDigital(abono) {
    const ticket = document.getElementById("abonoDigital");
    if (!ticket) return;

    const items = abono.proyecciones || [];
    const codigos = items
        .map(item => `${item.Asiento ? item.Asiento + ": " : ""}${item.CodigoAcceso}`)
        .join(" | ");

    document.getElementById("abonoTitulo").textContent = `Abono ${abono.IdAbono}`;
    document.getElementById("abonoDetalle").textContent =
        `${items.length} funcion(es) | Factura ${abono.NroFactura} | Bs ${Number(abono.TotalPagado).toFixed(2)}`;
    document.getElementById("abonoCodigo").textContent = `Codigos: ${codigos}`;

    const qrContenedor = document.getElementById("abonoQR");
    qrContenedor.innerHTML = "";

    if (typeof QRCode !== "undefined") {
        new QRCode(qrContenedor, {
            text: JSON.stringify({
                venta: abono.IdVenta,
                abono: abono.IdAbono,
                factura: abono.NroFactura,
                proyecciones: items.map(item => ({
                    proyeccion: item.IdProyeccion,
                    asiento: item.Asiento,
                    codigo: item.CodigoAcceso
                }))
            }),
            width: 96,
            height: 96,
            colorDark: "#141219",
            colorLight: "#efe8da"
        });
    }

    ticket.hidden = false;
}

function descargarAbonoQR() {
    const qrImagen = document.querySelector("#abonoQR canvas, #abonoQR img");

    if (!qrImagen) {
        mostrarToast("No hay un abono generado para descargar.", "error");
        return;
    }

    const codigo = document.getElementById("abonoTitulo").textContent.replace(/[^a-zA-Z0-9-]/g, "");
    const enlace = document.createElement("a");
    enlace.download = `FestCine_${codigo || "Abono"}.png`;
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

function buscarAsistentePorEmail() {
    const email = document.getElementById("inputAsistenteEmail").value.trim().toLowerCase();
    const inputNombre = document.getElementById("inputAsistenteNombre");
    const inputTelefono = document.getElementById("inputAsistenteTelefono");
    const selectTipo = document.getElementById("selectTipoAsistente");
    const estado = document.getElementById("estadoAsistente");
    const btnLimpiar = document.getElementById("btnLimpiarAsistente");

    if (!email) {
        limpiarFormularioAsistente();
        return;
    }

    const encontrado = asistentes.find(item => item.Email.toLowerCase() === email);

    if (encontrado) {
        asistenteSeleccionado = encontrado;

        inputNombre.value = encontrado.NombreCompleto;
        inputTelefono.value = encontrado.Telefono || "";
        selectTipo.value = encontrado.TipoAsistente;

        inputNombre.readOnly = true;
        inputTelefono.readOnly = true;
        selectTipo.disabled = true;

        estado.textContent = `✓ Asistente registrado (ID ${encontrado.IdAsistente}) · se usarán sus datos guardados.`;
        estado.classList.remove("error");
        estado.classList.add("success");
        btnLimpiar.hidden = false;
    } else {
        asistenteSeleccionado = null;

        inputNombre.readOnly = false;
        inputTelefono.readOnly = false;
        selectTipo.disabled = false;

        estado.textContent = "No encontramos este correo. Completa los datos para registrar un nuevo asistente.";
        estado.classList.remove("success", "error");
        btnLimpiar.hidden = true;
    }
}

function limpiarFormularioAsistente() {
    asistenteSeleccionado = null;

    const inputNombre = document.getElementById("inputAsistenteNombre");
    const inputTelefono = document.getElementById("inputAsistenteTelefono");
    const selectTipo = document.getElementById("selectTipoAsistente");
    const estado = document.getElementById("estadoAsistente");
    const btnLimpiar = document.getElementById("btnLimpiarAsistente");

    inputNombre.value = "";
    inputTelefono.value = "";
    selectTipo.value = "PublicoGeneral";

    inputNombre.readOnly = false;
    inputTelefono.readOnly = false;
    selectTipo.disabled = false;

    estado.textContent = "Escribe el correo para ver si ya está registrado.";
    estado.classList.remove("success", "error");
    btnLimpiar.hidden = true;
}

function reiniciarAsistente() {
    document.getElementById("inputAsistenteEmail").value = "";
    limpiarFormularioAsistente();
}

async function comprarEntrada() {
    const email = document.getElementById("inputAsistenteEmail").value.trim().toLowerCase();
    const nombreCompleto = document.getElementById("inputAsistenteNombre").value.trim();
    const telefono = document.getElementById("inputAsistenteTelefono").value.trim();
    const tipoAsistente = document.getElementById("selectTipoAsistente").value;

    const cantidadBoletos = obtenerCantidadBoletos();
    const idProyeccion = Number(document.getElementById("selectProyeccion").value);
    const idTarifa = Number(document.getElementById("selectTarifa").value);
    const metodoPago = document.getElementById("selectMetodoPago").value;

    if (!email || !nombreCompleto || !idProyeccion || !idTarifa || !metodoPago) {
        mostrarToast("Debes completar los datos del asistente y de la compra.", "error");
        return;
    }

    if (!esEmailValido(email)) {
        mostrarToast("Ingresa un email valido para identificar al asistente.", "error");
        return;
    }

    if (asientosSeleccionados.length !== cantidadBoletos) {
        mostrarToast(`Debes elegir ${cantidadBoletos} asiento(s) antes de comprar.`, "error");
        return;
    }

    try {
        let idAsistente;

        if (asistenteSeleccionado) {
            idAsistente = asistenteSeleccionado.IdAsistente;
        } else {
            const respuestaAsistente = await fetch(`${API}/api/asistentes`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({
                    nombreCompleto,
                    email,
                    telefono: telefono || null,
                    tipoAsistente
                })
            });

            const dataAsistente = await respuestaAsistente.json();

            if (!respuestaAsistente.ok || !dataAsistente.ok) {
                throw new Error(dataAsistente.mensaje || "No se pudo registrar al asistente.");
            }

            idAsistente = dataAsistente.data.IdAsistente;

            asistenteSeleccionado = dataAsistente.data;
        }

        const respuesta = await fetch(`${API}/api/comprar-entrada`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                idAsistente,
                idProyeccion,
                idTarifa,
                metodoPago,
                asientos: asientosSeleccionados
            })
        });

        const data = await respuesta.json();

        if (!respuesta.ok || !data.ok) {
            throw new Error(data.mensaje || "No se pudo registrar la compra.");
        }

        const compra = data.data;
        const entradas = compra.entradas || [compra];
        const detalleEntradas = entradas
            .map(entrada => `${entrada.Asiento ? `Asiento ${entrada.Asiento} - ` : ""}${entrada.CodigoAcceso}`)
            .join("\n");
        const totalPagado = Number(compra.TotalPagado || compra.MontoPagado || 0);

        setResultado(
            "resultadoCompra",
            `Compra registrada correctamente

IdVenta: ${compra.IdVenta}
Boletos: ${entradas.length}
Asientos y codigos:
${detalleEntradas}
Factura: ${compra.NroFactura}
Monto pagado: Bs ${totalPagado.toFixed(2)}

La compra fue registrada llamando al procedimiento P1_ComprarEntradas.`,
            "success"
        );

        ventasSesion.push({ metodoPago, monto: totalPagado });
        mostrarTicketDigital(compra, idProyeccion, metodoPago);

        mostrarToast("Compra registrada correctamente.", "success");
        reiniciarAsistente();
        await cargarDatos();

    } catch (error) {
        setResultado(
            "resultadoCompra",
            `✗ Compra rechazada

${error.message}

El error fue devuelto por SQL Server y capturado por la aplicación cliente.`,
            "error"
        );

        mostrarToast(error.message, "error");
    }
}

async function marcarAsistencia() {
    const input = document.getElementById("inputCodigoAsistencia");
    const codigoAcceso = input.value.trim();

    if (!codigoAcceso) {
        mostrarToast("Debes indicar un código de acceso.", "error");
        return;
    }

    try {
        const respuesta = await fetch(`${API}/api/marcar-asistencia`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ codigoAcceso })
        });

        const data = await respuesta.json();

        if (!respuesta.ok || !data.ok) {
            throw new Error(data.mensaje || "No se pudo registrar la asistencia.");
        }

        setResultado("resultadoAsistencia", data.mensaje, "success");
        mostrarToast(data.mensaje, "success");
        input.value = "";
        await cargarInformes();

    } catch (error) {
        setResultado("resultadoAsistencia", error.message, "error");
        mostrarToast(error.message, "error");
    }
}

async function programarProyeccion() {
    const idPeliculaEdicion = Number(document.getElementById("selectPeliculaAgenda").value);
    const idSala = Number(document.getElementById("selectSalaAgenda").value);
    const fechaHoraInicio = document.getElementById("inputFechaHora").value;
    const tieneQA = document.getElementById("checkQA").checked;

    if (!idPeliculaEdicion || !idSala || !fechaHoraInicio) {
        mostrarToast("Debes completar pelicula, sala y fecha/hora.", "error");
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
            throw new Error(data.mensaje || "No se pudo programar la proyeccion.");
        }

        setResultado(
            "resultadoAgenda",
            `Proyeccion programada correctamente

Pelicula-edicion: ${idPeliculaEdicion}
Sala: ${idSala}
Fecha y hora: ${fechaHoraInicio}
Q&A: ${tieneQA ? "Sí" : "No"}

La insercion fue permitida por TR1_ControlAgenda.`,
            "success"
        );

        mostrarToast("Proyeccion programada correctamente.", "success");
        await cargarDatos();

    } catch (error) {
        setResultado(
            "resultadoAgenda",
            `Proyeccion rechazada

${error.message}

El trigger TR1_ControlAgenda bloqueo la operacion y la interfaz mostro un mensaje amigable.`,
            "error"
        );

        mostrarToast(error.message, "error");
    }
}

function configurarRangoAgenda(edicion) {
    if (!edicion || !edicion.FechaInicio || !edicion.FechaFin) return;

    const inicio = edicion.FechaInicio.slice(0, 10);
    const fin = edicion.FechaFin.slice(0, 10);

    const input = document.getElementById("inputFechaHora");
    input.min = `${inicio}T00:00`;
    input.max = `${fin}T23:59`;

    if (!input.value) {
        input.value = `${inicio}T12:00`;
    }

    const formatear = (fechaISO) => {
        const [yyyy, mm, dd] = fechaISO.split("-");
        return `${dd}/${mm}/${yyyy}`;
    };

    document.getElementById("hintRangoEdicion").textContent =
        `Rango válido de la edición actual (Año ${edicion.Anio}): ${formatear(inicio)} al ${formatear(fin)}.`;
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

/* ============================================================
   MÓDULO 3: ABONOS
   ============================================================ */

function renderAbonoProyecciones() {
    const contenedor = document.getElementById("abonoProyeccionesLista");
    contenedor.innerHTML = "";
    abonoAsientos = {};
    abonoMapasAsientos = {};

    proyecciones.forEach(item => {
        const fila = document.createElement("label");
        fila.className = "abono-item";
        fila.innerHTML = `
            <input type="checkbox" value="${item.IdProyeccion}">
            <span>${item.IdProyeccion} - ${item.Pelicula} | ${item.NombreSala} | ${formatearFecha(item.FechaHoraInicio)}</span>
        `;
        fila.querySelector("input").addEventListener("change", () => {
            actualizarContadorAbono();
            actualizarAsientosAbono();
        });
        contenedor.appendChild(fila);
    });

    actualizarContadorAbono();
    renderAbonoAsientosPanel();
}

function mostrarInfoTipoAbono() {
    const idTipoAbono = Number(document.getElementById("selectTipoAbono").value);
    const tipo = tiposAbono.find(item => item.IdTipoAbono === idTipoAbono);

    document.getElementById("infoTipoAbono").textContent = tipo ? tipo.Descripcion : "";

    actualizarContadorAbono();
}

function actualizarContadorAbono() {
    const idTipoAbono = Number(document.getElementById("selectTipoAbono").value);
    const tipo = tiposAbono.find(item => item.IdTipoAbono === idTipoAbono);
    const max = tipo ? tipo.CantidadMaxProyecciones : 0;

    const seleccionadas = obtenerProyeccionesAbonoSeleccionadas().length;
    const asientosElegidos = Object.keys(abonoAsientos).length;

    document.getElementById("abonoContador").textContent = `(${seleccionadas}/${max})`;
    document.getElementById("abonoAsientosContador").textContent = `(${asientosElegidos}/${seleccionadas})`;
}

function obtenerProyeccionesAbonoSeleccionadas() {
    return Array.from(
        document.querySelectorAll("#abonoProyeccionesLista input:checked")
    ).map(input => Number(input.value));
}

async function actualizarAsientosAbono() {
    const seleccionadas = obtenerProyeccionesAbonoSeleccionadas();
    const seleccionadasSet = new Set(seleccionadas.map(String));

    Object.keys(abonoAsientos).forEach(idProyeccion => {
        if (!seleccionadasSet.has(idProyeccion)) {
            delete abonoAsientos[idProyeccion];
        }
    });

    renderAbonoAsientosPanel();

    await Promise.all(
        seleccionadas
            .filter(idProyeccion => !abonoMapasAsientos[idProyeccion])
            .map(async idProyeccion => {
                try {
                    abonoMapasAsientos[idProyeccion] = await obtenerJSON(`${API}/api/proyecciones/${idProyeccion}/asientos`);
                } catch (error) {
                    mostrarToast(error.message, "error");
                }
            })
    );

    renderAbonoAsientosPanel();
}

function renderAbonoAsientosPanel() {
    const panel = document.getElementById("abonoAsientosPanel");
    if (!panel) return;

    const seleccionadas = obtenerProyeccionesAbonoSeleccionadas();

    if (seleccionadas.length === 0) {
        panel.textContent = "Selecciona las proyecciones para elegir un asiento en cada sala.";
        actualizarContadorAbono();
        return;
    }

    panel.innerHTML = "";

    seleccionadas.forEach(idProyeccion => {
        const proyeccion = proyecciones.find(item => item.IdProyeccion === idProyeccion);
        const mapa = abonoMapasAsientos[idProyeccion];
        const card = document.createElement("div");
        card.className = "abono-seat-card";

        const titulo = document.createElement("div");
        titulo.className = "abono-seat-title";
        titulo.innerHTML = `
            <strong>${proyeccion ? proyeccion.Pelicula : `Proyección ${idProyeccion}`}</strong>
            <span>${proyeccion ? `${proyeccion.NombreSala} · ${formatearFecha(proyeccion.FechaHoraInicio)}` : ""}</span>
        `;

        const screen = document.createElement("div");
        screen.className = "screen-shape compact";
        screen.textContent = "Pantalla";

        const seats = document.createElement("div");
        seats.className = "seat-map abono-seat-map";

        if (!mapa) {
            seats.innerHTML = `<div class="seat-map-empty">Cargando asientos...</div>`;
        } else {
            mapa.asientos.forEach(asiento => {
                const boton = document.createElement("button");
                const seleccionado = abonoAsientos[idProyeccion] === asiento.codigo;

                boton.type = "button";
                boton.className = `seat ${asiento.estado}`;
                boton.textContent = asiento.codigo;
                boton.disabled = asiento.estado === "ocupado";
                boton.classList.toggle("seleccionado", seleccionado);
                boton.onclick = () => seleccionarAsientoAbono(idProyeccion, asiento.codigo);

                seats.appendChild(boton);
            });
        }

        card.appendChild(titulo);
        card.appendChild(screen);
        card.appendChild(seats);
        panel.appendChild(card);
    });

    actualizarContadorAbono();
}

function seleccionarAsientoAbono(idProyeccion, codigo) {
    if (abonoAsientos[idProyeccion] === codigo) {
        delete abonoAsientos[idProyeccion];
    } else {
        abonoAsientos[idProyeccion] = codigo;
    }

    renderAbonoAsientosPanel();
}

async function venderAbono() {
    const idAsistente = Number(document.getElementById("selectAsistenteAbono").value);
    const idTipoAbono = Number(document.getElementById("selectTipoAbono").value);
    const idTarifa = Number(document.getElementById("selectTarifaAbono").value);
    const metodoPago = document.getElementById("selectMetodoPagoAbono").value;
    const forzarFallo = document.getElementById("checkForzarFallo").checked;

    const proyeccionesSeleccionadas = obtenerProyeccionesAbonoSeleccionadas();

    if (!idAsistente || !idTipoAbono || !idTarifa || !metodoPago) {
        mostrarToast("Debes completar todos los datos del abono.", "error");
        return;
    }

    if (proyeccionesSeleccionadas.length === 0) {
        mostrarToast("Selecciona al menos una proyección para el abono.", "error");
        return;
    }

    if (proyeccionesSeleccionadas.some(idProyeccion => !abonoAsientos[idProyeccion])) {
        mostrarToast("Debes elegir un asiento para cada proyección del abono.", "error");
        return;
    }

    try {
        const respuesta = await fetch(`${API}/api/vender-abono`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                idAsistente,
                idTipoAbono,
                idTarifa,
                metodoPago,
                proyecciones: proyeccionesSeleccionadas,
                asientos: abonoAsientos,
                forzarFallo
            })
        });

        const data = await respuesta.json();

        if (!respuesta.ok || !data.ok) {
            throw new Error(data.mensaje || "No se pudo registrar el abono.");
        }

        const abono = data.data;
        const detalleProyecciones = (abono.proyecciones || [])
            .map(item => {
                const proyeccion = proyecciones.find(proy => proy.IdProyeccion === item.IdProyeccion);
                return `${proyeccion ? proyeccion.Pelicula : `Proyección ${item.IdProyeccion}`} | Asiento ${item.Asiento || "-"} | ${item.CodigoAcceso}`;
            })
            .join("\n");

        setResultado(
            "resultadoAbono",
            `Abono vendido correctamente

IdVenta: ${abono.IdVenta}
IdAbono: ${abono.IdAbono}
Factura: ${abono.NroFactura}
Total pagado: Bs ${Number(abono.TotalPagado).toFixed(2)}
Proyecciones incluidas: ${abono.CantidadProyecciones}
Asientos reservados:
${detalleProyecciones}

La venta fue registrada llamando al procedimiento T1_VenderAbono.`,
            "success"
        );

        mostrarAbonoDigital(abono);
        mostrarToast("Abono vendido correctamente.", "success");
        await cargarDatos();

    } catch (error) {
        setResultado(
            "resultadoAbono",
            `✗ Venta de abono rechazada

${error.message}

Si activaste "Forzar fallo de pasarela", T1_VenderAbono ejecutó ROLLBACK: no quedó ningún registro de Venta, Pago ni Abono.`,
            "error"
        );

        mostrarToast(error.message, "error");
    }
}

/* ============================================================
   MÓDULO 5: INFORMES
   ============================================================ */

async function cargarInformes() {
    try {
        const [ranking, premiacion, resumen, detalle] = await Promise.all([
            obtenerJSON(`${API}/api/informes/ranking-peliculas`),
            obtenerJSON(`${API}/api/informes/acta-premiacion`),
            obtenerJSON(`${API}/api/informes/financiero-resumen`),
            obtenerJSON(`${API}/api/informes/financiero-detalle`)
        ]);

        renderTablaRanking(ranking);
        renderTablaPremiacion(premiacion);
        renderTablaFinancieroResumen(resumen);
        renderTablaFinancieroDetalle(detalle);
    } catch (error) {
        mostrarToast(error.message, "error");
    }
}

function renderTablaRanking(datos) {
    const tbody = document.getElementById("tablaRanking");
    tbody.innerHTML = "";

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.Pelicula}</td>
            <td>${item.CantidadProyecciones}</td>
            <td>${item.CapacidadTotalProgramada}</td>
            <td>${item.AsistentesReales}</td>
            <td>${Number(item.PorcentajeOcupacion).toFixed(2)}%</td>
        `;
        tbody.appendChild(fila);
    });
}

function renderTablaPremiacion(datos) {
    const tbody = document.getElementById("tablaPremiacion");
    tbody.innerHTML = "";

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.Categoria}</td>
            <td>${item.PeliculaGanadora}</td>
            <td>${item.EstadoFestival}</td>
            <td>${item.DescripcionPremio ?? "—"}</td>
            <td>${item.PromedioVotacion ?? "—"}</td>
            <td>${item.CantidadEvaluaciones}</td>
        `;
        tbody.appendChild(fila);
    });
}

function renderTablaFinancieroResumen(datos) {
    const tbody = document.getElementById("tablaFinancieroResumen");
    tbody.innerHTML = "";

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.TipoAcceso}</td>
            <td>${item.CantidadVentas}</td>
            <td>Bs ${Number(item.TotalRecaudado).toFixed(2)}</td>
        `;
        tbody.appendChild(fila);
    });
}

function renderTablaFinancieroDetalle(datos) {
    const tbody = document.getElementById("tablaFinancieroDetalle");
    tbody.innerHTML = "";

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.TipoVentaAgrupado}</td>
            <td>${item.DetalleVenta}</td>
            <td>${item.TipoTarifa}</td>
            <td>${item.CantidadVentas}</td>
            <td>Bs ${Number(item.TotalRecaudado).toFixed(2)}</td>
        `;
        tbody.appendChild(fila);
    });
}

async function cargarEventosParalelos() {
    try {
        eventosParalelos = await obtenerJSON(`${API}/api/eventos-paralelos`);
        renderTablaEventos(eventosParalelos);

        llenarSelect(
            "selectEventoInscripcion",
            eventosParalelos,
            item => `${item.Titulo} | Bs ${Number(item.CostoInscripcion).toFixed(2)} | Cupos: ${item.AforoDisponible}`,
            "IdEvento"
        );

    } catch (error) {
        mostrarToast(error.message, "error");
    }
}

function renderTablaEventos(datos) {
    const tbody = document.getElementById("tablaEventos");
    tbody.innerHTML = "";

    if (datos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7">No hay eventos paralelos registrados para esta edición.</td></tr>`;
        return;
    }

    datos.forEach(item => {
        const fila = document.createElement("tr");
        const sala = item.NombreSala
            ? `${item.NombreSala} · ${item.NombreSede}`
            : "Sin sala asignada";

        fila.innerHTML = `
            <td>${item.TipoEvento}</td>
            <td>${item.Titulo}</td>
            <td>${sala}</td>
            <td>${formatearFecha(item.FechaHora)}</td>
            <td>${item.AforoDisponible} / ${item.AforoMax}</td>
            <td>Bs ${Number(item.CostoInscripcion).toFixed(2)}</td>
            <td>${item.Expositores ?? "Sin expositor asignado"}</td>
        `;
        tbody.appendChild(fila);
    });
}

async function inscribirseEvento() {
    const idAsistente = Number(document.getElementById("selectAsistenteEvento").value);
    const idEvento = Number(document.getElementById("selectEventoInscripcion").value);
    const metodoPago = document.getElementById("selectMetodoPagoEvento").value;

    if (!idAsistente || !idEvento) {
        mostrarToast("Debes seleccionar el asistente y el evento.", "error");
        return;
    }

    try {
        const respuesta = await fetch(`${API}/api/inscribir-evento`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ idAsistente, idEvento, metodoPago })
        });

        const data = await respuesta.json();

        if (!respuesta.ok || !data.ok) {
            throw new Error(data.mensaje || "No se pudo registrar la inscripción.");
        }

        const { CodigoAcceso, NroFactura, MontoPagado } = data.data;

        setResultado(
            "resultadoInscripcionEvento",
            `${data.mensaje}\nCódigo de acceso: ${CodigoAcceso}\nFactura: ${NroFactura}\nMonto pagado: Bs ${Number(MontoPagado).toFixed(2)}`,
            "success"
        );
        mostrarToast(data.mensaje, "success");

        await cargarEventosParalelos();

    } catch (error) {
        setResultado("resultadoInscripcionEvento", error.message, "error");
        mostrarToast(error.message, "error");
    }
}

async function cargarJurado() {
    try {
        const [jurados, miembros, peliculasComp, evaluaciones, premios] = await Promise.all([
            obtenerJSON(`${API}/api/jurados-categoria`),
            obtenerJSON(`${API}/api/miembros-jurado`),
            obtenerJSON(`${API}/api/peliculas-competencia`),
            obtenerJSON(`${API}/api/evaluaciones`),
            obtenerJSON(`${API}/api/premios`)
        ]);

        miembrosJurado = miembros;
        peliculasCompetencia = peliculasComp;

        renderTablaJurados(jurados);
        renderTablaEvaluaciones(evaluaciones);
        renderTablaPremios(premios);

        llenarSelect(
            "selectMiembroJurado",
            miembrosJurado,
            item => `${item.NombreCompleto} | ${item.NombreCategoria} | Edición ${item.AnioEdicion}`,
            "IdMiembro"
        );

        actualizarPeliculasCompetencia();

    } catch (error) {
        mostrarToast(error.message, "error");
    }
}

function renderTablaJurados(datos) {
    const tbody = document.getElementById("tablaJurados");
    tbody.innerHTML = "";

    if (datos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="4">No hay jurados registrados.</td></tr>`;
        return;
    }

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.AnioEdicion}</td>
            <td>${item.NombreCategoria}</td>
            <td>${item.NombreJurado}</td>
            <td>${item.Miembros ?? "Sin miembros asignados"}</td>
        `;
        tbody.appendChild(fila);
    });
}

function renderTablaEvaluaciones(datos) {
    const tbody = document.getElementById("tablaEvaluaciones");
    tbody.innerHTML = "";

    if (datos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7">No hay evaluaciones registradas.</td></tr>`;
        return;
    }

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.AnioEdicion}</td>
            <td>${item.NombreCategoria}</td>
            <td>${item.Pelicula}</td>
            <td>${item.Jurado}</td>
            <td>${Number(item.Puntuacion).toFixed(1)}</td>
            <td>${item.Comentario ?? ""}</td>
            <td>${formatearFecha(item.FechaEvaluacion)}</td>
        `;
        tbody.appendChild(fila);
    });
}

function renderTablaPremios(datos) {
    const tbody = document.getElementById("tablaPremios");
    tbody.innerHTML = "";

    if (datos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="4">No hay premios registrados.</td></tr>`;
        return;
    }

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.AnioEdicion}</td>
            <td>${item.NombreCategoria}</td>
            <td>${item.PeliculaGanadora}</td>
            <td>${item.DescripcionPremio}</td>
        `;
        tbody.appendChild(fila);
    });
}

function actualizarPeliculasCompetencia() {
    const selectMiembro = document.getElementById("selectMiembroJurado");
    const hint = document.getElementById("hintPeliculaCompetencia");

    if (!selectMiembro.value) {
        llenarSelect("selectPeliculaCompetencia", [], () => "", "IdPeliculaEdicion");
        hint.textContent = "Selecciona primero un miembro del jurado.";
        return;
    }

    const idMiembro = Number(selectMiembro.value);
    const miembro = miembrosJurado.find(item => item.IdMiembro === idMiembro);

    const peliculas = peliculasCompetencia.filter(item =>
        item.IdCategoria === miembro.IdCategoria && item.IdEdicion === miembro.IdEdicion
    );

    llenarSelect(
        "selectPeliculaCompetencia",
        peliculas,
        item => `${item.Titulo} (Edición ${item.AnioEdicion})`,
        "IdPeliculaEdicion"
    );

    hint.textContent = peliculas.length === 0
        ? "No hay películas en competencia para esta categoría y edición."
        : `Categoría: ${miembro.NombreCategoria}`;
}

async function registrarEvaluacion() {
    const idMiembro = Number(document.getElementById("selectMiembroJurado").value);
    const idPeliculaEdicion = Number(document.getElementById("selectPeliculaCompetencia").value);
    const puntuacion = Number(document.getElementById("inputPuntuacion").value);
    const comentario = document.getElementById("inputComentarioEvaluacion").value.trim();

    if (!idMiembro || !idPeliculaEdicion || !puntuacion) {
        mostrarToast("Debes seleccionar el jurado, la película y la puntuación.", "error");
        return;
    }

    const miembro = miembrosJurado.find(item => item.IdMiembro === idMiembro);
    const idCategoria = miembro.IdCategoria;

    try {
        const respuesta = await fetch(`${API}/api/evaluaciones`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                idMiembro,
                idPeliculaEdicion,
                idCategoria,
                puntuacion,
                comentario
            })
        });

        const data = await respuesta.json();

        if (!respuesta.ok || !data.ok) {
            throw new Error(data.mensaje || "No se pudo registrar la evaluación.");
        }

        setResultado("resultadoEvaluacion", data.mensaje, "success");
        mostrarToast(data.mensaje, "success");
        document.getElementById("inputComentarioEvaluacion").value = "";

        const evaluaciones = await obtenerJSON(`${API}/api/evaluaciones`);
        renderTablaEvaluaciones(evaluaciones);

    } catch (error) {
        setResultado("resultadoEvaluacion", error.message, "error");
        mostrarToast(error.message, "error");
    }
}

async function cargarFichaPelicula() {
    try {
        peliculasTodas = await obtenerJSON(`${API}/api/peliculas-todas`);

        llenarSelect(
            "selectFichaPelicula",
            peliculasTodas,
            item => `${item.Titulo} (${item.AnioProduccion})`,
            "IdPelicula"
        );

        await mostrarFichaPelicula();

    } catch (error) {
        mostrarToast(error.message, "error");
    }
}

async function mostrarFichaPelicula() {
    const select = document.getElementById("selectFichaPelicula");
    const idPelicula = Number(select.value);

    if (!idPelicula) return;

    try {
        const ficha = await obtenerJSON(`${API}/api/ficha-pelicula/${idPelicula}`);
        const { detalle, reparto, historial } = ficha;

        document.getElementById("fichaTitulo").textContent = detalle.Titulo;

        document.getElementById("fichaDetalle").innerHTML = `
            <p><strong>Año de producción:</strong> ${detalle.AnioProduccion}</p>
            <p><strong>Duración:</strong> ${detalle.DuracionMin} min</p>
            <p><strong>País de origen:</strong> ${detalle.PaisOrigen}</p>
            <p><strong>Clasificación:</strong> ${detalle.ClasifEdades}</p>
            <p><strong>Formato:</strong> ${detalle.FormatoProyeccion}</p>
            <p><strong>Géneros:</strong> ${detalle.Generos ?? "Sin géneros asignados"}</p>
            <p><strong>Sinopsis:</strong> ${detalle.Sinopsis}</p>
        `;

        renderTablaHistorialPelicula(historial);
        renderTablaRepartoPelicula(reparto);

    } catch (error) {
        mostrarToast(error.message, "error");
    }
}

function renderTablaHistorialPelicula(datos) {
    const tbody = document.getElementById("tablaHistorialPelicula");
    tbody.innerHTML = "";

    if (datos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="2">Sin participaciones registradas.</td></tr>`;
        return;
    }

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.AnioEdicion}</td>
            <td>${item.EstadoFestival}</td>
        `;
        tbody.appendChild(fila);
    });
}

function renderTablaRepartoPelicula(datos) {
    const tbody = document.getElementById("tablaRepartoPelicula");
    tbody.innerHTML = "";

    if (datos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="4">Sin reparto o equipo técnico registrado.</td></tr>`;
        return;
    }

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.Rol}</td>
            <td>${item.NombreCompleto}</td>
            <td>${item.Nacionalidad}</td>
            <td>${item.PersonajeActuado ?? "-"}</td>
        `;
        tbody.appendChild(fila);
    });
}

async function cargarLogistica() {
    try {
        const [alojamientos, traslados, patrocinios] = await Promise.all([
            obtenerJSON(`${API}/api/alojamientos`),
            obtenerJSON(`${API}/api/traslados`),
            obtenerJSON(`${API}/api/patrocinios`)
        ]);

        renderTablaAlojamientos(alojamientos);
        renderTablaTraslados(traslados);
        renderTablaPatrocinios(patrocinios);

    } catch (error) {
        mostrarToast(error.message, "error");
    }
}

function renderTablaAlojamientos(datos) {
    const tbody = document.getElementById("tablaAlojamientos");
    tbody.innerHTML = "";

    if (datos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="6">No hay alojamientos registrados.</td></tr>`;
        return;
    }

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.AnioEdicion}</td>
            <td>${item.NombreCompleto}</td>
            <td>${item.NombreHotel}</td>
            <td>${item.NroHabitacion}</td>
            <td>${formatearFechaCorta(item.CheckIn)}</td>
            <td>${formatearFechaCorta(item.CheckOut)}</td>
        `;
        tbody.appendChild(fila);
    });
}

function renderTablaTraslados(datos) {
    const tbody = document.getElementById("tablaTraslados");
    tbody.innerHTML = "";

    if (datos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7">No hay traslados registrados.</td></tr>`;
        return;
    }

    datos.forEach(item => {
        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.AnioEdicion}</td>
            <td>${item.NombreCompleto}</td>
            <td>${item.TipoTraslado}</td>
            <td>${item.Origen}</td>
            <td>${item.Destino}</td>
            <td>${formatearFecha(item.FechaHora)}</td>
            <td>${item.NroVuelo ?? "-"}</td>
        `;
        tbody.appendChild(fila);
    });
}

function renderTablaPatrocinios(datos) {
    const tbody = document.getElementById("tablaPatrocinios");
    tbody.innerHTML = "";

    if (datos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="5">No hay patrocinios registrados.</td></tr>`;
        return;
    }

    datos.forEach(item => {
        const aportacion = item.MontoEconomico != null
            ? `Bs ${Number(item.MontoEconomico).toFixed(2)}`
            : item.DescripcionEspecie;

        const fila = document.createElement("tr");
        fila.innerHTML = `
            <td>${item.AnioEdicion}</td>
            <td>${item.NombreEmpresa}</td>
            <td>${item.Contacto ?? "-"}</td>
            <td>${item.TipoAportacion}</td>
            <td>${aportacion}</td>
        `;
        tbody.appendChild(fila);
    });
}

document.addEventListener("DOMContentLoaded", () => {
    configurarChartDefaults();

    document.getElementById("selectProyeccion").addEventListener("change", () => {
        marcarProyeccionSeleccionada();
        cargarAsientosProyeccion();
    });
    document.getElementById("selectTarifa").addEventListener("change", actualizarResumenCompra);
    document.getElementById("inputCantidadBoletos").addEventListener("input", normalizarCantidadBoletos);
    document.getElementById("selectTipoAbono").addEventListener("change", mostrarInfoTipoAbono);
    document.getElementById("inputAsistenteEmail").addEventListener("input", buscarAsistentePorEmail);
    document.getElementById("selectMiembroJurado").addEventListener("change", actualizarPeliculasCompetencia);
    document.getElementById("selectFichaPelicula").addEventListener("change", mostrarFichaPelicula);

    cargarDatos();
});



