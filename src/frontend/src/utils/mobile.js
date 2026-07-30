const PERSIAN_DIGITS = '۰۱۲۳۴۵۶۷۸۹'
const ARABIC_DIGITS = '٠١٢٣٤٥٦٧٨٩'

/** ارقام فارسی/عربی → انگلیسی و حذف غیرعدد؛ حداکثر ۱۱ رقم */
export function normalizeMobileInput(value) {
  let out = ''
  for (const ch of String(value || '')) {
    const pi = PERSIAN_DIGITS.indexOf(ch)
    if (pi >= 0) {
      out += String(pi)
      continue
    }
    const ai = ARABIC_DIGITS.indexOf(ch)
    if (ai >= 0) {
      out += String(ai)
      continue
    }
    if (ch >= '0' && ch <= '9') out += ch
  }
  return out.slice(0, 11)
}

export function isValidMobile(value) {
  return /^09\d{9}$/.test(String(value || ''))
}

export const MOBILE_HINT = '۱۱ رقم، شروع با ۰۹'
export const MOBILE_ERROR = 'موبایل باید ۱۱ رقم عددی و با ۰۹ شروع شود'
