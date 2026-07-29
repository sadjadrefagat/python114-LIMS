import { NavLink } from 'react-router-dom'

const GROUPS = [
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
    ],
  },
]

export default function AdminSidebar({ open, onClose }) {
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
        aria-label="منوی مدیریت"
      >
        <div className="admin-sidebar-head">
          <div>
            <div className="admin-sidebar-kicker">پنل مدیریت</div>
            <h2 className="admin-sidebar-title">مدیریت آموزشگاه</h2>
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
          {GROUPS.map((group) => (
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
