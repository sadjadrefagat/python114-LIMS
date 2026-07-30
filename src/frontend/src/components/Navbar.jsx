import { Link, NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { roleLabel } from '../api/client'

export default function Navbar({
  showAdminToggle = false,
  adminNavOpen = false,
  onToggleAdminNav,
}) {
  const { user, isAuthenticated, logout } = useAuth()
  const navigate = useNavigate()

  async function handleLogout() {
    await logout()
    navigate('/login')
  }

  return (
    <nav className="navbar navbar-expand-lg navbar-lims sticky-top">
      <div className="container-fluid app-nav-inner">
        <Link className="navbar-brand brand-mark" to="/">
          <span className="brand-badge">ل</span>
          <span>آموزشگاه لیمز</span>
        </Link>

        <div className="d-flex align-items-center gap-2 order-lg-last">
          {showAdminToggle && (
            <button
              type="button"
              className="btn btn-sm btn-outline-success rounded-pill d-lg-none px-3"
              aria-expanded={adminNavOpen}
              aria-controls="adminSidebar"
              onClick={onToggleAdminNav}
            >
              <i className={`bi ${adminNavOpen ? 'bi-x-lg' : 'bi-layout-sidebar-inset-reverse'} me-1`} />
              مدیریت
            </button>
          )}

          <button
            className="navbar-toggler"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#mainNav"
            aria-controls="mainNav"
            aria-expanded="false"
            aria-label="باز کردن منو"
          >
            <span className="navbar-toggler-icon" />
          </button>
        </div>

        <div className="collapse navbar-collapse" id="mainNav">
          <ul className="navbar-nav me-auto mb-2 mb-lg-0 gap-lg-1">
            <li className="nav-item">
              <NavLink className="nav-link" to="/">
                خانه
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink className="nav-link" to="/courses">
                دوره‌ها
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink className="nav-link" to="/about">
                درباره ما
              </NavLink>
            </li>
            {isAuthenticated && (
              <li className="nav-item">
                <NavLink className="nav-link" to="/dashboard">
                  داشبورد
                </NavLink>
              </li>
            )}
          </ul>

          <div className="d-flex align-items-center gap-2">
            {isAuthenticated ? (
              <>
                <span className="chip chip-teal">
                  <i className="bi bi-person-circle" />
                  {user.full_name || user.username}
                  <span className="opacity-75">({roleLabel(user.role)})</span>
                </span>
                <button
                  className="btn btn-sm btn-outline-secondary rounded-pill"
                  onClick={handleLogout}
                >
                  خروج
                </button>
              </>
            ) : (
              <>
                <Link className="btn btn-sm btn-outline-success rounded-pill px-3" to="/register">
                  ثبت‌نام
                </Link>
                <Link className="btn btn-brand btn-sm rounded-pill px-3" to="/login">
                  ورود
                </Link>
              </>
            )}
          </div>
        </div>
      </div>
    </nav>
  )
}
