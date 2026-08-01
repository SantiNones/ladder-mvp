# S4 — Narrative generate → validate → persist → serve

How a deterministic narrative is built from an already-filtered payload,
validated against the SPEC §7 schema, persisted on the snapshot (D14),
and served unchanged on `GET /snapshots/:id`. No real LLM call (D15).

```mermaid
sequenceDiagram
  participant Rake as narrative_generate
  participant VR as VisibilityResolver
  participant PPB as PromptPayloadBuilder
  participant NG as NarrativeGenerator
  participant DB as Snapshot
  participant GET as SnapshotsController

  Rake->>VR: Ana viewing Ana
  VR->>PPB: filtered visible set
  PPB->>NG: prompt_payload
  NG->>NG: template then validate
  alt invalid or error
    NG->>NG: deterministic fallback
  end
  NG->>DB: save narrative plus prompt_payload
  GET->>DB: read stored columns
  Note over GET: never rebuild prompt_payload once present
```
