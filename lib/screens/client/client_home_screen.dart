import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/work_and_chat_models.dart';
import '../../models/service_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/work_and_chat_service.dart';
import '../../services/service_request_service.dart';
import '../auth/login_screen.dart';
import 'create_request_screen.dart';
import 'request_history_screen.dart';
import 'client_profile_screen.dart';
import 'ratings_screen.dart';
import 'work_coordination_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  final UserModel user;

  const ClientHomeScreen({super.key, required this.user});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _HomeTab(user: widget.user),
      RequestHistoryScreen(user: widget.user),
      ClientRatingsScreen(user: widget.user),
      ClientProfileScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Calificar',
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
  final _requestService = ServiceRequestService();

  List<AcceptedWork> _activeWorks = [];
  List<ServiceRequest> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final works = await _workService.getClientActiveWorks();
    final requests = await _requestService.getClientRequests();

    setState(() {
      _activeWorks = works;
      _pendingRequests = requests
          .where((r) =>
              r.status == RequestStatus.pending && (r.quotationsCount ?? 0) > 0)
          .toList();
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
    // Necesitamos cargar la solicitud
    final requests = await _requestService.getClientRequests();
    final request = requests.firstWhere(
      (r) => r.id == work.requestId,
      orElse: () => ServiceRequest(
        id: work.requestId,
        clientId: work.clientId,
        title: 'Trabajo en progreso',
        description: '',
        serviceType: ServiceType.emergency,
        sector: '',
        exactLocation: '',
        status: RequestStatus.in_progress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkCoordinationScreen(
          work: work,
          request: request,
          currentUser: widget.user,
          isClient: true,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio - Cliente'),
        actions: [
          // Badge con trabajos activos
          if (_activeWorks.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.work),
                  onPressed: () {
                    if (_activeWorks.isNotEmpty) {
                      _goToWork(_activeWorks.first);
                    }
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_activeWorks.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue,
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
                              '¡Hola, ${widget.user.fullName}!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                // Navegar al perfil
                                final parent = context.findAncestorStateOfType<
                                    _ClientHomeScreenState>();
                                parent
                                    ?.setState(() => parent._currentIndex = 2);
                              },
                              child: Text(
                                '📍 ${widget.user.sector ?? 'Sin ubicación'} → Ver perfil',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
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
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // ==================== TRABAJOS ACTIVOS (DESTACADO) ====================
                if (_activeWorks.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[400]!, Colors.orange[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
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
                                  '⚡ Trabajos en Curso',
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
                                  color: Colors.orange,
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
                                        color: Colors.orange[100],
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
                                            '\$${work.paymentAmount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.orange[700],
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
                                          color: Colors.orange[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward,
                                          color: Colors.orange[700],
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

                // ==================== SOLICITUDES CON COTIZACIONES ====================
                if (_pendingRequests.isNotEmpty) ...[
                  const Text(
                    '📋 Cotizaciones Recibidas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tienes ${_pendingRequests.length} solicitud${_pendingRequests.length > 1 ? 'es' : ''} con cotizaciones por revisar',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  ..._pendingRequests.take(2).map((request) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.description,
                                color: Colors.blue[700]),
                          ),
                          title: Text(request.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${request.quotationsCount} cotización${(request.quotationsCount ?? 0) > 1 ? 'es' : ''} recibida${(request.quotationsCount ?? 0) > 1 ? 's' : ''}'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            final homeState = context.findAncestorStateOfType<
                                _ClientHomeScreenState>();
                            homeState
                                ?.setState(() => homeState._currentIndex = 1);
                          },
                        ),
                      )),
                  const SizedBox(height: 24),
                ],
              ],
              const Text(
                'Servicios Disponibles',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _ServiceCard(
                      icon: Icons.plumbing,
                      title: 'Plomería',
                      color: Colors.blue,
                      user: widget.user),
                  _ServiceCard(
                      icon: Icons.electrical_services,
                      title: 'Electricidad',
                      color: Colors.amber,
                      user: widget.user),
                  _ServiceCard(
                      icon: Icons.lock,
                      title: 'Cerrajería',
                      color: Colors.orange,
                      user: widget.user),
                  _ServiceCard(
                      icon: Icons.construction,
                      title: 'Albañilería',
                      color: Colors.brown,
                      user: widget.user),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateRequestScreen(user: widget.user),
            ),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Solicitud'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final UserModel user;

  const _ServiceCard(
      {required this.icon,
      required this.title,
      required this.color,
      required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateRequestScreen(user: user, preselectedService: title),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
