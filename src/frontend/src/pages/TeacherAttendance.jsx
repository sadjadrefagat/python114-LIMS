import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'
import { useClientPagination } from '../hooks/useClientPagination'
import { SESSION_STATUS, normalizeTime } from './TeacherDashboard'

export default function TeacherAttendance() {
  const [rows, setRows] = useState([])
  const [classes, setClasses] = useState([])
  const [classRef, setClassRef] = useState('')
  const [status, setStatus] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const paging = useClientPagination(rows)

  useEffect(() => {
    api
      .get('/me/teaching/classes')
      .then((d) => setClasses(d.classes || []))
      .catch(() => setClasses([]))
  }, [])

  useEffect(() => {
    setLoading(true)
    const qs = new URLSearchParams()
    if (classRef) qs.set('class_ref', classRef)
    if (status) qs.set('status', status)
    api
      .get(`/me/teaching/sessions${qs.toString() ? `?${qs}` : ''}`)
      .then((d) => {
        setRows(d.sessions || [])
        setError('')
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [classRef, status])

  const classOptions = useMemo(
    () => [
      { value: '', label: 'همه کلاس‌ها' },
      ...classes.map((c) => ({
        value: String(c.Id),
        label: `#${c.Id} — ${c.CourseName}`,
      })),
    ],
    [classes],
  )

  return (
    <div className="container py-4">
      <div className="page-head d-flex flex-wrap justify-content-between gap-2">
        <div>
          <h1 className="section-title h3 mb-1">حضور و غیاب / جلسات من</h1>
          <p className="muted mb-0">جلسات کلاس‌های شما برای ثبت و پیگیری حضور</p>
        </div>
        <div className="d-flex gap-2">
          <Link to="/sessions" className="btn btn-brand rounded-pill">
            مدیریت جلسات
          </Link>
          <Link to="/dashboard" className="btn btn-outline-secondary rounded-pill">
            داشبورد
          </Link>
        </div>
      </div>

      <div className="d-flex flex-wrap gap-2 mb-3">
        <div style={{ minWidth: 220 }}>
          <VazirSelect value={classRef} onChange={setClassRef} options={classOptions} />
        </div>
        <div style={{ minWidth: 180 }}>
          <VazirSelect
            value={status}
            onChange={setStatus}
            options={[
              { value: '', label: 'همه وضعیت‌ها' },
              ...Object.entries(SESSION_STATUS).map(([value, label]) => ({ value, label })),
            ]}
          />
        </div>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}
      {loading ? (
        <Loading />
      ) : (
        <div className="panel table-responsive">
          <table className="table table-zebra mb-0 align-middle">
            <thead>
              <tr>
                <th>کد</th>
                <th>دوره</th>
                <th>کلاس</th>
                <th>تاریخ</th>
                <th>ساعت</th>
                <th>نوع</th>
                <th>وضعیت</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.CourseName}</td>
                  <td>#{row.ClassRef}</td>
                  <td>{row.Date}</td>
                  <td className="text-nowrap">
                    {normalizeTime(row.StartTime) || '—'} تا {normalizeTime(row.EndTime) || '—'}
                  </td>
                  <td>{row.SessionTypeName || '—'}</td>
                  <td>
                    <span className="chip chip-teal">{SESSION_STATUS[row.Status] || row.Status}</span>
                  </td>
                  <td>
                    <Link
                      className="btn btn-sm btn-outline-success rounded-pill"
                      to="/sessions"
                      state={{ openAttendance: row.Id }}
                    >
                      حضور و غیاب
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">جلسه‌ای یافت نشد.</div>}
          <PaginationBar
            page={paging.page}
            totalPages={paging.totalPages}
            total={paging.total}
            pageSize={paging.pageSize}
            from={paging.from}
            to={paging.to}
            onChange={paging.setPage}
          />
        </div>
      )}
    </div>
  )
}
