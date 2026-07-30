/**
 * دکمه‌های آیکونی مشاهده / حضور / ویرایش / حذف
 */
export default function RowActions({ onView, onAttendance, onEdit, onDelete }) {
  return (
    <div className="row-actions">
      {onView ? (
        <button
          type="button"
          className="row-action is-view"
          title="جزئیات"
          aria-label="جزئیات"
          onClick={onView}
        >
          <i className="bi bi-eye" />
        </button>
      ) : null}
      {onAttendance ? (
        <button
          type="button"
          className="row-action is-attendance"
          title="حضور و غیاب"
          aria-label="حضور و غیاب"
          onClick={onAttendance}
        >
          <i className="bi bi-clipboard-check" />
        </button>
      ) : null}
      {onEdit ? (
        <button
          type="button"
          className="row-action is-edit"
          title="ویرایش"
          aria-label="ویرایش"
          onClick={onEdit}
        >
          <i className="bi bi-pencil" />
        </button>
      ) : null}
      {onDelete ? (
        <button
          type="button"
          className="row-action is-delete"
          title="حذف"
          aria-label="حذف"
          onClick={onDelete}
        >
          <i className="bi bi-trash" />
        </button>
      ) : null}
    </div>
  )
}
