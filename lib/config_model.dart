import 'dart:convert';

class ConfigModel {
  List<Map<String, dynamic>> departments;
  Map<String, double> rowHeights;
  double copiedHeaderHeight; // Nueva propiedad

  ConfigModel({
    required this.departments,
    required this.rowHeights,
    this.copiedHeaderHeight = 30.0, // Valor por defecto
  });

  // Convierte el modelo a un mapa para guardarlo en JSON
  Map<String, dynamic> toJson() {
    return {
      'departments': departments,
      'rowHeights': rowHeights,
      'copiedHeaderHeight': copiedHeaderHeight, // Añadir a JSON
    };
  }

  // Crea un modelo a partir de un mapa (cargado desde JSON)
  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      departments: List<Map<String, dynamic>>.from(json['departments']),
      rowHeights: Map<String, double>.from(json['rowHeights']),
      // Cargar desde JSON con un valor por defecto si no existe
      copiedHeaderHeight: (json['copiedHeaderHeight'] as num?)?.toDouble() ?? 30.0,
    );
  }
}
