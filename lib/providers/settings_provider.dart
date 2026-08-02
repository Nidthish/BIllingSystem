import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/settings.dart';

class SettingsProvider with ChangeNotifier {
  Settings? _settings;

  Settings? get settings => _settings;

  Future<void> loadSettings() async {
    _settings = await DatabaseHelper.instance.getSettings();
    notifyListeners();
  }

  Future<void> updateSettings(Settings newSettings) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('settings');
    await db.insert('settings', newSettings.toMap());
    _settings = newSettings;
    notifyListeners();
  }
}
