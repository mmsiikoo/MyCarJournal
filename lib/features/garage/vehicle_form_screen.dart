import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../core/vehicle_types.dart';
import '../../models/vehicle.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_snack.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.vehicleId});

  final String? vehicleId;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _plate = TextEditingController();
  final _tank = TextEditingController();
  final _odometer = TextEditingController();

  FuelType _fuelType = FuelType.petrol;
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.vehicleId != null;

  @override
  void dispose() {
    _nickname.dispose();
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _plate.dispose();
    _tank.dispose();
    _odometer.dispose();
    super.dispose();
  }

  void _hydrate(Vehicle vehicle) {
    _nickname.text = vehicle.nickname;
    _make.text = vehicle.make;
    _model.text = vehicle.model;
    _year.text = vehicle.year?.toString() ?? '';
    _plate.text = vehicle.plate;
    _tank.text = vehicle.tankCapacity == null
        ? ''
        : formatDecimal(vehicle.tankCapacity!);
    _odometer.text = vehicle.initialOdometer == 0
        ? ''
        : formatDecimal(vehicle.initialOdometer);
    _fuelType = vehicle.fuelType;
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nickname.text.trim().isEmpty &&
        _make.text.trim().isEmpty &&
        _model.text.trim().isEmpty) {
      setState(() => _error = 'Вкажіть назву авто або марку й модель.');
      return;
    }
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final vehicle = Vehicle(
      id: widget.vehicleId ?? '',
      nickname: _nickname.text,
      make: _make.text,
      model: _model.text,
      year: int.tryParse(_year.text.trim()),
      plate: _plate.text,
      fuelType: _fuelType,
      tankCapacity: Validators.parseNumber(_tank.text),
      initialOdometer: Validators.parseNumber(_odometer.text) ?? 0,
      createdAt: DateTime.now(),
    );

    try {
      final repository = ref.read(vehicleRepositoryProvider);
      if (_isEditing) {
        await repository.update(uid, vehicle);
      } else {
        final id = await repository.create(uid, vehicle);
        ref.read(selectedVehicleIdProvider.notifier).select(id);
      }
      if (!mounted) return;
      showAppSnack(
        context,
        _isEditing ? 'Авто оновлено' : 'Авто додано в гараж',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Не вдалося зберегти авто: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.value ?? const <Vehicle>[];
    Vehicle? existing;
    if (_isEditing) {
      for (final vehicle in vehicles) {
        if (vehicle.id == widget.vehicleId) {
          existing = vehicle;
          break;
        }
      }
      if (existing != null && !_initialized) {
        _hydrate(existing);
      }
    }

    if (_isEditing && existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редагування авто')),
        body: vehiclesAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Авто не знайдено')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагування авто' : 'Нове авто'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Основна інформація',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nickname,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Назва авто (необов’язково)',
                        hintText: 'Наприклад, «Сімейний Passat»',
                        prefixIcon: Icon(Icons.bookmark_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _make,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Марка',
                              hintText: 'Volkswagen',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _model,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Модель',
                              hintText: 'Passat',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _year,
                            keyboardType: TextInputType.number,
                            validator: Validators.optionalYear,
                            decoration: const InputDecoration(
                              labelText: 'Рік випуску',
                              hintText: '2019',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _plate,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Номерний знак',
                              hintText: 'AA 1234 BB',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Пальне та пробіг',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<FuelType>(
                      initialValue: _fuelType,
                      decoration: const InputDecoration(
                        labelText: 'Тип пального',
                        prefixIcon: Icon(Icons.local_gas_station_outlined),
                      ),
                      items: [
                        for (final type in FuelType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _fuelType = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tank,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) =>
                                Validators.optionalNonNegative(
                                  value,
                                  'Об’єм бака',
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Об’єм бака, л',
                              hintText: '60',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _odometer,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) =>
                                Validators.optionalNonNegative(value, 'Пробіг'),
                            decoration: const InputDecoration(
                              labelText: 'Початковий пробіг, км',
                              hintText: '85000',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Початковий пробіг використовується для розрахунку витрати, '
                      'якщо у вас ще немає заправок.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Зберігаємо…' : 'Зберегти авто'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
