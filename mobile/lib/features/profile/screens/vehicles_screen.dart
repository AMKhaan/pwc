import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await DioClient.instance.get(ApiConstants.myVehicles);
      setState(() {
        _vehicles = (res.data as List).cast<Map<String, dynamic>>();
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(String vehicleId) async {
    await DioClient.instance
        .delete('${ApiConstants.myVehicles}/$vehicleId');
    _load();
  }

  void _showAddSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AddVehiclePage(onSaved: _load),
      ),
    );
  }

  void _showEditSheet(Map<String, dynamic> vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AddVehiclePage(onSaved: _load, existing: vehicle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddSheet),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_car_outlined,
                          size: 56, color: AppTheme.textHint),
                      const SizedBox(height: 16),
                      const Text('No vehicles added',
                          style: TextStyle(
                              fontSize: 16, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      const Text('Add a vehicle to post rides',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textHint)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Vehicle'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(160, 44)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _VehicleCard(
                    vehicle: _vehicles[i],
                    onEdit: () => _showEditSheet(_vehicles[i]),
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Remove Vehicle'),
                          content: const Text(
                              'Are you sure you want to remove this vehicle?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Remove',
                                    style: TextStyle(color: AppTheme.error))),
                          ],
                        ),
                      );
                      if (confirm == true) _delete(_vehicles[i]['id'] as String);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({required this.vehicle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car,
                  color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle['make']} ${vehicle['model']} (${vehicle['year']})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle['color']} · ${vehicle['licensePlate']}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vehicle['totalSeats']} seats · ${vehicle['fuelType']}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.primary, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.error, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class AddVehicleSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Map<String, dynamic>? existing;
  const AddVehicleSheet({super.key, required this.onSaved, this.existing});

  @override
  State<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<AddVehicleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _seatsCtrl;
  late final TextEditingController _ccCtrl;
  late final TextEditingController _ownerCtrl;
  late final TextEditingController _chassisCtrl;
  late String _fuelType;
  late String _vehicleType;
  bool _isLoading = false;
  String? _error;

  bool get _isEditing => widget.existing != null;
  bool get _isBike => _vehicleType == 'BIKE';

  final _fuelTypes = ['PETROL', 'CNG', 'DIESEL', 'ELECTRIC', 'HYBRID'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _vehicleType = e?['vehicleType'] as String? ?? 'CAR';
    _makeCtrl = TextEditingController(text: e?['make'] as String? ?? '');
    _modelCtrl = TextEditingController(text: e?['model'] as String? ?? '');
    _yearCtrl = TextEditingController(text: e?['year']?.toString() ?? '');
    _colorCtrl = TextEditingController(text: e?['color'] as String? ?? '');
    _plateCtrl = TextEditingController(text: e?['licensePlate'] as String? ?? '');
    _seatsCtrl = TextEditingController(text: e?['totalSeats']?.toString() ?? '3');
    _ccCtrl = TextEditingController(text: e?['engineCC']?.toString() ?? '');
    _ownerCtrl = TextEditingController(text: e?['ownerName'] as String? ?? '');
    _chassisCtrl = TextEditingController(text: e?['chassisNumber'] as String? ?? '');
    _fuelType = e?['fuelType'] as String? ?? 'PETROL';
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    _seatsCtrl.dispose();
    _ccCtrl.dispose();
    _ownerCtrl.dispose();
    _chassisCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    final data = {
      'vehicleType': _vehicleType,
      'make': _makeCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      'year': int.parse(_yearCtrl.text.trim()),
      'color': _colorCtrl.text.trim(),
      'licensePlate': _plateCtrl.text.trim(),
      'totalSeats': int.parse(_seatsCtrl.text.trim()),
      'fuelType': _fuelType,
      'ownerName': _ownerCtrl.text.trim(),
      'chassisNumber': _chassisCtrl.text.trim(),
      if (!_isBike && _ccCtrl.text.isNotEmpty)
        'engineCC': int.parse(_ccCtrl.text.trim()),
    };
    try {
      if (_isEditing) {
        await DioClient.instance.patch(
            '${ApiConstants.myVehicles}/${widget.existing!['id']}', data: data);
      } else {
        await DioClient.instance.post(ApiConstants.myVehicles, data: data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = extractApiError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _KeyboardPadding(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Text(_isEditing ? 'Edit Vehicle' : 'Add Vehicle',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 12),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],

              // Vehicle Type
              const Text('Vehicle Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(children: [
                _TypeToggle(
                  label: 'Car',
                  icon: Icons.directions_car,
                  selected: _vehicleType == 'CAR',
                  onTap: () => setState(() => _vehicleType = 'CAR'),
                ),
                const SizedBox(width: 10),
                _TypeToggle(
                  label: 'Bike',
                  icon: Icons.two_wheeler,
                  selected: _vehicleType == 'BIKE',
                  onTap: () => setState(() => _vehicleType = 'BIKE'),
                ),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: CustomTextField(
                    label: 'Make', hint: 'Toyota', controller: _makeCtrl,
                    validator: (v) => v!.isEmpty ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(child: CustomTextField(
                    label: 'Model', hint: 'Corolla', controller: _modelCtrl,
                    validator: (v) => v!.isEmpty ? 'Required' : null)),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: CustomTextField(
                    label: 'Year', hint: '2020', controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final y = int.tryParse(v ?? '');
                      if (y == null || y < 2000 || y > 2030) return '2000–2030';
                      return null;
                    })),
                const SizedBox(width: 12),
                Expanded(child: CustomTextField(
                    label: 'Color', hint: 'White', controller: _colorCtrl,
                    validator: (v) => v!.isEmpty ? 'Required' : null)),
              ]),
              const SizedBox(height: 12),

              CustomTextField(
                  label: 'License Plate', hint: 'LHR-123-AB',
                  controller: _plateCtrl,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: CustomTextField(
                    label: 'Seats (excl. driver)', hint: '3',
                    controller: _seatsCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 10) return '1–10';
                      return null;
                    })),
                if (!_isBike) ...[
                  const SizedBox(width: 12),
                  Expanded(child: CustomTextField(
                      label: 'Engine CC', hint: '1000',
                      controller: _ccCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (_isBike) return null;
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 50 || n > 5000) return '50–5000';
                        return null;
                      })),
                ],
              ]),
              const SizedBox(height: 12),

              // Fuel type (show only if not bike — bikes use petrol only)
              if (!_isBike) ...[
                const Text('Fuel Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _fuelTypes.map((f) => ChoiceChip(
                    label: Text(f),
                    selected: _fuelType == f,
                    onSelected: (_) => setState(() => _fuelType = f),
                    selectedColor: AppTheme.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                        color: _fuelType == f ? AppTheme.primary : AppTheme.textSecondary,
                        fontWeight: _fuelType == f ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Engine CC info label for bike
              if (_isBike) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, size: 14, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Expanded(child: Text('Bikes avg. 40 km/liter — auto calculated',
                        style: TextStyle(fontSize: 12, color: AppTheme.primary))),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              CustomTextField(
                  label: 'Owner Name (as per documents)',
                  hint: 'Muhammad Ali',
                  controller: _ownerCtrl,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),

              CustomTextField(
                  label: 'Chassis Number',
                  hint: 'ABC123456789',
                  controller: _chassisCtrl,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 20),

              PrimaryButton(
                  label: _isEditing ? 'Update Vehicle' : 'Save Vehicle',
                  isLoading: _isLoading,
                  onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeToggle({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecondary, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? AppTheme.primary : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// Full-screen page wrapper — Scaffold.resizeToAvoidBottomInset handles keyboard
class _AddVehiclePage extends StatelessWidget {
  final VoidCallback onSaved;
  final Map<String, dynamic>? existing;
  const _AddVehiclePage({required this.onSaved, this.existing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AddVehicleSheet(onSaved: onSaved, existing: existing),
      ),
    );
  }
}

// Static padding — no dynamic keyboard insets (Scaffold handles resize)
class _KeyboardPadding extends StatelessWidget {
  final Widget child;
  const _KeyboardPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: child,
    );
  }
}
