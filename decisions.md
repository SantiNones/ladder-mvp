# Ladder — Decisions Log

Proyecto: MVP/POC de un día, Ruby on Rails + React + SQLite.
Contexto: preparación para la Final Coffee Chat con Adrià Carro Fàbregas
(Director / Senior Engineering Manager, Operations Domain, Factorial),
lunes 2026-08-03.

Este archivo registra **decisiones tomadas y por qué**, no el diseño en
sí (eso vive en `SPEC.md`). Si una decisión se revierte, se tacha y se
añade la nueva debajo con fecha — no se borra. El historial es parte del
argumento.

**Encuadre honesto para el lunes:** esto es un día de estudio con límite
de tiempo, no un producto. Se cuenta como lo que fue.

---

## El producto en una línea

Ladder calcula, de forma determinista y auditable, **qué le falta a una
persona para el siguiente nivel** de un competency framework, a partir
de evidencia registrada; y usa un LLM únicamente para redactar la
narrativa y los próximos pasos sobre un gap que el modelo no calculó.

Lo que **no** es: una evaluación de desempeño, un rating, un veredicto
de readiness, ni una herramienta de tracking de actividad.

---

## D1 — El hub es un ciclo cerrado, no una petición

**Fecha:** 2026-07-31

**Decisión:** la entidad central es un `Snapshot` (persona × ciclo),
creado al cerrar el ciclo. El sistema no espera que nadie pregunte nada.

**Por qué:** el proyecto anterior (OpsGuard) ya cubre la forma reactiva
— hub = request entrante, resolver determinista, capa de explicación.
Repetir esa forma con otro sub-dominio habría producido OpsGuard v2.
Cambiar el hub cambia el producto de verdad; cambiar el sub-dominio solo
cambia el catálogo.

**Alternativas descartadas:**

- *Hub = transición de nivel* ("Ana pasa de Junior a Mid"): buen
  producto, pero ocurre una vez al año — casi no hay nada que enseñar en
  la UI, y el mecanismo de decisión salía arbitrario.
- *Hub = período de time-tracking con rachas de cumplimiento*:
  descartado por D2.

---

## D2 — Nada de tracking de cumplimiento ni de actividad

**Fecha:** 2026-07-31

**Decisión:** el producto no mide consistencia de fichaje, horas de uso,
ni ninguna métrica de actividad. Las fuentes de evidencia son de
crecimiento: objetivos cerrados, formaciones completadas, proyectos
entregados, feedback recibido, mentoría dada.

**Por qué:** una capa de gamificación sobre cumplimiento operativo es
vigilancia con gráficas bonitas. Criterio explícito de Santiago: no
construir software que oprima ni que haga el día a día más estresante.
Además coincide con el marco legal — "monitoring or evaluating workers'
performance or behaviour" es categoría de alto riesgo bajo el Anexo III
(ver L1).

**Nota de origen:** la mecánica de progresión viene de RISE (habit
tracker con XP, niveles y leaderboard). Lo que se reutiliza es la
progresión contra un estándar; lo que se descarta a propósito es la
comparación entre personas (ver D6).

---

## D3 — El estándar de referencia es un competency framework publicado

**Fecha:** 2026-07-31

**Decisión:** el mecanismo de decisión se ancla en un competency
framework publicado, no en reglas inventadas para el demo.

**Por qué:** era la objeción principal contra este hub — que el criterio
de "¿está listo?" saliera arbitrario. Un framework publicado convierte
la regla en lectura de un estándar, no en opinión del sistema.

### ~~D3a — Sembrar con el framework de ingeniería de Factorial~~ (revertida)

~~Se siembra con el framework de Factorial (niveles tipo AI Engineer,
ejes Skill / Engagement), lo que además demuestra que se leyeron sus
documentos.~~

**Revertida el 2026-07-31, por Santiago.** El documento de career path
llegó por un canal interno y no hay certeza de que sea material público.
No se usa.

### D3b — Sembrar con el Dropbox Engineering Career Framework

**Fecha:** 2026-07-31 (sustituye a D3a)

**Decisión:** el seed usa el Dropbox Engineering Career Framework,
publicado por Dropbox en GitHub Pages y recogido en progression.fyi
(directorio de frameworks compartidos públicamente a propósito).
Niveles: **IC2 → IC3 Software Engineer**. Competencias: sus cinco
pilares — Results, Direction, Talent, Culture, Craft.

**Por qué este:** procedencia pública verificable, estructura
nivel × pilar × comportamiento que encaja exacto con el modelo de datos,
y — a diferencia de la opción anterior — **las competencias también son
suyas**, así que no queda ninguna parte del framework inventada por
nosotros.

**Postura de atribución:** el seed y el README citan y enlazan la
fuente. Es un demo local, no comercial. No se ha verificado una licencia
de reutilización específica, así que la postura es atribución explícita
y nada de presentarlo como propio.

**Efecto secundario en el discurso, y es el bueno:** el motivo del
cambio es mejor material que el framework en sí. Empezar a sembrar con
un documento recibido, parar al no poder confirmar que fuera público, y
cambiar a uno publicado — en un producto de IA, donde el seed acaba
siendo el contexto del modelo, la **procedencia de los datos es una
decisión de diseño, no un trámite**. De ahí sale la columna `source` en
`Criterion` (ver M5).

---

## M5 — `Criterion.source` registra la procedencia en el esquema

**Fecha:** 2026-07-31

**Decisión:** `Criterion` lleva una columna `source` con el origen de
cada criterio (`dropbox-public` en todo el seed actual).

**Por qué:** que la procedencia viva en los datos y no en una nota al
pie. Si algún día entra un criterio propio de la empresa, o uno
derivado, el esquema ya distingue. Es la versión barata de data lineage,
y encaja con el panel de trazabilidad de L3.

---

## D4 — El nivel actual es un input humano, nunca un output del sistema

**Fecha:** 2026-07-31

**Decisión:** `Person.level_position` es un campo que edita una persona.
*(Nombrado `current_level` en la redacción original de esta decisión;
`level_position` es el nombre final, fijado en `SPEC.md` §4. Mismo
campo, un solo cambio de nombre — detectado por el agente en Cursor al
planear S0, 2026-07-31.)*
El sistema jamás lo deriva, lo propone ni lo modifica.

**Por qué:** es la propiedad de seguridad central del producto, y está
expresada en el esquema de datos, no en una política escrita. Si el
nivel fuera derivado ("todos los criterios cubiertos ⇒ subir de nivel"),
el sistema estaría tomando una decisión de promoción — exactamente el
caso de alto riesgo del Anexo III (L1). Al ser input, es
estructuralmente imposible.

**Consecuencia deseada:** el output del sistema es un *gap*, no un
veredicto.

---

## D5 — Un self-claim, por sí solo, nunca cubre un criterio

**Fecha:** 2026-07-31

**Decisión:** para que un criterio cuente como cubierto necesita al
menos una evidencia cuyo autor no sea la propia persona.

**Por qué:** dos razones, y las dos son defendibles en voz alta. Primera,
producto: el problema original es que quien pregunta más crece más
rápido; si el auto-reporte contara solo, se amplifica ese mismo sesgo.
Segunda, técnica: le da al resolver determinista una regla **con
criterio**, no solo aritmética de conjuntos — que era el riesgo de que
el proyecto oliera a CRUD.

---

## D6 — Sin comparación entre personas, por diseño

**Fecha:** 2026-07-31

**Decisión:** nadie ve el nivel, el gap ni el progreso de sus
compañeros. No hay ranking, ni percentil, ni "vas por encima de la
media". La única comparación disponible es contra el framework y contra
tus propios ciclos anteriores.

**Por qué:** en RISE el leaderboard era correcto — gente adulta
compitiendo voluntariamente en algo suyo. En una herramienta de
crecimiento profesional, donde no se elige participar, la comparación
entre pares produce ansiedad, no desarrollo. No es un permiso olvidado:
es una decisión de producto, y el modelo de datos no la soporta ni
accidentalmente.

---

## D7 — El output se llama "development gap", nunca "evaluación"

**Fecha:** 2026-07-31

**Decisión:** vocabulario fijo en UI, código y documentación: *gap*,
*criterio*, *evidencia*, *próximos pasos*. Prohibidos: *evaluación*,
*rating*, *score*, *nota*, *readiness*.

**Por qué:** Factorial ya tiene un módulo llamado *Evaluación del
desempeño*, y One ya co-crea evaluaciones. Usar su vocabulario invita
la comparación que menos conviene y sugiere que se propone reemplazar
algo suyo. Un nombre distinto es la forma más barata de no pisarlos.

---

## D8 — Diferenciación explícita frente a Factorial One

**Fecha:** 2026-07-31

**Contexto:** One promete (1) respuestas basadas en permisos, (2)
conclusiones ancladas en datos de la empresa, (3) co-creación de
encuestas, informes y evaluaciones. El movimiento estrella de OpsGuard
—permisos antes de cargar datos— ya es un bullet de marketing suyo.

**Decisión:** no presentar Ladder como algo que a Factorial le falta.
Presentarlo por su diferencia de forma:

1. **One es preguntado; Ladder no.** One es RAG conversacional
   horizontal. Ladder no tiene input de usuario en el camino crítico.
2. **Filtrar el retrieval ≠ decidir en código.** One acota lo que el
   modelo puede ver. Ladder decide el resultado en código determinista y
   deja al modelo solo la redacción. Son garantías de naturaleza
   distinta.
3. **Ladder es la junta, no el módulo.** Desempeño, Formación y OKR
   existen por separado; el recorrido "en qué nivel estoy → qué me falta
   → qué formación lo cierra" no es módulo de nadie.

---

## D9 — Si el humano decide, el humano tiene que poder auditar

**Fecha:** 2026-07-31 (planteado por Santiago)

**Decisión:** el manager puede ver, para cada criterio de su report, si
está cubierto y **qué evidencia concreta lo cubrió**, congelada en el
snapshot.

**Por qué:** el D4 saca al sistema de la decisión de nivel y se la deja
al manager. Esa decisión solo es legítima si quien decide puede ver la
base sobre la que decide — si no, el human-in-the-loop es decorativo, no
una garantía. Es el complemento necesario de D4, no una feature aparte.

**Consecuencia técnica:** obliga a que el JSON del snapshot guarde
`evidence_ids` por criterio, no solo `criterion_id` (ver M4).

**Línea para el lunes:** "saqué a la IA de la decisión y se la devolví
al manager; pero devolver la decisión sin devolver la evidencia es
teatro, así que el snapshot congela ambas cosas."

---

## D10 — Tercera lente (HR) como stretch con criterio de corte

**Fecha:** 2026-07-31

**Decisión:** la vista de HR queda fuera del scope base y entra solo si
los tres primeros sprints terminan en hora. Contenido: una **nota de
calibración del framework** visible solo para HR.

**Qué es calibrar:** en empresas reales, los managers se reúnen antes de
cerrar decisiones para comparar cómo están aplicando el framework, de
modo que un manager blando y uno duro no produzcan resultados injustos
entre equipos.

**Matiz importante:** la calibración clásica es sobre *ratings*, y aquí
no hay ratings (D7). La versión compatible es calibrar **la aplicación
del framework**, no a las personas: notas sobre criterios, no sobre
gente. Ej: *"este equipo está aplicando SK-03 más flojo que el resto."*

**Por qué es el caso de visibilidad más rico:** es el único campo con
tres respuestas distintas en vez de dos. Empleado: nunca. Manager: solo
lo suyo. HR: todo. Los demás campos son binarios.

**Coste estimado:** 30-45 min con tests.

**Si no entra:** se corta y se cuenta. Haber scopeado y cortado con
razón es mejor material que haber llegado con todo hecho.

**Idea derivada, fuera de scope y explícitamente para conversación, no
para hoy:** HR viendo el agregado — *"SK-03 es gap para el 80% del
equipo ⇒ el catálogo de formación tiene un hueco"*. Es la junta entre
Desempeño, Formación y OKR otra vez, y es lo que exigiría la tabla
intermedia de M4.

---

## D11 — Tres estados, no dos

**Fecha:** 2026-07-31

**Decisión:** un criterio del nivel objetivo puede estar en tres
estados, no en dos: `met`, `gap/uncorroborated` (solo hay self-claim), y
`gap/empty` (no hay nada).

**Por qué:** salió solo al construir el seed. La regla D5 dejaba a
CRA-3.2 en gap **teniendo evidencia**, y colapsarlo con "no hay nada"
perdía información accionable: no es lo mismo *"nadie sabe que hiciste
esto"* que *"lo dijiste tú y falta que alguien lo confirme"*. Piden
acciones distintas.

**Beneficio lateral:** convierte la regla D5 en algo visible en la UI en
vez de enterrado en un test. La restricción se demuestra sola.

**Coste:** una etiqueta calculada. Cero estructura nueva.

---

## D12 — Flujo de git/PR real, no simulado

**Fecha:** 2026-07-31

**Decisión:** el repo se trabaja con rama por bloque de trabajo, commits
pequeños en Conventional Commits, PR real en GitHub por bloque, revisión
explícita antes de mergear, squash merge. Nunca commits directos a
`main`.

**Por qué:** Santiago nunca ha trabajado código de forma colaborativa
más allá de un proyecto de bootcamp — es un gap real, no cosmético, y
este build es la oportunidad de cerrarlo con repetición de verdad, no
con una simulación. Es tan objetivo del día como el propio MVP (ver
`SPEC.md` §1b).

**Granularidad decidida:** agrupado en 4-5 PRs por bloque de trabajo
(`s0-scaffold`, `s1-s2-core`, `s3-ui`, `s4-s5-ai-polish`,
`s6-hr-stretch`), no uno por cada uno de los 7 sprints.

**Alternativa descartada:** un PR por sprint. Más fiel a equipos con
sprints muy chicos, pero añade ~30-40 min de ceremonia repetida sobre un
día ya ajustado por el tiempo que tomó instalar Ruby por primera vez.
Agrupado sigue ejercitando el hábito real (abrir PR, revisar diff,
exigirse encontrar algo que cuestionar, mergear) sin comerse el tiempo
de construir.

**Por qué S1+S2 y S4+S5 comparten PR y no S0/S3/S6:** S1+S2 es el
núcleo determinista — el corazón de la historia de seguridad del
producto — y tiene más sentido revisado como una unidad. Mismo criterio
para S4+S5 (capa IA + su expresión visual). S0, S3 y S6 ya son unidades
naturales por sí solos.

---

## D13 — Trunk-based, no git-flow

**Fecha:** 2026-07-31

**Decisión:** `main` es la rama protegida y todo entra por PR revisado
desde ramas cortas (`sprint/*`). No hay rama `dev` intermedia.

**Por qué:** git-flow (con `dev` como capa de integración antes de
`main`) resuelve un problema que este proyecto no tiene: varias
personas en paralelo, un ambiente de producción real que no se puede
romper, y ciclos de release programados. Ladder es de una sola persona,
sin deploy (§11), sin nadie más cuyo trabajo pueda chocar en una rama
compartida. Añadir `dev` sería ceremonia sin riesgo real que esté
mitigando.

**Cuándo cambiaría:** el día que exista un ambiente de producción real,
más de una persona contribuyendo, y se quiera una zona de staging antes
de soltar algo a usuarios — ninguna de esas tres se da hoy.

---

## D14 — El panel de trazabilidad sirve el payload guardado, no uno recalculado

**Fecha:** 2026-07-31 (flaggeado por el agente construyendo S2)

**Contexto:** en S2, `GET /snapshots/:id` construye `prompt_payload` de
nuevo en cada request, a partir del set visible actual — correcto por
ahora, porque todavía no existe ninguna narrativa ni nada persistido.

**Decisión:** cuando S4 añada `NarrativeGenerator` y persista
`snapshot.prompt_payload` al cerrar el ciclo, el endpoint debe servir
**la columna guardada** para cualquier snapshot ya cerrado — nunca
recalcularla. Recalcular en vivo solo aplicaría a una previsualización
de un ciclo todavía abierto, si eso llega a construirse.

**Por qué:** el panel de trazabilidad existe para probar qué vio el
modelo de verdad. Si se recalculara en vivo, el contenido podría
derivar del original con el tiempo — si se edita o borra evidencia
después de cerrado el ciclo, el panel mostraría algo distinto a lo que
el modelo realmente recibió, rompiendo la garantía central de L3.

**Cuándo aplica:** S4. Registrado ahora para que no se improvise
distinto bajo presión de tiempo.

---

## D15 — S4 corre en modo determinístico, no LLM real

**Fecha:** 2026-07-31 (decidido por Santiago)

**Decisión:** la narrativa de S4 se genera con una plantilla
determinística, no con una llamada real a un LLM — aunque había una
API key de OpenAI disponible y no era el obstáculo.

**Por qué:** la pregunta que abrió esta decisión fue la correcta —
¿una conexión real mejora el producto, o solo demuestra que se puede
conectar un LLM? La parte difícil del proyecto (qué puede y qué no
puede decidir una IA) ya está 100% construida y probada sin que ningún
modelo real haya corrido — `GapCalculator`, `VisibilityResolver`, y el
schema de salida sin campo de nivel/veredicto no cambian en nada según
el modo. Lo que un LLM real añadiría — prosa más natural, prueba de
integración con una API — es una habilidad que OpsGuard ya demostró
(su propio modo "AI-assisted" con GPT-4o-mini y fallback seguro);
repetirla acá no es señal nueva.

Además, los tests A9 (criterio inventado → fallback) y A14 (API caída
→ fallback) se prueban con más rigor simulando la entrada mala a
propósito que esperando que un modelo real falle justo a tiempo para
demostrarlo — es la práctica estándar incluso en equipos que sí usan
LLMs en producción.

**Riesgo evitado:** una llave nueva que resguardar, una dependencia de
red frágil en medio de una demo en vivo el lunes, y tiempo de S5/S6
gastado en integración en vez de en la frontera misma.

**Puerta abierta, barata:** cambiar la plantilla por una llamada real a
OpenAI más adelante es un cambio pequeño — el contrato y la validación
ya están completos sin importar el modo, mismo patrón del toggle
`USE_AI` de OpsGuard.

---

## D16 — Dónde una IA real sí añadiría valor (fuera de scope, para la conversación)

**Fecha:** 2026-07-31 (explorado por Santiago, no construido hoy)

**Contexto:** tras D15, vale la pena distinguir "narrar una decisión ya
tomada" (bajo riesgo, bajo valor único) de un punto medio real: la IA
haciendo trabajo cognitivo que un humano haría a mano, sobre datos que
siguen pasando por el mismo filtro de visibilidad, siempre como
sugerencia que un humano confirma — nunca aplicada sola.

**Cuatro ideas concretas, ninguna construida en este MVP:**

1. **Etiquetar evidencia libre contra los 15 criterios.** Hoy alguien
   decide a mano a qué criterio pertenece una nota. Un LLM podría leer
   texto libre y sugerir el match ("esto suena a RES-3.2"); el manager
   confirma o corrige. La IA nunca escribe `criterion_id` sola.
2. **Detectar patrones entre varios reports de un mismo manager.** Si
   varios reports comparten el mismo hueco, señalarlo como posible
   necesidad de equipo, no solo individual — el mismo pitch que
   Factorial hace de su propio "One" ("detecta patrones... para
   decisiones basadas en datos"), aplicado a este dominio. Emparentado
   con la vista agregada de HR que ya quedó fuera de scope en D10.
3. **Un chatbot conversacional sobre el payload ya filtrado** — mismo
   patrón que "One" (RAG con permisos), pero conversacional en vez de
   proactivo. Complementaría a Ladder, no lo reemplazaría — sigue
   atado al mismo `VisibilityResolver` y al mismo schema sin campo de
   veredicto.
4. **Personalizar `next_steps` usando también la evidencia ya
   cubierta**, no solo el hueco — una sugerencia como "ya destrabaste
   a tu equipo en el incidente de pagos (RES-3.2); un paso natural en
   DIR-3.1 sería buscar una situación ambigua parecida" es síntesis
   real, no una plantilla con el nombre del criterio pegado.

**Por qué ninguna se construye hoy:** el tiempo restante del bloque no
alcanza, y ninguna es necesaria para demostrar la frontera AI/
determinista — que es lo que este MVP existe para probar. Quedan
documentadas para no tener que improvisar la respuesta si el tema sale
en la conversación del lunes.

### L1 — EU AI Act, Anexo III punto 4

Los sistemas de IA usados en empleo y gestión de trabajadores son de
**alto riesgo** cuando se destinan a: decisiones de promoción o
terminación, asignación de tareas basada en comportamiento o rasgos
personales, y **monitorización o evaluación del rendimiento o la
conducta** de trabajadores.

Ladder está deliberadamente diseñado para quedar **fuera** de esa
categoría: no decide promociones (D4), no evalúa rendimiento (D7), no
monitoriza conducta (D2). El LLM no toca ninguna de las tres.

### L2 — Digital Omnibus on AI: el plazo se movió, el diseño no

Aprobado por el Parlamento Europeo el 16 de junio de 2026 y por el
Consejo el 29 de junio de 2026, en vigor desde julio de 2026.

- Obligaciones de alto riesgo para sistemas autónomos de **Anexo III**:
  aplazadas al **2 de diciembre de 2027**.
- Sistemas de Anexo I embebidos en productos regulados: **2 de agosto de
  2028**.
- La mayoría de las obligaciones de **transparencia del Artículo 50**
  siguen aplicando desde el **2 de agosto de 2026**. Las de watermarking
  del Art. 50(2) pasan al 2 de diciembre de 2026.
- Sanciones bajo el Art. 99: hasta 15 M€ o el 3 % de la facturación
  global.

**Lectura para el proyecto:** el aplazamiento mueve la fecha límite, no
el diseño. Cualquier producto de talent AI que se empiece hoy se está
construyendo para diciembre de 2027, y le conviene nacer con la frontera
puesta en vez de retrofitearla.

### L3 — Transparencia (Art. 50) como feature, no como disclaimer

Ladder incluye un panel de trazabilidad: un botón que muestra el
**payload exacto enviado al modelo**. Se ve, sin explicación verbal, que
contiene solo criterios que el resolver de visibilidad declaró visibles,
y que el nivel no está en el input.

Esto convierte la obligación de transparencia en algo demostrable en
cinco segundos, en lugar de una nota al pie.

---

## Safety concerns y cómo se mitigan

| # | Riesgo | Mitigación | Verificable por |
|---|---|---|---|
| S1 | El sistema acaba decidiendo promociones | `level_position` es input humano, nunca derivado (D4) | Test: ningún code path escribe `level_position` fuera del endpoint de edición manual |
| S2 | El LLM emite un veredicto de readiness | El schema de respuesta del modelo **no tiene campo de nivel ni de veredicto**. No es un filtro, es imposibilidad estructural | Test de contrato sobre el schema de salida |
| S3 | El LLM ve evidencia que el viewer no puede ver | El resolver de visibilidad corre **antes** de construir el prompt; el payload se arma solo con el set visible | Test: `prompt_payload` no contiene ningún `criterion_id` fuera del set visible para ese viewer |
| S4 | El LLM inventa criterios o evidencia | Salida estructurada y validada; toda afirmación referencia un `criterion_code` del payload | Test: todo código citado en la narrativa existe en el payload |
| S5 | Deriva hacia vigilancia | Ninguna fuente de evidencia es de actividad o presencia (D2) | Revisión del enum `source_type` |
| S6 | Comparación entre pares se cuela por una feature futura | El modelo de datos no expone datos de pares a ningún viewer (D6) | Test de visibilidad con un tercero no relacionado |
| S7 | Feedback de pares desanonimizado | La autoría de evidencia con `author_relation: peer` se elimina en el resolver, antes de serializar | Test: el JSON servido no contiene `author_id` para evidencia de pares |
| S8 | Sesgo por auto-reporte | Un self-claim solo nunca cubre un criterio (D5) | Test de la regla de elegibilidad |

**Límite honesto del prototipo:** sin auth real, sin deploy, datos
ficticios, sin audit log persistente, sin evals sobre la calidad de la
narrativa. Un sistema de producción en este dominio necesitaría al menos
audit trail inmutable, notificación a la persona trabajadora de que hay
un sistema de IA implicado, y revisión de impacto discriminatorio.

---

## Decisiones de modelado

### M1 — Cuatro entidades: `Person`, `Criterion`, `Evidence`, `Snapshot`

Aplicando el test de la doble pregunta solo sobre pares conectados por
un verbo real:

- **Person ↔ Criterion** — ¿una persona evidencia muchos criterios? Sí.
  ¿un criterio lo evidencian muchas personas? Sí. → **doble sí ⇒ fila
  intermedia**: `Evidence`, con datos propios (fecha, autor, tipo,
  texto). No es tabla puente vacía.
- **Person ↔ Snapshot** — ¿una persona tiene muchos snapshots? Sí (uno
  por ciclo). ¿un snapshot pertenece a varias personas? No. → uno a
  muchos, FK en `Snapshot`.
- **Manager ↔ Report** (`Person` consigo misma) — para esta manager
  (Laura), ¿puede haber más de un report? Sí: Ana, Carlos, Diego. Para
  este report (Ana), ¿puede haber más de un manager? En el MVP no. → un
  solo sí ⇒ uno a muchos, con la FK en el lado "muchos": `manager_id`
  vive en la fila del report y apunta a la del manager.
  *Decisión declarada, no hecho: las orgs reales tienen línea punteada.*

  **Método, aprendido aquí:** en una relación de una tabla consigo
  misma, hay que **nombrar los dos roles antes de aplicar el test**
  ("manager" y "report", no "A" y "B"). Con las etiquetas genéricas el
  sí/no no tiene a qué agarrarse y el test se vuelve inusable.
- **Evidence ↔ Snapshot** — sin verbo directo. La cadena
  Person→Evidence y Person→Snapshot ya lo cubre; no se dibuja flecha
  redundante.

### M2 — `Level` y `Competency` son campos, no tablas

`level_position` (entero) y `competency` (string) viven como columnas de
`Criterion`. Los nombres de nivel viven en una constante.

**Por qué:** ninguna feature del MVP necesita guardar atributos propios
de un nivel o de una competencia. Convertirlas en tablas añade dos joins
a cada query y no compra nada. Si apareciera "descripción larga por
competencia" o "orden configurable por empresa", pasarían a ser tablas.

### M3 — `Snapshot` se guarda congelado, aunque el gap sea derivable

El gap se puede recalcular en cualquier momento desde `Evidence`. Aun
así `Snapshot` es una tabla, y guarda: `level_position_at_close`,
`met_criterion_ids`, `gap_criterion_ids`, `narrative`, `prompt_payload`.

**Por qué:** la feature que lo exige es la progresión histórica ("en H1
te faltaban 4 criterios, ahora 2"), que es el gráfico central del
producto. Un valor derivado al vuelo cambiaría retroactivamente cuando
se añade evidencia vieja, y la narrativa dejaría de corresponder al
estado sobre el que se generó.

### M4 — La relación `Snapshot ↔ Criterion` se guarda como JSON anidado, no como tabla

Da doble sí en el test, así que en rigor pediría una intermedia
`SnapshotCriterion` con estado met/gap.

**Corte declarado:** se guarda como JSON en `Snapshot`, pero **anidado
con la evidencia que cubrió cada criterio**, no como un array plano de
IDs:

```json
met: [{ "criterion_id": 12, "evidence_ids": [5, 9] }]
gap: [{ "criterion_id": 13, "state": "empty",          "evidence_ids": [] },
      { "criterion_id": 14, "state": "uncorroborated", "evidence_ids": [7] }]
```

**Por qué anidado (corrección de Santiago, 2026-07-31):** si mañana se
edita o se borra una evidencia, el snapshot congelado debe seguir
mostrando qué la justificaba en su momento. Un array plano de
`criterion_id` perdía esa trazabilidad. Ver D9.

**Por qué JSON basta:** la auditoría que el producto necesita va en
dirección snapshot → criterios → evidencia, y esa dirección el JSON la
sirve sin problema.

**Disparador para promoverla a tabla intermedia:** cuando haga falta la
dirección contraria — *"¿en qué snapshots del equipo aparece el criterio
SK-03 como gap?"*. Eso es análisis agregado (ver la idea de "hueco en el
catálogo de formación" en D10), no auditoría individual. El día que
entre esa feature, la intermedia es obligatoria y el JSON hay que
migrarlo.

---

## Cortes de scope (MVP de 4-5 h)

| Fuera | Razón |
|---|---|
| Auth real | Se sustituye por un selector de lente (Employee / Manager), como en OpsGuard |
| Rol de HR en la UI | **Stretch, no corte definitivo** (ver D10). Base: existe solo como autor de evidencia en el seed. Entra si los tres primeros sprints van en hora |
| Edición del framework | Se siembra. El CRUD del catálogo no enseña nada del boundary |
| Deploy | Fuera. Se demuestra en local |
| Evals de la narrativa | Fuera por tiempo. Se nombra como el siguiente paso obvio |
| Notificaciones, ciclos automáticos | Fuera. El cierre de ciclo se dispara con un botón |

---

## Preguntas abiertas

- ¿Nombre definitivo? "Ladder" es provisional.
- ¿Cuántos criterios sembrar? Propuesta: 2 niveles × 3 competencias ×
  ~10 criterios. Suficiente para que el gap se vea, poco para sembrar.
- ¿La narrativa se genera al cerrar el ciclo o bajo demanda? Afecta si
  hace falta un job o basta una llamada síncrona.
