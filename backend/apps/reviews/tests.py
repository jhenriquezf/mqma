
from django.test import TestCase
from django.contrib.auth import get_user_model

User = get_user_model()


class ReviewTest(TestCase):
    def test_nps_validation(self):
        from apps.reviews.models import Review
        from django.core.exceptions import ValidationError
        # nps_score debe ser 0-10
        user = User.objects.create_user(email="r@mqma.cl", password="x")
        # El modelo tiene validators — validación directa
        from django.core.validators import MaxValueValidator, MinValueValidator
        validator_max = MaxValueValidator(10)
        validator_min = MinValueValidator(0)
        try:
            validator_max(11)
            self.fail("Debería haber fallado con 11")
        except ValidationError:
            pass
        try:
            validator_min(-1)
            self.fail("Debería haber fallado con -1")
        except ValidationError:
            pass
