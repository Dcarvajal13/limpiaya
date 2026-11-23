# Roadmap · Sprint 3 — lo que queda

**Estado:** 9 nov 2026 · `develop` en `9c8e310` · **4 de 10 historias cerradas** (4 de 11 pts).

| Historia | Pts | Estado | Dónde |
|---|:--:|---|---|
| HU-14 · Ver las postulantes | 1 | ✅ Hecha | develop (PR #37) |
| HU-06 · Perfil público | 1 | ✅ Hecha | develop (PR #41) |
| HU-15 · Elegir a una trabajadora | 1 | ✅ Hecha | develop (PR #38) |
| HU-17 · Marcar completado | 1 | ✅ Hecha | develop (PR #39) · Trello en Pruebas |
| **HU-16 · Próximos y pasados** | 1 | ⛔ Pendiente | Placeholder |
| **HU-28 · Cancelar asignado** | 1 | 🟡 En curso | Otra persona |
| **HU-29 · Calificar trabajadora** | 1 | ⛔ Pendiente | TODO en `mis_solicitudes_screen:105` |
| **HU-30 · Calificar cliente** | ½ | ⛔ Pendiente | — |
| **HU-38 · Chat** | 3 | ⛔ Pendiente | Solo base de datos |
| **HU-52 · Desglose del costo** | ½ | 🟡 2/3 | Falta el detalle |

---

## Lo que ya está y conviene reutilizar

- **Cambios de estado por RPC** (nadie escribe `estado` a mano): `elegir_trabajadora(uuid)`, `completar_servicio(uuid)` y `cancelar_solicitud(uuid, text)` — esta última **solo** para solicitudes Publicadas.
- **Reglas en el dominio**: `ServicioService` (elegir/completar + traducción de errores) y `SolicitudService` (tarifa 10 % y total de HU-52).
- **Vistas**: `solicitudes_publicas` (sin dirección), `trabajadoras_publicas`, `resenas_publicas` y `reputacion`.
- **Tablas listas**: `mensajes` (con RLS y Realtime) y `calificaciones` (`unique (solicitud_id, autor_id)`, `estrellas` 1–5, `motivo` para 1–2 estrellas).
- **Pantallas/patrones**: `dialogo_cancelar_solicitud.dart`, `dialogos_servicio.dart`, `completar_servicio_provider.dart`, `PerfilPublicoScreen`.
- **HU-52**: el desglose ya funciona en publicar/editar; solo falta mostrarlo en el detalle.

---

## Orden recomendado

La ruta crítica es **HU-16**, porque desbloquea HU-28, HU-29, HU-30 y el criterio 3 de HU-52, y además es la puerta de entrada natural al chat.

```
HU-16  ──► HU-28
   │       HU-29 + HU-30
   │       HU-52 (c3)
   └────► HU-38 (pista paralela, 3 pts)
```

---

## 1 · HU-16 · Ver mis servicios próximos y pasados (1 pt)

**Qué falta**

1. **Modelo de datos del servicio agendado.** `Solicitud` no trae dirección ni punto de referencia (vienen de `solicitudes`, que sí es legible para el cliente dueño y para la trabajadora asignada por RLS). Crear `ServicioAgendado` (o un `SolicitudDetalle`) con: contraparte (nombre/foto), zona, horario, pago, estado, dirección y punto de referencia.
2. **Repositorio**: `ServicioRepository.detalle(id)`, leyendo `solicitudes` + `zonas` + `perfiles` de la contraparte. No hace falta vista nueva; si se prefiere, una vista `servicios_agendados` que ya traiga el join.
3. **Provider** `servicioAgendadoProvider(id)` (family, autoDispose).
4. **Pantalla de detalle** en `/trabajadora/servicios/:id`, reemplazando el `TODO(HU-16)` de `app_router.dart:111`. Debe incluir: datos del servicio, dirección, contraparte, botón de chat (deshabilitado hasta HU-38), y las acciones de completar/cancelar.
5. **Pestañas reales** en `mis_servicios_screen.dart`: **Próximos** (Asignadas futuras, orden ascendente) y **Pasados** (Completadas y Canceladas, descendente). Hoy son placeholders.
6. **Entrada desde el cliente**: en `tarjeta_solicitud_cliente.dart` el botón "Ver servicio" muestra un snackbar (`HU-16` pendiente); debe navegar a la ruta.
7. **Tests**: próximos ordenados, pasados ordenados, estado vacío por pestaña, navegación desde ambos roles.

**Cómo se prueba:** datos demo con una asignada futura, una completada y una cancelada; revisar ambas pestañas en los dos roles.

**Riesgo:** es la historia que más bloquea. Si se atrasa, HU-29/30 y HU-52 c3 quedan sin dónde vivir.

---

## 2 · HU-28 · Cancelar un servicio asignado (1 pt) — **En curso, coordinar**

**Qué falta**

1. **RPC** `cancelar_servicio(p_solicitud uuid, p_motivo text)`:
   - solo el cliente dueño **o** la trabajadora asignada, y solo si está `asignada`;
   - motivo **obligatorio**: sin motivo, `raise exception 'Elige un motivo'` y no cambia nada;
   - guarda `cancelada_en`, `cancelada_por`, `motivo_cancelacion` y `cancelacion_tardia` (< 24 h);
   - la postulación aceptada pasa a `solicitud_cancelada`.
   - Alternativa: ampliar `cancelar_solicitud` con un parámetro de estado permitido (menos limpio para auditar).
2. **Repositorio + provider** (`ServicioRepository.cancelar`), reutilizando `ServicioService.traducir`.
3. **Diálogo con motivo obligatorio** (variante del actual `dialogo_cancelar_solicitud`, que hoy lo tiene opcional) y botón "Cancelar servicio" en el detalle y en la tarjeta del cliente.
4. **La otra parte lo ve**: estado Cancelada + motivo en tarjeta/detalle de ambos roles.
5. **Tests**: cancela con motivo, no cancela sin motivo (mensaje exacto), no aparece si está Completada.

**Ojo:** ya está en "En curso" en Trello; antes de escribir código, revisar si hay rama/PR abierto para no duplicar.

---

## 3 · HU-29 + HU-30 · Calificar (1 pt + ½ pt)

Van juntas: es la misma pantalla con el rol cambiado (destinatario = trabajadora o cliente).

**Qué falta**

1. **Entidad `Calificacion`** (estrellas, comentario, autor, destinatario, fecha) y **repositorio**:
   - `crear(solicitudId, destinatarioId, estrellas, comentario, motivo?)`;
   - `miCalificacion(solicitudId)` para el criterio "ya califiqué, la veo y no puedo repetir";
   - la política RLS ya limita a `puede_calificar` y el `unique (solicitud_id, autor_id)` impide duplicados.
2. **Pantalla/diálogo de calificar**: 1–5 estrellas tocables, comentario opcional (≤ 500), botón deshabilitado sin estrellas y mensaje **"Elige de 1 a 5 estrellas"**.
3. **Cliente (HU-29)**: botón "Calificar" en la tarjeta Completada y desde la invitación de HU-17 (hoy `_calificar()` es un snackbar en `mis_solicitudes_screen.dart:105`).
4. **Trabajadora (HU-30)**: la misma acción desde "Pasados" (depende de HU-16) y `motivo` obligatorio cuando pone 1–2 estrellas (columna `motivo`, enum `motivo_calificacion_baja`).
5. **Efecto en el perfil público**: `reputacion` sale de `resenas_publicas`, que **solo publica una reseña a los 7 días o cuando ambas partes calificaron**. Decidir si el criterio "su promedio se actualiza" se cumple con esa regla o si hace falta mostrar "reseña pendiente de publicación". Si no, el criterio parecerá incumplido en la demo.
6. **Tests**: envío válido, sin estrellas, ya calificado, motivo en 1–2 estrellas.

---

## 4 · HU-38 · Chatear con la otra parte (3 pts) — pista paralela

**Lo que ya existe:** tabla `mensajes` (`contenido` 1–500, índice por `solicitud_id + created_at`), RLS de lectura para participantes y de escritura solo si `chat_abierto()` (Asignada, o hasta 7 días tras completar/cancelar), publicación de Realtime y la migración `20261103000000_chat_leidos.sql` con `leido_en` + índice de no leídos (**local, sin subir**).

**Qué falta**

1. **Capa de datos**: entidad `Mensaje`, `ChatRepository` (conversación, enviar, marcar leídos, conteo de no leídos) e implementación Supabase, con `.stream()` para Realtime.
2. **Provider** con envío optimista y validación local (trim, no vacío, ≤ 500).
3. **Pantalla de chat** en `/servicio/:id/chat` (hoy `PantallaEnConstruccion`): burbujas propias/ajenas, **fecha y hora** por mensaje, estado vacío, modo solo lectura cuando el chat cerró, y manejo de "no soy parte" en vez del error crudo de Postgrest.
4. **Lista "Mensajes"** con contraparte, último mensaje y badge de no leídos. Hoy la pestaña del cliente hace `onProximamente('Mensajes')` y la barra de la trabajadora ni la tiene.
5. **Entrada**: botón "Escribir por el chat" en el detalle del servicio (HU-16) y ocultarlo cuando la solicitud está Publicada.
6. **Tests**: envío, límite de 500, no leídos, sin acceso para terceros.

**Riesgo:** 3 pts, la más grande y ya con 4 historias cerradas. Plan B del roadmap original: texto + refresco al abrir, y dejar no leídos para el final.

---

## 5 · HU-52 · Desglose del costo (½ pt) — falta 1 criterio

- c1 y c2 **ya están**: el resumen en publicar/editar muestra "La trabajadora recibe / Tarifa LimpiaYa (10 %) / Total" y se recalcula al cambiar el pago.
- **Falta c3**: el mismo desglose al abrir el detalle de una solicitud Publicada en "Mis solicitudes". Lo natural es ponerlo en `TarjetaSolicitudCliente` o en el detalle de HU-16, reutilizando `SolicitudService.tarifa/total`.
- Tests: los tres montos y el recálculo al editar el pago.

---

## Plan de trabajo sugerido

| Bloque | Contenido | Salida |
|---|---|---|
| 1 | HU-16 (detalle + pestañas + navegación) | Cero `PantallaEnConstruccion` en el flujo del servicio |
| 2 | HU-28 (RPC + diálogo) | Cancelar con motivo visible para ambas partes |
| 3 | HU-29 + HU-30 (pantalla compartida) | Reseñas de punta a punta |
| 4 | HU-52 c3 (cierre corto, se cuela en cualquier bloque) | 3/3 |
| 5 | HU-38 (chat completo) | 4/4 |
| 6 | Pruebas cruzadas y demo | Flujo completo con dos cuentas |

---

## Definición de terminado (igual que en las cerradas)

- `flutter analyze` limpio y `flutter test` en verde.
- Rama → PR a `develop` → check **"Analizar y probar"** → merge.
- Verificación manual en la app con datos demo (no solo tests).
- Trello: criterios marcados con evidencia en un comentario y tarjeta en la lista que corresponda.

---

## Riesgos abiertos

| Riesgo | Señal | Mitigación |
|---|---|---|
| HU-16 frena a cuatro historias | Sigue el placeholder al cerrar el bloque 1 | Hacerla primero y sin adornos |
| Reseñas nuevas no se ven por la regla de 7 días | La demo califica y el perfil no cambia | Decidir visibilidad antes de HU-29 |
| HU-38 se come el sprint | Al terminar el bloque 3 no hay mensaje de punta a punta | Recortar a texto + refresco al abrir |
| Dos personas en HU-28 | Ramas que se pisan | Confirmar dueño antes de empezar |
| Archivos locales sin subir | `chat_leidos.sql` y este roadmap fuera de `develop` | PR de fase 0 aparte |

---

## Pendiente de subir (fuera de las historias cerradas)

- `supabase/migrations/20261103000000_chat_leidos.sql` — base de HU-38.
- `docs/ROADMAP_SPRINT3.md` — este documento.
- `.gitignore` con `env.local.json`.
