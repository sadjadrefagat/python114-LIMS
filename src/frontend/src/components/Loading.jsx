export default function Loading({ text = 'در حال بارگذاری...' }) {
  return (
    <div className="text-center py-5 muted">
      <div className="spinner-border" style={{ color: '#0f9d8a' }} role="status" />
      <div className="mt-2">{text}</div>
    </div>
  )
}
