import { useEffect, useMemo, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { api } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'

const OPTS = ['A', 'B', 'C', 'D']

function optionText(q, key) {
  return q[`Option${key}`]
}

export default function PlacementExam() {
  const { user, hasRole } = useAuth()
  const [params, setParams] = useSearchParams()
  const attemptParam = params.get('attempt')

  const [types, setTypes] = useState([])
  const [history, setHistory] = useState([])
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [attempt, setAttempt] = useState(null)
  const [questions, setQuestions] = useState([])
  const [resultMessage, setResultMessage] = useState('')
  const [idx, setIdx] = useState(0)

  const isStudent = Boolean(user?.student_ref)
  const current = questions[idx] || null

  const progress = useMemo(() => {
    if (!questions.length) return 0
    const answered = questions.filter((q) => q.SelectedOption).length
    return Math.round((answered / questions.length) * 100)
  }, [questions])

  async function loadHub() {
    setLoading(true)
    setError('')
    try {
      const [tRes, hRes] = await Promise.all([
        api.get('/placement/test-types'),
        isStudent ? api.get('/placement/attempts/me') : Promise.resolve({ attempts: [] }),
      ])
      setTypes(tRes.test_types || [])
      setHistory(hRes.attempts || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  async function loadAttempt(id) {
    setLoading(true)
    setError('')
    try {
      const data = await api.get(`/placement/attempts/${id}`)
      setAttempt(data.attempt)
      setQuestions(data.questions || [])
      setResultMessage(data.result_message || '')
      setIdx(0)
    } catch (err) {
      setError(err.message)
      setAttempt(null)
      setQuestions([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (attemptParam) loadAttempt(attemptParam)
    else {
      setAttempt(null)
      setQuestions([])
      setResultMessage('')
      loadHub()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [attemptParam, user?.student_ref])

  async function startTest(typeId) {
    setBusy(true)
    setError('')
    try {
      const data = await api.post('/placement/attempts', { test_type_ref: Number(typeId) })
      setAttempt(data.attempt)
      setQuestions(data.questions || [])
      setResultMessage(data.result_message || '')
      setIdx(0)
      setParams({ attempt: String(data.attempt.Id) })
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function saveAnswer(qid, opt) {
    if (!attempt || attempt.Status !== 'in_progress') return
    setQuestions((prev) =>
      prev.map((q) => (q.Id === qid ? { ...q, SelectedOption: opt } : q)),
    )
    setError('')
    try {
      await api.put(`/placement/attempts/${attempt.Id}/answer`, {
        question_ref: qid,
        selected_option: opt,
      })
    } catch (err) {
      setError(err.message)
      // در صورت خطا وضعیت را از سرور هم‌تراز کن
      try {
        const data = await api.get(`/placement/attempts/${attempt.Id}`)
        setQuestions(data.questions || [])
      } catch {
        /* ignore */
      }
    }
  }

  async function selectOption(opt) {
    if (!current) return
    // کلیک دوباره روی همان گزینه = پاک کردن پاسخ
    const next = current.SelectedOption === opt ? null : opt
    await saveAnswer(current.Id, next)
  }

  async function clearAnswer() {
    if (!current?.SelectedOption) return
    await saveAnswer(current.Id, null)
  }

  async function submit() {
    if (!attempt) return
    setBusy(true)
    setError('')
    try {
      const data = await api.post(`/placement/attempts/${attempt.Id}/submit`)
      setAttempt(data.attempt)
      setQuestions(data.questions || [])
      setResultMessage(data.result_message || '')
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  function goNext() {
    setIdx((i) => Math.min(questions.length - 1, i + 1))
  }

  function goPrev() {
    setIdx((i) => Math.max(0, i - 1))
  }

  function backToHub() {
    setParams({})
  }

  if (!isStudent && !hasRole('admin', 'secretary', 'education', 'teacher')) {
    return (
      <div className="container py-4">
        <div className="alert alert-warning">برای شرکت در آزمون باید با حساب زبان‌آموز وارد شوید.</div>
      </div>
    )
  }

  if (!isStudent && !attemptParam) {
    return (
      <div className="container py-4">
        <div className="alert alert-info">
          مدیریت مخزن سوالات از{' '}
          <Link to="/placement/bank">اینجا</Link> انجام می‌شود. شرکت در آزمون فقط برای زبان‌آموز است.
        </div>
      </div>
    )
  }

  return (
    <div className="container py-4 placement-exam">
      <div className="page-head mb-3">
        <h1 className="section-title h3 mb-1">آزمون تعیین سطح</h1>
        <p className="muted mb-0">
          می‌توانید سوالی را بدون پاسخ رد کنید یا هر زمان آزمون را تمام کنید؛ نمره و سطح پیشنهادی خودکار اعلام می‌شود.
        </p>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}
      {loading && <Loading />}

      {!loading && !attemptParam && (
        <>
          <div className="row g-3 mb-4">
            {types.map((t) => (
              <div className="col-md-6 col-lg-4" key={t.Id}>
                <div className="create-panel h-100 d-flex flex-column">
                  <div className="small text-muted mb-1">{t.LanguageName}</div>
                  <h2 className="h5 fw-bold">{t.Name}</h2>
                  <p className="small flex-grow-1">{t.Description || 'آزمون چندگزینه‌ای تعیین سطح'}</p>
                  <div className="d-flex flex-wrap gap-2 small text-muted mb-3">
                    <span><i className="bi bi-clock me-1" />{t.DurationMinutes} دقیقه</span>
                    <span><i className="bi bi-list-ol me-1" />{t.QuestionsToAsk} سوال</span>
                    <span><i className="bi bi-collection me-1" />{t.ActiveQuestionCount} در مخزن</span>
                  </div>
                  <button
                    type="button"
                    className="btn btn-brand rounded-pill"
                    disabled={busy || !t.ActiveQuestionCount}
                    onClick={() => startTest(t.Id)}
                  >
                    شروع آزمون
                  </button>
                </div>
              </div>
            ))}
            {!types.length && (
              <div className="col-12">
                <div className="alert alert-secondary">فعلاً آزمونی فعال نیست.</div>
              </div>
            )}
          </div>

          {!!history.length && (
            <>
              <h2 className="h5 fw-bold mb-2">سوابق من</h2>
              <div className="table-responsive">
                <table className="table align-middle">
                  <thead>
                    <tr>
                      <th>آزمون</th>
                      <th>نمره</th>
                      <th>سطح</th>
                      <th>وضعیت</th>
                      <th />
                    </tr>
                  </thead>
                  <tbody>
                    {history.map((h) => (
                      <tr key={h.Id}>
                        <td>{h.TestTypeName}</td>
                        <td>
                          {h.Status === 'completed'
                            ? `${h.ScoreValue} / ${h.MaxScore} (${h.PercentScore}٪)`
                            : '—'}
                        </td>
                        <td>{h.SuggestedLevelName || '—'}</td>
                        <td>{h.Status === 'completed' ? 'تمام‌شده' : 'ناتمام'}</td>
                        <td>
                          <button
                            type="button"
                            className="btn btn-sm btn-outline-secondary rounded-pill"
                            onClick={() => setParams({ attempt: String(h.Id) })}
                          >
                            {h.Status === 'completed' ? 'مشاهده نتیجه' : 'ادامه'}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </>
      )}

      {!loading && attempt && attempt.Status === 'in_progress' && current && (
        <div className="create-panel">
          <div className="d-flex flex-wrap justify-content-between gap-2 mb-3">
            <div>
              <div className="fw-bold">{attempt.TestTypeName}</div>
              <div className="small text-muted">
                سوال {idx + 1} از {questions.length} · پاسخ‌داده‌شده {questions.filter((q) => q.SelectedOption).length}
              </div>
            </div>
            <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={backToHub}>
              بازگشت
            </button>
          </div>
          <div className="progress mb-2" style={{ height: 8 }}>
            <div className="progress-bar bg-success" style={{ width: `${progress}%` }} />
          </div>
          <div className="d-flex flex-wrap gap-1 mb-3" role="navigation" aria-label="شماره سوالات">
            {questions.map((q, i) => {
              const answered = Boolean(q.SelectedOption)
              const active = i === idx
              return (
                <button
                  key={q.Id}
                  type="button"
                  className={`btn btn-sm rounded-circle placement-q-dot ${
                    active ? 'btn-brand' : answered ? 'btn-outline-success' : 'btn-outline-secondary'
                  }`}
                  style={{ width: '2rem', height: '2rem', padding: 0 }}
                  title={answered ? `سوال ${i + 1} (پاسخ‌داده‌شده)` : `سوال ${i + 1} (بدون پاسخ)`}
                  onClick={() => setIdx(i)}
                >
                  {i + 1}
                </button>
              )
            })}
          </div>
          <div className="small text-muted mb-2">
            {current.SkillLabel} · سختی {current.Difficulty}
            {!current.SelectedOption ? ' · این سوال هنوز بدون پاسخ است (اختیاری)' : ''}
          </div>
          <p className="fs-5 fw-semibold mb-3">{current.Prompt}</p>
          <div className="d-grid gap-2 mb-3">
            {OPTS.map((opt) => {
              const active = current.SelectedOption === opt
              return (
                <button
                  key={opt}
                  type="button"
                  className={`btn text-start rounded-pill ${active ? 'btn-brand' : 'btn-outline-secondary'}`}
                  onClick={() => selectOption(opt)}
                >
                  <strong className="me-2">{opt}.</strong>
                  {optionText(current, opt)}
                  {active ? <span className="small ms-2 opacity-75">(کلیک دوباره = پاک کردن)</span> : null}
                </button>
              )
            })}
          </div>
          {current.SelectedOption ? (
            <div className="mb-3">
              <button
                type="button"
                className="btn btn-sm btn-outline-danger rounded-pill"
                onClick={clearAnswer}
              >
                <i className="bi bi-x-circle me-1" />
                پاک کردن پاسخ این سوال
              </button>
            </div>
          ) : null}
          <div className="d-flex flex-wrap justify-content-between align-items-center gap-2">
            <button
              type="button"
              className="btn btn-outline-secondary rounded-pill"
              disabled={idx === 0}
              onClick={goPrev}
            >
              قبلی
            </button>
            <div className="d-flex flex-wrap gap-2">
              {idx < questions.length - 1 && (
                <button type="button" className="btn btn-brand rounded-pill" onClick={goNext}>
                  {current.SelectedOption ? 'بعدی' : 'رد کردن (بدون پاسخ)'}
                </button>
              )}
              <button type="button" className="btn btn-success rounded-pill" disabled={busy} onClick={submit}>
                {busy ? '...' : 'پایان آزمون (حتی با سوال بی‌پاسخ)'}
              </button>
            </div>
          </div>
        </div>
      )}

      {!loading && attempt && attempt.Status === 'completed' && (
        <div className="create-panel placement-result">
          <div className="text-center mb-4">
            <div className="display-6 text-success mb-2"><i className="bi bi-award" /></div>
            <h2 className="h4 fw-bold">کارنامه آزمون تعیین سطح</h2>
            <p className="mb-1">{attempt.TestTypeName}</p>
            {resultMessage && <p className="lead">{resultMessage}</p>}
            <div className="d-flex flex-wrap justify-content-center gap-3 mt-3">
              <div className="px-3">
                <div className="text-muted small">نمره</div>
                <div className="fs-4 fw-bold">{attempt.ScoreValue} / {attempt.MaxScore}</div>
              </div>
              <div className="px-3">
                <div className="text-muted small">درصد</div>
                <div className="fs-4 fw-bold">{attempt.PercentScore}٪</div>
              </div>
              <div className="px-3">
                <div className="text-muted small">سطح پیشنهادی</div>
                <div className="fs-4 fw-bold text-brand">
                  {attempt.SuggestedLevelName || '—'}
                </div>
              </div>
            </div>

            {(() => {
              const correct = questions.filter((q) => q.IsCorrect === true || q.IsCorrect === 1).length
              const unanswered = questions.filter((q) => !q.SelectedOption).length
              const wrong = questions.length - correct - unanswered
              return (
                <div className="placement-result-summary mt-3">
                  <span className="placement-result-pill is-correct">
                    <i className="bi bi-check-circle-fill" />
                    درست: {correct}
                  </span>
                  <span className="placement-result-pill is-wrong">
                    <i className="bi bi-x-circle-fill" />
                    اشتباه: {wrong}
                  </span>
                  <span className="placement-result-pill is-skip">
                    <i className="bi bi-dash-circle-fill" />
                    بدون پاسخ: {unanswered}
                  </span>
                </div>
              )
            })()}

            <button type="button" className="btn btn-outline-secondary rounded-pill mt-3" onClick={backToHub}>
              بازگشت به فهرست
            </button>
          </div>

          <h3 className="h6 fw-bold mb-3">مرور پاسخ‌ها</h3>
          <div className="d-grid gap-3">
            {questions.map((q, i) => {
              const unanswered = !q.SelectedOption
              const isCorrect = !unanswered && (q.IsCorrect === true || q.IsCorrect === 1)
              const status = unanswered ? 'skip' : isCorrect ? 'correct' : 'wrong'
              const statusLabel =
                status === 'correct' ? 'پاسخ درست' : status === 'wrong' ? 'پاسخ اشتباه' : 'بدون پاسخ'
              const statusIcon =
                status === 'correct'
                  ? 'bi-check-circle-fill'
                  : status === 'wrong'
                    ? 'bi-x-circle-fill'
                    : 'bi-dash-circle-fill'

              return (
                <article key={q.Id} className={`placement-review-card is-${status}`}>
                  <div className="placement-review-head">
                    <div className="placement-review-num">سوال {i + 1}</div>
                    <div className={`placement-review-badge is-${status}`}>
                      <i className={`bi ${statusIcon}`} aria-hidden="true" />
                      {statusLabel}
                    </div>
                  </div>
                  <div className="small text-muted mb-1">{q.SkillLabel} · سختی {q.Difficulty}</div>
                  <p className="fw-semibold mb-3">{q.Prompt}</p>

                  <div className="d-grid gap-2 mb-2">
                    {OPTS.map((opt) => {
                      const text = optionText(q, opt)
                      const isUser = q.SelectedOption === opt
                      const isKey = q.CorrectOption === opt
                      let cls = 'placement-review-opt'
                      if (isKey) cls += ' is-key'
                      if (isUser && !isKey) cls += ' is-user-wrong'
                      if (isUser && isKey) cls += ' is-user-ok'
                      return (
                        <div key={opt} className={cls}>
                          <strong className="me-2">{opt}.</strong>
                          <span className="flex-grow-1">{text}</span>
                          {isKey ? (
                            <span className="placement-review-opt-tag is-key">
                              <i className="bi bi-check-lg" /> پاسخ صحیح
                            </span>
                          ) : null}
                          {isUser && !isKey ? (
                            <span className="placement-review-opt-tag is-user">
                              <i className="bi bi-person-fill" /> انتخاب شما
                            </span>
                          ) : null}
                          {isUser && isKey ? (
                            <span className="placement-review-opt-tag is-ok">
                              <i className="bi bi-emoji-smile" /> انتخاب درست شما
                            </span>
                          ) : null}
                        </div>
                      )
                    })}
                  </div>

                  {unanswered ? (
                    <div className="placement-review-note is-skip">
                      <i className="bi bi-info-circle me-1" />
                      این سوال را پاسخ نداده‌اید. پاسخ صحیح گزینه <strong>{q.CorrectOption}</strong> است.
                    </div>
                  ) : !isCorrect ? (
                    <div className="placement-review-note is-wrong">
                      <i className="bi bi-exclamation-triangle-fill me-1" />
                      شما گزینه <strong>{q.SelectedOption}</strong> را انتخاب کردید؛ پاسخ صحیح{' '}
                      <strong>{q.CorrectOption}</strong> است.
                    </div>
                  ) : (
                    <div className="placement-review-note is-correct">
                      <i className="bi bi-trophy-fill me-1" />
                      آفرین — پاسخ شما درست بود.
                    </div>
                  )}

                  {q.Explanation ? (
                    <div className="placement-review-explain">
                      <i className="bi bi-lightbulb me-1" />
                      {q.Explanation}
                    </div>
                  ) : null}
                </article>
              )
            })}
          </div>
        </div>
      )}
    </div>
  )
}
