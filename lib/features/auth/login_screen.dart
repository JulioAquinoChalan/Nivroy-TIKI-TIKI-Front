import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

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
                        _isRegistering ? 'Crear cuenta' : 'Iniciar sesion',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Correo electronico',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Contrasena',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contrasena'
                                : 'Ocultar contrasena',
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
                        label: Text(_isRegistering ? 'Registrarme' : 'Entrar'),
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
                              ? 'Ya tengo cuenta'
                              : 'Crear una cuenta',
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

class _VerifyEmailView extends StatefulWidget {
  const _VerifyEmailView({required this.appState});

  final AppState appState;

  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          widget.appState.isBusy ||
          !widget.appState.isAuthenticated ||
          widget.appState.isEmailVerified) {
        return;
      }

      widget.appState.reloadAuthUser();
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;

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
                        'Verifica tu correo',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enviamos un enlace a ${appState.authEmail}. Verifica tu correo para cargar tus rules de Firestore.',
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: appState.isBusy
                            ? null
                            : appState.reloadAuthUser,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Ya verifique mi correo'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: appState.isBusy
                            ? null
                            : appState.sendEmailVerification,
                        icon: const Icon(Icons.mark_email_unread_outlined),
                        label: const Text('Reenviar verificacion'),
                      ),
                      TextButton.icon(
                        onPressed: appState.isBusy ? null : appState.logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesion'),
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
