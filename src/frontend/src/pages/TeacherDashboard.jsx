import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'

const CLASS_STATUS = {
  draft: 'پیش‌نویس',
  open: 'باز',
  full: 'تکمیل ظرفیت',
  in_progress: 'در حال برگزاری',
  finished: 'پایان‌یافته',
  cancelled: 'لغو شده',
}

const SESSION_STATUS = {
  scheduled: 'برنامه‌ریزی‌شده',
  in_progress: 'در حال برگزاری',
  completed: 'برگزار شده',
  cancelled: 'لغو شده',
  postponed: 'به تعویق',
}

function normalizeTime(t) {
  if (!t) return ''
  const s = String(t)
  return s.length >= 5 ? s.slice(0, 5) : s
}

function StatLink({ to, color, icon, label, value, hint }) {
  return (
    <Link to={to} className={`teacher-stat teacher-stat-${color}`}>
      <span className="teacher-stat-icon" aria-hidden="true">
        <i className={`bi ${icon}`} />
      </span>
      <span className="teacher-stat-meta">
        <span className="teacher-stat-label">{label}</span>
        <strong className="teacher-stat-value">{value}</strong>
        {hint ? <span className="teacher-stat-hint">{hint}</span> : null}
      </span>
      <i className="bi bi-chevron-left teacher-stat-chevron" aria-hidden="true" />
    </Link>
  )
}

/**
 * داشبورد اختصاصی مدرس — کلاس‌ها، دوره‌ها، زبان‌آموزان، حضور و غیاب
 */
export default function TeacherDashboard() {
  const { user } = useAuth()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    api
      .get('/me/teaching/summary')
      .then((res) => {
        if (!cancelled) {
          setData(res)
          setError('')
        }
      })
      .catch((err) => {
        if (!cancelled) setError(err.message)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [])

  if (loading) return <Loading />
  if (error) {
    return <div className="alert alert-warning">{error}</div>
  }

  const stats = data?.stats || {}
  const teacherName =
    data?.teacher
      ? `${data.teacher.FirstName || ''} ${data.teacher.LastName || ''}`.trim()
      : user?.full_name || user?.username

  return (
    <div className="teacher-dash">
      <div className="teacher-dash-hero">
        <div>
          <p className="teacher-dash-kicker">پنل مدرس</p>
          <h2 className="teacher-dash-hello">سلام، {teacherName}</h2>
          <p className="teacher-dash-lead">
            کلاس‌ها، زبان‌آموزان و حضور و غیاب خود را از اینجا پیگیری کنید.
            {data?.teacher?.Specialty ? (
              <>
                {' '}
                تخصص: <strong>{data.teacher.Specialty}</strong>
              </>
            ) : null}
          </p>
        </div>
        <Link to="/teacher/attendance" className="btn btn-brand rounded-pill">
          <i className="bi bi-clipboard-check ms-1" />
          حضور و غیاب
        </Link>
      </div>

      <div className="teacher-stat-grid">
        <StatLink
          to="/teacher/classes"
          color="teal"
          icon="bi-people"
          label="کلاس‌های من"
          value={stats.classes_total ?? 0}
          hint={`${stats.classes_active ?? 0} فعال / جاری`}
        />
        <StatLink
          to="/teacher/courses"
          color="sky"
          icon="bi-journal-bookmark"
          label="دوره‌های من"
          value={stats.courses_total ?? 0}
          hint="دوره‌های مرتبط با کلاس‌ها"
        />
        <StatLink
          to="/teacher/students"
          color="coral"
          icon="bi-mortarboard"
          label="زبان‌آموزان من"
          value={stats.students_total ?? 0}
          hint="ثبت‌نام‌های جاری"
        />
        <StatLink
          to="/teacher/attendance"
          color="amber"
          icon="bi-calendar3"
          label="جلسات پیش‌رو"
          value={stats.sessions_upcoming ?? 0}
          hint={`${stats.attendance_sessions ?? 0} جلسه با حضور ثبت‌شده`}
        />
      </div>

      <div className="row g-4 mt-1">
        <div className="col-lg-6">
          <section className="teacher-panel">
            <div className="teacher-panel-head">
              <h3>کلاس‌های اخیر</h3>
              <Link to="/teacher/classes">همه</Link>
            </div>
            {!data?.classes?.length ? (
              <div className="empty-state py-3">کلاسی به شما اختصاص داده نشده است.</div>
            ) : (
              <ul className="teacher-list">
                {data.classes.map((c) => (
                  <li key={c.Id}>
                    <div>
                      <strong>{c.CourseName}</strong>
                      <span className="muted small d-block">
                        کلاس #{c.Id}
                        {c.SessionTypeName ? ` · ${c.SessionTypeName}` : ''}
                        {c.BranchName ? ` · ${c.BranchName}` : ''}
                      </span>
                    </div>
                    <span className="chip chip-teal">{CLASS_STATUS[c.Status] || c.Status}</span>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>

        <div className="col-lg-6">
          <section className="teacher-panel">
            <div className="teacher-panel-head">
              <h3>جلسات پیش‌رو</h3>
              <Link to="/teacher/attendance">تقویم جلسات</Link>
            </div>
            {!data?.upcoming_sessions?.length ? (
              <div className="empty-state py-3">جلسهٔ برنامه‌ریزی‌شده‌ای نیست.</div>
            ) : (
              <ul className="teacher-list">
                {data.upcoming_sessions.map((s) => (
                  <li key={s.Id}>
                    <div>
                      <strong>{s.CourseName}</strong>
                      <span className="muted small d-block">
                        {s.Date}
                        {s.StartTime || s.EndTime
                          ? ` · ${normalizeTime(s.StartTime) || '—'} تا ${normalizeTime(s.EndTime) || '—'}`
                          : ''}
                      </span>
                    </div>
                    <Link
                      className="btn btn-sm btn-outline-success rounded-pill"
                      to="/sessions"
                      state={{ openAttendance: s.Id }}
                    >
                      حضور
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>

        <div className="col-lg-6">
          <section className="teacher-panel">
            <div className="teacher-panel-head">
              <h3>زبان‌آموزان</h3>
              <Link to="/teacher/students">فهرست کامل</Link>
            </div>
            {!data?.students?.length ? (
              <div className="empty-state py-3">زبان‌آموزی در کلاس‌های شما نیست.</div>
            ) : (
              <ul className="teacher-list">
                {data.students.map((s) => (
                  <li key={`${s.Id}-${s.ClassRef}`}>
                    <div>
                      <strong>
                        {s.FirstName} {s.LastName}
                      </strong>
                      <span className="muted small d-block">
                        {s.CourseName}
                        {s.Mobile ? ` · ${s.Mobile}` : ''}
                      </span>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>

        <div className="col-lg-6">
          <section className="teacher-panel">
            <div className="teacher-panel-head">
              <h3>میانبرها</h3>
            </div>
            <div className="teacher-shortcuts">
              <Link to="/teacher/courses" className="teacher-shortcut">
                <i className="bi bi-journal-bookmark" />
                دوره‌های من
              </Link>
              <Link to="/teacher/classes" className="teacher-shortcut">
                <i className="bi bi-people" />
                کلاس‌های من
              </Link>
              <Link to="/teacher/students" className="teacher-shortcut">
                <i className="bi bi-mortarboard" />
                زبان‌آموزان من
              </Link>
              <Link to="/teacher/attendance" className="teacher-shortcut">
                <i className="bi bi-clipboard-check" />
                حضور و غیاب
              </Link>
              <Link to="/sessions" className="teacher-shortcut">
                <i className="bi bi-calendar3" />
                همه جلسات
              </Link>
              <Link to="/scores" className="teacher-shortcut">
                <i className="bi bi-clipboard2-data" />
                نمرات
              </Link>
              <Link to="/placement/bank" className="teacher-shortcut">
                <i className="bi bi-ui-checks-grid" />
                مخزن تعیین سطح
              </Link>
            </div>
          </section>
        </div>
      </div>
    </div>
  )
}

export { CLASS_STATUS, SESSION_STATUS, normalizeTime }
