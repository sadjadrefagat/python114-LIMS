import { useEffect, useId, useRef } from 'react'
import { createPortal } from 'react-dom'

/**
 * مودال تأیید عملیات خطرناک (حذف / لغو)
 */
export default function ConfirmDialog({
  open = false,
  title = 'تأیید حذف',
  message = 'آیا از انجام این کار مطمئن هستید؟',
  details = [],
  confirmLabel = 'حذف',
  cancelLabel = 'انصراف',
  tone = 'danger',
  busy = false,
  onConfirm,
  onCancel,
}) {
  const titleId = useId()
  const descId = useId()
  const panelRef = useRef(null)
  const cancelRef = useRef(null)

  useEffect(() => {
    if (!open) return undefined
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const t = requestAnimationFrame(() => cancelRef.current?.focus())
    return () => {
      document.body.style.overflow = prev
      cancelAnimationFrame(t)
    }
  }, [open])

  useEffect(() => {
    if (!open) return undefined
    function onKey(e) {
      if (e.key === 'Escape' && !busy) onCancel?.()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [open, busy, onCancel])

  if (!open) return null

  const rows = (details || []).filter((d) => d && d.value != null && String(d.value).trim() !== '')

  return createPortal(
    <div
      className={`confirm-overlay tone-${tone}`}
      role="presentation"
      onMouseDown={(e) => {
        if (!busy && e.target === e.currentTarget) onCancel?.()
      }}
    >
      <div
        ref={panelRef}
        className="confirm-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={descId}
      >
        <div className="confirm-dialog-icon" aria-hidden="true">
          <i className="bi bi-exclamation-triangle" />
        </div>

        <h2 id={titleId} className="confirm-dialog-title">
          {title}
        </h2>
        <p id={descId} className="confirm-dialog-message">
          {message}
        </p>

        {rows.length > 0 ? (
          <dl className="confirm-dialog-details">
            {rows.map((row) => (
              <div key={row.label} className="confirm-dialog-detail">
                <dt>{row.label}</dt>
                <dd>{row.value}</dd>
              </div>
            ))}
          </dl>
        ) : null}

        <div className="confirm-dialog-actions">
          <button
            ref={cancelRef}
            type="button"
            className="btn confirm-btn-cancel"
            disabled={busy}
            onClick={onCancel}
          >
            {cancelLabel}
          </button>
          <button
            type="button"
            className="btn confirm-btn-ok"
            disabled={busy}
            onClick={onConfirm}
          >
            {busy ? (
              <>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true" />
                در حال انجام…
              </>
            ) : (
              <>
                <i className="bi bi-trash3" aria-hidden="true" />
                {confirmLabel}
              </>
            )}
          </button>
        </div>
      </div>
    </div>,
    document.body,
  )
}
