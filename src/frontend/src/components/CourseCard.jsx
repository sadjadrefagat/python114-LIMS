import { Link } from 'react-router-dom'
import { formatMoney } from '../api/client'

const LANG_TONES = ['teal', 'sky', 'coral', 'sun', 'rose', 'violet']

function toneFor(course) {
  const id = Number(course.LanguageRef || course.Id || 0)
  return LANG_TONES[id % LANG_TONES.length]
}

/**
 * کارت دوره — اکشن‌ها با آیکون
 */
export default function CourseCard({ course, canManage = false, onEdit, onDelete }) {
  const tone = toneFor(course)

  return (
    <article className={`course-card tone-${tone}`}>
      <div className="course-card-banner">
        <div className="course-card-banner-inner">
          <span className="course-card-lang">
            <i className="bi bi-translate" />
            {course.LanguageName || 'زبان'}
          </span>
          {course.IsHighlighted ? (
            <span className="course-card-badge">
              <i className="bi bi-star-fill" />
              پیشنهادی
            </span>
          ) : null}
        </div>
        <div className="course-card-watermark" aria-hidden="true">
          <i className="bi bi-journal-bookmark" />
        </div>
      </div>

      <div className="course-card-body">
        {course.LevelName ? <span className="course-card-level">{course.LevelName}</span> : null}
        <h2 className="course-card-title">{course.Name}</h2>

        <ul className="course-card-meta">
          <li>
            <i className="bi bi-calendar2-week" />
            <span>{course.SessionsCount} جلسه</span>
          </li>
          {course.AgeGroup ? (
            <li>
              <i className="bi bi-people" />
              <span>{course.AgeGroup}</span>
            </li>
          ) : null}
          {course.TeachingMethod ? (
            <li>
              <i className="bi bi-laptop" />
              <span>{course.TeachingMethod}</span>
            </li>
          ) : null}
        </ul>

        <div className="course-card-foot">
          <div className="course-card-price">
            <strong>{formatMoney(course.Cost)}</strong>
          </div>
          <div className="course-card-actions">
            <Link
              to={`/courses/${course.Id}`}
              className="course-action is-view"
              title="جزئیات"
              aria-label="جزئیات"
            >
              <i className="bi bi-eye" />
            </Link>
            <Link
              to={`/courses/${course.Id}#enroll`}
              className="course-action is-enroll"
              title="ثبت‌نام"
              aria-label="ثبت‌نام"
            >
              <i className="bi bi-person-plus" />
            </Link>
            {canManage && (
              <>
                <button
                  type="button"
                  className="course-action is-edit"
                  title="ویرایش"
                  aria-label="ویرایش"
                  onClick={() => onEdit?.(course)}
                >
                  <i className="bi bi-pencil" />
                </button>
                <button
                  type="button"
                  className="course-action is-delete"
                  title="حذف"
                  aria-label="حذف"
                  onClick={() => onDelete?.(course)}
                >
                  <i className="bi bi-trash" />
                </button>
              </>
            )}
          </div>
        </div>
      </div>
    </article>
  )
}
