import { useEffect, useId, useMemo, useRef, useState } from 'react'

/**
 * Combo سفارشی با فونت وزیر
 * (optionهای native در ویندوز فونت سیستم/Tahoma می‌گیرند)
 * multiple=true → value آرایهٔ string|number
 */
export default function VazirSelect({
  value = '',
  onChange,
  options = [],
  placeholder = 'انتخاب کنید',
  required = false,
  disabled = false,
  multiple = false,
  className = '',
}) {
  const [open, setOpen] = useState(false)
  const rootRef = useRef(null)
  const listId = useId()

  const selectedValues = useMemo(() => {
    if (!multiple) return []
    if (!Array.isArray(value)) return []
    return value.map(String)
  }, [multiple, value])

  const selected = useMemo(() => {
    if (multiple) {
      return options.filter((o) => selectedValues.includes(String(o.value)))
    }
    return options.find((o) => String(o.value) === String(value)) || null
  }, [options, value, multiple, selectedValues])

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
    if (multiple) {
      const v = String(opt.value)
      const next = selectedValues.includes(v)
        ? selectedValues.filter((x) => x !== v)
        : [...selectedValues, v]
      onChange?.(next)
      return
    }
    onChange?.(opt.value)
    setOpen(false)
  }

  function displayLabel() {
    if (multiple) {
      if (!selected.length) return placeholder
      if (selected.length === 1) return selected[0].label
      return `${selected.length} مورد انتخاب شده`
    }
    return selected ? selected.label : placeholder
  }

  const hasValue = multiple ? selectedValues.length > 0 : Boolean(value || value === 0)

  return (
    <div className={`vazir-select ${multiple ? 'is-multiple' : ''} ${className}`} ref={rootRef}>
      <button
        type="button"
        className={`vazir-select-trigger form-select text-start ${disabled ? 'disabled' : ''}`}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-controls={listId}
        aria-multiselectable={multiple || undefined}
        disabled={disabled}
        onClick={() => !disabled && setOpen((v) => !v)}
      >
        <span className={hasValue ? '' : 'text-muted'}>{displayLabel()}</span>
      </button>

      {required && (
        <input
          tabIndex={-1}
          className="vazir-select-required"
          value={hasValue ? '1' : ''}
          onChange={() => {}}
          required
        />
      )}

      {open && (
        <ul id={listId} className="vazir-select-menu" role="listbox" aria-multiselectable={multiple || undefined}>
          {options.map((opt) => {
            const isActive = multiple
              ? selectedValues.includes(String(opt.value))
              : String(opt.value) === String(value)
            return (
              <li key={String(opt.value)}>
                <button
                  type="button"
                  role="option"
                  aria-selected={isActive}
                  className={`vazir-select-option ${isActive ? 'active' : ''}`}
                  onClick={() => pick(opt)}
                >
                  {multiple && (
                    <span className={`vazir-select-check ${isActive ? 'is-on' : ''}`} aria-hidden="true">
                      <i className={`bi ${isActive ? 'bi-check-square-fill' : 'bi-square'}`} />
                    </span>
                  )}
                  <span>{opt.label}</span>
                </button>
              </li>
            )
          })}
          {!options.length && <li className="vazir-select-empty">موردی نیست</li>}
        </ul>
      )}
    </div>
  )
}
