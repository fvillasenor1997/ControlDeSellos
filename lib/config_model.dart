class ConfigModel {
  List<Map<String, dynamic>> departments;
  Map<String, double> rowHeights;
  double tableBottomOffset; // Nueva propiedad

  ConfigModel({
    required this.departments, 
    required this.rowHeights,
    required this.tableBottomOffset, // Nueva propiedad
  });
}
