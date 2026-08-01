# Ladder — roadmap a producción

Expande la tabla "Fuera de scope" de `SPEC.md` §11. Cada corte ahí fue
deliberado para el MVP de un día — esto dice, para cada uno, qué haría
falta si el proyecto se llevara en serio. No es una promesa de trabajo
futuro, es la respuesta lista para "¿y esto cómo lo llevarías a
producción?".

---

## Auth real

**Hoy:** el selector de lente no tiene contraseña. El cliente manda
`X-Person-Id` en cada request, y `ApplicationController#current_person`
confía en ese header sin verificarlo.

**Para producción:** no es solo "agregar Devise". Significa mover la
identidad al servidor por completo — sesión o JWT firmado, derivado de
un login real (SSO con el proveedor de identidad de la empresa, lo más
probable en un contexto B2B). El punto de confianza deja de ser "lo que
manda el cliente" y pasa a ser "lo que el servidor ya verificó". Cada
controller que hoy hace `current_person` sigue funcionando igual — lo
que cambia es de dónde sale ese valor, no la lógica de visibilidad que
ya existe.

## Deploy real

**Hoy:** no hay deploy — dos servidores en local (`bin/rails s` +
`npm run dev`), tal como dice el `README.md`. El próximo paso planeado
(no este documento) es una demo pública mínima, con Rails sirviendo los
assets de Vite desde un mismo host, para poder mostrarlo sin depender de
correr nada localmente.

**Para producción de verdad, más allá de esa demo:** Postgres en vez de
SQLite (SQLite no tolera bien escrituras concurrentes), secrets vía
credentials cifrados o vault del proveedor (nunca en el repo), backups
automáticos, monitoreo/alerting, y deploys sin downtime. Ninguno de
estos es exótico — es la distancia normal entre "demo pública" y "algo
que una empresa opera".

## CRUD del framework

**Hoy:** el framework se siembra a mano en `db/seeds.rb`. Los 15
criterios son fijos.

**Para producción:** una UI de administración (probablemente solo para
HR) para agregar y editar criterios — pero el diseño no es un CRUD
trivial. Si el texto de un criterio cambia, las evidencias ya
etiquetadas contra la versión vieja no deberían reinterpretarse
retroactivamente — el mismo principio de "congelado al momento de
crearse" que ya aplica a `author_relation` (§4). Eso implica versionar
criterios, no solo editarlos in-place.

## Evals de calidad de la narrativa

**Hoy:** la única validación es estructural — el schema del modelo no
admite nivel/readiness/puntuación, y un `criterion_code` inventado
dispara el fallback (A9). Nadie mide si la narrativa generada es *buena*
— precisa, no alucinada, con el tono correcto.

**Para producción:** un set dorado de pares (payload, narrativa
esperada) y un harness de evals automático que puntúe groundedness
(¿cada frase de la narrativa se puede trazar a una fila real de `met` o
`gap`?) y tono, corriendo en CI antes de aceptar un cambio de prompt o
de proveedor del modelo. `SPEC.md` §11 ya lo nombra como "el siguiente
paso obvio" — sigue siendo el de mayor apalancamiento de toda esta lista.

## Ciclos automáticos, notificaciones

**Hoy:** un botón (o una rake task) cierra el ciclo a mano.

**Para producción:** un job programado (Sidekiq, GoodJob) que cierre
ciclos en fechas fijas del calendario de la empresa, más notificaciones
(email o Slack) a la persona y a su manager cuando el ciclo cierra y la
narrativa queda lista.

## Vista agregada de HR

**Hoy:** no existe ningún endpoint agregado, a propósito — es la
frontera que A13 prueba explícitamente. La razón no es "todavía no",
es "expondría comparación entre personas" (D6).

**Para producción real, si se decide construir esto de todas formas:**
hace falta la tabla intermedia que M4 ya nombra — diseñada para que el
agregado sea sobre *huecos de la organización en un criterio* ("20% del
equipo no tiene RES-3.2 corroborado"), nunca sobre *personas comparadas
entre sí*. La barrera D6 no se relaja para construir esto — se diseña
alrededor de ella desde el modelo de datos hacia arriba.

## Audit log persistente

**Hoy:** no hay histórico de quién vio qué snapshot, cuándo, ni qué
campos le fueron servidos.

**Para producción:** una tabla append-only (`access_logs` o similar)
registrando cada acceso a un snapshot ajeno — quién, cuándo, qué vio.
Esto importa más de lo que parece un detalle de compliance: la promesa
central del producto es visibilidad controlada (§6), y sin audit log esa
promesa no es verificable después del hecho — solo se puede confiar en
que el código de hoy la respeta, no auditar que la respetó ayer.
