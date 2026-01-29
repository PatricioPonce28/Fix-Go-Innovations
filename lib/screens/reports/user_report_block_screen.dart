import 'package:flutter/material.dart';
import '../../services/reports/user_report_block_service.dart';
import '../../models/reports/user_report_block_models.dart';
import '../../core/supabase_client.dart';

class ReportUserScreen extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;
  final String? workId;

  const ReportUserScreen({
    Key? key,
    required this.reportedUserId,
    required this.reportedUserName,
    this.workId,
  }) : super(key: key);

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  late UserReportService _reportService;
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reportService = UserReportService();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Por favor selecciona una razón y describe el problema'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = supabaseClient.auth.currentUser!.id;

      // Verificar si ya ha reportado a este usuario
      final hasReported = await _reportService.hasAlreadyReported(
        userId,
        widget.reportedUserId,
      );

      if (hasReported && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya has reportado a este usuario')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await _reportService.reportUser(
        reportedByUserId: userId,
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason!,
        description: _descriptionController.text,
        workId: widget.workId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Reporte enviado exitosamente!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getReasonDescription(ReportReason reason) {
    switch (reason) {
      case ReportReason.harassment:
        return 'Comportamiento hostil, intimidación o acoso';
      case ReportReason.fraud:
        return 'Sospecha de estafa o fraude';
      case ReportReason.inappropriateContent:
        return 'Contenido inapropiado o ofensivo';
      case ReportReason.unsafeService:
        return 'Servicio inseguro o riesgoso';
      case ReportReason.fraudulentPayment:
        return 'Problema de pago o transacción fraudulenta';
      case ReportReason.misrepresentation:
        return 'Información falsa o engañosa';
      case ReportReason.nonPayment:
        return 'No pagó por el servicio';
      case ReportReason.rude:
        return 'Comportamiento grosero o irrespetuoso';
      case ReportReason.other:
        return 'Otro problema no listado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Usuario'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.warning, size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    const Text(
                      'Reportar Usuario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reportando a: ${widget.reportedUserName}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Razón del reporte
            const Text(
              'Razón del Reporte',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...ReportReason.values.map((reason) {
              return Card(
                child: ListTile(
                  title: Text(
                      reason.name[0].toUpperCase() + reason.name.substring(1)),
                  subtitle: Text(_getReasonDescription(reason)),
                  leading: Radio<ReportReason>(
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() => _selectedReason = value);
                    },
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),

            // Descripción
            const Text(
              'Descripción Detallada',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText:
                    'Por favor proporciona detalles específicos sobre tu reporte...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 6,
              maxLength: 1000,
            ),
            const SizedBox(height: 24),

            // Advertencia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los reportes falsos pueden resultar en restricciones de cuenta',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón enviar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Enviar Reporte',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla para gestionar bloques
class BlockManagementScreen extends StatefulWidget {
  const BlockManagementScreen({Key? key}) : super(key: key);

  @override
  State<BlockManagementScreen> createState() => _BlockManagementScreenState();
}

class _BlockManagementScreenState extends State<BlockManagementScreen> {
  late UserBlockService _blockService;

  @override
  void initState() {
    super.initState();
    _blockService = UserBlockService();
  }

  Future<void> _unblockUser(UserBlockModel block) async {
    try {
      await _blockService.unblockUser(
        blockingUserId: block.blockingUserId,
        blockedUserId: block.blockedUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario desbloqueado')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabaseClient.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios Bloqueados'),
        elevation: 0,
      ),
      body: FutureBuilder<List<UserBlockModel>>(
        future: _blockService.getBlockedUsers(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final blocks = snapshot.data ?? [];

          if (blocks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay usuarios bloqueados'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: blocks.length,
            itemBuilder: (context, index) {
              final block = blocks[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: FutureBuilder(
                    future: supabaseClient
                        .from('user_profiles')
                        .select('full_name')
                        .eq('id', block.blockedUserId)
                        .single(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final data = snapshot.data;
                        return Text(data?['full_name'] ?? 'Usuario');
                      }
                      return const Text('Usuario');
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (block.reason != null) Text('Razón: ${block.reason}'),
                      Text(
                        'Bloqueado el ${block.createdAt.day}/${block.createdAt.month}/${block.createdAt.year}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Desbloquear Usuario'),
                          content: const Text(
                            '¿Estás seguro de que deseas desbloquear este usuario?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                _unblockUser(block);
                                Navigator.pop(context);
                              },
                              child: const Text('Desbloquear'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
