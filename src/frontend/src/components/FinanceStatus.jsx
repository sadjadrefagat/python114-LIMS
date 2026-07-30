import { formatMoney } from '../api/client'

const LABELS = {
  debtor: 'بدهکار',
  creditor: 'بستانکار',
  settled: 'تسویه‌شده',
  partial: 'بدهکار', // سازگاری داده قدیمی
}

/**
 * وضعیت مالی + نوار شدت
 * بدهکار: درصد باقی‌مانده شهریه (مرجانی)
 * تسویه‌شده: آبی کامل
 * بستانکار: درصد مازاد پرداخت (سبز)
 */
export default function FinanceStatus({
  status,
  intensity = 0,
  courseCost = 0,
  paidAmount = 0,
  balance = 0,
  compact = false,
}) {
  const key = status === 'partial' ? 'debtor' : status || 'debtor'
  const label = LABELS[key] || key
  const pct = Math.max(0, Math.min(100, Number(intensity) || 0))
  const due = Number(courseCost) || 0
  const paid = Number(paidAmount) || 0
  const bal = Number(balance) || paid - due

  let hint = ''
  if (key === 'debtor') {
    hint = due > 0 ? `${formatMoney(Math.max(0, -bal))} باقی‌مانده از ${formatMoney(due)}` : 'بدهی ثبت شده'
  } else if (key === 'creditor') {
    hint = `${formatMoney(Math.max(0, bal))} بستانکاری`
  } else {
    hint = due > 0 ? `پرداخت ${formatMoney(paid)} از ${formatMoney(due)}` : 'تسویه کامل'
  }

  return (
    <div className={`finance-status is-${key} ${compact ? 'is-compact' : ''}`} title={hint}>
      <div className="finance-status-top">
        <span className="finance-status-label">{label}</span>
        <span className="finance-status-pct">{pct}٪</span>
      </div>
      <div className="finance-status-track" aria-hidden="true">
        <div className="finance-status-fill" style={{ width: `${pct}%` }} />
      </div>
      {!compact ? <div className="finance-status-hint">{hint}</div> : null}
    </div>
  )
}

export const financeStatusOptions = [
  { value: 'debtor', label: 'بدهکار' },
  { value: 'creditor', label: 'بستانکار' },
  { value: 'settled', label: 'تسویه‌شده' },
]

export function financeStatusLabel(status) {
  return LABELS[status] || status || '—'
}
