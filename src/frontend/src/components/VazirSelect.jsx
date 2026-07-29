import { useEffect, useId, useMemo, useRef, useState } from 'react'

/**
 * Combo سفارشی با فونت وزیر
 * (optionهای native در ویندوز فونت سیستم/Tahoma می‌گیرند)
 */
export default function VazirSelect({
  value = '',
  onChange,
  options = [],
  placeholder = 'انتخاب کنید',
  required = false,
  disabled = false,
  className = '',
}) {
  const [open, setOpen] = useState(false)
  const rootRef = useRef(null)
  const listId = useId()

  const selected = useMemo(
    () => options.find((o) => String(o.value) === String(value)),
    [options, value],
  )

  useEffect(() => {
    function onDocClick(e) {
      if (!rootRef.current?.contains(e.target)) setOpen(false)
    }
    function onEsc(e) {
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('mousedown', onDocClick)
    document.addEventListener('keydown', onEsc)
    return () => {
      document.removeEventListener('mousedown', onDocClick)
      document.removeEventListener('keydown', onEsc)
    }
  }, [])

  function pick(opt) {
    onChange?.(opt.value)
    setOpen(false)
  }

  return (
    <div className={`vazir-select ${className}`} ref={rootRef}>
      <button
        type="button"
        className={`vazir-select-trigger form-select text-start ${disabled ? 'disabled' : ''}`}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-controls={listId}
        disabled={disabled}
        onClick={() => !disabled && setOpen((v) => !v)}
      >
        <span className={selected ? '' : 'text-muted'}>
          {selected ? selected.label : placeholder}
        </span>
      </button>

      {/* برای اعتبارسنجی HTML فرم‌های required */}
      {required && (
        <input
          tabIndex={-1}
          className="vazir-select-required"
          value={value ?? ''}
          onChange={() => {}}
          required
        />
      )}

      {open && (
        <ul id={listId} className="vazir-select-menu" role="listbox">
          {options.map((opt) => (
            <li key={String(opt.value)}>
              <button
                type="button"
                role="option"
                aria-selected={String(opt.value) === String(value)}
                className={`vazir-select-option ${
                  String(opt.value) === String(value) ? 'active' : ''
                }`}
                onClick={() => pick(opt)}
              >
                {opt.label}
              </button>
            </li>
          ))}
          {!options.length && <li className="vazir-select-empty">موردی نیست</li>}
        </ul>
      )}
    </div>
  )
}
