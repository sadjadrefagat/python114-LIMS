import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'

const PAGE_SIZE = 20

/** زمان ذخیره‌شده UTC است؛ برای نمایش به وقت ایران تبدیل می‌شود */
function formatWhen(value) {
  if (!value) return '—'
  const raw = String(value).trim()
  let date
  if (/Z$/i.test(raw) || /[+-]\d{2}:?\d{2}$/.test(raw)) {
    date = new Date(raw)
  } else {
    const iso = raw.includes('T') ? raw : raw.replace(' ', 'T')
    const cleaned = iso.replace(/(\.\d{1,7})$/, '')
    date = new Date(`${cleaned}Z`)
  }
  if (Number.isNaN(date.getTime())) {
    return raw.replace('T', ' ').slice(0, 19)
  }
  // YYYY-MM-DD HH:mm:ss به وقت تهران
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Tehran',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).formatToParts(date)
  const get = (type) => parts.find((p) => p.type === type)?.value || ''
  return `${get('year')}/${get('month')}/${get('day')} ${get('hour')}:${get('minute')}:${get('second')}`
}

export default function Activities() {
  const [rows, setRows] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [actionCode, setActionCode] = useState('')
  const [entityType, setEntityType] = useState('')
  const [actionLabels, setActionLabels] = useState({})
  const [entityLabels, setEntityLabels] = useState({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const t = setTimeout(async () => {
      setLoading(true)
      try {
        const params = new URLSearchParams()
        params.set('limit', String(PAGE_SIZE))
        params.set('offset', String((page - 1) * PAGE_SIZE))
        if (search.trim()) params.set('search', search.trim())
        if (actionCode) params.set('action_code', actionCode)
        if (entityType) params.set('entity_type', entityType)
        const data = await api.get(`/activities?${params}`)
        setRows(data.activities || [])
        setTotal(data.total || 0)
        setActionLabels(data.action_labels || {})
        setEntityLabels(data.entity_labels || {})
        setError('')
      } catch (err) {
        setError(err.message)
        setRows([])
      } finally {
        setLoading(false)
      }
    }, 250)
    return () => clearTimeout(t)
  }, [search, actionCode, entityType, page])

  useEffect(() => {
    setPage(1)
  }, [search, actionCode, entityType])

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE) || 1)
  const from = total === 0 ? 0 : (page - 1) * PAGE_SIZE + 1
  const to = Math.min(page * PAGE_SIZE, total)

  const actionOptions = [
    { value: '', label: 'همه عملیات' },
    ...Object.entries(actionLabels).map(([value, label]) => ({ value, label })),
  ]
  const entityOptions = [
    { value: '', label: 'همه موجودیت‌ها' },
    ...Object.entries(entityLabels).map(([value, label]) => ({ value, label })),
  ]

  return (
    <div className="container py-4">
      <div className="page-head d-flex justify-content-between flex-wrap gap-2 align-items-start">
        <div>
          <p className="page-kicker">مدیریت</p>
          <h1 className="section-title h3 mb-1">فعالیت‌ها و لاگ سامانه</h1>
          <p className="muted mb-0">ورود، ایجاد، ویرایش و حذف عملیات کاربران · زمان‌ها به وقت ایران</p>
        </div>
      </div>

      <div className="card border-0 shadow-sm mb-3">
        <div className="card-body">
          <div className="row g-3 align-items-end">
            <div className="col-md-4">
              <label className="form-label">جستجو</label>
              <input
                className="form-control"
                placeholder="پیام، کاربر، مسیر…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">نوع عملیات</label>
              <VazirSelect value={actionCode} onChange={setActionCode} options={actionOptions} />
            </div>
            <div className="col-md-3">
              <label className="form-label">موجودیت</label>
              <VazirSelect value={entityType} onChange={setEntityType} options={entityOptions} />
            </div>
            <div className="col-md-2">
              <button
                type="button"
                className="btn btn-outline-secondary w-100"
                onClick={() => {
                  setSearch('')
                  setActionCode('')
                  setEntityType('')
                }}
              >
                پاک کردن
              </button>
            </div>
          </div>
        </div>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}
      {loading ? (
        <Loading />
      ) : (
        <div className="panel table-responsive">
          <table className="table table-hover table-zebra mb-0 align-middle">
            <thead>
              <tr>
                <th>#</th>
                <th>زمان</th>
                <th>کاربر</th>
                <th>عملیات</th>
                <th>موجودیت</th>
                <th>پیام</th>
                <th>متد</th>
                <th>کد</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td className="small text-nowrap">{formatWhen(row.CreatedAt)}</td>
                  <td>{row.Username || (row.UserRef ? `#${row.UserRef}` : '—')}</td>
                  <td>
                    <span className="chip chip-teal">
                      {actionLabels[row.ActionCode] || row.ActionCode}
                    </span>
                  </td>
                  <td>{entityLabels[row.EntityType] || row.EntityType || '—'}</td>
                  <td>
                    <div>{row.Message}</div>
                    {row.Path && <div className="small text-muted">{row.Path}</div>}
                  </td>
                  <td className="small">{row.Method || '—'}</td>
                  <td>
                    <span
                      className={`badge ${
                        row.StatusCode >= 400 ? 'text-bg-danger' : 'text-bg-success'
                      }`}
                    >
                      {row.StatusCode ?? '—'}
                    </span>
                  </td>
                </tr>
              ))}
              {!rows.length && (
                <tr>
                  <td colSpan={8} className="text-center muted py-4">
                    هنوز فعالیتی ثبت نشده است. با کار در سامانه لاگ ساخته می‌شود.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
          <PaginationBar
            page={page}
            totalPages={totalPages}
            total={total}
            pageSize={PAGE_SIZE}
            from={from}
            to={to}
            onChange={setPage}
          />
        </div>
      )}
    </div>
  )
}
