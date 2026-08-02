import { useEffect, useMemo, useState } from 'react'
import { fetchSnapshot } from '../api.js'
import CriterionGroup from './CriterionGroup.jsx'

function levelName(position) {
  return `IC${position} Software Engineer`
}

function groupCriteria(snapshot) {
  const byCompetency = {}

  for (const row of snapshot.met ?? []) {
    const competency = row.competency
    byCompetency[competency] ??= []
    byCompetency[competency].push({ criterion: row, status: 'met' })
  }

  for (const row of snapshot.gap ?? []) {
    const competency = row.competency
    byCompetency[competency] ??= []
    byCompetency[competency].push({
      criterion: row,
      status: row.state ?? 'empty',
    })
  }

  return byCompetency
}

export default function MyLadder({ personId, snapshotId, viewerName }) {
  const [snapshot, setSnapshot] = useState(null)
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)
  const [showTrace, setShowTrace] = useState(false)

  useEffect(() => {
    if (!snapshotId) {
      setSnapshot(null)
      setError(null)
      setLoading(false)
      setShowTrace(false)
      return
    }

    let cancelled = false
    setLoading(true)
    setError(null)
    setShowTrace(false)

    fetchSnapshot(snapshotId, personId)
      .then((data) => {
        if (!cancelled) setSnapshot(data)
      })
      .catch((err) => {
        if (!cancelled) {
          setSnapshot(null)
          setError(err.status === 404 ? 'Snapshot not found.' : 'Could not load ladder.')
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })

    return () => {
      cancelled = true
    }
  }, [personId, snapshotId])

  const grouped = useMemo(
    () => (snapshot ? groupCriteria(snapshot) : {}),
    [snapshot],
  )

  if (!snapshotId) {
    return (
      <section className="panel">
        <h2>My ladder</h2>
        <p className="empty-state">No closed cycle yet.</p>
      </section>
    )
  }

  if (loading) {
    return (
      <section className="panel">
        <h2>My ladder</h2>
        <p className="muted">Loading…</p>
      </section>
    )
  }

  if (error) {
    return (
      <section className="panel">
        <h2>My ladder</h2>
        <p className="empty-state">{error}</p>
      </section>
    )
  }

  if (!snapshot) return null

  const viewingOther = viewerName && snapshot.person_name !== viewerName
  const narrative = snapshot.narrative
  const noNextLevel =
    (snapshot.met?.length ?? 0) === 0 && (snapshot.gap?.length ?? 0) === 0

  return (
    <section className="panel">
      <header className="panel-header">
        <div>
          <h2>{viewingOther ? 'Ladder' : 'My ladder'}</h2>
          {viewingOther && (
            <p className="subject-label">Viewing {snapshot.person_name}</p>
          )}
        </div>
        <p className="cycle-label">{snapshot.cycle_label}</p>
      </header>

      <div className="level-row">
        <div>
          <span className="level-caption">Current level</span>
          <p className="level-value">
            {noNextLevel
              ? `Level ${snapshot.level_position_at_close}`
              : levelName(snapshot.level_position_at_close)}
          </p>
        </div>
        <div>
          <span className="level-caption">Target level</span>
          <p className="level-value">
            {noNextLevel
              ? 'No next level defined for this role'
              : levelName(snapshot.target_level_position)}
          </p>
        </div>
      </div>

      {noNextLevel && (
        <p className="empty-state">
          This framework only covers the Software Engineer IC track — there&rsquo;s
          no next level defined here.
        </p>
      )}

      {narrative && (
        <div className="narrative-block">
          <h3 className="narrative-heading">Narrative</h3>
          <p className="narrative-summary">{narrative.summary}</p>
          {narrative.focus_competency && (
            <p className="narrative-focus">
              Focus competency: <strong>{narrative.focus_competency}</strong>
            </p>
          )}
          {Array.isArray(narrative.next_steps) && narrative.next_steps.length > 0 && (
            <ul className="next-steps">
              {narrative.next_steps.map((step) => (
                <li key={step.criterion_code}>
                  <span className="next-step-code">{step.criterion_code}</span>
                  {step.suggestion}
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      <CriterionGroup criteriaByCompetency={grouped} />

      {snapshot.prompt_payload && (
        <div className="trace-panel">
          <p className="trace-caption">
            Exactly what the model received — no current level, no names, no
            other person&rsquo;s data. The gap state you see below (met,
            uncorroborated, empty) was already computed before the model ran
            — it can only describe it, never set it.
          </p>
          <button
            type="button"
            className="trace-toggle"
            onClick={() => setShowTrace((open) => !open)}
            aria-expanded={showTrace}
          >
            {showTrace ? 'Hide what the model received' : 'See what the model received'}
          </button>
          {showTrace && (
            <pre className="trace-payload">
              {JSON.stringify(snapshot.prompt_payload, null, 2)}
            </pre>
          )}
        </div>
      )}
    </section>
  )
}
