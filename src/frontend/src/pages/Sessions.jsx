import { useEffect, useMemo, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker, {
  compareJalali,
  todayJalaliString,
} from '../components/JalaliDatePicker'
import PaginationBar from '../components/PaginationBar'
import { useClientPagination } from '../hooks/useClientPagination'

const emptyForm = {
  class_ref: '',
  date: '',
  start_time: '10:00',
  end_time: '11:30',
  session_type_ref: '',
  is_makeup: '0',
  meeting_link: '',
  location_address: '',
  status: 'scheduled',
  cancel_reason: '',
  notes: '',
}

const STATUS_LABEL = {
  scheduled: 'برنامه‌ریزی‌شده',
  in_progress: 'در حال برگزاری',
  completed: 'برگزار شده',
  cancelled: 'لغو شده',
  rescheduled: 'جابه‌جا شده',
}

function normalizeTime(value) {
  const v = (value || '').trim()
  if (/^\d{2}:\d{2}:\d{2}$/.test(v)) return v.slice(0, 5)
  return v
}

function isValidTime(value) {
  return /^([01]\d|2[0-3]):[0-5]\d$/.test(normalizeTime(value))
}

export default function Sessions() {
  const [rows, setRows] = useState([])
  const [classes, setClasses] = useState([])
  const [sessionTypes, setSessionTypes] = useState([])
  const [search, setSearch] = useState('')
  const [form, setForm] = useState(emptyForm)
  const [editId, setEditId] = useState(null)
  const [editOriginalDate, setEditOriginalDate] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const today = useMemo(() => todayJalaliString(), [])
  const dateIsPastLocked = Boolean(editId && editOriginalDate && compareJalali(editOriginalDate, today) < 0)
  const paging = useClientPagination(rows)

  async function load(q = search) {
    setLoading(true)
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const [s, c, st] = await Promise.all([
        api.get(`/sessions${query}`),
        api.get('/classes'),
        api.get('/session-types'),
      ])
      setRows(s.sessions || [])
      setClasses(c.classes || [])
      setSessionTypes(st.session_types || [])
      setError('')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    const t = setTimeout(() => load(search), 250)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search])

  function resetForm() {
    setEditId(null)
    setEditOriginalDate('')
    setForm(emptyForm)
  }

  function startEdit(row) {
    setEditId(row.Id)
    setEditOriginalDate(row.Date || '')
    setForm({
      class_ref: String(row.ClassRef || ''),
      date: row.Date || '',
      start_time: normalizeTime(row.StartTime) || '10:00',
      end_time: normalizeTime(row.EndTime) || '11:30',
      session_type_ref: String(row.SessionTypeRef || ''),
      is_makeup: row.IsMakeup ? '1' : '0',
      meeting_link: row.MeetingLink || '',
      location_address: row.LocationAddress || '',
      status: row.Status || 'scheduled',
      cancel_reason: row.CancelReason || '',
      notes: row.Notes || '',
    })
    setError('')
    setMessage('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  function validateBeforeSave(dateValue) {
    if (!dateValue) {
      setError('تاریخ جلسه را انتخاب کنید')
      return false
    }
    const isPast = compareJalali(dateValue, today) < 0
    if (isPast && (!editId || dateValue !== editOriginalDate)) {
      setError('ثبت جلسه با تاریخ گذشته مجاز نیست')
      return false
    }
    if (!isValidTime(form.start_time) || !isValidTime(form.end_time)) {
      setError('ساعت باید به صورت HH:MM و بین ۰۰:۰۰ تا ۲۳:۵۹ باشد')
      return false
    }
    if (form.start_time >= form.end_time) {
      setError('ساعت پایان باید بعد از شروع باشد')
      return false
    }
    if (form.status === 'cancelled' && !form.cancel_reason.trim()) {
      setError('برای لغو جلسه، دلیل الزامی است')
      return false
    }
    return true
  }

  async function handleSubmit(e) {
    e.preventDefault()
    if (!validateBeforeSave(form.date)) return

    setBusy(true)
    setError('')
    setMessage('')
    try {
      if (editId) {
        await api.put(`/sessions/${editId}`, {
          date: form.date,
          start_time: form.start_time,
          end_time: form.end_time,
          session_type_ref: Number(form.session_type_ref),
          is_makeup: form.is_makeup === '1',
          meeting_link: form.meeting_link || null,
          location_address: form.location_address || null,
          status: form.status,
          cancel_reason: form.cancel_reason.trim() || null,
          notes: form.notes.trim() || null,
        })
        setMessage('جلسه ویرایش شد')
      } else {
        await api.post('/sessions', {
          class_ref: Number(form.class_ref),
          date: form.date,
          start_time: form.start_time,
          end_time: form.end_time,
          session_type_ref: Number(form.session_type_ref),
          is_makeup: form.is_makeup === '1',
          meeting_link: form.meeting_link || null,
          location_address: form.location_address || null,
          notes: form.notes.trim() || null,
        })
        setMessage('جلسه ثبت شد')
      }
      resetForm()
      await load(search)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function handleDelete(row) {
    if (!window.confirm(`حذف جلسه #${row.Id} (${row.CourseName})؟`)) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/sessions/${row.Id}`)
      setMessage('جلسه لغو شد')
      if (editId === row.Id) resetForm()
      await load(search)
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="container py-4">
      <div className="page-head d-flex flex-wrap justify-content-between align-items-end gap-2">
        <div>
          <h1 className="section-title h3 mb-1">جلسات</h1>
          <p className="muted mb-0">
            ثبت و ویرایش زمان‌بندی — تاریخ گذشته مجاز نیست
          </p>
        </div>
        <input
          className="form-control"
          style={{ maxWidth: 240 }}
          placeholder="جستجو..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      <div className="create-panel">
        <div className="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
          <h2 className="h6 fw-bold mb-0">
            {editId ? `ویرایش جلسه #${editId}` : 'ثبت جلسه جدید'}
          </h2>
          {editId && (
            <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetForm}>
              انصراف از ویرایش
            </button>
          )}
        </div>
        <form className="row g-2" onSubmit={handleSubmit}>
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
            <label className="form-label">تاریخ شمسی</label>
            <JalaliDatePicker
              required
              disabled={dateIsPastLocked}
              minDate={dateIsPastLocked ? '' : today}
              value={form.date}
              onChange={(v) => setForm((p) => ({ ...p, date: v }))}
            />
            <div className="form-text">
              {dateIsPastLocked
                ? 'تاریخ جلسه گذشته قفل است؛ سایر فیلدها قابل ویرایش‌اند'
                : 'از امروز به بعد'}
            </div>
          </div>
          <div className="col-md-4">
            <label className="form-label">نوع جلسه</label>
            <VazirSelect
              required
              value={form.session_type_ref}
              onChange={(v) => setForm((p) => ({ ...p, session_type_ref: v }))}
              options={sessionTypes.map((s) => ({ value: String(s.Id), label: s.Name }))}
            />
          </div>
          <div className="col-md-3">
            <label className="form-label">ساعت شروع</label>
            <input
              type="time"
              className="form-control"
              value={form.start_time}
              onChange={(e) => setForm((p) => ({ ...p, start_time: e.target.value }))}
              min="00:00"
              max="23:59"
              step="60"
              required
            />
          </div>
          <div className="col-md-3">
            <label className="form-label">ساعت پایان</label>
            <input
              type="time"
              className="form-control"
              value={form.end_time}
              onChange={(e) => setForm((p) => ({ ...p, end_time: e.target.value }))}
              min="00:00"
              max="23:59"
              step="60"
              required
            />
          </div>
          <div className="col-md-3">
            <label className="form-label">جبرانی؟</label>
            <VazirSelect
              value={form.is_makeup}
              onChange={(v) => setForm((p) => ({ ...p, is_makeup: v }))}
              options={[
                { value: '0', label: 'خیر' },
                { value: '1', label: 'بله' },
              ]}
            />
          </div>
          {editId && (
            <div className="col-md-3">
              <label className="form-label">وضعیت</label>
              <VazirSelect
                value={form.status}
                onChange={(v) => setForm((p) => ({ ...p, status: v }))}
                options={Object.entries(STATUS_LABEL).map(([value, label]) => ({
                  value,
                  label,
                }))}
              />
            </div>
          )}
          <div className="col-md-3">
            <label className="form-label">لینک آنلاین</label>
            <input
              className="form-control"
              value={form.meeting_link}
              onChange={(e) => setForm((p) => ({ ...p, meeting_link: e.target.value }))}
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">آدرس حضوری</label>
            <input
              className="form-control"
              value={form.location_address}
              onChange={(e) => setForm((p) => ({ ...p, location_address: e.target.value }))}
            />
          </div>
          {editId && form.status === 'cancelled' && (
            <div className="col-md-6">
              <label className="form-label">دلیل لغو</label>
              <input
                className="form-control"
                value={form.cancel_reason}
                onChange={(e) => setForm((p) => ({ ...p, cancel_reason: e.target.value }))}
                required
              />
            </div>
          )}
          <div className="col-md-6">
            <label className="form-label">یادداشت</label>
            <input
              className="form-control"
              value={form.notes}
              onChange={(e) => setForm((p) => ({ ...p, notes: e.target.value }))}
            />
          </div>
          <div className="col-md-3 d-grid align-items-end">
            <button className="btn btn-brand rounded-pill" disabled={busy}>
              {busy ? '...' : editId ? 'ذخیره تغییرات' : 'ثبت جلسه'}
            </button>
          </div>
        </form>
      </div>

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
                <th>دوره</th>
                <th>تاریخ</th>
                <th>ساعت</th>
                <th>نوع</th>
                <th>وضعیت</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
                  <tr key={row.Id}>
                    <td>{row.Id}</td>
                    <td>{row.CourseName}</td>
                    <td>{row.Date}</td>
                    <td>
                      {normalizeTime(row.StartTime)} - {normalizeTime(row.EndTime)}
                    </td>
                    <td>{row.SessionTypeName}</td>
                    <td>{STATUS_LABEL[row.Status] || row.Status}</td>
                    <td className="text-nowrap">
                      <button
                        type="button"
                        className="btn btn-sm btn-outline-success rounded-pill me-1"
                        onClick={() => startEdit(row)}
                      >
                        ویرایش
                      </button>
                      <button
                        type="button"
                        className="btn btn-sm btn-outline-danger rounded-pill"
                        onClick={() => handleDelete(row)}
                      >
                        حذف
                      </button>
                    </td>
                  </tr>
                ))}
              {!rows.length && (
                <tr>
                  <td colSpan={7} className="text-center muted py-4">
                    جلسه‌ای ثبت نشده است
                  </td>
                </tr>
              )}
            </tbody>
          </table>
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
