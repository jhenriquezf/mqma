import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _saving = false;
  final _nameCtrl = TextEditingController();
  String? _stage;
  String? _lookingFor;
  final Set<String> _interests = {};
  String? _mbti;

  static const _stages = [
    ('idea', 'Idea'), ('mvp', 'MVP'), ('early', 'Early stage'),
    ('growth', 'Growth'), ('scale', 'Scale'),
    ('executive', 'Ejecutivo'), ('investor', 'Inversor'),
  ];

  static const _goals = [
    ('cofounder', 'Cofundador'), ('clients', 'Clientes'),
    ('investors', 'Inversores'), ('talent', 'Talento'),
    ('mentors', 'Mentores'), ('network', 'Expandir red'), ('friends', 'Amigos'),
  ];

  static const _tags = [
    'IA', 'Fintech', 'SaaS', 'E-commerce', 'Salud',
    'Educación', 'Retail', 'Gastronomía', 'Sostenibilidad',
    'Cripto', 'Real estate', 'Marketing', 'Legal', 'RRHH',
  ];

  static const _mbtis = [
    'INTJ','INTP','ENTJ','ENTP','INFJ','INFP','ENFJ','ENFP',
    'ISTJ','ISFJ','ESTJ','ESFJ','ISTP','ISFP','ESTP','ESFP',
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 4) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);

    final error = await ref.read(authStateProvider.notifier).completeOnboarding(
      name: _nameCtrl.text.trim(),
      stage: _stage,
      lookingFor: _lookingFor,
      interests: _interests.toList(),
      mbti: _mbti,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.go('/events');
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Barra de progreso
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: List.generate(5, (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i <= _step
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFFE8E6DF),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _nameStep(),
                  _choiceStep('¿En qué etapa estás?', 'Nos ayuda a encontrar personas similares', _stages, _stage, (v) => setState(() => _stage = v)),
                  _choiceStep('¿Qué buscas en una mesa?', 'Sé honesto — mejora el matching', _goals, _lookingFor, (v) => setState(() => _lookingFor = v)),
                  _interestsStep(),
                  _mbtiStep(),
                ],
              ),
            ),
            // CTA principal
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                onPressed: _saving ? null : _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _step == 4 ? 'Empezar' : 'Continuar',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _nameStep() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      const Text('¿Cómo te llaman?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('El nombre que verán en la mesa', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      const SizedBox(height: 32),
      TextField(
        controller: _nameCtrl, autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(hintText: 'Tu nombre'),
      ),
    ]),
  );

  Widget _choiceStep(
    String title,
    String sub,
    List<(String, String)> opts,
    String? sel,
    void Function(String) onSel,
  ) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(sub, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      const SizedBox(height: 24),
      Expanded(child: ListView(
        children: opts.map((o) => GestureDetector(
          onTap: () => onSel(o.$1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: sel == o.$1 ? const Color(0xFF1D9E75).withValues(alpha: 0.08) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel == o.$1 ? const Color(0xFF1D9E75) : Colors.grey[200]!,
                width: sel == o.$1 ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  o.$2,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: sel == o.$1 ? FontWeight.w600 : FontWeight.w400,
                    color: sel == o.$1 ? const Color(0xFF0F6E56) : Colors.grey[800],
                  ),
                ),
                if (sel == o.$1)
                  const Icon(Icons.check_circle, color: Color(0xFF1D9E75), size: 20),
              ],
            ),
          ),
        )).toList(),
      )),
    ]),
  );

  Widget _interestsStep() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      const Text('¿Qué te mueve?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Elige hasta 5 temas', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      const SizedBox(height: 24),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _tags.map((t) => FilterChip(
          label: Text(t),
          selected: _interests.contains(t),
          onSelected: (v) => setState(() {
            if (v && _interests.length < 5) {
              _interests.add(t);
            } else {
              _interests.remove(t);
            }
          }),
          selectedColor: const Color(0xFF1D9E75).withValues(alpha: 0.15),
          checkmarkColor: const Color(0xFF1D9E75),
        )).toList(),
      ),
    ]),
  );

  Widget _mbtiStep() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      const Text('¿Cuál es tu MBTI?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(
        'Opcional — mejora el matching de personalidad',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: _saving ? null : _finish,
        child: const Text('Saltar este paso'),
      ),
      Expanded(
        child: GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: _mbtis.map((t) => GestureDetector(
            onTap: () => setState(() => _mbti = t),
            child: Container(
              decoration: BoxDecoration(
                color: _mbti == t ? const Color(0xFF1D9E75) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _mbti == t ? const Color(0xFF1D9E75) : Colors.grey[300]!,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                t,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _mbti == t ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          )).toList(),
        ),
      ),
    ]),
  );
}
