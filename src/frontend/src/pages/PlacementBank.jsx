import { useEffect, useMemo, useState } from 'react'
import { api } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'

const SKILLS = [
  { value: 'grammar', label: 'گرامر' },
  { value: 'vocabulary', label: 'واژگان' },
  { value: 'reading', label: 'درک مطلب' },
  { value: 'listening', label: 'شنیداری' },
  { value: 'general', label: 'عمومی' },
]

const emptyType = {
  code: '',
  name: '',
  language_ref: '',
  description: '',
  duration_minutes: '30',
  questions_to_ask: '10',
  is_active: true,
}

const emptyQuestion = {
  test_type_ref: '',
  skill: 'general',
  difficulty: '2',
  prompt: '',
  option_a: '',
  option_b: '',
  option_c: '',
  option_d: '',
  correct_option: 'A',
  points: '1',
  explanation: '',
  is_active: true,
}

const emptyRule = {
  test_type_ref: '',
  min_percent: '0',
  max_percent: '39',
  level_ref: '',
  label: '',
}

export default function PlacementBank() {
  const { hasRole } = useAuth()
  const canManage = hasRole('admin', 'secretary', 'education', 'teacher')
  const canViewResults = hasRole('admin', 'secretary', 'education')
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [tab, setTab] = useState('questions')
  const [types, setTypes] = useState([])
  const [questions, setQuestions] = useState([])
  const [rules, setRules] = useState([])
  const [attempts, setAttempts] = useState([])
  const [languages, setLanguages] = useState([])
  const [levels, setLevels] = useState([])
  const [filterType, setFilterType] = useState('')
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editId, setEditId] = useState(null)
  const [typeForm, setTypeForm] = useState(emptyType)
  const [qForm, setQForm] = useState(emptyQuestion)
  const [ruleForm, setRuleForm] = useState(emptyRule)

  async function load() {
    if (!canManage) return
    setLoading(true)
    setError('')
    try {
      const qs = new URLSearchParams()
      qs.set('include_inactive', 'true')
      if (filterType) qs.set('test_type_ref', filterType)
      if (search.trim()) qs.set('search', search.trim())

      const [tRes, qRes, rRes, aRes, langRes, lvRes] = await Promise.allSettled([
        api.get('/placement/test-types?include_inactive=true'),
        api.get(`/placement/questions?${qs}`),
        api.get(`/placement/level-rules${filterType ? `?test_type_ref=${filterType}` : ''}`),
        canViewResults ? api.get('/placement/attempts') : Promise.resolve({ attempts: [] }),
        api.get('/languages'),
        api.get('/levels'),
      ])

      const failed = []
      if (tRes.status === 'fulfilled') setTypes(tRes.value.test_types || [])
      else {
        setTypes([])
        failed.push(`انواع آزمون: ${tRes.reason?.message || 'خطا'}`)
      }
      if (qRes.status === 'fulfilled') setQuestions(qRes.value.questions || [])
      else {
        setQuestions([])
        failed.push(`سوالات: ${qRes.reason?.message || 'خطا'}`)
      }
      if (rRes.status === 'fulfilled') setRules(rRes.value.level_rules || [])
      else {
        setRules([])
        failed.push(`قوانین: ${rRes.reason?.message || 'خطا'}`)
      }
      if (aRes.status === 'fulfilled') setAttempts(aRes.value.attempts || [])
      else setAttempts([])
      if (langRes.status === 'fulfilled') setLanguages(langRes.value.languages || [])
      else setLanguages([])
      if (lvRes.status === 'fulfilled') setLevels(lvRes.value.levels || [])
      else setLevels([])

      if (failed.length) setError(failed.join(' | '))
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [canManage, filterType, canViewResults])

  useEffect(() => {
    if (!canViewResults && tab === 'attempts') setTab('questions')
  }, [canViewResults, tab])

  const typeOptions = useMemo(
    () => types.map((t) => ({ value: String(t.Id), label: `${t.Name} (${t.Code})` })),
    [types],
  )
  const levelOptions = useMemo(
    () => levels.map((l) => ({ value: String(l.Id), label: `${l.Code} — ${l.Name}` })),
    [levels],
  )

  const qPaging = useClientPagination(questions)
  const attemptPaging = useClientPagination(attempts)

  function resetForms() {
    setEditId(null)
    setShowForm(false)
    setTypeForm(emptyType)
    setQForm({ ...emptyQuestion, test_type_ref: filterType || '' })
    setRuleForm({ ...emptyRule, test_type_ref: filterType || '' })
  }

  function startCreate() {
    resetForms()
    setShowForm(true)
    setMessage('')
    setError('')
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      if (tab === 'types') {
        const payload = {
          code: typeForm.code.trim(),
          name: typeForm.name.trim(),
          language_ref: Number(typeForm.language_ref),
          description: typeForm.description || null,
          duration_minutes: Number(typeForm.duration_minutes),
          questions_to_ask: Number(typeForm.questions_to_ask),
          is_active: Boolean(typeForm.is_active),
        }
        if (editId) await api.put(`/placement/test-types/${editId}`, payload)
        else await api.post('/placement/test-types', payload)
        setMessage(editId ? 'نوع آزمون به‌روز شد' : 'نوع آزمون ایجاد شد')
      } else if (tab === 'questions') {
        const payload = {
          test_type_ref: Number(qForm.test_type_ref),
          skill: qForm.skill,
          difficulty: Number(qForm.difficulty),
          prompt: qForm.prompt.trim(),
          option_a: qForm.option_a.trim(),
          option_b: qForm.option_b.trim(),
          option_c: qForm.option_c.trim(),
          option_d: qForm.option_d.trim(),
          correct_option: qForm.correct_option,
          points: Number(qForm.points),
          explanation: qForm.explanation || null,
          is_active: Boolean(qForm.is_active),
        }
        if (editId) await api.put(`/placement/questions/${editId}`, payload)
        else await api.post('/placement/questions', payload)
        setMessage(editId ? 'سوال به‌روز شد' : 'سوال به مخزن افزوده شد')
      } else if (tab === 'rules') {
        const payload = {
          test_type_ref: Number(ruleForm.test_type_ref),
          min_percent: Number(ruleForm.min_percent),
          max_percent: Number(ruleForm.max_percent),
          level_ref: Number(ruleForm.level_ref),
          label: ruleForm.label || null,
        }
        if (editId) {
          const { test_type_ref: _, ...upd } = payload
          await api.put(`/placement/level-rules/${editId}`, upd)
        } else await api.post('/placement/level-rules', payload)
        setMessage(editId ? 'قانون به‌روز شد' : 'قانون سطح افزوده شد')
      }
      resetForms()
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function handleDelete(kind, row) {
    const ok = await askConfirm({
      title: 'حذف',
      message: `مورد #${row.Id} حذف / آرشیو شود؟`,
      confirmLabel: 'حذف',
      danger: true,
    })
    if (!ok) return
    setBusy(true)
    try {
      if (kind === 'types') await api.delete(`/placement/test-types/${row.Id}`)
      if (kind === 'questions') await api.delete(`/placement/questions/${row.Id}`)
      if (kind === 'rules') await api.delete(`/placement/level-rules/${row.Id}`)
      setMessage('انجام شد')
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  if (!canManage) {
    return <div className="container py-4"><div className="alert alert-warning">دسترسی ندارید</div></div>
  }

  return (
    <div className="container py-4">
      {confirmDialog}
      <div className="page-head d-flex flex-wrap justify-content-between gap-2">
        <div>
          <h1 className="section-title h3 mb-1">مخزن آزمون تعیین سطح</h1>
          <p className="muted mb-0">
            {canViewResults
              ? 'انواع آزمون، سوالات، قوانین پیشنهاد سطح و نتایج'
              : 'انواع آزمون، سوالات و قوانین پیشنهاد سطح'}
          </p>
        </div>
        <div className="d-flex flex-wrap gap-2">
          <div style={{ minWidth: 200 }}>
            <VazirSelect
              value={filterType}
              onChange={setFilterType}
              placeholder="همه انواع"
              options={[{ value: '', label: 'همه انواع' }, ...typeOptions]}
            />
          </div>
          {tab === 'questions' && (
            <input
              className="form-control"
              style={{ maxWidth: 180 }}
              placeholder="جستجوی سوال"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && load()}
            />
          )}
          <button type="button" className="btn btn-outline-secondary rounded-pill" onClick={load}>
            بروزرسانی
          </button>
          {tab !== 'attempts' && (
            <button type="button" className="btn btn-brand rounded-pill" onClick={startCreate}>
              {tab === 'types' ? 'نوع جدید' : tab === 'rules' ? 'قانون جدید' : 'سوال جدید'}
            </button>
          )}
        </div>
      </div>

      <div className="d-flex flex-wrap gap-2 mb-3">
        {[
          { id: 'questions', label: 'مخزن سوالات' },
          { id: 'types', label: 'انواع آزمون' },
          { id: 'rules', label: 'قوانین سطح' },
          ...(canViewResults ? [{ id: 'attempts', label: 'نتایج زبان‌آموزان' }] : []),
        ].map((t) => (
          <button
            key={t.id}
            type="button"
            className={`btn btn-sm rounded-pill ${tab === t.id ? 'btn-brand' : 'btn-outline-secondary'}`}
            onClick={() => {
              setTab(t.id)
              resetForms()
            }}
          >
            {t.label}
          </button>
        ))}
      </div>

      {error && <div className="alert alert-danger">{error}</div>}
      {message && <div className="alert alert-success">{message}</div>}
      {loading && <Loading />}

      {showForm && tab === 'types' && (
        <div className="create-panel mb-3">
          <h2 className="h6 fw-bold">{editId ? `ویرایش نوع #${editId}` : 'نوع آزمون جدید'}</h2>
          <form className="row g-2" onSubmit={handleSubmit}>
            <div className="col-md-3">
              <label className="form-label">کد</label>
              <input className="form-control" required value={typeForm.code} onChange={(e) => setTypeForm((p) => ({ ...p, code: e.target.value }))} />
            </div>
            <div className="col-md-5">
              <label className="form-label">نام</label>
              <input className="form-control" required value={typeForm.name} onChange={(e) => setTypeForm((p) => ({ ...p, name: e.target.value }))} />
            </div>
            <div className="col-md-4">
              <label className="form-label">زبان</label>
              <VazirSelect
                required
                value={typeForm.language_ref}
                onChange={(v) => setTypeForm((p) => ({ ...p, language_ref: v }))}
                options={languages.map((l) => ({ value: String(l.Id), label: l.Name }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">مدت (دقیقه)</label>
              <input className="form-control" type="number" min="5" required value={typeForm.duration_minutes} onChange={(e) => setTypeForm((p) => ({ ...p, duration_minutes: e.target.value }))} />
            </div>
            <div className="col-md-3">
              <label className="form-label">تعداد سوال</label>
              <input className="form-control" type="number" min="1" required value={typeForm.questions_to_ask} onChange={(e) => setTypeForm((p) => ({ ...p, questions_to_ask: e.target.value }))} />
            </div>
            <div className="col-12">
              <label className="form-label">توضیح</label>
              <textarea className="form-control" rows={2} value={typeForm.description} onChange={(e) => setTypeForm((p) => ({ ...p, description: e.target.value }))} />
            </div>
            <div className="col-12 d-flex gap-2">
              <button className="btn btn-brand rounded-pill" disabled={busy} type="submit">ذخیره</button>
              <button className="btn btn-outline-secondary rounded-pill" type="button" onClick={resetForms}>انصراف</button>
            </div>
          </form>
        </div>
      )}

      {showForm && tab === 'questions' && (
        <div className="create-panel mb-3">
          <h2 className="h6 fw-bold">{editId ? `ویرایش سوال #${editId}` : 'سوال جدید'}</h2>
          <form className="row g-2" onSubmit={handleSubmit}>
            <div className="col-md-4">
              <label className="form-label">نوع آزمون</label>
              <VazirSelect required value={qForm.test_type_ref} onChange={(v) => setQForm((p) => ({ ...p, test_type_ref: v }))} options={typeOptions} />
            </div>
            <div className="col-md-3">
              <label className="form-label">مهارت</label>
              <VazirSelect value={qForm.skill} onChange={(v) => setQForm((p) => ({ ...p, skill: v }))} options={SKILLS} />
            </div>
            <div className="col-md-2">
              <label className="form-label">سختی</label>
              <VazirSelect
                value={qForm.difficulty}
                onChange={(v) => setQForm((p) => ({ ...p, difficulty: v }))}
                options={[1, 2, 3, 4, 5].map((n) => ({ value: String(n), label: String(n) }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">نمره</label>
              <input className="form-control" type="number" step="0.5" min="0.5" required value={qForm.points} onChange={(e) => setQForm((p) => ({ ...p, points: e.target.value }))} />
            </div>
            <div className="col-12">
              <label className="form-label">متن سوال</label>
              <textarea className="form-control" rows={2} required value={qForm.prompt} onChange={(e) => setQForm((p) => ({ ...p, prompt: e.target.value }))} />
            </div>
            {['a', 'b', 'c', 'd'].map((k) => (
              <div className="col-md-6" key={k}>
                <label className="form-label">گزینه {k.toUpperCase()}</label>
                <input
                  className="form-control"
                  required
                  value={qForm[`option_${k}`]}
                  onChange={(e) => setQForm((p) => ({ ...p, [`option_${k}`]: e.target.value }))}
                />
              </div>
            ))}
            <div className="col-md-3">
              <label className="form-label">پاسخ صحیح</label>
              <VazirSelect
                value={qForm.correct_option}
                onChange={(v) => setQForm((p) => ({ ...p, correct_option: v }))}
                options={['A', 'B', 'C', 'D'].map((o) => ({ value: o, label: o }))}
              />
            </div>
            <div className="col-md-9">
              <label className="form-label">توضیح (اختیاری)</label>
              <input className="form-control" value={qForm.explanation} onChange={(e) => setQForm((p) => ({ ...p, explanation: e.target.value }))} />
            </div>
            <div className="col-12 d-flex gap-2">
              <button className="btn btn-brand rounded-pill" disabled={busy} type="submit">ذخیره</button>
              <button className="btn btn-outline-secondary rounded-pill" type="button" onClick={resetForms}>انصراف</button>
            </div>
          </form>
        </div>
      )}

      {showForm && tab === 'rules' && (
        <div className="create-panel mb-3">
          <h2 className="h6 fw-bold">{editId ? `ویرایش قانون #${editId}` : 'قانون پیشنهاد سطح'}</h2>
          <form className="row g-2" onSubmit={handleSubmit}>
            <div className="col-md-4">
              <label className="form-label">نوع آزمون</label>
              <VazirSelect required value={ruleForm.test_type_ref} onChange={(v) => setRuleForm((p) => ({ ...p, test_type_ref: v }))} options={typeOptions} disabled={Boolean(editId)} />
            </div>
            <div className="col-md-2">
              <label className="form-label">از ٪</label>
              <input className="form-control" type="number" min="0" max="100" required value={ruleForm.min_percent} onChange={(e) => setRuleForm((p) => ({ ...p, min_percent: e.target.value }))} />
            </div>
            <div className="col-md-2">
              <label className="form-label">تا ٪</label>
              <input className="form-control" type="number" min="0" max="100" required value={ruleForm.max_percent} onChange={(e) => setRuleForm((p) => ({ ...p, max_percent: e.target.value }))} />
            </div>
            <div className="col-md-4">
              <label className="form-label">سطح پیشنهادی</label>
              <VazirSelect required value={ruleForm.level_ref} onChange={(v) => setRuleForm((p) => ({ ...p, level_ref: v }))} options={levelOptions} />
            </div>
            <div className="col-12">
              <label className="form-label">برچسب</label>
              <input className="form-control" value={ruleForm.label} onChange={(e) => setRuleForm((p) => ({ ...p, label: e.target.value }))} />
            </div>
            <div className="col-12 d-flex gap-2">
              <button className="btn btn-brand rounded-pill" disabled={busy} type="submit">ذخیره</button>
              <button className="btn btn-outline-secondary rounded-pill" type="button" onClick={resetForms}>انصراف</button>
            </div>
          </form>
        </div>
      )}

      {!loading && tab === 'types' && (
        <div className="table-responsive">
          <table className="table align-middle">
            <thead>
              <tr>
                <th>کد</th>
                <th>نام</th>
                <th>زبان</th>
                <th>مدت</th>
                <th>سوال</th>
                <th>مخزن</th>
                <th>وضعیت</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {types.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Code}</td>
                  <td>{row.Name}</td>
                  <td>{row.LanguageName}</td>
                  <td>{row.DurationMinutes}′</td>
                  <td>{row.QuestionsToAsk}</td>
                  <td>{row.ActiveQuestionCount}</td>
                  <td>{row.IsActive ? 'فعال' : 'آرشیو'}</td>
                  <td>
                    <RowActions
                      onEdit={() => {
                        setTab('types')
                        setEditId(row.Id)
                        setTypeForm({
                          code: row.Code || '',
                          name: row.Name || '',
                          language_ref: String(row.LanguageRef || ''),
                          description: row.Description || '',
                          duration_minutes: String(row.DurationMinutes || 30),
                          questions_to_ask: String(row.QuestionsToAsk || 10),
                          is_active: Boolean(row.IsActive),
                        })
                        setShowForm(true)
                      }}
                      onDelete={() => handleDelete('types', row)}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {!loading && tab === 'questions' && (
        <>
          <div className="table-responsive">
            <table className="table align-middle">
              <thead>
                <tr>
                  <th>#</th>
                  <th>آزمون</th>
                  <th>مهارت</th>
                  <th>سوال</th>
                  <th>صحیح</th>
                  <th>وضعیت</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {qPaging.slice.map((row) => (
                  <tr key={row.Id}>
                    <td>{row.Id}</td>
                    <td className="small">{row.TestTypeName}</td>
                    <td>{row.SkillLabel}</td>
                    <td style={{ maxWidth: 280 }}>{row.Prompt}</td>
                    <td>{row.CorrectOption}</td>
                    <td>{row.IsActive ? 'فعال' : 'آرشیو'}</td>
                    <td>
                      <RowActions
                        onEdit={() => {
                          setEditId(row.Id)
                          setQForm({
                            test_type_ref: String(row.TestTypeRef),
                            skill: row.Skill || 'general',
                            difficulty: String(row.Difficulty || 1),
                            prompt: row.Prompt || '',
                            option_a: row.OptionA || '',
                            option_b: row.OptionB || '',
                            option_c: row.OptionC || '',
                            option_d: row.OptionD || '',
                            correct_option: row.CorrectOption || 'A',
                            points: String(row.Points || 1),
                            explanation: row.Explanation || '',
                            is_active: Boolean(row.IsActive),
                          })
                          setShowForm(true)
                        }}
                        onDelete={() => handleDelete('questions', row)}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <PaginationBar paging={qPaging} />
        </>
      )}

      {!loading && tab === 'rules' && (
        <div className="table-responsive">
          <table className="table align-middle">
            <thead>
              <tr>
                <th>آزمون</th>
                <th>بازه درصد</th>
                <th>سطح</th>
                <th>برچسب</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {rules.map((row) => (
                <tr key={row.Id}>
                  <td>{row.TestTypeName}</td>
                  <td>{row.MinPercent}٪ — {row.MaxPercent}٪</td>
                  <td>{row.LevelCode} · {row.LevelName}</td>
                  <td>{row.Label || '—'}</td>
                  <td>
                    <RowActions
                      onEdit={() => {
                        setEditId(row.Id)
                        setRuleForm({
                          test_type_ref: String(row.TestTypeRef),
                          min_percent: String(row.MinPercent),
                          max_percent: String(row.MaxPercent),
                          level_ref: String(row.LevelRef),
                          label: row.Label || '',
                        })
                        setShowForm(true)
                      }}
                      onDelete={() => handleDelete('rules', row)}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {!loading && tab === 'attempts' && (
        <>
          <div className="table-responsive">
            <table className="table align-middle">
              <thead>
                <tr>
                  <th>#</th>
                  <th>زبان‌آموز</th>
                  <th>آزمون</th>
                  <th>نمره</th>
                  <th>سطح پیشنهادی</th>
                  <th>وضعیت</th>
                </tr>
              </thead>
              <tbody>
                {attemptPaging.slice.map((row) => (
                  <tr key={row.Id}>
                    <td>{row.Id}</td>
                    <td>{row.StudentName}</td>
                    <td>{row.TestTypeName}</td>
                    <td>
                      {row.Status === 'completed'
                        ? `${row.ScoreValue} / ${row.MaxScore} (${row.PercentScore}٪)`
                        : '—'}
                    </td>
                    <td>{row.SuggestedLevelName || '—'}</td>
                    <td>{row.Status === 'completed' ? 'تمام‌شده' : row.Status === 'in_progress' ? 'در حال انجام' : row.Status}</td>
                  </tr>
                ))}
                {!attempts.length && (
                  <tr><td colSpan={6} className="text-muted text-center">هنوز نتیجه‌ای ثبت نشده</td></tr>
                )}
              </tbody>
            </table>
          </div>
          <PaginationBar paging={attemptPaging} />
        </>
      )}
    </div>
  )
}
