"""
فروشگاه اقلام آموزشی — کاتالوگ، لایک، بوکمارک، سبد خرید، سفارش
"""
from __future__ import annotations

import secrets
from typing import Any, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query

from auth import get_current_user, get_optional_user, require_roles
from database import execute, execute_returning_id, fetch_all, fetch_one
from models import (
    CartItemUpsert,
    ShopCategoryCreate,
    ShopCategoryUpdate,
    ShopCheckoutRequest,
    ShopProductCreate,
    ShopProductUpdate,
)

router = APIRouter(tags=["shop"])
StaffDep = Depends(require_roles("admin", "secretary", "education"))
AuthDep = Depends(get_current_user)
OptionalUserDep = Depends(get_optional_user)

PRODUCT_TYPES_FA = {
    "book": "کتاب",
    "file": "فایل دیجیتال",
    "stationery": "لوازم التحریر",
    "course_pack": "پکیج دوره",
    "other": "سایر",
}


def ensure_shop_schema() -> None:
    """ایجاد جداول فروشگاه در صورت نبود"""
    execute(
        """
        IF OBJECT_ID(N'dbo.ShopCategory', N'U') IS NULL
        CREATE TABLE dbo.ShopCategory (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            Name NVARCHAR(100) NOT NULL,
            SortOrder INT NOT NULL CONSTRAINT DF_ShopCategory_Sort DEFAULT (0),
            IsActive BIT NOT NULL CONSTRAINT DF_ShopCategory_Active DEFAULT (1),
            CONSTRAINT UQ_ShopCategory_Name UNIQUE (Name)
        )
        """
    )
    execute(
        """
        IF OBJECT_ID(N'dbo.ShopProduct', N'U') IS NULL
        CREATE TABLE dbo.ShopProduct (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            CategoryRef INT NULL,
            Name NVARCHAR(200) NOT NULL,
            Sku NVARCHAR(50) NULL,
            Description NVARCHAR(MAX) NULL,
            Price INT NOT NULL CONSTRAINT DF_ShopProduct_Price DEFAULT (0),
            Stock INT NOT NULL CONSTRAINT DF_ShopProduct_Stock DEFAULT (0),
            ProductType NVARCHAR(20) NOT NULL CONSTRAINT DF_ShopProduct_Type DEFAULT (N'other'),
            ImageUrl NVARCHAR(500) NULL,
            IsActive BIT NOT NULL CONSTRAINT DF_ShopProduct_Active DEFAULT (1),
            IsFeatured BIT NOT NULL CONSTRAINT DF_ShopProduct_Feat DEFAULT (0),
            CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_ShopProduct_Created DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT FK_ShopProduct_Category FOREIGN KEY (CategoryRef) REFERENCES dbo.ShopCategory(Id),
            CONSTRAINT CK_ShopProduct_Type CHECK (ProductType IN (N'book', N'file', N'stationery', N'course_pack', N'other')),
            CONSTRAINT CK_ShopProduct_Price CHECK (Price >= 0),
            CONSTRAINT CK_ShopProduct_Stock CHECK (Stock >= 0)
        )
        """
    )
    execute(
        """
        IF OBJECT_ID(N'dbo.ShopProductLike', N'U') IS NULL
        CREATE TABLE dbo.ShopProductLike (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            UserRef INT NOT NULL,
            ProductRef INT NOT NULL,
            CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_ShopLike_Created DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT UQ_ShopLike UNIQUE (UserRef, ProductRef),
            CONSTRAINT FK_ShopLike_User FOREIGN KEY (UserRef) REFERENCES dbo.AppUser(Id),
            CONSTRAINT FK_ShopLike_Product FOREIGN KEY (ProductRef) REFERENCES dbo.ShopProduct(Id)
        )
        """
    )
    execute(
        """
        IF OBJECT_ID(N'dbo.ShopProductBookmark', N'U') IS NULL
        CREATE TABLE dbo.ShopProductBookmark (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            UserRef INT NOT NULL,
            ProductRef INT NOT NULL,
            CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_ShopBookmark_Created DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT UQ_ShopBookmark UNIQUE (UserRef, ProductRef),
            CONSTRAINT FK_ShopBookmark_User FOREIGN KEY (UserRef) REFERENCES dbo.AppUser(Id),
            CONSTRAINT FK_ShopBookmark_Product FOREIGN KEY (ProductRef) REFERENCES dbo.ShopProduct(Id)
        )
        """
    )
    execute(
        """
        IF OBJECT_ID(N'dbo.ShopCartItem', N'U') IS NULL
        CREATE TABLE dbo.ShopCartItem (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            UserRef INT NULL,
            SessionKey NVARCHAR(64) NULL,
            ProductRef INT NOT NULL,
            Qty INT NOT NULL CONSTRAINT DF_ShopCart_Qty DEFAULT (1),
            UpdatedAt DATETIME2 NOT NULL CONSTRAINT DF_ShopCart_Updated DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT FK_ShopCart_User FOREIGN KEY (UserRef) REFERENCES dbo.AppUser(Id),
            CONSTRAINT FK_ShopCart_Product FOREIGN KEY (ProductRef) REFERENCES dbo.ShopProduct(Id),
            CONSTRAINT CK_ShopCart_Qty CHECK (Qty >= 0),
            CONSTRAINT CK_ShopCart_Owner CHECK (UserRef IS NOT NULL OR SessionKey IS NOT NULL)
        )
        """
    )
    execute(
        """
        IF OBJECT_ID(N'dbo.ShopOrder', N'U') IS NULL
        CREATE TABLE dbo.ShopOrder (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            UserRef INT NULL,
            SessionKey NVARCHAR(64) NULL,
            Status NVARCHAR(20) NOT NULL CONSTRAINT DF_ShopOrder_Status DEFAULT (N'pending'),
            TotalAmount INT NOT NULL CONSTRAINT DF_ShopOrder_Total DEFAULT (0),
            Note NVARCHAR(500) NULL,
            CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_ShopOrder_Created DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT FK_ShopOrder_User FOREIGN KEY (UserRef) REFERENCES dbo.AppUser(Id),
            CONSTRAINT CK_ShopOrder_Status CHECK (Status IN (N'pending', N'paid', N'cancelled', N'shipped', N'delivered'))
        )
        """
    )
    execute(
        """
        IF OBJECT_ID(N'dbo.ShopOrderItem', N'U') IS NULL
        CREATE TABLE dbo.ShopOrderItem (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            OrderRef INT NOT NULL,
            ProductRef INT NOT NULL,
            Qty INT NOT NULL,
            UnitPrice INT NOT NULL,
            CONSTRAINT FK_ShopOrderItem_Order FOREIGN KEY (OrderRef) REFERENCES dbo.ShopOrder(Id),
            CONSTRAINT FK_ShopOrderItem_Product FOREIGN KEY (ProductRef) REFERENCES dbo.ShopProduct(Id),
            CONSTRAINT CK_ShopOrderItem_Qty CHECK (Qty > 0)
        )
        """
    )
    _seed_shop_demo()


def _seed_shop_demo() -> None:
    if fetch_one("SELECT TOP 1 Id FROM ShopCategory"):
        return
    cats = [
        ("کتاب و منابع", 1),
        ("فایل و محتوای دیجیتال", 2),
        ("لوازم التحریر آموزشی", 3),
        ("پکیج‌های آمادگی آزمون", 4),
    ]
    cat_ids: list[int] = []
    for name, sort in cats:
        cat_ids.append(
            execute_returning_id(
                "INSERT INTO ShopCategory ([Name], [SortOrder], [IsActive]) VALUES (?, ?, 1)",
                (name, sort),
            )
        )
    products = [
        (cat_ids[0], "کتاب گرامر انگلیسی سطح متوسط", "BK-EN-GRAM-01", "مرجع کامل گرامر با تمرین", 850000, 40, "book", 1),
        (cat_ids[0], "واژه‌نامه موضوعی آلمانی", "BK-DE-VOC-02", "۵۰۰ واژه پرتکرار با مثال", 620000, 25, "book", 0),
        (cat_ids[1], "پکیج صوتی مکالمه اسپانیایی", "FL-ES-AUD-01", "۳۰ درس صوتی قابل دانلود", 450000, 999, "file", 1),
        (cat_ids[1], "نمونه سوالات IELTS Reading", "FL-IELTS-RD-03", "PDF + پاسخ‌نامه", 390000, 999, "file", 1),
        (cat_ids[2], "دفترچه تمرین زبان‌آموز", "ST-NOTE-01", "۱۲۰ برگ خط‌دار ویژه کلاس", 180000, 120, "stationery", 0),
        (cat_ids[2], "فلش‌کارت واژگان رنگی", "ST-FLASH-05", "بسته ۲۰۰ کارت دو رو", 275000, 60, "stationery", 1),
        (cat_ids[3], "پکیج آمادگی آزمون YOS", "PK-YOS-01", "کتاب + فایل تمرین + راهنما", 1250000, 15, "course_pack", 1),
        (cat_ids[3], "پکیج مکالمه فشرده فرانسه", "PK-FR-CONV", "بسته ۴ هفته‌ای خودآموز", 980000, 20, "course_pack", 0),
    ]
    for cat, name, sku, desc, price, stock, ptype, feat in products:
        execute(
            """INSERT INTO ShopProduct
                ([CategoryRef], [Name], [Sku], [Description], [Price], [Stock],
                 [ProductType], [IsActive], [IsFeatured])
               VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)""",
            (cat, name, sku, desc, price, stock, ptype, feat),
        )


def _bad(detail: str) -> HTTPException:
    return HTTPException(status_code=400, detail=detail)


def _not_found(entity: str = "Resource") -> HTTPException:
    return HTTPException(status_code=404, detail=f"{entity} not found")


def _ok_list(key: str, rows: list[dict[str, Any]]) -> dict[str, Any]:
    return {key: rows, "count": len(rows)}


def _session_key(x_cart_session: Optional[str]) -> Optional[str]:
    if not x_cart_session:
        return None
    key = x_cart_session.strip()[:64]
    return key or None


PRODUCT_SELECT = """
    SELECT
        P.Id, P.CategoryRef, P.Name, P.Sku, P.Description, P.Price, P.Stock,
        P.ProductType, P.ImageUrl, P.IsActive, P.IsFeatured, P.CreatedAt,
        C.Name AS CategoryName,
        (SELECT COUNT(*) FROM ShopProductLike L WHERE L.ProductRef = P.Id) AS LikeCount,
        (SELECT COUNT(*) FROM ShopProductBookmark B WHERE B.ProductRef = P.Id) AS BookmarkCount
    FROM ShopProduct P
    LEFT JOIN ShopCategory C ON P.CategoryRef = C.Id
"""


def _enrich_product(row: dict[str, Any], user: Optional[dict[str, Any]]) -> dict[str, Any]:
    row["ProductTypeLabel"] = PRODUCT_TYPES_FA.get(row.get("ProductType") or "", row.get("ProductType"))
    row["Liked"] = False
    row["Bookmarked"] = False
    if user:
        uid = user["Id"]
        row["Liked"] = bool(
            fetch_one(
                "SELECT Id FROM ShopProductLike WHERE UserRef = ? AND ProductRef = ?",
                (uid, row["Id"]),
            )
        )
        row["Bookmarked"] = bool(
            fetch_one(
                "SELECT Id FROM ShopProductBookmark WHERE UserRef = ? AND ProductRef = ?",
                (uid, row["Id"]),
            )
        )
    return row


# ---------- Categories ----------

@router.get("/shop/categories")
async def list_shop_categories(include_inactive: bool = False):
    q = "SELECT Id, Name, SortOrder, IsActive FROM ShopCategory WHERE 1=1"
    if not include_inactive:
        q += " AND IsActive = 1"
    q += " ORDER BY SortOrder, Id"
    return _ok_list("categories", fetch_all(q))


@router.post("/shop/categories", status_code=201)
async def create_shop_category(body: ShopCategoryCreate, user: dict = StaffDep):
    if fetch_one("SELECT Id FROM ShopCategory WHERE Name = ?", (body.name.strip(),)):
        raise _bad("نام دسته تکراری است")
    new_id = execute_returning_id(
        "INSERT INTO ShopCategory ([Name], [SortOrder], [IsActive]) VALUES (?, ?, ?)",
        (body.name.strip(), body.sort_order, 1 if body.is_active else 0),
    )
    return {"message": "دسته ایجاد شد", "id": new_id}


@router.put("/shop/categories/{category_id}")
async def update_shop_category(category_id: int, body: ShopCategoryUpdate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM ShopCategory WHERE Id = ?", (category_id,)):
        raise _not_found("Category")
    data = body.model_dump(exclude_unset=True)
    sets: list[str] = []
    params: list[Any] = []
    if "name" in data:
        sets.append("[Name] = ?")
        params.append(str(data["name"]).strip())
    if "sort_order" in data:
        sets.append("[SortOrder] = ?")
        params.append(data["sort_order"])
    if "is_active" in data:
        sets.append("[IsActive] = ?")
        params.append(1 if data["is_active"] else 0)
    if not sets:
        raise _bad("هیچ فیلدی ارسال نشده است")
    params.append(category_id)
    execute(f"UPDATE ShopCategory SET {', '.join(sets)} WHERE Id = ?", tuple(params))
    return {"message": "دسته به‌روزرسانی شد", "id": category_id}


# ---------- Products ----------

@router.get("/shop/products")
async def list_shop_products(
    search: Optional[str] = None,
    category_ref: Optional[int] = None,
    product_type: Optional[str] = None,
    featured_only: bool = False,
    include_inactive: bool = False,
    sort: Optional[str] = Query(None, pattern="^(price_asc|price_desc|newest|popular)$"),
    user: Optional[dict] = OptionalUserDep,
):
    q = PRODUCT_SELECT + " WHERE 1=1"
    params: list[Any] = []
    if not include_inactive:
        q += " AND P.IsActive = 1"
    if category_ref is not None:
        q += " AND P.CategoryRef = ?"
        params.append(category_ref)
    if product_type:
        q += " AND P.ProductType = ?"
        params.append(product_type)
    if featured_only:
        q += " AND P.IsFeatured = 1"
    if search:
        like = f"%{search.strip()}%"
        q += " AND (P.Name LIKE ? OR P.Sku LIKE ? OR P.Description LIKE ? OR C.Name LIKE ?)"
        params.extend([like, like, like, like])
    if sort == "price_asc":
        q += " ORDER BY P.Price ASC, P.Id DESC"
    elif sort == "price_desc":
        q += " ORDER BY P.Price DESC, P.Id DESC"
    elif sort == "popular":
        q += " ORDER BY LikeCount DESC, P.Id DESC"
    elif sort == "newest":
        q += " ORDER BY P.CreatedAt DESC, P.Id DESC"
    else:
        q += " ORDER BY P.IsFeatured DESC, P.Id DESC"
    rows = [_enrich_product(r, user) for r in fetch_all(q, tuple(params))]
    return _ok_list("products", rows)


@router.get("/shop/products/{product_id}")
async def get_shop_product(product_id: int, user: Optional[dict] = OptionalUserDep):
    row = fetch_one(PRODUCT_SELECT + " WHERE P.Id = ?", (product_id,))
    if not row or (not row.get("IsActive") and not user):
        raise _not_found("Product")
    return {"product": _enrich_product(row, user)}


@router.post("/shop/products", status_code=201)
async def create_shop_product(body: ShopProductCreate, user: dict = StaffDep):
    if body.category_ref and not fetch_one("SELECT Id FROM ShopCategory WHERE Id = ?", (body.category_ref,)):
        raise _bad("دسته نامعتبر است")
    if body.sku and fetch_one("SELECT Id FROM ShopProduct WHERE Sku = ?", (body.sku.strip(),)):
        raise _bad("کد کالا تکراری است")
    new_id = execute_returning_id(
        """INSERT INTO ShopProduct
            ([CategoryRef], [Name], [Sku], [Description], [Price], [Stock],
             [ProductType], [ImageUrl], [IsActive], [IsFeatured])
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            body.category_ref,
            body.name.strip(),
            (body.sku or "").strip() or None,
            body.description,
            body.price,
            body.stock,
            body.product_type,
            body.image_url,
            1 if body.is_active else 0,
            1 if body.is_featured else 0,
        ),
    )
    return {"message": "محصول ایجاد شد", "id": new_id}


@router.put("/shop/products/{product_id}")
async def update_shop_product(product_id: int, body: ShopProductUpdate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM ShopProduct WHERE Id = ?", (product_id,)):
        raise _not_found("Product")
    data = body.model_dump(exclude_unset=True)
    col_map = {
        "name": "Name",
        "category_ref": "CategoryRef",
        "sku": "Sku",
        "description": "Description",
        "price": "Price",
        "stock": "Stock",
        "product_type": "ProductType",
        "image_url": "ImageUrl",
        "is_active": "IsActive",
        "is_featured": "IsFeatured",
    }
    sets: list[str] = []
    params: list[Any] = []
    for key, col in col_map.items():
        if key not in data:
            continue
        val = data[key]
        if key in ("is_active", "is_featured"):
            val = 1 if val else 0
        if key in ("name", "sku") and isinstance(val, str):
            val = val.strip() or None
        sets.append(f"[{col}] = ?")
        params.append(val)
    if not sets:
        raise _bad("هیچ فیلدی ارسال نشده است")
    params.append(product_id)
    execute(f"UPDATE ShopProduct SET {', '.join(sets)} WHERE Id = ?", tuple(params))
    return {"message": "محصول به‌روزرسانی شد", "id": product_id}


@router.delete("/shop/products/{product_id}")
async def archive_shop_product(product_id: int, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM ShopProduct WHERE Id = ?", (product_id,)):
        raise _not_found("Product")
    execute("UPDATE ShopProduct SET IsActive = 0 WHERE Id = ?", (product_id,))
    return {"message": "محصول آرشیو شد", "id": product_id}


# ---------- Like / Bookmark ----------

@router.post("/shop/products/{product_id}/like")
async def toggle_product_like(product_id: int, user: dict = AuthDep):
    if not fetch_one("SELECT Id FROM ShopProduct WHERE Id = ? AND IsActive = 1", (product_id,)):
        raise _not_found("Product")
    existing = fetch_one(
        "SELECT Id FROM ShopProductLike WHERE UserRef = ? AND ProductRef = ?",
        (user["Id"], product_id),
    )
    if existing:
        execute("DELETE FROM ShopProductLike WHERE Id = ?", (existing["Id"],))
        liked = False
    else:
        execute_returning_id(
            "INSERT INTO ShopProductLike ([UserRef], [ProductRef]) VALUES (?, ?)",
            (user["Id"], product_id),
        )
        liked = True
    count = fetch_one(
        "SELECT COUNT(*) AS Cnt FROM ShopProductLike WHERE ProductRef = ?",
        (product_id,),
    )
    return {"liked": liked, "like_count": int(count["Cnt"]) if count else 0}


@router.post("/shop/products/{product_id}/bookmark")
async def toggle_product_bookmark(product_id: int, user: dict = AuthDep):
    if not fetch_one("SELECT Id FROM ShopProduct WHERE Id = ? AND IsActive = 1", (product_id,)):
        raise _not_found("Product")
    existing = fetch_one(
        "SELECT Id FROM ShopProductBookmark WHERE UserRef = ? AND ProductRef = ?",
        (user["Id"], product_id),
    )
    if existing:
        execute("DELETE FROM ShopProductBookmark WHERE Id = ?", (existing["Id"],))
        bookmarked = False
    else:
        execute_returning_id(
            "INSERT INTO ShopProductBookmark ([UserRef], [ProductRef]) VALUES (?, ?)",
            (user["Id"], product_id),
        )
        bookmarked = True
    return {"bookmarked": bookmarked}


@router.get("/shop/me/likes")
async def my_liked_products(user: dict = AuthDep):
    rows = fetch_all(
        PRODUCT_SELECT
        + """
        JOIN ShopProductLike L ON L.ProductRef = P.Id
        WHERE L.UserRef = ? AND P.IsActive = 1
        ORDER BY L.CreatedAt DESC
        """,
        (user["Id"],),
    )
    return _ok_list("products", [_enrich_product(r, user) for r in rows])


@router.get("/shop/me/bookmarks")
async def my_bookmarked_products(user: dict = AuthDep):
    rows = fetch_all(
        PRODUCT_SELECT
        + """
        JOIN ShopProductBookmark B ON B.ProductRef = P.Id
        WHERE B.UserRef = ? AND P.IsActive = 1
        ORDER BY B.CreatedAt DESC
        """,
        (user["Id"],),
    )
    return _ok_list("products", [_enrich_product(r, user) for r in rows])


# ---------- Cart ----------

def _cart_owner_clause(user: Optional[dict], session_key: Optional[str]) -> tuple[str, tuple]:
    if user:
        return "CI.UserRef = ?", (user["Id"],)
    if session_key:
        return "CI.SessionKey = ? AND CI.UserRef IS NULL", (session_key,)
    raise _bad("برای سبد خرید وارد شوید یا کلید نشست ارسال کنید")


def _merge_guest_cart(user_id: int, session_key: Optional[str]) -> None:
    if not session_key:
        return
    guest_items = fetch_all(
        "SELECT Id, ProductRef, Qty FROM ShopCartItem WHERE SessionKey = ? AND UserRef IS NULL",
        (session_key,),
    )
    for item in guest_items:
        existing = fetch_one(
            "SELECT Id, Qty FROM ShopCartItem WHERE UserRef = ? AND ProductRef = ?",
            (user_id, item["ProductRef"]),
        )
        if existing:
            execute(
                "UPDATE ShopCartItem SET Qty = ?, UpdatedAt = SYSUTCDATETIME() WHERE Id = ?",
                (int(existing["Qty"]) + int(item["Qty"]), existing["Id"]),
            )
            execute("DELETE FROM ShopCartItem WHERE Id = ?", (item["Id"],))
        else:
            execute(
                "UPDATE ShopCartItem SET UserRef = ?, SessionKey = NULL, UpdatedAt = SYSUTCDATETIME() WHERE Id = ?",
                (user_id, item["Id"]),
            )


@router.get("/shop/cart")
async def get_cart(
    user: Optional[dict] = OptionalUserDep,
    x_cart_session: Optional[str] = Header(None, alias="X-Cart-Session"),
):
    session_key = _session_key(x_cart_session)
    if user and session_key:
        _merge_guest_cart(user["Id"], session_key)
    if not user and not session_key:
        return {"items": [], "count": 0, "total": 0, "session_key": secrets.token_hex(16)}

    clause, params = _cart_owner_clause(user, session_key)
    rows = fetch_all(
        f"""
        SELECT CI.Id, CI.ProductRef, CI.Qty, CI.UpdatedAt,
               P.Name, P.Price, P.Stock, P.ImageUrl, P.Sku, P.IsActive
        FROM ShopCartItem CI
        JOIN ShopProduct P ON CI.ProductRef = P.Id
        WHERE {clause} AND CI.Qty > 0
        ORDER BY CI.UpdatedAt DESC
        """,
        params,
    )
    total = sum(int(r["Price"]) * int(r["Qty"]) for r in rows)
    return {
        "items": rows,
        "count": sum(int(r["Qty"]) for r in rows),
        "total": total,
        "session_key": None if user else session_key,
    }


@router.post("/shop/cart")
async def upsert_cart_item(
    body: CartItemUpsert,
    user: Optional[dict] = OptionalUserDep,
    x_cart_session: Optional[str] = Header(None, alias="X-Cart-Session"),
):
    product = fetch_one(
        "SELECT Id, Stock, IsActive, Name FROM ShopProduct WHERE Id = ?",
        (body.product_ref,),
    )
    if not product or not product.get("IsActive"):
        raise _not_found("Product")
    session_key = _session_key(x_cart_session)
    if not user and not session_key:
        session_key = secrets.token_hex(16)

    if body.qty <= 0:
        if user:
            execute(
                "DELETE FROM ShopCartItem WHERE UserRef = ? AND ProductRef = ?",
                (user["Id"], body.product_ref),
            )
        else:
            execute(
                "DELETE FROM ShopCartItem WHERE SessionKey = ? AND UserRef IS NULL AND ProductRef = ?",
                (session_key, body.product_ref),
            )
        return {"message": "از سبد حذف شد", "session_key": None if user else session_key}

    if body.qty > int(product["Stock"]):
        raise _bad(f"موجودی «{product['Name']}» کافی نیست (موجودی: {product['Stock']})")

    if user:
        existing = fetch_one(
            "SELECT Id FROM ShopCartItem WHERE UserRef = ? AND ProductRef = ?",
            (user["Id"], body.product_ref),
        )
        if existing:
            execute(
                "UPDATE ShopCartItem SET Qty = ?, UpdatedAt = SYSUTCDATETIME() WHERE Id = ?",
                (body.qty, existing["Id"]),
            )
        else:
            execute_returning_id(
                "INSERT INTO ShopCartItem ([UserRef], [ProductRef], [Qty]) VALUES (?, ?, ?)",
                (user["Id"], body.product_ref, body.qty),
            )
    else:
        existing = fetch_one(
            "SELECT Id FROM ShopCartItem WHERE SessionKey = ? AND UserRef IS NULL AND ProductRef = ?",
            (session_key, body.product_ref),
        )
        if existing:
            execute(
                "UPDATE ShopCartItem SET Qty = ?, UpdatedAt = SYSUTCDATETIME() WHERE Id = ?",
                (body.qty, existing["Id"]),
            )
        else:
            execute_returning_id(
                "INSERT INTO ShopCartItem ([SessionKey], [ProductRef], [Qty]) VALUES (?, ?, ?)",
                (session_key, body.product_ref, body.qty),
            )
    return {"message": "سبد به‌روزرسانی شد", "session_key": None if user else session_key}


@router.delete("/shop/cart")
async def clear_cart(
    user: Optional[dict] = OptionalUserDep,
    x_cart_session: Optional[str] = Header(None, alias="X-Cart-Session"),
):
    session_key = _session_key(x_cart_session)
    if user:
        execute("DELETE FROM ShopCartItem WHERE UserRef = ?", (user["Id"],))
    elif session_key:
        execute("DELETE FROM ShopCartItem WHERE SessionKey = ? AND UserRef IS NULL", (session_key,))
    else:
        raise _bad("سبد خالی است")
    return {"message": "سبد خالی شد"}


@router.post("/shop/checkout", status_code=201)
async def checkout(
    body: ShopCheckoutRequest,
    user: Optional[dict] = OptionalUserDep,
    x_cart_session: Optional[str] = Header(None, alias="X-Cart-Session"),
):
    session_key = _session_key(x_cart_session)
    if user and session_key:
        _merge_guest_cart(user["Id"], session_key)
    clause, params = _cart_owner_clause(user, session_key)
    items = fetch_all(
        f"""
        SELECT CI.Id AS CartId, CI.ProductRef, CI.Qty, P.Name, P.Price, P.Stock, P.IsActive
        FROM ShopCartItem CI
        JOIN ShopProduct P ON CI.ProductRef = P.Id
        WHERE {clause} AND CI.Qty > 0
        """,
        params,
    )
    if not items:
        raise _bad("سبد خرید خالی است")

    for item in items:
        if not item.get("IsActive"):
            raise _bad(f"محصول «{item['Name']}» دیگر فعال نیست")
        if int(item["Qty"]) > int(item["Stock"]):
            raise _bad(f"موجودی «{item['Name']}» کافی نیست")

    total = sum(int(i["Price"]) * int(i["Qty"]) for i in items)
    order_id = execute_returning_id(
        """INSERT INTO ShopOrder ([UserRef], [SessionKey], [Status], [TotalAmount], [Note])
           VALUES (?, ?, N'pending', ?, ?)""",
        (
            user["Id"] if user else None,
            None if user else session_key,
            total,
            body.note,
        ),
    )
    for item in items:
        execute_returning_id(
            """INSERT INTO ShopOrderItem ([OrderRef], [ProductRef], [Qty], [UnitPrice])
               VALUES (?, ?, ?, ?)""",
            (order_id, item["ProductRef"], item["Qty"], item["Price"]),
        )
        execute(
            "UPDATE ShopProduct SET Stock = Stock - ? WHERE Id = ?",
            (item["Qty"], item["ProductRef"]),
        )
    if user:
        execute("DELETE FROM ShopCartItem WHERE UserRef = ?", (user["Id"],))
    else:
        execute("DELETE FROM ShopCartItem WHERE SessionKey = ? AND UserRef IS NULL", (session_key,))

    return {
        "message": "سفارش ثبت شد",
        "order_id": order_id,
        "total": total,
        "status": "pending",
    }


@router.get("/shop/orders")
async def list_shop_orders(user: dict = StaffDep):
    rows = fetch_all(
        """
        SELECT O.Id, O.UserRef, O.SessionKey, O.Status, O.TotalAmount, O.Note, O.CreatedAt,
               U.FullName AS UserName, U.Username
        FROM ShopOrder O
        LEFT JOIN AppUser U ON O.UserRef = U.Id
        ORDER BY O.Id DESC
        """
    )
    return _ok_list("orders", rows)
