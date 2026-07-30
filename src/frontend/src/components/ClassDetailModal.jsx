import { useEffect, useId, useState } from 'react'
import { createPortal } from 'react-dom'
import { Link } from 'react-router-dom'
import { api, formatMoney } from '../api/client'
import Loading from './Loading'

const classStatusMap = {
  draft: 'پیش‌نویس',
  open: 'باز',
  full: 'تکمیل ظرفیت',
  in_progress: 'در حال برگزاری',
  finished: 'پایان‌یافته',
  cancelled: 'لغو شده',
}

const sessionStatusMap = {
  scheduled: 'برنامه‌ریزی‌شده',
  in_progress: 'در حال برگزاری',
  completed: 'برگزار شده',
  cancelled: 'لغو شده',
  rescheduled: 'جابه‌جا شده',
}

const classTypeMap = {
  group: 'گروهی',
  private: 'خصوصی',
  semi_private: 'نیمه‌خصوصی',
  vip: 'ویژه',
}

function num(n) {
  return Number(n || 0).toLocaleString('en-US')
}

function StatCard({ color, icon, category, value, footer }) {
  return (
    <div className="md-stat-card class-modal-stat">
      <div className={`md-stat-icon md-${color}`}>
        <i className={`bi ${icon}`} />
      </div>
      <p className="md-stat-category">{category}</p>
      <h3 className="md-stat-title">{value}</h3>
      {footer ? (
        <div className="md-stat-footer">
          <i className="bi bi-info-circle" />
          <span>{footer}</span>
        </div>
      ) : null}
    </div>
  )
}

function ProgressBlock({ label, value, pct, color = 'teal' }) {
  const width = Math.max(0, Math.min(100, Number(pct) || 0))
  return (
    <div className="class-progress-block">
      <div className="class-progress-head">
        <span>{label}</span>
        <strong>{value}</strong>
      </div>
      <div className="md-progress">
        <div className={`md-progress-bar is-${color}`} style={{ width: `${width}%` }} />
      </div>
      <div className="class-progress-pct">{num(width)}٪</div>
    </div>
  )
}

function SpecRow({ label, children }) {
  if (children == null || children === '') return null
  return (
    <div className="class-spec-row">
      <dt>{label}</dt>
      <dd>{children}</dd>
    </div>
  )
}

/**
 * مودال نمایش جزئیات کلاس — تب مشخصات / تب آمار
 */
export default function ClassDetailModal({ classId, open, onClose }) {
  const titleId = useId()
  const [tab, setTab] = useState('info')
  const [cls, setCls] = useState(null)
  const [stats, setStats] = useState(null)
  const [sessions, setSessions] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!open) return undefined
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.body.style.overflow = prev
    }
  }, [open])

  useEffect(() => {
    if (!open) return undefined
    function onKey(e) {
      if (e.key === 'Escape') onClose?.()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [open, onClose])

  useEffect(() => {
    if (!open || !classId) return undefined
    let cancelled = false
    setLoading(true)
    setError('')
    setTab('info')
    setCls(null)
    setStats(null)
    setSessions([])
    api
      .get(`/classes/${classId}`)
      .then((data) => {
        if (cancelled) return
        setCls(data.class)
        setStats(data.stats || {})
        setSessions(data.recent_sessions || [])
      })
      .catch((err) => {
        if (!cancelled) setError(err.message || 'خطا در بارگذاری جزئیات کلاس')
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [open, classId])

  if (!open) return null

  const heldLabel =
    stats?.planned_sessions > 0
      ? `${num(stats.sessions_completed)} از ${num(stats.planned_sessions)} جلسه برنامه‌ریزی‌شده`
      : `${num(stats?.sessions_completed)} از ${num(stats?.sessions_total)} جلسه ثبت‌شده`

  return createPortal(
    <div
      className="class-modal-overlay"
      role="presentation"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onClose?.()
      }}
    >
      <div
        className="class-modal-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
      >
        <div className="class-modal-header">
          <div>
            <h2 id={titleId} className="class-modal-title">
              {cls ? cls.CourseName : 'جزئیات کلاس'}
            </h2>
            {cls ? (
              <div className="class-modal-subtitle">
                <span>کد #{cls.Id}</span>
                <span className="chip chip-teal">{classStatusMap[cls.Status] || cls.Status}</span>
              </div>
            ) : null}
          </div>
          <button type="button" className="class-modal-close" onClick={onClose} aria-label="بستن">
            <i className="bi bi-x-lg" />
          </button>
        </div>

        <div className="class-modal-tabs" role="tablist">
          <button
            type="button"
            role="tab"
            aria-selected={tab === 'info'}
            className={`class-modal-tab ${tab === 'info' ? 'is-active' : ''}`}
            onClick={() => setTab('info')}
          >
            <i className="bi bi-card-text" />
            مشخصات کلاس
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={tab === 'stats'}
            className={`class-modal-tab ${tab === 'stats' ? 'is-active' : ''}`}
            onClick={() => setTab('stats')}
          >
            <i className="bi bi-bar-chart-line" />
            آمار
          </button>
        </div>

        <div className="class-modal-body">
          {loading ? (
            <Loading />
          ) : error ? (
            <div className="alert alert-danger mb-0">{error}</div>
          ) : !cls || !stats ? null : tab === 'info' ? (
            <div className="class-modal-pane" role="tabpanel">
              <dl className="class-spec-grid">
                <SpecRow label="دوره">{cls.CourseName}</SpecRow>
                <SpecRow label="مدرس">{cls.TeacherName}</SpecRow>
                <SpecRow label="نوع جلسه">{cls.SessionTypeName}</SpecRow>
                <SpecRow label="نوع کلاس">{classTypeMap[cls.ClassType] || cls.ClassType}</SpecRow>
                <SpecRow label="وضعیت">{classStatusMap[cls.Status] || cls.Status}</SpecRow>
                <SpecRow label="شعبه">{cls.BranchName || '—'}</SpecRow>
                <SpecRow label="تاریخ شروع">{cls.StartDate || '—'}</SpecRow>
                <SpecRow label="تاریخ پایان">{cls.EndDate || '—'}</SpecRow>
                <SpecRow label="ظرفیت">{num(cls.Capacity)}</SpecRow>
                <SpecRow label="ثبت‌نام فعال">{num(cls.EnrolledCount)}</SpecRow>
                <SpecRow label="آدرس / مکان">{cls.LocationAddress || '—'}</SpecRow>
                <SpecRow label="لینک آنلاین">
                  {cls.MeetingLink ? (
                    <a href={cls.MeetingLink} target="_blank" rel="noreferrer">
                      {cls.MeetingLink}
                    </a>
                  ) : (
                    '—'
                  )}
                </SpecRow>
                {cls.CancelReason ? <SpecRow label="دلیل لغو">{cls.CancelReason}</SpecRow> : null}
                {stats.course_cost != null ? (
                  <SpecRow label="شهریه دوره">{formatMoney(stats.course_cost)}</SpecRow>
                ) : null}
              </dl>

              <div className="class-modal-actions mt-3">
                <Link to={`/courses/${cls.CourseRef}`} className="btn btn-sm btn-outline-secondary rounded-pill" onClick={onClose}>
                  صفحه دوره
                </Link>
                <Link to="/sessions" className="btn btn-sm btn-outline-primary rounded-pill" onClick={onClose}>
                  مدیریت جلسات
                </Link>
              </div>
            </div>
          ) : (
            <div className="class-modal-pane" role="tabpanel">
              <div className="row g-3 mb-3">
                <div className="col-md-6">
                  <ProgressBlock
                    label="پیشرفت برگزاری جلسات"
                    value={heldLabel}
                    pct={stats.sessions_held_pct}
                    color="teal"
                  />
                </div>
                <div className="col-md-6">
                  <ProgressBlock
                    label="پر شدن ظرفیت"
                    value={`${num(stats.enrolled_count)} از ${num(stats.capacity)} نفر · ${num(stats.seats_left)} جای خالی`}
                    pct={stats.fill_pct}
                    color="info"
                  />
                </div>
                {stats.attendance_total_marks > 0 && (
                  <div className="col-md-6">
                    <ProgressBlock
                      label="نرخ حضور (حاضر + تأخیر)"
                      value={`${num(stats.attendance_present + stats.attendance_late)} از ${num(stats.attendance_total_marks)} ثبت`}
                      pct={stats.attendance_pct}
                      color="success"
                    />
                  </div>
                )}
              </div>

              <div className="row g-3 class-modal-stats">
                <div className="col-6 col-lg-3">
                  <StatCard
                    color="success"
                    icon="bi-check2-circle"
                    category="برگزار شده"
                    value={num(stats.sessions_completed)}
                    footer={`از ${num(stats.sessions_total)} جلسه ثبت‌شده`}
                  />
                </div>
                <div className="col-6 col-lg-3">
                  <StatCard
                    color="info"
                    icon="bi-hourglass-split"
                    category="باقی‌مانده"
                    value={num(stats.sessions_remaining)}
                    footer={`${num(stats.sessions_scheduled)} برنامه‌ریزی · ${num(stats.sessions_in_progress)} جاری`}
                  />
                </div>
                <div className="col-6 col-lg-3">
                  <StatCard
                    color="warning"
                    icon="bi-calendar-week"
                    category="میانگین هفتگی"
                    value={num(stats.avg_sessions_per_week)}
                    footer={`جلسه برگزارشده / هفته · بازه ${num(stats.span_weeks)} هفته`}
                  />
                </div>
                <div className="col-6 col-lg-3">
                  <StatCard
                    color="teal"
                    icon="bi-graph-up"
                    category="میانگین کل جلسات"
                    value={num(stats.avg_all_sessions_per_week)}
                    footer="همه وضعیت‌ها در هر هفته"
                  />
                </div>
              </div>

              <div className="row g-3 class-modal-stats mb-3">
                <div className="col-6 col-lg-3">
                  <StatCard
                    color="danger"
                    icon="bi-x-octagon"
                    category="لغو / جابه‌جایی"
                    value={`${num(stats.sessions_cancelled)} / ${num(stats.sessions_rescheduled)}`}
                    footer={`${num(stats.makeup_count)} جلسه جبرانی`}
                  />
                </div>
                <div className="col-6 col-lg-3">
                  <StatCard
                    color="primary"
                    icon="bi-clock"
                    category="مدت میانگین جلسه"
                    value={
                      stats.avg_duration_minutes != null
                        ? `${num(stats.avg_duration_minutes)} دقیقه`
                        : '—'
                    }
                    footer="بر اساس ساعت شروع و پایان"
                  />
                </div>
                <div className="col-6 col-lg-3">
                  <StatCard
                    color="rose"
                    icon="bi-calendar-event"
                    category="جلسه بعدی"
                    value={stats.next_session_date || '—'}
                    footer={
                      stats.last_session_date
                        ? `آخرین: ${stats.last_session_date}`
                        : 'هنوز جلسه‌ای برگزار نشده'
                    }
                  />
                </div>
                <div className="col-6 col-lg-3">
                  <StatCard
                    color="orange"
                    icon="bi-wallet2"
                    category="وضعیت مالی ثبت‌نام‌ها"
                    value={`${num(stats.finance_settled)} تسویه`}
                    footer={`${num(stats.finance_debtors)} بدهکار · ${num(stats.finance_creditors)} بستانکار`}
                  />
                </div>
              </div>

              <div className="row g-3">
                <div className="col-lg-5">
                  <div className="class-modal-section">
                    <h3 className="h6 mb-2">خلاصه ثبت‌نام و حضور</h3>
                    <ul className="class-detail-list">
                      <li>
                        <span>کل ثبت‌نام‌ها</span>
                        <strong>{num(stats.registrations_total)}</strong>
                      </li>
                      <li>
                        <span>فعال / در صف</span>
                        <strong>{num(stats.enrolled_count)}</strong>
                      </li>
                      <li>
                        <span>تکمیل‌شده</span>
                        <strong>{num(stats.registrations_completed)}</strong>
                      </li>
                      <li>
                        <span>انصراف</span>
                        <strong>{num(stats.registrations_withdrawn)}</strong>
                      </li>
                      <li>
                        <span>حاضر / غایب / تأخیر / مرخصی</span>
                        <strong>
                          {num(stats.attendance_present)} / {num(stats.attendance_absent)} /{' '}
                          {num(stats.attendance_late)} / {num(stats.attendance_leave)}
                        </strong>
                      </li>
                    </ul>
                  </div>
                </div>
                <div className="col-lg-7">
                  <div className="class-modal-section">
                    <div className="d-flex justify-content-between align-items-center mb-2">
                      <h3 className="h6 mb-0">آخرین جلسات</h3>
                      <Link to="/sessions" className="small" onClick={onClose}>
                        مشاهده همه
                      </Link>
                    </div>
                    <div className="table-responsive">
                      <table className="table table-sm table-hover table-zebra mb-0 align-middle">
                        <thead>
                          <tr>
                            <th>کد</th>
                            <th>تاریخ</th>
                            <th>ساعت</th>
                            <th>وضعیت</th>
                            <th></th>
                          </tr>
                        </thead>
                        <tbody>
                          {sessions.map((s) => (
                            <tr key={s.Id}>
                              <td>{s.Id}</td>
                              <td>{s.SessionDate}</td>
                              <td>
                                {s.StartTime} – {s.EndTime}
                              </td>
                              <td>
                                <span className="chip chip-teal">
                                  {sessionStatusMap[s.Status] || s.Status}
                                </span>
                              </td>
                              <td>
                                {s.IsMakeup ? (
                                  <span className="badge text-bg-secondary">جبرانی</span>
                                ) : null}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                      {!sessions.length && (
                        <div className="empty-state py-3">جلسه‌ای برای این کلاس ثبت نشده است.</div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>,
    document.body,
  )
}
