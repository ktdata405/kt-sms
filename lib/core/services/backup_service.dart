import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class BackupService {
  static Future<String?> createBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsMap = <String, dynamic>{};
      for (String key in prefs.getKeys()) {
        prefsMap[key] = prefs.get(key);
      }

      final messages = await DatabaseHelper.instance.getMessages();

      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'preferences': prefsMap,
        'messages': messages,
      };

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/kt_sms_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonEncode(backupData));

      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      if (data.containsKey('preferences')) {
        final prefs = await SharedPreferences.getInstance();
        final prefsMap = data['preferences'] as Map<String, dynamic>;
        for (var entry in prefsMap.entries) {
          final val = entry.value;
          if (val is bool) {
            await prefs.setBool(entry.key, val);
          } else if (val is int) {
            await prefs.setInt(entry.key, val);
          } else if (val is double) {
            await prefs.setDouble(entry.key, val);
          } else if (val is String) {
            await prefs.setString(entry.key, val);
          }
        }
      }

      if (data.containsKey('messages')) {
        final messages = data['messages'] as List<dynamic>;
        for (var msg in messages) {
          await DatabaseHelper.instance.insertMessage(msg as Map<String, dynamic>);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
