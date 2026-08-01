export default function MyTeam({ reports, onOpenLadder }) {
  return (
    <section className="panel">
      <header className="panel-header">
        <h2>My team</h2>
        <p className="muted">Direct reports · alphabetical</p>
      </header>

      {reports.length === 0 ? (
        <p className="empty-state">No direct reports.</p>
      ) : (
        <ul className="team-list">
          {reports.map((report) => {
            const hasSnapshot = report.latest_snapshot_id != null
            return (
              <li key={report.id} className="team-row">
                <div>
                  <p className="team-name">{report.name}</p>
                  {hasSnapshot ? (
                    <p className="team-meta">
                      {report.cycle_label}: {report.covered}/{report.total} covered
                    </p>
                  ) : (
                    <p className="team-meta">No closed cycle yet</p>
                  )}
                </div>
                {hasSnapshot ? (
                  <button
                    type="button"
                    className="link-button"
                    onClick={() => onOpenLadder(report.latest_snapshot_id)}
                  >
                    Open ladder
                  </button>
                ) : (
                  <span className="muted">—</span>
                )}
              </li>
            )
          })}
        </ul>
      )}
    </section>
  )
}
