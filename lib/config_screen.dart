import 'package:flutter/material.dart';
import 'config_model.dart';

class ConfigScreen extends StatefulWidget {
  final ConfigModel initialConfig;

  const ConfigScreen({super.key, required this.initialConfig});

  @override
  _ConfigScreenState createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late ConfigModel _config;
  final _nameController = TextEditingController();
  final _widthController = TextEditingController();
  late final Map<String, TextEditingController> _heightControllers;
  late final TextEditingController _copiedHeaderHeightController;
  late List<Map<String, TextEditingController>> _departmentControllers;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _heightControllers = {
      'header': TextEditingController(text: _config.rowHeights['header'].toString()),
      'department': TextEditingController(text: _config.rowHeights['department'].toString()),
      'stamp': TextEditingController(text: _config.rowHeights['stamp'].toString()),
      'signature': TextEditingController(text: _config.rowHeights['signature'].toString()),
      'date': TextEditingController(text: _config.rowHeights['date'].toString()),
    };
    _copiedHeaderHeightController =
        TextEditingController(text: _config.copiedHeaderHeight.toString());

    _departmentControllers = _config.departments.map((dept) {
      return {
        'stamp_text': TextEditingController(text: dept['stamp_text'] as String),
        'stamp_font_size': TextEditingController(text: dept['stamp_font_size'].toString()),
        'signature_text': TextEditingController(text: dept['signature_text'] as String),
        'signature_font_size': TextEditingController(text: dept['signature_font_size'].toString()),
        'date_text': TextEditingController(text: dept['date_text'] as String),
        'date_font_size': TextEditingController(text: dept['date_font_size'].toString()),
      };
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightControllers.values.forEach((controller) => controller.dispose());
    _copiedHeaderHeightController.dispose();
    for (var controllerMap in _departmentControllers) {
      controllerMap.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }

  void _addDepartment() {
    if (_nameController.text.isNotEmpty && _widthController.text.isNotEmpty) {
      final width = double.tryParse(_widthController.text);
      if (width != null) {
        setState(() {
          final newDept = {
            'name': _nameController.text,
            'width': width,
            'stamp_text': 'SELLO', 'stamp_font_size': 6.0,
            'signature_text': 'FIRMA', 'signature_font_size': 6.0,
            'date_text': 'FECHA', 'date_font_size': 6.0,
          };
          _config.departments.add(newDept);
          _departmentControllers.add({
            'stamp_text': TextEditingController(text: newDept['stamp_text'] as String),
            'stamp_font_size': TextEditingController(text: newDept['stamp_font_size'].toString()),
            'signature_text': TextEditingController(text: newDept['signature_text'] as String),
            'signature_font_size': TextEditingController(text: newDept['signature_font_size'].toString()),
            'date_text': TextEditingController(text: newDept['date_text'] as String),
            'date_font_size': TextEditingController(text: newDept['date_font_size'].toString()),
          });
          _nameController.clear();
          _widthController.clear();
        });
      }
    }
  }

  void _removeDepartment(int index) {
    setState(() {
      _departmentControllers[index].values.forEach((c) => c.dispose());
      _departmentControllers.removeAt(index);
      _config.departments.removeAt(index);
    });
  }

  void _saveConfig() {
    _config.rowHeights = {
      'header': double.tryParse(_heightControllers['header']!.text) ?? 20.0,
      'department': double.tryParse(_heightControllers['department']!.text) ?? 20.0,
      'stamp': double.tryParse(_heightControllers['stamp']!.text) ?? 50.0,
      'signature': double.tryParse(_heightControllers['signature']!.text) ?? 25.0,
      'date': double.tryParse(_heightControllers['date']!.text) ?? 25.0,
    };

    _config.copiedHeaderHeight =
        double.tryParse(_copiedHeaderHeightController.text) ?? 30.0;

    for (int i = 0; i < _config.departments.length; i++) {
      _config.departments[i]['stamp_text'] = _departmentControllers[i]['stamp_text']!.text;
      _config.departments[i]['stamp_font_size'] = double.tryParse(_departmentControllers[i]['stamp_font_size']!.text) ?? 6.0;
      _config.departments[i]['signature_text'] = _departmentControllers[i]['signature_text']!.text;
      _config.departments[i]['signature_font_size'] = double.tryParse(_departmentControllers[i]['signature_font_size']!.text) ?? 6.0;
      _config.departments[i]['date_text'] = _departmentControllers[i]['date_text']!.text;
      _config.departments[i]['date_font_size'] = double.tryParse(_departmentControllers[i]['date_font_size']!.text) ?? 6.0;
    }

    Navigator.of(context).pop(_config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Departamentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nuevo Departamento'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _widthController,
                      decoration: const InputDecoration(labelText: 'Ancho %'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addDepartment,
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _config.departments.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ExpansionTile(
                      title: Text(_config.departments[index]['name'] as String),
                      subtitle: Text('Ancho: ${_config.departments[index]['width']}%'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeDepartment(index),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Column(
                            children: [
                              _buildTextAndSizeRow(
                                  _departmentControllers[index]['stamp_text']!,
                                  _departmentControllers[index]['stamp_font_size']!,
                                  'Texto de Sello'),
                              const SizedBox(height: 8),
                              _buildTextAndSizeRow(
                                  _departmentControllers[index]['signature_text']!,
                                  _departmentControllers[index]['signature_font_size']!,
                                  'Texto de Firma'),
                              const SizedBox(height: 8),
                              _buildTextAndSizeRow(
                                  _departmentControllers[index]['date_text']!,
                                  _departmentControllers[index]['date_font_size']!,
                                  'Texto de Fecha'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              const Text('Altura del Encabezado Copiado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _copiedHeaderHeightController,
                decoration:
                    const InputDecoration(labelText: 'Altura del encabezado a copiar'),
                keyboardType: TextInputType.number,
              ),
              const Divider(),
              const Text('Altura de las Filas de la Tabla',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _heightControllers['header'],
                decoration: const InputDecoration(labelText: 'Altura de la cabecera de la tabla'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _heightControllers['department'],
                decoration: const InputDecoration(labelText: 'Altura de los departamentos'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _heightControllers['stamp'],
                decoration: const InputDecoration(labelText: 'Altura del sello'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _heightControllers['signature'],
                decoration: const InputDecoration(labelText: 'Altura de la firma'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _heightControllers['date'],
                decoration: const InputDecoration(labelText: 'Altura de la fecha'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextAndSizeRow(TextEditingController textController, TextEditingController sizeController, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: textController,
            decoration: InputDecoration(labelText: label),
            keyboardType: TextInputType.multiline,
            maxLines: null,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: TextField(
            controller: sizeController,
            decoration: const InputDecoration(labelText: 'Tamaño'),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}
