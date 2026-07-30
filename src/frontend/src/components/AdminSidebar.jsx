import { NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const STAFF_GROUPS = [
  {
    title: 'آموزش',
    items: [
      { to: '/languages', label: 'زبان‌ها', icon: 'bi-translate' },
      { to: '/levels', label: 'سطح‌ها', icon: 'bi-bar-chart-steps' },
      { to: '/courses', label: 'دوره‌ها', icon: 'bi-journal-bookmark' },
      { to: '/classes', label: 'کلاس‌ها', icon: 'bi-people' },
      { to: '/sessions', label: 'جلسات', icon: 'bi-calendar3' },
    ],
  },
  {
    title: 'افراد و ثبت‌نام',
    items: [
      { to: '/teachers', label: 'مدرسان', icon: 'bi-person-workspace' },
      { to: '/students', label: 'زبان‌آموزان', icon: 'bi-person-lines-fill' },
      { to: '/enrollments', label: 'ثبت‌نام‌ها', icon: 'bi-clipboard-check' },
    ],
  },
  {
    title: 'تنظیمات',
    items: [
      { to: '/lookups', label: 'نوع جلسه و شعب', icon: 'bi-gear' },
      { to: '/users', label: 'کاربران و دسترسی‌ها', icon: 'bi-shield-lock', adminOnly: true },
    ],
  },
]

const TEACHER_GROUPS = [
  {
    title: 'کلاس من',
    items: [
      { to: '/sessions', label: 'جلسات و حضور و غیاب', icon: 'bi-clipboard-check' },
      { to: '/dashboard', label: 'داشبورد', icon: 'bi-speedometer2' },
    ],
  },
]

export default function AdminSidebar({ open, onClose }) {
  const { hasRole, user } = useAuth()
  const isStaff = hasRole('admin', 'secretary', 'education')
  const isAdmin = user?.role === 'admin'
  const groups = isStaff
    ? STAFF_GROUPS.map((g) => ({
        ...g,
        items: g.items.filter((item) => !item.adminOnly || isAdmin),
      }))
    : TEACHER_GROUPS
  const kicker = isStaff ? 'پنل مدیریت' : 'پنل مدرس'
  const title = isStaff ? 'مدیریت آموزشگاه' : 'جلسات و حضور'

  return (
    <>
      <div
        className={`admin-sidebar-backdrop ${open ? 'is-open' : ''}`}
        onClick={onClose}
        aria-hidden={!open}
      />
      <aside
        id="adminSidebar"
        className={`admin-sidebar ${open ? 'is-open' : ''}`}
        aria-label={kicker}
      >
        <div className="admin-sidebar-head">
          <div>
            <div className="admin-sidebar-kicker">{kicker}</div>
            <h2 className="admin-sidebar-title">{title}</h2>
          </div>
          <button
            type="button"
            className="btn btn-sm btn-light admin-sidebar-close d-lg-none"
            onClick={onClose}
            aria-label="بستن منوی مدیریت"
          >
            <i className="bi bi-x-lg" />
          </button>
        </div>

        <nav className="admin-sidebar-nav">
          {groups.map((group) => (
            <div key={group.title} className="admin-sidebar-group">
              <div className="admin-sidebar-group-title">{group.title}</div>
              <ul className="admin-sidebar-list">
                {group.items.map((item) => (
                  <li key={item.to}>
                    <NavLink
                      to={item.to}
                      className={({ isActive }) =>
                        `admin-sidebar-link ${isActive ? 'active' : ''}`
                      }
                      onClick={onClose}
                    >
                      <i className={`bi ${item.icon}`} />
                      <span>{item.label}</span>
                    </NavLink>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </nav>
      </aside>
    </>
  )
}
