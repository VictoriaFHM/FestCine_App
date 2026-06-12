# Documentación Técnica — FestCine

Este directorio contiene la documentación de la Fase 1 (Modelado Lógico) y
las asunciones de negocio del proyecto, requeridas por el reporte final.

| Documento | Contenido |
|---|---|
| [01_DER.md](01_DER.md) | Diagrama Entidad-Relación general (33 tablas) + 5 diagramas por módulo con atributos (Mermaid). |
| [02_Normalizacion_3FN.md](02_Normalizacion_3FN.md) | Justificación de 1FN/2FN/3FN tabla por tabla, y casos de desnormalización justificada (contadores de aforo, montos congelados). |
| [03_Asunciones.md](03_Asunciones.md) | Asunciones de negocio no especificadas en el enunciado (aforo, reembolsos, tarifa VIP, pasarela de pago simulada, alcance de la UI, etc.). |

## Cómo visualizar los diagramas Mermaid

- **VS Code:** instalar la extensión "Markdown Preview Mermaid Support" y
  abrir la vista previa (`Ctrl+Shift+V`).
- **Online:** copiar el bloque ```mermaid``` en https://mermaid.live
- **GitHub:** los diagramas Mermaid en archivos `.md` se renderizan
  automáticamente en la vista del repositorio.

## Relación con el resto del proyecto

- El modelo descrito aquí corresponde a
  [`../SQL/01_DDL_Creacion_Tablas.sql`](../SQL/01_DDL_Creacion_Tablas.sql).
- Los procedimientos/triggers mencionados en las Asunciones están en
  [`../SQL/04_BACKEND_Procedimientos_Triggers.sql`](../SQL/04_BACKEND_Procedimientos_Triggers.sql).
- Las pruebas de P1/T1/TR1 están en
  [`../SQL/04B_PRUEBAS_Backend.sql`](../SQL/04B_PRUEBAS_Backend.sql).
