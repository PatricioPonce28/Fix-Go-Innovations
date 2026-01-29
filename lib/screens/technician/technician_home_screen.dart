import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/work_and_chat_models.dart';
import '../../models/service_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/work_and_chat_service.dart';
import '../../services/service_request_service.dart';
import '../../services/ratings_service.dart';
import '../auth/login_screen.dart';
import '../client/work_coordination_screen.dart';
import 'available_requests_screen.dart';
import 'my_quotations_screen.dart';
import 'technician_profile_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  final UserModel user;

  const TechnicianHomeScreen({super.key, required this.user});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _HomeTab(user: widget.user),
      AvailableRequestsScreen(user: widget.user),
      MyQuotationsScreen(user: widget.user),
      TechnicianProfileScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Mis Cotizaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ==================== TAB DE INICIO ====================
class _HomeTab extends StatefulWidget {
  final UserModel user;

  const _HomeTab({required this.user});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _authService = AuthService();
  final _workService = WorkService();
  final _ratingsService = RatingsService();

  TechnicianStats? _stats;
  List<AcceptedWork> _activeWorks = [];
  Map<String, dynamic> _ratingStats = {
    'average_rating': 0.0,
    'total_ratings': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = await _workService.getTechnicianStats();
    final works = await _workService.getTechnicianActiveWorks();
    final ratingStats =
        await _ratingsService.getTechnicianRatingStats(widget.user.id);

    setState(() {
      _stats = stats;
      _activeWorks = works;
      _ratingStats = ratingStats;
      _isLoading = false;
    });
  }

  void _logout(BuildContext context) {
    _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _goToWork(AcceptedWork work) async {
    final serviceRequestService = ServiceRequestService();
    if (!mounted) return;

    try {
      var requestData = await serviceRequestService
          .getServiceRequestWithImages(work.requestId);

      if (!mounted) return;

      // Si no se encuentra, crear una solicitud de fallback
      final ServiceRequest request;
      if (requestData == null) {
        print(
            '[DEBUG] Creando solicitud de fallback para requestId: ${work.requestId}');
        request = ServiceRequest(
          id: work.requestId,
          clientId: work.clientId,
          title: 'Trabajo Coordinado',
          description: 'Detalles disponibles en chat y pago',
          serviceType: ServiceType.emergency,
          sector: '',
          exactLocation: '',
          status: RequestStatus.in_progress,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        request = requestData;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkCoordinationScreen(
            work: work,
            request: request,
            currentUser: widget.user,
            isClient: false,
          ),
        ),
      ).then((_) => _loadData());
    } catch (e) {
      print('❌ Error cargando solicitud: $e');
      if (!mounted) return;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Técnico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de perfil
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.orange,
                        backgroundImage: widget.user.profilePhotoUrl != null
                            ? NetworkImage(widget.user.profilePhotoUrl!)
                            : null,
                        child: widget.user.profilePhotoUrl == null
                            ? Text(
                                widget.user.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 24, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.build,
                                    size: 16, color: Colors.orange[700]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.user.specialty ?? 'Técnico',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.user.cedula != null)
                              Text(
                                'Cédula: ${widget.user.cedula}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Activo',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Estadísticas reales
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_stats != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.description,
                        title: 'Cotizaciones',
                        value: '${_stats!.totalQuotations}',
                        color: Colors.blue,
                        onTap: () {
                          final homeState = context.findAncestorStateOfType<
                              _TechnicianHomeScreenState>();
                          homeState?.setState(() {
                            homeState._currentIndex = 2;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle,
                        title: 'Aceptadas',
                        value: '${_stats!.acceptedQuotations}',
                        color: Colors.green,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.star,
                        title: 'Calificación',
                        value: _ratingStats['total_ratings'] > 0
                            ? _ratingStats['average_rating'].toStringAsFixed(1)
                            : '-',
                        subtitle: _ratingStats['total_ratings'] > 0
                            ? '${_ratingStats['total_ratings']} reseñas'
                            : 'Sin reseñas',
                        color: Colors.amber,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // ==================== TRABAJOS ACTIVOS (DESTACADO) ====================
              if (!_isLoading && _activeWorks.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚡ Trabajos en Progreso',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Requieren tu atención',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_activeWorks.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._activeWorks.take(2).map((work) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      work.status.icon,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          work.status.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Tu pago: \$${work.technicianAmount?.toStringAsFixed(2) ?? '0.00'}',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _goToWork(work),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward,
                                        color: Colors.blue[700],
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                      if (_activeWorks.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: Text(
                              '+${_activeWorks.length - 2} más',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Acciones rápidas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Acciones Rápidas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      final homeState = context.findAncestorStateOfType<
                          _TechnicianHomeScreenState>();
                      homeState?.setState(() {
                        homeState._currentIndex = 1;
                      });
                    },
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cards de acciones
              _ActionCard(
                icon: Icons.work_outline,
                title: 'Solicitudes Disponibles',
                subtitle: 'Encuentra nuevos trabajos',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AvailableRequestsScreen(user: widget.user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.description,
                title: 'Mis Cotizaciones',
                subtitle: 'Revisa tus cotizaciones enviadas',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyQuotationsScreen(user: widget.user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.history,
                title: 'Historial de Trabajos',
                subtitle: 'Trabajos completados',
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Próximamente')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== STAT CARD ====================
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ACTION CARD ====================
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
