import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cores.dart';

final supabase = Supabase.instance.client;

class TelaConfirmarPresenca extends StatefulWidget {
  const TelaConfirmarPresenca({super.key});

  @override
  State<TelaConfirmarPresenca> createState() => _TelaConfirmarPresencaState();
}

class _TelaConfirmarPresencaState extends State<TelaConfirmarPresenca> {
  // Dados do jogador (virá da URL ou do usuário logado)
  String jogadorNome = '';
  int? jogadorId;
  
  // Dados do jogo
  int? jogoId;
  String proximoJogoLocal = '';
  String proximoJogoData = '';
  int numeroJogo = 0;
  int confirmados = 0;
  
  // Estado
  bool presencaConfirmada = false;
  bool carregando = true;
  bool processando = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  void carregarDados() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      
      // Busca dados do usuário logado
      if (uid != null) {
        final userData = await supabase
            .from('users')
            .select('id, display_name')
            .eq('uid', uid)
            .single();
        
        jogadorNome = userData['display_name'] ?? 'Jogador';
        jogadorId = userData['id'];
      }

      // Busca o próximo jogo (data >= hoje)
      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      final jogoData = await supabase
          .from('jogos')
          .select()
          .gte('data', hoje)
          .order('data', ascending: true)
          .limit(1)
          .single();

      // Conta quantos confirmados
      final confirmadosData = await supabase
          .from('jogos_users')
          .select('id')
          .eq('id_jogo', jogoData['id'])
          .eq('confirmado', true);

      // Verifica se o jogador já confirmou
      if (jogadorId != null) {
        final minhaConfirmacao = await supabase
            .from('jogos_users')
            .select()
            .eq('id_jogo', jogoData['id'])
            .eq('id_jogador', jogadorId!)
            .maybeSingle();
        
        presencaConfirmada = minhaConfirmacao != null && minhaConfirmacao['confirmado'] == true;
      }

      setState(() {
        jogoId = jogoData['id'];
        proximoJogoLocal = jogoData['local'] ?? '';
        numeroJogo = jogoData['id'];
        
        // Formata a data
        if (jogoData['data'] != null) {
          final data = DateTime.parse(jogoData['data']);
          proximoJogoData = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
        }
        
        confirmados = confirmadosData.length;
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  void confirmarPresenca() async {
    if (jogoId == null || jogadorId == null) return;

    setState(() {
      processando = true;
    });

    try {
      // Verifica se já existe registro
      final existe = await supabase
          .from('jogos_users')
          .select()
          .eq('id_jogo', jogoId!)
          .eq('id_jogador', jogadorId!)
          .maybeSingle();

      if (existe != null) {
        // Atualiza
        await supabase
            .from('jogos_users')
            .update({'confirmado': true})
            .eq('id_jogo', jogoId!)
            .eq('id_jogador', jogadorId!);
      } else {
        // Insere novo
        await supabase.from('jogos_users').insert({
          'id_jogo': jogoId,
          'id_jogador': jogadorId,
          'confirmado': true,
        });
      }

      setState(() {
        presencaConfirmada = true;
        confirmados++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presença confirmada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao confirmar: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }

    setState(() {
      processando = false;
    });
  }

  void cancelarPresenca() async {
    if (jogoId == null || jogadorId == null) return;

    setState(() {
      processando = true;
    });

    try {
      await supabase
          .from('jogos_users')
          .update({'confirmado': false})
          .eq('id_jogo', jogoId!)
          .eq('id_jogador', jogadorId!);

      setState(() {
        presencaConfirmada = false;
        confirmados--;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presença cancelada'),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cancelar: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }

    setState(() {
      processando = false;
    });
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                    'Confirmar Presença',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    jogadorNome.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Card do Jogo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Jogo #$numeroJogo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Icon(Icons.location_on, color: AppColors.accent, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          proximoJogoLocal,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              proximoJogoData,
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Confirmados: $confirmados',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Status atual
                  if (presencaConfirmada)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success),
                          SizedBox(width: 8),
                          Text(
                            'Você está confirmado!',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Botão Confirmar ou Cancelar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: processando
                          ? null
                          : (presencaConfirmada ? cancelarPresenca : confirmarPresenca),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: presencaConfirmada ? AppColors.danger : AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 6,
                      ),
                      child: processando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              presencaConfirmada ? 'Não Vou!' : 'Confirmar Presença',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Link para o app
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: const Text(
                      'Ir para o App',
                      style: TextStyle(color: AppColors.accent, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}