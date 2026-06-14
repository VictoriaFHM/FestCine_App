# Normalización — Justificación de Tercera Forma Normal (3FN)

Este documento justifica que el modelo implementado en
[`01_DDL_Creacion_Tablas.sql`](../SQL/01_DDL_Creacion_Tablas.sql) cumple la
Tercera Forma Normal (3FN), y documenta los casos puntuales donde se aplicó
una **desnormalización deliberada** por razones de rendimiento e integridad
transaccional (ver también [03_Asunciones.md](03_Asunciones.md)).

## Recordatorio de las reglas aplicadas

- **1FN**: todos los atributos son atómicos (sin listas ni grupos repetitivos)
  y existe una clave primaria que identifica de forma única cada fila.
- **2FN**: cumple 1FN y, además, **ningún atributo no-clave depende solo de
  una parte** de una clave primaria compuesta (sin dependencias parciales).
- **3FN**: cumple 2FN y, además, **ningún atributo no-clave depende de otro
  atributo no-clave** (sin dependencias transitivas); todo atributo no-clave
  depende **únicamente** de la clave primaria completa.

Estrategia general del diseño: se usan **claves sustitutas** (`IDENTITY`)
como PK en casi todas las tablas, y los catálogos (Genero, Tarifa, TipoAbono,
CategoriaComp, Sede, etc.) están separados en tablas propias, de modo que sus
atributos descriptivos **no se repiten** en las tablas que los referencian
(solo se guarda la FK). Esto evita por construcción la mayoría de las
dependencias transitivas.

---

## Módulo A — Catálogo Cinematográfico y Personal

| Tabla | Clave primaria | Dependencias funcionales (no-clave → depende de) | 1FN/2FN/3FN |
|---|---|---|---|
| `Edicion` | `IdEdicion` | `Anio, FechaInicio, FechaFin, Ciudad, Tema` → `IdEdicion` | ✅ Clave simple, sin atributos no-clave entre sí. |
| `Genero` | `IdGenero` | `NombreGenero` → `IdGenero` | ✅ Tabla catálogo de un solo atributo. |
| `Pelicula` | `IdPelicula` | `Titulo, AnioProduccion, DuracionMin, PaisOrigen, Sinopsis, ClasifEdades, FormatoProyeccion` → `IdPelicula` | ✅ Todos describen a la película en sí (no dependen de género, edición, etc.). |
| `PeliculaGenero` | `(IdPelicula, IdGenero)` | sin atributos no-clave | ✅ Tabla puente M:N pura — resuelve "una película tiene varios géneros y un género agrupa varias películas". |
| `PeliculaEdicion` | `IdPeliculaEdicion` (UK: `IdPelicula+IdEdicion`) | `EstadoFestival` → `(IdPelicula, IdEdicion)` | ✅ `EstadoFestival` es el estado **de esa película en esa edición concreta**; al ser `IdPeliculaEdicion` un sustituto 1:1 de `(IdPelicula,IdEdicion)`, no hay dependencia parcial ni transitiva. |
| `PersonalCine` | `IdPersonal` | `NombreCompleto, Nacionalidad, FechaNac, Biografia, Email, Telefono` → `IdPersonal` | ✅ Atributos propios de la persona, centralizados (un director y actor es una sola fila). |
| `RolPelicula` | `(IdPersonal, IdPelicula, Rol)` | `PersonajeActuado` → `(IdPersonal, IdPelicula, Rol)` | ✅ Ver nota 1 más abajo. |

**Nota 1 — `RolPelicula.PersonajeActuado`:** este atributo solo tiene sentido
cuando `Rol = 'Actor'`, pero su valor depende exclusivamente de la
combinación completa `(IdPersonal, IdPelicula, Rol)` — no existe otro
atributo no-clave del cual dependa, por lo que **no rompe 3FN** (es un
atributo "disperso"/opcional, no una dependencia transitiva). La
alternativa de crear una tabla `Actuacion` separada se evaluó pero se
descartó por agregar complejidad sin eliminar ninguna redundancia real.

---

## Módulo B — Agenda, Sedes y Eventos Paralelos

| Tabla | Clave primaria | Dependencias funcionales | 1FN/2FN/3FN |
|---|---|---|---|
| `Sede` | `IdSede` | `NombreSede, Direccion, Ciudad` → `IdSede` | ✅ |
| `Sala` | `IdSala` | `IdSede, NombreSala, CapacidadAsientos` → `IdSala` | ✅ No se duplica `NombreSede`/`Ciudad` aquí (se obtiene vía FK + `Sede`). |
| `Proyeccion` | `IdProyeccion` | `IdPeliculaEdicion, IdSala, FechaHoraInicio, TieneQA, AforoDisponibleActual` → `IdProyeccion` | ✅ con observación. Ver **Caso especial 1** (contador de aforo). |
| `EventoParalelo` | `IdEvento` | `IdEdicion, IdSala, TipoEvento, Titulo, AforoMax, AforoDisponible, CostoInscripcion, FechaHora` → `IdEvento` | ✅ con observación. Ver **Caso especial 1**. |
| `ExpositorEvento` | `(IdEvento, IdPersonal)` | `RolExpositor` → `(IdEvento, IdPersonal)` | ✅ Tabla puente M:N — el rol depende de la combinación evento+persona, no de cada parte por separado. |

---

## Módulo C — Competición, Jurados y Premios

| Tabla | Clave primaria | Dependencias funcionales | 1FN/2FN/3FN |
|---|---|---|---|
| `CategoriaComp` | `IdCategoria` | `NombreCategoria, Descripcion` → `IdCategoria` | ✅ |
| `JuradoCategoria` | `IdJuradoCategoria` (UK: `IdEdicion+IdCategoria`) | `NombreJurado` → `(IdEdicion, IdCategoria)` | ✅ Representa "el panel de jurado de la categoría X en la edición Y"; un solo panel por combinación (garantizado por la UK). |
| `MiembroJurado` | `IdMiembro` (UK: `IdJuradoCategoria+IdPersonal`) | sin atributos no-clave adicionales | ✅ Permite que `IdPersonal` integre **distintos** paneles (distintas categorías/ediciones) sin duplicar sus datos personales. |
| `PeliculaCategoria` | `(IdPeliculaEdicion, IdCategoria)` | sin atributos no-clave | ✅ Tabla puente M:N — "una película-edición compite en varias categorías". |
| `Evaluacion` | `IdEvaluacion` (UK: `IdMiembro+IdPeliculaEdicion+IdCategoria`) | `Puntuacion, Comentario, FechaEvaluacion` → `(IdMiembro, IdPeliculaEdicion, IdCategoria)` | ✅ La nota/comentario de **ese** jurado para **esa** película en **esa** categoría. La FK compuesta hacia `PeliculaCategoria` además garantiza que solo se evalúe una película en una categoría en la que realmente compite (regla de integridad, no de normalización). |
| `Premio` | `IdPremio` (UK: `IdEdicion+IdCategoria`) | `IdPeliculaEdicion, DescripcionPremio` → `(IdEdicion, IdCategoria)` | ✅ Un solo ganador por categoría y edición (garantizado por la UK). |

---

## Módulo D — Clientes, Acreditaciones y Ventas

| Tabla | Clave primaria | Dependencias funcionales | 1FN/2FN/3FN |
|---|---|---|---|
| `Asistente` | `IdAsistente` | `NombreCompleto, Email, Telefono, TipoAsistente` → `IdAsistente` | ✅ |
| `Acreditacion` | `IdAcreditacion` (UK: `IdAsistente+IdEdicion+TipoAcred`) | `FechaVencimiento` → `(IdAsistente, IdEdicion, TipoAcred)` | ✅ La vigencia depende de **esa** acreditación específica (un asistente puede tener acreditaciones distintas en ediciones distintas, o incluso varios tipos en la misma edición). |
| `Tarifa` | `IdTarifa` | `TipoTarifa, Monto` → `IdTarifa` | ✅ Catálogo de tarifas vigentes. |
| `TipoAbono` | `IdTipoAbono` | `NombreTipoAbono, Descripcion, CantidadMaxProyecciones, PrecioBase` → `IdTipoAbono` | ✅ |
| `Venta` | `IdVenta` | `IdAsistente, FechaVenta, TipoVenta, Total, EstadoVenta` → `IdVenta` | ✅ con observación. Ver **Caso especial 2** (`Total`). |
| `Pago` | `IdPago` (UK: `IdVenta`) | `MetodoPago, MontoPagado, EstadoPago, FechaPago` → `IdVenta` | ✅ Relación 1:1 con `Venta` (un pago por venta). Ver **Caso especial 2**. |
| `Factura` | `IdFactura` (UK: `IdVenta`, `NroFactura`) | `NroFactura, FechaEmision, MontoTotal` → `IdVenta` | ✅ Relación 1:1 con `Venta`. Ver **Caso especial 2**. |
| `Entrada` | `IdEntrada` | `IdVenta, IdProyeccion, IdTarifa, Asiento, FechaCompra, CodigoAcceso, Asistio` → `IdEntrada` | ✅ No almacena el monto (se obtiene vía FK a `Tarifa`/`Pago`), evitando redundancia. `Asiento` depende de la entrada emitida y se protege con unicidad por proyección. |
| `EntradaEvento` | `IdEntradaEvento` | `IdVenta, IdEvento, IdTarifa, FechaCompra, CodigoAcceso, Asistio` → `IdEntradaEvento` | ✅ Igual razonamiento que `Entrada`. |
| `Abono` | `IdAbono` (UK: `IdVenta`) | `IdTarifa, IdTipoAbono, FechaCompra, MontoTotal` → `IdAbono` | ✅ con observación. Ver **Caso especial 2** (`MontoTotal`). |
| `AbonoProyeccion` | `(IdAbono, IdProyeccion)` | `Asiento, CodigoAcceso, Asistio, FechaUso` → `(IdAbono, IdProyeccion)` | ✅ Tabla puente M:N — el código de acceso, asiento reservado y estado de uso son propios de **esa** proyección dentro de **ese** abono. |

---

## Módulo E — Logística y Patrocinios

| Tabla | Clave primaria | Dependencias funcionales | 1FN/2FN/3FN |
|---|---|---|---|
| `Alojamiento` | `IdAlojamiento` | `IdPersonal, IdEdicion, NombreHotel, NroHabitacion, CheckIn, CheckOut` → `IdAlojamiento` | ✅ con observación. Ver **Nota 2**. |
| `Traslado` | `IdTraslado` | `IdPersonal, IdEdicion, TipoTraslado, Origen, Destino, FechaHora, NroVuelo` → `IdTraslado` | ✅ Todos los atributos describen ese traslado específico. |
| `Patrocinador` | `IdPatrocinador` | `NombreEmpresa, Contacto, Email, Telefono` → `IdPatrocinador` | ✅ |
| `Patrocinio` | `IdPatrocinio` | `IdPatrocinador, IdEdicion, TipoAportacion, MontoEconomico, DescripcionEspecie` → `IdPatrocinio` | ✅ Un patrocinador puede aportar en varias ediciones sin duplicar sus datos de contacto. |

**Nota 2 — `Alojamiento.NombreHotel`:** se modela el hotel como un atributo
descriptivo simple (no como entidad propia) porque no se requiere almacenar
más datos del hotel (dirección, teléfono, etc.). Al no existir otros
atributos que dependieran de `NombreHotel`, no hay dependencia transitiva
que viole 3FN; se documenta como una simplificación de alcance (ver
Asunciones).

---

## Casos especiales de desnormalización justificada

### Caso especial 1 — Contadores de aforo (`Proyeccion.AforoDisponibleActual`, `EventoParalelo.AforoDisponible`)

Estos campos son **redundantes** en sentido estricto: en teoría podrían
calcularse en cualquier momento como:

```
AforoDisponibleActual = Sala.CapacidadAsientos
                         - COUNT(Entrada WHERE IdProyeccion = ...)
                         - COUNT(AbonoProyeccion WHERE IdProyeccion = ...)
```

**Por qué se desnormaliza:** calcular este valor "al vuelo" en cada compra
obligaría a recorrer y agregar dos tablas (`Entrada` y `AbonoProyeccion`)
dentro de cada transacción de venta, y —más importante— **no resolvería por
sí solo la condición de carrera** de dos compras simultáneas para el último
cupo disponible. Mantener un contador propio permite:

1. Bloquear la fila de `Proyeccion`/`EventoParalelo` con
   `WITH (UPDLOCK, HOLDLOCK)` (usado en `P1_ComprarEntrada` y
   `T1_VenderAbono`) para garantizar atomicidad bajo concurrencia.
2. Validar el aforo con una simple comparación (`<= 0`) en lugar de un
   `COUNT()` agregado.

Esta es una desnormalización **de rendimiento y control transaccional**,
explícitamente permitida por el enunciado ("Justificar si se decide
desnormalizar alguna tabla por razones de rendimiento"). El campo se
inicializa en `TR1_ControlAgenda` (= capacidad de la sala) y se mantiene
consistente exclusivamente a través de `P1_ComprarEntrada` y
`T1_VenderAbono` (nunca se actualiza directamente desde el cliente).

### Caso especial 2 — Montos "congelados" (`Venta.Total`, `Pago.MontoPagado`, `Factura.MontoTotal`, `Abono.MontoTotal`)

A primera vista, estos montos podrían parecer redundantes con
`Tarifa.Monto` o `TipoAbono.PrecioBase` (dependencia transitiva
`Venta.Total → Tarifa.Monto → IdTarifa`). Sin embargo, **no son la misma
dependencia funcional**:

- `Tarifa.Monto` y `TipoAbono.PrecioBase` representan el **precio vigente
  actual** del catálogo (puede cambiar con el tiempo: ajustes de precios
  entre ediciones).
- `Venta.Total`, `Pago.MontoPagado`, `Factura.MontoTotal` y
  `Abono.MontoTotal` representan el **monto efectivamente cobrado en el
  momento de esa transacción** — un hecho histórico que **no debe cambiar**
  aunque la tarifa del catálogo se actualice después.

Por lo tanto, estos atributos dependen funcionalmente de
`IdVenta`/`IdPago`/`IdFactura`/`IdAbono` (la transacción), **no** de
`IdTarifa`/`IdTipoAbono` — no hay violación de 3FN. Esta separación es,
además, un requisito de trazabilidad financiera y de auditoría (las
facturas emitidas no pueden "recalcularse" si cambian los precios del
festival).

---

## Conclusión

Las 33 tablas cumplen 1FN (atributos atómicos, PK definida), 2FN (sin
dependencias parciales en las tablas con clave compuesta —
`PeliculaGenero`, `RolPelicula`, `PeliculaCategoria`, `ExpositorEvento`,
`AbonoProyeccion`) y 3FN (sin dependencias transitivas entre atributos
no-clave). Los dos únicos patrones de redundancia presentes en el modelo
(contadores de aforo y montos congelados en ventas) son desnormalizaciones
**deliberadas**, justificadas por rendimiento/concurrencia y por
trazabilidad financiera respectivamente, y se documentan también en
[03_Asunciones.md](03_Asunciones.md).
