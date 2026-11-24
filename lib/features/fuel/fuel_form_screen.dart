import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../models/fuel_entry.dart';
import '../../models/vehicle.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_snack.dart';

class FuelFormScreen extends ConsumerStatefulWidget {
  const FuelFormScreen({super.key, this.entryId});

  final String? entryId;

  @override
  ConsumerState<FuelFormScreen> createState() => _FuelFormScreenState();
}

class _FuelFormScreenState extends ConsumerState<FuelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometer = TextEditingController();
  final _liters = TextEditingController();
  final _price = TextEditingController();
  final _station = TextEditingController();
  final _notes = TextEditingController();

  DateTime _date = DateTime.now();
  bool _isFullTank = true;
  bool _initialized = false;
  bool _saving = false;
  String? _vehicleId;
  String? _error;

  bool get _isEditing => widget.entryId != null;

  @override
  void dispose() {
    _odometer.dispose();
    _liters.dispose();
    _price.dispose();
    _station.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _hydrate(FuelEntry entry) {
    _vehicleId = entry.vehicleId;
    _date = entry.date;
    _odometer.text = formatDecimal(entry.odometer);
    _liters.text = formatDecimal(entry.liters);
    _price.text = formatDecimal(entry.pricePerLiter);
    _station.text = entry.station;
    _notes.text = entry.notes;
    _isFullTank = entry.isFullTank;
    _initialized = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Дата заправки',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    if (_vehicleId == null) {
      setState(() => _error = 'Оберіть автомобіль.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final entry = FuelEntry(
      id: widget.entryId ?? '',
      vehicleId: _vehicleId!,
      date: _date,
      odometer: Validators.parseNumber(_odometer.text)!,
      liters: Validators.parseNumber(_liters.text)!,
      pricePerLiter: Validators.parseNumber(_price.text)!,
      isFullTank: _isFullTank,
      station: _station.text,
      notes: _notes.text,
      createdAt: DateTime.now(),
    );

    try {
      final repository = ref.read(fuelRepositoryProvider);
      if (_isEditing) {
        await repository.update(uid, entry);
      } else {
        await repository.create(uid, entry);
      }
      if (!mounted) return;
      showAppSnack(
        context,
        _isEditing ? 'Заправку оновлено' : 'Заправку додано',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Не вдалося зберегти заправку: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.value ?? const <Vehicle>[];
    final entries = ref.watch(fuelEntriesProvider).value ?? const <FuelEntry>[];
    final active = ref.watch(activeVehicleProvider);

    FuelEntry? existing;
    if (_isEditing) {
      for (final entry in entries) {
        if (entry.id == widget.entryId) {
          existing = entry;
          break;
        }
      }
      if (existing != null && !_initialized) {
        _hydrate(existing);
      }
    }

    if (!_initialized && !_isEditing) {
      _vehicleId =
          active?.id ?? (vehicles.isNotEmpty ? vehicles.first.id : null);
      _initialized = true;
    }

    if (_isEditing && existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редагування заправки')),
        body: ref.watch(fuelEntriesProvider).isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Заправку не знайдено')),
      );
    }

    if (vehicles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Нова заправка')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Спочатку додайте автомобіль у гаражі.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагування заправки' : 'Нова заправка'),
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
                    DropdownButtonFormField<String>(
                      initialValue: _vehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Автомобіль',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                      ),
                      items: [
                        for (final vehicle in vehicles)
                          DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(vehicle.title),
                          ),
                      ],
                      onChanged: (value) => setState(() => _vehicleId = value),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата',
                          prefixIcon: Icon(Icons.event_outlined),
                          suffixIcon: Icon(Icons.expand_more_rounded),
                        ),
                        child: Text(formatDate(_date)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _odometer,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => Validators.positiveNumber(
                              value,
                              label: 'Пробіг',
                            ),
                            decoration: InputDecoration(
                              labelText: 'Пробіг, км',
                              hintText: formatWhole(
                                ref.watch(latestOdometerProvider),
                              ),
                              prefixIcon: const Icon(Icons.speed_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _liters,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => Validators.positiveNumber(
                              value,
                              label: 'Кількість літрів',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Кількість, л',
                              hintText: '40',
                              prefixIcon: Icon(
                                Icons.local_gas_station_outlined,
                              ),
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
                            controller: _price,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => Validators.positiveNumber(
                              value,
                              label: 'Ціна за літр',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Ціна за літр, ₴',
                              hintText: '56,90',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ListenableBuilder(
                            listenable: Listenable.merge([_liters, _price]),
                            builder: (context, _) {
                              final liters =
                                  Validators.parseNumber(_liters.text) ?? 0;
                              final price =
                                  Validators.parseNumber(_price.text) ?? 0;
                              return InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Сума',
                                  prefixIcon: Icon(Icons.receipt_long_outlined),
                                ),
                                child: Text(
                                  formatMoney(liters * price),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: _isFullTank,
                      onChanged: (value) => setState(() => _isFullTank = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Повний бак'),
                      subtitle: const Text(
                        'Потрібно для точного розрахунку витрати',
                      ),
                      secondary: const Icon(Icons.battery_full_rounded),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _station,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'АЗС (необов’язково)',
                        hintText: 'Наприклад, ОККО',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notes,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Нотатки (необов’язково)',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
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
                      label: Text(
                        _saving ? 'Зберігаємо…' : 'Зберегти заправку',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Витрата розраховується між двома повними баками: '
                      'літри / пробіг × 100.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
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
