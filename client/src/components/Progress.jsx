import { useEffect, useState } from 'react'
import { fetchProgress } from '../api.js'

const COMPETENCY_ORDER = ['RES', 'DIR', 'TAL', 'CUL', 'CRA']
const COMPETENCY_NAMES = {
  RES: 'Results',
  DIR: 'Direction',
  TAL: 'Talent',
  CUL: 'Culture',
  CRA: 'Craft',
}

export default function Progress({ personId }) {
  const [data, setData] = useState(null)
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!personId) return

    let cancelled = false
    setLoading(true)
    setError(null)

    fetchProgress(personId)
      .then((result) => {
        if (!cancelled) setData(result)
      })
      .catch(() => {
        if (!cancelled) setError('Could not load progress.')
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })

    return () => {
      cancelled = true
    }
  }, [personId])

  if (loading) {
    return (
      <section className="panel">
        <h2>Progress</h2>
        <p className="muted">Loading…</p>
      </section>
    )
  }

  if (error) {
    return (
      <section className="panel">
        <h2>Progress</h2>
        <p className="empty-state">{error}</p>
      </section>
    )
  }

  if (!data) return null

  const byCompetency = data.current?.by_competency ?? []
  const rows = COMPETENCY_ORDER.map((code) => byCompetency.find((row) => row.competency === code)).filter(
    Boolean,
  )

  return (
    <section className="panel">
      <header className="panel-header">
        <h2>Progress</h2>
        {data.current?.cycle_label && <p className="cycle-label">{data.current.cycle_label}</p>}
      </header>

      {rows.length === 0 ? (
        <p className="empty-state">At the top of the framework — no next-level criteria to track.</p>
      ) : (
        <div className="progress-bars">
          {rows.map((row) => (
            <div key={row.competency} className="progress-bar-row">
              <span className="progress-bar-label">
                {row.competency} — {COMPETENCY_NAMES[row.competency]}
              </span>
              <div className="progress-bar-track">
                <div
                  className="progress-bar-fill"
                  style={{ width: `${row.total ? (row.covered / row.total) * 100 : 0}%` }}
                />
              </div>
              <span className="progress-bar-count">
                {row.covered}/{row.total}
              </span>
            </div>
          ))}
        </div>
      )}

      {data.history.length > 1 && (
        <div className="progress-history">
          <h3 className="narrative-heading">Across cycles</h3>
          <div className="history-points">
            {data.history.map((point) => (
              <div key={point.cycle_label} className="history-point">
                <span className="history-point-value">
                  {point.covered}/{point.total}
                </span>
                <span className="history-point-label">{point.cycle_label}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </section>
  )
}
