/**
 * دکمه‌های آیکونی ویرایش / حذف (مثل کارت دوره)
 */
export default function RowActions({ onEdit, onDelete }) {
  return (
    <div className="row-actions">
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
