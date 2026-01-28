import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/work_and_chat_models.dart';
import '../../models/service_request_model.dart';
import '../../services/work_and_chat_service.dart';

class WorkProgressTab extends StatefulWidget {
  final AcceptedWork work;
  final ServiceRequest request;
  final bool isClient;
  final VoidCallback onStatusChanged;

  const WorkProgressTab({
    super.key,
    required this.work,
    required this.request,
    required this.isClient,
    required this.onStatusChanged,
  });

  @override
  State<WorkProgressTab> createState() => _WorkProgressTabState();
}

class _WorkProgressTabState extends State<WorkProgressTab> {
  final _workService = WorkService();
  bool _isUpdating = false;

  // Para calificación
  int _rating = 5;
  final _reviewController = TextEditingController();
  bool _isRating = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(WorkStatus newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar a ${newStatus.displayName}?'),
        content: Text(_getStatusConfirmationMessage(newStatus)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isUpdating = true);

    final success = await _workService.updateWorkStatus(
      widget.work.id,
      newStatus,
    );

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (!mounted) return;

    if (success) {
      widget.onStatusChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a ${newStatus.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar estado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusConfirmationMessage(WorkStatus status) {
    switch (status) {
      case WorkStatus.on_way:
        return '¿Estás en camino hacia la ubicación del cliente?';
      case WorkStatus.in_progress:
        return '¿Has comenzado a trabajar en la solicitud?';
      case WorkStatus.completed:
        return '¿Has terminado el trabajo satisfactoriamente?';
      default:
        return '¿Confirmas el cambio de estado?';
    }
  }

  Future<void> _submitRating() async {
    if (_rating < 1 || !mounted) return;

    setState(() => _isRating = true);

    final success = await _workService.rateWork(
      workId: widget.work.id,
      rating: _rating,
      review: _reviewController.text.trim().isNotEmpty
          ? _reviewController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isRating = false);

    if (!mounted) return;

    if (success) {
      widget.onStatusChanged();
      Navigator.pop(context); // Cerrar dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Gracias por tu calificación'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar calificación'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calificar Servicio'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Cómo fue tu experiencia?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        setState(() {
                          _rating = index + 1;
                        });
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Cuéntanos tu experiencia...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isRating ? null : _submitRating,
            child: _isRating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar Calificación'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline de estados
          const Text(
            '📊 Progreso del Trabajo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Estados del trabajo
          _StatusTimeline(
            currentStatus: widget.work.status,
            startedAt: widget.work.startedAt,
            completedAt: widget.work.completedAt,
            paidAt: widget.work.paidAt,
          ),

          const SizedBox(height: 24),

          // Información del trabajo
          const Text(
            '📋 Información del Trabajo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.request.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.request.sector,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Acciones según el rol y estado
          if (!widget.isClient &&
              widget.work.status == WorkStatus.paid) ...[
            // Técnico puede iniciar el camino
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(WorkStatus.on_way),
                icon: const Icon(Icons.directions_car),
                label: const Text(
                  'Iniciar Viaje al Cliente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],

          if (!widget.isClient &&
              widget.work.status == WorkStatus.on_way) ...[
            // Técnico puede iniciar el trabajo
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(WorkStatus.in_progress),
                icon: const Icon(Icons.construction),
                label: const Text(
                  'Iniciar Trabajo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],

          if (!widget.isClient &&
              widget.work.status == WorkStatus.in_progress) ...[
            // Técnico puede completar el trabajo
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(WorkStatus.completed),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'Marcar como Completado',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],

          if (widget.isClient && widget.work.status == WorkStatus.completed) ...[
            // Cliente puede calificar
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _showRatingDialog,
                icon: const Icon(Icons.star),
                label: const Text(
                  'Calificar Servicio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],

          // Mostrar calificación si ya existe
          if (widget.work.clientRating != null) ...[
            const SizedBox(height: 24),
            const Text(
              '⭐ Calificación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < widget.work.clientRating!
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.work.clientRating}/5',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (widget.work.clientReview != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.work.clientReview!,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ==================== TIMELINE DE ESTADOS ====================
class _StatusTimeline extends StatelessWidget {
  final WorkStatus currentStatus;
  final DateTime? paidAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const _StatusTimeline({
    required this.currentStatus,
    this.paidAt,
    this.startedAt,
    this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      (WorkStatus.paid, 'Pagado', paidAt),
      (WorkStatus.on_way, 'En Camino', null),
      (WorkStatus.in_progress, 'En Progreso', startedAt),
      (WorkStatus.completed, 'Completado', completedAt),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(statuses.length, (index) {
            final (status, label, timestamp) = statuses[index];
            final isActive = currentStatus.index >= status.index;
            final isCurrent = currentStatus == status;

            return Column(
              children: [
                Row(
                  children: [
                    // Círculo del estado
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent ? Colors.green : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        isActive ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Información del estado
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive ? Colors.black : Colors.grey,
                            ),
                          ),
                          if (timestamp != null)
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm', 'es_ES')
                                  .format(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Badge "Actual" si es el estado actual
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Actual',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                // Línea conectora
                if (index < statuses.length - 1)
                  Container(
                    margin: const EdgeInsets.only(left: 19),
                    width: 2,
                    height: 30,
                    color: isActive ? Colors.green : Colors.grey[300],
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
