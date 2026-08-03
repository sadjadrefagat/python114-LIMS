import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api, formatMoney } from '../api/client'
import Loading from '../components/Loading'
import PaginationBar from '../components/PaginationBar'
import { useClientPagination } from '../hooks/useClientPagination'

export default function TeacherCourses() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const paging = useClientPagination(rows)

  useEffect(() => {
    setLoading(true)
    api
      .get('/me/teaching/courses')
      .then((d) => {
        setRows(d.courses || [])
        setError('')
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div className="container py-4">
      <div className="page-head d-flex flex-wrap justify-content-between gap-2">
        <div>
          <h1 className="section-title h3 mb-1">دوره‌های من</h1>
          <p className="muted mb-0">دوره‌هایی که در آن‌ها کلاس تدریس می‌کنید</p>
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
                <th>دوره</th>
                <th>زبان / سطح</th>
                <th>کلاس‌ها</th>
                <th>فعال</th>
                <th>زبان‌آموزان</th>
                <th>جلسات دوره</th>
                <th>شهریه</th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
                <tr key={row.Id}>
                  <td>
                    <Link to={`/courses/${row.Id}`}>{row.Name}</Link>
                  </td>
                  <td>
                    {row.LanguageName || '—'}
                    {row.LevelName ? ` · ${row.LevelName}` : ''}
                  </td>
                  <td>{row.ClassCount}</td>
                  <td>{row.ActiveClassCount}</td>
                  <td>{row.StudentCount}</td>
                  <td>{row.SessionsCount ?? '—'}</td>
                  <td className="text-nowrap">{formatMoney(row.Cost)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">دوره‌ای یافت نشد.</div>}
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
