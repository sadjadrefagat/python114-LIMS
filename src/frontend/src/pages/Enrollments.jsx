import { useEffect, useMemo, useState } from 'react'
import { api, formatMoney } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker from '../components/JalaliDatePicker'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import FinanceStatus, { financeStatusLabel } from '../components/FinanceStatus'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'

const statusMap = {
  pending_payment: 'در انتظار پرداخت',
  pending_approval: 'در انتظار تأیید',
  active: 'فعال',
  frozen: 'معلق',
  completed: 'تکمیل‌شده',
  withdrawn: 'انصراف',
  transferred: 'انتقال',
}

const balanceFilterOptions = [
  { value: '', label: 'همه مانده‌ها' },
  { value: 'debtor', label: 'بدهکار (مانده منفی)' },
  { value: 'creditor', label: 'بستانکار (مانده مثبت)' },
  { value: 'settled', label: 'تسویه‌شده (مانده صفر)' },
  { value: 'nonzero', label: 'فقط دارای مانده' },
]

const emptyForm = {
  student_refs: [],
  student_ref: '',
  class_ref: '',
  date: '',
  status: 'pending_payment',
  withdraw_reason: '',
}

const emptyFilters = {
  search: '',
  status: '',
  balance_filter: '',
  student_ref: '',
  course_ref: '',
  class_ref: '',
}

function AccountBalance({ balance, debtAmount, creditAmount }) {
  const bal = Number(balance)
  const debt = debtAmount != null ? Number(debtAmount) : Math.max(0, -bal)
  const credit = creditAmount != null ? Number(creditAmount) : Math.max(0, bal)

  if (bal < 0) {
    return (
      <div className="account-balance is-debt" title={`بدهی: ${formatMoney(debt)}`}>
        <span className="account-balance-label">بدهکار</span>
        <strong>{formatMoney(debt)}</strong>
      </div>
    )
  }
  if (bal > 0) {
    return (
      <div className="account-balance is-credit" title={`بستانکاری: ${formatMoney(credit)}`}>
        <span className="account-balance-label">بستانکار</span>
        <strong>{formatMoney(credit)}</strong>
      </div>
    )
  }
  return (
    <div className="account-balance is-settled" title="مانده صفر">
      <span className="account-balance-label">تسویه</span>
      <strong>{formatMoney(0)}</strong>
    </div>
  )
}

export default function Enrollments() {
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [rows, setRows] = useState([])
  const [students, setStudents] = useState([])
  const [classes, setClasses] = useState([])
  const [courses, setCourses] = useState([])
  const [filters, setFilters] = useState(emptyFilters)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [showFilters, setShowFilters] = useState(true)
  const [editId, setEditId] = useState(null)
  const [form, setForm] = useState(emptyForm)
  const paging = useClientPagination(rows)

  const activeFilterCount = useMemo(() => {
    return Object.entries(filters).filter(([k, v]) => k !== 'search' && String(v || '').trim()).length
      + (filters.search.trim() ? 1 : 0)
  }, [filters])

  function setFilter(key, value) {
    setFilters((p) => ({ ...p, [key]: value == null ? '' : String(value) }))
  }

  async function load(f = filters) {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      if (f.search.trim()) params.set('search', f.search.trim())
      if (f.status) params.set('status', f.status)
      if (f.balance_filter) params.set('balance_filter', f.balance_filter)
      if (f.student_ref) params.set('student_ref', f.student_ref)
      if (f.course_ref) params.set('course_ref', f.course_ref)
      if (f.class_ref) params.set('class_ref', f.class_ref)
      const q = params.toString()
      const [en, st, cl, co] = await Promise.all([
        api.get(`/enrollments${q ? `?${q}` : ''}`),
        api.get('/students'),
        api.get('/classes'),
        api.get('/courses'),
      ])
      setRows(en.enrollments || [])
      setStudents(st.students || [])
      setClasses(cl.classes || [])
      setCourses(co.courses || [])
      setError('')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    const t = setTimeout(() => load(filters), 250)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters])

  function resetForm() {
    setEditId(null)
    setForm(emptyForm)
    setShowCreate(false)
  }

  function startEdit(row) {
    setEditId(row.Id)
    setForm({
      student_refs: [],
      student_ref: String(row.StudentRef || ''),
      class_ref: row.ClassRef ? String(row.ClassRef) : '',
      date: row.Date || '',
      status: row.Status || 'pending_payment',
      withdraw_reason: row.WithdrawReason || '',
    })
    setShowCreate(true)
    setMessage('')
    setError('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')

    if (editId && form.status === 'withdrawn' && !form.withdraw_reason.trim()) {
      setError('برای انصراف، دلیل الزامی است')
      setBusy(false)
      return
    }

    if (!editId && !form.student_refs.length) {
      setError('حداقل یک زبان‌آموز انتخاب کنید')
      setBusy(false)
      return
    }

    try {
      if (editId) {
        await api.put(`/enrollments/${editId}`, {
          status: form.status,
          withdraw_reason: form.status === 'withdrawn' ? form.withdraw_reason.trim() : null,
        })
        setMessage('ثبت‌نام ویرایش شد')
      } else {
        const payload = {
          student_refs: form.student_refs.map(Number),
          class_ref: Number(form.class_ref),
          date: form.date,
          status: form.status,
        }
        const res = await api.post('/enrollments/bulk', payload)
        const n = res.count ?? res.ids?.length ?? form.student_refs.length
        setMessage(n > 1 ? `${n} ثبت‌نام انجام شد` : 'ثبت‌نام انجام شد')
      }
      resetForm()
      await load(filters)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function handleDelete(row) {
    if (row.Status === 'withdrawn') {
      setError('این ثبت‌نام قبلاً لغو شده است')
      return
    }
    const ok = await askConfirm({
      title: 'حذف ثبت‌نام',
      message: 'این ثبت‌نام از فهرست حذف می‌شود (انصراف منطقی). در صورت نیاز می‌توانید با فیلتر «انصراف» آن را ببینید.',
      confirmLabel: 'حذف',
      cancelLabel: 'بازگشت',
      details: [
        { label: 'زبان‌آموز', value: row.StudentName },
        { label: 'دوره', value: row.CourseName },
        { label: 'کلاس', value: row.ClassRef ? `#${row.ClassRef}` : null },
        { label: 'وضعیت', value: statusMap[row.Status] || row.Status },
        { label: 'مالی', value: financeStatusLabel(row.FinancialStatus) },
        {
          label: 'مانده حساب',
          value:
            Number(row.Balance) < 0
              ? `بدهی ${formatMoney(row.DebtAmount ?? -row.Balance)}`
              : Number(row.Balance) > 0
                ? `بستانکاری ${formatMoney(row.CreditAmount ?? row.Balance)}`
                : formatMoney(0),
        },
        { label: 'تاریخ', value: row.Date },
      ],
    })
    if (!ok) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/enrollments/${row.Id}`)
      setRows((prev) => prev.filter((r) => r.Id !== row.Id))
      setMessage('ثبت‌نام حذف شد')
      if (editId === row.Id) resetForm()
      await load(filters)
    } catch (err) {
      setError(err.message)
    }
  }

  const studentOptions = students.map((s) => ({
    value: String(s.Id),
    label: `${s.FirstName} ${s.LastName}`,
  }))

  const totals = useMemo(() => {
    let debt = 0
    let credit = 0
    let paid = 0
    let cost = 0
    for (const r of rows) {
      debt += Number(r.DebtAmount ?? Math.max(0, -(r.Balance || 0))) || 0
      credit += Number(r.CreditAmount ?? Math.max(0, r.Balance || 0)) || 0
      paid += Number(r.PaidAmount) || 0
      cost += Number(r.CourseCost) || 0
    }
    return { debt, credit, paid, cost, count: rows.length }
  }, [rows])

  return (
    <div className="container py-4">
      {confirmDialog}
      <div className="page-head d-flex justify-content-between flex-wrap gap-2">
        <div>
          <h1 className="section-title h3 mb-1">ثبت‌نام‌ها</h1>
          <p className="muted mb-0">وضعیت ثبت‌نام، شهریه و مانده حساب زبان‌آموز</p>
        </div>
        <div className="d-flex gap-2 flex-wrap">
          <button
            type="button"
            className={`btn btn-outline-secondary rounded-pill ${showFilters ? 'active' : ''}`}
            onClick={() => setShowFilters((v) => !v)}
          >
            <i className="bi bi-funnel me-1" />
            فیلترها
            {activeFilterCount > 0 && (
              <span className="badge text-bg-primary ms-1">{activeFilterCount}</span>
            )}
          </button>
          <button
            className="btn btn-brand rounded-pill"
            onClick={() => (showCreate ? resetForm() : setShowCreate(true))}
          >
            {showCreate ? 'بستن' : 'ثبت‌نام جدید'}
          </button>
        </div>
      </div>

      {showFilters && (
        <div className="card border-0 shadow-sm mb-3 enrollments-filter-panel">
          <div className="card-body">
            <div className="row g-3 align-items-end">
              <div className="col-md-4 col-lg-3">
                <label className="form-label">جستجو</label>
                <div className="input-group">
                  <span className="input-group-text">
                    <i className="bi bi-search" />
                  </span>
                  <input
                    className="form-control"
                    placeholder="نام، دوره، کد ثبت‌نام، کلاس…"
                    value={filters.search}
                    onChange={(e) => setFilter('search', e.target.value)}
                  />
                </div>
              </div>
              <div className="col-md-4 col-lg-2">
                <label className="form-label">وضعیت مالی</label>
                <VazirSelect
                  value={filters.balance_filter}
                  onChange={(v) => setFilter('balance_filter', v)}
                  options={balanceFilterOptions}
                />
              </div>
              <div className="col-md-4 col-lg-2">
                <label className="form-label">وضعیت ثبت‌نام</label>
                <VazirSelect
                  value={filters.status}
                  onChange={(v) => setFilter('status', v)}
                  options={[
                    { value: '', label: 'همه (بدون انصراف)' },
                    ...Object.entries(statusMap).map(([value, label]) => ({ value, label })),
                  ]}
                />
              </div>
              <div className="col-md-4 col-lg-2">
                <label className="form-label">زبان‌آموز</label>
                <VazirSelect
                  value={filters.student_ref}
                  onChange={(v) => setFilter('student_ref', v)}
                  options={[{ value: '', label: 'همه زبان‌آموزان' }, ...studentOptions]}
                />
              </div>
              <div className="col-md-4 col-lg-3">
                <label className="form-label">دوره</label>
                <VazirSelect
                  value={filters.course_ref}
                  onChange={(v) => setFilter('course_ref', v)}
                  options={[
                    { value: '', label: 'همه دوره‌ها' },
                    ...courses.map((c) => ({ value: String(c.Id), label: c.Name })),
                  ]}
                />
              </div>
              <div className="col-md-4 col-lg-3">
                <label className="form-label">کلاس</label>
                <VazirSelect
                  value={filters.class_ref}
                  onChange={(v) => setFilter('class_ref', v)}
                  options={[
                    { value: '', label: 'همه کلاس‌ها' },
                    ...classes.map((c) => ({
                      value: String(c.Id),
                      label: `${c.Id} — ${c.CourseName}`,
                    })),
                  ]}
                />
              </div>
              <div className="col-md-4 col-lg-3 d-flex gap-2">
                <button
                  type="button"
                  className="btn btn-outline-danger rounded-pill"
                  disabled={!activeFilterCount}
                  onClick={() => setFilters(emptyFilters)}
                >
                  پاک کردن فیلترها
                </button>
              </div>
            </div>

            <div className="enrollments-quick-filters mt-3">
              <span className="small text-muted ms-1">میانبر:</span>
              {[
                { key: 'balance_filter', value: 'debtor', label: 'بدهکاران', icon: 'bi-exclamation-circle' },
                { key: 'balance_filter', value: 'creditor', label: 'بستانکاران', icon: 'bi-cash-coin' },
                { key: 'balance_filter', value: 'settled', label: 'تسویه‌شده', icon: 'bi-check2-circle' },
                { key: 'balance_filter', value: 'nonzero', label: 'دارای مانده', icon: 'bi-arrows-collapse' },
                { key: 'status', value: 'active', label: 'فعال', icon: 'bi-person-check' },
                { key: 'status', value: 'pending_payment', label: 'در انتظار پرداخت', icon: 'bi-hourglass-split' },
              ].map((chip) => {
                const active = filters[chip.key] === chip.value
                return (
                  <button
                    key={`${chip.key}-${chip.value}`}
                    type="button"
                    className={`shop-chip ${active ? 'is-active' : ''}`}
                    onClick={() =>
                      setFilter(chip.key, active ? '' : chip.value)
                    }
                  >
                    <i className={`bi ${chip.icon} me-1`} />
                    {chip.label}
                  </button>
                )
              })}
            </div>
          </div>
        </div>
      )}

      {!loading && rows.length > 0 && (
        <div className="enrollments-finance-summary mb-3">
          <div className="efs-item">
            <span>تعداد</span>
            <strong>{totals.count}</strong>
          </div>
          <div className="efs-item">
            <span>جمع شهریه</span>
            <strong>{formatMoney(totals.cost)}</strong>
          </div>
          <div className="efs-item">
            <span>جمع پرداخت</span>
            <strong>{formatMoney(totals.paid)}</strong>
          </div>
          <div className="efs-item is-debt">
            <span>جمع بدهی</span>
            <strong>{formatMoney(totals.debt)}</strong>
          </div>
          <div className="efs-item is-credit">
            <span>جمع بستانکاری</span>
            <strong>{formatMoney(totals.credit)}</strong>
          </div>
        </div>
      )}

      {showCreate && (
        <div className="create-panel">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h2 className="h6 fw-bold mb-0">
              {editId ? `ویرایش ثبت‌نام #${editId}` : 'ثبت‌نام جدید'}
            </h2>
            {editId && (
              <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetForm}>
                انصراف
              </button>
            )}
          </div>
          <form className="row g-2" onSubmit={handleSubmit}>
            <div className="col-md-4">
              <label className="form-label">
                زبان‌آموز{!editId ? ' (چندتایی)' : ''}
              </label>
              {editId ? (
                <VazirSelect
                  required
                  disabled
                  value={form.student_ref}
                  onChange={(v) => setForm((p) => ({ ...p, student_ref: v }))}
                  options={studentOptions}
                />
              ) : (
                <VazirSelect
                  required
                  multiple
                  placeholder="انتخاب یک یا چند زبان‌آموز"
                  value={form.student_refs}
                  onChange={(v) => setForm((p) => ({ ...p, student_refs: v }))}
                  options={studentOptions}
                />
              )}
            </div>
            <div className="col-md-4">
              <label className="form-label">کلاس</label>
              <VazirSelect
                required
                disabled={Boolean(editId)}
                value={form.class_ref}
                onChange={(v) => setForm((p) => ({ ...p, class_ref: v }))}
                options={classes.map((c) => ({
                  value: String(c.Id),
                  label: `${c.Id} — ${c.CourseName}`,
                }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">تاریخ ثبت‌نام</label>
              <JalaliDatePicker
                required
                disabled={Boolean(editId)}
                value={form.date}
                onChange={(v) => setForm((p) => ({ ...p, date: v }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">وضعیت</label>
              <VazirSelect
                value={form.status}
                onChange={(v) => setForm((p) => ({ ...p, status: v }))}
                options={Object.entries(statusMap).map(([value, label]) => ({ value, label }))}
              />
            </div>
            {editId && (
              <div className="col-md-4">
                <label className="form-label">وضعیت مالی (خودکار)</label>
                <div className="form-control bg-light">
                  بر اساس شهریه و پرداخت محاسبه می‌شود
                </div>
              </div>
            )}
            {editId && form.status === 'withdrawn' && (
              <div className="col-md-4">
                <label className="form-label">دلیل انصراف</label>
                <input
                  className="form-control"
                  value={form.withdraw_reason}
                  onChange={(e) => setForm((p) => ({ ...p, withdraw_reason: e.target.value }))}
                  required
                />
              </div>
            )}
            <div className="col-md-4 d-grid align-items-end">
              <button className="btn btn-brand rounded-pill" disabled={busy}>
                {busy
                  ? '...'
                  : editId
                    ? 'ذخیره'
                    : form.student_refs.length > 1
                      ? `ثبت ${form.student_refs.length} نفر`
                      : 'ثبت'}
              </button>
            </div>
          </form>
          {!editId && form.student_refs.length > 1 && (
            <p className="small text-muted mb-0 mt-2">
              کلاس، تاریخ و وضعیت برای همهٔ {form.student_refs.length} زبان‌آموز اعمال می‌شود.
              وضعیت مالی از روی شهریه و پرداخت‌ها به‌صورت خودکار محاسبه می‌شود.
            </p>
          )}
        </div>
      )}

      {message && <div className="alert alert-success py-2">{message}</div>}
      {error && <div className="alert alert-danger">{error}</div>}
      {loading ? (
        <Loading />
      ) : (
        <div className="panel table-responsive">
          <table className="table table-hover table-zebra mb-0 align-middle">
            <thead>
              <tr>
                <th>کد</th>
                <th>زبان‌آموز</th>
                <th>دوره</th>
                <th>کلاس</th>
                <th>تاریخ</th>
                <th>وضعیت</th>
                <th>شهریه</th>
                <th>پرداخت‌شده</th>
                <th>مانده حساب</th>
                <th>وضعیت مالی</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.StudentName}</td>
                  <td>{row.CourseName}</td>
                  <td>{row.ClassRef || '—'}</td>
                  <td>{row.Date}</td>
                  <td>
                    <span className="chip chip-teal">{statusMap[row.Status] || row.Status}</span>
                  </td>
                  <td className="text-nowrap">{formatMoney(row.CourseCost)}</td>
                  <td className="text-nowrap">{formatMoney(row.PaidAmount)}</td>
                  <td>
                    <AccountBalance
                      balance={row.Balance}
                      debtAmount={row.DebtAmount}
                      creditAmount={row.CreditAmount}
                    />
                  </td>
                  <td style={{ minWidth: 140 }}>
                    <FinanceStatus
                      compact
                      status={row.FinancialStatus}
                      intensity={row.FinanceIntensity}
                      courseCost={row.CourseCost}
                      paidAmount={row.PaidAmount}
                      balance={row.Balance}
                    />
                  </td>
                  <td className="text-nowrap">
                    <RowActions
                      onEdit={() => startEdit(row)}
                      onDelete={row.Status === 'withdrawn' ? undefined : () => handleDelete(row)}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">ثبت‌نامی با این فیلترها یافت نشد.</div>}
          <PaginationBar
            page={paging.page}
            totalPages={paging.totalPages}
            total={paging.total}
            pageSize={paging.pageSize}
            from={paging.from}
            to={paging.to}
            onChange={paging.setPage}
          />
        </div>
      )}
    </div>
  )
}
