import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart';
import '../widgets/user_profile.dart';

class LandingPage extends StatefulWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onFlowEditorPressed;
  final bool isUserAuthenticated;

  const LandingPage({
    super.key,
    this.onLoginPressed,
    this.onFlowEditorPressed,
    required this.isUserAuthenticated,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with navigation
          _buildHeader(),
          // Main content
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/logo.png', width: 35, height: 35, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Text(
            'Node Path',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          Expanded(child: SizedBox()),
          // Navigation menu
          Row(
            children: [
              const SizedBox(width: 16),

              // Login button
              // if (!widget.isUserAuthenticated)
              //   TextButton(
              //     onPressed: widget.onLoginPressed,
              //     child: const Text('Login'),
              //   ),
              const SizedBox(width: 8),
              // Profile icon
              const UserProfileWidget(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Row(
        children: [
          // Left section - Text content
          Expanded(flex: 1, child: _buildLeftSection()),
          const SizedBox(width: 50),
          // Right section - Flowchart diagram
          Expanded(flex: 1, child: _buildRightSection()),
        ],
      ),
    );
  }

  Widget _buildLeftSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main heading
            Text(
              'FLOWCHART\nMAKER',
              style: GoogleFonts.lato(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 24),
            // Description
            Text(
              'Easily create flowcharts, mind maps and other diagrams.',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: const Color(0xFF7F8C8D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Create Flow Chart button
            ElevatedButton(
              onPressed: () {
                if (!widget.isUserAuthenticated) {
                  widget.onLoginPressed?.call();
                } else {
                  widget.onFlowEditorPressed?.call();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallet.theme,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Create Flow Chart'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightSection() {
    return Center(
      child: Container(
        width: 400,
        height: 400,
        child: Image.asset("assets/flowchart.png"),
      ),
    );
  }
}

// class FlowchartPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..style = PaintingStyle.fill
//       ..strokeWidth = 2;

//     final linePaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3
//       ..color = const Color(0xFF7F8C8D);

//     final arrowPaint = Paint()
//       ..style = PaintingStyle.fill
//       ..color = const Color(0xFF7F8C8D);

//     // Calculate positions
//     final centerX = size.width / 2;
//     final startY = 50.0;
//     final rectY = startY + 80.0;
//     final diamondY = rectY + 80.0;
//     final endY = diamondY + 120.0;

//     // Shape 1 - Top oval (yellow)
//     final oval1Rect = RRect.fromRectAndRadius(
//       Rect.fromCenter(
//         center: Offset(centerX, startY),
//         width: 120,
//         height: 50,
//       ),
//       const Radius.circular(25),
//     );
//     paint.color = const Color(0xFFFFD700);
//     canvas.drawRRect(oval1Rect, paint);

//     // Shape 2 - Rectangle (blue)
//     final rect1Rect = RRect.fromRectAndRadius(
//       Rect.fromCenter(
//         center: Offset(centerX, rectY),
//         width: 100,
//         height: 60,
//       ),
//       const Radius.circular(8),
//     );
//     paint.color = const Color(0xFF87CEEB);
//     canvas.drawRRect(rect1Rect, paint);

//     // Shape 3 - Diamond (green)
//     final diamondPath = Path();
//     diamondPath.moveTo(centerX, diamondY - 30);
//     diamondPath.lineTo(centerX + 40, diamondY);
//     diamondPath.lineTo(centerX, diamondY + 30);
//     diamondPath.lineTo(centerX - 40, diamondY);
//     diamondPath.close();
//     paint.color = const Color(0xFF90EE90);
//     canvas.drawPath(diamondPath, paint);

//     // Shape 4 - Bottom left oval (coral)
//     final oval2Rect = RRect.fromRectAndRadius(
//       Rect.fromCenter(
//         center: Offset(centerX - 80, endY),
//         width: 120,
//         height: 50,
//       ),
//       const Radius.circular(25),
//     );
//     paint.color = const Color(0xFFFF7F50);
//     canvas.drawRRect(oval2Rect, paint);

//     // Shape 5 - Bottom right rectangle (orange)
//     final rect2Rect = RRect.fromRectAndRadius(
//       Rect.fromCenter(
//         center: Offset(centerX + 80, endY),
//         width: 100,
//         height: 60,
//       ),
//       const Radius.circular(8),
//     );
//     paint.color = const Color(0xFFFFA500);
//     canvas.drawRRect(rect2Rect, paint);

//     // Draw connecting lines with arrows
//     // Top to rectangle
//     canvas.drawLine(
//       Offset(centerX, startY + 25),
//       Offset(centerX, rectY - 30),
//       linePaint,
//     );
//     _drawArrow(canvas, Offset(centerX, rectY - 30), arrowPaint);

//     // Rectangle to diamond
//     canvas.drawLine(
//       Offset(centerX, rectY + 30),
//       Offset(centerX, diamondY - 30),
//       linePaint,
//     );
//     _drawArrow(canvas, Offset(centerX, diamondY - 30), arrowPaint);

//     // Diamond to left oval
//     canvas.drawLine(
//       Offset(centerX - 40, diamondY),
//       Offset(centerX - 20, endY),
//       linePaint,
//     );
//     _drawArrow(canvas, Offset(centerX - 20, endY), arrowPaint);

//     // Diamond to right rectangle
//     canvas.drawLine(
//       Offset(centerX + 40, diamondY),
//       Offset(centerX + 20, endY),
//       linePaint,
//     );
//     _drawArrow(canvas, Offset(centerX + 20, endY), arrowPaint);

//     // Bottom line from right rectangle
//     canvas.drawLine(
//       Offset(centerX + 80, endY + 30),
//       Offset(centerX + 80, endY + 60),
//       linePaint,
//     );
//   }

//   void _drawArrow(Canvas canvas, Offset position, Paint paint) {
//     final path = Path();
//     path.moveTo(position.dx, position.dy);
//     path.lineTo(position.dx - 6, position.dy - 8);
//     path.lineTo(position.dx + 6, position.dy - 8);
//     path.close();
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
