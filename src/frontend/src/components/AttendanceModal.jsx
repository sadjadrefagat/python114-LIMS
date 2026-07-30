import { useEffect, useId, useMemo, useState } from 'react'
import { createPortal } from 'react-dom'
import { api } from '../api/client'
import Loading from './Loading'

const STATUS_OPTIONS = [
  { value: 'present', label: 'حاضر', tone: 'success' },
  { value: 'absent', label: 'غایب', tone: 'danger' },
  { value: 'late', label: 'تأخیر', tone: 'warning' },
  { value: 'leave', label: 'مرخصی', tone: 'info' },
]

function normalizeTime(value) {
  const v = (value || '').trim()
  if (/^\d{2}:\d{2}:\d{2}$/.test(v)) return v.slice(0, 5)
  return v
}

/**
 * مودال ثبت حضور و غیاب زبان‌آموزان یک جلسه
 */
export default function AttendanceModal({ sessionId, open, onClose, onSaved }) {
  const titleId = useId()
  const [session, setSession] = useState(null)
  const [students, setStudents] = useState([])
  const [marks, setMarks] = useState({})
  const [loading, setLoading] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

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
      if (e.key === 'Escape' && !busy) onClose?.()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [open, busy, onClose])

  useEffect(() => {
    if (!open || !sessionId) return undefined
    let cancelled = false
    setLoading(true)
    setError('')
    setMessage('')
    setSession(null)
    setStudents([])
    setMarks({})
    api
      .get(`/sessions/${sessionId}/roster`)
      .then((data) => {
        if (cancelled) return
        const list = data.students || []
        setSession(data.session)
        setStudents(list)
        const next = {}
        for (const row of list) {
          next[row.StudentRef] = row.AttendanceStatus || ''
        }
        setMarks(next)
      })
      .catch((err) => {
        if (!cancelled) setError(err.message || 'خطا در بارگذاری لیست حضور')
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [open, sessionId])

  const summary = useMemo(() => {
    const counts = { present: 0, absent: 0, late: 0, leave: 0, unset: 0 }
    for (const status of Object.values(marks)) {
      if (!status) counts.unset += 1
      else if (counts[status] != null) counts[status] += 1
    }
    return counts
  }, [marks])

  function setStatus(studentRef, status) {
    setMarks((prev) => ({ ...prev, [studentRef]: status }))
  }

  function markAll(status) {
    setMarks((prev) => {
      const next = { ...prev }
      for (const key of Object.keys(next)) next[key] = status
      return next
    })
  }

  async function handleSave() {
    const items = Object.entries(marks)
      .filter(([, status]) => status)
      .map(([student_ref, attendance_status]) => ({
        student_ref: Number(student_ref),
        attendance_status,
      }))

    if (!items.length) {
      setError('حداقل وضعیت یک زبان‌آموز را مشخص کنید')
      return
    }

    setBusy(true)
    setError('')
    setMessage('')
    try {
      await api.post('/attendance/bulk', {
        session_ref: Number(sessionId),
        items,
      })
      setMessage('حضور و غیاب ذخیره شد')
      onSaved?.()
      setTimeout(() => onClose?.(), 450)
    } catch (err) {
      setError(err.message || 'ذخیره حضور و غیاب ناموفق بود')
    } finally {
      setBusy(false)
    }
  }

  if (!open) return null

  return createPortal(
    <div
      className="class-modal-overlay"
      role="presentation"
      onMouseDown={(e) => {
        if (!busy && e.target === e.currentTarget) onClose?.()
      }}
    >
      <div
        className="class-modal-dialog attendance-modal-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
      >
        <div className="class-modal-header">
          <div>
            <h2 id={titleId} className="class-modal-title">
              حضور و غیاب
            </h2>
            {session ? (
              <div className="class-modal-subtitle">
                <span>{session.CourseName}</span>
                <span>
                  {session.Date} · {normalizeTime(session.StartTime)}–{normalizeTime(session.EndTime)}
                </span>
              </div>
            ) : null}
          </div>
          <button
            type="button"
            className="class-modal-close"
            onClick={onClose}
            disabled={busy}
            aria-label="بستن"
          >
            <i className="bi bi-x-lg" />
          </button>
        </div>

        <div className="class-modal-body">
          {loading ? (
            <Loading />
          ) : error && !session ? (
            <div className="alert alert-danger mb-0">{error}</div>
          ) : (
            <>
              <div className="attendance-toolbar">
                <div className="attendance-summary">
                  <span className="chip chip-teal">حاضر {summary.present}</span>
                  <span className="chip chip-coral">غایب {summary.absent}</span>
                  <span className="chip chip-amber">تأخیر {summary.late}</span>
                  <span className="chip chip-sky">مرخصی {summary.leave}</span>
                  {summary.unset > 0 ? <span className="chip">بدون ثبت {summary.unset}</span> : null}
                </div>
                <div className="attendance-quick">
                  <button
                    type="button"
                    className="btn btn-sm btn-outline-success"
                    onClick={() => markAll('present')}
                  >
                    همه حاضر
                  </button>
                  <button
                    type="button"
                    className="btn btn-sm btn-outline-danger"
                    onClick={() => markAll('absent')}
                  >
                    همه غایب
                  </button>
                </div>
              </div>

              {error ? <div className="alert alert-danger py-2">{error}</div> : null}
              {message ? <div className="alert alert-success py-2">{message}</div> : null}

              {!students.length ? (
                <div className="empty-state py-4">زبان‌آموزی برای این کلاس ثبت‌نام نشده است.</div>
              ) : (
                <div className="table-responsive">
                  <table className="table table-sm table-hover align-middle mb-0 attendance-table">
                    <thead>
                      <tr>
                        <th style={{ width: '3rem' }}>#</th>
                        <th>زبان‌آموز</th>
                        <th>وضعیت حضور</th>
                      </tr>
                    </thead>
                    <tbody>
                      {students.map((row, idx) => (
                        <tr key={row.StudentRef}>
                          <td className="text-muted">{idx + 1}</td>
                          <td className="fw-semibold">{row.StudentName}</td>
                          <td>
                            <div className="attendance-status-group" role="group" aria-label="وضعیت حضور">
                              {STATUS_OPTIONS.map((opt) => (
                                <button
                                  key={opt.value}
                                  type="button"
                                  className={`attendance-status-btn is-${opt.tone} ${
                                    marks[row.StudentRef] === opt.value ? 'is-active' : ''
                                  }`}
                                  onClick={() => setStatus(row.StudentRef, opt.value)}
                                >
                                  {opt.label}
                                </button>
                              ))}
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </>
          )}
        </div>

        <div className="attendance-modal-footer">
          <button type="button" className="btn btn-outline-secondary rounded-pill" disabled={busy} onClick={onClose}>
            انصراف
          </button>
          <button
            type="button"
            className="btn btn-brand rounded-pill"
            disabled={busy || loading || !students.length}
            onClick={handleSave}
          >
            {busy ? 'در حال ذخیره…' : 'ذخیره حضور و غیاب'}
          </button>
        </div>
      </div>
    </div>,
    document.body,
  )
}
