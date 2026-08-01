# Learning Log — Ladder

Registro de lo que Santiago no sabía y aprendió construyendo este
proyecto — Ruby on Rails, git/PR profesional, y disciplina de
verificación. Existe porque `SPEC.md` §1b dice que aprender esto es
tan objetivo del día como el MVP en sí.

Formato por entrada: el gap, el concepto correcto, por qué importa.
Compacto — no es transcript de la sesión.

---

## 2026-07-31

### Entorno: Ruby del sistema vs. gestionado

**Gap:** macOS trae Ruby 2.6.10 de fábrica, y Rails moderno pide 3.1+.
No sabía que había una diferencia entre "instalar otra versión de Ruby"
y "reemplazar la del sistema".

**Concepto:** `rbenv` no reemplaza el Ruby de macOS, convive con él.
Instala versiones aparte y pone un "shim" — un programa intermediario
diminuto — en el lugar donde normalmente iría `ruby`. Cuando escribes
`ruby -v`, en realidad corre el shim, que decide qué versión real usar
según `rbenv global`. La alternativa (`brew install ruby` a secas)
obliga a editar el `PATH` a mano, que es donde la mayoría se atasca.

**Por qué importa:** es el patrón estándar en tiendas Rails — varias
versiones conviviendo, cada proyecto con la suya si hace falta.

### Entorno: la terminal cachea rutas de comandos

**Gap:** activé rbenv y corregí el `PATH`, pero `ruby -v` en la misma
ventana seguía mostrando la 2.6.10 vieja.

**Concepto:** zsh guarda en caché dónde vive cada comando la primera vez
que lo resuelve, dentro de esa sesión de terminal. Cambiar el `PATH` no
invalida esa caché automáticamente. Una ventana **nueva** arranca sin
ese caché y lee la configuración ya corregida — por eso "cierra y abre
de nuevo" resuelve la mayoría de estos casos.

**Por qué importa:** el mismo patrón se repitió con `rbenv rehash` (ver
abajo) y es la explicación por defecto cuando algo "debería funcionar
pero no" justo después de cambiar el entorno.

### rbenv: los shims no se regeneran solos

**Gap:** instalé Rails con `gem install rails`, terminó bien (39 gemas),
pero `rails -v` respondió con un mensaje de macOS diciendo que Rails no
estaba instalado.

**Concepto:** rbenv genera un shim por cada comando ejecutable de cada
gema instalada, pero **no lo hace automáticamente** salvo que tengas el
plugin `rbenv-gem-rehash` (no viene por defecto con `brew install
rbenv`). Sin eso, hay que correr `rbenv rehash` a mano después de
instalar una gema con ejecutable nuevo (como `rails`).

**Por qué importa:** el mensaje de error de macOS es engañoso —"Rails is
not currently installed"— cuando en realidad sí estaba instalado, solo
que rbenv no lo había hecho visible todavía.

### `rails new` inicializa su propio git por defecto

**Gap:** el agente en Cursor necesitó borrar `api/.git` a mitad de S0.

**Concepto:** `rails new` corre `git init` y un commit inicial por
defecto, salvo que le pases `--skip-git`. Como ya teníamos un repo en la
raíz del proyecto, esto crea un repo anidado dentro de `api/` — git
trata esa carpeta como un submódulo fantasma y los archivos de adentro
dejan de aparecer bien en los commits del repo principal.

**Por qué importa:** la próxima vez que se re-scaffoldee algo con
`rails new` dentro de un repo existente, usar `--skip-git` desde el
inicio evita la limpieza después.

### `bundle install` interrumpido deja el proyecto en estado roto

**Gap:** el `bundle install` se veía "colgado" y se mató a mitad de
camino. Después, cualquier comando de Rails (`rails runner`, etc.)
fallaba con "Could not find sqlite3-2.9.5-arm64-darwin, puma-8.0.2..." —
una lista larga de gemas "no encontradas".

**Concepto:** compilar la extensión nativa de `sqlite3` (y otras gemas
con partes en C) tarda uno o dos minutos y no imprime nada mientras
tanto — parece colgado sin estarlo. Matarlo a mitad de la compilación
deja el `Gemfile.lock` apuntando a gemas que nunca terminaron de
instalarse. La solución no es depurar cada gema suelta: es volver a
correr `bundle install` completo y dejarlo terminar.

**Por qué importa:** es la misma lección de fondo que el caché de PATH —
en herramientas de compilación, "sin salida en pantalla" no es lo mismo
que "colgado", y cortar por impaciencia genera más trabajo que esperar.

### Rails: los idiomas que aparecieron en S0

- **Migration** — un cambio de schema versionado y reversible; un
  archivo por cambio estructural, para poder rodar hacia atrás si algo
  sale mal.
- **`belongs_to` auto-referencial** — una tabla apuntando a sí misma
  (`manager_id` en `people`, apuntando a otra fila de `people`). El
  truco es nombrar los dos roles (`manager`/`report`) en vez de pensar
  en "la tabla contra sí misma" de forma genérica.
- **`find_or_create_by!`** — permite un seed idempotente (correrlo dos
  veces no duplica datos) sin necesitar una gema de upsert aparte.
- **Inflections** (`config/initializers/inflections.rb`) — Rails
  pluraliza nombres automáticamente para nombrar tablas
  (`Criterion` → `criteria`, `Evidence` → `evidences`), y a veces se
  equivoca o hay que confirmárselo explícitamente cuando el plural es
  irregular.
- **`bin/rails dbconsole`** — abre una consola SQL real conectada a la
  base de datos correcta del proyecto, sin tener que buscar el archivo
  `.sqlite3` a mano ni recordar el comando de conexión.
- **`bin/rails runner '...'`** — corre una línea de Ruby con toda la
  aplicación ya cargada (modelos, asociaciones), útil para checks
  rápidos sin abrir una consola completa.
- **Ruta `/up`** — Rails moderno la añade por defecto como healthcheck;
  un `200 OK` ahí confirma que la app booteó de verdad, no solo que el
  comando no tiró error.

### Git: mergear en GitHub no actualiza tu copia local

**Gap:** después de darle "Squash and merge" en la interfaz de GitHub,
pregunté qué hacían exactamente `git checkout main` + `git pull`.

**Concepto:** el repo remoto (en GitHub) y el repo local (en tu Mac) son
dos copias separadas que solo se sincronizan cuando se lo pides
explícitamente. El botón de merge en GitHub crea el commit nuevo **en
la nube**; tu `main` local sigue siendo la versión vieja hasta que
corres `git pull`, que baja esos commits nuevos a tu máquina.
`git checkout main` es aparte: solo mueve el puntero de tu rama activa
local, de la rama del sprint de vuelta a `main`.

**Por qué importa:** si crearas la siguiente rama de sprint sin hacer
`pull` primero, nacería desde la versión vieja de `main` — sin el
scaffold de Rails ni de React adentro. Es el patrón a repetir después
de cada PR mergeado: `checkout main` → `pull` → recién ahí, rama nueva.

### Disciplina: verificar en vez de confiar

**Gap:** el agente reportó S0 como validado, pero al pedirle los
comandos exactos para comprobarlo yo mismo, no los di hasta que
`AGENTS.md` lo exigió explícitamente — y aun así, la primera vez que
edité `AGENTS.md` a mitad de sesión, el agente no se enteró solo.

**Concepto:** un agente no relee sus instrucciones automáticamente cada
vez que el archivo cambia — solo al arrancar una tarea, salvo que se le
diga explícitamente "releé el archivo". Y "reportado como validado" no
es lo mismo que "verificado independientemente" — probar la
idempotencia de verdad significa correr el seed dos veces y comparar
números, no confiar en que alguien más dice haberlo hecho.

**Por qué importa:** es literalmente la barra que describe el rol al
que estoy aplicando — "never blindly accepts agent output" — practicada
en código real, no solo como frase para la entrevista.
