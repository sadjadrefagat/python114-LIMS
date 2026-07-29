import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { api, formatMoney } from '../api/client'
import Loading from '../components/Loading'

export default function CourseDetail() {
  const { id } = useParams()
  const [course, setCourse] = useState(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setLoading(true)
    api
      .get(`/courses/${id}`)
      .then((data) => setCourse(data.course))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [id])

  if (loading) return <Loading />
  if (error) {
    return (
      <div className="container py-5">
        <div className="alert alert-danger">{error}</div>
        <Link to="/courses">بازگشت</Link>
      </div>
    )
  }
  if (!course) return null

  return (
    <div className="container py-4">
      <Link to="/courses" className="text-success small">
        ← بازگشت به دوره‌ها
      </Link>
      <div className="panel p-4 mt-3 fade-up">
        <div className="d-flex flex-wrap gap-2 mb-3">
          <span className="chip chip-teal">{course.LanguageName}</span>
          {course.LevelName && <span className="chip chip-sky">{course.LevelName}</span>}
          {course.IsHighlighted ? <span className="chip chip-coral">پیشنهادی</span> : null}
        </div>
        <h1 className="h3 fw-bold section-title">{course.Name}</h1>
        <p className="muted">{course.Description || 'توضیحات تکمیلی برای این دوره ثبت نشده است.'}</p>
        <div className="row g-3 mt-2">
          <div className="col-md-3">
            <div className="stat-box">
              <div className="small muted">شهریه</div>
              <div className="value" style={{ fontSize: '1.15rem' }}>
                {formatMoney(course.Cost)}
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="stat-box">
              <div className="small muted">تعداد جلسات</div>
              <div className="value">{course.SessionsCount}</div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="stat-box">
              <div className="small muted">مدت (ساعت)</div>
              <div className="value">{course.DurationHours ?? '—'}</div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="stat-box">
              <div className="small muted">روش تدریس</div>
              <div className="value" style={{ fontSize: '1rem' }}>
                {course.TeachingMethod || '—'}
              </div>
            </div>
          </div>
        </div>
        {course.Syllabus && (
          <div className="mt-4">
            <h2 className="h6 fw-bold">سرفصل</h2>
            <p className="mb-0" style={{ whiteSpace: 'pre-wrap' }}>
              {course.Syllabus}
            </p>
          </div>
        )}
      </div>
    </div>
  )
}
