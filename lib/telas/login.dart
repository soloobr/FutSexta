import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cores.dart';

final supabase = Supabase.instance.client;

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  String mensagemErro = '';
  bool carregando = false;

  void fazerLogin() async {
    setState(() {
      carregando = true;
      mensagemErro = '';
    });

    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: senhaController.text,
      );

      if (response.user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      setState(() {
        mensagemErro = 'Email ou senha inválidos';
      });
    } catch (e) {
      setState(() {
        mensagemErro = 'Erro: $e';
      });
    }

    setState(() {
      carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF152238)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardBg,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    size: 60,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'FutSexta',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const Text(
                  'Amigos de Sexta',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 48),

                // Campo Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.email, color: AppColors.accent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.cardBg,
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Senha
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.lock, color: AppColors.accent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.cardBg,
                  ),
                ),
                const SizedBox(height: 24),

                // Mensagem de erro
                if (mensagemErro.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mensagemErro,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),

                // Botão Login
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: carregando ? null : fazerLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.accent.withOpacity(0.5),
                    ),
                    child: carregando
                        ? const CircularProgressIndicator(color: AppColors.textLight)
                        : const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}