import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;

    if (appState.isAuthenticated && !appState.isEmailVerified) {
      return _VerifyEmailView(appState: appState);
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isRegistering
                            ? l10n.t('auth.createAccount')
                            : l10n.t('auth.signIn'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l10n.t('auth.email'),
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: l10n.t('auth.password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? l10n.t('auth.showPassword')
                                : l10n.t('auth.hidePassword'),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: appState.isBusy ? null : _submit,
                        icon: Icon(
                          _isRegistering ? Icons.person_add_alt : Icons.login,
                        ),
                        label: Text(
                          _isRegistering
                              ? l10n.t('auth.register')
                              : l10n.t('auth.enter'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: appState.isBusy
                            ? null
                            : () => setState(
                                () => _isRegistering = !_isRegistering,
                              ),
                        child: Text(
                          _isRegistering
                              ? l10n.t('auth.haveAccount')
                              : l10n.t('auth.createAccountAction'),
                        ),
                      ),
                      if (appState.lastError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          appState.lastError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
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

  void _submit() {
    final appState = context.read<AppState>();
    if (_isRegistering) {
      appState.register(
        email: _emailController.text,
        password: _passwordController.text,
      );
      return;
    }

    appState.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }
}

class _VerifyEmailView extends StatelessWidget {
  const _VerifyEmailView({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.t('auth.verifyEmailTitle'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.t('auth.verifyEmailMessage', {
                          'email': appState.authEmail,
                        }),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: appState.isBusy
                            ? null
                            : appState.reloadAuthUser,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.t('auth.alreadyVerified')),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: appState.isBusy
                            ? null
                            : appState.sendEmailVerification,
                        icon: const Icon(Icons.mark_email_unread_outlined),
                        label: Text(l10n.t('auth.resendVerification')),
                      ),
                      TextButton.icon(
                        onPressed: appState.isBusy ? null : appState.logout,
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.t('common.logout')),
                      ),
                      if (appState.lastError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          appState.lastError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
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
