import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { api, formatMoney, roleLabel } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import TeacherDashboard from './TeacherDashboard'

const ENROLL_STATUS_FA = {
  pending_payment: 'در انتظار پرداخت',
  pending_approval: 'در انتظار تأیید',
  active: 'فعال',
  frozen: 'معلق',
  completed: 'تکمیل‌شده',
  withdrawn: 'انصراف',
  transferred: 'انتقال',
}

const CLASS_STATUS_FA = {
  draft: 'پیش‌نویس',
  open: 'باز',
  full: 'تکمیل',
  in_progress: 'جاری',
  finished: 'پایان',
  cancelled: 'لغو',
}

const PAYMENT_STATUS_FA = {
  draft: 'پیش‌نویس',
  pending: 'در انتظار',
  paid: 'پرداخت‌شده',
  failed: 'ناموفق',
  refunded: 'استرداد',
  partially_paid: 'پرداخت جزئی',
  overdue: 'سررسید گذشته',
}

const FINANCE_STATUS_FA = {
  debtor: 'بدهکار',
  creditor: 'بستانکار',
  settled: 'تسویه‌شده',
}

const FINANCE_COLORS = {
  debtor: '#e91e63',
  creditor: '#4caf50',
  settled: '#00bcd4',
}

const PAYMENT_COLORS = ['#4caf50', '#ff9800', '#9e9e9e', '#e91e63', '#3f51b5', '#795548', '#607d8b']
const PIE_COLORS = ['#e91e63', '#00bcd4', '#4caf50', '#ff9800', '#9c27b0', '#3f51b5', '#607d8b']


function num(n) {
  return Number(n || 0).toLocaleString('en-US')
}

function StatCard({ color, icon, category, value, footer, to }) {
  const body = (
    <>
      <div className={`md-stat-icon md-${color}`}>
        <i className={`bi ${icon}`} />
      </div>
      <p className="md-stat-category">{category}</p>
      <h3 className="md-stat-title">{value}</h3>
      <div className="md-stat-footer">
        <i className="bi bi-clock-history" />
        <span>{footer}</span>
      </div>
    </>
  )
  if (to) return <Link to={to} className="md-stat-card">{body}</Link>
  return <div className="md-stat-card">{body}</div>
}

function ChartCard({ color, title, subtitle, children }) {
  return (
    <div className="md-chart-card">
      <div className={`md-chart-header md-${color}`}>{children}</div>
      <div className="md-chart-body">
        <h4>{title}</h4>
        <p>{subtitle}</p>
      </div>
    </div>
  )
}

export default function Dashboard() {
  const { user, hasRole } = useAuth()
  const canOps = hasRole('admin', 'secretary', 'finance')
  const canStaff = hasRole('admin', 'secretary', 'education')
  const isFinanceOnly = user?.role === 'finance'
  const isTeacherOnly = user?.role === 'teacher'
  const staffPath = (path) => (isFinanceOnly ? undefined : path)
  const [summary, setSummary] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!canOps) return undefined
    setLoading(true)
    api
      .get('/reports/summary')
      .then(setSummary)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [canOps])

  const enrollData = useMemo(
    () =>
      (summary?.enrollments_by_status || []).map((r) => ({
        name: ENROLL_STATUS_FA[r.label] || r.label,
        value: Number(r.value) || 0,
      })),
    [summary],
  )

  const classData = useMemo(
    () =>
      (summary?.classes_by_status || []).map((r) => ({
        name: CLASS_STATUS_FA[r.label] || r.label,
        value: Number(r.value) || 0,
      })),
    [summary],
  )

  const langData = useMemo(
    () =>
      (summary?.courses_by_language || []).map((r) => ({
        name: r.label,
        value: Number(r.value) || 0,
      })),
    [summary],
  )

  const paymentStatusData = useMemo(
    () =>
      (summary?.payments_by_status || []).map((r) => ({
        name: PAYMENT_STATUS_FA[r.label] || r.label,
        value: Number(r.value) || 0,
        amount: Number(r.amount) || 0,
        key: r.label,
      })),
    [summary],
  )

  const financeStatusData = useMemo(
    () =>
      (summary?.finance_by_status || []).map((r) => ({
        name: FINANCE_STATUS_FA[r.label] || r.label,
        value: Number(r.value) || 0,
        key: r.label,
        fill: FINANCE_COLORS[r.label] || '#607d8b',
      })),
    [summary],
  )

  const capTotal = summary?.capacity_total || 0
  const capUsed = summary?.capacity_used || 0
  const capPct = capTotal > 0 ? Math.min(100, Math.round((capUsed / capTotal) * 100)) : 0

  const capacitySeries = useMemo(
    () => [
      { name: 'آزاد', value: Math.max(capTotal - capUsed, 0) },
      { name: 'اشغال', value: capUsed },
    ],
    [capTotal, capUsed],
  )

  const links = [
    { to: '/courses', title: 'دوره‌ها', icon: 'bi-journal-bookmark' },
    user?.student_ref && !isFinanceOnly && !isTeacherOnly && { to: '/my-courses', title: 'دوره‌های من', icon: 'bi-journal-bookmark-fill' },
    user?.student_ref && !isFinanceOnly && !isTeacherOnly && { to: '/placement', title: 'آزمون تعیین سطح', icon: 'bi-clipboard2-check' },
    canStaff && { to: '/classes', title: 'کلاس‌ها', icon: 'bi-people' },
    canStaff && { to: '/sessions', title: 'جلسات', icon: 'bi-calendar3' },
    canStaff && { to: '/scores', title: 'نمرات و تعیین سطح', icon: 'bi-clipboard2-data' },
    isTeacherOnly && { to: '/scores', title: 'نمرات', icon: 'bi-clipboard2-data' },
    (canStaff || hasRole('teacher')) && { to: '/placement/bank', title: 'مخزن آزمون تعیین سطح', icon: 'bi-ui-checks-grid' },
    canStaff && { to: '/students', title: 'زبان‌آموزان', icon: 'bi-mortarboard' },
    canStaff && { to: '/teachers', title: 'مدرسان', icon: 'bi-person-workspace' },
    canStaff && { to: '/enrollments', title: 'ثبت‌نام‌ها', icon: 'bi-clipboard-check' },
    (canStaff || isFinanceOnly) && { to: '/payments', title: 'پرداخت‌ها', icon: 'bi-wallet2' },
    hasRole('admin') && { to: '/activities', title: 'فعالیت‌ها', icon: 'bi-clock-history' },
  ].filter(Boolean)

  return (
    <div className="md-dash container-fluid px-3 px-lg-4 py-4">
      <div className="md-dash-top">
        <div>
          <h1 className="md-dash-title">داشبورد</h1>
          <p className="md-dash-sub">
            {user?.full_name || user?.username}
            <span> · {roleLabel(user?.role)}</span>
          </p>
        </div>
        <nav className="md-breadcrumb">
          <Link to="/">خانه</Link>
          <span>/</span>
          <strong>داشبورد</strong>
        </nav>
      </div>

      {canOps && loading && <Loading />}
      {canOps && error && <div className="alert alert-warning">{error}</div>}

      {canOps && summary && (
        <>
          <div className="row g-4 mb-2">
            <div className="col-sm-6 col-xl-3">
              <StatCard
                color="rose"
                icon="bi-mortarboard-fill"
                category="زبان‌آموز فعال"
                value={num(summary.students)}
                footer="به‌روز از پایگاه داده"
                to={staffPath('/students')}
              />
            </div>
            <div className="col-sm-6 col-xl-3">
              <StatCard
                color="info"
                icon="bi-person-badge-fill"
                category="مدرس"
                value={num(summary.teachers)}
                footer={`${num(summary.sessions_scheduled)} جلسه برنامه‌ریزی‌شده`}
                to={staffPath('/teachers')}
              />
            </div>
            <div className="col-sm-6 col-xl-3">
              <StatCard
                color="success"
                icon="bi-journal-bookmark-fill"
                category="دوره فعال"
                value={num(summary.courses)}
                footer={`${num(summary.languages)} زبان`}
                to="/courses"
              />
            </div>
            <div className="col-sm-6 col-xl-3">
              <StatCard
                color="warning"
                icon="bi-wallet2"
                category="پرداخت موفق"
                value={formatMoney(summary.payments_paid_total)}
                footer={`${num(summary.enrollments_active)} ثبت‌نام فعال`}
                to="/payments"
              />
            </div>
          </div>

          <div className="row g-4 mb-2">
            <div className="col-sm-6 col-xl-3">
              <StatCard
                color="primary"
                icon="bi-door-open-fill"
                category="کلاس باز / جاری"
                value={num(summary.classes_open)}
                footer={`از ${num(summary.classes_total)} کلاس`}
                to={staffPath('/classes')}
              />
            </div>
            <div className="col-sm-6 col-xl-3">
              <StatCard
                color="danger"
                icon="bi-clipboard2-check-fill"
                category="ثبت‌نام فعال"
                value={num(summary.enrollments_active)}
                footer={`${num(summary.enrollments_total)} کل ثبت‌نام`}
                to={staffPath('/enrollments')}
              />
            </div>
            <div className="col-sm-6 col-xl-3">
              <StatCard
                color="teal"
                icon="bi-calendar-event-fill"
                category="جلسات scheduled"
                value={num(summary.sessions_scheduled)}
                footer="وضعیت برنامه‌ریزی‌شده"
                to={staffPath('/sessions')}
              />
            </div>
            <div className="col-sm-6 col-xl-3">
              <StatCard
                color="orange"
                icon="bi-speedometer2"
                category="اشغال ظرفیت"
                value={`${capPct}%`}
                footer={`${num(capUsed)} / ${num(capTotal)}`}
              />
            </div>
          </div>

          <div className="row g-4 mt-1">
            <div className="col-lg-4">
              <ChartCard color="rose" title="وضعیت ثبت‌نام‌ها" subtitle="توزیع بر اساس Status">
                <div className="md-chart-box">
                  <ResponsiveContainer width="100%" height={220}>
                    <PieChart>
                      <Pie
                        data={enrollData}
                        dataKey="value"
                        nameKey="name"
                        cx="50%"
                        cy="50%"
                        innerRadius={48}
                        outerRadius={78}
                        paddingAngle={2}
                      >
                        {enrollData.map((entry, i) => (
                          <Cell key={entry.name} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip formatter={(v) => num(v)} />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </ChartCard>
            </div>

            <div className="col-lg-4">
              <ChartCard color="success" title="وضعیت کلاس‌ها" subtitle="تعداد در هر وضعیت">
                <div className="md-chart-box">
                  <ResponsiveContainer width="100%" height={220}>
                    <BarChart data={classData} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.25)" />
                      <XAxis dataKey="name" tick={{ fill: '#fff', fontSize: 11 }} axisLine={false} tickLine={false} />
                      <YAxis tick={{ fill: '#fff', fontSize: 11 }} axisLine={false} tickLine={false} allowDecimals={false} />
                      <Tooltip formatter={(v) => num(v)} />
                      <Bar dataKey="value" fill="#fff" radius={[6, 6, 0, 0]} maxBarSize={36} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </ChartCard>
            </div>

            <div className="col-lg-4">
              <ChartCard color="info" title="دوره بر اساس زبان" subtitle="توزیع کاتالوگ فعال">
                <div className="md-chart-box">
                  <ResponsiveContainer width="100%" height={220}>
                    <AreaChart data={langData.length ? langData : [{ name: '—', value: 0 }]} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
                      <defs>
                        <linearGradient id="langFill" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="0%" stopColor="#fff" stopOpacity={0.9} />
                          <stop offset="100%" stopColor="#fff" stopOpacity={0.15} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.25)" />
                      <XAxis dataKey="name" tick={{ fill: '#fff', fontSize: 11 }} axisLine={false} tickLine={false} />
                      <YAxis tick={{ fill: '#fff', fontSize: 11 }} axisLine={false} tickLine={false} allowDecimals={false} />
                      <Tooltip formatter={(v) => num(v)} />
                      <Area type="monotone" dataKey="value" stroke="#fff" fill="url(#langFill)" strokeWidth={2} />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </ChartCard>
            </div>
          </div>

          <div className="row g-4 mt-1">
            <div className="col-lg-6">
              <ChartCard color="warning" title="وضعیت پرداخت‌ها" subtitle="تعداد و مبلغ بر اساس وضعیت">
                <div className="md-chart-box">
                  <ResponsiveContainer width="100%" height={220}>
                    <PieChart>
                      <Pie
                        data={paymentStatusData.length ? paymentStatusData : [{ name: '—', value: 0 }]}
                        dataKey="value"
                        nameKey="name"
                        cx="50%"
                        cy="50%"
                        innerRadius={48}
                        outerRadius={78}
                        paddingAngle={2}
                      >
                        {(paymentStatusData.length ? paymentStatusData : [{ name: '—' }]).map((entry, i) => (
                          <Cell key={entry.name} fill={PAYMENT_COLORS[i % PAYMENT_COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip
                        formatter={(v, _n, item) => {
                          const amount = item?.payload?.amount
                          return amount != null
                            ? `${num(v)} مورد · ${formatMoney(amount)}`
                            : num(v)
                        }}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </ChartCard>
            </div>
            <div className="col-lg-6">
              <ChartCard color="rose" title="بدهکار / بستانکار / تسویه" subtitle="وضعیت مالی ثبت‌نام‌ها">
                <div className="md-chart-box">
                  <ResponsiveContainer width="100%" height={220}>
                    <BarChart
                      data={financeStatusData.length ? financeStatusData : [{ name: '—', value: 0, fill: '#fff' }]}
                      margin={{ top: 8, right: 8, left: -18, bottom: 0 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.25)" />
                      <XAxis dataKey="name" tick={{ fill: '#fff', fontSize: 11 }} axisLine={false} tickLine={false} />
                      <YAxis tick={{ fill: '#fff', fontSize: 11 }} axisLine={false} tickLine={false} allowDecimals={false} />
                      <Tooltip formatter={(v) => num(v)} />
                      <Bar dataKey="value" radius={[6, 6, 0, 0]} maxBarSize={48}>
                        {(financeStatusData.length ? financeStatusData : []).map((entry) => (
                          <Cell key={entry.key || entry.name} fill="#fff" />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </ChartCard>
            </div>
          </div>

          <div className="row g-4 mt-1">
            <div className="col-lg-8">
              <div className="md-plain-card">
                <div className="md-plain-head">
                  <h4>ظرفیت کلاس‌های فعال</h4>
                  <span>
                    {num(capUsed)} ثبت‌نام از {num(capTotal)} ظرفیت ({capPct}%)
                  </span>
                </div>
                <div className="md-progress">
                  <div className="md-progress-bar" style={{ width: `${capPct}%` }} />
                </div>
                <div className="md-chart-box md-chart-box-light">
                  <ResponsiveContainer width="100%" height={180}>
                    <BarChart data={capacitySeries} layout="vertical" margin={{ top: 8, right: 16, left: 24, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#eef2f7" />
                      <XAxis type="number" tick={{ fontSize: 12 }} allowDecimals={false} />
                      <YAxis type="category" dataKey="name" tick={{ fontSize: 12 }} width={48} />
                      <Tooltip formatter={(v) => num(v)} />
                      <Bar dataKey="value" radius={[0, 8, 8, 0]} maxBarSize={28}>
                        <Cell fill="#00bcd4" />
                        <Cell fill="#e91e63" />
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>
            <div className="col-lg-4">
              <div className="md-plain-card h-100">
                <div className="md-plain-head">
                  <h4>میانبرها</h4>
                  <span>دسترسی سریع</span>
                </div>
                <div className="md-shortcuts">
                  {links.map((link) => (
                    <Link key={link.to} to={link.to} className="md-shortcut">
                      <span className="md-shortcut-icon">
                        <i className={`bi ${link.icon}`} />
                      </span>
                      <span>{link.title}</span>
                      <i className="bi bi-chevron-left ms-auto opacity-50" />
                    </Link>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </>
      )}

      {!canOps && isTeacherOnly && <TeacherDashboard />}

      {!canOps && !isTeacherOnly && (
        <div className="row g-4">
          {user?.student_ref && (
            <div className="col-md-6 col-xl-4">
              <StatCard
                color="success"
                icon="bi-journal-bookmark-fill"
                category="دوره‌های من"
                value="مشاهده"
                footer="وضعیت ثبت‌نام و کلاس‌ها"
                to="/my-courses"
              />
            </div>
          )}
          {user?.student_ref && (
            <div className="col-md-6 col-xl-4">
              <StatCard
                color="info"
                icon="bi-clipboard2-check"
                category="آزمون تعیین سطح"
                value="شروع"
                footer="شرکت آنلاین و اعلام خودکار سطح"
                to="/placement"
              />
            </div>
          )}
          <div className="col-md-6 col-xl-8">
            <div className="md-plain-card h-100">
              <div className="md-plain-head">
                <h4>میانبرها</h4>
              </div>
              <div className="md-shortcuts">
                {links.map((link) => (
                  <Link key={link.to} to={link.to} className="md-shortcut">
                    <span className="md-shortcut-icon">
                      <i className={`bi ${link.icon}`} />
                    </span>
                    <span>{link.title}</span>
                  </Link>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
