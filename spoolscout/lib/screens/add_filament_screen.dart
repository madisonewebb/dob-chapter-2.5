import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';

class AddFilamentScreen extends StatefulWidget {
  @override
  _AddFilamentScreenState createState() => _AddFilamentScreenState();
}

class _AddFilamentScreenState extends State<AddFilamentScreen> {
  final TextEditingController priceController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController customBrandController = TextEditingController();
  final TextEditingController customTypeController = TextEditingController();
  final TextEditingController customAttributeController =
      TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _selectedType;
  String? _selectedBrand;

  final FirestoreService firestoreService = FirestoreService();

  final List<String> filamentAttributes = [
    'Tough',
    'Heat-resistant',
    'Impact-resistant',
    'Lightweight',
    'Rigid',
    'Transparent',
    'Opaque',
    'UV-resistant',
    'UV-reactive',
    'Matte',
    'Glossy',
    'Poor adhesion',
    'Good adhesion',
    'Moisture-sensitive'
  ];
  final Set<String> selectedAttributes = {};

  final List<String> filamentTypes = [
    'PLA',
    'ABS',
    'PETG',
    'ASA',
    'Nylon',
    'TPU',
    'Carbon Fiber',
    'Other'
  ];

  final List<String> filamentBrands = [
    'Bambu',
    'Prusa',
    'Overture',
    'Hatchbox',
    'Sunlu',
    'Protopasta',
    'Elegoo',
    'Polymaker',
    'Amazon Basics',
    'Amolen',
    'Anycubic',
    'Creality',
    'Eryone',
    'eSun',
    'Extrudr',
    'Other'
  ];

  String get brand => _selectedBrand == 'Other'
      ? customBrandController.text.trim()
      : _selectedBrand ?? '';

  String get type => _selectedType == 'Other'
      ? customTypeController.text.trim()
      : _selectedType ?? '';

  String get price => priceController.text.trim();

  String get weight => weightController.text.trim();

  String get temperature => temperatureController.text.trim();

  String get attributes =>
      selectedAttributes.join(', ') +
      (customAttributeController.text.isNotEmpty
          ? ', ${customAttributeController.text.trim()}'
          : '');

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _captureImageWithCamera() async {
    final XFile? capturedImage =
        await _picker.pickImage(source: ImageSource.camera);
    if (capturedImage != null) {
      setState(() {
        _selectedImage = File(capturedImage.path);
      });
    }
  }

  void _submitForm() async {
    if (price.isEmpty ||
        weight.isEmpty ||
        temperature.isEmpty ||
        brand.isEmpty ||
        type.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'All required fields (including an image, type, brand, and temperature) must be filled!'),
        ),
      );
      return;
    }

    try {
      await firestoreService.submitFilament(
        brand: brand,
        type: type,
        price: price,
        weight: weight,
        temperature: temperature,
        attributes: attributes,
        imagePath: _selectedImage!.path,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Filament submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend body under the AppBar
      appBar: AppBar(
        title: Text('Add Filament'),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Wallpaper background
          Image.asset(
            'assets/images/wallpaper.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedType = newValue;
                        });
                      },
                      items: filamentTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      decoration: InputDecoration(
                        labelText: 'Filament Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_selectedType == 'Other')
                      TextField(
                        controller: customTypeController,
                        decoration: InputDecoration(
                          labelText: 'Custom Filament Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedBrand,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBrand = newValue;
                        });
                      },
                      items: filamentBrands
                          .map((brand) => DropdownMenuItem(
                                value: brand,
                                child: Text(brand),
                              ))
                          .toList(),
                      decoration: InputDecoration(
                        labelText: 'Filament Brand',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_selectedBrand == 'Other')
                      TextField(
                        controller: customBrandController,
                        decoration: InputDecoration(
                          labelText: 'Custom Filament Brand',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Price (in USD)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: weightController,
                      decoration: InputDecoration(
                        labelText: 'Weight (in grams)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: temperatureController,
                      decoration: InputDecoration(
                        labelText: 'Ideal Temperature (°C)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 24),
                    Text('Filament Attributes (Optional):'),
                    Wrap(
                      spacing: 10,
                      children: filamentAttributes.map((attribute) {
                        final bool isSelected =
                            selectedAttributes.contains(attribute);
                        return FilterChip(
                          label: Text(attribute),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                selectedAttributes.add(attribute);
                              } else {
                                selectedAttributes.remove(attribute);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: customAttributeController,
                      decoration: InputDecoration(
                        labelText: 'Custom Attribute (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_selectedImage != null)
                      Image.file(
                        _selectedImage!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: Icon(Icons.photo_library,
                              color: Color.fromRGBO(4, 107, 123, 1)),
                          label: Text(
                            'Gallery',
                            style: TextStyle(
                                color: Color.fromRGBO(4, 107, 123, 1)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _captureImageWithCamera,
                          icon: Icon(Icons.camera,
                              color: Color.fromRGBO(4, 107, 123, 1)),
                          label: Text(
                            'Camera',
                            style: TextStyle(
                                color: Color.fromRGBO(4, 107, 123, 1)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(4, 107, 123, 1),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Submit Filament'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
