import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'stamp_model.dart';
import 'stamp_designer_screen.dart';
// ¡Asegúrate de haber creado los otros archivos!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Sellos',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const StampManagementScreen(),
    );
  }
}

class StampManagementScreen extends StatefulWidget {
  const StampManagementScreen({super.key});

  @override
  _StampManagementScreenState createState() => _StampManagementScreenState();
}

class _StampManagementScreenState extends State<StampManagementScreen> {
  List<Stamp> _stamps = [];

  @override
  void initState() {
    super.initState();
    _loadStamps();
  }

  Future<void> _loadStamps() async {
    final prefs = await SharedPreferences.getInstance();
    final stampsString = prefs.getStringList('stamps') ?? [];
    setState(() {
      _stamps = stampsString.map((s) => Stamp.fromJson(json.decode(s))).toList();
    });
  }

  Future<void> _saveStamps() async {
    final prefs = await SharedPreferences.getInstance();
    final stampsString = _stamps.map((s) => json.encode(s.toJson())).toList();
    await prefs.setStringList('stamps', stampsString);
  }

  void _addOrEditStamp({Stamp? stamp, int? index}) async {
    final result = await Navigator.push<Stamp>(
      context,
      MaterialPageRoute(builder: (context) => StampDesignerScreen(stamp: stamp)),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _stamps[index] = result;
        } else {
          _stamps.add(result);
        }
      });
      _saveStamps();
    }
  }
  
  void _deleteStamp(int index) {
      setState(() {
          _stamps.removeAt(index);
      });
      _saveStamps();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Sellos'),
      ),
      body: _stamps.isEmpty
          ? const Center(child: Text('No tienes sellos. ¡Crea uno nuevo!'))
          : ListView.builder(
              itemCount: _stamps.length,
              itemBuilder: (context, index) {
                final stamp = _stamps[index];
                return ListTile(
                  leading: Icon(
                    stamp.shape == 'circle' ? Icons.circle : Icons.crop_square,
                    color: Color(stamp.colorValue),
                  ),
                  title: Text(stamp.text),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _addOrEditStamp(stamp: stamp, index: index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteStamp(index),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Aquí iría la lógica para seleccionar el sello y aplicarlo al PDF
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sello "${stamp.text}" seleccionado.')),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditStamp(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
