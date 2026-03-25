
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from .models import Profile, ProfileTag, DeviceToken
from .serializers import ProfileSerializer, ProfileUpdateSerializer, UserMeSerializer


class MeView(APIView):
    """GET /users/me/ — perfil completo del usuario autenticado."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserMeSerializer(request.user)
        return Response(serializer.data)


class ProfileDetailView(generics.RetrieveUpdateAPIView):
    """GET/PATCH /users/profile/ — ver y editar el propio perfil."""
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_serializer_class(self):
        if self.request.method in ('PUT', 'PATCH'):
            return ProfileUpdateSerializer
        return ProfileSerializer

    def get_object(self):
        profile, _ = Profile.objects.get_or_create(user=self.request.user)
        return profile


class DeviceTokenView(APIView):
    """
    POST   /users/device-token/  → registra (o actualiza) el token FCM del dispositivo
    DELETE /users/device-token/  → elimina el token al cerrar sesión
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        token = request.data.get("token", "").strip()
        platform = request.data.get("platform", "android")
        if not token:
            return Response({"error": "token requerido"}, status=status.HTTP_400_BAD_REQUEST)
        if platform not in ("android", "ios", "web"):
            return Response({"error": "platform inválida"}, status=status.HTTP_400_BAD_REQUEST)

        _, created = DeviceToken.objects.update_or_create(
            user=request.user,
            token=token,
            defaults={"platform": platform},
        )
        return Response(
            {"registered": True},
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )

    def delete(self, request):
        token = request.data.get("token", "").strip()
        qs = DeviceToken.objects.filter(user=request.user)
        if token:
            qs = qs.filter(token=token)
        qs.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ProfileTagView(APIView):
    """POST/DELETE /users/profile/tags/ — gestión de tags del perfil."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        profile, _ = Profile.objects.get_or_create(user=request.user)
        tag = request.data.get('tag', '').strip().lower()
        category = request.data.get('category', 'interest')
        if not tag:
            return Response({'error': 'tag requerido'}, status=400)
        if profile.tags.count() >= 20:
            return Response({'error': 'máximo 20 tags'}, status=400)
        obj, created = ProfileTag.objects.get_or_create(
            profile=profile, tag=tag, defaults={'category': category}
        )
        return Response({'id': str(obj.id), 'tag': obj.tag, 'category': obj.category},
                        status=201 if created else 200)

    def delete(self, request):
        profile, _ = Profile.objects.get_or_create(user=request.user)
        tag = request.data.get('tag', '').strip().lower()
        deleted, _ = ProfileTag.objects.filter(profile=profile, tag=tag).delete()
        return Response(status=204 if deleted else 404)
