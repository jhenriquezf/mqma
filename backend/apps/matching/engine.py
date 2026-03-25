"""
Motor de matching MQMA — V1
Score = intereses (30%) + etapa (25%) + objetivo (25%) + personalidad (20%)
Retorna grupos propuestos sin persistir — el admin aprueba antes de guardar.
"""
from itertools import combinations
from apps.users.models import Profile


WEIGHTS = {
    "interests": 0.30,
    "stage": 0.25,
    "looking_for": 0.25,
    "personality": 0.20,
}

STAGE_PROXIMITY = {
    "idea": 0, "mvp": 1, "early": 2, "growth": 3,
    "scale": 4, "executive": 5, "investor": 6, "other": 3,
}


def _interest_score(p1: Profile, p2: Profile) -> float:
    tags1 = set(p1.tags.filter(category="interest").values_list("tag", flat=True))
    tags2 = set(p2.tags.filter(category="interest").values_list("tag", flat=True))
    if not tags1 or not tags2:
        return 0.5
    intersection = tags1 & tags2
    union = tags1 | tags2
    return len(intersection) / len(union)


def _stage_score(p1: Profile, p2: Profile) -> float:
    s1 = STAGE_PROXIMITY.get(p1.stage, 3)
    s2 = STAGE_PROXIMITY.get(p2.stage, 3)
    diff = abs(s1 - s2)
    return max(0.0, 1 - diff * 0.2)


def _looking_for_score(p1: Profile, p2: Profile) -> float:
    # Diversidad de objetivos suma más que homogeneidad
    if p1.looking_for != p2.looking_for:
        return 0.8
    return 0.4


def _personality_score(p1: Profile, p2: Profile) -> float:
    if not p1.mbti or not p2.mbti:
        return 0.5
    # Introvertido/extrovertido complementario
    intro_extro = (p1.mbti[0] != p2.mbti[0])
    return 0.75 if intro_extro else 0.5


def pair_score(p1: Profile, p2: Profile) -> float:
    return (
        WEIGHTS["interests"] * _interest_score(p1, p2)
        + WEIGHTS["stage"] * _stage_score(p1, p2)
        + WEIGHTS["looking_for"] * _looking_for_score(p1, p2)
        + WEIGHTS["personality"] * _personality_score(p1, p2)
    )


def group_score(profiles: list[Profile]) -> float:
    if len(profiles) < 2:
        return 0.0
    pairs = list(combinations(profiles, 2))
    return sum(pair_score(a, b) for a, b in pairs) / len(pairs)


def build_groups(profiles: list[Profile], group_size: int = 6) -> list[dict]:
    """
    Algoritmo greedy: ordena por score acumulado y agrupa.
    Retorna lista de dicts {profiles, score} listos para que el admin apruebe.
    """
    remaining = list(profiles)
    groups = []

    while len(remaining) >= group_size:
        best_group = None
        best_score = -1

        # Toma el primer perfil como ancla y busca los mejores compañeros
        anchor = remaining[0]
        candidates = remaining[1:]
        scored = sorted(
            candidates,
            key=lambda p: pair_score(anchor, p),
            reverse=True,
        )
        group = [anchor] + scored[: group_size - 1]
        score = group_score(group)

        if score > best_score:
            best_score = score
            best_group = group

        groups.append({"profiles": best_group, "score": round(best_score, 4)})
        for p in best_group:
            remaining.remove(p)

    # Resto que no alcanzó a formar grupo completo — admin decide
    if remaining:
        groups.append({"profiles": remaining, "score": 0.0, "incomplete": True})

    return groups
