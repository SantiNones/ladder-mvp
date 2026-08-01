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

  useEffect(() => {
    if (!snapshotId) {
      setSnapshot(null)
      setError(null)
      setLoading(false)
      return
    }

    let cancelled = false
    setLoading(true)
    setError(null)

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
            {levelName(snapshot.level_position_at_close)}
          </p>
        </div>
        <div>
          <span className="level-caption">Target level</span>
          <p className="level-value">
            {levelName(snapshot.target_level_position)}
          </p>
        </div>
      </div>

      <CriterionGroup criteriaByCompetency={grouped} />
    </section>
  )
}
