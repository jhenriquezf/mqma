"""
Management command: seed_data
Crea datos de prueba ricos para testear el algoritmo de matching.

Uso:
    python manage.py seed_data           # crea todo
    python manage.py seed_data --reset   # borra data previa y recrea

Genera:
  • 1 ciudad  (Santiago)
  • 2 restaurantes
  • 9 usuarios con perfiles completos (MBTI, stage, tags, etc.)
  • 3 eventos en distintos estados
  • Bookings + pagos confirmados para activar el matching
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone
from datetime import date, time, timedelta


USERS_DATA = [
    # ─────────────────────────────────────────────────────────────────────────
    # Grupo ideal A (evento "Cena Networking" — 6 confirmados)
    # Alta afinidad: todos en ecosistema SaaS/tech, etapas compatibles
    # ─────────────────────────────────────────────────────────────────────────
    {
        "email": "ana.torres@mqma.test",
        "password": "Mqma2024!",
        "name": "Ana Torres",
        "age": 31,
        "bio": "Fundadora de SaaS B2B para pymes. Apasionada por el product-led growth.",
        "industry": "SaaS / Software",
        "stage": "mvp",
        "looking_for": "investors",
        "mbti": "INTJ",
        "interests": ["saas", "fintech", "product management", "b2b"],
        "skills": ["product", "estrategia"],
        "sector": "tecnología",
    },
    {
        "email": "pedro.lagos@mqma.test",
        "password": "Mqma2024!",
        "name": "Pedro Lagos",
        "age": 42,
        "bio": "Inversor ángel con foco en SaaS y fintech. 12 exits en portafolio.",
        "industry": "Venture Capital",
        "stage": "investor",
        "looking_for": "cofounder",
        "mbti": "ENTP",
        "interests": ["fintech", "saas", "startups", "venture capital"],
        "skills": ["fundraising", "estrategia"],
        "sector": "inversión",
    },
    {
        "email": "camila.ruiz@mqma.test",
        "password": "Mqma2024!",
        "name": "Camila Ruiz",
        "age": 28,
        "bio": "CTO de startup IA. Builder de equipos técnicos desde cero.",
        "industry": "Inteligencia Artificial",
        "stage": "early",
        "looking_for": "talent",
        "mbti": "INTJ",
        "interests": ["inteligencia artificial", "saas", "producto", "tech"],
        "skills": ["engineering", "arquitectura"],
        "sector": "tecnología",
    },
    {
        "email": "diego.soto@mqma.test",
        "password": "Mqma2024!",
        "name": "Diego Soto",
        "age": 35,
        "bio": "CEO en growth stage, 3 años escalando modelo SaaS en Latam.",
        "industry": "SaaS / Software",
        "stage": "growth",
        "looking_for": "clients",
        "mbti": "ESTP",
        "interests": ["saas", "b2b", "growth hacking", "ventas"],
        "skills": ["sales", "liderazgo"],
        "sector": "tecnología",
    },
    {
        "email": "isabel.mora@mqma.test",
        "password": "Mqma2024!",
        "name": "Isabel Mora",
        "age": 29,
        "bio": "Product Manager con foco en UX y métricas. Fan de los OKRs.",
        "industry": "SaaS / Software",
        "stage": "mvp",
        "looking_for": "mentors",
        "mbti": "ENFP",
        "interests": ["product management", "ux design", "saas", "métricas"],
        "skills": ["product", "data analysis"],
        "sector": "tecnología",
    },
    {
        "email": "matias.vega@mqma.test",
        "password": "Mqma2024!",
        "name": "Matías Vega",
        "age": 47,
        "bio": "Advisor y mentor de startups. Ex-VP en empresa Fortune 500.",
        "industry": "Consultoría / Advisory",
        "stage": "executive",
        "looking_for": "network",
        "mbti": "ENTJ",
        "interests": ["startups", "b2b", "saas", "liderazgo"],
        "skills": ["mentoring", "estrategia"],
        "sector": "consultoría",
    },

    # ─────────────────────────────────────────────────────────────────────────
    # Grupo B (evento "Almuerzo Founders" — mezcla distinta de perfiles)
    # ─────────────────────────────────────────────────────────────────────────
    {
        "email": "valentina.park@mqma.test",
        "password": "Mqma2024!",
        "name": "Valentina Park",
        "age": 26,
        "bio": "Diseñadora UX / UI. Fundadora de estudio de diseño para startups.",
        "industry": "Diseño / Creative",
        "stage": "early",
        "looking_for": "clients",
        "mbti": "INFP",
        "interests": ["ux design", "producto", "branding", "startups"],
        "skills": ["diseño", "investigación"],
        "sector": "estudio creativo",  # distinto de "diseño" (skill)
    },
    {
        "email": "rodrigo.munoz@mqma.test",
        "password": "Mqma2024!",
        "name": "Rodrigo Muñoz",
        "age": 38,
        "bio": "Abogado especialista en startups. Fundador de LegalTech.",
        "industry": "LegalTech",
        "stage": "mvp",
        "looking_for": "network",
        "mbti": "ISTJ",
        "interests": ["legaltech", "startups", "b2b", "regulación"],
        "skills": ["legal", "contratos"],
        "sector": "servicios legales",  # distinto de "legal" (skill)
    },
    {
        "email": "francisca.herrera@mqma.test",
        "password": "Mqma2024!",
        "name": "Francisca Herrera",
        "age": 33,
        "bio": "Directora de Marketing. Growth hacker con experiencia en e-commerce y SaaS.",
        "industry": "Marketing Digital",
        "stage": "growth",
        "looking_for": "talent",
        "mbti": "ENFJ",
        "interests": ["marketing digital", "growth hacking", "b2b", "saas"],
        "skills": ["marketing", "contenido"],
        "sector": "agencia digital",  # distinto de "marketing" (skill)
    },
]


class Command(BaseCommand):
    help = "Crea datos de prueba para testing del algoritmo de matching"

    def add_arguments(self, parser):
        parser.add_argument(
            "--reset",
            action="store_true",
            help="Elimina datos de prueba previos antes de crear nuevos",
        )

    def handle(self, *args, **options):
        if options["reset"]:
            self._reset()

        self.stdout.write(self.style.MIGRATE_HEADING("🌱 Creando data de prueba MQMA…\n"))

        with transaction.atomic():
            city, restaurant1, restaurant2 = self._create_places()
            users = self._create_users(city)
            events = self._create_events(city, restaurant1, restaurant2)
            self._create_bookings(users, events)

        self._print_summary(users, events)

    # ── Reset ─────────────────────────────────────────────────────────────────

    def _reset(self):
        from apps.users.models import User
        test_emails = [u["email"] for u in USERS_DATA]
        deleted, _ = User.objects.filter(email__in=test_emails).delete()
        self.stdout.write(f"  🗑  {deleted} usuarios de prueba eliminados")

        from apps.events.models import City
        City.objects.filter(name="Santiago", country="Chile").delete()
        self.stdout.write("  🗑  Ciudad y datos relacionados eliminados\n")

    # ── Lugares ───────────────────────────────────────────────────────────────

    def _create_places(self):
        from apps.events.models import City, Restaurant

        city, created = City.objects.get_or_create(
            name="Santiago",
            country="Chile",
            defaults={"timezone": "America/Santiago", "active": True, "min_users": 50},
        )
        self.stdout.write(f"  {'✚' if created else '✓'} Ciudad: {city}")

        rest1, _ = Restaurant.objects.get_or_create(
            name="Bocanáriz",
            city=city,
            defaults={
                "address": "José Victorino Lastarria 276, Santiago Centro",
                "avg_price_clp": 35000,
                "dietary_options": ["vegetariano", "sin gluten"],
                "active": True,
                "notes": "Restaurante de vinos, ambiente íntimo, ideal para networking.",
            },
        )

        rest2, _ = Restaurant.objects.get_or_create(
            name="Osaka",
            city=city,
            defaults={
                "address": "Av. Nueva Costanera 4093, Vitacura",
                "avg_price_clp": 45000,
                "dietary_options": ["sin gluten", "mariscos"],
                "active": True,
                "notes": "Fusión nikkei, ambiente premium para founders.",
            },
        )

        self.stdout.write(f"  ✓ Restaurantes: {rest1.name}, {rest2.name}")
        return city, rest1, rest2

    # ── Usuarios ──────────────────────────────────────────────────────────────

    def _create_users(self, city):
        from apps.users.models import User, Profile, ProfileTag

        users = []
        for data in USERS_DATA:
            user, created = User.objects.get_or_create(
                email=data["email"],
                defaults={"is_active": True, "is_verified": True},
            )
            if created:
                user.set_password(data["password"])
                user.save()

            profile, _ = Profile.objects.update_or_create(
                user=user,
                defaults={
                    "name": data["name"],
                    "age": data["age"],
                    "bio": data["bio"],
                    "industry": data["industry"],
                    "stage": data["stage"],
                    "looking_for": data["looking_for"],
                    "mbti": data["mbti"],
                    "city": city,
                    "onboarding_complete": True,
                },
            )

            # Tags — borramos primero para recrear limpio; usamos un set para
            # evitar duplicados (unique_together impide mismo tag en distintas categorías)
            ProfileTag.objects.filter(profile=profile).delete()
            seen_tags: set[str] = set()
            tag_entries = (
                [(t, "interest") for t in data["interests"]]
                + [(t, "skill") for t in data["skills"]]
                + [(data["sector"], "sector")]
            )
            for tag, category in tag_entries:
                if tag not in seen_tags:
                    ProfileTag.objects.create(profile=profile, tag=tag, category=category)
                    seen_tags.add(tag)

            users.append(user)
            icon = "✚" if created else "✓"
            self.stdout.write(
                f"  {icon} {profile.name} [{data['mbti']}] "
                f"etapa={data['stage']} busca={data['looking_for']}"
            )

        self.stdout.write("")
        return users

    # ── Eventos ───────────────────────────────────────────────────────────────

    def _create_events(self, city, restaurant1, restaurant2):
        from apps.events.models import Event

        today = date.today()

        # Evento 1: Listo para matching (6 bookings confirmados)
        e1, _ = Event.objects.update_or_create(
            restaurant=restaurant1,
            event_date=today - timedelta(days=3),  # pasado = ya cerrado
            defaults={
                "city": city,
                "event_time": time(20, 0),
                "capacity": 30,
                "price_clp": 25000,
                "status": "matching",
                "type": "dinner",
                "notes": "Evento especial para founders de SaaS. Networking intensivo.",
            },
        )

        # Evento 2: Abierto para nuevas reservas
        e2, _ = Event.objects.update_or_create(
            restaurant=restaurant2,
            event_date=today + timedelta(days=14),
            defaults={
                "city": city,
                "event_time": time(13, 0),
                "capacity": 18,
                "price_clp": 35000,
                "status": "open",
                "type": "founders",
                "notes": "Almuerzo exclusivo para founders. Cupos muy limitados.",
            },
        )

        # Evento 3: Abierto, sin reservas (para probar el flujo completo)
        e3, _ = Event.objects.update_or_create(
            restaurant=restaurant1,
            event_date=today + timedelta(days=30),
            defaults={
                "city": city,
                "event_time": time(19, 30),
                "capacity": 24,
                "price_clp": 19900,
                "status": "open",
                "type": "dinner",
                "notes": "",
            },
        )

        self.stdout.write(f"  ✓ Evento 1 [{e1.get_status_display()}]: {e1.get_type_display()} {e1.event_date} → para matching")
        self.stdout.write(f"  ✓ Evento 2 [{e2.get_status_display()}]: {e2.get_type_display()} {e2.event_date} → abierto")
        self.stdout.write(f"  ✓ Evento 3 [{e3.get_status_display()}]: {e3.get_type_display()} {e3.event_date} → sin reservas")
        self.stdout.write("")
        return [e1, e2, e3]

    # ── Bookings + pagos ──────────────────────────────────────────────────────

    def _create_bookings(self, users, events):
        from apps.events.models import Booking
        from apps.payments.models import Payment

        e1, e2, e3 = events

        # Evento 1 (matching): los 6 primeros usuarios con booking confirmado + pago
        for user in users[:6]:
            booking, created = Booking.objects.get_or_create(
                user=user,
                event=e1,
                defaults={"status": "confirmed"},
            )
            if not created:
                booking.status = "confirmed"
                booking.save(update_fields=["status"])

            Payment.objects.get_or_create(
                booking=booking,
                defaults={
                    "provider": "flow",
                    "amount": e1.price_clp,
                    "currency": "CLP",
                    "status": "paid",
                    "paid_at": timezone.now(),
                },
            )

        self.stdout.write(f"  ✓ Evento 1: 6 bookings confirmados + pagos pagados")

        # Evento 2 (open): usuarios 7-9 con booking confirmado
        for user in users[6:]:
            booking, created = Booking.objects.get_or_create(
                user=user,
                event=e2,
                defaults={"status": "confirmed"},
            )
            if not created:
                booking.status = "confirmed"
                booking.save(update_fields=["status"])

            Payment.objects.get_or_create(
                booking=booking,
                defaults={
                    "provider": "flow",
                    "amount": e2.price_clp,
                    "currency": "CLP",
                    "status": "paid",
                    "paid_at": timezone.now(),
                },
            )

        self.stdout.write(f"  ✓ Evento 2: 3 bookings confirmados (aún acepta reservas)")

        # Evento 3 (open): sin bookings → para testear el flujo desde la app
        self.stdout.write(f"  ✓ Evento 3: sin bookings (úsalo para testear la app)\n")

    # ── Resumen ───────────────────────────────────────────────────────────────

    def _print_summary(self, users, events):
        from apps.matching.engine import build_groups
        from apps.users.models import Profile

        e1 = events[0]
        confirmed_profiles = list(
            Profile.objects.filter(
                user__bookings__event=e1,
                user__bookings__status="confirmed",
            ).prefetch_related("tags")
        )

        self.stdout.write(self.style.SUCCESS("✅ Data creada exitosamente!\n"))
        self.stdout.write(self.style.MIGRATE_HEADING("📊 Simulación del matching para Evento 1:"))
        self.stdout.write(f"   Perfiles disponibles: {len(confirmed_profiles)}\n")

        if len(confirmed_profiles) >= 2:
            groups = build_groups(confirmed_profiles, group_size=6)
            for i, g in enumerate(groups, 1):
                names = [p.name for p in g["profiles"]]
                incomplete = " ⚠ incompleto" if g.get("incomplete") else ""
                self.stdout.write(
                    f"   Grupo {i} (score={g['score']:.3f}{incomplete}):"
                )
                for p in g["profiles"]:
                    self.stdout.write(
                        f"      • {p.name} [{p.mbti}] "
                        f"{p.stage} → busca {p.looking_for}"
                    )
                self.stdout.write("")

        self.stdout.write(self.style.MIGRATE_HEADING("🔑 Credenciales de prueba:"))
        for data in USERS_DATA:
            self.stdout.write(f"   {data['email']}  /  {data['password']}")

        self.stdout.write("")
        self.stdout.write(self.style.MIGRATE_HEADING("🚀 Próximos pasos:"))
        self.stdout.write("   1. Admin → /admin/matching/panel/  → selecciona Evento 1 → 'Correr Matching'")
        self.stdout.write("   2. App Flutter → inicia sesión como ana.torres@mqma.test")
        self.stdout.write("   3. Evento 3 (sin reservas) → prueba el booking flow completo con Flow")
        self.stdout.write("")
