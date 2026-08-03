import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { Link, NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { useTheme } from '../context/ThemeContext'
import { api, rememberCartSession, roleLabel } from '../api/client'

/**
 * ساعت هدر از API سرور (/time) خوانده می‌شود، نه از ساعت مرورگر.
 * هر ۳۰ ثانیه همگام می‌شود؛ بین همگام‌سازی با آفست سرور تیک می‌زند.
 */
function useServerClock() {
  const [info, setInfo] = useState(null)
  const [offsetMs, setOffsetMs] = useState(null)
  const [tick, setTick] = useState(0)

  useEffect(() => {
    let alive = true

    async function sync() {
      try {
        const t0 = Date.now()
        const data = await api.get('/time', { skipAuth: true })
        const t1 = Date.now()
        if (!alive || !data?.unix_ms) return
        const approxServerNow = Number(data.unix_ms) + (t1 - t0) / 2
        setOffsetMs(approxServerNow - t1)
        setInfo(data)
      } catch {
        /* آخرین مقدار را نگه می‌داریم */
      }
    }

    sync()
    const syncId = setInterval(sync, 60_000)
    const tickId = setInterval(() => setTick((n) => n + 1), 15_000)
    return () => {
      alive = false
      clearInterval(syncId)
      clearInterval(tickId)
    }
  }, [])

  return useMemo(() => {
    if (!info) {
      return { label: '…', time: '--:--', iso: '', ready: false }
    }
    if (offsetMs == null) {
      return {
        label: info.jalali?.label || '…',
        time: info.time || '--:--',
        iso: info.jalali?.iso || '',
        ready: true,
      }
    }
    const serverNow = new Date(Date.now() + offsetMs)
    const parts = new Intl.DateTimeFormat('en-GB', {
      timeZone: 'Asia/Tehran',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).formatToParts(serverNow)
    const get = (type) => parts.find((p) => p.type === type)?.value || ''
    const time = `${get('hour')}:${get('minute')}`
    return {
      label: info.jalali?.label || '…',
      time,
      iso: info.jalali?.iso || '',
      ready: true,
    }
    // tick باعث بازمحاسبهٔ ساعت بین همگام‌سازی‌ها می‌شود
  }, [info, offsetMs, tick])
}

export default function Navbar({
  showAdminToggle = false,
  adminNavOpen = false,
  onToggleAdminNav,
}) {
  const { user, isAuthenticated, logout, hasRole } = useAuth()
  const { theme, themes, setTheme, saving: themeSaving } = useTheme()
  const isStudent = hasRole('student') && Boolean(user?.student_ref)
  const navigate = useNavigate()
  const clock = useServerClock()
  const dateInfo = { label: clock.label, iso: clock.iso }
  const timeLabel = clock.time

  const [menuOpen, setMenuOpen] = useState(false)
  const [navOpen, setNavOpen] = useState(false)
  const [menuPos, setMenuPos] = useState({ top: 0, left: 0 })
  const [cartCount, setCartCount] = useState(0)
  const menuRef = useRef(null)
  const triggerRef = useRef(null)
  const dropdownRef = useRef(null)

  useEffect(() => {
    let cancelled = false
    async function refreshCart() {
      try {
        const data = rememberCartSession(await api.get('/shop/cart'))
        if (!cancelled) setCartCount(data.count || 0)
      } catch {
        if (!cancelled) setCartCount(0)
      }
    }
    refreshCart()
    function onCartChanged() {
      refreshCart()
    }
    window.addEventListener('lims-cart-changed', onCartChanged)
    window.addEventListener('storage', onCartChanged)
    return () => {
      cancelled = true
      window.removeEventListener('lims-cart-changed', onCartChanged)
      window.removeEventListener('storage', onCartChanged)
    }
  }, [isAuthenticated])

  function updateMenuPos() {
    const el = triggerRef.current
    if (!el) return
    const rect = el.getBoundingClientRect()
    const width = Math.min(280, window.innerWidth * 0.86)
    let left = rect.left
    if (left + width > window.innerWidth - 8) left = window.innerWidth - width - 8
    if (left < 8) left = 8
    setMenuPos({ top: rect.bottom + 8, left })
  }

  useLayoutEffect(() => {
    if (!menuOpen) return undefined
    updateMenuPos()
    function onReposition() {
      updateMenuPos()
    }
    window.addEventListener('resize', onReposition)
    window.addEventListener('scroll', onReposition, true)
    return () => {
      window.removeEventListener('resize', onReposition)
      window.removeEventListener('scroll', onReposition, true)
    }
  }, [menuOpen])

  useEffect(() => {
    if (!menuOpen) return undefined
    function onDoc(e) {
      const t = e.target
      if (menuRef.current?.contains(t)) return
      if (dropdownRef.current?.contains(t)) return
      setMenuOpen(false)
    }
    function onKey(e) {
      if (e.key === 'Escape') setMenuOpen(false)
    }
    document.addEventListener('mousedown', onDoc)
    document.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onDoc)
      document.removeEventListener('keydown', onKey)
    }
  }, [menuOpen])

  async function handleLogout() {
    setMenuOpen(false)
    await logout()
    navigate('/login')
  }

  const navLinkClass = ({ isActive }) => `site-nav-link ${isActive ? 'is-active' : ''}`

  return (
    <header className={`site-header sticky-top ${navOpen ? 'is-nav-open' : ''}`}>
      <div className="site-header-banner">
        <div className="site-header-banner-glow" aria-hidden="true" />
        <div className="app-nav-inner site-header-banner-inner">
          <Link className="site-brand" to="/" onClick={() => setNavOpen(false)}>
            <span className="site-brand-mark" aria-hidden="true">
              ل
            </span>
            <span className="site-brand-text">
              <span className="site-brand-name">آموزشگاه لیمز</span>
              <span className="site-brand-tag">سامانه مدیریت آموزشگاه‌های زبان</span>
            </span>
          </Link>

          <div className="site-header-date" title={dateInfo.iso}>
            <i className="bi bi-calendar3" aria-hidden="true" />
            <div className="site-header-date-text">
              <strong>{dateInfo.label}</strong>
              <span>{timeLabel}</span>
            </div>
          </div>

          <div className="site-header-actions">
            {showAdminToggle && (
              <button
                type="button"
                className="site-header-icon-btn d-lg-none"
                aria-expanded={adminNavOpen}
                aria-controls="adminSidebar"
                title="منوی مدیریت"
                onClick={onToggleAdminNav}
              >
                <i className={`bi ${adminNavOpen ? 'bi-x-lg' : 'bi-layout-sidebar-inset-reverse'}`} />
                <span className="d-none d-sm-inline">مدیریت</span>
              </button>
            )}

            {isAuthenticated ? (
              <div className="site-user-menu" ref={menuRef}>
                <button
                  ref={triggerRef}
                  type="button"
                  className={`site-user-trigger ${menuOpen ? 'is-open' : ''}`}
                  aria-expanded={menuOpen}
                  aria-haspopup="menu"
                  onClick={() => setMenuOpen((v) => !v)}
                >
                  <span className="site-user-avatar" aria-hidden="true">
                    {(user.full_name || user.username || 'ک').trim().charAt(0)}
                  </span>
                  <span className="site-user-meta">
                    <strong>{user.full_name || user.username}</strong>
                    <span>{roleLabel(user.role)}</span>
                  </span>
                  <i className={`bi bi-chevron-down site-user-caret ${menuOpen ? 'is-open' : ''}`} />
                </button>

                {menuOpen &&
                  createPortal(
                    <div
                      ref={dropdownRef}
                      className="site-user-dropdown"
                      role="menu"
                      style={{ top: menuPos.top, left: menuPos.left }}
                    >
                      <div className="site-user-dropdown-head">
                        <div className="site-user-avatar is-lg" aria-hidden="true">
                          {(user.full_name || user.username || 'ک').trim().charAt(0)}
                        </div>
                        <div>
                          <strong>{user.full_name || user.username}</strong>
                          <span>{roleLabel(user.role)}</span>
                        </div>
                      </div>
                      <Link
                        role="menuitem"
                        className="site-user-dropdown-item"
                        to="/dashboard"
                        onClick={() => setMenuOpen(false)}
                      >
                        <i className="bi bi-speedometer2" />
                        داشبورد
                      </Link>
                      {isStudent && (
                        <Link
                          role="menuitem"
                          className="site-user-dropdown-item"
                          to="/my-courses"
                          onClick={() => setMenuOpen(false)}
                        >
                          <i className="bi bi-journal-bookmark-fill" />
                          دوره‌های من
                        </Link>
                      )}
                      {isStudent && (
                        <Link
                          role="menuitem"
                          className="site-user-dropdown-item"
                          to="/placement"
                          onClick={() => setMenuOpen(false)}
                        >
                          <i className="bi bi-clipboard2-check" />
                          آزمون تعیین سطح
                        </Link>
                      )}
                      <Link
                        role="menuitem"
                        className="site-user-dropdown-item"
                        to="/shop"
                        onClick={() => setMenuOpen(false)}
                      >
                        <i className="bi bi-shop" />
                        فروشگاه
                      </Link>
                      <Link
                        role="menuitem"
                        className="site-user-dropdown-item"
                        to="/courses"
                        onClick={() => setMenuOpen(false)}
                      >
                        <i className="bi bi-journal-bookmark" />
                        دوره‌ها
                      </Link>
                      <div className="theme-picker" onMouseDown={(e) => e.stopPropagation()}>
                        <p className="theme-picker-title">
                          تم ظاهری {themeSaving ? '…' : ''}
                          <span className="d-block fw-normal" style={{ opacity: 0.85 }}>
                            برای حساب شما ذخیره می‌شود
                          </span>
                        </p>
                        <div className="theme-picker-grid">
                          {themes.map((t) => (
                            <button
                              key={t.id}
                              type="button"
                              className={`theme-swatch-btn ${theme === t.id ? 'is-active' : ''}`}
                              title={t.group}
                              onClick={() => setTheme(t.id)}
                            >
                              <span className="theme-swatch-dots" aria-hidden="true">
                                {t.swatch.map((c) => (
                                  <span key={c} style={{ background: c }} />
                                ))}
                              </span>
                              <span className="theme-swatch-label">{t.label}</span>
                            </button>
                          ))}
                        </div>
                      </div>
                      <button
                        type="button"
                        role="menuitem"
                        className="site-user-dropdown-item is-danger"
                        onClick={handleLogout}
                      >
                        <i className="bi bi-box-arrow-left" />
                        خروج از حساب
                      </button>
                    </div>,
                    document.body,
                  )}
              </div>
            ) : (
              <div className="site-auth-actions">
                <Link className="btn btn-sm btn-outline-light site-auth-register" to="/register">
                  ثبت‌نام
                </Link>
                <Link className="btn btn-sm btn-light site-auth-login" to="/login">
                  ورود
                </Link>
              </div>
            )}

            <button
              type="button"
              className="site-header-icon-btn d-lg-none"
              aria-expanded={navOpen}
              aria-controls="siteMainNav"
              aria-label="باز کردن منو"
              onClick={() => setNavOpen((v) => !v)}
            >
              <i className={`bi ${navOpen ? 'bi-x-lg' : 'bi-list'}`} />
            </button>
          </div>
        </div>
      </div>

      <nav className="site-header-nav" aria-label="منوی اصلی">
        <div className="app-nav-inner">
          <div className={`site-header-nav-collapse ${navOpen ? 'is-open' : ''}`} id="siteMainNav">
            <ul className="site-nav-list">
              <li>
                <NavLink className={navLinkClass} to="/" end onClick={() => setNavOpen(false)}>
                  <i className="bi bi-house-door" />
                  خانه
                </NavLink>
              </li>
              <li>
                <NavLink className={navLinkClass} to="/courses" onClick={() => setNavOpen(false)}>
                  <i className="bi bi-journal-bookmark" />
                  دوره‌ها
                </NavLink>
              </li>
              <li>
                <NavLink className={navLinkClass} to="/shop" onClick={() => setNavOpen(false)}>
                  <i className="bi bi-shop" />
                  فروشگاه
                </NavLink>
              </li>
              <li>
                <NavLink className={navLinkClass} to="/cart" onClick={() => setNavOpen(false)}>
                  <i className="bi bi-cart3" />
                  سبد خرید
                  {cartCount > 0 && <span className="shop-nav-badge">{cartCount}</span>}
                </NavLink>
              </li>
              <li>
                <NavLink className={navLinkClass} to="/about" onClick={() => setNavOpen(false)}>
                  <i className="bi bi-info-circle" />
                  درباره ما
                </NavLink>
              </li>
              {isAuthenticated && (
                <li>
                  <NavLink className={navLinkClass} to="/dashboard" onClick={() => setNavOpen(false)}>
                    <i className="bi bi-speedometer2" />
                    داشبورد
                  </NavLink>
                </li>
              )}
              {isStudent && (
                <li>
                  <NavLink className={navLinkClass} to="/my-courses" onClick={() => setNavOpen(false)}>
                    <i className="bi bi-journal-bookmark-fill" />
                    دوره‌های من
                  </NavLink>
                </li>
              )}
              {isStudent && (
                <li>
                  <NavLink className={navLinkClass} to="/placement" onClick={() => setNavOpen(false)}>
                    <i className="bi bi-clipboard2-check" />
                    تعیین سطح
                  </NavLink>
                </li>
              )}
            </ul>
          </div>
        </div>
      </nav>
    </header>
  )
}
