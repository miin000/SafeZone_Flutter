import 'dart:async'; // THÊM IMPORT NÀY
import 'package:flutter/foundation.dart';

class DraftManager {
  final Map<String, dynamic> _draftData = {};
  Timer? _saveTimer;
  final Duration _saveDelay = const Duration(seconds: 2);

  final VoidCallback? onSave;

  DraftManager({this.onSave});

  void updateDraft(String key, dynamic value) {
    _draftData[key] = value;

    // Debounce save
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _saveDraft);
  }

  void _saveDraft() {
    if (_draftData.isNotEmpty && onSave != null) {
      onSave!();
    }
  }

  Map<String, dynamic> get draftData => Map.from(_draftData);

  void clearDraft() {
    _draftData.clear();
    _saveTimer?.cancel();
  }

  void dispose() {
    _saveTimer?.cancel();
  }
}