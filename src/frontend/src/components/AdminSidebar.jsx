import { NavLink } from 'react-router-dom'
import { createPortal } from 'react-dom'
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
      { to: '/scores', label: 'نمرات و تعیین سطح', icon: 'bi-clipboard2-data' },
      { to: '/placement/bank', label: 'مخزن آزمون تعیین سطح', icon: 'bi-ui-checks-grid' },
    ],
  },
  {
    title: 'افراد و مالی',
    items: [
      { to: '/teachers', label: 'مدرسان', icon: 'bi-person-workspace' },
      { to: '/students', label: 'زبان‌آموزان', icon: 'bi-person-lines-fill' },
      { to: '/enrollments', label: 'ثبت‌نام‌ها', icon: 'bi-clipboard-check' },
      { to: '/payments', label: 'پرداخت‌ها', icon: 'bi-wallet2' },
      { to: '/shop/admin', label: 'فروشگاه', icon: 'bi-shop-window' },
    ],
  },
  {
    title: 'تنظیمات',
    items: [
      { to: '/lookups', label: 'نوع جلسه و شعب', icon: 'bi-gear' },
      { to: '/activities', label: 'فعالیت‌ها و لاگ', icon: 'bi-clock-history', adminOnly: true },
      { to: '/users', label: 'کاربران و دسترسی‌ها', icon: 'bi-shield-lock', adminOnly: true },
    ],
  },
]

const TEACHER_GROUPS = [
  {
    title: 'پنل مدرس',
    items: [
      { to: '/dashboard', label: 'داشبورد', icon: 'bi-speedometer2' },
      { to: '/teacher/courses', label: 'دوره‌های من', icon: 'bi-journal-bookmark' },
      { to: '/teacher/classes', label: 'کلاس‌های من', icon: 'bi-people' },
      { to: '/teacher/students', label: 'زبان‌آموزان من', icon: 'bi-mortarboard' },
      { to: '/teacher/attendance', label: 'حضور و غیاب', icon: 'bi-clipboard-check' },
      { to: '/sessions', label: 'جلسات', icon: 'bi-calendar3' },
      { to: '/scores', label: 'نمرات', icon: 'bi-clipboard2-data' },
      { to: '/placement/bank', label: 'مخزن تعیین سطح', icon: 'bi-ui-checks-grid' },
    ],
  },
]

const FINANCE_GROUPS = [
  {
    title: 'مالی',
    items: [
      { to: '/payments', label: 'پرداخت‌ها', icon: 'bi-wallet2' },
      { to: '/dashboard', label: 'داشبورد', icon: 'bi-speedometer2' },
    ],
  },
]

export default function AdminSidebar({ open, onClose }) {
  const { hasRole, user } = useAuth()
  const isStaff = hasRole('admin', 'secretary', 'education')
  const isFinanceOnly = user?.role === 'finance'
  const isAdmin = user?.role === 'admin'

  let groups = TEACHER_GROUPS
  let kicker = 'پنل مدرس'
  let title = 'جلسات و حضور'

  if (isStaff) {
    groups = STAFF_GROUPS.map((g) => ({
      ...g,
      items: g.items.filter((item) => !item.adminOnly || isAdmin),
    }))
    kicker = 'پنل مدیریت'
    title = 'مدیریت آموزشگاه'
  } else if (isFinanceOnly) {
    groups = FINANCE_GROUPS
    kicker = 'پنل مالی'
    title = 'پرداخت‌ها و گزارش'
  } else {
    kicker = 'پنل مدرس'
    title = 'کلاس‌ها و زبان‌آموزان'
  }

  const panel = (
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
                      <i className={`bi ${item.icon}`} aria-hidden="true" />
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

  if (typeof document === 'undefined') return null
  return createPortal(panel, document.body)
}
