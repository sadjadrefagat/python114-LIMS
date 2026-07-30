import { Link } from 'react-router-dom'

const DESIGN_TEAM = [
  {
    name: 'اسرا رهبران',
    role: 'Product Designer',
    roleFa: 'طراح محصول',
    email: 'asra.rahbaran@lims.dev',
    avatar: '/avatars/avatar-asra.jpg?v=3',
  },
  {
    name: 'صبا صمدیان',
    role: 'UI Designer',
    roleFa: 'طراح رابط کاربری',
    email: 'saba.samadian@lims.dev',
    avatar: '/avatars/avatar-saba.jpg',
  },
  {
    name: 'وحیده سیدی',
    role: 'Frontend Engineer',
    roleFa: 'مهندس فرانت‌اند',
    email: 'vahideh.seyedi@lims.dev',
    avatar: '/avatars/avatar-vahideh.jpg',
  },
  {
    name: 'امیررضا حسنی',
    role: 'Backend Engineer',
    roleFa: 'مهندس بک‌اند',
    email: 'amirreza.hasani@lims.dev',
    avatar: '/avatars/avatar-amirreza.jpg',
  },
  {
    name: 'الیار نورنواز',
    role: 'QA Engineer',
    roleFa: 'مهندس تضمین کیفیت',
    email: 'elyar.nournavaz@lims.dev',
    avatar: '/avatars/avatar-elyar.jpg',
  },
  {
    name: 'عرشیا فرجی',
    role: 'Full-stack Developer',
    roleFa: 'توسعه‌دهنده فول‌استک',
    email: 'arshia.faraji@lims.dev',
    avatar: '/avatars/avatar-arshia.jpg',
  },
]

const TEAM_LEAD = {
  name: 'سجاد رفاقت',
  role: 'Tech Lead & Product Owner',
  roleFa: 'راهبر فنی و مدیر محصول',
  email: 'sadjadrefagat@gmail.com',
  avatar: '/avatars/avatar-sadjad.jpg?v=4',
}

function Person({ person, featured = false }) {
  return (
    <article className={`about-person ${featured ? 'is-featured' : ''} fade-up`}>
      <div className="about-avatar-wrap">
        <img
          className="about-avatar"
          src={person.avatar}
          alt={person.name}
          width={featured ? 168 : 128}
          height={featured ? 168 : 128}
          loading="lazy"
        />
      </div>
      <h3 className="about-person-name">{person.name}</h3>
      <p className="about-person-role">
        <span className="about-role-fa">{person.roleFa}</span>
        <span className="about-role-en">{person.role}</span>
      </p>
      <a className="about-person-email" href={`mailto:${person.email}`}>
        {person.email}
      </a>
    </article>
  )
}

export default function About() {
  return (
    <div className="about-page">
      <section className="about-hero">
        <div className="about-hero-bg" aria-hidden="true" />
        <div className="container about-hero-inner">
          <p className="about-brand fade-up">آموزشگاه لیمز</p>
          <h1 className="about-hero-title fade-up">تیمی که سامانه را ساخت</h1>
          <p className="about-hero-text fade-up-delay">
            از طراحی تجربه کاربری تا معماری بک‌اند — کسانی که LIMS را زنده نگه می‌دارند.
          </p>
          <div className="about-hero-cta fade-up-delay">
            <a href="#team" className="btn btn-brand btn-lg rounded-pill px-4">
              آشنایی با تیم
            </a>
            <Link to="/courses" className="btn btn-outline-light btn-lg rounded-pill px-4">
              مشاهده دوره‌ها
            </Link>
          </div>
        </div>
      </section>

      <section className="about-lead-section" id="team">
        <div className="container">
          <div className="about-section-head fade-up">
            <h2 className="about-section-title">راهبر و مدیر تیم</h2>
            <p className="about-section-sub">هدایت محصول، اولویت‌بندی بک‌لاگ و هم‌راستایی تیم</p>
          </div>
          <div className="about-lead-stage">
            <Person person={TEAM_LEAD} featured />
          </div>
        </div>
      </section>

      <section className="about-team-section">
        <div className="container">
          <div className="about-section-head fade-up">
            <h2 className="about-section-title">تیم طراحی و توسعه</h2>
            <p className="about-section-sub">
              طراحان محصول، مهندسان فرانت‌اند و بک‌اند، و تضمین کیفیت
            </p>
          </div>
          <div className="about-team-grid">
            {DESIGN_TEAM.map((person) => (
              <Person key={person.email} person={person} />
            ))}
          </div>
        </div>
      </section>

      <section className="about-mission">
        <div className="container about-mission-inner fade-up">
          <h2 className="about-mission-title">چرا لیمز؟</h2>
          <p className="about-mission-text">
            هدف ما یکپارچه‌سازی ثبت‌نام، کلاس‌بندی، حضور و پیشرفت زبان‌آموز در یک سامانه RTL شفاف
            است — با فونت وزیر، تقویم شمسی، و جریان کاری قابل اتکا برای آموزشگاه.
          </p>
        </div>
      </section>
    </div>
  )
}
