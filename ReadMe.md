# نحوه راه اندازی دیتابیس
کافی است فایل limsdb.bak را از پوشه query برداشته و آنرا restore کنید.

# نحوه اجرای بک اند
وارد پوشه backend در src شده و کد زیر را در cmd اجرا کنید:
`python -m uvicorn main:app --host 0.0.0.0 --reload`

# نحوه اجرای فرانت اند
وارد پوشه frontend در src شده و دستور زیر را در cmd اجرا کنید:
`npm run dev`