import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'stamp_model.dart';

class StampDesignerScreen extends StatefulWidget {
  final Stamp? stamp; // Sello existente para editar, o null si es nuevo
  const StampDesignerScreen({super.key, this.stamp});

  @override
  _StampDesignerScreenState createState() => _StampDesignerScreenState();
}

class _StampDesignerScreenState extends State<StampDesignerScreen> {
  late Stamp _currentStamp;

  @override
  void initState() {
    super.initState();
    _currentStamp = widget.stamp ?? Stamp(text: 'MI SELLO');
  }

  void _changeColor(Color color) {
    setState(() {
      _currentStamp.colorValue = color.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stamp == null ? 'Diseñar Sello' : 'Editar Sello'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Devuelve el sello diseñado a la pantalla anterior
              Navigator.of(context).pop(_currentStamp);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Vista previa del sello
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Color(_currentStamp.colorValue), width: 3),
                shape: _currentStamp.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
              ),
              child: Text(
                _currentStamp.text,
                style: TextStyle(
                  fontSize: _currentStamp.fontSize,
                  fontWeight: _currentStamp.isBold ? FontWeight.bold : FontWeight.normal,
                  color: Color(_currentStamp.colorValue),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Controles de diseño
            TextField(
              decoration: const InputDecoration(labelText: 'Texto del Sello'),
              controller: TextEditingController(text: _currentStamp.text),
              onChanged: (value) => setState(() => _currentStamp.text = value),
            ),
            Slider(
              label: 'Tamaño: ${_currentStamp.fontSize.toStringAsFixed(0)}',
              value: _currentStamp.fontSize,
              min: 10,
              max: 50,
              onChanged: (value) => setState(() => _currentStamp.fontSize = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Elige un color'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: Color(_currentStamp.colorValue),
                            onColorChanged: _changeColor,
                          ),
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            child: const Text('OK'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Color'),
                ),
                ToggleButtons(
                  isSelected: [_currentStamp.shape == 'rectangle', _currentStamp.shape == 'circle'],
                  onPressed: (index) {
                    setState(() {
                      _currentStamp.shape = index == 0 ? 'rectangle' : 'circle';
                    });
                  },
                  children: const [Icon(Icons.crop_square), Icon(Icons.circle_outlined)],
                ),
                SwitchListTile(
                  title: const Text('Negrita'),
                  value: _currentStamp.isBold,
                  onChanged: (value) => setState(() => _currentStamp.isBold = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
