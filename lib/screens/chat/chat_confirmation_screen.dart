import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../services/work_and_chat_service.dart';
import '../../services/notification_system_service.dart';
import '../client/chat_tab.dart';

/// 🎯 Pantalla de confirmación bilateral del chat
/// Ambas partes deben confirmar antes de que se inicialice el chat
class ChatConfirmationScreen extends StatefulWidget {
  final String workId;
  final String technicianName;
  final String clientName;
  final bool isClient;
  final String sector;
  final String exactLocation;

  const ChatConfirmationScreen({
    super.key,
    required this.workId,
    required this.technicianName,
    required this.clientName,
    required this.isClient,
    required this.sector,
    required this.exactLocation,
  });

  @override
  State<ChatConfirmationScreen> createState() => _ChatConfirmationScreenState();
}

class _ChatConfirmationScreenState extends State<ChatConfirmationScreen>
    with TickerProviderStateMixin {
  final _workService = WorkService();
  late AnimationController _animationController;
  late AnimationController _pulseController;

  bool _clientConfirmed = false;
  bool _technicianConfirmed = false;
  bool _isLoading = false;
  bool _hasConfirmed = false;
  String _statusMessage = 'Esperando confirmación...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _loadConfirmationStatus();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Cargar estado actual de confirmaciones
  Future<void> _loadConfirmationStatus() async {
    try {
      // Obtener el work usando workId directamente
      final details = await _workService.getWorkDetails(widget.workId);
      if (details.isNotEmpty) {
        setState(() {
          _clientConfirmed = details['client_confirmed_chat'] ?? false;
          _technicianConfirmed = details['technician_confirmed_chat'] ?? false;
        });
        _checkBothConfirmed();
      }
    } catch (e) {
      print('❌ Error cargando estado: $e');
    }
  }

  /// Configurar listener en tiempo real
  void _setupRealtimeListener() {
    final subscription = _workService.streamWorkConfirmations(widget.workId);
    subscription.listen((confirmations) {
      if (!mounted) return;
      setState(() {
        _clientConfirmed = confirmations['client_confirmed'] ?? false;
        _technicianConfirmed = confirmations['technician_confirmed'] ?? false;
      });
      _checkBothConfirmed();
    });
  }

  /// Verificar si ambas partes confirmaron
  void _checkBothConfirmed() {
    if (_clientConfirmed && _technicianConfirmed && !_hasConfirmed) {
      setState(() => _statusMessage = '✅ ¡Ambas partes confirmaron!');
      _proceedToChat();
    }
  }

  /// Usuario confirma que está listo para el chat
  Future<void> _confirmReady() async {
    if (_hasConfirmed) return;

    setState(() => _isLoading = true);

    try {
      // Vibración de confirmación
      await Vibration.vibrate(duration: 100);

      // Confirmar en la base de datos
      final success = await _workService.confirmChatReady(
        widget.workId,
        isClient: widget.isClient,
      );

      if (!success) throw Exception('No se pudo confirmar');

      setState(() {
        _hasConfirmed = true;
        if (widget.isClient) {
          _clientConfirmed = true;
        } else {
          _technicianConfirmed = true;
        }
        _statusMessage = '✅ Tu confirmación fue enviada';
      });

      // Si la otra parte ya confirmó, ir al chat
      if ((widget.isClient && _technicianConfirmed) ||
          (!widget.isClient && _clientConfirmed)) {
        await Future.delayed(const Duration(milliseconds: 500));
        _proceedToChat();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Ir a pantalla de chat
  Future<void> _proceedToChat() async {
    if (!mounted) return;

    // Vibración de éxito
    await Vibration.vibrate(
      pattern: [100, 100, 100],
      intensities: [200, 100, 200],
    );

    // Mostrar notificación
    final notificationService = NotificationSystemService();
    await notificationService.showChatInitializedNotification(
      otherUserName:
          widget.isClient ? widget.technicianName : widget.clientName,
      workId: widget.workId,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatTab(
          workId: widget.workId,
          otherUserName:
              widget.isClient ? widget.technicianName : widget.clientName,
          isClient: widget.isClient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Confirmación de Chat'),
          elevation: 0,
          backgroundColor: Colors.blue[600],
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),

                // 🎯 ANIMATED ICON
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                        parent: _animationController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue[100],
                    ),
                    child: Icon(
                      Icons.chat_bubble,
                      color: Colors.blue[600],
                      size: 50,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 📝 TÍTULO PRINCIPAL
                Text(
                  'Esperando Chat con ${widget.isClient ? widget.technicianName : widget.clientName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),

                // 📋 DESCRIPCIÓN
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles de la Coordinación',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('📍 Ubicación', widget.exactLocation),
                      const SizedBox(height: 8),
                      _buildDetailRow('🏢 Sector', widget.sector),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ✅ ESTADO DE CONFIRMACIONES
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado de Confirmaciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cliente
                      _buildConfirmationStatus(
                        name: widget.clientName,
                        role: 'Cliente',
                        confirmed: _clientConfirmed,
                        isCurrentUser: widget.isClient,
                      ),

                      const SizedBox(height: 12),

                      // Técnico
                      _buildConfirmationStatus(
                        name: widget.technicianName,
                        role: 'Técnico',
                        confirmed: _technicianConfirmed,
                        isCurrentUser: !widget.isClient,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 📱 BOTÓN DE CONFIRMACIÓN
                if (!_hasConfirmed)
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                          parent: _pulseController, curve: Curves.easeInOut),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _confirmReady,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle, size: 24),
                        label: Text(
                          _isLoading
                              ? 'Confirmando...'
                              : '✅ Listo para Iniciar Chat',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Información
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ambas partes deben confirmar para iniciar el chat. Una vez confirmado, podrán coordinar los detalles del trabajo.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStatus({
    required String name,
    required String role,
    required bool confirmed,
    required bool isCurrentUser,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confirmed ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: confirmed ? Colors.green : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            confirmed ? Icons.check_circle : Icons.pending,
            color: confirmed ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  role + (isCurrentUser ? ' (Tú)' : ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (confirmed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '✓ Listo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
