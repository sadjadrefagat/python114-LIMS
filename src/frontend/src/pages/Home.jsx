import { Link } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { api, formatMoney } from '../api/client'
import Loading from '../components/Loading'

export default function Home() {
  const [courses, setCourses] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api
      .get('/courses?highlighted_only=true')
      .then((data) => {
        const list = data.courses || []
        if (list.length) setCourses(list.slice(0, 3))
        else {
          return api.get('/courses').then((all) => setCourses((all.courses || []).slice(0, 3)))
        }
      })
      .catch(() => setCourses([]))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div>
      <section className="hero">
        <div className="hero-glow" />
        <div className="container">
          <div className="row align-items-center g-4">
            <div className="col-lg-6 fade-up">
              <div className="chip chip-coral mb-3">آموزشگاه زبان لیمز</div>
              <h1 className="hero-title">یادگیری زبان، ساده و منظم</h1>
              <p className="hero-text">
                از ثبت‌نام تا کلاس و پیشرفت تحصیلی، همه‌چیز در یک سامانه روشن و فارسی.
                دوره‌های حضوری و آنلاین با مدرسان مجرب.
              </p>
              <div className="d-flex flex-wrap gap-2 mt-4">
                <Link to="/courses" className="btn btn-brand btn-lg rounded-pill px-4">
                  مشاهده دوره‌ها
                </Link>
                <Link to="/register" className="btn btn-accent btn-lg rounded-pill px-4">
                  ثبت‌نام
                </Link>
                <Link to="/login" className="btn btn-outline-success btn-lg rounded-pill px-4">
                  ورود
                </Link>
              </div>
            </div>
            <div className="col-lg-6 fade-up-delay">
              <div className="hero-visual">
                <div className="chip chip-sky mb-3 bg-white text-dark">CEFR · حضوری · آنلاین</div>
                <h2 className="h3 fw-bold mb-2">مسیر یادگیری شفاف</h2>
                <p className="mb-0 opacity-90">
                  کاتالوگ دوره، کلاس‌بندی، حضور و غیاب و گزارش پیشرفت — همگی یکپارچه.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="container pb-5">
        <div className="d-flex justify-content-between align-items-end mb-3">
          <div>
            <h2 className="section-title h4 mb-1">دوره‌های منتخب</h2>
            <p className="muted mb-0">شروع سریع مسیر زبان‌آموزی</p>
          </div>
          <Link to="/courses" className="btn btn-sm btn-outline-success rounded-pill">
            همه دوره‌ها
          </Link>
        </div>

        {loading ? (
          <Loading />
        ) : (
          <div className="row g-3">
            {courses.map((course) => (
              <div className="col-md-4" key={course.Id}>
                <div className="course-tile">
                  <div className="d-flex justify-content-between mb-2">
                    <span className="chip chip-teal">{course.LanguageName}</span>
                    {course.IsHighlighted ? <span className="chip chip-coral">پیشنهادی</span> : null}
                  </div>
                  <h3 className="h5 fw-bold">{course.Name}</h3>
                  <p className="muted small mb-3">
                    {course.LevelName || 'سطح آزاد'} · {course.SessionsCount} جلسه
                  </p>
                  <div className="fw-bold text-success mb-3">{formatMoney(course.Cost)}</div>
                  <div className="d-flex gap-2">
                    <Link to={`/courses/${course.Id}`} className="btn btn-sm btn-outline-success rounded-pill">
                      جزئیات
                    </Link>
                    <Link to={`/courses/${course.Id}#enroll`} className="btn btn-sm btn-brand rounded-pill">
                      ثبت‌نام
                    </Link>
                  </div>
                </div>
              </div>
            ))}
            {!courses.length && <div className="empty-state">هنوز دوره‌ای ثبت نشده است.</div>}
          </div>
        )}
      </section>
    </div>
  )
}
