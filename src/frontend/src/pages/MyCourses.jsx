import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { api, formatMoney } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import FinanceStatus from '../components/FinanceStatus'

const STATUS_MAP = {
  pending_payment: 'در انتظار پرداخت',
  pending_approval: 'در انتظار تأیید',
  active: 'فعال',
  frozen: 'معلق',
  completed: 'تکمیل‌شده',
  withdrawn: 'انصراف',
  transferred: 'انتقال',
}

const STATUS_TONE = {
  pending_payment: 'is-warn',
  pending_approval: 'is-warn',
  active: 'is-ok',
  frozen: 'is-muted',
  completed: 'is-info',
  withdrawn: 'is-danger',
  transferred: 'is-muted',
}

const CLASS_STATUS_MAP = {
  draft: 'پیش‌نویس',
  open: 'باز',
  full: 'تکمیل ظرفیت',
  in_progress: 'در حال برگزاری',
  finished: 'پایان‌یافته',
  cancelled: 'لغو شده',
}

const TABS = [
  { id: 'current', label: 'جاری', statuses: ['pending_payment', 'pending_approval', 'active', 'frozen'] },
  { id: 'completed', label: 'تکمیل‌شده', statuses: ['completed'] },
  { id: 'closed', label: 'انصراف / انتقال', statuses: ['withdrawn', 'transferred'] },
  { id: 'all', label: 'همه', statuses: null },
]

function BalanceLine({ row }) {
  const bal = Number(row.Balance) || 0
  const debt = Number(row.DebtAmount ?? Math.max(0, -bal)) || 0
  const credit = Number(row.CreditAmount ?? Math.max(0, bal)) || 0
  if (bal < 0) {
    return <span className="my-course-balance is-debt">بدهی: {formatMoney(debt)}</span>
  }
  if (bal > 0) {
    return <span className="my-course-balance is-credit">بستانکاری: {formatMoney(credit)}</span>
  }
  return <span className="my-course-balance is-settled">مانده: {formatMoney(0)}</span>
}

export default function MyCourses() {
  const { user } = useAuth()
  const [rows, setRows] = useState([])
  const [tab, setTab] = useState('current')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [reloadKey, setReloadKey] = useState(0)

  useEffect(() => {
    let cancelled = false
    async function load() {
      setLoading(true)
      try {
        const data = await api.get('/me/enrollments')
        if (!cancelled) {
          setRows(data.enrollments || [])
          setError('')
        }
      } catch (err) {
        if (!cancelled) {
          const msg = err.message || ''
          setError(
            /internal server error/i.test(msg)
              ? 'خطای سرور در دریافت دوره‌ها. چند ثانیه بعد دوباره تلاش کنید.'
              : msg,
          )
          setRows([])
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    load()
    return () => {
      cancelled = true
    }
  }, [reloadKey])

  const filtered = useMemo(() => {
    const conf = TABS.find((t) => t.id === tab) || TABS[0]
    if (!conf.statuses) return rows
    return rows.filter((r) => conf.statuses.includes(r.Status))
  }, [rows, tab])

  const counts = useMemo(() => {
    const out = { all: rows.length }
    for (const t of TABS) {
      if (!t.statuses) continue
      out[t.id] = rows.filter((r) => t.statuses.includes(r.Status)).length
    }
    return out
  }, [rows])

  if (!user?.student_ref) {
    return (
      <div className="container py-4">
        <div className="alert alert-warning">
          حساب شما به پروفایل زبان‌آموز متصل نیست. با آموزشگاه هماهنگ کنید تا «دوره‌های من» فعال شود.
        </div>
      </div>
    )
  }

  return (
    <div className="container py-4 my-courses-page">
      <div className="page-head d-flex justify-content-between align-items-start flex-wrap gap-2">
        <div>
          <p className="page-kicker">پنل زبان‌آموز</p>
          <h1 className="section-title h3 mb-1">دوره‌های من</h1>
          <p className="muted mb-0">
            {user.full_name || user.username} · مشاهده وضعیت ثبت‌نام و کلاس‌ها
          </p>
        </div>
        <Link to="/courses" className="btn btn-brand rounded-pill align-self-center">
          <i className="bi bi-plus-lg me-1" />
          ثبت‌نام دوره جدید
        </Link>
      </div>

      <div className="shop-tabs mb-3">
        {TABS.map((t) => (
          <button
            key={t.id}
            type="button"
            className={`shop-tab ${tab === t.id ? 'is-active' : ''}`}
            onClick={() => setTab(t.id)}
          >
            {t.label}
            <span className="my-course-tab-count">{counts[t.id] ?? 0}</span>
          </button>
        ))}
      </div>

      {error && (
        <div className="alert alert-danger d-flex justify-content-between align-items-center flex-wrap gap-2">
          <span>{error}</span>
          <button
            type="button"
            className="btn btn-sm btn-outline-danger"
            onClick={() => setReloadKey((k) => k + 1)}
          >
            تلاش دوباره
          </button>
        </div>
      )}
      {loading ? (
        <Loading />
      ) : filtered.length === 0 ? (
        <div className="empty-state text-center py-5 text-muted">
          <i className="bi bi-journal-x display-5 d-block mb-2" />
          {rows.length === 0
            ? 'هنوز در هیچ دوره‌ای ثبت‌نام نکرده‌اید.'
            : 'در این دسته موردی نیست.'}
          {rows.length === 0 && (
            <div className="mt-3">
              <Link to="/courses" className="btn btn-primary rounded-pill">
                مشاهده کاتالوگ دوره‌ها
              </Link>
            </div>
          )}
        </div>
      ) : (
        <div className="row g-3">
          {filtered.map((row) => (
            <div key={row.Id} className="col-md-6 col-xl-4">
              <article className="my-course-card">
                <div className="my-course-card-top">
                  <div className="my-course-lang">{row.LanguageName || '—'}</div>
                  <span className={`my-course-status ${STATUS_TONE[row.Status] || ''}`}>
                    {STATUS_MAP[row.Status] || row.Status}
                  </span>
                </div>
                <h2 className="my-course-title">{row.CourseName}</h2>
                <ul className="my-course-meta">
                  {row.LevelName && (
                    <li>
                      <i className="bi bi-bar-chart-steps" />
                      سطح {row.LevelName}
                      {row.LevelCode ? ` (${row.LevelCode})` : ''}
                    </li>
                  )}
                  <li>
                    <i className="bi bi-people" />
                    کلاس {row.ClassRef ? `#${row.ClassRef}` : '—'}
                    {row.ClassStatus
                      ? ` · ${CLASS_STATUS_MAP[row.ClassStatus] || row.ClassStatus}`
                      : ''}
                  </li>
                  {row.TeacherName && (
                    <li>
                      <i className="bi bi-person-workspace" />
                      مدرس: {row.TeacherName}
                    </li>
                  )}
                  {(row.ClassStartDate || row.ClassEndDate) && (
                    <li>
                      <i className="bi bi-calendar3" />
                      {row.ClassStartDate || '—'} تا {row.ClassEndDate || '—'}
                    </li>
                  )}
                  {row.SessionTypeName && (
                    <li>
                      <i className="bi bi-display" />
                      {row.SessionTypeName}
                      {row.BranchName ? ` · ${row.BranchName}` : ''}
                    </li>
                  )}
                  <li>
                    <i className="bi bi-calendar-check" />
                    تاریخ ثبت‌نام: {row.Date || '—'}
                  </li>
                </ul>

                <div className="my-course-finance">
                  <div className="my-course-finance-amounts">
                    <div>
                      <span>شهریه</span>
                      <strong>{formatMoney(row.CourseCost)}</strong>
                    </div>
                    <div>
                      <span>پرداخت‌شده</span>
                      <strong>{formatMoney(row.PaidAmount)}</strong>
                    </div>
                  </div>
                  <BalanceLine row={row} />
                  <FinanceStatus
                    compact
                    status={row.FinancialStatus}
                    intensity={row.FinanceIntensity}
                    courseCost={row.CourseCost}
                    paidAmount={row.PaidAmount}
                    balance={row.Balance}
                  />
                </div>

                {row.Status === 'withdrawn' && row.WithdrawReason && (
                  <p className="my-course-withdraw small text-muted mb-0 mt-2">
                    دلیل انصراف: {row.WithdrawReason}
                  </p>
                )}

                <div className="my-course-actions">
                  <Link to={`/courses/${row.CourseRef}`} className="btn btn-sm btn-outline-primary">
                    جزئیات دوره
                  </Link>
                </div>
              </article>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
