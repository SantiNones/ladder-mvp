# Ladder — SPEC

MVP de un bloque de ~4-5 h. Ruby on Rails (API) + React + SQLite.
Las decisiones y sus razones viven en `decisions.md`; este archivo dice
**qué se construye**. Si algo aquí contradice `decisions.md`, gana
`decisions.md` y este archivo se corrige.

**Idioma del producto:** inglés. El framework fuente está en inglés y
traducirlo introduce deriva sobre el texto que es la fuente de verdad
del cálculo.

---

## 1. Qué es

Ladder calcula de forma determinista **qué le falta a una persona para
el siguiente nivel** de un competency framework publicado, a partir de
evidencia registrada, y usa un LLM únicamente para redactar la narrativa
y los próximos pasos sobre un gap que el modelo no calculó.

**Qué no es:** una evaluación de desempeño, un rating, un veredicto de
readiness, ni una herramienta de tracking de actividad.

---

## 1b. Objetivo de aprendizaje, tan real como el producto

Este build tiene dos entregables, no uno. El primero es el MVP en sí. El
segundo, igual de real: que Santiago termine el día sabiendo Rails y
habiendo practicado disciplina de código profesional — dos gaps
reconocidos, no accidentales. Nunca ha trabajado código de forma
colaborativa más allá de un proyecto de bootcamp, y ese es exactamente
el tipo de gap que este ejercicio existe para cerrar.

Esto tiene consecuencias en cómo se construye, no solo en qué se
construye:

- **Cada idioma de Rails que aparece por primera vez se explica en el
  momento**, una frase, no un tutorial (regla ya en `AGENTS.md`). Una
  migration, un `has_many :through`, un service object, una scope — la
  primera vez que aparecen, se nombra qué son y por qué encajan aquí.
- **El flujo de trabajo de git/PR es parte del ejercicio, no un
  accesorio.** Rama, commits, PR, revisión, merge — practicados de
  verdad en este repo, no simulados. El detalle vive en la sección de
  git de `AGENTS.md`.
- **Cuando algo cuesta más de lo esperado — como instalar Ruby por
  primera vez — se cuenta así el lunes, no se pule.** Es parte de la
  evidencia de "we learn and teach", no un defecto que ocultar.

## 2. Usuarios y lentes

Sin auth real. Un selector arriba cambia de lente, como en OpsGuard.

| Lente | Persona | Ve |
|---|---|---|
| Employee | Ana Ferrer | Su propio ladder y su gap |
| Manager | Laura Puig | Su propio ladder + el de sus direct reports |
| HR *(stretch, D10)* | Marta Solé | Lo anterior + la nota de calibración del framework |

---

## 3. Recorrido

1. Se cierra un ciclo para una persona (botón, no cron).
2. El **GapCalculator** lee la evidencia de la ventana y produce, para
   cada criterio del nivel objetivo, uno de tres estados.
3. El resultado se congela en un `Snapshot`.
4. El **VisibilityResolver** decide, para el viewer actual, qué criterios
   y qué evidencia se sirven — antes de construir nada.
5. La **capa AI** recibe solo ese subconjunto y devuelve narrativa +
   próximos pasos, validados contra un schema.
6. La UI muestra el ladder, el gap por competencia, la evidencia, y un
   panel de trazabilidad con el payload exacto que recibió el modelo.

---

## 4. Modelo de datos

Cuatro tablas. `level` y `competency` son campos, no tablas (M2).

### `people`

| campo | tipo | notas |
|---|---|---|
| `id` | integer | |
| `name` | string | |
| `role` | string | enum: `employee`, `manager`, `hr` |
| `manager_id` | integer, null | FK → `people.id`. Auto-referencial |
| `level_position` | integer | **Input humano. El sistema nunca lo escribe (D4)** |

```ruby
belongs_to :manager, class_name: "Person", optional: true
has_many :reports, class_name: "Person", foreign_key: :manager_id
has_many :evidences
has_many :criteria, through: :evidences
has_many :snapshots
```

### `criteria`

| campo | tipo | notas |
|---|---|---|
| `id` | integer | |
| `code` | string, unique | `RES-3.1` |
| `level_position` | integer | 2 o 3 en el seed |
| `competency` | string | enum: `RES`, `DIR`, `TAL`, `CUL`, `CRA` |
| `text` | text | verbatim de la fuente |
| `source` | string | `dropbox-public` (M5) |

### `evidences`

Ojo Rails: el inflector pluraliza `Evidence` → tabla `evidences`.

| campo | tipo | notas |
|---|---|---|
| `id` | integer | |
| `person_id` | integer | sobre quién es la evidencia |
| `criterion_id` | integer | qué criterio pretende cubrir |
| `author_id` | integer | quién la registró |
| `author_relation` | string | enum: `self`, `manager`, `peer`, `hr`. **Congelado al crear** |
| `source_type` | string | enum: `project`, `manager_note`, `peer_feedback`, `training`, `goal`, `self_claim` |
| `body` | text | |
| `occurred_on` | date | |

**`author_relation` es derivable** (comparando `author_id` con
`person_id` y `person.manager_id`), y aun así se guarda. Misma razón que
M3: si Ana cambia de manager, la evidencia vieja no debe reinterpretarse
retroactivamente. Se congela en el momento de crearla.

### `snapshots`

| campo | tipo | notas |
|---|---|---|
| `id` | integer | |
| `person_id` | integer | |
| `cycle_label` | string | `H1 2026` |
| `window_start` / `window_end` | date | ambos **inclusivos** |
| `closed_at` | datetime | |
| `level_position_at_close` | integer | copia congelada |
| `target_level_position` | integer | `level_position_at_close + 1` |
| `met` | json | `[{ criterion_id, evidence_ids: [] }]` (M4) |
| `gap` | json | `[{ criterion_id, state, evidence_ids: [] }]` |
| `narrative` | text, null | |
| `prompt_payload` | json, null | lo que recibió el modelo (L3) |

---

## 5. Reglas deterministas — `GapCalculator`

Servicio puro. Sin IA, sin HTTP, sin sesión. Entrada: `person`,
`window_start`, `window_end`. Salida: `met` y `gap`.

```
target_level    = person.level_position + 1
target_criteria = Criterion.where(level_position: target_level)

para cada criterion en target_criteria:
  relevant      = evidencia de (person, criterion) con
                  window_start <= occurred_on <= window_end
  corroborating = relevant donde author_relation != 'self'

  si corroborating no vacío  -> MET,            evidence_ids = corroborating
  si no, si relevant no vacío -> GAP/uncorroborated, evidence_ids = relevant
  si no                       -> GAP/empty,      evidence_ids = []
```

### Los tres estados

| estado | significado | qué ve la persona |
|---|---|---|
| `met` | hay evidencia de un autor distinto a la propia persona | cubierto |
| `gap` / `uncorroborated` | solo hay self-claim (D5) | "lo reclamaste, falta que alguien lo confirme" |
| `gap` / `empty` | no hay evidencia | pendiente |

El tercer estado existe porque *"no hay nada"* y *"reclamado sin
corroborar"* piden acciones distintas.

### Bordes, explícitos

Aquí es donde viven los boundary bugs. Cada uno tiene su test (§9).

- Evidencia exactamente en `window_start` o `window_end`: **cuenta**.
  Ambos extremos inclusivos.
- Persona sin nivel siguiente en el framework: `target_criteria` vacío →
  snapshot válido con `met: []` y `gap: []`, más un flag
  `at_top_of_framework`. **No es una excepción.**
- Persona sin manager: permitido (`manager_id` nulo).
- Varias evidencias sobre el mismo criterio: cuenta una vez como `met`,
  y `evidence_ids` las lista todas.
- Evidencia cuyo autor pasó a ser manager después: `author_relation`
  sigue siendo el del momento de creación.

---

## 6. Matriz de visibilidad — `VisibilityResolver`

Corre **antes** de cargar o serializar nada.

### Acceso al snapshot

| Viewer respecto al sujeto | Resultado |
|---|---|
| Es la propia persona | Acceso |
| Es su manager directo | Acceso |
| Es HR *(stretch)* | Acceso |
| Cualquier otro caso | **404, no 403** |

404 y no 403 a propósito: un 403 confirma que ese snapshot existe.

### Campos

| Campo | Employee (self) | Manager (de su report) | HR *(stretch)* |
|---|---|---|---|
| Lista de gap y estados | ✅ | ✅ | ✅ |
| Texto de la evidencia | ✅ | ✅ | ✅ |
| Autor de evidencia `manager` / `hr` | ✅ | ✅ | ✅ |
| Autor de evidencia `peer` | ❌ anonimizado | ❌ anonimizado | ❌ anonimizado |
| Nota de calibración | ❌ | ❌ | ✅ |
| Cualquier dato de un tercero | ❌ | ❌ | ❌ |
| Comparación con pares | ❌ **no existe** | ❌ **no existe** | ❌ **no existe** |

La autoría de peer se elimina **para todos**, incluido HR: el valor de
un feedback de par depende de que quien lo escribe no tema represalia.
La comparación entre pares no es un permiso denegado — no existe endpoint
que la sirva (D6).

---

## 7. Contrato de la capa AI

### Lo que recibe el modelo

Exactamente esto, construido a partir del set ya filtrado. Se guarda tal
cual en `snapshot.prompt_payload`.

```json
{
  "subject_first_name": "Ana",
  "cycle_label": "H1 2026",
  "target_level_name": "IC3 Software Engineer",
  "met": [
    { "code": "RES-3.1", "competency": "RES", "text": "...",
      "evidence": [
        { "source_type": "project", "author_relation": "manager",
          "body": "..." }
      ] }
  ],
  "gap": [
    { "code": "DIR-3.1", "competency": "DIR", "text": "...",
      "state": "empty" }
  ]
}
```

**No contiene:** el nivel actual de la persona, nombres de autores, IDs
internos, ni dato alguno de otra persona.

### Lo que puede devolver

```json
{
  "summary": "string, máximo 3 frases",
  "focus_competency": "RES | DIR | TAL | CUL | CRA",
  "next_steps": [ { "criterion_code": "string", "suggestion": "string" } ]
}
```

**El schema no tiene campo de nivel, de readiness ni de puntuación.** No
es un filtro sobre la salida: el modelo no tiene dónde escribirlo (S2).

### Validación al recibir

1. Todo `criterion_code` de `next_steps` debe existir en el `gap` del
   payload. Si no → rechazar.
2. `focus_competency` debe ser uno de los cinco. Si no → rechazar.
3. JSON inválido, timeout o error de red → rechazar.

**Al rechazar:** narrativa determinista de fallback, construida desde el
gap con una plantilla. La app nunca se queda sin narrativa, y nunca
muestra output no validado.

---

## 8. Pantallas

1. **Barra de lente** — selector de persona/rol.
2. **My ladder** (employee) — nivel actual, nivel objetivo, criterios
   agrupados por competencia con su chip de estado, evidencia
   desplegable por criterio.
3. **Progress** — barras de criterios cubiertos por competencia, y
   evolución entre ciclos (el seed trae dos ciclos para Ana, así que hay
   dos puntos reales).
4. **My team** (manager) — lista de direct reports con `cubiertos/total`
   y enlace al ladder de cada uno. **Sin ranking ni orden por
   puntuación**; orden alfabético.
5. **Trace panel** — botón *"See what the model received"*, que muestra
   `prompt_payload` en crudo.

---

## 9. Criterios de aceptación

Cada uno es un test. La columna enlaza con los riesgos de `decisions.md`.

| # | Criterio | Riesgo |
|---|---|---|
| A1 | Con el seed de Ana H1 2026: 5 met, 5 gap | — |
| A2 | `CRA-3.2` sale `gap/uncorroborated`, no `met`, teniendo evidencia | S8 |
| A3 | Añadir una evidencia `peer` sobre `CRA-3.2` lo pasa a `met` | S8 |
| A4 | Evidencia en `occurred_on == window_start` cuenta; un día antes no | — |
| A5 | Persona en el nivel más alto → snapshot con `at_top_of_framework`, sin excepción | — |
| A6 | Ningún code path escribe `level_position` fuera del endpoint manual | S1 |
| A7 | El schema de salida del modelo no admite campo de nivel ni de veredicto | S2 |
| A8 | `prompt_payload` no contiene ningún `criterion_id` fuera del set visible | S3 |
| A9 | Un `criterion_code` inventado en `next_steps` dispara el fallback | S4 |
| A10 | El JSON servido no contiene `author_id` ni nombre para evidencia `peer` | S7 |
| A11 | Laura pidiendo el snapshot de Diego (no es su report) → **404** | S6 |
| A12 | Ana pidiendo el snapshot de Carlos → **404** | S6 |
| A13 | Ningún endpoint devuelve agregados ni comparativas entre personas | S6 |
| A14 | Con la API del modelo caída, la app sirve la narrativa de fallback | — |

Tests con **Minitest**, el default de Rails. Razón: cero configuración,
y lo que se demuestra es la frontera, no el framework de testing.

---

## 10. Plan de sprints

Regla de cada sprint: enunciar goal, scope y validación antes de
implementar; revisar el diff al terminar y **señalar al menos una cosa**
que cuestionar o cambiar, aunque sea pequeña.

| # | Sprint | Tiempo | Sale con | PR |
|---|---|---|---|---|
| S0 | `rails new --api`, Vite+React, migraciones, seed | 20 min | `rails db:seed` corre y los datos están | `sprint/s0-scaffold` |
| S1 | `GapCalculator` + tests A1-A5 | 60 min | El cálculo correcto, sin UI todavía | `sprint/s1-s2-core` |
| S2 | `VisibilityResolver`, serializers + tests A8, A10-A13 | 50 min | La API no filtra nada de más | ↑ mismo PR que S1 |
| S3 | React: My ladder + My team | 60 min | Se navega y se ve el gap | `sprint/s3-ui` |
| S4 | Capa AI, validación, fallback, trace panel + A7, A9, A14 | 40 min | La frontera es visible en pantalla | `sprint/s4-s5-ai-polish` |
| S5 | Gráfico de progreso y pulido | 30 min | Los dos ciclos se ven | ↑ mismo PR que S4 |
| S6 | *Stretch:* lente HR + nota de calibración (D10) | 35 min | Solo si S0-S5 van en hora | `sprint/s6-hr-stretch` |

Núcleo ≈ 4 h 20. **El orden no es negociable: el determinista primero,
la IA en el penúltimo sprint.** Si se acaba el tiempo, lo que falta es
el gráfico y el stretch — nunca los tests de la frontera.

**S1 y S2 comparten un PR a propósito:** es el núcleo determinista, el
corazón de la historia de seguridad del producto (§5, §6), y tiene más
sentido revisado como una sola unidad que partido en dos. Mismo criterio
para S4+S5. El flujo de rama/commit/PR/review/merge está en la sección
de git de `AGENTS.md` — es tan parte del ejercicio como el código
mismo (§1b).

---

## 11. Fuera de scope

| Fuera | Razón |
|---|---|
| Auth real | Selector de lente. La decisión que se demuestra es de visibilidad, no de autenticación |
| Deploy | Se enseña en local |
| CRUD del framework | Se siembra. El catálogo no enseña nada de la frontera |
| Evals de calidad de la narrativa | Por tiempo. Es el siguiente paso obvio y se nombra como tal |
| Ciclos automáticos, notificaciones | Un botón cierra el ciclo |
| Vista agregada de HR ("hueco en el catálogo de formación") | Es la idea de roadmap, no del día. Exigiría además la tabla intermedia de M4 |
| Audit log persistente | Un prototipo no lo necesita; producción sí. Se nombra en las limitaciones |

---

## 12. Seed

**Framework:** Dropbox Engineering Career Framework, publicado en
`dropbox.github.io/dbx-career-framework`. Atribución en el README y en
`source` de cada criterio (D3b, M5).

**Niveles:** IC2 (position 2), IC3 (position 3).
**Competencias:** los cinco pilares — RES, DIR, TAL, CUL, CRA.
**Criterios:** 5 en IC2 (uno por pilar), 10 en IC3 (dos por pilar).

**Personas:**

| nombre | role | level | manager_id | para qué está |
|---|---|---|---|---|
| Laura Puig | manager | 3 | `nil` | la lente de manager |
| Ana Ferrer | employee | 2 | Laura | el sujeto del demo |
| Carlos Medina | employee | 2 | Laura | segundo report + autor `peer` |
| Diego Rams | employee | 2 | `nil` | **no es report de Laura** — existe solo para A11 |
| Marta Solé | hr | 3 | `nil` | autora de evidencia; lente solo en el stretch |

Dos detalles buscados, no accidentes:

- **Diego no tiene manager en el seed.** Basta con que no sea report de
  Laura; añadir un sexto manager solo para él no aporta nada.
- **Laura está en el nivel más alto sembrado (IC3), así que su propio
  ladder dispara `at_top_of_framework`.** Eso es deliberado: el caso
  borde de A5 queda ejercitado por datos reales de la demo, no solo por
  un test sintético.

**Ciclos de Ana:** dos. `H2 2025` con 2 criterios cubiertos y `H1 2026`
con 5, para que el gráfico de progreso tenga dos puntos reales.

**Evidencia de `H1 2026`:** 6 entradas — cinco corroboradas
(RES-3.1, RES-3.2, CRA-3.1, TAL-3.2, CUL-3.2) y un self-claim sobre
CRA-3.2 que deliberadamente **no** cubre.

**Forma del resultado:** RES 2/2 · DIR **0/2** · TAL 1/2 · CUL 1/2 ·
CRA 1/2 + 1 uncorroborated. El gap está concentrado en Direction a
propósito: así el gráfico dice algo y la narrativa tiene material real.
