import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../api/client'
import Loading from '../components/Loading'
import PaginationBar from '../components/PaginationBar'
import { useClientPagination } from '../hooks/useClientPagination'
import { CLASS_STATUS } from './TeacherDashboard'

export default function TeacherClasses() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const paging = useClientPagination(rows)

  useEffect(() => {
    setLoading(true)
    api
      .get('/me/teaching/classes')
      .then((d) => {
        setRows(d.classes || [])
        setError('')
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div className="container py-4">
      <div className="page-head d-flex flex-wrap justify-content-between gap-2">
        <div>
          <h1 className="section-title h3 mb-1">کلاس‌های من</h1>
          <p className="muted mb-0">کلاس‌هایی که به شما به‌عنوان مدرس اختصاص داده شده‌اند</p>
        </div>
        <Link to="/dashboard" className="btn btn-outline-secondary rounded-pill">
          بازگشت به داشبورد
        </Link>
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
                <th>نوع جلسه</th>
                <th>ظرفیت</th>
                <th>ثبت‌نام</th>
                <th>بازه</th>
                <th>وضعیت</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.CourseName}</td>
                  <td>{row.SessionTypeName || '—'}</td>
                  <td>{row.Capacity}</td>
                  <td>{row.EnrolledCount ?? '—'}</td>
                  <td className="small text-nowrap">
                    {row.StartDate || '—'} تا {row.EndDate || '—'}
                  </td>
                  <td>
                    <span className="chip chip-teal">{CLASS_STATUS[row.Status] || row.Status}</span>
                  </td>
                  <td>
                    <Link
                      className="btn btn-sm btn-outline-success rounded-pill"
                      to="/teacher/students"
                      state={{ classRef: row.Id }}
                    >
                      زبان‌آموزان
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">کلاسی یافت نشد.</div>}
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
