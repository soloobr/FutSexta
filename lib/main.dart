import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cores.dart';
import 'telas/login.dart';
import 'telas/home.dart';
import 'telas/confirmar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dtrmlcsymuexyjdbgeff.supabase.co',         // Troca pela sua URL do Supabase
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR0cm1sY3N5bXVleHlqZGJnZWZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgxNjM0NzgsImV4cCI6MjA0MzczOTQ3OH0.pN4YdELGAB4bPFHH4HeORYSmuyV0dDox-orzsykZTzE',   // Troca pela sua anon key
  );

 runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Verifica se já tem usuário logado
    final usuarioLogado = Supabase.instance.client.auth.currentUser != null;

    return MaterialApp(
      title: 'FutSexta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
      ),
      initialRoute: usuarioLogado ? '/home' : '/',
      routes: {
        '/': (context) => const TelaLogin(),
        '/home': (context) => const TelaPrincipal(),
        '/confirmar': (context) => const TelaConfirmarPresenca(),
      },
    );
  }
}