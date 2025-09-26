import 'dart:convert';

class ConfigModel {
  List<Map<String, dynamic>> departments;
  Map<String, double> rowHeights;

  ConfigModel({required this.departments, required this.rowHeights});

  // Nuevo: convierte el modelo a un mapa para guardarlo en JSON
  Map<String, dynamic> toJson() {
    return {
      'departments': departments,
      'rowHeights': rowHeights,
    };
  }

  // Nuevo: crea un modelo a partir de un mapa (cargado desde JSON)
  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      departments: List<Map<String, dynamic>>.from(json['departments']),
      rowHeights: Map<String, double>.from(json['rowHeights']),
    );
  }
}
