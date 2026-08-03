/** رده‌های سنی دوره — باید با AGE_GROUP_RULES بک‌اند هم‌خوان باشد */

export const AGE_GROUP_RULES = {
  کودک: { min: 3, max: 11 },
  نوجوان: { min: 12, max: 17 },
  جوان: { min: 18, max: 29 },
  بزرگسال: { min: 30, max: null },
  'همه سنین': { min: null, max: null },
}

export function ageGroupLabel(code) {
  if (!code) return '—'
  const rule = AGE_GROUP_RULES[code]
  if (!rule) return code
  const { min, max } = rule
  if (min == null && max == null) return `${code} (بدون محدودیت سنی)`
  if (min != null && max == null) return `${code} (${min} سال به بالا)`
  if (min == null && max != null) return `${code} (تا ${max} سال)`
  return `${code} (${min} تا ${max} سال)`
}

export const AGE_GROUP_OPTIONS = Object.keys(AGE_GROUP_RULES).map((code) => ({
  value: code,
  label: ageGroupLabel(code),
}))
