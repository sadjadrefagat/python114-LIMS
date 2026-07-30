import { Link } from 'react-router-dom'

const TEAM_WOMEN = [
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
]

const TEAM_MEN = [
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
  titles: ['راهبر تیم', 'مدیر محصول', 'طراح و معمار ارشد نرم‌افزار'],
  email: 'sadjadrefagat@gmail.com',
  avatar: '/avatars/avatar-sadjad.jpg?v=4',
}

function Person({ person, featured = false }) {
  const titles = person.titles?.length
    ? person.titles
    : [person.roleFa, person.role].filter(Boolean)

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
      <ul className={`about-person-role ${featured ? 'is-titles' : ''}`}>
        {titles.map((title) => (
          <li key={title}>{title}</li>
        ))}
      </ul>
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
          <p className="about-brand fade-up">لیمـز</p>
          <h1 className="about-hero-title fade-up">سامانه مدیریت آموزشگاه زبان</h1>
          <p className="about-hero-text fade-up-delay">
            لیمز به آموزشگاه‌ها کمک می‌کند ثبت‌نام، کلاس‌ها، جلسات و مسیر پیشرفت زبان‌آموزان را
            یکپارچه و شفاف مدیریت کنند.
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

      <section className="about-mission">
        <div className="container about-mission-inner fade-up">
          <h2 className="about-mission-title">چشم‌انداز ما</h2>
          <p className="about-mission-text">
            آموزشگاه‌های زبان امروز به ابزاری نیاز دارند که عملیات روزمره را ساده کند، نه پیچیده.
            لیمز با تمرکز بر مدیریت دوره‌ها، ظرفیت کلاس‌ها، ثبت‌نام و پیگیری وضعیت مالی،
            تصویری روشن از عملکرد آموزشگاه در اختیار مدیران قرار می‌دهد تا تصمیم‌گیری سریع‌تر و
            دقیق‌تر باشد.
          </p>
        </div>
      </section>

      <section className="about-lead-section" id="team">
        <div className="container">
          <div className="about-section-head fade-up">
            <h2 className="about-section-title">تیم لیمز</h2>
            <p className="about-section-sub">
              متخصصانی که طراحی محصول، توسعه و کیفیت سامانه را پیش می‌برند
            </p>
          </div>
          <div className="about-lead-stage">
            <Person person={TEAM_LEAD} featured />
          </div>
        </div>
      </section>

      <section className="about-team-section">
        <div className="container">
          <div className="about-section-head fade-up">
            <h2 className="about-section-title">اعضای تیم</h2>
            <p className="about-section-sub">طراحی، مهندسی نرم‌افزار و تضمین کیفیت</p>
          </div>
          <div className="about-team-rows">
            <div className="about-team-row" aria-label="اعضای تیم — سطر اول">
              {TEAM_WOMEN.map((person) => (
                <Person key={person.email} person={person} />
              ))}
            </div>
            <div className="about-team-row" aria-label="اعضای تیم — سطر دوم">
              {TEAM_MEN.map((person) => (
                <Person key={person.email} person={person} />
              ))}
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
