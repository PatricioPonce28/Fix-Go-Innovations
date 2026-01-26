import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../models/image_data.dart';
import '../../models/service_request_model.dart';
import '../../services/service_request_service.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';

class CreateRequestScreen extends StatefulWidget {
  final UserModel user;
  final String? preselectedService;

  const CreateRequestScreen({
    super.key,
    required this.user,
    this.preselectedService,
  });

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _exactLocationController = TextEditingController();
  final _requestService = ServiceRequestService();
  final _storageService = StorageService();
  final _locationService = LocationService();
  final _mapController = MapController();

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  ServiceType _serviceType = ServiceType.new_installation;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<ImageData> _selectedImages = [];
  
  // Ubicación del mapa
  LatLng _currentLocation = LatLng(-0.1807, -78.4678); // Quito por defecto
  bool _hasSelectedLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedService != null) {
      _titleController.text = widget.preselectedService!;
    }
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _exactLocationController.dispose();
    super.dispose();
  }

  // Obtener ubicación actual
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    final location = await _locationService.getCurrentLocation();
    
    if (location != null) {
      setState(() {
        _currentLocation = location;
        _hasSelectedLocation = true;
        _isLoadingLocation = false;
      });
      
      // Centrar el mapa en la ubicación
      _mapController.move(_currentLocation, 15.0);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ubicación obtenida'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _isLoadingLocation = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No se pudo obtener la ubicación. Por favor, habilita el GPS.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Abrir en OpenStreetMap
  Future<void> _openInOpenStreetMap() async {
    final url = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${_currentLocation.latitude}'
      '&mlon=${_currentLocation.longitude}#map=17/${_currentLocation.latitude}/${_currentLocation.longitude}'
    );
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el mapa')),
      );
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 5 imágenes permitidas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () async {
                Navigator.pop(context);
                final imageData = await _storageService.takePhoto();
                if (imageData != null) {
                  setState(() => _selectedImages.add(imageData));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () async {
                Navigator.pop(context);
                final imageData = await _storageService.pickImageFromGallery();
                if (imageData != null) {
                  setState(() => _selectedImages.add(imageData));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, agrega al menos una foto del trabajo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_hasSelectedLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, obtén tu ubicación en el mapa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear dirección con coordenadas
      final locationString = 
          '${_exactLocationController.text.trim()} '
          '(Lat: ${_currentLocation.latitude.toStringAsFixed(6)}, '
          'Lng: ${_currentLocation.longitude.toStringAsFixed(6)})';

      final result = await _requestService.createRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        serviceType: _serviceType,
        sector: widget.user.sector ?? '',
        exactLocation: locationString,
        availabilityDate: _selectedDate,
        availabilityTime: _selectedTime != null
            ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : null,
        images: _selectedImages,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('✅ ¡Solicitud creada!'),
            content: const Text(
              'Tu solicitud ha sido creada exitosamente.\n\n'
              'Los técnicos disponibles podrán verla y contactarte pronto.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context); // Volver al home
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
        title: const Text('Nueva Solicitud'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título del trabajo
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título del Trabajo',
                    prefixIcon: Icon(Icons.work_outline),
                    hintText: 'Ej: Reparación de tubería rota',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa un título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del Problema',
                    prefixIcon: Icon(Icons.description_outlined),
                    hintText: 'Describe con detalle el problema o servicio necesario...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Describe el problema';
                    }
                    if (value.length < 10) {
                      return 'Descripción muy corta (mínimo 10 caracteres)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tipo de servicio
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo de Servicio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<ServiceType>(
                          title: const Text('🚨 Emergencia'),
                          subtitle: const Text('Requiere atención urgente'),
                          value: ServiceType.emergency,
                          groupValue: _serviceType,
                          onChanged: (value) {
                            setState(() => _serviceType = value!);
                          },
                        ),
                        RadioListTile<ServiceType>(
                          title: const Text('🔧 Instalación Nueva'),
                          subtitle: const Text('Trabajo planificado'),
                          value: ServiceType.new_installation,
                          groupValue: _serviceType,
                          onChanged: (value) {
                            setState(() => _serviceType = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sector (prellenado)
                TextFormField(
                  initialValue: widget.user.sector ?? '',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Sector',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 16),

                // MAPA INTERACTIVO
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '📍 Ubicación en el Mapa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_hasSelectedLocation)
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
                                  '✓ Ubicado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Mapa
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _isLoadingLocation
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('Obteniendo ubicación...'),
                                      ],
                                    ),
                                  )
                                : FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _currentLocation,
                                      initialZoom: 15.0,
                                      onTap: (tapPosition, point) {
                                        setState(() {
                                          _currentLocation = point;
                                          _hasSelectedLocation = true;
                                        });
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.conectatecnicos.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _currentLocation,
                                            width: 80,
                                            height: 80,
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Botones del mapa
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                                icon: const Icon(Icons.my_location, size: 18),
                                label: const Text('Mi Ubicación'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openInOpenStreetMap,
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('Abrir Mapa'),
                              ),
                            ),
                          ],
                        ),
                        
                        if (_hasSelectedLocation) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Lat: ${_currentLocation.latitude.toStringAsFixed(6)}, '
                            'Lng: ${_currentLocation.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ubicación exacta (referencia adicional)
                TextFormField(
                  controller: _exactLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Referencia de Dirección (Opcional)',
                    prefixIcon: Icon(Icons.home),
                    hintText: 'Ej: Casa blanca, portón negro',
                  ),
                ),
                const SizedBox(height: 16),

                // Disponibilidad
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Disponibilidad',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  _selectedDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                      : 'Seleccionar Fecha',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickTime,
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  _selectedTime != null
                                      ? _selectedTime!.format(context)
                                      : 'Seleccionar Hora',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Fotos del trabajo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Fotos del Trabajo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_selectedImages.length}/5',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Grid de imágenes
                        if (_selectedImages.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          _selectedImages[index].bytes,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        
                        const SizedBox(height: 12),
                        
                        // Botón agregar foto
                        OutlinedButton.icon(
                          onPressed: _selectedImages.length < 5 ? _pickImages : null,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Agregar Foto'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón enviar
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Crear Solicitud',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}