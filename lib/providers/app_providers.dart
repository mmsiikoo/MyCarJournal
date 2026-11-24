import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_repository.dart';
import '../data/event_repository.dart';
import '../data/fuel_repository.dart';
import '../data/photo_service.dart';
import '../data/user_data_repository.dart';
import '../data/vehicle_repository.dart';
import '../models/event_photo.dart';
import '../models/fuel_entry.dart';
import '../models/fuel_stats.dart';
import '../models/maintenance_event.dart';
import '../models/vehicle.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences не ініціалізовано'),
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepository(ref.watch(firestoreProvider)),
);

final fuelRepositoryProvider = Provider<FuelRepository>(
  (ref) => FuelRepository(ref.watch(firestoreProvider)),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(firestoreProvider)),
);

final userDataRepositoryProvider = Provider<UserDataRepository>(
  (ref) => UserDataRepository(ref.watch(firestoreProvider)),
);

final photoServiceProvider = Provider<PhotoService>((ref) => PhotoService());

final userChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(userChangesProvider).value,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    return switch (raw) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  void setMode(ThemeMode mode) {
    state = mode;
    ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class SelectedVehicleIdNotifier extends Notifier<String?> {
  static const _key = 'selectedVehicleId';

  @override
  String? build() => ref.read(sharedPrefsProvider).getString(_key);

  void select(String? id) {
    state = id;
    final prefs = ref.read(sharedPrefsProvider);
    if (id == null) {
      prefs.remove(_key);
    } else {
      prefs.setString(_key, id);
    }
  }
}

final selectedVehicleIdProvider =
    NotifierProvider<SelectedVehicleIdNotifier, String?>(
      SelectedVehicleIdNotifier.new,
    );

final vehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(const <Vehicle>[]);
  return ref.watch(vehicleRepositoryProvider).watchVehicles(uid);
});

final activeVehicleProvider = Provider<Vehicle?>((ref) {
  final vehicles = ref.watch(vehiclesProvider).value ?? const <Vehicle>[];
  if (vehicles.isEmpty) return null;
  final selectedId = ref.watch(selectedVehicleIdProvider);
  for (final vehicle in vehicles) {
    if (vehicle.id == selectedId) return vehicle;
  }
  return vehicles.first;
});

final fuelEntriesProvider = StreamProvider<List<FuelEntry>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(const <FuelEntry>[]);
  return ref.watch(fuelRepositoryProvider).watchEntries(uid);
});

final eventsProvider = StreamProvider<List<MaintenanceEvent>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(const <MaintenanceEvent>[]);
  return ref.watch(eventRepositoryProvider).watchEvents(uid);
});

final activeVehicleFuelEntriesProvider = Provider<List<FuelEntry>>((ref) {
  final vehicle = ref.watch(activeVehicleProvider);
  final entries = ref.watch(fuelEntriesProvider).value ?? const <FuelEntry>[];
  if (vehicle == null) return const [];
  return entries.where((entry) => entry.vehicleId == vehicle.id).toList();
});

final activeVehicleEventsProvider = Provider<List<MaintenanceEvent>>((ref) {
  final vehicle = ref.watch(activeVehicleProvider);
  final events = ref.watch(eventsProvider).value ?? const <MaintenanceEvent>[];
  if (vehicle == null) return const [];
  return events.where((event) => event.vehicleId == vehicle.id).toList();
});

final fuelStatsProvider = Provider<FuelStats>((ref) {
  return FuelStats.fromEntries(ref.watch(activeVehicleFuelEntriesProvider));
});

final latestOdometerProvider = Provider<double>((ref) {
  final vehicle = ref.watch(activeVehicleProvider);
  if (vehicle == null) return 0;
  var maxOdometer = vehicle.initialOdometer;
  for (final entry in ref.watch(activeVehicleFuelEntriesProvider)) {
    maxOdometer = math.max(maxOdometer, entry.odometer);
  }
  for (final event in ref.watch(activeVehicleEventsProvider)) {
    final odometer = event.odometer;
    if (odometer != null) maxOdometer = math.max(maxOdometer, odometer);
  }
  return maxOdometer;
});

final eventPhotosProvider = StreamProvider.family<List<EventPhoto>, String>((
  ref,
  eventId,
) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(const <EventPhoto>[]);
  return ref.watch(eventRepositoryProvider).watchPhotos(uid, eventId);
});
