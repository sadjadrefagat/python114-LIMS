import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api, formatMoney, roleLabel } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'

export default function Dashboard() {
  const { user, hasRole } = useAuth()
  const [summary, setSummary] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!hasRole('admin', 'secretary', 'finance')) return
    setLoading(true)
    api
      .get('/reports/summary')
      .then(setSummary)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [user])

  return (
    <div className="container py-4">
      <div className="page-head">
        <h1 className="section-title h3 mb-1">سلام {user?.full_name || user?.username}</h1>
        <p className="muted mb-0">نقش شما: {roleLabel(user?.role)}</p>
      </div>

      <div className="row g-3 mb-4">
        <div className="col-md-4">
          <Link to="/courses" className="course-tile d-block">
            <i className="bi bi-journal-bookmark text-success fs-3" />
            <h2 className="h6 fw-bold mt-2 mb-1">کاتالوگ دوره‌ها</h2>
            <p className="muted small mb-0">مشاهده و ثبت دوره</p>
          </Link>
        </div>
        {hasRole('admin', 'secretary') && (
          <>
            <div className="col-md-4">
              <Link to="/languages" className="course-tile d-block">
                <i className="bi bi-translate text-primary fs-3" />
                <h2 className="h6 fw-bold mt-2 mb-1">زبان و سطح</h2>
                <p className="muted small mb-0">ثبت زبان و سطح CEFR</p>
              </Link>
            </div>
            <div className="col-md-4">
              <Link to="/classes" className="course-tile d-block">
                <i className="bi bi-people text-info fs-3" />
                <h2 className="h6 fw-bold mt-2 mb-1">کلاس‌ها و جلسات</h2>
                <p className="muted small mb-0">تشکیل کلاس و زمان‌بندی</p>
              </Link>
            </div>
            <div className="col-md-4">
              <Link to="/teachers" className="course-tile d-block">
                <i className="bi bi-person-workspace text-warning fs-3" />
                <h2 className="h6 fw-bold mt-2 mb-1">مدرسان</h2>
                <p className="muted small mb-0">ثبت و مدیریت مدرس</p>
              </Link>
            </div>
            <div className="col-md-4">
              <Link to="/students" className="course-tile d-block">
                <i className="bi bi-person-lines-fill text-danger fs-3" />
                <h2 className="h6 fw-bold mt-2 mb-1">زبان‌آموزان</h2>
                <p className="muted small mb-0">ثبت و جستجوی فراگیران</p>
              </Link>
            </div>
            <div className="col-md-4">
              <Link to="/enrollments" className="course-tile d-block">
                <i className="bi bi-clipboard-check text-success fs-3" />
                <h2 className="h6 fw-bold mt-2 mb-1">ثبت‌نام‌ها</h2>
                <p className="muted small mb-0">ثبت‌نام در کلاس</p>
              </Link>
            </div>
          </>
        )}
      </div>

      {hasRole('admin', 'secretary', 'finance') && (
        <div className="panel p-3">
          <h2 className="h5 fw-bold section-title mb-3">خلاصه عملیاتی</h2>
          {loading && <Loading />}
          {error && <div className="alert alert-warning">{error}</div>}
          {summary && (
            <div className="row g-3">
              <div className="col-6 col-md-2">
                <div className="stat-box">
                  <div className="small muted">زبان‌آموز</div>
                  <div className="value">{summary.students}</div>
                </div>
              </div>
              <div className="col-6 col-md-2">
                <div className="stat-box">
                  <div className="small muted">مدرس</div>
                  <div className="value">{summary.teachers}</div>
                </div>
              </div>
              <div className="col-6 col-md-2">
                <div className="stat-box">
                  <div className="small muted">دوره</div>
                  <div className="value">{summary.courses}</div>
                </div>
              </div>
              <div className="col-6 col-md-2">
                <div className="stat-box">
                  <div className="small muted">کلاس باز</div>
                  <div className="value">{summary.classes_open}</div>
                </div>
              </div>
              <div className="col-6 col-md-2">
                <div className="stat-box">
                  <div className="small muted">ثبت‌نام فعال</div>
                  <div className="value">{summary.enrollments_active}</div>
                </div>
              </div>
              <div className="col-6 col-md-2">
                <div className="stat-box">
                  <div className="small muted">پرداخت</div>
                  <div className="value" style={{ fontSize: '0.95rem' }}>
                    {formatMoney(summary.payments_paid_total)}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
