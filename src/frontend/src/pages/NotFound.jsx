import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const PUBLIC_LINKS = [
  { to: '/', label: 'صفحه اصلی', icon: 'bi-house' },
  { to: '/courses', label: 'دوره‌ها', icon: 'bi-journal-bookmark' },
  { to: '/about', label: 'درباره ما', icon: 'bi-people' },
  { to: '/login', label: 'ورود', icon: 'bi-box-arrow-in-left' },
]

const STAFF_LINKS = [
  { to: '/dashboard', label: 'داشبورد', icon: 'bi-speedometer2' },
  { to: '/students', label: 'زبان‌آموزان', icon: 'bi-mortarboard' },
  { to: '/enrollments', label: 'ثبت‌نام‌ها', icon: 'bi-clipboard-check' },
]

export default function NotFound() {
  const navigate = useNavigate()
  const { isAuthenticated, hasRole } = useAuth()
  const isStaff = hasRole('admin', 'secretary')

  function goBack() {
    if (window.history.length > 1) navigate(-1)
    else navigate('/', { replace: true })
  }

  const links = [
    ...PUBLIC_LINKS.filter((l) => !(isAuthenticated && l.to === '/login')),
    ...(isStaff ? STAFF_LINKS : []),
  ]

  return (
    <div className="not-found-page">
      <div className="container not-found-inner fade-up">
        <p className="not-found-code" aria-hidden="true">
          404
        </p>
        <h1 className="not-found-title">صفحه پیدا نشد</h1>
        <p className="not-found-text">
          آدرسی که وارد کرده‌اید وجود ندارد یا جابه‌جا شده است. می‌توانید به صفحهٔ قبل برگردید یا
          از میانبرهای زیر استفاده کنید.
        </p>

        <div className="not-found-actions">
          <button type="button" className="btn btn-brand btn-lg rounded-pill px-4" onClick={goBack}>
            <i className="bi bi-arrow-right ms-1" aria-hidden="true" />
            بازگشت به صفحه قبل
          </button>
          <Link to="/" className="btn btn-outline-success btn-lg rounded-pill px-4">
            <i className="bi bi-house ms-1" aria-hidden="true" />
            صفحه اصلی
          </Link>
        </div>

        <div className="not-found-links">
          <p className="not-found-links-label">صفحات مهم</p>
          <ul className="not-found-link-list">
            {links.map((item) => (
              <li key={item.to}>
                <Link to={item.to} className="not-found-link">
                  <i className={`bi ${item.icon}`} aria-hidden="true" />
                  <span>{item.label}</span>
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  )
}
