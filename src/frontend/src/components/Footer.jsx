import { Link } from 'react-router-dom'

export default function Footer() {
  return (
    <footer className="footer-lims">
      <div className="container d-flex flex-wrap justify-content-between gap-2">
        <div>© آموزشگاه زبان لیمز — سامانه مدیریت یکپارچه</div>
        <div className="d-flex flex-wrap gap-3">
          <Link to="/about" className="footer-link">
            درباره ما
          </Link>
          <span>پشتیبانی: support@lims.local</span>
        </div>
      </div>
    </footer>
  )
}
