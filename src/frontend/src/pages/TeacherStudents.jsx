import { useEffect, useMemo, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'
import { useClientPagination } from '../hooks/useClientPagination'

const ENROLL_STATUS = {
  pending_payment: 'در انتظار پرداخت',
  pending_approval: 'در انتظار تأیید',
  active: 'فعال',
  frozen: 'معلق',
}

export default function TeacherStudents() {
  const location = useLocation()
  const initialClass = location.state?.classRef ? String(location.state.classRef) : ''
  const [rows, setRows] = useState([])
  const [classes, setClasses] = useState([])
  const [classRef, setClassRef] = useState(initialClass)
  const [search, setSearch] = useState('')
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
    if (search.trim()) qs.set('search', search.trim())
    api
      .get(`/me/teaching/students${qs.toString() ? `?${qs}` : ''}`)
      .then((d) => {
        setRows(d.students || [])
        setError('')
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [classRef, search])

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
          <h1 className="section-title h3 mb-1">زبان‌آموزان من</h1>
          <p className="muted mb-0">زبان‌آموزان ثبت‌نام‌شده در کلاس‌های شما</p>
        </div>
        <Link to="/dashboard" className="btn btn-outline-secondary rounded-pill">
          بازگشت به داشبورد
        </Link>
      </div>

      <div className="d-flex flex-wrap gap-2 mb-3">
        <input
          className="form-control"
          style={{ maxWidth: 240 }}
          placeholder="جستجوی نام، موبایل، دوره…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <div style={{ minWidth: 220 }}>
          <VazirSelect value={classRef} onChange={setClassRef} options={classOptions} />
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
                <th>نام</th>
                <th>موبایل</th>
                <th>دوره</th>
                <th>کلاس</th>
                <th>وضعیت ثبت‌نام</th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
                <tr key={`${row.Id}-${row.EnrollmentId}`}>
                  <td>
                    {row.FirstName} {row.LastName}
                  </td>
                  <td>{row.Mobile || '—'}</td>
                  <td>
                    {row.CourseName}
                    {row.LevelName ? (
                      <span className="muted small d-block">{row.LevelName}</span>
                    ) : null}
                  </td>
                  <td>#{row.ClassRef}</td>
                  <td>
                    <span className="chip chip-teal">
                      {ENROLL_STATUS[row.EnrollmentStatus] || row.EnrollmentStatus}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">زبان‌آموزی یافت نشد.</div>}
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
