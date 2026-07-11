# 001 v2 — opencode-moa: Orquestador Nativo OpenCode Multi-Modelo

**Nombre del repo:** `opencode-moa` (alineado al paper *Mixture-of-Agents*, Together AI 2024)
**Estado:** Borrador para revisión v2
**Fecha:** 2026-07-10
**Carpeta:** `003/` (nueva serie, separada de `002/*-glm-5.1.md` que eran bash-based)
**Base de conocimiento:** `002/007-glm-5.1.md`, iteraciones previas del usuario (cardiorrenal, oc-rust-02, eval-7-ia-001, oc-software-development-agents/001, /002)
**Principio rector:** 100% nativo OpenCode. Cero bash, cero python, cero scripts auxiliares, cero CLI shellouts.
**Audiencia:** Esta propuesta es **diseño**, no implementación. Una vez aprobada, se generan los archivos en user-level (`~/.config/opencode/`) o project-level (`.opencode/`).

---

## 0. Changelog

### v2 (esta versión) — 2026-07-10

| # | Cambio | Tipo | Razón |
|---|--------|------|-------|
| V1 | Numeración **0-9** (no decimales) | Mayor | Más limpio: 0=init, 1-8=flujo, 9=sumario |
| V2 | Sección **"Instalación"** — user-level + project-level | Mayor | El usuario lo quiere permanente en `~/.config/opencode/`, no copiable a cada proyecto |
| V3 | Sección **"Merge de configuración"** con 3 capas | Mayor | Permite overrides sin duplicar archivos |
| V4 | Validador reporta **viabilidad por sección** (no global) | Mayor | Una propuesta puede tener 4 secciones y solo 1 fallar — descalificar todo es agresivo |
| V5 | `descalificar_fallida` ahora es **opt-in** (default `false`) | Mayor | El usuario pidió matiz: si una propuesta tiene ideas rescatables, mantenerla en ranking con penalización |
| V6 | `smoke_test` con 4 capas (argumento > project > user > default) | Mayor | El usuario quiere control desde VPS (ssh) y desde local con flags |
| V7 | `smoke_test` acepta `true` / `false` / `"auto"` | Mayor | "Auto" deja que el orquestador decida según heurística |
| V8 | Sección **"Nombre del repo"** con 35 propuestas | Medio | Para subir a GitHub; el usuario eligió `opencode-moa` |
| V9 | Sección **"i18n"** — todo en inglés | Medio | El repo será en inglés (research-grade) |
| V10 | Paso 0 documentado como **Inicialización** explícita | Bajo | Antes estaba implícito, ahora es parte del flujo |
| V11 | Sumario se numera como **Paso 9** | Bajo | Para consistencia con numeración 0-9 |
| V12 | Mención de **config desde VPS vía SSH** | Bajo | Caso de uso real del usuario |

### v1 (versión inicial) — 2026-07-10

| # | Cambio | Tipo | Razón |
|---|--------|------|-------|
| N1 | **Eliminado `orquestador.sh`** (2058 líneas de bash) | Mayor | El orquestador ahora es un agente primario |
| N2 | **Eliminados `lib/*.sh`** (12 helpers) | Mayor | Toda la lógica vive dentro del system prompt de los agentes |
| N3 | **Eliminado `Makefile`** | Mayor | Reemplazado por custom commands |
| N4 | **Eliminado `scripts/check-env.sh`** | Mayor | OpenCode nativo: el validador detecta con `bash` |
| N5 | **Eliminado `orquestador.config`** | Mayor | Reemplazado por `.opencode/orquestador.json` |
| N6 | **Eliminados hooks pre/post-run** | Mayor | El orquestador decide el orden en su razonamiento |
| N7 | **Eliminada whitelist bash en `validator.md`** (100+ reglas) | Mayor | Reemplazado por `permission.bash` con globs nativos |
| N8 | **Eliminada llamada `opencode run --agent X --model Y`** | Mayor | Los subagents se invocan vía `task(subagent_type='X')` |
| N9 | **Multi-modelo solo en propuesta** | Mayor | Basado en evidencia de iteraciones reales |
| N10 | **Iterate mode con decisión por el LLM orquestador** | Mayor | El LLM hace la resta en su razonamiento |
| N11 | **Nomenclatura `out/{id}/iter-{N}/...`** | Medio | Estructura agrupada por iteración |
| N12 | **Solo 7 agentes** (vs 12 en 007) | Medio | Un agente por rol + 3 archivos `propuesta-{modelo}` |
| N13 | **Config única en JSON** con `version` field | Bajo | Permite validar schema y migrar |
| N14 | **IDs validados con regex** | Bajo | Evita problemas de Linux |
| N15 | **Slugificación automática del prompt** | Bajo | El LLM slugifica deterministamente |

**Lo que se conserva del 007 (bash-based)**:
- Lógica de pasos 1-9
- Validación empírica — sigue siendo valuable, solo cambia el ejecutor
- Modo iterate convergente — solo cambia la lógica de decisión
- Concepto de "agentes especializados"
- Anti-sesgo: temperatura 0.0 en evaluador/validador, 0.1 en sintetizador

---

## 1. Resumen Ejecutivo

`opencode-moa` es un orquestador multi-modelo **construido dentro de OpenCode**, no alrededor de él. Toda la lógica vive en un agente primario (`orquestador`) que usa la `task` tool para invocar subagents especializados en paralelo.

**Punto clave**: el usuario NO ejecuta `bash orquestador.sh`, NO edita `lib/*.sh`, NO configura `orquestador.config`. Solo:

1. (Una vez) Crea los agentes y comandos en `~/.config/opencode/` (user-level).
2. (Opcional) Crea `./orquestador.json` en proyectos específicos para overrides.
3. Ejecuta `/orquestar <prompt> <id>` o `/orquestar-iterate <prompt> <id>` desde la TUI.

El orquestador agent corre internamente, lanza subagents en paralelo, espera resultados, decide iterar o parar, y entrega el ganador en `out/{id}/iter-{N}/`.

**Garantía "cero bash"**: ningún archivo del proyecto es ejecutable, ningún script corre fuera de OpenCode. Todo es markdown + JSON + primitivas nativas (`task`, `bash`, `webfetch`, `read`, `write`, `glob`, `grep`, `todowrite`, `question`).

**Tradeoff explícito**: se pierde portabilidad (el orquestador ya no corre fuera de OpenCode) y `metrics.jsonl` estructurado (OpenCode loguea a su manera). A cambio: cero mantenimiento, todo declarativo, todo auditable.

---

## 2. Por qué nativo, no bash

### 2.1 Primitivas de OpenCode que reemplazan al bash

| Función del bash 007 | Primitiva OpenCode nativa |
|---|---|
| `lib/run-model.sh` (invoca `opencode run --agent X`) | `task` tool con `subagent_type='X'` |
| `lib/run-parallel.sh` (N procesos en background) | Múltiples `task` en una sola respuesta |
| `lib/validate-step.sh` | `glob` + `read` desde el orquestador agent |
| `lib/validate-empirical.sh` | `read` + `grep` desde el orquestador o `validador` |
| `lib/convergence.sh` | Resta en el razonamiento del LLM |
| `lib/parse-model.sh` | El LLM lee el JSON y extrae campos |
| `lib/render-filename.sh` | El LLM compone paths en su prompt |
| `lib/timing.sh` | OpenCode session log ya tiene timestamps |
| `lib/hooks.sh` | El orquestador decide el orden en su prompt |
| `scripts/check-env.sh` | El validador detecta con `bash: command -v X` |
| `Makefile` | Custom commands `/paso3`, etc. |
| `orquestador.config` | `.opencode/orquestador.json` |
| Whitelist bash del validador | `permission.bash` con globs nativos |

### 2.2 Ventajas de nativizar

- **Cero mantenimiento de scripts**: no hay `bash -n`, `shellcheck`, `jq`, `set -euo pipefail`
- **Permisos declarativos**: `permission.bash: { "npm install *": "allow" }` es autoexplicativo
- **Auditable nativamente**: session log de OpenCode muestra cada `task`, output, decisión
- **Resumible sin código**: el orquestador mira `out/{id}/iter-*/` con `glob` y continúa
- **Paralelismo declarativo**: el orquestador solo dice "lanza 3 task en paralelo"
- **Sin shellout al CLI**: no hay `opencode run` desde bash
- **Config centralizada y validable**: JSON con schema versionado

### 2.3 Lo que se pierde (aceptable)

- Portabilidad: el orquestador ya no corre fuera de OpenCode
- `metrics.jsonl` estructurado: OpenCode loguea; opcional escribir `out/{id}/metrics.jsonl` con `write`
- `compute_convergence.sh` testeable unitariamente: la lógica está en el prompt
- Hooks pre/post por paso: el orquestador hace el flujo completo en su prompt
- `--print-logs`, `--log-level INFO`: OpenCode gestiona su log
- `FORCE=1`: el orquestador puede borrar archivos con `bash rm` si el usuario lo pide

---

## 3. Decisión multi vs single-model por rol

### 3.1 Evidencia de tus iteraciones reales

| Proyecto | # Generadores | # Evaluadores | ¿Multi-eval cambió la decisión? |
|---|---|---|---|
| cardiorrenal R1 | 9 | 9 | No (consenso 8/9) |
| cardiorrenal R2 | 3 | 8 | **Sí** (5-3 split, GLM se autoeligió) |
| oc-rust-02 | 8 | 8 | No (consenso 8/8) |
| eval-7-ia-001 | 6 | 6 | No cambió decisión, pero detectó sesgo |
| oc-sda/001 | 2 | 2 | Sí (refinó) |
| oc-sda/002 | 3 | 3 | Sí (iteración sucesiva) |

**Sesgo de auto-evaluación cuantificado** (eval-7-ia-001):
- Rango: -0.51 a +1.89 puntos sobre 10
- Outlier: `qwen3.7-max` con sesgo +1.89

**Convergencia inter-evaluador**:
- 67% de los casos: consenso claro (>85%)
- 33% de los casos: empate técnico que requiere multi-eval

### 3.2 Decisión tomada

| Rol | ¿Multi-modelo? | Modelo(s) | Justificación |
|---|---|---|---|
| **Propuesta (paso 1, 5)** | **SÍ** | Lista en `orquestador.json` (default: glm-5.1, kimi-k2.6, minimax-m3) | Diversidad de enfoques, confirmado en todos los proyectos |
| **Evaluador (paso 3, 7)** | **NO** | `minimax-m3-thinking` (temp 0.0) | Consenso >85% en mayoría; un evaluador estricto basta cuando NO hay empate |
| **Validador (paso 2, 6)** | **NO** | `minimax-m3-thinking` (temp 0.0) | Resultados de bash son binarios; no hay subjetividad |
| **Sintetizador (paso 4, 8)** | **NO** | `minimax-m3-thinking` (temp 0.1) | Necesita criterio único y consistente |
| **Orquestador (todo)** | **NO** | `minimax-m3-thinking` (temp 0.2) | Coordinación requiere memoria estable |

### 3.3 Tradeoff del evaluador single-model

- **Pro**: 3-8x más económico, lógica simple, sin preocupación de auto-sesgo.
- **Contra**: si el evaluador tiene sesgo sistemático, pasa desapercibido.
- **Mitigación**: el orquestador puede detectar empates técnicos y sugerir re-evaluar con otro modelo (funcionalidad opcional).

---

## 4. Arquitectura general

### 4.1 Archivos a crear

```
# User-level (instalación única, disponible en todos los proyectos)
~/.config/opencode/
├── agents/
│   ├── orquestador.md                # PRIMARY: coordina 10 pasos (0-9) + iterate
│   ├── propuesta-glm.md              # subagent: genera/mejora, model=glm-5.1
│   ├── propuesta-kimi.md             # subagent: genera/mejora, model=kimi-k2.6
│   ├── propuesta-mimo.md             # subagent: genera/mejora, model=minimax-m3-thinking
│   ├── evaluador.md                  # subagent: evalúa todas, temp=0.0
│   ├── sintetizador.md               # subagent: clasifica/selecciona, temp=0.1
│   └── validador.md                  # subagent: bash + webfetch whitelist, temp=0.0
├── commands/
│   ├── orquestar.md                  # /orquestar <prompt> <id>
│   └── orquestar-iterate.md          # /orquestar-iterate <prompt> <id>
└── orquestador.json                  # config por defecto del usuario

# Project-level (opcional, solo overrides)
<proyecto>/
├── .opencode/
│   └── agents/
│       └── propuesta-{modelo_extra}.md   # para añadir modelos al pool
└── orquestador.json                      # override de la config del usuario
```

### 4.2 Outputs (generados por los agentes)

```
<proyecto>/out/
└── {id}/
    ├── iter-1/
    │   ├── 01-propuesta-glm.md
    │   ├── 01-propuesta-kimi.md
    │   ├── 01-propuesta-mimo.md
    │   ├── 02-validacion-glm.md
    │   ├── 02-validacion-kimi.md
    │   ├── 02-validacion-mimo.md
    │   ├── 03-calificacion-evaluador.md
    │   ├── 04-clasificacion.md
    │   ├── 05-mejorada-glm.md
    │   ├── 05-mejorada-kimi.md
    │   ├── 05-mejorada-mimo.md
    │   ├── 06-validacion-mejorada-glm.md
    │   ├── 06-validacion-mejorada-kimi.md
    │   ├── 06-validacion-mejorada-mimo.md
    │   ├── 07-calificacion-final.md
    │   ├── 08-ganador.md
    │   └── 09-sumario.md
    ├── iter-2/
    │   └── ... (misma estructura)
    └── iter-N/
        └── ...
```

### 4.3 Flujo visual

```
Usuario: /orquestar "Diseña API REST" auth-jwt
              │
              ▼
┌─────────────────────────────────────────────────┐
│ COMANDO /orquestar                              │
│ → invoca agent orquestador con prompt e id      │
└─────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ PASO 0 — INICIALIZACIÓN (orquestador agent)     │
│ 1. Lee orquestador.json (merge user + project)  │
│ 2. Valida config + existencia de agentes        │
│ 3. Valida/slugifica id                          │
│ 4. Crea out/{id}/iter-{N}/                      │
│ 5. todowrite: [paso 1-9]                        │
└─────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ PASO 1 — task(propuesta-glm)                    │ ─┐
│         task(propuesta-kimi)                    │  │ paralelo
│         task(propuesta-mimo)                    │ ─┘
└─────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ PASO 2 — task(validador) ×3                     │ ─┐ paralelo
│         (valida cada propuesta por sección)     │ ─┘
└─────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ PASO 3 — task(evaluador) ×1                     │
│         (evalúa todas con criterios)            │
└─────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ PASO 4 — task(sintetizador)                     │ — secuencial
│         (clasifica + descalifica opt-in)        │
└─────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ PASO 5 — task(propuesta-{x}) ×3                 │ ─┐
│         (cada uno con feedback empírico)        │  │ paralelo
└─────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ PASOS 6, 7, 8 — análogos a 2, 3, 4              │
└─────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ PASO 9 — escribe sumario.md                     │
│ Si modo iterate: decide continue/stop           │
└─────────────────────────────────────────────────┘
```

---

## 5. Instalación: dónde van los archivos

### 5.1 Instalación user-level (recomendada, una vez)

Esta instalación deja `opencode-moa` disponible en cualquier proyecto del usuario (local o vía SSH en VPS).

```bash
# 1. Crear directorios (en tu máquina local O en el VPS vía ssh)
mkdir -p ~/.config/opencode/agents
mkdir -p ~/.config/opencode/commands

# 2. Copiar los archivos del repo `opencode-moa`:
cp agents/* ~/.config/opencode/agents/
cp commands/* ~/.config/opencode/commands/
cp orquestador.json ~/.config/opencode/

# 3. Verificar
ls ~/.config/opencode/agents/
ls ~/.config/opencode/commands/
cat ~/.config/opencode/orquestador.json
```

**Caso VPS**: el usuario se conecta por SSH al VPS y hace lo mismo:
```bash
ssh user@vps "mkdir -p ~/.config/opencode/{agents,commands}"
scp -r agents/* user@vps:~/.config/opencode/agents/
scp -r commands/* user@vps:~/.config/opencode/commands/
scp orquestador.json user@vps:~/.config/opencode/
```

O, si el repo está en GitHub:
```bash
ssh user@vps "cd ~/.config/opencode && git clone https://github.com/usuario/opencode-moa.git _moa && cp _moa/agents/* agents/ && cp _moa/commands/* commands/ && cp _moa/orquestador.json ."
```

### 5.2 Instalación project-level (alternativa, una vez por proyecto)

Para instalar `opencode-moa` SOLO en un proyecto específico:

```bash
cd /path/to/my/project
mkdir -p .opencode/agents .opencode/commands
cp /path/to/opencode-moa/agents/* .opencode/agents/
cp /path/to/opencode-moa/commands/* .opencode/commands/
cp /path/to/opencode-moa/orquestador.json .
```

Esto tiene precedencia sobre la user-level (ver sección 6).

### 5.3 Híbrido (recomendado)

- **User-level**: agents y commands base (los 7 agentes + 2 comandos + orquestador.json por defecto).
- **Project-level**: solo `./orquestador.json` con overrides (ej. cambiar `smoke_test`, `modelos_a_competir`, etc.).

Así puedes tener una config global razonable y ajustarla por proyecto.

### 5.4 Verificación post-instalación

```bash
# 1. Listar agentes disponibles para OpenCode
opencode agent list

# Debería mostrar, entre otros:
#   orquestador (primary)
#   propuesta-glm (subagent)
#   propuesta-kimi (subagent)
#   propuesta-mimo (subagent)
#   evaluador (subagent)
#   sintetizador (subagent)
#   validador (subagent)

# 2. Listar custom commands
opencode command list

# Debería mostrar:
#   orquestar
#   orquestar-iterate

# 3. Smoke test (ver sección 20 para detalles)
# Desde la TUI de OpenCode:
/orquestar "Lista los 7 colores del arcoíris" colores
```

---

## 6. Merge de configuración

### 6.1 Precedencia (mayor a menor)

1. **Argumento runtime** del comando (ej. `/orquestar --smoke-test=true`).
2. **`./orquestador.json`** (project-level, si existe).
3. **`~/.config/opencode/orquestador.json`** (user-level).
4. **Defaults del orquestador** (valores hardcoded como fallback final).

### 6.2 Cómo el orquestador hace el merge

El agente orquestador tiene esta lógica en su system prompt:

```markdown
## Merge de configuración

Al iniciar, lee la configuración en este orden (último gana):

1. Empieza con defaults internos (hardcoded):
   - max_iteraciones = 3
   - umbral_convergencia = 0.5
   - validacion_empirica = true
   - descalificar_fallida = false   # V5: opt-in
   - smoke_test = false

2. Lee ~/.config/opencode/orquestador.json (si existe) — MERGE con defaults
   - Solo las claves presentes en el JSON sobrescriben los defaults
   - Las claves que NO están en el JSON se preservan

3. Lee ./orquestador.json (si existe) — MERGE con lo anterior
   - Solo las claves presentes sobrescriben

4. Parsea $ARGUMENTS del comando — MERGE final
   - Flags como --smoke-test=true, --max-iter=5, etc.
   - Solo aplica si el flag está presente

5. Valida el resultado final
   - max_iteraciones >= 1 && <= 10
   - umbral_convergencia >= 0.0 && <= 50.0
   - modelos_a_competir no vacío
   - cada modelo tiene su subagent correspondiente

6. Si alguna validación falla, aborta con mensaje claro
```

### 6.3 Ejemplo concreto

User-level `~/.config/opencode/orquestador.json`:
```json
{
  "version": "1.0",
  "modelos_a_competir": ["opencode-go/glm-5.1", "opencode-go/kimi-k2.6", "opencode-go/minimax-m3:thinking"],
  "modelo_objetivo": "opencode-go/minimax-m3-thinking",
  "max_iteraciones": 3,
  "umbral_convergencia": 0.5,
  "validacion_empirica": true,
  "descalificar_fallida": false,
  "smoke_test": false
}
```

Project-level `./orquestador.json` (opcional, override solo de algunas claves):
```json
{
  "smoke_test": "auto",
  "umbral_convergencia": 0.3,
  "descalificar_fallida": true
}
```

Merge final (lo que el orquestador usa):
```json
{
  "version": "1.0",
  "modelos_a_competir": ["opencode-go/glm-5.1", "opencode-go/kimi-k2.6", "opencode-go/minimax-m3:thinking"],
  "modelo_objetivo": "opencode-go/minimax-m3-thinking",
  "max_iteraciones": 3,                  // del user-level (no override)
  "umbral_convergencia": 0.3,            // del project-level (override)
  "validacion_empirica": true,           // del user-level
  "descalificar_fallida": true,          // del project-level (override)
  "smoke_test": "auto"                   // del project-level (override)
}
```

Argumento runtime (override final): `/orquestar --smoke-test=false "..." id`:
```json
{
  ...
  "smoke_test": false                    // del argumento (override final)
  ...
}
```

---

## 7. `orquestador.json` — esquema completo

### 7.1 Schema v1.0

```json
{
  "$schema": "https://opencode-moa.dev/schemas/orquestador.v1.json",
  "version": "1.0",
  "modelos_a_competir": [
    "opencode-go/glm-5.1",
    "opencode-go/kimi-k2.6",
    "opencode-go/minimax-m3:thinking"
  ],
  "modelo_objetivo": "opencode-go/minimax-m3-thinking",
  "max_iteraciones": 3,
  "umbral_convergencia": 0.5,
  "validacion_empirica": true,
  "descalificar_fallida": false,
  "smoke_test": false
}
```

### 7.2 Especificación de cada campo

| Campo | Tipo | Default | Descripción |
|---|---|---|---|
| `version` | string | requerido | Versión del schema (semver) |
| `modelos_a_competir` | array<string> | requerido | Modelos `proveedor/modelo[:variante]` para paso 1 y 5 |
| `modelo_objetivo` | string | requerido | Modelo para evaluador, validador, sintetizador y orquestador |
| `max_iteraciones` | integer (1-10) | 3 | Máximo de iteraciones del modo iterate |
| `umbral_convergencia` | number (0.0-50.0) | 0.5 | Mejora mínima de score entre iteraciones |
| `validacion_empirica` | boolean | true | Habilita pasos 2 y 6 (validación con bash + webfetch) |
| `descalificar_fallida` | boolean | false | **V5: opt-in**. Si true, propuestas ❌ NO VIABLE son descalificadas |
| `smoke_test` | boolean \| "auto" | false | **V7**. true/false/"auto" |

### 7.3 Validación al inicio (paso 0)

1. Verifica que `version` esté presente y sea `"1.0"`.
2. Verifica que `modelos_a_competir` sea array no vacío.
3. Verifica que `max_iteraciones >= 1 && <= 10`.
4. Verifica que `umbral_convergencia >= 0.0 && <= 50.0`.
5. Verifica que `descalificar_fallida` sea boolean.
6. Verifica que `smoke_test` sea boolean o `"auto"`.
7. Para cada modelo en `modelos_a_competir`, deriva `id_corto` y verifica con `glob` que existe `.opencode/agents/propuesta-{id_corto}.md` o `~/.config/opencode/agents/propuesta-{id_corto}.md`.
8. Si todo OK, crea `out/{id}/iter-{N}/` con `bash mkdir -p`.

### 7.4 Ejemplo de error

Si `orquestador.json` lista un modelo sin subagent:
```
ERROR: Missing subagent file for modelo opencode-go/opus-5.
Expected at: ~/.config/opencode/agents/propuesta-opus.md (or .opencode/agents/propuesta-opus.md)

Resolution:
  Option A: Create the subagent file with frontmatter:
    ---
    description: Generates technical proposals
    mode: subagent
    model: opencode-go/opus-5
    prompt: "{file:./prompts/03-propuesta.md}"
    ---
  Option B: Remove "opencode-go/opus-5" from modelos_a_competir in orquestador.json
```

---

## 8. Agentes: definición de cada uno

### 8.1 `agents/orquestador.md` (PRIMARY)

```markdown
---
description: opencode-moa orchestrator. Coordinates 10 steps (0-9) + iterate mode.
mode: primary
model: opencode-go/minimax-m3-thinking
temperature: 0.2
---

You are the orchestrator of a multi-model competition. Your job is to coordinate 10 steps (0 to 9) + iterate mode, all within native OpenCode.

## Fundamental rules

1. **Zero bash scripts**. All logic lives in your reasoning. If you find a bash script in the project, IGNORE it.
2. **Everything is a subagent**. To generate, evaluate, validate, synthesize, use `task(subagent_type='...')`.
3. **Declarative parallelism**: if you need N independent executions, put them in the SAME response as multiple `task` invocations.
4. **External config**: always read `~/.config/opencode/orquestador.json` and `./orquestador.json` at startup. Do NOT assume defaults.
5. **Structured output**: each subagent writes to `out/{id}/iter-{N}/` with fixed nomenclature.
6. **All communication in English** (this is an i18n requirement, see section 18).

## Step 0 — Initialization

```
1. Read $ARGUMENTS (from command /orquestar or /orquestar-iterate)
   - $1 = user prompt
   - $2 = id (optional; if missing, slugify $1)
   - Additional flags: --smoke-test={true|false|auto}, --max-iter=N, --convergence=X, --force
2. Validate id: must match ^[a-z0-9][a-z0-9-]{2,29}$
3. Apply merge of configuration (see section 6):
   - Start with hardcoded defaults
   - Read ~/.config/opencode/orquestador.json (if exists) and merge
   - Read ./orquestador.json (if exists) and merge
   - Apply $ARGUMENTS flags (if present)
   - Validate final config
4. For each model in modelos_a_competir, verify that propuesta-{id_corto}.md exists
   (use glob in both ~/.config/opencode/agents/ and .opencode/agents/)
5. Determine N (iteration number):
   - Use glob: out/{id}/iter-*/
   - N = max existing iter + 1 (or 1 if none exist)
6. Create out/{id}/iter-{N}/ with bash: mkdir -p out/{id}/iter-{N}
7. todowrite: [step 1, step 2, step 3, step 4, step 5, step 6, step 7, step 8, step 9]
8. If --force flag: rm -rf out/{id}/iter-{N} before creating
```

## Step 1 — Proposal generation (parallel)

For each model in `modelos_a_competir`:
```
task(
  description="Proposal with {id_corto}",
  subagent_type="propuesta-{id_corto}",
  prompt="
    Generate a technical proposal for: {user_prompt}

    ID: {id}
    Iteration: {N}
    Model: {model}

    Write your proposal to out/{id}/iter-{N}/01-propuesta-{id_corto}.md

    Follow your system prompt instructions.
  "
)
```

(All `task` calls in the SAME response, no text between them, for parallelism.)

## Step 2 — Empirical validation (parallel, optional)

If `validacion_empirica == true`:
For each generated proposal:
```
task(
  description="Validate proposal {id_corto}",
  subagent_type="validador",
  prompt="
    Empirically validate the proposal at out/{id}/iter-{N}/01-propuesta-{id_corto}.md

    Write your report to out/{id}/iter-{N}/02-validacion-{id_corto}.md

    IMPORTANT: Report viability PER SECTION, not global. See section 12 for format.

    Follow your system prompt instructions.
  "
)
```

## Step 3 — Evaluation

Single invocation (one evaluator for all proposals):
```
task(
  description="Evaluate all proposals",
  subagent_type="evaluador",
  prompt="
    Evaluate ALL proposals in out/{id}/iter-{N}/01-propuesta-*.md

    Validation reports available in out/{id}/iter-{N}/02-validacion-*.md (if they exist)

    Adjust AP based on viability scores per section (see section 13)

    Write consolidated evaluation to out/{id}/iter-{N}/03-calificacion-evaluador.md

    Follow your system prompt instructions.
  "
)
```

## Step 4 — Classification (with optional disqualification)

```
task(
  description="Classify proposals",
  subagent_type="sintetizador",
  prompt="
    Classify evaluated proposals.

    Read:
    - out/{id}/iter-{N}/03-calificacion-evaluador.md
    - out/{id}/iter-{N}/01-propuesta-*.md
    - out/{id}/iter-{N}/02-validacion-*.md (if exist)

    Write consolidated ranking to out/{id}/iter-{N}/04-clasificacion.md

    If descalificar_fallida == true (opt-in), disqualify proposals marked ❌ NO VIABLE.
    Otherwise, mark them ⚠️ but keep in ranking with AP reduced.

    Follow your system prompt instructions.
  "
)
```

## Step 5 — Improvement (parallel)

For each proposal:
```
task(
  description="Improve proposal {id_corto}",
  subagent_type="propuesta-{id_corto}",
  prompt="
    Improve the proposal at out/{id}/iter-{N}/01-propuesta-{id_corto}.md
    using feedback from:
    - out/{id}/iter-{N}/03-calificacion-evaluador.md
    - out/{id}/iter-{N}/04-clasificacion.md
    - out/{id}/iter-{N}/02-validacion-{id_corto}.md (if exists)

    Write improved proposal to out/{id}/iter-{N}/05-mejorada-{id_corto}.md

    Follow your system prompt instructions in 'improvement' mode.
  "
)
```

## Steps 6, 7, 8 — Analogous to 2, 3, 4 but for improved proposals

Step 6: validate improved proposals (writes `06-validacion-mejorada-*.md`)
Step 7: re-evaluate (writes `07-calificacion-final.md`)
Step 8: select winner (writes `08-ganador.md`)

## Step 9 — Summary

The orchestrator writes this itself with `write` (no subagent):
```
write(
  content="...",
  filePath="out/{id}/iter-{N}/09-sumario.md"
)
```

Content includes:
- Final score (extracted from 08-ganador.md)
- Winner model and proposal path
- Disqualified proposals (if any)
- Iteration metrics: time, token usage, iteration number
- Convergence status (if iterate mode)

## Iterate mode

If the command was `/orquestar-iterate`, after step 9:
```
1. Read out/{id}/iter-{N}/09-sumario.md → score_actual
2. If N == 1: prev_score = 0, jump to step 1 (continue always for first iter)
3. Read out/{id}/iter-{N-1}/09-sumario.md → prev_score
4. Calculate: mejora = score_actual - prev_score
5. Read umbral_convergencia from merged config
6. Read max_iteraciones from merged config
7. Decision logic:

   if N >= max_iteraciones:
     log("Maximum iterations reached ({N}/{max_iter}). STOP.")
     FINALIZE()

   if mejora >= umbral_convergencia:
     log("Meaningful improvement: {mejora} >= {umbral}. CONTINUE to iter {N+1}.")
     CONTINUE to step 1 with N+1
   else:
     log("Insufficient improvement: {mejora} < {umbral}. CONVERGED. STOP.")
     log("  (Regression: {mejora < 0})" if mejora < 0 else "")
     FINALIZE()

IMPORTANT: A regression (mejora < 0) ALWAYS results in STOP.
The check "mejora >= umbral" covers this:
  - mejora = -0.5, umbral = 0.5
  - -0.5 >= 0.5 → FALSE → STOP
```

## Empirical validation and permissions

When you need bash (for mkdir, ls, etc.), your default permissions are broad. BUT if you want to execute commands for the validator, do NOT do it yourself: delegate to the `validador` subagent which has restricted permissions.

## Messages to the user

Before each step, write in your response:
```
[STEP 1] Generating proposals with 3 models in parallel...
```

After each step:
```
[STEP 1 ✓] 3 proposals generated in out/{id}/iter-{N}/
```

## Errors and recovery

- If a subagent fails, retry 1 time. If it fails again, abort with clear message.
- If the JSON is malformed, abort with instructions on how to fix it.
- If a subagent file is missing, abort with message from section 7.4.
- If max_iter is reached in iterate mode, stop and write final summary.

## Smoke test support

If `--smoke-test=true` in $ARGUMENTS, OR if merged config has `smoke_test: true`:
- Replace user_prompt with "List the 7 colors of the rainbow in order"
- This validates the pipeline without spending many tokens

If `smoke_test: "auto"`:
- If user_prompt length < 50 chars AND doesn't contain "design" or "implement" or "build": use smoke test
- Otherwise: use real prompt
```

### 8.2 `agents/propuesta-{modelo}.md` (subagent per model)

Three nearly identical files. Example `agents/propuesta-glm.md`:

```markdown
---
description: Generates or improves technical proposals
mode: subagent
model: opencode-go/glm-5.1
temperature: 0.7
---

# Role

You are a technical proposal generator. You receive a user prompt and produce a detailed, structured, actionable proposal.

# Operating modes

Two modes based on the prompt you receive:

## Mode "generation" (step 1)

Typical prompt: "Generate a proposal for: {user_prompt}. ID: {id}. Iteration: {N}. Model: {model}. Write to out/{id}/iter-{N}/01-propuesta-{modelo_id}.md"

Your job:
1. Read the user prompt
2. Analyze the technical domain
3. Produce a complete proposal with:
   - Executive summary
   - Proposed architecture
   - Tech stack
   - Installation/execution commands (which the validator will test)
   - Security, scalability, maintainability considerations
   - Effort estimation
4. Write the file with `write`
5. Return a 1-paragraph summary to the orchestrator

## Mode "improvement" (step 5)

Typical prompt: "Improve the proposal at {path} using feedback from {feedback_paths}. Write to {output_path}"

Your job:
1. Read the original proposal
2. Read the feedbacks (evaluation, classification, empirical validation)
3. Identify weaknesses pointed out
4. Produce an improved version that addresses those points
5. Write with `write`
6. Return summary to orchestrator

# Principles

- **Concrete commands**: each proposal must include exact shell commands that the validator can execute.
- **Honest**: if you don't know something, say so. Don't invent APIs.
- **Traceable**: each technical decision must have justification.

# Anti-hallucination

- If you mention an API or URL, verify it exists (you can use `webfetch`).
- If you recommend a command, make sure of its syntax.
- If in doubt, suggest alternatives instead of asserting.

# Output format

```markdown
# 01 — Proposal {iteration} {id_corto}

**Date:** {ISO 8601}
**Model:** {model}
**Iteration:** {N}
**ID:** {id}

## Executive summary
[1-2 paragraphs]

## Proposed architecture
[Textual diagram + description]

## Tech stack
- Language: ...
- Framework: ...
- Database: ...
- Dependencies: ...

## Installation commands
```bash
# Exact commands that the validator will execute
npm install ...
```

## Considerations
- Security: ...
- Scalability: ...
- Maintainability: ...

## Effort estimation
- Complexity: ...
- Time: ...

## References
- [URL 1](https://...)
- [URL 2](https://...)
```

Minimum 50 lines, maximum 500.
```

**`agents/propuesta-kimi.md`** and **`agents/propuesta-mimo.md`**: identical except `model: opencode-go/kimi-k2.6` and `model: opencode-go/minimax-m3:thinking` respectively.

### 8.3 `agents/evaluador.md` (single-model)

```markdown
---
description: Evaluates technical proposals with objective criteria
mode: subagent
model: opencode-go/minimax-m3-thinking
temperature: 0.0
---

# Role

You are a technical evaluator. Your job is to grade ALL proposals in an iteration with objective criteria.

# Inputs

You receive a prompt with:
- Path to proposals: `out/{id}/iter-{N}/01-propuesta-*.md`
- Path to empirical validations (if they exist): `out/{id}/iter-{N}/02-validacion-*.md`
- Your job: read everything and produce a consolidated evaluation

# Evaluation criteria (out of 10 each, total 50)

1. **Technical Quality (TQ)** [0-10]:
   - Is the architecture sound?
   - Is the stack appropriate?
   - Are technical decisions well-justified?

2. **Completeness (CO)** [0-10]:
   - Does it cover all aspects of the prompt?
   - Are there missing sections?
   - Are the commands executable as-is?

3. **Applicability (AP)** [0-10]:
   - Can it be implemented as-is?
   - Are dependencies reasonable?
   - Is the implementation plan clear?

4. **Security (SE)** [0-10]:
   - Does it consider authentication/authorization?
   - Does it handle sensitive data?
   - Does it validate inputs?

5. **Innovation (IN)** [0-10]:
   - Are there creative or differentiated approaches?
   - Does it leverage modern capabilities?
   - Is it just "the usual" or does it add something new?

# Adjustment by empirical validation (V4: per section)

If a proposal has a validation report with viability scores PER SECTION:
- If 0 sections are ❌ NO VIABLE: full AP (up to 10).
- If 1 section is ❌ NO VIABLE (out of 3-4): AP = 5-7 (reduced, not eliminated).
- If 2 sections are ❌ NO VIABLE: AP = 2-4 (severely reduced).
- If 3+ sections are ❌ NO VIABLE: AP = 1 (barely viable).
- If viability score GLOBAL < 2/10 OR all sections critical fail: AP = 1.

If `descalificar_fallida == true` AND global viability < 3/10: mark as DESCALIFICADA in your table.

# Anti-bias

- **Do not inflate scores**. Be strict. Your temperature is 0.0.
- **Evaluate ALL proposals**, even the one you generated in another step (if applicable).
- **Cite evidence**: each score must have 1-2 phrases from the proposal text that justify it.

# Output format

```markdown
# 03 — Evaluation {id} iter-{N}

**Date:** {ISO 8601}
**Evaluator:** {evaluator_model}
**Proposals evaluated:** {count}

## Consolidated table

| Proposal | TQ | CO | AP | SE | IN | Total | Viability | Notes |
|----------|----|----|----|----|----|----|-----------|-------|
| glm-5.1   | X  | X  | X  | X  | X  | X/50 | X/10 | ...   |
| kimi-k2.6 | X  | X  | X  | X  | X  | X/50 | X/10 | ...   |
| minimax-m3| X  | X  | X  | X  | X  | X/50 | X/10 | ...   |

## Detail per proposal

### Proposal: glm-5.1 (path: ...)

**Technical Quality (X/10):**
> [Verbatim quote from the proposal that justifies the score]
> [Evaluator analysis]

**Completeness (X/10):**
> ...

(... same for AP, SE, IN)

**Total score:** X/50
**Empirical viability:** X/10

### Proposal: kimi-k2.6
...

### Proposal: minimax-m3
...

## General observations

[If any score is particularly high or low, explain why]
[If there are very similar proposals, mention it]
```

Minimum 80 lines.
```

### 8.4 `agents/sintetizador.md` (single-model)

```markdown
---
description: Synthesizes rankings and selects winners
mode: subagent
model: opencode-go/minimax-m3-thinking
temperature: 0.1
---

# Role

You are the synthesizer. Your job is to consolidate evaluations into a final ranking and, in step 8, select the absolute winner.

# Mode "classification" (step 4)

Inputs:
- `out/{id}/iter-{N}/03-calificacion-evaluador.md` (evaluations)
- `out/{id}/iter-{N}/01-propuesta-*.md` (proposals)
- `out/{id}/iter-{N}/02-validacion-*.md` (validations, if exist)

Output: `out/{id}/iter-{N}/04-clasificacion.md`

Process:
1. Read evaluations
2. If `descalificar_fallida == true` AND any proposal is ❌ NO VIABLE in validation:
   - Mark it as DESCALIFICADA in the ranking
3. Otherwise: mark as ⚠️ VIABLE CON ADVERTENCIAS but keep in ranking
4. Generate ranking ordered by total score
5. For ties, use lexicographic order of id_corto

Output format:
```markdown
# 04 — Classification {id} iter-{N}

**Date:** {ISO 8601}
**Synthesizer:** {model}

## Ranking

| Pos | Proposal | Total Score | Empirical Viability | State |
|-----|----------|-------------|---------------------|-------|
| 🥇 1 | minimax-m3 | 45.5/50 | 8/10 | ✅ OK |
| 🥈 2 | glm-5.1 | 43.2/50 | 6/10 | ⚠️ VIABLE CON ADVERTENCIAS |
| 🥉 3 | kimi-k2.6 | 41.8/50 | 9/10 | ✅ OK |
| — | ~~opus-5~~ | 38.0/50 | 2/10 | ~~DESCALIFICADA (❌ NO VIABLE)~~ |

## Analysis

[2-3 paragraphs justifying the ranking]

## Disqualifications (if descalificar_fallida == true)

[List with reason]

## Warnings (if descalificar_fallida == false)

[List with sections affected and recommendation]
```

# Mode "final selection" (step 8)

Inputs:
- `out/{id}/iter-{N}/07-calificacion-final.md`
- `out/{id}/iter-{N}/05-mejorada-*.md`
- `out/{id}/iter-{N}/04-clasificacion.md`
- `out/{id}/iter-{N}/06-validacion-mejorada-*.md` (if exist)

Output: `out/{id}/iter-{N}/08-ganador.md`

Process:
1. Compare aggregate score vs empirical viability
2. If high aggregate score but viability < 5/10, should NOT win
3. If `descalificar_fallida == true`, ❌ NO VIABLE proposals are excluded
4. Select winner and justify

Output format:
```markdown
# 08 — Winner {id} iter-{N}

**Date:** {ISO 8601}
**Synthesizer:** {model}
**Winner:** {winner_model}
**Total score:** {X}/50
**Empirical viability:** {Y}/10

## Decision analysis

[Justification considering both metrics]

## Winning proposal

[1-paragraph summary of the winning proposal]
```

# Principles

- **Temperature 0.1**: slight balance between creativity and consistency
- **Equanimous**: use explicit criteria, not intuition
- **Transparent**: each decision must have visible justification
```

### 8.5 `agents/validador.md` (single-model, bash permissions)

```markdown
---
description: Empirical validator — executes commands and consults official documentation
mode: subagent
model: opencode-go/minimax-m3-thinking
temperature: 0.0
permission:
  edit: deny
  bash:
    "*": ask
    "command -v *": allow
    "* --version": allow
    "*-version": allow
    "which *": allow
    "shellcheck *": allow
    "node --check *": allow
    "python -c *": allow
    "python3 -c *": allow
    "pip show *": allow
    "npm ls": allow
    "npm list *": allow
    "cargo --list": allow
    "npm install *": allow
    "pip install *": allow
    "cargo build *": allow
    "cargo check *": allow
    "go build *": allow
    "go vet *": allow
    "make *": allow
    "echo *": allow
    "printf *": allow
    "cat *": allow
    "ls *": allow
    "head *": allow
    "tail *": allow
    "wc *": allow
    "file *": allow
    "stat *": allow
    "mkdir *": allow
    "mkdir -p *": allow
    "rm *": ask
    "cp *": allow
    "mv *": allow
    "touch *": allow
    "grep *": allow
    "awk *": allow
    "sed *": allow
    "curl *": allow
    "wget *": allow
    "sleep *": allow
    "date *": allow
  webfetch: allow
  read: allow
  write: allow
---

# Role

You are the empirical validator. Your job is to close the theory-practice loop by executing the commands proposals mention, capturing real results, and reporting per-section viability.

# Inputs

You receive a prompt with:
- Path to the proposal to validate: `out/{id}/iter-{N}/01-propuesta-{modelo_id}.md` (or `05-mejorada-{modelo_id}.md` in step 6)
- Your output file: `out/{id}/iter-{N}/02-validacion-{modelo_id}.md` (or `06-validacion-mejorada-{modelo_id}.md`)

# Process (V4: per-section viability)

1. Read the proposal completely
2. **Identify SECTIONS** in the proposal (architecture, install commands, API endpoints, code snippets, etc.)
3. For each section, extract verifiable technical elements:
   - Complete shell commands
   - Dependencies and versions
   - External API URLs
   - Environment assumptions
   - Code snippets (validatable with `node --check`, `python -c`, etc.)
4. **Execute each element with bash**:
   - `command -v X` for existence
   - `X --version` for version
   - `shellcheck` for bash syntax
   - `node --check`, `python -c` for code syntax
   - `npm install`, `pip install`, `cargo build` for builds
   - `curl -sI` for HTTP endpoints
   - **Each command with 30s timeout**. If exceeded, mark SKIP.
5. **Investigate with webfetch** the official documentation of mentioned technologies
6. **Report viability PER SECTION** (not just global) — see format below

# Output format (V4: per-section)

```markdown
# 02 — Empirical Validation {id} iter-{N} {modelo_id}

**Date:** {ISO 8601}
**Proposal validated:** {proposal_path}
**Validator:** {model}

## Executive summary

| Metric | Value |
|--------|-------|
| Sections identified | N |
| Sections viable | N |
| Sections with warnings | N |
| Sections not viable | N |
| Total commands executed | N |
| Commands OK | N |
| Commands FAILED | N |
| Commands SKIP | N |
| **Global viability score** | **X/10** |

**Verdict:** ✅ VIABLE / ⚠️ VIABLE WITH WARNINGS / ❌ NOT VIABLE

## Viability per section

| Section | Viability | State |
|---------|-----------|-------|
| Installation commands | 9/10 | ✅ |
| External endpoints | 2/10 | ❌ (URL does not respond) |
| Python snippet | 8/10 | ✅ |
| Environment assumptions | 5/10 | ⚠️ Partial |

## Detail per section

### ✅ Section: Installation commands

#### `npm install express`
- **Purpose:** Install Express framework for REST API
- **Installed version:** express@4.18.2
- **Time:** 4.2s
- **Observation:** Clean installation, no warnings

### ⚠️ Section: Environment assumptions

#### `python --version`
- **Purpose:** Verify Python version
- **Installed version:** Python 3.9.7
- **Required version:** 3.10+
- **Difference:** ⚠️ Insufficient version
- **Recommendation:** Upgrade to 3.10+ or adjust proposal

### ❌ Section: External endpoints

#### `curl -sI https://api.example.com/v1/users`
- **Purpose:** Verify endpoint responds
- **Error:** HTTP 404 Not Found
- **Root cause:** URL does not exist or endpoint removed
- **Recommendation:** Use a different API or update the URL

### ⏭️ Section: [name]

#### `comando X`
- **Skip reason:** Exceeded timeout / requires sudo / ...
- **Recommendation:** ...

## Investigation with webfetch

### Official documentation consulted

#### {Technology} — {URL}
- **Matches proposal:** Yes / Partially / No
- **Observations:** ...

## Suggested changes to the proposal

1. **Change 1:** ...
2. **Change 2:** ...

## Conclusion

[Summary of empirical viability state, with global score and critical sections]
```

Minimum 30 lines, 6 mandatory sections.

# Principles

- **Absolute objectivity**: temperature 0.0, do not inflate the score
- **Zero hallucinations**: if you can't verify something, mark ⏭️ SKIP
- **Only official documentation**: webfetch only to official sites (expressjs.com, flask.palletsprojects.com, nodejs.org)
- **Sandbox**: never execute destructive commands (`rm -rf /`, `mkfs`, `dd of=/dev/...`). If you need them, mark SKIP with reason "destructive command not allowed"
- **Timeout**: each command has 30s. If exceeded, mark SKIP
- **Auditable**: each result includes exact command, output, time
- **PER SECTION**: report viability per section, not just global. This allows the evaluator to penalize AP proportionally without disqualifying the entire proposal.
```

---

## 9. Comandos: `/orquestar` y `/orquestar-iterate`

### 9.1 `.opencode/commands/orquestar.md`

```markdown
---
description: Orchestrate a complete multi-model competition (10 steps)
agent: orquestador
model: opencode-go/minimax-m3-thinking
subtask: true
---

Execute the complete multi-model competition.

Arguments:
- $1 = user prompt (in quotes if it has spaces)
- $2 = id (optional; if missing, the orchestrator slugifies $1)

Optional flags (parsed by the orchestrator):
- --smoke-test={true|false|auto} — overrides smoke_test from config
- --max-iter=N — overrides max_iteraciones
- --convergence=X — overrides umbral_convergencia
- --force — deletes out/{id}/iter-{N}/ before starting
- --no-validation — disables validation steps (2 and 6)

Behavior:
1. Read and merge orquestador.json (user + project + args)
2. Validate configuration
3. Execute steps 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
4. Write out/{id}/iter-1/09-sumario.md with final score
5. Show summary to user

Examples:
/orquestar "Design a REST API for inventory management with JWT auth" auth-jwt
/orquestar "List the 7 colors of the rainbow in order"  # id auto-slugified: "list-the-7-colors"
/orquestar --smoke-test=true "Test the pipeline" smoke
/orquestar --force "Redo the calculation" calc-v2

Expected output:
- out/auth-jwt/iter-1/01-propuesta-glm.md
- out/auth-jwt/iter-1/01-propuesta-kimi.md
- out/auth-jwt/iter-1/01-propuesta-mimo.md
- ... (all flow files)
- out/auth-jwt/iter-1/08-ganador.md
- out/auth-jwt/iter-1/09-sumario.md
```

### 9.2 `.opencode/commands/orquestar-iterate.md`

```markdown
---
description: Orchestrate with iterate mode (loop until convergence or max_iterations)
agent: orquestador
model: opencode-go/minimax-m3-thinking
subtask: true
---

Execute the multi-model competition in iterate mode.

Arguments:
- $1 = user prompt
- $2 = id (optional)

Same optional flags as /orquestar.

Behavior:
1. Same as /orquestar, but after step 9:
   - Read current iteration's score from sumario
   - Compare with previous iteration's score (if exists)
   - If improvement >= threshold AND N < max_iter: continue to iter N+1
   - Otherwise: stop with consolidated final summary

Examples:
/orquestar-iterate "Design a REST API for inventory management" auth-jwt
/orquestar-iterate --max-iter=5 --convergence=0.3 "Design a complex system" complex

Expected output:
- out/auth-jwt/iter-1/ (all files)
- out/auth-jwt/iter-2/ (all files, if there was sufficient improvement)
- out/auth-jwt/iter-N/ (until convergence)
- out/auth-jwt/iter-N/09-sumario.md with final winner's score
```

---

## 10. Flujo de los 10 pasos (0-9)

This section shows the exact code the orchestrator emits at each step. We assume:
- `models = ["opencode-go/glm-5.1", "opencode-go/kimi-k2.6", "opencode-go/minimax-m3:thinking"]`
- `id_corto_map = { "opencode-go/glm-5.1": "glm", "opencode-go/kimi-k2.6": "kimi", "opencode-go/minimax-m3:thinking": "mimo" }`
- `N = 1` (first iteration)

### 10.1 Step 0 — Initialization

The orchestrator does NOT emit `task` calls in step 0. It does:
1. `read $ARGUMENTS`
2. `read ~/.config/opencode/orquestador.json` (if exists)
3. `read ./orquestador.json` (if exists)
4. Merge (orquestador agent does this in its reasoning)
5. `glob .opencode/agents/propuesta-*.md` and `glob ~/.config/opencode/agents/propuesta-*.md`
6. `bash: mkdir -p out/{id}/iter-{N}`
7. `todowrite: [step 1, ..., step 9]`

### 10.2 Step 1 — Parallel proposal generation

```
task(
  description="Proposal with GLM",
  subagent_type="propuesta-glm",
  prompt="Generate a proposal for: {user_prompt}.

ID: {id}
Iteration: {N}
Model: opencode-go/glm-5.1

Write to out/{id}/iter-{N}/01-propuesta-glm.md.

Follow your system prompt."
)

task(
  description="Proposal with KIMI",
  subagent_type="propuesta-kimi",
  prompt="... (same prompt, id_corto=kimi) ..."
)

task(
  description="Proposal with MIMO",
  subagent_type="propuesta-mimo",
  prompt="... (same prompt, id_corto=mimo) ..."
)
```

(All 3 `task` in the SAME response, no text between them, for parallelism.)

### 10.3 Step 2 — Parallel empirical validation

If `validacion_empirica == true`:

```
task(
  description="Validate GLM proposal",
  subagent_type="validador",
  prompt="Validate out/{id}/iter-{N}/01-propuesta-glm.md. Write report to out/{id}/iter-{N}/02-validacion-glm.md.

IMPORTANT: Report viability PER SECTION, not global."
)

task(
  description="Validate KIMI proposal",
  subagent_type="validador",
  prompt="Validate out/{id}/iter-{N}/01-propuesta-kimi.md. Write to out/{id}/iter-{N}/02-validacion-kimi.md. PER SECTION viability."
)

task(
  description="Validate MIMO proposal",
  subagent_type="validador",
  prompt="Validate out/{id}/iter-{N}/01-propuesta-mimo.md. Write to out/{id}/iter-{N}/02-validacion-mimo.md. PER SECTION viability."
)
```

### 10.4 Step 3 — Evaluation

A single invocation (only one evaluator for all proposals):

```
task(
  description="Evaluate all proposals",
  subagent_type="evaluador",
  prompt="Evaluate ALL proposals in out/{id}/iter-{N}/01-propuesta-*.md. Validations in out/{id}/iter-{N}/02-validacion-*.md. Write out/{id}/iter-{N}/03-calificacion-evaluador.md.

Adjust AP per-section based on validation viability (not just global)."
)
```

### 10.5 Step 4 — Classification (with optional disqualification)

```
task(
  description="Classify proposals",
  subagent_type="sintetizador",
  prompt="Read out/{id}/iter-{N}/03-calificacion-evaluador.md, out/{id}/iter-{N}/01-propuesta-*.md, out/{id}/iter-{N}/02-validacion-*.md. Write ranking to out/{id}/iter-{N}/04-clasificacion.md. Mode: classification.

If descalificar_fallida == true, mark ❌ NO VIABLE as DESCALIFICADA.
Otherwise, mark ⚠️ but keep in ranking."
)
```

### 10.6 Step 5 — Parallel improvement

```
task(
  description="Improve GLM proposal",
  subagent_type="propuesta-glm",
  prompt="Improve out/{id}/iter-{N}/01-propuesta-glm.md with feedback from 03-calificacion-evaluador.md, 04-clasificacion.md, 02-validacion-glm.md. Write out/{id}/iter-{N}/05-mejorada-glm.md. Mode: improvement."
)

task(
  description="Improve KIMI proposal",
  subagent_type="propuesta-kimi",
  prompt="... (analogous)"
)

task(
  description="Improve MIMO proposal",
  subagent_type="propuesta-mimo",
  prompt="... (analogous)"
)
```

### 10.7 Steps 6, 7, 8

Identical to 2, 3, 4 but with paths pointing to `05-mejorada-*.md` and writing to `06-validacion-mejorada-*.md`, `07-calificacion-final.md`, `08-ganador.md`.

### 10.8 Step 9 — Summary

The orchestrator writes this itself with `write` (no subagent):

```
write(
  content="# 09 — Summary {id} iter-{N}

**Date:** {ISO}
**Iteration:** {N}
**Total iterations planned:** {max_iter}

## Final score

- **Winner:** {winner_model}
- **Total score:** {score}/50
- **Empirical viability:** {viability}/10
- **Winning proposal:** out/{id}/iter-{N}/05-mejorada-{winner_model}.md

## Disqualifications

[If descalificar_fallida == true AND any disqualifications, list]

## Iteration metrics

- Total commands tested: {N}
- Total commands OK: {N}
- Total commands FAILED: {N}
- Total commands SKIP: {N}
- Average viability: {avg}

## Convergence status (iterate mode only)

- Previous score: {prev_score}
- Current score: {current_score}
- Improvement: {mejora}
- Threshold: {umbral}
- Verdict: CONVERGED / CONTINUE / MAX_REACHED

## Next steps

[For normal mode: FIN]
[For iterate mode: continue or stop based on logic]",
  filePath="out/{id}/iter-{N}/09-sumario.md"
)
```

---

## 11. Modo iterate

### 11.1 Cuándo se activa

When the invoked command is `/orquestar-iterate` (not `/orquestar`). The orchestrator detects this by the command that invoked it (OpenCode provides this as a context variable).

### 11.2 Lógica de decisión (pseudo-código)

```python
# After step 9 of iteration N:

N = current_iteration_number()
prev_score = read_score_from_sumario(iter=N-1) if N > 1 else 0
new_score = read_score_from_sumario(iter=N)
threshold = merged_config.umbral_convergencia
max_iter = merged_config.max_iteraciones

if N >= max_iter:
    log(f"Maximum iterations reached ({N}/{max_iter}). STOP.")
    FINALIZE()

mejora = new_score - prev_score

if mejora >= threshold:
    log(f"Meaningful improvement: {mejora} >= {threshold}. CONTINUE to iter {N+1}.")
    continue_flow(N+1)
else:
    log(f"Insufficient improvement: {mejora} < {threshold}. CONVERGED. STOP.")
    if mejora < 0:
        log(f"  (Regression detected: {mejora})")
    FINALIZE()
```

### 11.3 Casos cubiertos

| Escenario | mejora | N vs max | Decisión |
|---|---|---|---|
| First iteration | N/A | 1 < 3 | CONTINUE (always the first) |
| Large improvement | +2.0 | 2 < 3 | CONTINUE |
| Small improvement | +0.3 | 2 < 3, threshold=0.5 | STOP (converged) |
| Regression | -1.0 | 2 < 3 | STOP (regression) |
| No change | 0 | 2 < 3 | STOP (no change) |
| Reached maximum | cualquiera | 3 == 3 | STOP (max) |

### 11.4 Anti-loop-infinito

Three safeguards:
1. **`max_iteraciones`**: hard cap (default 3, max recommended 10).
2. **Convergence by threshold**: if improvement is < threshold, stop.
3. **Regression always stops**: improvement < 0 → STOP.

Infinite loops are impossible.

### 11.5 Cómo lo ejecuta el LLM orquestador

The orchestrator has this rule in its prompt (already written in section 8.1):

```
if N >= max_iteraciones:
    log("STOP for max")
    FIN
if mejora >= umbral_convergencia:
    log("CONTINUE")
    continue_flow(N+1)
else:
    log("STOP for convergence or regression")
    FIN
```

The LLM does the subtraction `new_score - prev_score` in its reasoning. If it has doubts about the score format, it uses `read` to verify the file.

---

## 12. Validación empírica con viabilidad por sección (V4)

### 12.1 Por qué por sección

A complex proposal can have 4-5 distinct technical sections:
- Installation commands
- External API endpoints
- Code snippets (Python/JS)
- Environment assumptions
- Configuration files

It's common for ONE section to fail (e.g., an external URL no longer responds) while the OTHER 4 sections are perfectly valid. Disqualifying the entire proposal for that single failure is too aggressive.

### 12.2 Formato del reporte del validador

Already detailed in section 8.5. Key structure:

```markdown
## Viability per section

| Section | Viability | State |
|---------|-----------|-------|
| Installation commands | 9/10 | ✅ |
| External endpoints | 2/10 | ❌ |
| Python snippet | 8/10 | ✅ |
| Environment assumptions | 5/10 | ⚠️ |

## Global viability score
Weighted average: 6.0/10
Critical sections failed: 1 of 4
```

### 12.3 Permisos bash del validador

Already detailed in section 8.5 frontmatter. Key whitelist:

```yaml
permission:
  bash:
    "*": ask
    "command -v *": allow
    "* --version": allow
    "shellcheck *": allow
    "node --check *": allow
    "python3 -c *": allow
    "pip show *": allow
    "npm ls": allow
    "cargo --list": allow
    "npm install *": allow
    "pip install *": allow
    "cargo build *": allow
    "make *": allow
    "echo *": allow
    "cat *": allow
    "ls *": allow
    "head *": allow
    "tail *": allow
    "grep *": allow
    "curl *": allow
    "mkdir *": allow
    "mkdir -p *": allow
    "rm *": ask
```

### 12.4 Comandos prohibidos (fall under `*: ask`)

- `rm -rf /`
- `mkfs`, `mkfs.ext4`
- `dd of=/dev/...`
- `chmod 777 /`
- `curl | bash`
- Any command not in the whitelist → user confirmation

---

## 13. Descalificación opt-in (V5)

### 13.1 Cambio de default

**Before (v1)**: `descalificar_fallida: true` by default.
**Now (v2)**: `descalificar_fallida: false` by default.

Razón: el usuario observó que propuestas complejas pueden tener valor rescatable incluso si una sección falla. Descalificar todo es agresivo.

### 13.2 Comportamiento según el flag

**When `descalificar_fallida: false` (default v2)**:
- Proposals with ❌ sections are marked ⚠️ in the ranking.
- They stay in the ranking with reduced AP (per section, see evaluator logic).
- The synthesizer explains which sections failed and recommends manual review.
- The user can still see the proposal and decide to use it partially.

**When `descalificar_fallida: true` (opt-in)**:
- Proposals with global viability < 3/10 OR 3+ ❌ sections are marked DESCALIFICADA.
- They appear crossed out (`~~propuesta-X~~`) in the ranking.
- They are excluded from the final selection.

### 13.3 Cuándo activar `descalificar_fallida: true`

- For safety-critical proposals (medical, financial, security).
- When the user wants strict validation, no exceptions.
- When proposals tend to be small/simple (one section, all-or-nothing).

### 13.4 Cuándo dejar en `false` (default)

- For complex proposals with multiple sections (most cases).
- When you want to rescue partial ideas.
- When you trust the evaluator's AP reduction as a softer signal.

### 13.5 Tabla resumen

| Global viability | ❌ sections | descalificar=false | descalificar=true |
|---|---|---|---|
| 9-10/10 | 0 | ✅ OK | ✅ OK |
| 7-8/10 | 0-1 | ✅ OK | ✅ OK |
| 5-6/10 | 1-2 | ⚠️ VIABLE CON ADVERTENCIAS | ⚠️ VIABLE CON ADVERTENCIAS |
| 3-4/10 | 2-3 | ⚠️ VIABLE CON ADVERTENCIAS | ❌ DESCALIFICADA |
| < 3/10 | 3+ | ⚠️ VIABLE CON ADVERTENCIAS | ❌ DESCALIFICADA |

---

## 14. Estructura de salida: `out/{id}/iter-{N}/...`

### 14.1 Nomenclatura

```
out/
└── {id}/                              # lowercase, [a-z0-9-]{3,30}
    ├── iter-1/
    │   ├── 01-propuesta-glm.md
    │   ├── 01-propuesta-kimi.md
    │   ├── 01-propuesta-mimo.md
    │   ├── 02-validacion-glm.md       # si validacion_empirica
    │   ├── 02-validacion-kimi.md
    │   ├── 02-validacion-mimo.md
    │   ├── 03-calificacion-evaluador.md
    │   ├── 04-clasificacion.md
    │   ├── 05-mejorada-glm.md
    │   ├── 05-mejorada-kimi.md
    │   ├── 05-mejorada-mimo.md
    │   ├── 06-validacion-mejorada-glm.md   # si validacion_empirica
    │   ├── 06-validacion-mejorada-kimi.md
    │   ├── 06-validacion-mejorada-mimo.md
    │   ├── 07-calificacion-final.md
    │   ├── 08-ganador.md
    │   └── 09-sumario.md
    ├── iter-2/
    │   └── ... (misma estructura)
    └── iter-N/
        └── ...
```

### 14.2 Validación del ID

The orchestrator validates with regex before creating the directory:

```
regex = ^[a-z0-9][a-z0-9-]{2,29}$
```

- Minimum 3 characters, maximum 30.
- First character: letter or digit (not hyphen).
- Rest: letters, digits, hyphens.
- No spaces, no uppercase, no special characters.

If the user's ID doesn't match, the orchestrator attempts to slugify the prompt:

| Prompt | Auto ID |
|---|---|
| "Design a REST API for inventory management" | `design-a-rest-api-for-inve` |
| "Calculate factorial of N" | `calculate-factorial-of-n` |
| "List 7 colors" | `list-7-colors` |

If slugification fails (rare cases with non-ASCII characters), the orchestrator asks the user with the `question` tool.

---

## 15. Resumabilidad

### 15.1 Comportamiento al re-ejecutar

If the user runs `/orquestar "..." auth-jwt` and `out/auth-jwt/iter-1/` already exists:

- The orchestrator uses `glob` to see which files exist.
- For each step, verifies if expected outputs already exist.
- If they exist and are "complete" (more than X lines), **skips that step**.
- If they exist but are empty or partial, **regenerates them**.

### 15.2 Criterio de "completitud"

| File | Minimum lines |
|---|---|
| `01-propuesta-*.md` | 50 |
| `02-validacion-*.md` | 30 |
| `03-calificacion-evaluador.md` | 80 |
| `04-clasificacion.md` | 20 |
| `05-mejorada-*.md` | 50 |
| `06-validacion-mejorada-*.md` | 30 |
| `07-calificacion-final.md` | 80 |
| `08-ganador.md` | 15 |
| `09-sumario.md` | 10 |

If a file exists but has fewer lines than the minimum, it is regenerated with FORCE.

### 15.3 Forzar re-ejecución

`/orquestar --force "..." auth-jwt` → deletes `out/auth-jwt/iter-{N}/` before starting (where N is the next iteration to be created).

---

## 16. Métricas nativas

### 16.1 Lo que OpenCode ya loguea

- Session log of each subagent invocation (prompt, output, time, tokens).
- History of invoked tools (task, bash, read, write, etc.).
- Errors with stack trace.

The user can review this from the TUI or web UI.

### 16.2 Métricas opcionales (V13)

If the user wants structured metrics, the orchestrator can write `out/{id}/metrics.jsonl` per step:

```json
{"timestamp":"2026-07-10T10:30:00Z","step":"1","subagent":"propuesta-glm","elapsed_sec":45,"outfile":"out/auth-jwt/iter-1/01-propuesta-glm.md"}
{"timestamp":"2026-07-10T10:30:45Z","step":"1","subagent":"propuesta-kimi","elapsed_sec":38,"outfile":"out/auth-jwt/iter-1/01-propuesta-kimi.md"}
{"timestamp":"2026-07-10T10:31:23Z","step":"1","subagent":"propuesta-mimo","elapsed_sec":52,"outfile":"out/auth-jwt/iter-1/01-propuesta-mimo.md"}
{"timestamp":"2026-07-10T10:32:15Z","step":"3","subagent":"evaluador","elapsed_sec":89,"outfile":"out/auth-jwt/iter-1/03-calificacion-evaluador.md"}
...
```

This is **optional**. The proposal does NOT require it.

---

## 17. Smoke test con 4 capas (V6, V7)

### 17.1 Modos aceptados

```json
{
  "smoke_test": true | false | "auto"
}
```

- `true`: always execute smoke test (prompt dummy)
- `false`: never execute smoke test
- `"auto"`: the orchestrator decides based on heuristic

### 17.2 Precedencia de 4 capas

1. **Argumento runtime** (highest priority): `/orquestar --smoke-test=true "..." id`
2. **Project-level orquestador.json**: `./orquestador.json` with `"smoke_test": true`
3. **User-level orquestador.json**: `~/.config/opencode/orquestador.json` with `"smoke_test": "auto"`
4. **Default fallback**: `false` (no smoke test)

### 17.3 Heurística para `"auto"`

The orchestrator uses this heuristic when `smoke_test == "auto"`:
- If user prompt < 50 chars AND doesn't contain "design" / "implement" / "build" / "create": use smoke test
- Otherwise: use real prompt

Examples:
| Prompt | Auto decision |
|---|---|
| "List 7 colors" | Smoke test (short, simple) |
| "Design REST API with JWT" | Real flow (contains "design", complex) |
| "Hello world" | Smoke test (trivial) |
| "Calculate factorial of N" | Real flow (50+ chars or algorithm) |

### 17.4 Caso de uso para VPS

El usuario usa OpenCode web desde VPS. Para configurar el smoke test desde VPS vía SSH:

```bash
# Conectarse al VPS
ssh user@vps

# Editar config user-level
nano ~/.config/opencode/orquestador.json
# Cambiar "smoke_test": false → "smoke_test": "auto"

# O editar config project-level (afecta solo este proyecto)
nano ./orquestador.json
# Agregar "smoke_test": true
```

### 17.5 Cómo lo procesa el orquestador

Already detailed in section 8.1 system prompt:

```markdown
## Smoke test

If --smoke-test=true in $ARGUMENTS, OR if merged config has smoke_test: true:
- Replace user_prompt with "List the 7 colors of the rainbow in order"
- This validates the pipeline without spending many tokens

If smoke_test: "auto":
- If user_prompt length < 50 chars AND doesn't contain "design" or "implement" or "build": use smoke test
- Otherwise: use real prompt
```

---

## 18. i18n (V9)

### 18.1 Idioma del repo y código

Todo el contenido del repo `opencode-moa` está en **inglés**:

| Elemento | Idioma |
|---|---|
| `agents/*.md` system prompts | English |
| `commands/*.md` descriptions | English |
| `orquestador.json` keys | English |
| Output file headers (`# 01 — Proposal`, etc.) | English |
| Commit messages | English |
| README, CONTRIBUTING, docs | English |
| GitHub Issues / PRs | English (preferred) |

### 18.2 Excepciones permitidas

- El contenido de las propuestas generadas puede estar en el idioma del usuario (si el usuario escribe el prompt en español, la propuesta se genera en español).
- Los mensajes de error y logs que van al usuario pueden estar en español si el usuario lo prefiere (configurable, default English).
- El feedback empírico del validador se reporta en inglés (es reporting técnico).

### 18.3 Razón

- Research-grade: el repo será público, otros investigadores/devs deben poder entenderlo.
- Consistencia con el ecosistema OpenCode (documentación oficial en inglés).
- Mayor alcance en GitHub.

### 18.4 Configuración opcional

Para usuarios que prefieren mensajes en español:

```json
// En orquestador.json (futuro, no implementado en v2)
{
  "idioma_output": "es"  // "es" | "en", default "en"
}
```

(Esto se puede agregar en v3 si hay demanda. Por ahora, todo el repo es inglés.)

---

## 19. Nombre del repo (V8) — 35 propuestas

### 19.1 Elección del usuario

**`opencode-moa`** (alineado al paper Mixture-of-Agents, Together AI 2024).

### 19.2 Lista completa de 35 propuestas organizadas en 5 grupos

#### Grupo A — Multi-Agent / MoA (paper-style) (4 nombres)

| # | Nombre | Significado |
|---|---|---|
| A1 | `opencode-moa` ⭐ | OpenCode + Mixture-of-Agents (elegido) |
| A2 | `opencode-mixture-of-agents` | Descriptivo completo |
| A3 | `native-moa-orchestrator` | Enfatiza nativo + MoA |
| A4 | `opencode-moa-native` | Variante de orden |

#### Grupo B — Native-focused (4 nombres)

| # | Nombre | Significado |
|---|---|---|
| B1 | `opencode-native-orchestrator` | Conciso y directo |
| B2 | `native-opencode-flow` | Flow nativo |
| B3 | `opencode-native-agents` | Agentes nativos |
| B4 | `pure-opencode` | "Puro" sin dependencias externas |

#### Grupo C — Orchestrator / Conductor (3 nombres)

| # | Nombre | Significado |
|---|---|---|
| C1 | `opencode-orchestrator` | Genérico |
| C2 | `opencode-conductor` | Metáfora musical |
| C3 | `opencode-pipeline` | Énfasis en pipeline |

#### Grupo D — Mix / Layer / Mesh (3 nombres)

| # | Nombre | Significado |
|---|---|---|
| D1 | `opencode-agent-mesh` | Red de agentes |
| D2 | `opencode-mix-flow` | Mix + flow |
| D3 | `opencode-agent-cascade` | Cascada de agentes |

#### Grupo E — Brand-y / Catchy (20 nombres, 10 con sufijo `-oc` + 10 sin sufijo)

| # | Nombre | Significado |
|---|---|---|
| E1 | `coflow-oc` | collaborative flow + oc |
| E2 | `meshup-oc` | mesh + up (mashup) |
| E3 | `swarmix-oc` | swarm + mix |
| E4 | `fuse-oc` | fusionar agentes |
| E5 | `polylm-oc` | poly + LM |
| E6 | `braid-oc` | trenzar modelos |
| E7 | `loom-oc` | tejer respuestas |
| E8 | `cascade-oc` | cascada |
| E9 | `forge-oc` | forjar respuestas |
| E10 | `bloom-oc` | florecer iterativamente |
| E11 | `agentfuse` | fusionar agentes |
| E12 | `polycode` | múltiples códigos |
| E13 | `synthex` | synthesis + index |
| E14 | `moaflow` | MoA + flow |
| E15 | `agentloom` | tejer agentes |
| E16 | `mixloop` | mix + loop (iterate mode) |
| E17 | `codecascade` | cascada de codes |
| E18 | `flowmesh` | flow + mesh |
| E19 | `agentpulse` | pulso de agentes |
| E20 | `prismlm` | prisma (múltiples colores) |

### 19.3 Top 5 final

| Rank | Nombre | Estilo | Razón |
|---|---|---|---|
| 1 | `opencode-moa` ⭐ | Paper | Tu elección, paper-aligned |
| 2 | `meshup-oc` | Brand-y | Compacto, memorable |
| 3 | `opencode-mixture-of-agents` | Descriptivo | Searchable |
| 4 | `polycode` | Brand-y | Genérico, brandable |
| 5 | `prismlm` | Brand-y | Visual, único |

---

## 20. Smoke test mínimo

### 20.1 Comando

```
/orquestar "List the 7 colors of the rainbow in order" colors
```

### 20.2 Comportamiento esperado

- Orchestrator reads `orquestador.json` (default with 3 models)
- Validates 3 files `propuesta-{glm,kimi,mimo}.md` exist
- Creates `out/colores/iter-1/`
- Launches 3 parallel `task`
- Each proposal: ~30 lines with "The 7 colors are: red, orange, yellow, green, blue, indigo, violet" + some variation per model
- Step 2 (validation): skipped or runs quickly (low complexity)
- Step 3: evaluator grades the 3 proposals (probably all with high score because the task is trivial)
- Step 4: ranking → winner
- Step 5: improvement → refines the proposals (little margin)
- Steps 7, 8: re-eval and final selection
- Step 9: summary written

### 20.3 Criterios de éxito

- [ ] The command completes without errors
- [ ] 12+ files exist `out/colores/iter-1/*.md`
- [ ] `09-sumario.md` has final score
- [ ] The session log shows steps 0-9 executed

---

## 21. Riesgos y tradeoffs

### 21.1 vs la versión bash del 007

| Aspecto | 007 (bash) | 001 v2 (nativo) | Comentario |
|---|---|---|---|
| Portabilidad | Corre en cualquier Linux con bash 4 | Solo dentro de OpenCode | Tradeoff por diseño |
| Mantenimiento | 12 helpers bash + Makefile + config | 7 agentes + 1 JSON | Menos superficie |
| Testabilidad | `bash -n`, `shellcheck`, unit tests | Smoke tests manuales | Menos riguroso pero más simple |
| Paralelismo | `lib/run-parallel.sh` con `&` y `wait` | Múltiples `task` en una respuesta | Equivalente |
| Métricas | `metrics.jsonl` estructurado con jq | Session log de OpenCode | Menos queryable |
| Concurrencia | Lock files en bash | OpenCode nativo lo gestiona | Mejor |
| Resumabilidad | `FORCE=1` + `step_completed` | Glob + read en orquestador | Equivalente |
| Permisos | Whitelist bash en `validator.md` (100+ líneas) | `permission.bash` con globs (30 líneas) | Más declarativo |
| Config | `orquestador.config` con 17 variables bash | `orquestador.json` con 9 campos + 4 capas merge | Más conciso + flexible |
| Hooks | `lib/hooks.sh` con pre/post por paso | No hay; el orquestador decide en su prompt | Menos flexible |
| CLI shellout | Sí (`opencode run --agent X`) | No (todo via `task`) | Más rápido, menos frágil |
| Config desde VPS | ssh + editar `orquestador.config` | ssh + editar `orquestador.json` (JSON más legible) | Equivalente |

### 21.2 Riesgos nuevos

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| El orquestador "se confunde" leyendo el JSON | Baja | Alto | Validación al inicio con instrucciones claras; abortar si falla |
| El LLM no respeta el orden de pasos | Media | Alto | todowrite + instrucciones explícitas en el prompt del orquestador |
| El validador se queda esperando aprobación de un comando | Alta | Medio | Globs cubren 90% de casos; el 10% requiere interacción humana |
| Iteraciones consumen muchos tokens | Alta | Medio | `max_iteraciones` configurable (default 3); `umbral_convergencia` ayuda a parar pronto |
| El LLM genera IDs inválidos | Baja | Bajo | Regex validation + slugificación fallback |
| Un subagent falla a mitad del flujo | Media | Alto | Reintentar 1 vez; si falla, abortar con instrucción clara |
| El orquestador re-ejecuta pasos innecesariamente | Media | Bajo | Criterios de completitud (líneas mínimas) |
| Múltiples `task` en paralelo saturan el rate limit del provider | Media | Medio | OpenCode nativo gestiona backoff; en casos extremos, reducir `modelos_a_competir` |
| Descalificación opt-in deja pasar propuestas inviables | Baja | Medio | Por default opt-in está en false; el usuario lo activa explícitamente |
| Viabilidad por sección inconsistente entre validadores | Baja | Bajo | Solo hay 1 validador (single-model); no hay inconsistencia |

---

## 22. Lo que esta propuesta NO resuelve

- **Sandbox hermético para validación empírica**. La whitelist bash es primera línea de defensa, pero no garantiza aislamiento. Para producción crítica, ejecutar OpenCode en contenedor Docker.
- **Comparación de costos entre providers**. El orquestador no sabe cuánto cuesta cada modelo. El usuario debe tenerlo en cuenta al elegir `modelos_a_competir`.
- **Reanudación entre máquinas**. Los archivos `out/{id}/` están en el worktree local. Si cambias de máquina, no hay sync. Solución futura: usar git en `out/`.
- **UI gráfica para revisar iteraciones**. El usuario navega `out/{id}/iter-*/` con `read`/`glob`. Una UI dedicada es trabajo futuro.
- **Auto-tuning del umbral de convergencia**. El umbral es estático. Trabajo futuro: calcularlo dinámicamente basado en la varianza de scores.
- **Comparación contra orquestadores externos** (LangGraph, AutoGen). Esta propuesta es específica a OpenCode.
- **Métricas avanzadas** (costo por token, latencia por provider, etc.). El session log de OpenCode es la fuente.
- **Multi-model evaluation**. Decisión consciente basada en evidencia. Si en el futuro se necesita multi-eval, se pueden crear `evaluador-{modelo}.md` adicionales.

---

## 23. Próximos pasos

### 23.1 Para validar esta propuesta

1. Revisar la estructura general (23 secciones).
2. Validar la decisión multi/single-model por rol (sección 3) — basada en evidencia.
3. Validar la lógica de iteración corregida (sección 11).
4. Validar el schema de `orquestador.json` (sección 7).
5. Validar las decisiones V1-V12 (changelog, sección 0).
6. Sugerir cambios si algo no encaja con tu flujo de trabajo.

### 23.2 Para implementar (después de aprobación)

1. Crear el repo `opencode-moa` en GitHub (en inglés).
2. Crear la estructura de directorios en el repo:
   ```
   opencode-moa/
   ├── README.md
   ├── LICENSE
   ├── agents/
   │   ├── orquestador.md
   │   ├── propuesta-glm.md
   │   ├── propuesta-kimi.md
   │   ├── propuesta-mimo.md
   │   ├── evaluador.md
   │   ├── sintetizador.md
   │   └── validador.md
   ├── commands/
   │   ├── orquestar.md
   │   └── orquestar-iterate.md
   ├── orquestador.json
   └── docs/
       ├── installation.md
       ├── configuration.md
       └── examples.md
   ```
3. Publicar con tags `opencode`, `multi-agent`, `mixture-of-agents`, `native-orchestrator`.
4. Instalar user-level en local y en VPS.
5. Smoke test: `/orquestar "List the 7 colors of the rainbow" colors`.
6. Verificar que los 12+ archivos se generan correctamente.
7. Iteración real: `/orquestar-iterate "Design a REST API for inventory" auth-jwt`.

### 23.3 Para extender (futuro)

- Agregar `propuesta-{nuevo_modelo}.md` cuando se quiera incluir un cuarto modelo.
- Cambiar `modelo_objetivo` en `orquestador.json` para usar un modelo distinto en evaluador/validador/sintetizador.
- Crear `.opencode/commands/orquestar-list.md` para listar iteraciones previas (`out/*/iter-*/`).
- Crear `.opencode/commands/orquestar-show.md` para resumir una iteración (`out/{id}/iter-{N}/09-sumario.md`).
- Integrar con git: commitear `out/` después de cada iteración para tener historial.
- Implementar `idioma_output` config (sección 18.4) si hay demanda para español.
- Multi-eval opt-in: crear `evaluador-{modelo}.md` solo si el usuario explícitamente lo pide.

---

*Propuesta 001 v2 de la carpeta 003 (nueva serie nativa OpenCode).*
*Repo objetivo: `opencode-moa` (alineado al paper Mixture-of-Agents).*
*Reemplaza conceptualmente a `002/007-glm-5.1.md` como base para orquestación multi-modelo.*
*Fecha: 2026-07-10.*