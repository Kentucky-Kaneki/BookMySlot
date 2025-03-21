import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_my_slot/custom_widgets.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/customer_screens/cust_home_page.dart';
import 'package:book_my_slot/client_screens/client_home_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isCustomer = true; // Default to customer

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });
    // passwords don't match
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      CCustomSnackBar.show(
        context,
        "Passwords do not match",
        Colors.orange,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // password length less than 6
    if (_passwordController.text.trim().length < 6) {
      CCustomSnackBar.show(
        context,
        "Password length must be at least 6 characters",
        Colors.orange,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          "name": _nameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "role": _isCustomer ? "customer" : "owner",
        },
      );

      if (response.user != null) {
        // Save Token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.session!.accessToken);

        // Navigate & Clear Stack
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => _isCustomer
                  ? const CustomerHomePage()
                  : const ClientHomePage(),
            ),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up failed. Try again.')),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sign Up',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Inputs
            CCustomInputField(
              label: 'Enter name',
              controller: _nameController,
            ),
            CCustomInputField(
              label: 'Phone no.',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            CCustomInputField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            CCustomInputField(
              label: 'Set password',
              controller: _passwordController,
              obscureText: true,
            ),
            CCustomInputField(
              label: 'Confirm password',
              controller: _confirmPasswordController,
              obscureText: true,
            ),
            SizedBox(height: 16),
            // Toggle Button
            Center(
              child: Column(
                children: [
                  Text(
                    'Select Account Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.grey[200],
                    ),
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(30),
                      shadowColor: Colors.black.withValues(
                        alpha: 0.3,
                      ),
                      child: ToggleButtons(
                        borderRadius: BorderRadius.circular(30),
                        selectedColor: Colors.white,
                        color: Colors.black,
                        fillColor: kButtonBackgroundColor,
                        isSelected: [_isCustomer, !_isCustomer],
                        onPressed: (index) {
                          setState(() {
                            _isCustomer = index == 0;
                          });
                        },
                        constraints: const BoxConstraints(
                          minHeight: 50,
                          minWidth: 150,
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            child: Text('Customer'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            child: Text('Owner'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            // Register Button
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : CCustomButton(
                      buttonColor: kButtonBackgroundColor,
                      textColor: kButtonForegroundColor,
                      text: 'Register',
                      onPressed: _signUp,
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
