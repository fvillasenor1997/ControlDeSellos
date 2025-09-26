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
  late List<Map<String, TextEditingController>> _departmentTextControllers;

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

    _departmentTextControllers = _config.departments.map((dept) {
      return {
        'stamp': TextEditingController(text: dept['stamp_text']),
        'signature': TextEditingController(text: dept['signature_text']),
        'date': TextEditingController(text: dept['date_text']),
      };
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightControllers.values.forEach((controller) => controller.dispose());
    for (var controllerMap in _departmentTextControllers) {
      controllerMap.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }

  void _addDepartment() {
    if (_nameController.text.isNotEmpty && _widthController.text.isNotEmpty) {
      final width = double.tryParse(_widthController.text);
      if (width != null) {
        setState(() {
          _config.departments.add({
            'name': _nameController.text,
            'width': width,
            'stamp_text': 'SELLO',
            'signature_text': 'FIRMA',
            'date_text': 'FECHA',
          });
          _departmentTextControllers.add({
            'stamp': TextEditingController(text: 'SELLO'),
            'signature': TextEditingController(text: 'FIRMA'),
            'date': TextEditingController(text: 'FECHA'),
          });
          _nameController.clear();
          _widthController.clear();
        });
      }
    }
  }

  void _removeDepartment(int index) {
    setState(() {
      _departmentTextControllers[index].values.forEach((c) => c.dispose());
      _departmentTextControllers.removeAt(index);
      _config.departments.removeAt(index);
    });
  }

  void _saveConfig() {
    final newHeights = {
      'header': double.tryParse(_heightControllers['header']!.text) ?? 20.0,
      'department': double.tryParse(_heightControllers['department']!.text) ?? 20.0,
      'stamp': double.tryParse(_heightControllers['stamp']!.text) ?? 50.0,
      'signature': double.tryParse(_heightControllers['signature']!.text) ?? 25.0,
      'date': double.tryParse(_heightControllers['date']!.text) ?? 25.0,
    };
    _config.rowHeights = newHeights;

    for (int i = 0; i < _config.departments.length; i++) {
      _config.departments[i]['stamp_text'] = _departmentTextControllers[i]['stamp']!.text;
      _config.departments[i]['signature_text'] = _departmentTextControllers[i]['signature']!.text;
      _config.departments[i]['date_text'] = _departmentTextControllers[i]['date']!.text;
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
                      title: Text(_config.departments[index]['name']),
                      subtitle: Text('Ancho: ${_config.departments[index]['width']}%'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeDepartment(index),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: _departmentTextControllers[index]['stamp'],
                                decoration: const InputDecoration(labelText: 'Texto de Sello'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _departmentTextControllers[index]['signature'],
                                decoration: const InputDecoration(labelText: 'Texto de Firma'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _departmentTextControllers[index]['date'],
                                decoration: const InputDecoration(labelText: 'Texto de Fecha'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              const Text('Altura de las Filas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _heightControllers['header'],
                decoration: const InputDecoration(labelText: 'Altura de la cabecera'),
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
}
