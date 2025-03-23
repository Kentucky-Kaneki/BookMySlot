import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_my_slot/custom_widgets.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/customer_screens/cust_home_page.dart';
import 'package:book_my_slot/client_screens/client_home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.session != null) {
        // Save Token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.session!.accessToken);
        final userId = response.user!.id;
        final userProfile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();
        final bool isCustomer = userProfile['role'] == 'customer';
        await prefs.setBool('is_customer', isCustomer);

        // Navigate to Home Page
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => isCustomer
                  ? const CustomerHomePage()
                  : const ClientHomePage(),
            ),
            (route) => false,
          );
        }
      } else {
        CCustomSnackBar.show(
          context,
          'SignIn failed. Please check your credentials.',
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
          'Sign In',
          style: kAppBarTextStyle1,
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
              label: 'Enter email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            CCustomInputField(
              label: 'Password',
              controller: _passwordController,
              obscureText: true,
            ),
            Spacer(),
            // SignIn Button
            Center(
              child: _isLoading
                  ? CircularProgressIndicator()
                  : CCustomButton(
                      buttonColor: kMainColor,
                      textColor: Colors.white,
                      text: 'Sign In',
                      onPressed: _signIn,
                    ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
