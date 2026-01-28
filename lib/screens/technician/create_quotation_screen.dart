import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../models/service_request_model.dart';
import '../../services/quotation_service.dart';

class CreateQuotationScreen extends StatefulWidget {
  final ServiceRequest request;
  final UserModel technician;
  final VoidCallback onQuotationSent;

  const CreateQuotationScreen({
    super.key,
    required this.request,
    required this.technician,
    required this.onQuotationSent,
  });

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quotationService = QuotationService();

  // Controllers
  final _solutionTitleController = TextEditingController();
  final _workDescriptionController = TextEditingController();
  final _includedMaterialsController = TextEditingController();
  final _estimatedLaborController = TextEditingController();
  final _specialConditionsController = TextEditingController();
  final _materialsSubtotalController = TextEditingController();
  final _laborSubtotalController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  bool _isLoading = false;
  bool _includeIVA = true;
  int _validityDays = 7;

  double get _materialsSubtotal =>
      double.tryParse(_materialsSubtotalController.text) ?? 0;
  double get _laborSubtotal =>
      double.tryParse(_laborSubtotalController.text) ?? 0;
  double get _subtotal => _materialsSubtotal + _laborSubtotal;
  double get _taxAmount => _includeIVA ? _subtotal * 0.15 : 0; // IVA 15%
  double get _totalAmount => _subtotal + _taxAmount;

  @override
  void initState() {
    super.initState();
    _solutionTitleController.text = 'Solución a: ${widget.request.title}';

    // Listeners para recalcular totales
    _materialsSubtotalController.addListener(_updateTotals);
    _laborSubtotalController.addListener(_updateTotals);
  }

  void _updateTotals() {
    setState(() {});
  }

  @override
  void dispose() {
    _solutionTitleController.dispose();
    _workDescriptionController.dispose();
    _includedMaterialsController.dispose();
    _estimatedLaborController.dispose();
    _specialConditionsController.dispose();
    _materialsSubtotalController.dispose();
    _laborSubtotalController.dispose();
    _estimatedTimeController.dispose();
    _warrantyController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitQuotation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_totalAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El total debe ser mayor a 0'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _quotationService.createQuotation(
        requestId: widget.request.id,
        clientId: widget.request.clientId,
        technicianName: widget.technician.fullName,
        technicianRuc: widget.technician.cedula,
        solutionTitle: _solutionTitleController.text.trim(),
        workDescription: _workDescriptionController.text.trim(),
        includedMaterials: _includedMaterialsController.text.trim().isNotEmpty
            ? _includedMaterialsController.text.trim()
            : null,
        estimatedLabor: _estimatedLaborController.text.trim(),
        specialConditions: _specialConditionsController.text.trim().isNotEmpty
            ? _specialConditionsController.text.trim()
            : null,
        materialsSubtotal: _materialsSubtotal,
        laborSubtotal: _laborSubtotal,
        taxAmount: _taxAmount,
        totalAmount: _totalAmount,
        estimatedTime: _estimatedTimeController.text.trim(),
        warrantyOffered: _warrantyController.text.trim().isNotEmpty
            ? _warrantyController.text.trim()
            : null,
        validityDays: _validityDays,
        additionalNotes: _additionalNotesController.text.trim().isNotEmpty
            ? _additionalNotesController.text.trim()
            : null,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('✅ ¡Cotización Enviada!'),
            content: Text(
              'Tu cotización ${result['quotation_number']} ha sido enviada exitosamente.\n\n'
              'El cliente la revisará y podrá aceptarla.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context); // Cerrar pantalla de cotización
                  widget.onQuotationSent(); // Callback para refrescar
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
        title: const Text('Nueva Cotización'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del trabajo
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 Trabajo Solicitado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.request.title,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sector: ${widget.request.sector}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ENCABEZADO
              const Text(
                'Encabezado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: widget.technician.fullName,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Técnico',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: widget.technician.cedula ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'RUC / Cédula',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _solutionTitleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la Solución',
                  prefixIcon: Icon(Icons.title),
                  hintText: 'Ej: Solución a reparación de tubería',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // DETALLE DEL TRABAJO
              const Text(
                'Detalle del Trabajo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _workDescriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción del Servicio',
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Describe detalladamente el trabajo a realizar...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Describe el servicio';
                  }
                  if (value.length < 20) {
                    return 'Descripción muy corta (mínimo 20 caracteres)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _includedMaterialsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Materiales Incluidos (Opcional)',
                  prefixIcon: Icon(Icons.inventory),
                  hintText: 'Ej: Tubería PVC 1/2", codos, pegamento, etc.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _estimatedLaborController,
                decoration: const InputDecoration(
                  labelText: 'Mano de Obra Estimada',
                  prefixIcon: Icon(Icons.engineering),
                  hintText: 'Ej: 2 horas, Tarifa fija',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la mano de obra estimada';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _specialConditionsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Condiciones Especiales (Opcional)',
                  prefixIcon: Icon(Icons.info_outline),
                  hintText: 'Ej: Trabajo nocturno, urgencia, etc.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // COSTOS
              const Text(
                'Costos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _materialsSubtotalController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Subtotal Materiales',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.00',
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final num = double.tryParse(value);
                    if (num == null || num < 0) {
                      return 'Ingresa un valor válido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _laborSubtotalController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Subtotal Mano de Obra',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.00',
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el costo de mano de obra';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Ingresa un valor válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // IVA Toggle
              SwitchListTile(
                title: const Text('Incluir IVA (15%)'),
                subtitle: Text(_includeIVA ? 'Sí' : 'No'),
                value: _includeIVA,
                onChanged: (value) {
                  setState(() => _includeIVA = value);
                },
              ),
              const SizedBox(height: 12),

              // Resumen de costos
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _CostRow(
                        label: 'Subtotal',
                        value: _subtotal,
                      ),
                      if (_includeIVA) ...[
                        const Divider(),
                        _CostRow(
                          label: 'IVA (15%)',
                          value: _taxAmount,
                        ),
                      ],
                      const Divider(thickness: 2),
                      _CostRow(
                        label: 'TOTAL',
                        value: _totalAmount,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // NOTAS
              const Text(
                'Notas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _estimatedTimeController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo Estimado de Ejecución',
                  prefixIcon: Icon(Icons.timer),
                  hintText: 'Ej: 2-3 días, 1 semana',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el tiempo estimado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _warrantyController,
                decoration: const InputDecoration(
                  labelText: 'Garantía Ofrecida (Opcional)',
                  prefixIcon: Icon(Icons.verified_user),
                  hintText: 'Ej: 6 meses en mano de obra',
                ),
              ),
              const SizedBox(height: 12),

              // Vigencia de cotización
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vigencia de la Cotización',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _validityDays.toDouble(),
                              min: 3,
                              max: 30,
                              divisions: 27,
                              label: '$_validityDays días',
                              onChanged: (value) {
                                setState(() => _validityDays = value.toInt());
                              },
                            ),
                          ),
                          Text(
                            '$_validityDays días',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _additionalNotesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas Adicionales (Opcional)',
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Información adicional relevante...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Botón enviar
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitQuotation,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isLoading ? 'Enviando...' : 'Enviar Cotización',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== COST ROW ====================
class _CostRow extends StatelessWidget {
  final String label;
  final double value;
final bool isTotal;
const _CostRow({
required this.label,
required this.value,
this.isTotal = false,
});
@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 4),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
label,
style: TextStyle(
fontSize: isTotal ? 18 : 15,
fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
),
),
Text(
'\$${value.toStringAsFixed(2)}',
style: TextStyle(
fontSize: isTotal ? 20 : 16,
fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
color: isTotal ? Colors.blue[900] : null,
),
),
],
),
);
}
}