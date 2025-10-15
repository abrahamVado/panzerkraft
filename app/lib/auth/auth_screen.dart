import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onSignedIn});

  final Future<void> Function(String email) onSignedIn;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    //1.- Dispose the controller to avoid leaking native resources.
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    //1.- Validate the email input before attempting to sign in.
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _errorMessage = null);
    try {
      //2.- Delegate the actual sign-in to the provided callback.
      await widget.onSignedIn(_emailController.text);
    } catch (error) {
      //3.- Surface any unexpected error back to the user.
      setState(() => _errorMessage = 'Sign-in failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    //1.- Listen to the controller to reflect loading state on the button.
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //2.- Welcome message grounded on the product voice.
                    Text(
                      'Welcome back to Panzerkraft',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Corporate email',
                        hintText: 'person@company.com',
                      ),
                      validator: (value) {
                        //3.- Enforce a simple sanity check so only email-like strings pass.
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Please enter an email.';
                        }
                        if (!text.contains('@') || !text.contains('.')) {
                          return 'Enter a valid email.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign in'),
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
