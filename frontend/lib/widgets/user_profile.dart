import 'package:flutter/material.dart';
import '../globals.dart';
import '../services/local_storage_service.dart';
import '../services/google_signin_service.dart';
import '../screens/registration_screen.dart';
import '../main.dart';

class UserProfileWidget extends StatefulWidget {
  const UserProfileWidget({super.key});

  @override
  State<UserProfileWidget> createState() => _UserProfileWidgetState();
}

class _UserProfileWidgetState extends State<UserProfileWidget> {
  bool _isAuthenticated = false;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    final isAuthenticated = await LocalStorageService.isUserAuthenticated();
    if (isAuthenticated) {
      final userData = await LocalStorageService.getAllUserData();
      final storedName = userData['userName'];
      final storedEmail = userData['userEmail'];
      String? derivedName = storedName;
      if ((derivedName == null || derivedName.isEmpty) && storedEmail != null && storedEmail.isNotEmpty) {
        derivedName = storedEmail.contains('@') ? storedEmail.split('@').first : storedEmail;
      }
      setState(() {
        _isAuthenticated = isAuthenticated;
        _userName = derivedName;
        _userEmail = storedEmail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        popupMenuTheme: Theme.of(context).popupMenuTheme.copyWith(
          elevation: 10,
          shadowColor: Colors.black54,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Pallet.inside1,
        ),
      ),
      
      child: PopupMenuButton<String>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      color: Pallet.inside1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) async {
        if (value == 'logout') {
          // Sign out and clear persistence
          try {
            await GoogleSignInService().signOut();
          } catch (_) {}
          await LocalStorageService.clearUserData();
          if (mounted) {
            setState(() {
              _isAuthenticated = false;
              _userName = null;
              _userEmail = null;
            });
            // Navigate to home/root
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const Home(title: 'CrewBoard')),
              (route) => false,
            );
          }
        }

        if (value == 'signin' || value == 'signup') {
          if (!mounted) return;
          await showRegistrationDialog(context, onAuthenticated: () async {
            await _checkAuthenticationStatus();
          });
        }
      },
      itemBuilder: (context) {
        if (_isAuthenticated) {
          return <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_userName ?? 'User'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (_userEmail != null)
                    Text(
                      _userEmail!,
                      style: TextStyle(color: Pallet.font3),
                    ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Log Out'),
                ],
              ),
            ),
          ];
        }

        return <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'signin',
            child: Row(
              children: [
                Icon(Icons.login, size: 18),
                SizedBox(width: 8),
                Text('Sign In'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'signup',
            child: Row(
              children: [
                Icon(Icons.person_add_alt, size: 18),
                SizedBox(width: 8),
                Text('Sign Up'),
              ],
            ),
          ),
        ];
      },
      child: _buildAvatar(),
    ),
    );
  }

  Widget _buildAvatar() {
    if (_isAuthenticated) {
      return CircleAvatar(
        backgroundColor: Pallet.theme,
        child: Text(
          (_userName != null && _userName!.isNotEmpty)
              ? _userName!.substring(0, 1).toUpperCase()
              : 'U',
          style: TextStyle(
            color: Pallet.inside1,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      backgroundColor: Colors.lightBlue.withOpacity(0.2),
      child: Icon(Icons.person, color: Pallet.inside1),
    );
  }
}

