import { useEffect, useMemo, useState } from 'react'
import { api, formatMoney } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker, { todayJalaliString } from '../components/JalaliDatePicker'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'

const METHOD_LABEL = {
  cash: 'نقدی',
  card: 'کارت',
  online: 'آنلاین',
  installment: 'اقساط',
  other: 'سایر',
}

const STATUS_LABEL = {
  draft: 'پیش‌نویس',
  pending: 'در انتظار',
  paid: 'پرداخت‌شده',
  failed: 'ناموفق',
  refunded: 'استرداد',
  partially_paid: 'پرداخت جزئی',
  overdue: 'سررسید گذشته',
}

const emptyForm = {
  student_ref: '',
  registration_ref: '',
  amount: '',
  date: todayJalaliString(),
  payment_method: 'cash',
  status: 'paid',
  description: '',
}

export default function Payments() {
  const { hasRole } = useAuth()
  const canPay = hasRole('admin', 'secretary', 'education', 'finance')
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [rows, setRows] = useState([])
  const [students, setStudents] = useState([])
  const [enrollments, setEnrollments] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editId, setEditId] = useState(null)
  const [form, setForm] = useState(emptyForm)

  async function load() {
    setLoading(true)
    setError('')
    try {
      const [pRes, stRes, enRes] = await Promise.allSettled([
        api.get('/payments'),
        api.get('/students'),
        api.get('/enrollments?include_withdrawn=true'),
      ])
      if (pRes.status === 'fulfilled') setRows(pRes.value.payments || [])
      else throw pRes.reason
      if (stRes.status === 'fulfilled') setStudents(stRes.value.students || [])
      if (enRes.status === 'fulfilled') setEnrollments(enRes.value.enrollments || [])
      else setEnrollments([])
      const sideErrors = [stRes, enRes]
        .filter((r) => r.status === 'rejected')
        .map((r) => r.reason?.message)
        .filter(Boolean)
      if (sideErrors.length) setError(sideErrors.join(' — '))
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (!canPay) return undefined
    load()
    return undefined
  }, [canPay])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    if (!q) return rows
    return rows.filter((r) => {
      const blob = `${r.Id} ${r.StudentName || ''} ${r.Amount || ''} ${r.Date || ''} ${r.Description || ''} ${r.RegistrationRef || ''}`.toLowerCase()
      return blob.includes(q)
    })
  }, [rows, search])

  const filteredPaging = useClientPagination(filtered)

  const enrollmentOptions = useMemo(() => {
    const list = form.student_ref
      ? enrollments.filter((e) => String(e.StudentRef) === String(form.student_ref))
      : enrollments
    return list.map((e) => ({
      value: String(e.Id),
      label: `#${e.Id} · ${e.CourseName || 'دوره'} · مانده ${formatMoney(Math.max(0, -(e.Balance || 0)))}`,
    }))
  }, [enrollments, form.student_ref])

  function resetForm() {
    setEditId(null)
    setForm({ ...emptyForm, date: todayJalaliString() })
    setShowForm(false)
  }

  function startCreate() {
    setEditId(null)
    setForm({ ...emptyForm, date: todayJalaliString() })
    setShowForm(true)
    setMessage('')
    setError('')
  }

  function startEdit(row) {
    setEditId(row.Id)
    setForm({
      student_ref: String(row.StudentRef || ''),
      registration_ref: row.RegistrationRef != null ? String(row.RegistrationRef) : '',
      amount: row.Amount != null ? String(row.Amount) : '',
      date: row.Date || todayJalaliString(),
      payment_method: row.PaymentMethod || 'cash',
      status: row.Status || 'paid',
      description: row.Description || '',
    })
    setShowForm(true)
    setMessage('')
    setError('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  async function handleSubmit(e) {
    e.preventDefault()
    if (!form.student_ref) {
      setError('زبان‌آموز را انتخاب کنید')
      return
    }
    if (!form.registration_ref) {
      setError('ثبت‌نام مرتبط الزامی است؛ پرداخت باید به یک ثبت‌نام وصل شود')
      return
    }
    const amount = Number(form.amount)
    if (!Number.isFinite(amount) || amount < 0) {
      setError('مبلغ نامعتبر است')
      return
    }
    setBusy(true)
    setError('')
    setMessage('')
    const payload = {
      student_ref: Number(form.student_ref),
      registration_ref: Number(form.registration_ref),
      amount: Math.round(amount),
      date: form.date,
      payment_method: form.payment_method,
      status: form.status,
      description: form.description.trim() || null,
    }
    try {
      if (editId) {
        await api.put(`/payments/${editId}`, payload)
        setMessage('پرداخت ویرایش شد')
      } else {
        await api.post('/payments', payload)
        setMessage('پرداخت ثبت شد')
      }
      resetForm()
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function handleDelete(row) {
    const ok = await askConfirm({
      title: 'حذف پرداخت',
      message: 'این پرداخت برای همیشه حذف می‌شود و مانده ثبت‌نام مرتبط به‌روز می‌گردد.',
      confirmLabel: 'حذف',
      cancelLabel: 'بازگشت',
      details: [
        { label: 'کد', value: `#${row.Id}` },
        { label: 'زبان‌آموز', value: row.StudentName },
        { label: 'مبلغ', value: formatMoney(row.Amount) },
        { label: 'تاریخ', value: row.Date },
        { label: 'وضعیت', value: STATUS_LABEL[row.Status] || row.Status },
        { label: 'ثبت‌نام', value: row.RegistrationRef ? `#${row.RegistrationRef}` : null },
      ],
    })
    if (!ok) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/payments/${row.Id}`)
      setRows((prev) => prev.filter((r) => r.Id !== row.Id))
      setMessage('پرداخت حذف شد')
      if (editId === row.Id) resetForm()
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  if (!canPay) {
    return (
      <div className="container py-4">
        <div className="alert alert-warning">دسترسی به پرداخت‌ها ندارید.</div>
      </div>
    )
  }

  return (
    <div className="container py-4">
      {confirmDialog}
      <div className="page-head d-flex flex-wrap justify-content-between gap-2">
        <div>
          <h1 className="section-title h3 mb-1">پرداخت‌ها</h1>
          <p className="muted mb-0">ثبت، ویرایش و پیگیری پرداخت شهریه زبان‌آموزان</p>
        </div>
        <div className="d-flex gap-2">
          <input
            className="form-control"
            style={{ maxWidth: 220 }}
            placeholder="جستجو"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <button type="button" className="btn btn-brand rounded-pill" onClick={startCreate}>
            ثبت پرداخت
          </button>
        </div>
      </div>

      {showForm && (
        <div className="create-panel">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h2 className="h6 fw-bold mb-0">{editId ? `ویرایش پرداخت #${editId}` : 'پرداخت جدید'}</h2>
            <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetForm}>
              انصراف
            </button>
          </div>
          <form className="row g-2" onSubmit={handleSubmit}>
            <div className="col-md-4">
              <label className="form-label">زبان‌آموز</label>
              <VazirSelect
                required
                value={form.student_ref}
                onChange={(v) => setForm((p) => ({ ...p, student_ref: v, registration_ref: '' }))}
                options={students.map((s) => ({
                  value: String(s.Id),
                  label: `${s.FirstName} ${s.LastName}`,
                }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">ثبت‌نام مرتبط</label>
              <VazirSelect
                required
                value={form.registration_ref}
                onChange={(v) => setForm((p) => ({ ...p, registration_ref: v }))}
                placeholder="انتخاب ثبت‌نام"
                options={enrollmentOptions}
              />
              {!form.student_ref && (
                <div className="form-text">ابتدا زبان‌آموز را انتخاب کنید</div>
              )}
              {form.student_ref && enrollmentOptions.length === 0 && (
                <div className="form-text text-danger">برای این زبان‌آموز ثبت‌نامی یافت نشد</div>
              )}
            </div>
            <div className="col-md-4">
              <label className="form-label">مبلغ (ریال)</label>
              <input
                className="form-control"
                type="number"
                min="0"
                step="1"
                required
                value={form.amount}
                onChange={(e) => setForm((p) => ({ ...p, amount: e.target.value }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">تاریخ</label>
              <JalaliDatePicker
                required
                value={form.date}
                onChange={(v) => setForm((p) => ({ ...p, date: v }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">روش پرداخت</label>
              <VazirSelect
                value={form.payment_method}
                onChange={(v) => setForm((p) => ({ ...p, payment_method: v }))}
                options={Object.entries(METHOD_LABEL).map(([value, label]) => ({ value, label }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">وضعیت</label>
              <VazirSelect
                value={form.status}
                onChange={(v) => setForm((p) => ({ ...p, status: v }))}
                options={[
                  { value: 'paid', label: 'پرداخت‌شده' },
                  { value: 'pending', label: 'در انتظار' },
                  { value: 'draft', label: 'پیش‌نویس' },
                  { value: 'failed', label: 'ناموفق' },
                  { value: 'refunded', label: 'استرداد' },
                ]}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">توضیح</label>
              <input
                className="form-control"
                value={form.description}
                onChange={(e) => setForm((p) => ({ ...p, description: e.target.value }))}
              />
            </div>
            <div className="col-12">
              <button className="btn btn-brand rounded-pill px-4" disabled={busy}>
                {busy ? '...' : editId ? 'ذخیره تغییرات' : 'ثبت پرداخت'}
              </button>
            </div>
          </form>
        </div>
      )}

      {message && <div className="alert alert-success py-2">{message}</div>}
      {error && <div className="alert alert-danger py-2">{error}</div>}

      {loading ? (
        <Loading />
      ) : (
        <div className="panel table-responsive">
          <table className="table table-zebra mb-0 align-middle">
            <thead>
              <tr>
                <th>کد</th>
                <th>زبان‌آموز</th>
                <th>مبلغ</th>
                <th>تاریخ</th>
                <th>روش</th>
                <th>وضعیت</th>
                <th>ثبت‌نام</th>
                <th>توضیح</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {filteredPaging.slice.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.StudentName}</td>
                  <td>{formatMoney(row.Amount)}</td>
                  <td>{row.Date}</td>
                  <td>{METHOD_LABEL[row.PaymentMethod] || row.PaymentMethod}</td>
                  <td>
                    <span className="chip chip-teal">{STATUS_LABEL[row.Status] || row.Status}</span>
                  </td>
                  <td>
                    {row.RegistrationRef ? (
                      `#${row.RegistrationRef}`
                    ) : (
                      <span className="text-danger small fw-semibold" title="در مانده حساب ثبت‌نام لحاظ نمی‌شد">
                        بدون ثبت‌نام
                      </span>
                    )}
                  </td>
                  <td className="small">{row.Description || '—'}</td>
                  <td className="text-nowrap">
                    <RowActions onEdit={() => startEdit(row)} onDelete={() => handleDelete(row)} />
                  </td>
                </tr>
              ))}
              {!filtered.length && (
                <tr>
                  <td colSpan={9} className="text-center muted py-4">
                    پرداختی ثبت نشده است
                  </td>
                </tr>
              )}
            </tbody>
          </table>
          <PaginationBar
            page={filteredPaging.page}
            totalPages={filteredPaging.totalPages}
            total={filteredPaging.total}
            pageSize={filteredPaging.pageSize}
            from={filteredPaging.from}
            to={filteredPaging.to}
            onChange={filteredPaging.setPage}
          />
        </div>
      )}
    </div>
  )
}
