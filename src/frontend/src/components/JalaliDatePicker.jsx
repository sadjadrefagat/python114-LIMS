import DatePicker, { DateObject } from 'react-multi-date-picker'
import persian from 'react-date-object/calendars/persian'
import persian_fa from 'react-date-object/locales/persian_fa'
import 'react-multi-date-picker/styles/colors/teal.css'

/**
 * انتخابگر تاریخ شمسی کاملاً فارسی
 * خروجی: رشته‌ی YYYY/MM/DD با ارقام انگلیسی برای API
 */
export default function JalaliDatePicker({
  value = '',
  onChange,
  placeholder = 'انتخاب تاریخ',
  required = false,
  disabled = false,
  id,
}) {
  let dateValue = null
  if (value) {
    try {
      dateValue = new DateObject({ date: value, format: 'YYYY/MM/DD', calendar: persian })
    } catch {
      dateValue = null
    }
  }

  return (
    <DatePicker
      id={id}
      value={dateValue}
      onChange={(date) => {
        if (!date) {
          onChange?.('')
          return
        }
        onChange?.(date.format('YYYY/MM/DD'))
      }}
      calendar={persian}
      locale={persian_fa}
      calendarPosition="bottom-right"
      format="YYYY/MM/DD"
      inputClass="form-control rmdp-input-vazir"
      containerClassName="rmdp-vazir-wrap w-100"
      placeholder={placeholder}
      required={required}
      disabled={disabled}
      editable={false}
      className="teal"
    />
  )
}
