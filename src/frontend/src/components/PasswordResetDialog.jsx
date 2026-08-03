import { useEffect, useId, useRef, useState } from 'react'
import { createPortal } from 'react-dom'

/**
 * مودال زیبا برای ریست رمز عبور توسط مدیر
 */
export default function PasswordResetDialog({
  open = false,
  username = '',
  fullName = '',
  busy = false,
  error = '',
  onSubmit,
  onCancel,
}) {
  const titleId = useId()
  const descId = useId()
  const passRef = useRef(null)
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [showPass, setShowPass] = useState(false)
  const [localError, setLocalError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const isBusy = busy || submitting

  useEffect(() => {
    if (!open) return undefined
    setPassword('')
    setConfirm('')
    setShowPass(false)
    setLocalError('')
    setSubmitting(false)
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const t = requestAnimationFrame(() => passRef.current?.focus())
    return () => {
      document.body.style.overflow = prev
      cancelAnimationFrame(t)
    }
  }, [open])

  useEffect(() => {
    if (!open) return undefined
    function onKey(e) {
      if (e.key === 'Escape' && !isBusy) onCancel?.()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [open, isBusy, onCancel])

  if (!open) return null

  async function handleSubmit(e) {
    e.preventDefault()
    e.stopPropagation()
    const pw = password.trim()
    const cf = confirm.trim()
    if (pw.length < 8) {
      setLocalError('رمز عبور باید حداقل ۸ کاراکتر باشد')
      return
    }
    if (pw !== cf) {
      setLocalError('رمز و تکرار آن یکسان نیست')
      return
    }
    setLocalError('')
    setSubmitting(true)
    try {
      await onSubmit?.(pw, cf)
    } catch (err) {
      setLocalError(err?.message || 'ذخیره رمز انجام نشد')
    } finally {
      setSubmitting(false)
    }
  }

  const displayError = localError || error

  return createPortal(
    <div
      className="confirm-overlay tone-password"
      role="presentation"
      onMouseDown={(e) => {
        if (!isBusy && e.target === e.currentTarget) onCancel?.()
      }}
    >
      <div
        className="confirm-dialog password-reset-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={descId}
      >
        <div className="confirm-dialog-icon password-reset-icon" aria-hidden="true">
          <i className="bi bi-shield-lock" />
        </div>

        <h2 id={titleId} className="confirm-dialog-title">
          تعیین رمز جدید
        </h2>
        <p id={descId} className="confirm-dialog-message">
          رمز جدید را وارد کنید. پس از ذخیره، جلسات قبلی این کاربر باطل می‌شود.
        </p>

        <dl className="confirm-dialog-details">
          {fullName ? (
            <div className="confirm-dialog-detail">
              <dt>نام</dt>
              <dd>{fullName}</dd>
            </div>
          ) : null}
          <div className="confirm-dialog-detail">
            <dt>نام کاربری</dt>
            <dd>{username}</dd>
          </div>
        </dl>

        <form className="password-reset-form" onSubmit={handleSubmit}>
          <div className="password-reset-field">
            <label className="form-label" htmlFor="admin-reset-password">
              رمز جدید
            </label>
            <div className="password-reset-input-wrap">
              <input
                ref={passRef}
                id="admin-reset-password"
                className="form-control"
                type={showPass ? 'text' : 'password'}
                autoComplete="new-password"
                minLength={8}
                required
                disabled={isBusy}
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value)
                  setLocalError('')
                }}
              />
              <button
                type="button"
                className="password-reset-toggle"
                tabIndex={-1}
                onClick={() => setShowPass((v) => !v)}
                aria-label={showPass ? 'مخفی کردن رمز' : 'نمایش رمز'}
              >
                <i className={`bi ${showPass ? 'bi-eye-slash' : 'bi-eye'}`} />
              </button>
            </div>
          </div>

          <div className="password-reset-field">
            <label className="form-label" htmlFor="admin-reset-confirm">
              تکرار رمز
            </label>
            <input
              id="admin-reset-confirm"
              className="form-control"
              type={showPass ? 'text' : 'password'}
              autoComplete="new-password"
              minLength={8}
              required
              disabled={isBusy}
              value={confirm}
              onChange={(e) => {
                setConfirm(e.target.value)
                setLocalError('')
              }}
            />
          </div>

          {displayError ? <div className="password-reset-error">{displayError}</div> : null}

          <div className="confirm-dialog-actions">
            <button
              type="button"
              className="btn confirm-btn-cancel"
              disabled={isBusy}
              onClick={onCancel}
            >
              انصراف
            </button>
            <button type="submit" className="btn confirm-btn-ok password-reset-ok" disabled={isBusy}>
              {isBusy ? (
                <>
                  <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true" />
                  در حال ذخیره…
                </>
              ) : (
                <>
                  <i className="bi bi-check2-circle" aria-hidden="true" />
                  ذخیره رمز
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>,
    document.body,
  )
}
