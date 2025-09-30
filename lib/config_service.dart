import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config_model.dart';

class ConfigService {
  static const String _configKey = 'config';
  static const String _passwordKey = 'config_password';

  // Guarda la configuración en SharedPreferences
  Future<void> saveConfig(ConfigModel config) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(config.toJson());
    await prefs.setString(_configKey, jsonString);
  }

  // Carga la configuración desde SharedPreferences
  Future<ConfigModel> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_configKey);
    if (jsonString != null) {
      return ConfigModel.fromJson(json.decode(jsonString));
    }
    // Devuelve la configuración por defecto si no hay ninguna guardada
    return _getDefaultConfig();
  }

  // Verifica la contraseña
  Future<bool> checkPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final String savedPassword = prefs.getString(_passwordKey) ?? '1234'; // Contraseña por defecto
    return password == savedPassword;
  }
  
  // Configuración por defecto
  ConfigModel _getDefaultConfig() {
    return ConfigModel(
      departments: [
        {
          'name': 'METALURGIA', 'width': 49.0, 'stamp_text': 'SELLO', 'stamp_font_size': 6.0,
          'signature_text': 'FIRMA', 'signature_font_size': 6.0, 'date_text': 'FECHA', 'date_font_size': 6.0,
        },
        {
          'name': 'ALMACEN', 'width': 17.0, 'stamp_text': 'SELLO', 'stamp_font_size': 6.0,
          'signature_text': 'FIRMA', 'signature_font_size': 6.0, 'date_text': 'FECHA', 'date_font_size': 6.0,
        },
        {
          'name': 'CALIDAD', 'width': 17.0, 'stamp_text': 'SELLO', 'stamp_font_size': 6.0,
          'signature_text': 'FIRMA', 'signature_font_size': 6.0, 'date_text': 'FECHA', 'date_font_size': 6.0,
        },
        {
          'name': 'PRODUCCION', 'width': 17.0, 'stamp_text': 'SELLO', 'stamp_font_size': 6.0,
          'signature_text': 'FIRMA', 'signature_font_size': 6.0, 'date_text': 'FECHA', 'date_font_size': 6.0,
        },
      ],
      rowHeights: {
        'header': 20.0, 'department': 20.0, 'stamp': 50.0, 'signature': 25.0, 'date': 25.0,
      },
      copiedHeaderHeight: 30.0, // Valor por defecto para la nueva variable
    );
  }
}
