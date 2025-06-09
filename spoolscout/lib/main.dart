import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // initialize Firebase
  runApp(SpoolScoutApp());
}

class SpoolScoutApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spool Scout',
      theme: ThemeData(
        primaryColor: const Color.fromRGBO(
            4, 107, 123, 1), // Replace with your primary color
        fontFamily: 'ChickenWonder',
      ),
      home: SplashScreen(), // start with the SplashScreen
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAuthCheck();
  }

  void _navigateToAuthCheck() async {
    await Future.delayed(const Duration(seconds: 3)); // wait for 3 seconds
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => AuthCheck()), // now, navigate to AuthCheck
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/wallpaper.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 150,
                  width: 150,
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(
                  color: const Color.fromRGBO(4, 107, 123, 1),
                ),
                SizedBox(height: 20),
                Text(
                  'Loading Spool Scout...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'ChickenWonder',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          // user is authenticated; navigate to HomeScreen
          return HomeScreen();
        } else {
          // user is not authenticated; show LoginScreen
          return LoginScreen();
        }
      },
    );
  }
}
