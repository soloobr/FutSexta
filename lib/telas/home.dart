import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cores.dart';

final supabase = Supabase.instance.client;

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  // Dados do usuário
  String usuarioNome = '';
  int? usuarioId;
  
  // Dados do próximo jogo
  int? jogoId;
  String proximoJogoLocal = '';
  String proximoJogoData = '';
  String proximoJogoHorario = '';
  int numeroJogo = 0;
  int confirmados = 0;
  
  // Estado
  bool usuarioConfirmado = false;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  void carregarDados() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      
      if (uid == null) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      // 1. Busca dados do usuário pelo uid
      final userData = await supabase
          .from('users')
          .select('id, display_name')
          .eq('uid', uid)
          .single();

      // 2. Busca o próximo jogo (data >= hoje)
      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      final jogoData = await supabase
          .from('jogos')
          .select()
          .gte('data', hoje)
          .order('data', ascending: true)
          .limit(1)
          .single();

      // 3. Conta quantos confirmados no jogo
      final confirmadosData = await supabase
          .from('jogos_users')
          .select('id')
          .eq('id_jogo', jogoData['id'])
          .eq('confirmado', true);

      // 4. Verifica se o usuário já confirmou
      final minhaConfirmacao = await supabase
          .from('jogos_users')
          .select()
          .eq('id_jogo', jogoData['id'])
          .eq('id_jogador', userData['id'])
          .maybeSingle();

      setState(() {
        // Usuário
        usuarioNome = userData['display_name'] ?? 'Usuário';
        usuarioId = userData['id'];
        
        // Jogo
        jogoId = jogoData['id'];
        proximoJogoLocal = jogoData['local'] ?? '';
        proximoJogoHorario = jogoData['horariojogo'] ?? '';
        numeroJogo = jogoData['id'];
        
        // Formata a data
        if (jogoData['data'] != null) {
          final data = DateTime.parse(jogoData['data']);
          proximoJogoData = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
        }
        
        // Confirmados
        confirmados = confirmadosData.length;
        
        // Minha confirmação
        usuarioConfirmado = minhaConfirmacao != null && minhaConfirmacao['confirmado'] == true;
        
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  void toggleConfirmacao() async {
    if (jogoId == null || usuarioId == null) return;

    try {
      if (usuarioConfirmado) {
        // Desconfirmar
        await supabase
            .from('jogos_users')
            .update({'confirmado': false})
            .eq('id_jogo', jogoId!)
            .eq('id_jogador', usuarioId!);
        
        setState(() {
          usuarioConfirmado = false;
          confirmados--;
        });
      } else {
        // Confirmar - verifica se já existe registro
        final existe = await supabase
            .from('jogos_users')
            .select()
            .eq('id_jogo', jogoId!)
            .eq('id_jogador', usuarioId!)
            .maybeSingle();

        if (existe != null) {
          // Atualiza
          await supabase
              .from('jogos_users')
              .update({'confirmado': true})
              .eq('id_jogo', jogoId!)
              .eq('id_jogador', usuarioId!);
        } else {
          // Insere novo
          await supabase.from('jogos_users').insert({
            'id_jogo': jogoId,
            'id_jogador': usuarioId,
            'confirmado': true,
          });
        }
        
        setState(() {
          usuarioConfirmado = true;
          confirmados++;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void fazerLogout() async {
    await supabase.auth.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.background, Color(0xFF152238)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF152238)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('Ir para o APP', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    TextButton(
                      onPressed: fazerLogout,
                      child: const Text('LogOff', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.sports_soccer,
                          size: 80,
                          color: AppColors.textLight,
                        ),
                      ),

                      // Bem Vindo
                      const Text(
                        'Bem Vindo!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        usuarioNome.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Próximo Jogo
                      const Text(
                        'Proximo Jogo:',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Card do Jogo
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Número do jogo
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$numeroJogo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Ícone bola
                            const Icon(Icons.sports_soccer, size: 40, color: Colors.black54),
                            const SizedBox(width: 12),

                            // Info do jogo
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    proximoJogoLocal,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    proximoJogoData,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Confirmados: $confirmados',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Botão Confirmar/Não Vou
                      SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: toggleConfirmacao,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: usuarioConfirmado ? AppColors.danger : AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            usuarioConfirmado ? 'Não Vou!' : 'Confirmar Presença',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}