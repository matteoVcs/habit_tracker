import 'package:flutter/material.dart';
import 'habit_list_page.dart';
import 'db/supabase_helper.dart';
import 'style/theme_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtl = TextEditingController();
  final TextEditingController pwdCtl = TextEditingController();
  bool isLogin = true;
  String message = '';

  Future<void> _submit() async {
    final email = emailCtl.text.trim();
    final pwd = pwdCtl.text;

    if (email.isEmpty || pwd.isEmpty) {
      setState(() => message = 'Remplis tous les champs');
      return;
    }

    final ok = isLogin
        ? await SupabaseHelper.loginUser(email, pwd)
        : await SupabaseHelper.registerUser(email, pwd);

    if (ok) {
      if (!isLogin) {
        setState(() {
          message = 'Inscription réussie ! Connecte-toi.';
          isLogin = true;
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HabitListPage()),
        );
      }
    } else {
      setState(() {
        message = isLogin ? 'Identifiants invalides' : 'Erreur d’inscription';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Connexion' : 'Créer un compte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Changer le thème',
            onPressed: () => themeController.toggleTheme(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pwdCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(isLogin ? Icons.login : Icons.person_add),
                  label: Text(isLogin ? 'Se connecter' : 'Créer un compte'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      message = '';
                    });
                  },
                  child: Text(
                    isLogin
                        ? "Pas encore inscrit ? Créer un compte"
                        : "J’ai déjà un compte",
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
