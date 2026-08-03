import { useEffect, useMemo, useRef, useState } from 'react'

const MONTHS = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
]

const WEEKDAYS = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']

function div(a, b) {
  return Math.floor(a / b)
}

export function gregorianToJalali(gy, gm, gd) {
  const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
  let gy2 = gm > 2 ? gy + 1 : gy
  let days =
    355666 +
    365 * gy +
    div(gy2 + 3, 4) -
    div(gy2 + 99, 100) +
    div(gy2 + 399, 400) +
    gd +
    gdm[gm - 1]
  let jy = -1595 + 33 * div(days, 12053)
  days %= 12053
  jy += 4 * div(days, 1461)
  days %= 1461
  if (days > 365) {
    jy += div(days - 1, 365)
    days = (days - 1) % 365
  }
  const jm = days < 186 ? 1 + div(days, 31) : 7 + div(days - 186, 30)
  const jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30)
  return { jy, jm, jd }
}

export function jalaliToGregorian(jy, jm, jd) {
  const jy2 = jy + 1595
  let days =
    -355668 +
    365 * jy2 +
    div(jy2, 33) * 8 +
    div((jy2 % 33) + 3, 4) +
    jd +
    (jm < 7 ? (jm - 1) * 31 : (jm - 7) * 30 + 186)
  let gy = 400 * div(days, 146097)
  days %= 146097
  if (days > 36524) {
    gy += 100 * div(--days, 36524)
    days %= 36524
    if (days >= 365) days += 1
  }
  gy += 4 * div(days, 1461)
  days %= 1461
  if (days > 365) {
    gy += div(days - 1, 365)
    days = (days - 1) % 365
  }
  const gd = days + 1
  const sal_a = [
    0,
    31,
    (gy % 4 === 0 && gy % 100 !== 0) || gy % 400 === 0 ? 29 : 28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ]
  let gm = 0
  let remain = gd
  for (gm = 1; gm <= 12 && remain > sal_a[gm]; gm += 1) {
    remain -= sal_a[gm]
  }
  return { gy, gm, gd: remain }
}

function isLeapJalali(jy) {
  return (((jy + 12) % 33) % 4) === 1
}

function jalaliMonthLength(jy, jm) {
  if (jm <= 6) return 31
  if (jm <= 11) return 30
  return isLeapJalali(jy) ? 30 : 29
}

function currentJalali() {
  const t = new Date()
  return gregorianToJalali(t.getFullYear(), t.getMonth() + 1, t.getDate())
}

function pad2(n) {
  return String(n).padStart(2, '0')
}

export function parseJalali(value) {
  if (!value || typeof value !== 'string') return null
  const m = value.trim().match(/^(\d{4})\/(\d{1,2})\/(\d{1,2})$/)
  if (!m) return null
  const jy = Number(m[1])
  const jm = Number(m[2])
  const jd = Number(m[3])
  if (jm < 1 || jm > 12 || jd < 1 || jd > jalaliMonthLength(jy, jm)) return null
  return { jy, jm, jd }
}

export function formatJalali(jy, jm, jd) {
  if (!jy || !jm || !jd) return ''
  return `${jy}/${pad2(jm)}/${pad2(jd)}`
}

export function todayJalaliString() {
  const t = currentJalali()
  return formatJalali(t.jy, t.jm, t.jd)
}

const WEEKDAYS_LONG = ['یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه']

/** برچسب کامل امروز برای هدر: «پنجشنبه ۳۰ تیر ۱۴۰۵» */
export function todayJalaliLongLabel() {
  const now = new Date()
  const { jy, jm, jd } = gregorianToJalali(now.getFullYear(), now.getMonth() + 1, now.getDate())
  return {
    weekday: WEEKDAYS_LONG[now.getDay()],
    day: jd,
    month: MONTHS[jm - 1],
    year: jy,
    iso: formatJalali(jy, jm, jd),
    label: `${WEEKDAYS_LONG[now.getDay()]} ${jd} ${MONTHS[jm - 1]} ${jy}`,
  }
}

/** مقایسه رشته‌های YYYY/MM/DD شمسی؛ منفی = a قبل از b */
export function compareJalali(a, b) {
  const pa = parseJalali(a)
  const pb = parseJalali(b)
  if (!pa || !pb) return 0
  return formatJalali(pa.jy, pa.jm, pa.jd).localeCompare(formatJalali(pb.jy, pb.jm, pb.jd))
}

function weekdayIndex(jy, jm, jd) {
  const g = jalaliToGregorian(jy, jm, jd)
  const d = new Date(g.gy, g.gm - 1, g.gd).getDay() // 0=Sun
  return (d + 1) % 7 // شنبه=0
}

const YEAR_PAGE_SIZE = 12

function yearPageStart(jy) {
  return Math.floor(jy / YEAR_PAGE_SIZE) * YEAR_PAGE_SIZE
}

/**
 * انتخابگر تاریخ شمسی — یک فیلد + تقویم پاپ‌آپ
 * خروجی: YYYY/MM/DD
 * کلیک روی ماه/سال در عنوان → نمای انتخاب ماه یا سال
 */
export default function JalaliDatePicker({
  value = '',
  onChange,
  required = false,
  disabled = false,
  placeholder = 'انتخاب تاریخ شمسی',
  minDate = '',
  maxDate = '',
  id,
}) {
  const rootRef = useRef(null)
  const parsed = parseJalali(value)
  const today = currentJalali()
  const [open, setOpen] = useState(false)
  const [viewMode, setViewMode] = useState('days') // days | months | years
  const [viewYear, setViewYear] = useState(parsed?.jy || today.jy)
  const [viewMonth, setViewMonth] = useState(parsed?.jm || today.jm)
  const [yearPage, setYearPage] = useState(yearPageStart(parsed?.jy || today.jy))

  const minParsed = useMemo(() => parseJalali(minDate), [minDate])
  const maxParsed = useMemo(() => parseJalali(maxDate), [maxDate])

  useEffect(() => {
    const p = parseJalali(value)
    if (p) {
      setViewYear(p.jy)
      setViewMonth(p.jm)
      setYearPage(yearPageStart(p.jy))
    }
  }, [value])

  useEffect(() => {
    if (!open) return undefined
    function onDoc(e) {
      if (!rootRef.current?.contains(e.target)) setOpen(false)
    }
    function onEsc(e) {
      if (e.key !== 'Escape') return
      if (viewMode === 'years') setViewMode('months')
      else if (viewMode === 'months') setViewMode('days')
      else setOpen(false)
    }
    document.addEventListener('mousedown', onDoc)
    document.addEventListener('keydown', onEsc)
    return () => {
      document.removeEventListener('mousedown', onDoc)
      document.removeEventListener('keydown', onEsc)
    }
  }, [open, viewMode])

  const cells = useMemo(() => {
    const len = jalaliMonthLength(viewYear, viewMonth)
    const start = weekdayIndex(viewYear, viewMonth, 1)
    const list = []
    for (let i = 0; i < start; i += 1) list.push(null)
    for (let d = 1; d <= len; d += 1) list.push(d)
    while (list.length % 7 !== 0) list.push(null)
    return list
  }, [viewYear, viewMonth])

  const yearCells = useMemo(() => {
    const list = []
    for (let i = 0; i < YEAR_PAGE_SIZE; i += 1) list.push(yearPage + i)
    return list
  }, [yearPage])

  function isDisabledDay(d) {
    if (!d) return true
    const dateStr = formatJalali(viewYear, viewMonth, d)
    if (minDate && compareJalali(dateStr, minDate) < 0) return true
    if (maxDate && compareJalali(dateStr, maxDate) > 0) return true
    return false
  }

  function isYearDisabled(jy) {
    if (minParsed && jy < minParsed.jy) return true
    if (maxParsed && jy > maxParsed.jy) return true
    return false
  }

  function isMonthDisabled(jm) {
    if (minParsed) {
      if (viewYear < minParsed.jy) return true
      if (viewYear === minParsed.jy && jm < minParsed.jm) return true
    }
    if (maxParsed) {
      if (viewYear > maxParsed.jy) return true
      if (viewYear === maxParsed.jy && jm > maxParsed.jm) return true
    }
    return false
  }

  function pickDay(d) {
    if (isDisabledDay(d)) return
    const next = formatJalali(viewYear, viewMonth, d)
    onChange?.(next)
    setOpen(false)
  }

  function pickMonth(jm) {
    if (isMonthDisabled(jm)) return
    setViewMonth(jm)
    setViewMode('days')
  }

  function pickYear(jy) {
    if (isYearDisabled(jy)) return
    setViewYear(jy)
    setYearPage(yearPageStart(jy))
    setViewMode('months')
  }

  function shiftMonth(delta) {
    let m = viewMonth + delta
    let y = viewYear
    if (m < 1) {
      m = 12
      y -= 1
    } else if (m > 12) {
      m = 1
      y += 1
    }
    setViewYear(y)
    setViewMonth(m)
    setYearPage(yearPageStart(y))
  }

  function shiftYear(delta) {
    const y = viewYear + delta
    setViewYear(y)
    setYearPage(yearPageStart(y))
  }

  function shiftYearPage(delta) {
    setYearPage((p) => p + delta * YEAR_PAGE_SIZE)
  }

  function goToday() {
    const t = currentJalali()
    const next = formatJalali(t.jy, t.jm, t.jd)
    if (minDate && compareJalali(next, minDate) < 0) return
    if (maxDate && compareJalali(next, maxDate) > 0) return
    setViewYear(t.jy)
    setViewMonth(t.jm)
    setYearPage(yearPageStart(t.jy))
    setViewMode('days')
    onChange?.(next)
    setOpen(false)
  }

  function clearDate(e) {
    e.stopPropagation()
    onChange?.('')
  }

  function openPicker() {
    if (disabled) return
    const p = parseJalali(value)
    const base = p || today
    setViewYear(base.jy)
    setViewMonth(base.jm)
    setYearPage(yearPageStart(base.jy))
    setViewMode('days')
    setOpen((v) => !v)
  }

  function navPrev() {
    if (viewMode === 'days') shiftMonth(-1)
    else if (viewMode === 'months') shiftYear(-1)
    else shiftYearPage(-1)
  }

  function navNext() {
    if (viewMode === 'days') shiftMonth(1)
    else if (viewMode === 'months') shiftYear(1)
    else shiftYearPage(1)
  }

  const navPrevLabel = viewMode === 'years' ? 'دوره قبل' : viewMode === 'months' ? 'سال قبل' : 'ماه قبل'
  const navNextLabel = viewMode === 'years' ? 'دوره بعد' : viewMode === 'months' ? 'سال بعد' : 'ماه بعد'

  const display = value || ''
  const todayStr = todayJalaliString()

  return (
    <div className={`jalali-picker ${disabled ? 'is-disabled' : ''}`} ref={rootRef}>
      {required && (
        <input
          tabIndex={-1}
          className="vazir-select-required"
          value={value || ''}
          onChange={() => {}}
          required
          aria-hidden="true"
        />
      )}

      <button
        id={id}
        type="button"
        className={`form-control jalali-picker-trigger text-start ${!display ? 'is-empty' : ''}`}
        disabled={disabled}
        aria-haspopup="dialog"
        aria-expanded={open}
        onClick={openPicker}
      >
        <i className="bi bi-calendar3 jalali-picker-icon" />
        <span>{display || placeholder}</span>
        {display && !disabled && !required ? (
          <span
            className="jalali-picker-clear"
            role="button"
            tabIndex={-1}
            onClick={clearDate}
            aria-label="پاک کردن تاریخ"
          >
            <i className="bi bi-x" />
          </span>
        ) : null}
      </button>

      {open && !disabled && (
        <div className="jalali-calendar" role="dialog" aria-label="تقویم شمسی">
          <div className="jalali-calendar-head">
            <button type="button" className="jalali-nav-btn" onClick={navPrev} aria-label={navPrevLabel}>
              <i className="bi bi-chevron-right" />
            </button>

            <div className="jalali-calendar-title">
              {viewMode === 'days' && (
                <>
                  <button
                    type="button"
                    className="jalali-title-btn"
                    onClick={() => setViewMode('months')}
                    aria-label="انتخاب ماه"
                  >
                    {MONTHS[viewMonth - 1]}
                  </button>
                  <button
                    type="button"
                    className="jalali-title-btn"
                    onClick={() => {
                      setYearPage(yearPageStart(viewYear))
                      setViewMode('years')
                    }}
                    aria-label="انتخاب سال"
                  >
                    {viewYear}
                  </button>
                </>
              )}
              {viewMode === 'months' && (
                <button
                  type="button"
                  className="jalali-title-btn"
                  onClick={() => {
                    setYearPage(yearPageStart(viewYear))
                    setViewMode('years')
                  }}
                  aria-label="انتخاب سال"
                >
                  {viewYear}
                </button>
              )}
              {viewMode === 'years' && (
                <span className="jalali-title-range">
                  {yearPage} – {yearPage + YEAR_PAGE_SIZE - 1}
                </span>
              )}
            </div>

            <button type="button" className="jalali-nav-btn" onClick={navNext} aria-label={navNextLabel}>
              <i className="bi bi-chevron-left" />
            </button>
          </div>

          {viewMode === 'days' && (
            <>
              <div className="jalali-weekdays">
                {WEEKDAYS.map((w) => (
                  <span key={w}>{w}</span>
                ))}
              </div>

              <div className="jalali-days">
                {cells.map((d, idx) => {
                  if (!d) return <span key={`e-${idx}`} className="jalali-day is-empty" />
                  const dateStr = formatJalali(viewYear, viewMonth, d)
                  const selected = value === dateStr
                  const isToday = dateStr === todayStr
                  const off = isDisabledDay(d)
                  return (
                    <button
                      key={dateStr}
                      type="button"
                      className={`jalali-day ${selected ? 'is-selected' : ''} ${isToday ? 'is-today' : ''} ${off ? 'is-disabled' : ''}`}
                      disabled={off}
                      onClick={() => pickDay(d)}
                    >
                      {d}
                    </button>
                  )
                })}
              </div>
            </>
          )}

          {viewMode === 'months' && (
            <div className="jalali-months">
              {MONTHS.map((name, idx) => {
                const jm = idx + 1
                const selected = parsed?.jy === viewYear && parsed?.jm === jm
                const isCurrent = today.jy === viewYear && today.jm === jm
                const off = isMonthDisabled(jm)
                return (
                  <button
                    key={name}
                    type="button"
                    className={`jalali-chip ${selected ? 'is-selected' : ''} ${isCurrent ? 'is-today' : ''} ${off ? 'is-disabled' : ''}`}
                    disabled={off}
                    onClick={() => pickMonth(jm)}
                  >
                    {name}
                  </button>
                )
              })}
            </div>
          )}

          {viewMode === 'years' && (
            <div className="jalali-years">
              {yearCells.map((jy) => {
                const selected = parsed?.jy === jy
                const isCurrent = today.jy === jy
                const off = isYearDisabled(jy)
                return (
                  <button
                    key={jy}
                    type="button"
                    className={`jalali-chip ${selected ? 'is-selected' : ''} ${isCurrent ? 'is-today' : ''} ${off ? 'is-disabled' : ''}`}
                    disabled={off}
                    onClick={() => pickYear(jy)}
                  >
                    {jy}
                  </button>
                )
              })}
            </div>
          )}

          <div className="jalali-calendar-foot">
            <button type="button" className="btn btn-sm btn-outline-success rounded-pill" onClick={goToday}>
              امروز
            </button>
            <button type="button" className="btn btn-sm btn-light rounded-pill" onClick={() => setOpen(false)}>
              بستن
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
