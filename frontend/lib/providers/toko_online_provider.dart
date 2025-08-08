import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/toko_online_model.dart';
import '../services/toko_online_service.dart';

// State notifier untuk pengaturan toko online
class TokoOnlineSettingsNotifier
    extends StateNotifier<AsyncValue<TokoOnlineSettings>> {
  final TokoOnlineService _service;

  TokoOnlineSettingsNotifier(this._service)
      : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _service.getTokoOnlineSettings();
      state = AsyncValue.data(settings);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateSettings(TokoOnlineSettings newSettings) async {
    try {
      await _service.updateTokoOnlineSettings(newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// State notifier untuk rekening bank
class RekeningBankNotifier
    extends StateNotifier<AsyncValue<List<RekeningBank>>> {
  final TokoOnlineService _service;

  RekeningBankNotifier(this._service) : super(const AsyncValue.loading()) {
    loadRekeningBank();
  }

  Future<void> loadRekeningBank() async {
    try {
      state = const AsyncValue.loading();
      final rekeningList = await _service.getRekeningBank();
      state = AsyncValue.data(rekeningList);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addRekening(RekeningBank rekening) async {
    try {
      await _service.addRekeningBank(rekening);
      await loadRekeningBank(); // Reload data
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteRekening(int rekeningId) async {
    try {
      await _service.deleteRekeningBank(rekeningId);
      await loadRekeningBank(); // Reload data
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Providers
final tokoOnlineSettingsProvider = StateNotifierProvider<
    TokoOnlineSettingsNotifier, AsyncValue<TokoOnlineSettings>>((ref) {
  final service = ref.watch(tokoOnlineServiceProvider);
  return TokoOnlineSettingsNotifier(service);
});

final rekeningBankProvider =
    StateNotifierProvider<RekeningBankNotifier, AsyncValue<List<RekeningBank>>>(
        (ref) {
  final service = ref.watch(tokoOnlineServiceProvider);
  return RekeningBankNotifier(service);
});
