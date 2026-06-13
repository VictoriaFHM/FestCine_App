# Asunciones del Proyecto FestCine

El enunciado permite realizar suposiciones razonables sobre reglas de negocio
no especificadas, siempre que se documenten. Esta sección reúne todas las
asunciones tomadas durante el diseño e implementación del sistema.

---

## 1. Control de aforo

**Asunción:** el aforo disponible de una proyección
(`Proyeccion.AforoDisponibleActual`) se descuenta **en el momento de la
compra** (entrada individual o abono), no en el momento en que el asistente
efectivamente ingresa a la sala.

**Justificación:** el enunciado pide validar "si aún hay aforo disponible" al
comprar (P1) y reservar un cupo al vender un abono (T1); no existe un proceso
de "check-in" en los módulos obligatorios (Taquilla y Agenda). Reservar el
cupo en la compra es la interpretación estándar de un sistema de boletería
(evita sobreventa) y es la que permite implementar el bloqueo
`WITH (UPDLOCK, HOLDLOCK)` en `P1_ComprarEntrada` y `T1_VenderAbono`.

**Consecuencia:** el campo `Asistio` (en `Entrada` y `AbonoProyeccion`) es
**independiente** del aforo — se usa únicamente como dato histórico para la
consulta de "Ranking de Películas / % de ocupación real" (Asistentes reales
vs. capacidad de sala), y se puebla solo desde los datos de prueba (DML),
no desde la UI. No existe un módulo de "marcar asistencia" porque no es un
módulo obligatorio del enunciado.

---

## 2. Política de reembolsos / cancelaciones

**Asunción:** el sistema **no implementa** un procedimiento de
cancelación/reembolso (no hay un `P2_CancelarEntrada` ni endpoint asociado).

**Justificación:** el enunciado solo menciona la política de reembolsos como
*ejemplo* de algo que puede quedar como asunción documentada, y no forma
parte de los entregables obligatorios (P1, T1, TR1). La tabla `Venta`
contempla el estado `'Anulada'` en su `CHECK` (`EstadoVenta`) para que el
modelo de datos **soporte** una futura extensión, pero actualmente ninguna
venta cambia a ese estado.

**Si se requiriera implementarlo:** un reembolso debería (a) cambiar
`Venta.EstadoVenta` a `'Anulada'`, (b) cambiar `Pago.EstadoPago` a
`'Rechazado'`, y (c) **incrementar** `Proyeccion.AforoDisponibleActual` (o
`EventoParalelo.AforoDisponible` / revertir la fila de `AbonoProyeccion`)
para liberar el cupo — todo dentro de una transacción análoga a `T1`.

---

## 3. Tarifa "Acreditado" ($0) y control de aforo VIP

**Asunción:** existe una tarifa `Acreditado` con `Monto = 0.00` (ver
`02_DML_Llenado_Datos.sql`, línea 120) que se usa para acreditaciones VIP /
Jurado / Prensa / Industria. `P1_ComprarEntrada` registra la `Entrada` y
descuenta el aforo **igual que con cualquier otra tarifa**, sin importar que
el monto sea $0.

**Justificación:** esto cumple textualmente el requisito D del enunciado:
*"Las acreditaciones VIP suelen tener tarifa $0 [...] pero deben registrarse
por control de aforo"*. La validación de **qué tarifa corresponde a qué
asistente** (por ejemplo, que solo un asistente con `TipoAsistente =
'Acreditado'` pueda seleccionar la tarifa `Acreditado`) **no se valida
automáticamente en el servidor**; se asume que es una decisión del operador
de taquilla (rol Cajero) al seleccionar la tarifa en la UI. Esto se documenta
como limitación conocida, no como una regla de negocio faltante crítica.

---

## 4. Trigger TR1: `INSTEAD OF INSERT` en lugar de `BEFORE INSERT`

**Asunción / adaptación técnica:** el enunciado describe TR1 como un trigger
`BEFORE INSERT`. SQL Server **no soporta triggers `BEFORE`** (solo
`INSTEAD OF` y `AFTER`). Se implementó como `INSTEAD OF INSERT`, que es el
equivalente funcional correcto para "interceptar el INSERT antes de que
ocurra, validar, y decidir si se ejecuta o no".

**Justificación:** un `AFTER INSERT` requeriría insertar la fila primero y
luego revertirla con `ROLLBACK`/`DELETE` si la validación falla, lo cual es
menos eficiente y más propenso a efectos secundarios (por ejemplo,
recálculo de `IDENTITY`). `INSTEAD OF INSERT` permite validar **antes** de
escribir cualquier dato, lanzar un `THROW` con un código de error específico
(51000–51005) y, solo si todas las validaciones pasan, ejecutar el `INSERT`
real (incluyendo el cálculo de `AforoDisponibleActual = CapacidadAsientos`
de la sala).

---

## 5. Reglas adicionales validadas por TR1 (más allá del cruce de horarios)

El enunciado pide explícitamente solo la validación de cruce de horarios
(duración + 30 min de limpieza). Se añadieron validaciones adicionales,
documentadas aquí como asunciones de buena práctica:

- **51000 / 51001** — la sala y la película-edición referenciadas deben
  existir (integridad referencial explícita con mensaje amigable, en vez de
  depender del error genérico de FK de SQL Server).
- **51002** — solo películas con `EstadoFestival IN ('Seleccionada',
  'Premiada')` pueden programarse. *Asunción:* una película `'Postulada'` o
  `'Rechazada'` no debería tener proyecciones públicas todavía.
- **51003** — la fecha/hora de la proyección debe estar dentro del rango
  `[Edicion.FechaInicio, Edicion.FechaFin]` (inclusive el día completo de
  `FechaFin`, mediante `DATEADD(DAY,1,FechaFin)`). *Asunción:* no se pueden
  programar proyecciones fuera de las fechas oficiales del festival.
- **51004** — cruce de horario en la misma sala (duración + 30 min de
  limpieza), tal como pide el enunciado.
- **51005** — si se insertan **varias proyecciones en un mismo INSERT**
  (multi-fila), también se valida que no se solapen entre sí.

**Fuera de alcance (limitación conocida):** TR1 valida cruces entre
`Proyeccion` y `Proyeccion`, pero **no** valida si una sala está ocupada por
un `EventoParalelo` en ese horario (y viceversa). Se asume que la
coordinación entre proyecciones y eventos paralelos en una misma sala es
responsabilidad operativa del coordinador del festival, fuera del alcance de
los módulos obligatorios.

---

## 6. T1_VenderAbono: simulación de pasarela de pago y cálculo del monto

**Asunción 1 — Simulación de fallo de pago:** no existe integración real con
una pasarela de pago. El parámetro `@ForzarFallo BIT = 0` permite simular un
fallo de pago (error 53009) **después** de insertar `Venta` y `Pago` pero
**antes** de insertar `Abono`/`AbonoProyeccion`/`Factura`, disparando el
`ROLLBACK TRANSACTION` completo. Esto cumple el requisito T1 de
*"Si la pasarela de pago falla [...] se debe aplicar un ROLLBACK"* de forma
demostrable y determinística para la presentación.

**Asunción 2 — Cálculo del monto total del abono:**
```sql
SET @Total = CASE WHEN @MontoTarifa = 0 THEN 0 ELSE @PrecioBase END;
```
Es decir: si la tarifa seleccionada es la tarifa `Acreditado` ($0), el abono
completo es gratuito (acreditación VIP/Jurado/etc. da acceso sin costo);
en cualquier otro caso, se cobra `TipoAbono.PrecioBase` **independientemente**
del monto específico de la tarifa no-VIP seleccionada (es decir, el campo
`@IdTarifa` para un abono no-VIP es informativo/de clasificación, no
multiplica el precio base). *Justificación:* el enunciado no detalla cómo
interactúan tarifas y abonos; esta regla simple (todo-o-nada según
acreditación VIP) es razonable y queda documentada para la justificación oral.

---

## 7. Edición "actual" del festival

**Asunción:** la "edición actual" (la que se muestra en Taquilla, Agenda y
Datos) es siempre la de **mayor `Anio`** registrada en la tabla `Edicion`
(`E.Anio = (SELECT MAX(Anio) FROM Edicion)`), usada en `vw_PeliculasDisponibles`
y `vw_ProyeccionesDisponibles`. Las ediciones anteriores permanecen en la base
de datos para las consultas históricas/estadísticas (Acta de Premiación,
Informe Financiero), pero no aparecen como "disponibles" para venta.

---

## 8. Alcance de la aplicación cliente-servidor (Fase 5)

**Asunción:** los módulos **obligatorios** son únicamente Taquilla (P1) y
Agenda (TR1), tal como exige la Fase 5 del enunciado. Las siguientes áreas
del modelo de datos (Competición/Jurados/Premios, Eventos Paralelos,
Logística de invitados, Patrocinios, venta de Abonos vía UI) están
**completamente modeladas y pobladas** (DDL + DML) y son consultables vía
DQL, pero **no tienen un módulo de interfaz dedicado**, ya que no son parte
de los módulos obligatorios. La venta de abonos (T1) se valida mediante
`04B_PRUEBAS_Backend.sql` directamente sobre SQL Server.

> Nota: agregar un módulo de UI para Abonos (invocando T1) es una mejora
> *opcional* contemplada en el plan de trabajo, no un requisito de la Fase 5.

---

## 9. Métodos de pago y estados

**Asunción:** los métodos de pago (`Efectivo`, `Tarjeta`, `Transferencia`,
`QR`) se aceptan todos como válidos y, al no existir pasarela real, todo pago
no simulado-como-fallido se registra con `EstadoPago = 'Aprobado'` de forma
inmediata (sin estado `'Pendiente'` intermedio). El estado `'Pendiente'`
existe en el `CHECK` de `Pago`/`Venta` para soportar una futura integración
real, pero no se usa en los procedimientos actuales.

---

## 10. Códigos de acceso y numeración de facturas

**Asunción:** los códigos de acceso y números de factura son generados
internamente por los procedimientos almacenados con un formato secuencial
legible, sin dependencia de un sistema externo:

- Entrada individual: `ENT-NNNNNN` (basado en `IdVenta`).
- Abono por proyección: `ABO-NNNNNN-PPP` (`IdAbono` + `IdProyeccion`).
- Factura: `FAC-NNNNNN` (basado en `IdVenta`).

No se asume integración con un sistema de facturación fiscal externo (no se
generan códigos de verificación, QR fiscal, etc.) — esto está fuera del
alcance académico del proyecto.
