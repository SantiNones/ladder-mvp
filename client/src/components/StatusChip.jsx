const LABELS = {
  met: 'met',
  uncorroborated: 'uncorroborated',
  empty: 'empty',
}

export default function StatusChip({ status }) {
  const label = LABELS[status] ?? status
  return <span className={`status-chip status-chip--${status}`}>{label}</span>
}
