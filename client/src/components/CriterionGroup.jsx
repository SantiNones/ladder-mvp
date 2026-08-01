import { useState } from 'react'
import StatusChip from './StatusChip.jsx'

function EvidenceList({ evidence }) {
  if (!evidence?.length) {
    return <p className="evidence-empty">No evidence recorded for this criterion.</p>
  }

  return (
    <ul className="evidence-list">
      {evidence.map((item) => (
        <li key={item.id} className="evidence-item">
          <div className="evidence-meta">
            <span>{item.author_relation}</span>
            <span>{item.source_type}</span>
            {item.occurred_on && <span>{item.occurred_on}</span>}
          </div>
          <p>{item.body}</p>
        </li>
      ))}
    </ul>
  )
}

function CriterionRow({ criterion, status }) {
  const [open, setOpen] = useState(false)
  const evidence = criterion.evidence ?? []

  return (
    <article className="criterion-row">
      <button
        type="button"
        className="criterion-toggle"
        onClick={() => setOpen((value) => !value)}
        aria-expanded={open}
      >
        <span className="criterion-code">{criterion.code}</span>
        <StatusChip status={status} />
        <span className="criterion-chevron">{open ? '▾' : '▸'}</span>
      </button>
      <p className="criterion-text">{criterion.text}</p>
      {open && <EvidenceList evidence={evidence} />}
    </article>
  )
}

const COMPETENCY_ORDER = ['RES', 'DIR', 'TAL', 'CUL', 'CRA']
const COMPETENCY_NAMES = {
  RES: 'Results',
  DIR: 'Direction',
  TAL: 'Talent',
  CUL: 'Culture',
  CRA: 'Craft',
}

export default function CriterionGroup({ criteriaByCompetency }) {
  return (
    <div className="competency-groups">
      {COMPETENCY_ORDER.map((competency) => {
        const rows = criteriaByCompetency[competency] ?? []
        if (rows.length === 0) return null

        return (
          <section key={competency} className="competency-group">
            <h3>
              {competency} — {COMPETENCY_NAMES[competency]}
            </h3>
            {rows.map(({ criterion, status }) => (
              <CriterionRow
                key={criterion.criterion_id}
                criterion={criterion}
                status={status}
              />
            ))}
          </section>
        )
      })}
    </div>
  )
}
