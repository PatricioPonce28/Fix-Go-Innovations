import 'package:flutter/material.dart';
import '../../models/work_and_chat_models.dart';
import '../../models/user_model.dart';
import '../../services/ratings_service.dart';

class ClientRatingsScreen extends StatefulWidget {
  final UserModel user;

  const ClientRatingsScreen({super.key, required this.user});

  @override
  State<ClientRatingsScreen> createState() => _ClientRatingsScreenState();
}

class _ClientRatingsScreenState extends State<ClientRatingsScreen> {
  final _ratingsService = RatingsService();
  List<AcceptedWork> _worksToRate = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorksToRate();
  }

  Future<void> _loadWorksToRate() async {
    setState(() => _isLoading = true);
    final works = await _ratingsService.getCompletedWorksToRate(widget.user.id);
    setState(() {
      _worksToRate = works;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Califica a los Técnicos'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _worksToRate.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          size: 80, color: Colors.green[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Todos los técnicos han sido calificados',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completa trabajos para poder calificar',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWorksToRate,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _worksToRate.length,
                    itemBuilder: (context, index) {
                      final work = _worksToRate[index];
                      return _RatingCard(
                        work: work,
                        onRated: () => _loadWorksToRate(),
                      );
                    },
                  ),
                ),
    );
  }
}

// ==================== TARJETA DE CALIFICACIÓN ====================
class _RatingCard extends StatefulWidget {
  final AcceptedWork work;
  final VoidCallback onRated;

  const _RatingCard({
    required this.work,
    required this.onRated,
  });

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  final _ratingsService = RatingsService();
  final _reviewController = TextEditingController();
  int _selectedRating = 0;
  bool _isLoading = false;
  String? _technicianName;
  String? _technicianPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadTechnicianInfo();
  }

  Future<void> _loadTechnicianInfo() async {
    final details =
        await _ratingsService.getWorkDetailsForRating(widget.work.id);
    if (details != null) {
      setState(() {
        _technicianName = details['technician']['full_name'];
        _technicianPhotoUrl = details['technician']['profile_photo_url'];
      });
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una calificación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _ratingsService.rateWork(
      workId: widget.work.id,
      rating: _selectedRating,
      review: _reviewController.text.isEmpty ? null : _reviewController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Calificación enviada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onRated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar la calificación'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con técnico
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange[100],
                  backgroundImage: _technicianPhotoUrl != null
                      ? NetworkImage(_technicianPhotoUrl!)
                      : null,
                  child: _technicianPhotoUrl == null
                      ? Icon(Icons.person, color: Colors.orange[700])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _technicianName ?? 'Técnico',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trabajo completado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (widget.work.completedAt != null)
                        Text(
                          'el ${widget.work.completedAt!.day}/${widget.work.completedAt!.month}/${widget.work.completedAt!.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selector de estrellas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu calificación',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      GestureDetector(
                        onTap: () => setState(() => _selectedRating = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            _selectedRating >= i
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_selectedRating > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _getRatingLabel(_selectedRating),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo de comentarios
            TextField(
              controller: _reviewController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Comparte tu experiencia (opcional)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // Botón enviar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Enviar Calificación',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Muy insatisfecho';
      case 2:
        return 'Insatisfecho';
      case 3:
        return 'Normal';
      case 4:
        return 'Muy satisfecho';
      case 5:
        return 'Excelente trabajo';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
