import 'dart:convert';

import 'package:flutter/material.dart';

import '../access_profile.dart';
import '../auth.dart';
import 'institutional_brand.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.api,
    required this.access,
    required this.onLogin,
  });
  final AuthApi api;
  final AccessProfile access;
  final ValueChanged<Session> onLogin;
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pending = widget.api.login(_username.text.trim(), _password.text);
      _password.clear();
      final session = await pending;
      if (!mounted) return;
      if (!session.roles.contains(widget.access.role)) {
        setState(
          () => _error =
              'Esta cuenta no corresponde al acceso ${widget.access.label}. '
              'Vuelve al inicio y elige el acceso correspondiente a tu rol.',
        );
        return;
      }
      widget.onLogin(session);
    } on LoginFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo iniciar sesión. Inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _username,
          enabled: !_loading,
          decoration: const InputDecoration(
            labelText: 'Usuario institucional',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          validator: (value) =>
              value == null || value.trim().isEmpty || value.trim().length > 60
              ? 'Introduce un usuario de 1 a 60 caracteres.'
              : null,
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _password,
          enabled: !_loading,
          obscureText: _hidden,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: _loading
                  ? null
                  : () => setState(() => _hidden = !_hidden),
              tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
              icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          validator: (value) =>
              value == null ||
                  value.trim().isEmpty ||
                  utf8.encode(value).length > 72
              ? 'Introduce una contraseña de hasta 72 bytes UTF-8.'
              : null,
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: institutionalWine,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login),
          label: Text(_loading ? 'Ingresando…' : 'Ingresar'),
        ),
      ],
    ),
  );
}
