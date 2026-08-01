# S3 — UI data flow

How the lens bar bootstraps via `GET /me`, then loads a ladder through
`GET /snapshots/:id` with the same `X-Person-Id`. Visibility stays on the
server — React only chooses which snapshot id to request.

```mermaid
sequenceDiagram
  participant UI
  participant MeController
  participant SnapshotsController
  participant VisibilityResolver

  UI->>MeController: GET /me X-Person-Id
  MeController-->>UI: self plus alphabetical reports summaries
  alt MyLadder
    UI->>SnapshotsController: GET /snapshots/:id X-Person-Id
    SnapshotsController->>VisibilityResolver: viewer subject snapshot
    VisibilityResolver-->>SnapshotsController: filtered set
    SnapshotsController-->>UI: ladder JSON
  else MyTeam open report
    UI->>SnapshotsController: GET /snapshots/reportLatestId X-Person-IdLaura
    SnapshotsController->>VisibilityResolver: Laura as viewer
    SnapshotsController-->>UI: Ana ladder JSON or 404
  end
```
