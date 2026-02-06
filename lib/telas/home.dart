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
  String usuarioModalidade = '';
  
  // Dados do próximo jogo
  int? jogoId;
  String proximoJogoLocal = '';
  String proximoJogoData = '';
  int numeroJogo = 0;
  int confirmadosJogo = 0;
  bool usuarioConfirmadoJogo = false;
  DateTime? proximoJogoDateTime;

  
  // Dados do próximo evento
  int? eventoId;
  String eventoDescricao = '';
  String eventoData = '';
  double eventoValor = 0;
  int confirmadosEvento = 0;
  bool usuarioConfirmadoEvento = false;
  bool temEvento = false;
  
  // Estado
  bool carregando = true;

  bool podeInscreverAvulso(DateTime dataHoraJogo) {
    final agora = DateTime.now();
    final limite = dataHoraJogo.subtract(const Duration(days: 1));
    return agora.isAfter(limite);
  }


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
          .select('id, display_name, modalidade')
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
          .maybeSingle();

      // 3. Busca o próximo evento (dataecent >= hoje)
      final eventoData = await supabase
          .from('eventos')
          .select()
          .gte('dataecent', hoje)
          .order('dataecent', ascending: true)
          .limit(1)
          .maybeSingle();

      // Variáveis temporárias
      int confJogo = 0;
      bool userConfJogo = false;
      int confEvento = 0;
      bool userConfEvento = false;


      // 4. Se tem jogo, busca confirmados
      if (jogoData != null) {
        final confirmadosJogoData = await supabase
            .from('jogos_users')
            .select('id')
            .eq('id_jogo', jogoData['id'])
            .eq('confirmado', true);

        usuarioModalidade = userData['modalidade'] ?? '';
        confJogo = confirmadosJogoData.length;

        // Verifica se o usuário já confirmou no jogo
        final minhaConfirmacaoJogo = await supabase
            .from('jogos_users')
            .select()
            .eq('id_jogo', jogoData['id'])
            .eq('id_jogador', userData['id'])
            .maybeSingle();

        userConfJogo = minhaConfirmacaoJogo != null && minhaConfirmacaoJogo['confirmado'] == true;
      }

      // 5. Se tem evento, busca confirmados
      if (eventoData != null) {
        final confirmadosEventoData = await supabase
            .from('eventos_users')
            .select('id')
            .eq('idevent', eventoData['id'])
            .eq('pago', true);

        confEvento = confirmadosEventoData.length;

        // Verifica se o usuário já confirmou no evento
        final minhaConfirmacaoEvento = await supabase
            .from('eventos_users')
            .select()
            .eq('idevent', eventoData['id'])
            .eq('idjogador', userData['id'])
            .maybeSingle();

        userConfEvento = minhaConfirmacaoEvento != null;
      }

      setState(() {
        // Usuário
        usuarioNome = userData['display_name'] ?? 'Usuário';
        usuarioId = userData['id'];
        usuarioModalidade = userData['modalidade'] ?? '';


        
        // Jogo
        if (jogoData != null) {
          jogoId = jogoData['id'];
          proximoJogoLocal = jogoData['local'] ?? '';
          numeroJogo = jogoData['id'];
          
          if (jogoData['data'] != null) {
            final data = DateTime.parse(jogoData['data']);
            // guarda para cálculos
            proximoJogoDateTime = data;
            proximoJogoData = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
          }
          
          confirmadosJogo = confJogo;
          usuarioConfirmadoJogo = userConfJogo;
        }
        
        // Evento
        if (eventoData != null) {
          temEvento = true;
          eventoId = eventoData['id'];
          eventoDescricao = eventoData['descricao'] ?? 'Evento';
          eventoValor = (eventoData['valor'] ?? 0).toDouble();
          
          if (eventoData['dataecent'] != null) {
            final data = DateTime.parse(eventoData['dataecent']);
            this.eventoData = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
          }
          
          confirmadosEvento = confEvento;
          usuarioConfirmadoEvento = userConfEvento;
        }
        
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  void toggleConfirmacaoJogo() async {
    if (jogoId == null || usuarioId == null) return;

    try {
      if (usuarioConfirmadoJogo) {
        await supabase
            .from('jogos_users')
            .update({'confirmado': false})
            .eq('id_jogo', jogoId!)
            .eq('id_jogador', usuarioId!);
        
        setState(() {
          usuarioConfirmadoJogo = false;
          confirmadosJogo--;
        });
      } else {
        final existe = await supabase
            .from('jogos_users')
            .select()
            .eq('id_jogo', jogoId!)
            .eq('id_jogador', usuarioId!)
            .maybeSingle();

        if (existe != null) {
          await supabase
              .from('jogos_users')
              .update({'confirmado': true})
              .eq('id_jogo', jogoId!)
              .eq('id_jogador', usuarioId!);
        } else {
          await supabase.from('jogos_users').insert({
            'id_jogo': jogoId,
            'id_jogador': usuarioId,
            'confirmado': true,
          });
        }
        
        setState(() {
          usuarioConfirmadoJogo = true;
          confirmadosJogo++;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void toggleConfirmacaoEvento() async {
    if (eventoId == null || usuarioId == null) return;

    try {
      if (usuarioConfirmadoEvento) {
        // Remove confirmação do evento
        await supabase
            .from('eventos_users')
            .delete()
            .eq('idevent', eventoId!)
            .eq('idjogador', usuarioId!);
        
        setState(() {
          usuarioConfirmadoEvento = false;
          confirmadosEvento--;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participação no evento cancelada'), backgroundColor: AppColors.danger),
        );
      } else {
        // Confirma no evento
        await supabase.from('eventos_users').insert({
          'idevent': eventoId,
          'idjogador': usuarioId,
          'pago': false,
          'valor': eventoValor,
        });
        
        setState(() {
          usuarioConfirmadoEvento = true;
          confirmadosEvento++;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participação no evento confirmada!'), backgroundColor: AppColors.success),
        );
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
                    IconButton(
                      onPressed: fazerLogout,
                      icon: const Icon(Icons.logout, color: AppColors.textMuted),
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

                      // ========== CARD DO JOGO ==========
                      const Text(
                       'Próximo Jogo: ' ,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),

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
                            const Icon(Icons.sports_soccer, size: 40, color: Colors.black54),
                            const SizedBox(width: 12),
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
                                    'Confirmados: $confirmadosJogo',
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
                      const SizedBox(height: 16),

                      // Botão Confirmar Jogo
                      /*SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: toggleConfirmacaoJogo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: usuarioConfirmadoJogo ? AppColors.danger : AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            usuarioConfirmadoJogo ? 'Não Vou!' : 'Confirmar Presença',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),*/
                  
                    if (usuarioModalidade == "Mensalista" ||
                        (usuarioModalidade == "Avulso" && proximoJogoDateTime != null && podeInscreverAvulso(proximoJogoDateTime!)))

                    SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                        onPressed: toggleConfirmacaoJogo,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: usuarioConfirmadoJogo ? AppColors.danger : AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 4,
                        ),
                        child: Text(
                            usuarioConfirmadoJogo ? 'Não Vou!' : 'Confirmar Presença',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        ),
                    )
                    else if (usuarioModalidade == "Avulso" && proximoJogoDateTime != null)
                      Builder(
                        builder: (context) {
                          print("APP_DEBUG usuarioModalidade: $usuarioModalidade");


                        final limite = proximoJogoDateTime!.subtract(const Duration(days: 1));
                        final aviso = "Avulso só pode colocar o nome na lista "
                            "${limite.day.toString().padLeft(2, '0')}/"
                            "${limite.month.toString().padLeft(2, '0')}/"
                            "${limite.year} às "
                            "${limite.hour.toString().padLeft(2, '0')}:"
                            "${limite.minute.toString().padLeft(2, '0')}";

                        return Text(
                            aviso,
                            style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                        );
                        },
                    ),
                      // ========== CARD DO EVENTO (se existir) ==========
                      if (temEvento) ...[
                        const SizedBox(height: 40),
                        const Text(
                          'Próximo Evento:',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),

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
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.celebration,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      eventoDescricao,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      eventoData,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'R\$ ${eventoValor.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Confirmados: $confirmadosEvento',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botão Confirmar Evento
                        SizedBox(
                          width: 220,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: toggleConfirmacaoEvento,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: usuarioConfirmadoEvento ? AppColors.danger : AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              usuarioConfirmadoEvento ? 'Cancelar Evento' : 'Participar do Evento',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
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