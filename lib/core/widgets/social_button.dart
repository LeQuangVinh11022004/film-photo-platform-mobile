import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SocialButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final String tooltip;

  const SocialButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 58,
          height: 48,
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.inputFill : AppColors.socialBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Center(child: widget.icon),
          ),
        ),
      ),
    );
  }
}

class SocialLoginRow extends StatelessWidget {
  final VoidCallback onGoogleTap;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onAppleTap;

  const SocialLoginRow({
    super.key,
    required this.onGoogleTap,
    this.onFacebookTap,
    this.onAppleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Button
        SocialButton(
          tooltip: 'Google',
          onTap: onGoogleTap,
          icon: Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
            height: 22,
            width: 22,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
          ),
        ),
        const SizedBox(width: 16),

        // Facebook Button
        SocialButton(
          tooltip: 'Facebook',
          onTap: onFacebookTap ?? onGoogleTap,
          icon: const Icon(
            Icons.facebook,
            color: Color(0xFF1877F2),
            size: 26,
          ),
        ),
        const SizedBox(width: 16),

        // Apple Button
        SocialButton(
          tooltip: 'Apple',
          onTap: onAppleTap ?? onGoogleTap,
          icon: const Icon(
            Icons.apple,
            color: Colors.black,
            size: 26,
          ),
        ),
      ],
    );
  }
}
