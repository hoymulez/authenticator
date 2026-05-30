import 'package:flutter/material.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/buttons.dart';
import '../widgets/gradient_scaffold.dart';

class _Slide {
  final String icon;
  final String title;
  final String body;
  const _Slide(this.icon, this.title, this.body);
}

const _slides = [
  _Slide('shield', 'Your keys, encrypted',
      'Every secret is sealed on-device with cipherlib before it ever touches storage or the cloud.'),
  _Slide('qr', 'Add in seconds',
      'Scan a QR code, paste a setup key, or batch-import everything from Google Authenticator.'),
  _Slide('cloudUp', 'Backup to your Drive',
      'Keep an encrypted copy in your own Google Drive — restore on any device, anytime.'),
];

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.themeOf(context);
    final s = _slides[_i];
    final last = _i == _slides.length - 1;

    return GradientScaffold(
      theme: theme,
      safeBottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.1), end: Offset.zero)
                            .animate(anim),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey(_i),
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: theme.accentGradient,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: theme.accent.withValues(alpha: 0.33),
                                blurRadius: 44,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: AppIcon(s.icon, size: 46, color: theme.onAccent),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: theme.ui(size: 27, weight: FontWeight.w700, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            s.body,
                            textAlign: TextAlign.center,
                            style: theme.ui(
                                size: 15.5, weight: FontWeight.w400, color: theme.muted, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (k) {
                final active = k == _i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? theme.accent : theme.borderHi,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 26),
            PrimaryButton(
              theme: theme,
              label: last ? 'Get started' : 'Continue',
              onPressed: () {
                if (last) {
                  widget.onDone();
                } else {
                  setState(() => _i++);
                }
              },
            ),
            SizedBox(
              height: 48,
              child: last
                  ? null
                  : Center(
                      child: GestureDetector(
                        onTap: widget.onDone,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text('Skip',
                              style: theme.ui(size: 14, weight: FontWeight.w600, color: theme.dim)),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
