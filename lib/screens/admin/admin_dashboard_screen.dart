import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/admin/admin_models.dart';
import '../../models/service_request_model.dart';
import '../../models/quotation_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel user;

  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminService = AdminService();
  final _authService = AuthService();

  PlatformStats? _stats;
  List<ActivityLog> _recentActivity = [];
  List<TopTechnician> _topTechnicians = [];
  List<PaymentTransaction> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = await _adminService.getPlatformStats();
    final activity = await _adminService.getRecentActivity(limit: 20);
    final topTechs = await _adminService.getTopTechnicians(limit: 5);
    final transactions = await _adminService.getAllTransactions();

    setState(() {
      _stats = stats;
      _recentActivity = activity;
      _topTechnicians = topTechs;
      _recentTransactions = transactions.take(10).toList();
      _isLoading = false;
    });
  }

  void _logout() {
    _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.work), text: 'Solicitudes'),
            Tab(icon: Icon(Icons.description), text: 'Cotizaciones'),
            Tab(icon: Icon(Icons.payment), text: 'Pagos'),
            Tab(icon: Icon(Icons.history), text: 'Actividad'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTab(
            stats: _stats,
            topTechnicians: _topTechnicians,
            recentTransactions: _recentTransactions,
            isLoading: _isLoading,
            onRefresh: _loadData,
          ),
          _UsersTab(),
          _RequestsTab(),
          _QuotationsTab(),
          _PaymentsTab(),
          _ActivityTab(activity: _recentActivity, isLoading: _isLoading),
        ],
      ),
    );
  }
}

// ==================== TAB DE DASHBOARD ====================
class _DashboardTab extends StatelessWidget {
  final PlatformStats? stats;
  final List<TopTechnician> topTechnicians;
  final List<PaymentTransaction> recentTransactions;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _DashboardTab({
    required this.stats,
    required this.topTechnicians,
    required this.recentTransactions,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estadísticas principales
            const Text(
              '📊 Estadísticas Generales',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (stats != null) ...[
              // Usuarios
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people,
                      title: 'Usuarios Totales',
                      value: '${stats!.totalUsers}',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.person,
                      title: 'Clientes',
                      value: '${stats!.totalClients}',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.build,
                      title: 'Técnicos',
                      value: '${stats!.totalTechnicians}',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Trabajos
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.work,
                      title: 'Solicitudes',
                      value: '${stats!.totalRequests}',
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.description,
                      title: 'Cotizaciones',
                      value: '${stats!.totalQuotations}',
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle,
                      title: 'Completados',
                      value: '${stats!.totalCompletedWorks}',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ingresos
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ingresos Totales',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${stats!.totalRevenue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.attach_money,
                              size: 64, color: Colors.green[200]),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Comisión Plataforma (10%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '\$${stats!.platformEarnings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pagado a Técnicos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '\$${stats!.technicianEarnings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Top Técnicos
              const Text(
                '⭐ Top Técnicos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...topTechnicians.map((tech) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Text(
                          tech.technicianName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(tech.technicianName),
                      subtitle: Text(
                        '${tech.completedWorks} trabajos • ${tech.averageRating?.toStringAsFixed(1) ?? '-'} ⭐',
                      ),
                      trailing: Text(
                        '\$${tech.totalEarned.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 24),

              // Transacciones Recientes
              const Text(
                '💳 Últimas Transacciones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...recentTransactions.take(5).map((transaction) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        transaction.status == 'completed'
                            ? Icons.check_circle
                            : Icons.pending,
                        color: transaction.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(
                        '\$${transaction.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Comisión: \$${transaction.platformFee.toStringAsFixed(2)} • ${transaction.paymentMethod}',
                      ),
                      trailing: Text(
                        DateFormat('dd/MM/yyyy')
                            .format(transaction.transactionDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  )),
            ],
          ],
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
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ACTIVITY TAB ====================
class _ActivityTab extends StatelessWidget {
  final List<ActivityLog> activity;
  final bool isLoading;

  const _ActivityTab({
    required this.activity,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activity.length,
      itemBuilder: (context, index) {
        final log = activity[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text(
              log.actionIcon,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(log.description),
            subtitle: Text(
              '${log.userEmail ?? 'Sistema'} • ${DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        );
      },
    );
  }
}

// ==================== USERS TAB ====================
class _UsersTab extends StatefulWidget {
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _adminService = AdminService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _adminService.getAllUsers(roleFilter: _roleFilter);
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: _roleFilter == 'all',
                onSelected: (_) {
                  setState(() => _roleFilter = 'all');
                  _loadUsers();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Clientes'),
                selected: _roleFilter == 'client',
                onSelected: (_) {
                  setState(() => _roleFilter = 'client');
                  _loadUsers();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Técnicos'),
                selected: _roleFilter == 'technician',
                onSelected: (_) {
                  setState(() => _roleFilter = 'technician');
                  _loadUsers();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.role == 'client'
                              ? Colors.blue
                              : Colors.orange,
                          child: Icon(
                            user.role == 'client' ? Icons.person : Icons.build,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(user.fullName),
                        subtitle: Text(user.email),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(
                            user.role == 'client' ? 'Cliente' : 'Técnico',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: user.role == 'client'
                              ? Colors.blue[100]
                              : Colors.orange[100],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==================== REQUESTS TAB ====================
class _RequestsTab extends StatefulWidget {
  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final _adminService = AdminService();
  List<ServiceRequest> _requests = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final requests = await _adminService.getAllRequests(
      statusFilter: _statusFilter == 'all' ? null : _statusFilter,
    );
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _statusFilter == 'all',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'all');
                    _loadRequests();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Pendientes'),
                  selected: _statusFilter == 'pending',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'pending');
                    _loadRequests();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('En progreso'),
                  selected: _statusFilter == 'in_progress',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'in_progress');
                    _loadRequests();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Completadas'),
                  selected: _statusFilter == 'completed',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'completed');
                    _loadRequests();
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _requests.isEmpty
                  ? const Center(child: Text('No hay solicitudes'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading:
                                Icon(Icons.assignment, color: Colors.blue[700]),
                            title: Text(request.title),
                            subtitle: Text(request.description),
                            isThreeLine: true,
                            trailing: Chip(
                              label: Text(request.status.name),
                              backgroundColor: request.status.name == 'pending'
                                  ? Colors.orange[100]
                                  : request.status.name == 'in_progress'
                                      ? Colors.blue[100]
                                      : Colors.green[100],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ==================== QUOTATIONS TAB ====================
class _QuotationsTab extends StatefulWidget {
  @override
  State<_QuotationsTab> createState() => _QuotationsTabState();
}

class _QuotationsTabState extends State<_QuotationsTab> {
  final _adminService = AdminService();
  List<Quotation> _quotations = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    final quotations = await _adminService.getAllQuotations(
      statusFilter: _statusFilter == 'all' ? null : _statusFilter,
    );
    setState(() {
      _quotations = quotations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _statusFilter == 'all',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'all');
                    _loadQuotations();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Pendientes'),
                  selected: _statusFilter == 'pending',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'pending');
                    _loadQuotations();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Aceptadas'),
                  selected: _statusFilter == 'accepted',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'accepted');
                    _loadQuotations();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Rechazadas'),
                  selected: _statusFilter == 'rejected',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'rejected');
                    _loadQuotations();
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _quotations.isEmpty
                  ? const Center(child: Text('No hay cotizaciones'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _quotations.length,
                      itemBuilder: (context, index) {
                        final quotation = _quotations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(Icons.description,
                                color: Colors.purple[700]),
                            title: Text(
                              quotation.quotationNumber,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '\$${quotation.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            isThreeLine: true,
                            trailing: Chip(
                              label: Text(quotation.status.name),
                              backgroundColor:
                                  quotation.status.name == 'pending'
                                      ? Colors.orange[100]
                                      : quotation.status.name == 'accepted'
                                          ? Colors.green[100]
                                          : Colors.red[100],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ==================== PAYMENTS TAB ====================
class _PaymentsTab extends StatefulWidget {
  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  final _adminService = AdminService();
  List<PaymentTransaction> _transactions = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final transactions = await _adminService.getAllTransactions(
      statusFilter: _statusFilter == 'all' ? null : _statusFilter,
    );
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _statusFilter == 'all',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'all');
                    _loadTransactions();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Pendientes'),
                  selected: _statusFilter == 'pending',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'pending');
                    _loadTransactions();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Completadas'),
                  selected: _statusFilter == 'completed',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'completed');
                    _loadTransactions();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Fallidas'),
                  selected: _statusFilter == 'failed',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'failed');
                    _loadTransactions();
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                  ? const Center(child: Text('No hay transacciones'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              transaction.status == 'completed'
                                  ? Icons.check_circle
                                  : transaction.status == 'failed'
                                      ? Icons.cancel
                                      : Icons.pending,
                              color: transaction.status == 'completed'
                                  ? Colors.green
                                  : transaction.status == 'failed'
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                            title: Text(
                              '\$${transaction.totalAmount.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${transaction.paymentMethod} • Comisión: \$${transaction.platformFee.toStringAsFixed(2)}',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(transaction.transactionDate),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
