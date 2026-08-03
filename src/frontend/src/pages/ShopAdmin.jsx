import { useEffect, useState } from 'react'
import { api, formatMoney } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'

const PRODUCT_TYPES = [
  { value: 'book', label: 'کتاب' },
  { value: 'file', label: 'فایل دیجیتال' },
  { value: 'stationery', label: 'لوازم التحریر' },
  { value: 'course_pack', label: 'پکیج دوره' },
  { value: 'other', label: 'سایر' },
]

const emptyProduct = {
  name: '',
  category_ref: '',
  sku: '',
  description: '',
  price: '',
  stock: '0',
  product_type: 'book',
  image_url: '',
  is_active: '1',
  is_featured: '0',
}

const emptyCategory = { name: '', sort_order: '0', is_active: '1' }

export default function ShopAdmin() {
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [tab, setTab] = useState('products')
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [orders, setOrders] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editId, setEditId] = useState(null)
  const [form, setForm] = useState(emptyProduct)
  const [catForm, setCatForm] = useState(emptyCategory)
  const [editCatId, setEditCatId] = useState(null)
  const paging = useClientPagination(products)

  async function loadAll() {
    setLoading(true)
    try {
      const params = new URLSearchParams({ include_inactive: 'true' })
      if (search.trim()) params.set('search', search.trim())
      const [p, c, o] = await Promise.all([
        api.get(`/shop/products?${params}`),
        api.get('/shop/categories?include_inactive=true'),
        api.get('/shop/orders'),
      ])
      setProducts(p.products || [])
      setCategories(c.categories || [])
      setOrders(o.orders || [])
      setError('')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    const t = setTimeout(() => loadAll(), 200)
    return () => clearTimeout(t)
  }, [search])

  function resetProductForm() {
    setEditId(null)
    setForm(emptyProduct)
    setShowForm(false)
  }

  function startEdit(p) {
    setEditId(p.Id)
    setForm({
      name: p.Name || '',
      category_ref: p.CategoryRef ? String(p.CategoryRef) : '',
      sku: p.Sku || '',
      description: p.Description || '',
      price: String(p.Price ?? ''),
      stock: String(p.Stock ?? '0'),
      product_type: p.ProductType || 'other',
      image_url: p.ImageUrl || '',
      is_active: p.IsActive ? '1' : '0',
      is_featured: p.IsFeatured ? '1' : '0',
    })
    setShowForm(true)
    setMessage('')
    setError('')
  }

  async function saveProduct(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    const body = {
      name: form.name.trim(),
      category_ref: form.category_ref ? Number(form.category_ref) : null,
      sku: form.sku.trim() || null,
      description: form.description.trim() || null,
      price: Number(form.price) || 0,
      stock: Number(form.stock) || 0,
      product_type: form.product_type,
      image_url: form.image_url.trim() || null,
      is_active: form.is_active === '1',
      is_featured: form.is_featured === '1',
    }
    try {
      if (editId) {
        await api.put(`/shop/products/${editId}`, body)
        setMessage('محصول به‌روزرسانی شد')
      } else {
        await api.post('/shop/products', body)
        setMessage('محصول ایجاد شد')
      }
      resetProductForm()
      await loadAll()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function archiveProduct(p) {
    const ok = await askConfirm({
      title: 'آرشیو محصول',
      message: `«${p.Name}» از فروشگاه مخفی شود؟`,
      confirmLabel: 'آرشیو',
    })
    if (!ok) return
    setBusy(true)
    try {
      await api.delete(`/shop/products/${p.Id}`)
      setMessage('محصول آرشیو شد')
      await loadAll()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function saveCategory(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    try {
      const body = {
        name: catForm.name.trim(),
        sort_order: Number(catForm.sort_order) || 0,
        is_active: catForm.is_active === '1',
      }
      if (editCatId) {
        await api.put(`/shop/categories/${editCatId}`, body)
        setMessage('دسته به‌روزرسانی شد')
      } else {
        await api.post('/shop/categories', body)
        setMessage('دسته ایجاد شد')
      }
      setCatForm(emptyCategory)
      setEditCatId(null)
      await loadAll()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const STATUS_FA = {
    pending: 'در انتظار',
    paid: 'پرداخت‌شده',
    cancelled: 'لغو',
    shipped: 'ارسال‌شده',
    delivered: 'تحویل‌شده',
  }

  return (
    <div className="container py-4">
      {confirmDialog}
      <div className="page-head">
        <div>
          <p className="page-kicker">مدیریت</p>
          <h1>مدیریت فروشگاه</h1>
        </div>
        {tab === 'products' && (
          <button
            type="button"
            className="btn btn-primary"
            onClick={() => {
              resetProductForm()
              setShowForm(true)
            }}
          >
            <i className="bi bi-plus-lg me-1" />
            محصول جدید
          </button>
        )}
      </div>

      <div className="shop-tabs mb-3">
        {[
          { id: 'products', label: 'محصولات', icon: 'bi-box' },
          { id: 'categories', label: 'دسته‌ها', icon: 'bi-tags' },
          { id: 'orders', label: 'سفارش‌ها', icon: 'bi-receipt' },
        ].map((t) => (
          <button
            key={t.id}
            type="button"
            className={`shop-tab ${tab === t.id ? 'is-active' : ''}`}
            onClick={() => setTab(t.id)}
          >
            <i className={`bi ${t.icon}`} />
            {t.label}
          </button>
        ))}
      </div>

      {message && <div className="alert alert-success">{message}</div>}
      {error && <div className="alert alert-danger">{error}</div>}

      {tab === 'products' && showForm && (
        <form className="card border-0 shadow-sm mb-4" onSubmit={saveProduct}>
          <div className="card-body">
            <h2 className="h5 mb-3">{editId ? 'ویرایش محصول' : 'محصول جدید'}</h2>
            <div className="row g-3">
              <div className="col-md-6">
                <label className="form-label">نام</label>
                <input
                  className="form-control"
                  required
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                />
              </div>
              <div className="col-md-3">
                <label className="form-label">دسته</label>
                <VazirSelect
                  value={form.category_ref}
                  onChange={(v) => setForm({ ...form, category_ref: v == null ? '' : String(v) })}
                  options={[
                    { value: '', label: 'بدون دسته' },
                    ...categories.map((c) => ({ value: String(c.Id), label: c.Name })),
                  ]}
                />
              </div>
              <div className="col-md-3">
                <label className="form-label">نوع</label>
                <VazirSelect
                  value={form.product_type}
                  onChange={(v) => setForm({ ...form, product_type: v })}
                  options={PRODUCT_TYPES}
                />
              </div>
              <div className="col-md-3">
                <label className="form-label">کد کالا</label>
                <input
                  className="form-control"
                  value={form.sku}
                  onChange={(e) => setForm({ ...form, sku: e.target.value })}
                />
              </div>
              <div className="col-md-3">
                <label className="form-label">قیمت (ریال)</label>
                <input
                  type="number"
                  className="form-control"
                  required
                  min={0}
                  value={form.price}
                  onChange={(e) => setForm({ ...form, price: e.target.value })}
                />
              </div>
              <div className="col-md-3">
                <label className="form-label">موجودی</label>
                <input
                  type="number"
                  className="form-control"
                  min={0}
                  value={form.stock}
                  onChange={(e) => setForm({ ...form, stock: e.target.value })}
                />
              </div>
              <div className="col-md-3">
                <label className="form-label">وضعیت</label>
                <VazirSelect
                  value={form.is_active}
                  onChange={(v) => setForm({ ...form, is_active: String(v) })}
                  options={[
                    { value: '1', label: 'فعال' },
                    { value: '0', label: 'غیرفعال' },
                  ]}
                />
              </div>
              <div className="col-md-3">
                <label className="form-label">ویژه</label>
                <VazirSelect
                  value={form.is_featured}
                  onChange={(v) => setForm({ ...form, is_featured: String(v) })}
                  options={[
                    { value: '0', label: 'خیر' },
                    { value: '1', label: 'بله' },
                  ]}
                />
              </div>
              <div className="col-12">
                <label className="form-label">توضیحات</label>
                <textarea
                  className="form-control"
                  rows={3}
                  value={form.description}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                />
              </div>
            </div>
            <div className="d-flex gap-2 mt-3">
              <button type="submit" className="btn btn-primary" disabled={busy}>
                ذخیره
              </button>
              <button type="button" className="btn btn-outline-secondary" onClick={resetProductForm}>
                انصراف
              </button>
            </div>
          </div>
        </form>
      )}

      {loading ? (
        <Loading />
      ) : tab === 'products' ? (
        <>
          <div className="mb-3" style={{ maxWidth: 360 }}>
            <input
              className="form-control"
              placeholder="جستجوی محصول…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <div className="table-responsive card border-0 shadow-sm">
            <table className="table align-middle mb-0">
              <thead>
                <tr>
                  <th>نام</th>
                  <th>دسته</th>
                  <th>نوع</th>
                  <th>قیمت</th>
                  <th>موجودی</th>
                  <th>لایک</th>
                  <th>وضعیت</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {paging.slice.map((p) => (
                  <tr key={p.Id}>
                    <td>
                      <strong>{p.Name}</strong>
                      {p.Sku && <div className="small text-muted">{p.Sku}</div>}
                    </td>
                    <td>{p.CategoryName || '—'}</td>
                    <td>{p.ProductTypeLabel || p.ProductType}</td>
                    <td>{formatMoney(p.Price)}</td>
                    <td>{p.Stock}</td>
                    <td>{p.LikeCount || 0}</td>
                    <td>
                      {p.IsActive ? (
                        <span className="badge text-bg-success">فعال</span>
                      ) : (
                        <span className="badge text-bg-secondary">آرشیو</span>
                      )}
                      {p.IsFeatured ? (
                        <span className="badge text-bg-warning ms-1">ویژه</span>
                      ) : null}
                    </td>
                    <td className="text-nowrap">
                      <button
                        type="button"
                        className="btn btn-sm btn-outline-primary me-1"
                        onClick={() => startEdit(p)}
                      >
                        ویرایش
                      </button>
                      {p.IsActive && (
                        <button
                          type="button"
                          className="btn btn-sm btn-outline-danger"
                          disabled={busy}
                          onClick={() => archiveProduct(p)}
                        >
                          آرشیو
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <PaginationBar
            className="mt-3"
            page={paging.page}
            totalPages={paging.totalPages}
            total={paging.total}
            pageSize={paging.pageSize}
            from={paging.from}
            to={paging.to}
            onChange={paging.setPage}
          />
        </>
      ) : tab === 'categories' ? (
        <div className="row g-4">
          <div className="col-md-5">
            <form className="card border-0 shadow-sm" onSubmit={saveCategory}>
              <div className="card-body">
                <h2 className="h5 mb-3">{editCatId ? 'ویرایش دسته' : 'دسته جدید'}</h2>
                <label className="form-label">نام</label>
                <input
                  className="form-control mb-2"
                  required
                  value={catForm.name}
                  onChange={(e) => setCatForm({ ...catForm, name: e.target.value })}
                />
                <label className="form-label">ترتیب</label>
                <input
                  type="number"
                  className="form-control mb-2"
                  value={catForm.sort_order}
                  onChange={(e) => setCatForm({ ...catForm, sort_order: e.target.value })}
                />
                <label className="form-label">وضعیت</label>
                <VazirSelect
                  value={catForm.is_active}
                  onChange={(v) => setCatForm({ ...catForm, is_active: String(v) })}
                  options={[
                    { value: '1', label: 'فعال' },
                    { value: '0', label: 'غیرفعال' },
                  ]}
                />
                <div className="d-flex gap-2 mt-3">
                  <button type="submit" className="btn btn-primary" disabled={busy}>
                    ذخیره
                  </button>
                  {editCatId && (
                    <button
                      type="button"
                      className="btn btn-outline-secondary"
                      onClick={() => {
                        setEditCatId(null)
                        setCatForm(emptyCategory)
                      }}
                    >
                      انصراف
                    </button>
                  )}
                </div>
              </div>
            </form>
          </div>
          <div className="col-md-7">
            <div className="table-responsive card border-0 shadow-sm">
              <table className="table mb-0">
                <thead>
                  <tr>
                    <th>نام</th>
                    <th>ترتیب</th>
                    <th>وضعیت</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {categories.map((c) => (
                    <tr key={c.Id}>
                      <td>{c.Name}</td>
                      <td>{c.SortOrder}</td>
                      <td>{c.IsActive ? 'فعال' : 'غیرفعال'}</td>
                      <td>
                        <button
                          type="button"
                          className="btn btn-sm btn-outline-primary"
                          onClick={() => {
                            setEditCatId(c.Id)
                            setCatForm({
                              name: c.Name,
                              sort_order: String(c.SortOrder ?? 0),
                              is_active: c.IsActive ? '1' : '0',
                            })
                          }}
                        >
                          ویرایش
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      ) : (
        <div className="table-responsive card border-0 shadow-sm">
          <table className="table align-middle mb-0">
            <thead>
              <tr>
                <th>#</th>
                <th>کاربر</th>
                <th>مبلغ</th>
                <th>وضعیت</th>
                <th>یادداشت</th>
                <th>تاریخ</th>
              </tr>
            </thead>
            <tbody>
              {orders.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center text-muted py-4">
                    سفارشی ثبت نشده است.
                  </td>
                </tr>
              ) : (
                orders.map((o) => (
                  <tr key={o.Id}>
                    <td>{o.Id}</td>
                    <td>{o.UserName || o.Username || 'مهمان'}</td>
                    <td>{formatMoney(o.TotalAmount)}</td>
                    <td>{STATUS_FA[o.Status] || o.Status}</td>
                    <td>{o.Note || '—'}</td>
                    <td className="small text-muted">
                      {o.CreatedAt ? String(o.CreatedAt).slice(0, 19).replace('T', ' ') : '—'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
