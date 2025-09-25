import 'package:flutter/material.dart';

class ConfigScreen extends StatefulWidget {
  final List<String> initialDepartments;

  const ConfigScreen({super.key, required this.initialDepartments});

  @override
  _ConfigScreenState createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late List<String> _departments;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _departments = List.from(widget.initialDepartments);
  }

  void _addDepartment() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _departments.add(_textController.text);
        _textController.clear();
      });
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
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Añadir departamento',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addDepartment,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_departments[index]),
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
