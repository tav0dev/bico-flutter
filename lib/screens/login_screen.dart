import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';
import '../widgets/tuco_slot.dart';
import '../widgets/bicco_button.dart';
import '../widgets/bicco_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _showPassword = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              Center(child: TucoSlot(size: 84)),
              const SizedBox(height: 18),
              Text(
                'Bem-vindo ao Bicco',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: tokens.text,
                  letterSpacing: -0.03,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'O seu corre, mais inteligente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: tokens.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              // Tab switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: tokens.bgSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _Tab(
                      label: 'Entrar',
                      active: _isLogin,
                      tokens: tokens,
                      onTap: () => setState(() => _isLogin = true),
                    ),
                    _Tab(
                      label: 'Criar conta',
                      active: !_isLogin,
                      tokens: tokens,
                      onTap: () => setState(() => _isLogin = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Fields
              BicoField(
                label: 'E-mail',
                placeholder: 'seu@email.com',
                controller: _emailCtrl,
                leadingIcon: Icons.mail_outline,
              ),
              const SizedBox(height: 14),
              BicoField(
                label: 'Senha',
                placeholder: '••••••••',
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                leadingIcon: Icons.lock_outline,
                trailing: GestureDetector(
                  onTap: () => setState(() => _showPassword = !_showPassword),
                  child: Icon(
                    _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: tokens.textMuted,
                  ),
                ),
              ),
              if (_isLogin) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Esqueceu a senha?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: tokens.green,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              BicoButton(
                variant: BtnVariant.primary,
                size: BtnSize.lg,
                full: true,
                onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding'),
                child: Text(_isLogin ? 'Entrar' : 'Criar minha conta'),
              ),
              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: tokens.borderSoft, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'ou continue com',
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textFaint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: tokens.borderSoft, thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),

              // Social buttons
              Row(
                children: [
                  Expanded(
                    child: BicoButton(
                      variant: BtnVariant.secondary,
                      full: true,
                      onPressed: () async {
                        await context.read<BicoNotifier>().signInWithGoogle();
                        // O redirecionamento é tratado pelo listener de Auth no Provider
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleIcon(),
                          const SizedBox(width: 8),
                          const Text('Google'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BicoButton(
                      variant: BtnVariant.secondary,
                      full: true,
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AppleIcon(),
                          const SizedBox(width: 8),
                          const Text('Apple'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Terms
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.textFaint,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Ao continuar você concorda com os '),
                    TextSpan(
                      text: 'Termos',
                      style: TextStyle(color: tokens.text, fontWeight: FontWeight.w500),
                    ),
                    const TextSpan(text: ' e a '),
                    TextSpan(
                      text: 'Política de Privacidade',
                      style: TextStyle(color: tokens.text, fontWeight: FontWeight.w500),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final dynamic tokens;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.tokens, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          decoration: BoxDecoration(
            color: active ? tokens.bg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [BoxShadow(color: const Color(0x0F0F172A), blurRadius: 2, offset: const Offset(0, 1))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? tokens.text : tokens.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _ApplePainter()),
    );
  }
}

class _ApplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // ViewBox original do SVG: -52.01 0 560.035 560.035
    // Largura total: ~560, Altura total: ~560
    final double scale = size.width / 560.035;
    canvas.scale(scale);
    canvas.translate(52.01, 0); // Ajuste do offset X do viewBox

    final Path path = Path();
    // Corpo da maçã
    path.moveTo(380.844, 297.529);
    path.cubicTo(381.631, 382.281, 455.193, 410.484, 456.008, 410.843);
    path.cubicTo(455.386, 412.831, 444.254, 451.034, 417.252, 490.495);
    path.cubicTo(393.909, 524.612, 369.684, 558.602, 331.521, 559.306);
    path.cubicTo(294.022, 559.997, 281.964, 537.07, 239.092, 537.07);
    path.cubicTo(196.233, 537.07, 182.836, 558.603, 147.339, 559.998);
    path.cubicTo(110.502, 561.393, 82.45, 523.107, 58.915, 489.115);
    path.cubicTo(10.822, 419.585, -25.931, 292.64, 23.419, 206.95);
    path.cubicTo(47.935, 164.396, 91.747, 137.449, 139.301, 136.758);
    path.cubicTo(175.474, 136.068, 209.616, 161.094, 231.73, 161.094);
    path.cubicTo(253.83, 161.094, 295.32, 130.998, 338.938, 135.418);
    path.cubicTo(357.198, 136.178, 408.455, 142.794, 441.367, 190.97);
    path.cubicTo(438.715, 192.614, 380.208, 226.678, 380.844, 297.529);
    
    // Folha
    path.moveTo(310.369, 89.418);
    path.cubicTo(329.926, 65.745, 343.089, 32.79, 339.498, 0);
    path.cubicTo(311.308, 1.133, 277.22, 18.785, 257.0, 42.445);
    path.cubicTo(238.879, 63.397, 223.009, 96.932, 227.291, 130.07);
    path.cubicTo(258.712, 132.501, 290.811, 112.496, 310.369, 89.418);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    
    // ViewBox original do seu novo SVG: -3 0 262 262
    final double scale = size.width / 262;
    canvas.scale(scale);
    canvas.translate(3, 0);

    // Blue segment
    final Path bluePath = Path()
      ..moveTo(255.878, 133.451)
      ..cubicTo(255.878, 122.717, 255.007, 114.884, 253.122, 106.761)
      ..lineTo(130.55, 106.761)
      ..lineTo(130.55, 155.209)
      ..lineTo(202.497, 155.209)
      ..cubicTo(201.047, 167.249, 193.214, 185.381, 175.807, 197.565)
      ..lineTo(175.563, 199.187)
      ..lineTo(214.318, 229.21)
      ..lineTo(217.003, 229.478)
      ..cubicTo(241.662, 206.704, 255.878, 173.196, 255.878, 133.451)
      ..close();
    canvas.drawPath(bluePath, paint..color = const Color(0xFF4285F4));

    // Green segment
    final Path greenPath = Path()
      ..moveTo(130.55, 261.1)
      ..cubicTo(165.798, 261.1, 195.389, 249.495, 217.003, 229.478)
      ..lineTo(175.807, 197.565)
      ..cubicTo(164.783, 205.253, 149.987, 210.62, 130.55, 210.62)
      ..cubicTo(96.027, 210.62, 66.726, 187.847, 56.281, 156.371)
      ..lineTo(54.75, 156.501)
      ..lineTo(14.452, 187.688)
      ..lineTo(13.925, 189.153)
      ..cubicTo(35.393, 231.798, 79.49, 261.1, 130.55, 261.1)
      ..close();
    canvas.drawPath(greenPath, paint..color = const Color(0xFF34A853));

    // Yellow segment
    final Path yellowPath = Path()
      ..moveTo(56.281, 156.371)
      ..cubicTo(53.525, 148.248, 51.93, 139.544, 51.93, 130.551)
      ..cubicTo(51.93, 121.557, 53.525, 112.854, 56.136, 104.731)
      ..lineTo(56.063, 103.001)
      ..lineTo(15.26, 71.312)
      ..lineTo(13.925, 71.947)
      ..cubicTo(5.077, 89.644, 0, 109.517, 0, 130.551)
      ..cubicTo(0, 151.585, 5.077, 171.458, 13.925, 189.153)
      ..lineTo(56.281, 156.371)
      ..close();
    canvas.drawPath(yellowPath, paint..color = const Color(0xFFFBBC05));

    // Red segment
    final Path redPath = Path()
      ..moveTo(130.55, 50.479)
      ..cubicTo(155.064, 50.479, 171.6, 61.068, 181.029, 69.917)
      ..lineTo(217.873, 33.943)
      ..cubicTo(195.245, 12.91, 165.798, 0, 130.55, 0)
      ..cubicTo(79.49, 0, 35.393, 29.301, 13.925, 71.947)
      ..lineTo(56.136, 104.731)
      ..cubicTo(66.726, 73.254, 96.027, 50.479, 130.55, 50.479)
      ..close();
    canvas.drawPath(redPath, paint..color = const Color(0xFFEB4335));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
