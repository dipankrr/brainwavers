import 'package:brainwavers/models/franchise_model.dart';
import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class FranchiseProvider with ChangeNotifier {

  List<Franchise> _franchises = [];

  bool _isLoading = false;
  String? _error;

  List<Franchise> get franchises => _franchises;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFranchiseData() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadFranchises(),
      ]);
      _error = null;
    } catch (e) {
      _error = 'Failed to load academic data: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadFranchises() async {
    _franchises = await SupabaseService.getFranchises();
  }



  // Franchise CRUD
  Future<void> addFranchise(Franchise franchiseItem) async {
    _setLoading(true);
    try {
      final newFranchise = await SupabaseService.createFranchise(franchiseItem);
      _franchises.add(newFranchise);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add Franchise: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateFranchise(Franchise franchiseItem) async {
    _setLoading(true);
    try {
      final updatedFranchise = await SupabaseService.updateFranchises(franchiseItem);
      final index = _franchises.indexWhere((c) => c.id == franchiseItem.id);
      if (index != -1) {
        _franchises[index] = updatedFranchise;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update Franchise: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteFranchise(String id) async {
    _setLoading(true);
    try {
      await SupabaseService.deleteFranchise(id);
      _franchises.removeWhere((franchiseItem) => franchiseItem.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete Franchise: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }



  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}