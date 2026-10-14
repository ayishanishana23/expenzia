import 'package:flutter/material.dart';

class OnboardScreen extends StatelessWidget {
  const OnboardScreen({super.key});

  static const _teal = Color(0xFF358F8B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                children: [
                  // Illustration area with a curved bottom edge.
                  ClipPath(
                    clipper: _HeaderClipper(),
                    child: Container(
                      height: constraints.maxHeight * 0.68,
                      width: double.infinity,
                      color: const Color(0xFFEDF8F7),
                      child: SafeArea(
                        bottom: false,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Positioned.fill(
                              child: CustomPaint(
                                painter: _RingsPainter(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Center(
                                    child: AspectRatio(
                                      aspectRatio: 0.75,
                                      child: LayoutBuilder(
                                        builder: (context, illustrationSize) {
                                          final width = illustrationSize.maxWidth;
                                          final height = illustrationSize.maxHeight;

                                          return Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Positioned.fill(
                                                child: Image.asset(
                                                  'assets/images/man.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),

                                              // Coin above the left hand.
                                              Positioned(
                                                left: width * 0.06,
                                                top: height * 0.12,
                                                width: width * 0.18,
                                                child: Image.asset(
                                                  'assets/images/coin.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),

                                              // Donut above the right hand.
                                              Positioned(
                                                right: width * 0.04,
                                                top: height * 0.20,
                                                width: width * 0.18,
                                                child: Image.asset(
                                                  'assets/images/donet.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            children: [
                              const Text(
                                'Spend Smarter\nSave More',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _teal,
                                  fontSize: 28,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _teal.withValues(alpha: 0.30),
                                      blurRadius: 14,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF66ADA7),
                                      Color(0xFF459590),
                                    ],
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushReplacementNamed('/home');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(54),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height - 20,
        size.width,
        size.height,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_HeaderClipper oldClipper) => false;
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    for (final scale in [0.30, 0.39, 0.48]) {
      canvas.drawCircle(center, size.width * scale, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) => false;
}