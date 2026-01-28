import 'package:flutter/material.dart';
import '../../services/notification_system_service.dart'; // Agregar
import '../client/chat_tab.dart';

/// Pantalla de espera mientras se inicializa el chat
class ChatInitializationScreen extends StatefulWidget {
  final String workId;
  final String sector;
  final String exactLocation;

  const ChatInitializationScreen({
    Key? key,
    required this.workId,
    required this.sector,
    required this.exactLocation,
  }) : super(key: key);

  @override
  State<ChatInitializationScreen> createState() =>
      _ChatInitializationScreenState();
}

class _ChatInitializationScreenState extends State<ChatInitializationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final _notificationService = NotificationSystemService(); // Agregar
  String _status = 'Inicializando chat...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _initializeChat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      setState(() => _status = 'Creando conversación...');
      
      // Esperar un poco para dar feedback visual
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _status = 'Conectando con el técnico...');
      
      // Esperar a que el chat esté listo
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _status = '✅ ¡Chat listo!');
      
      // Mostrar notificación
      _notificationService.showChatInitializedNotification(
        otherUserName: 'Técnico',
        workId: widget.workId,
      );
      
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Ir al chat
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatTab(
            workId: widget.workId,
            isClient: false,
            otherUserName: 'Cliente',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animación de carga
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Texto de estado
                Text(
                  _status,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Información de la ubicación
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Ubicación Confirmada',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📍 Sector: ${widget.sector}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '📌 Ubicación exacta: ${widget.exactLocation}',
                                style:
                                    const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Loading indicator
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Por favor, espera...',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
