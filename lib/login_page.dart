import 'package:flutter/material.dart';
import 'db/database_helper.dart';
import 'habit_list_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _message = '';
  bool _isLogin = true;

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _message = '';
    });
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Veuillez remplir tous les champs';
      });
      return;
    }

    if (_isLogin) {
      final user = await dbHelper.loginUser(email, password);
      if (user != null) {
        // ✅ Redirection vers la page principale
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HabitListPage()),
        );
      } else {
        setState(() {
          _message = 'Identifiants invalides';
        });
      }
    } else {
      final exists = await dbHelper.getUserByEmail(email);
      if (exists != null) {
        setState(() {
          _message = 'Un compte existe déjà avec cet e-mail';
        });
        return;
      }

      final id = await dbHelper.registerUser(email, password);
      if (id != null) {
        setState(() {
          _message = 'Compte créé ! Connectez-vous.';
          _isLogin = true;
        });
      } else {
        setState(() {
          _message = 'Erreur lors de l\'inscription';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Connexion' : 'Créer un compte')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Se connecter' : 'Créer un compte'),
            ),
            TextButton(
              onPressed: _toggleMode,
              child: Text(_isLogin
                  ? 'Pas encore inscrit ? Créer un compte'
                  : 'Déjà inscrit ? Se connecter'),
            ),
            const SizedBox(height: 10),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: const TextStyle(color: Colors.red),
              )
          ],
        ),
      ),
    );
  }
}
