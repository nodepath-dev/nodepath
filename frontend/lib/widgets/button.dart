import 'package:flutter/material.dart';

import '../globals.dart';

class Button extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isActive;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Widget? icon;
  final bool isOutlined;
  final BorderSide? borderSide;

  const Button({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isActive = true,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledColor,
    this.borderRadius,
    this.padding,
    this.elevation,
    this.icon,
    this.isOutlined = false,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderRadius = borderRadius ?? 8.0;
    final defaultPadding =
        padding ?? const EdgeInsets.symmetric(vertical: 16.0);
    final defaultElevation = elevation ?? (isActive ? 2.0 : 0.0);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: defaultPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultBorderRadius),
          ),
          side:
              borderSide ??
              BorderSide(
                color: isActive
                    ? (backgroundColor ?? theme.colorScheme.primary)
                    : Colors.grey.shade300,
              ),
        ),
        child: _buildButtonContent(),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? (backgroundColor ?? theme.colorScheme.primary)
            : (disabledColor ?? Colors.grey.shade200),
        foregroundColor: isActive
            ? (foregroundColor ?? Colors.white)
            : Colors.grey.shade600,
        padding: defaultPadding,
        elevation: defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor ?? Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 16,
              color: foregroundColor ?? Colors.white,
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: foregroundColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: foregroundColor,
      ),
    );
  }
}

class SignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isActive;
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isActive = true,
    this.text = 'Sign In',
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isActive: isActive,
      backgroundColor: backgroundColor ?? Colors.blue,
      foregroundColor: foregroundColor ?? Colors.white,
    );
  }
}

class SignUpButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isActive;
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SignUpButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isActive = true,
    this.text = 'Sign Up',
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isActive: isActive,
      backgroundColor: backgroundColor ?? Colors.green,
      foregroundColor: foregroundColor ?? Colors.white,
    );
  }
}

// class SocialButton extends StatelessWidget {
//   final String text;
//   final VoidCallback? onPressed;
//   final bool isLoading;
//   final Widget icon;
//   final Color? backgroundColor;
//   final Color? foregroundColor;
//   final Color? borderColor;

//   const SocialButton({
//     super.key,
//     required this.text,
//     this.onPressed,
//     this.isLoading = false,
//     required this.icon,
//     this.backgroundColor,
//     this.foregroundColor,
//     this.borderColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Button(
//       text: text,
//       onPressed: onPressed,
//       isLoading: isLoading,
//       icon: icon,
//       backgroundColor: backgroundColor ?? Colors.white,
//       foregroundColor: foregroundColor ?? Colors.black87,
//       borderSide: BorderSide(color: borderColor ?? Colors.grey.shade300),
//       isOutlined: true,
//       elevation: 2,
//     );
//   }
// }

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
     return Button(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon:  Padding(
        padding: const EdgeInsets.only(left: 6.0, right: 12.0),
        child: SizedBox(
          height: 20,
          width: 20,
          child: Image.asset(
            'assets/google_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.account_circle, size: 20),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }
}

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const AppleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Apple',
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      icon: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 12.0),
        child: SizedBox(
          height: 20,
          width: 20,
          child: Image.asset(
            'assets/apple_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.account_circle, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}


class SmallButton extends StatelessWidget {
  const SmallButton({super.key, required this.label, required this.onPress});
  final String label;
  final Function onPress;
  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.all(0),
        minimumSize: Size(30, 30),
      ),
      onPressed: () {
        onPress();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Pallet.inside1,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(color: Pallet.font3, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}