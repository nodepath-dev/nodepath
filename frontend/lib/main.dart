import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/landing_page.dart';
import 'screens/registration_screen.dart';
import 'screens/flows/main.dart' as flow_editor;
import 'services/local_storage_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/globals.dart';
import 'backend/server.dart';
import 'services/arri_client.rpc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NodePath',
      theme: ThemeData(
        textTheme: GoogleFonts.latoTextTheme(
          TextTheme(
            displayLarge: TextStyle(color: const Color(0xFF2C3E50)),
            displayMedium: TextStyle(color: const Color(0xFF2C3E50)),
            bodyMedium: TextStyle(color: const Color(0xFF7F8C8D)),
            titleMedium: TextStyle(color: const Color(0xFF2C3E50)),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const Home(title: 'NodePath'),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isUserAuthenticated = false;
  String? _userId;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
    _handleUrlParams();
  }

  Future<void> _checkAuthenticationStatus() async {
    final isAuthenticated = await LocalStorageService.isUserAuthenticated();
    if (isAuthenticated) {
      final userData = await LocalStorageService.getAllUserData();
      setState(() {
        _isUserAuthenticated = isAuthenticated;
        _userId = userData['userId'];
        _userName = userData['userName'];
        _userEmail = userData['userEmail'];
      });
    }
  }

  Future<void> _handleUrlParams() async {
    // Get the current route
    final uri = Uri.base;
    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      // Call verify email API
      try {
        final response = await server.auth.verifyemail(VerifyEmailParams(token: token));
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Window.width = MediaQuery.of(context).size.width;
    Window.height = MediaQuery.of(context).size.height;
    
    // If user is authenticated, navigate directly to FlowEditor
    if (_isUserAuthenticated) {
      return const flow_editor.FlowEditor();
    }
    
    // If user is not authenticated, show LandingPage
    return LandingPage(
      isUserAuthenticated: _isUserAuthenticated,
      onLoginPressed: () => _showAuthenticationDialog(context),
      onFlowEditorPressed: () => _navigateToFlowEditor(context),
    );
  }

  void _navigateToFlowEditor(BuildContext context) {
    // Navigate to FlowEditor and replace the current route
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const flow_editor.FlowEditor(),
      ),
    );
  }

  void _showAuthenticationDialog(BuildContext context) {
    showRegistrationDialog(context, onAuthenticated: () async {
      await _checkAuthenticationStatus();
    });
  }
}
