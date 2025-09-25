import 'package:flutter/material.dart';

class ConfigScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialDepartments;

  const ConfigScreen({super.key, required this.initialDepartments});

  @override
  _ConfigScreenState createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late List<Map<String, dynamic>> _departments;
  final _nameController = TextEditingController();
  final _widthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _departments = List.from(widget.initialDepartments);
  }

  void _addDepartment() {
    if (_nameController.text.isNotEmpty && _widthController.text.isNotEmpty) {
      final width = double.tryParse(_widthController.text);
      if (width != null) {
        setState(() {
          _departments.add({
            'name': _nameController.text,
            'width': width,
          });
          _nameController.clear();
          _widthController.clear();
        });
      }
    }
  }

  void _removeDepartment(int index) {
    setState(() {
      _departments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Departamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.of(context).pop(_departments);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Departamento',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _widthController,
                    decoration: const InputDecoration(
                      labelText: 'Ancho %',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addDepartment,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_departments[index]['name']),
                  subtitle: Text('Ancho: ${_departments[index]['width']}%'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeDepartment(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
