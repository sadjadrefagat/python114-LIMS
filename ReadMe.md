# نحوه راه اندازی دیتابیس
کافی است فایل limsdb.bak را از پوشه query برداشته و آنرا restore کنید.

# نحوه اجرای بک اند
رشته اتصال را در فایل database.py در پروژه backend اصلاح کنید. مثدار ثابت `DEFAULT_CONN_STR` را متناسب با پیکربندی سیستم خود تغییر دهید.
وارد پوشه backend در src شده و کد زیر را در cmd اجرا کنید:
`python -m uvicorn main:app --host 0.0.0.0 --reload`

# نحوه اجرای فرانت اند
وارد پوشه frontend در src شده و دستور زیر را در cmd اجرا کنید:
`npm run dev`