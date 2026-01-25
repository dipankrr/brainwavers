import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  final Map<String, List<Map<String, dynamic>>> _adminsByFranchise = {};

  bool isLoading = false;
  String? error;

  List<Map<String, dynamic>> getAdmins(String franchiseId) {
    return _adminsByFranchise[franchiseId] ?? [];
  }

  Future<void> loadAdmins(String franchiseId) async {
    try {
      isLoading = true;
      notifyListeners();

      final admins =
      await SupabaseService.getAdminsByFranchise(franchiseId);

      _adminsByFranchise[franchiseId] = admins;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAdmin({
    required String id,
    required String password,
    required String franchiseId,
  }) async {
    final success = await SupabaseService.createAdmin(
      Uuid().v4(),
      id,
      password,
      franchiseId,
    );

    if (success) {
      await loadAdmins(franchiseId); // 🔥 refresh UI
    }

    return success;
  }
}
