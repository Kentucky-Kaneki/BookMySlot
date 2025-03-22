import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:book_my_slot/custom_widgets.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/login_screens/signin_page.dart';

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

    // Phone no. validity
    if (_phoneController.text.trim().length != 10 ||
        !_phoneController.text.trim().contains(RegExp(r'^[0-9]+$'))) {
      CCustomSnackBar.show(
        context,
        "Invalid Phone number",
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
        final userId = response.user!.id;

        // Insert into profiles table
        await supabase.from('profiles').insert({
          "id": userId,
          "name": _nameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "role": _isCustomer ? "customer" : "owner",
        });

        // Successful login
        if (mounted) {
          print('mounted');
          CCustomSnackBar.show(
            context,
            "Email has been sent. Verify to register successfully",
            Colors.green,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignInPage()),
          );
        }
      } else {
        CCustomSnackBar.show(
          context,
          'Sign-up failed. Try again.',
          Colors.red,
        );
      }
    } on AuthException catch (e) {
      CCustomSnackBar.show(
        context,
        e.message,
        Colors.red,
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          // Dismiss keyboard on tap
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User Inputs
                    CCustomInputField(
                        label: 'Enter name', controller: _nameController),
                    CCustomInputField(
                        label: 'Phone no.',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone),
                    CCustomInputField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress),
                    CCustomInputField(
                        label: 'Set password',
                        controller: _passwordController,
                        obscureText: true),
                    CCustomInputField(
                        label: 'Confirm password',
                        controller: _confirmPasswordController,
                        obscureText: true),
                    const SizedBox(height: 16),

                    // Toggle Button
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Select Account Type',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.grey[200],
                            ),
                            child: ToggleButtons(
                              borderRadius: BorderRadius.circular(30),
                              selectedColor: Colors.white,
                              color: Colors.black,
                              fillColor: kMainColor,
                              isSelected: [_isCustomer, !_isCustomer],
                              onPressed: (index) {
                                setState(() {
                                  _isCustomer = index == 0;
                                });
                              },
                              constraints: const BoxConstraints(
                                  minHeight: 50, minWidth: 150),
                              children: const [
                                Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 8),
                                    child: Text('Customer')),
                                Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 8),
                                    child: Text('Owner')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Push the button to the bottom
                    const SizedBox(
                      height: 160,
                    ),
                    // Register Button
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.grey)
                            : CCustomButton(
                                buttonColor: kMainColor,
                                textColor: Colors.white,
                                text: 'Register',
                                onPressed: _signUp,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
