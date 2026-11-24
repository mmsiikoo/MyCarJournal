import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../core/vehicle_types.dart';
import '../../data/photo_service.dart';
import '../../models/event_photo.dart';
import '../../models/maintenance_event.dart';
import '../../models/vehicle.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/base64_image.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.eventId});

  final String? eventId;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _odometer = TextEditingController();
  final _cost = TextEditingController();
  final _notes = TextEditingController();
  final _nextDueOdometer = TextEditingController();

  MaintenanceCategory _category = MaintenanceCategory.oil;
  DateTime _date = DateTime.now();
  DateTime? _nextDueDate;
  String? _vehicleId;
  final List<PickedPhoto> _newPhotos = [];
  final Set<String> _removedPhotoIds = {};

  bool _initialized = false;
  bool _saving = false;
  bool _picking = false;
  int _uploaded = 0;
  int _uploadTotal = 0;
  String? _error;

  bool get _isEditing => widget.eventId != null;

  @override
  void dispose() {
    _title.dispose();
    _odometer.dispose();
    _cost.dispose();
    _notes.dispose();
    _nextDueOdometer.dispose();
    super.dispose();
  }

  void _hydrate(MaintenanceEvent event) {
    _vehicleId = event.vehicleId;
    _category = event.category;
    _title.text = event.title;
    _date = event.date;
    _odometer.text = event.odometer == null
        ? ''
        : formatDecimal(event.odometer!);
    _cost.text = event.cost == null ? '' : formatDecimal(event.cost!);
    _notes.text = event.notes;
    _nextDueDate = event.nextDueDate;
    _nextDueOdometer.text = event.nextDueOdometer == null
        ? ''
        : formatDecimal(event.nextDueOdometer!);
    _initialized = true;
  }

  Future<void> _pickDate({required bool due}) async {
    final now = DateTime.now();
    final initial = due ? (_nextDueDate ?? now) : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
      helpText: due ? 'Наступне ТО' : 'Дата події',
    );
    if (picked == null) return;
    setState(() {
      if (due) {
        _nextDueDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _pickPhotos(int remaining) async {
    if (remaining <= 0 || _picking) return;
    setState(() => _picking = true);
    try {
      final photos = await ref
          .read(photoServiceProvider)
          .pickAndCompress(maxCount: remaining);
      if (!mounted) return;
      setState(() => _newPhotos.addAll(photos));
    } on PhotoException catch (error) {
      if (!mounted) return;
      showAppSnack(context, error.message, error: true);
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, 'Не вдалося вибрати фото: $error', error: true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save(int existingPhotosCount) async {
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
      _uploaded = 0;
      _uploadTotal = _newPhotos.length;
    });

    final event = MaintenanceEvent(
      id: widget.eventId ?? '',
      vehicleId: _vehicleId!,
      category: _category,
      title: _title.text,
      date: _date,
      odometer: Validators.parseNumber(_odometer.text),
      cost: Validators.parseNumber(_cost.text),
      notes: _notes.text,
      photoCount: existingPhotosCount,
      coverThumb: null,
      nextDueDate: _nextDueDate,
      nextDueOdometer: Validators.parseNumber(_nextDueOdometer.text),
      createdAt: DateTime.now(),
    );

    try {
      await ref
          .read(eventRepositoryProvider)
          .saveEvent(
            uid: uid,
            event: event,
            newPhotos: _newPhotos,
            removedPhotoIds: _removedPhotoIds.toList(),
            onProgress: (uploaded, total) {
              if (!mounted) return;
              setState(() {
                _uploaded = uploaded;
                _uploadTotal = total;
              });
            },
          );
      if (!mounted) return;
      showAppSnack(context, _isEditing ? 'Подію оновлено' : 'Подію додано');
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Не вдалося зберегти подію: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final events = eventsAsync.value ?? const <MaintenanceEvent>[];
    final vehicles = ref.watch(vehiclesProvider).value ?? const <Vehicle>[];
    final active = ref.watch(activeVehicleProvider);

    MaintenanceEvent? existing;
    if (_isEditing) {
      for (final event in events) {
        if (event.id == widget.eventId) {
          existing = event;
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
        appBar: AppBar(title: const Text('Редагування події')),
        body: eventsAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Подію не знайдено')),
      );
    }

    if (vehicles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Нова подія')),
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

    final photosAsync = _isEditing
        ? ref.watch(eventPhotosProvider(widget.eventId!))
        : const AsyncValue<List<EventPhoto>>.data([]);
    final photos = photosAsync.value ?? const <EventPhoto>[];
    final photosLoading = _isEditing && photosAsync.isLoading;
    final visibleExisting = photos
        .where((photo) => !_removedPhotoIds.contains(photo.id))
        .toList();
    final totalPhotos = visibleExisting.length + _newPhotos.length;
    final remaining = PhotoService.maxPhotosPerEvent - totalPhotos;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагування події' : 'Нова подія'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
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
                    DropdownButtonFormField<MaintenanceCategory>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Категорія',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        for (final category in MaintenanceCategory.values)
                          DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  size: 18,
                                  color: category.color,
                                ),
                                const SizedBox(width: 8),
                                Text(category.label),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _category = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) =>
                          Validators.required(value, 'Опис події'),
                      decoration: const InputDecoration(
                        labelText: 'Що зроблено',
                        hintText:
                            'Наприклад, заміна передніх гальмівних колодок',
                        prefixIcon: Icon(Icons.build_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _pickDate(due: false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Дата',
                                prefixIcon: Icon(Icons.event_outlined),
                                suffixIcon: Icon(Icons.expand_more_rounded),
                              ),
                              child: Text(formatDate(_date)),
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
                              labelText: 'Пробіг, км',
                              prefixIcon: Icon(Icons.speed_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _cost,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          Validators.optionalNonNegative(value, 'Вартість'),
                      decoration: const InputDecoration(
                        labelText: 'Вартість, ₴ (необов’язково)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notes,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Нотатки (необов’язково)',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Нагадування про наступне ТО',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _pickDate(due: true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Наступна дата',
                                prefixIcon: const Icon(
                                  Icons.notifications_outlined,
                                ),
                                suffixIcon: _nextDueDate == null
                                    ? const Icon(Icons.expand_more_rounded)
                                    : IconButton(
                                        tooltip: 'Очистити',
                                        onPressed: () =>
                                            setState(() => _nextDueDate = null),
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                              ),
                              child: Text(
                                _nextDueDate == null
                                    ? 'Не вказано'
                                    : formatDate(_nextDueDate!),
                                style: _nextDueDate == null
                                    ? TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.45),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nextDueOdometer,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) =>
                                Validators.optionalNonNegative(
                                  value,
                                  'Наступний пробіг',
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Наступний пробіг, км',
                              prefixIcon: Icon(Icons.speed_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Фото ($totalPhotos/${PhotoService.maxPhotosPerEvent})',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: remaining <= 0 || _picking || photosLoading
                              ? null
                              : () => _pickPhotos(remaining),
                          icon: _picking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 18,
                                ),
                          label: Text(_picking ? 'Обробка…' : 'Додати фото'),
                        ),
                      ],
                    ),
                    Text(
                      'До 5 фото на подію. Зображення автоматично стискаються, '
                      'щоб економити місце.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (photosLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (totalPhotos == 0)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.35,
                              ),
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Фото ще немає',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final photo in visibleExisting)
                            _PhotoTile(
                              data: photo.thumb,
                              onRemove: () => setState(
                                () => _removedPhotoIds.add(photo.id),
                              ),
                            ),
                          for (var i = 0; i < _newPhotos.length; i++)
                            _PhotoTile(
                              data: _newPhotos[i].thumb,
                              isNew: true,
                              onRemove: () =>
                                  setState(() => _newPhotos.removeAt(i)),
                            ),
                        ],
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
                      onPressed: _saving
                          ? null
                          : () => _save(visibleExisting.length),
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
                        _saving
                            ? (_uploadTotal > 0
                                  ? 'Зберігаємо фото $_uploaded/$_uploadTotal…'
                                  : 'Зберігаємо…')
                            : 'Зберегти подію',
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

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.data,
    required this.onRemove,
    this.isNew = false,
  });

  final String data;
  final VoidCallback onRemove;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: 96, height: 96, child: Base64Image(data)),
        ),
        if (isNew)
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'нове',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
