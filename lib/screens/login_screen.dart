import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';
import 'package:aqua_app/screens/farmer_screen.dart';
import 'chatbot_screen.dart';
import '../widgets/glass_card.dart';
import '../widgets/swimming_fish_background.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});



  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isAuthority = true;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _deptIdController = TextEditingController();
  final _farmLocationController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _deptIdController.dispose();
    _farmLocationController.dispose();
    super.dispose();
  }

  
    void _submit() async {
      print('SUBMIT CLICKED, isLogin=$_isLogin');

      if (!_formKey.currentState!.validate()) return;

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        if (_isLogin) {
      //  LOGIN
          final user = await AuthService().login(email, password);

          if (user != null) {
            final name = _nameController.text.isNotEmpty
    ? _nameController.text
    : email.split('@')[0];

if (_isAuthority) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => DashboardScreen(userName: name),
    ),
  );
} else {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => FarmerScreen(farmerName: name),
    ),
  );
}


      }

      } else {

      // REGISTER
        final user = await AuthService().register(email, password);

        if (user != null) {

          ScaffoldMessenger.of(context).showSnackBar(

            const SnackBar(content: Text('Registration successful')),

          );

          setState(() {

            _isLogin = true; // go back to login
              
          });
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwimmingFishBackground(
        fishCount: 95,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                borderRadius: 24,
                blur: 16,
                backgroundColor: const Color(0x6F0F172A), // Premium translucent dark slate navy (frosted glass)
                borderColor: Colors.indigoAccent.withOpacity(0.25),
                borderWidth: 1.5,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isLogin ? 'Welcome Back' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Sign in to access GIS Smart Pisciculture' : 'Register to manage smart aqua assets',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // User Type Selector
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Authority'),
                            icon: Icon(Icons.admin_panel_settings),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Farmer'),
                            icon: Icon(Icons.set_meal),
                          ),
                        ],
                        selected: {_isAuthority},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _isAuthority = newSelection.first;
                          });
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.comfortable,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (!_isAuthority)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatbotScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.support_agent),
                          label: const Text('Open GIS Agent'),
                        ),

                      if (!_isAuthority) const SizedBox(height: 16),

                      // Form Fields
                      if (!_isLogin) 
                        CustomTextField(
                          label: 'Full Name',
                          prefixIcon: Icons.person,
                          controller: _nameController,
                          validator: (value) {
                             if (value == null || value.isEmpty) return 'Please enter your name';
                             return null;
                          },
                        ),

                      CustomTextField(
                        label: _isAuthority ? 'Official Email' : 'Phone Number/Email',
                        prefixIcon: _isAuthority ? Icons.email : Icons.contact_phone,
                        keyboardType: _isAuthority ? TextInputType.emailAddress : TextInputType.text,
                        controller: _emailController,
                         validator: (value) {
                             if (value == null || value.isEmpty) return 'Required field';
                             return null;
                          },
                      ),

                      if (!_isLogin && _isAuthority)
                        CustomTextField(
                          label: 'Department ID',
                          prefixIcon: Icons.badge,
                          controller: _deptIdController,
                           validator: (value) {
                             if (value == null || value.isEmpty) return 'Please enter Department ID';
                             return null;
                          },
                        ),

                      if (!_isLogin && !_isAuthority)
                        CustomTextField(
                          label: 'Farm Location / Address',
                          prefixIcon: Icons.location_on,
                          controller: _farmLocationController,
                           validator: (value) {
                             if (value == null || value.isEmpty) return 'Please enter farm location';
                             return null;
                          },
                        ),

                      CustomTextField(
                        label: 'Password',
                        prefixIcon: Icons.lock,
                        obscureText: true,
                        controller: _passwordController,
                         validator: (value) {
                             if (value == null || value.isEmpty) return 'Please enter password';
                             return null;
                          },
                      ),

                      if (!_isLogin)
                        CustomTextField(
                          label: 'Confirm Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _submit,
                        child: Text(_isLogin ? 'Login' : 'Register'),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          if (_isAuthority) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DashboardScreen(userName: 'Guest Authority')),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const FarmerScreen(farmerName: 'Guest Farmer')),
                            );
                          }
                        },
                        child: const Text(
                          'Continue as Guest',
                          style: TextStyle(color: Color(0xFF94A3B8), decoration: TextDecoration.underline),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? 'Don\'t have an account? Register'
                              : 'Already have an account? Login',
                          style: const TextStyle(color: Colors.indigoAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
