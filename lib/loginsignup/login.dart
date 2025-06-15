import 'package:expense_tracker/loginsignup/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      // Show a popup dialog with an error message
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Login Failed', style: GoogleFonts.oswald()),
          content: Text(
            'Invalid credentials. Please try again.',
            style: GoogleFonts.oswald(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
              },
              child: Text('OK',
                  style: GoogleFonts.oswald(color: Colors.deepPurple)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 2, 27),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Add top space to shift the content down
              const SizedBox(height: 80), // Adjust the height here as needed

              // Image at the top
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 19.0),
                  child: Image.asset(
                    'assests/logo.png', // Replace with your image path
                    height: 150,
                    width: 150,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title and tagline
              Text(
                "Welcome To Budget Buddy",
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 202, 167, 232),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your Personal Finance Assistant",
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              // Login form
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: login,
                child: Text("Login",
                    style: GoogleFonts.oswald(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: const Color.fromARGB(255, 29, 1, 34),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SignupPage()),
                  );
                },
                child: Text(
                  "Don't have an account? Sign up",
                  style: GoogleFonts.oswald(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
