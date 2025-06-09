import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:SpoolScout/screens/filament_detail_screen.dart';

class EditSubmissionScreen extends StatefulWidget {
  final DocumentSnapshot submission;

  EditSubmissionScreen({required this.submission});

  @override
  _EditSubmissionScreenState createState() => _EditSubmissionScreenState();
}

class _EditSubmissionScreenState extends State<EditSubmissionScreen> {
  late TextEditingController typeController;
  late TextEditingController brandController;
  late TextEditingController temperatureController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final Set<String> selectedAttributes = {};

  final List<String> allAttributes = [
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
    'Moisture-sensitive',
  ];

  @override
  void initState() {
    super.initState();
    typeController = TextEditingController(text: widget.submission['type']);
    brandController = TextEditingController(text: widget.submission['brand']);
    temperatureController = TextEditingController(
        text: widget.submission['temperature'].toString());

    // convert attributes to a Set<String>
    if (widget.submission['attributes'] != null) {
      final attributes = widget.submission['attributes'];
      selectedAttributes.addAll(
        attributes is List<dynamic>
            ? attributes.map((e) => e.toString())
            : attributes.toString().split(',').map((e) => e.trim()),
      );
    }
  }

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

  Future<void> _approveSubmission() async {
    final uniqueId =
        FirebaseFirestore.instance.collection('filaments').doc().id;

    try {
      // handle image upload
      String? imageUrl;
      if (_selectedImage != null) {
        final storageRef =
            FirebaseStorage.instance.ref().child('filaments/$uniqueId.jpg');
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      } else {
        imageUrl = widget.submission['imageUrl'];
      }

      // prepare updated data
      final updatedData = {
        'id': uniqueId,
        'type': typeController.text.trim(),
        'brand': brandController.text.trim(),
        'attributes': selectedAttributes.toList(),
        'temperature': int.tryParse(temperatureController.text.trim()) ?? 0,
        'status': 'approved',
        'imageUrl': imageUrl,
      };

      // save the updated filament in Firestore
      await FirebaseFirestore.instance
          .collection('filaments')
          .doc(uniqueId)
          .set(updatedData);

      // delete the original submission
      await widget.submission.reference.delete();

      // now, navigate to FilamentDetailScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FilamentDetailScreen(
            filament: updatedData, // Pass the updated filament data
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Submission approved and added to the database.')),
      );
    } catch (e) {
      // handle errors!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving submission: $e')),
      );
    }
  }

  Future<void> _rejectSubmission() async {
    await widget.submission.reference.update({'status': 'rejected'});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Submission rejected.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/wallpaper.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedImage != null)
                    Image.file(
                      _selectedImage!,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                  else if (widget.submission['imageUrl'] != null)
                    Image.network(
                      widget.submission['imageUrl'],
                      height: 200,
                      fit: BoxFit.cover,
                    )
                  else
                    Text(
                      'No image available',
                      style: TextStyle(
                        color: const Color.fromRGBO(4, 107, 123, 1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: Icon(Icons.photo_library, color: Colors.white),
                    label: Text(
                      'Choose Image',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(4, 107, 123, 1),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _captureImageWithCamera,
                    icon: Icon(Icons.camera, color: Colors.white),
                    label: Text(
                      'Capture Image',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(4, 107, 123, 1),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: typeController,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      labelStyle: TextStyle(
                        color: const Color.fromRGBO(4, 107, 123, 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromRGBO(4, 107, 123, 1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromRGBO(4, 107, 123, 1),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: brandController,
                    decoration: InputDecoration(
                      labelText: 'Brand',
                      labelStyle: TextStyle(
                        color: const Color.fromRGBO(4, 107, 123, 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromRGBO(4, 107, 123, 1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromRGBO(4, 107, 123, 1),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: temperatureController,
                    decoration: InputDecoration(
                      labelText: 'Temperature (°C)',
                      labelStyle: TextStyle(
                        color: const Color.fromRGBO(4, 107, 123, 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromRGBO(4, 107, 123, 1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromRGBO(4, 107, 123, 1),
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Attributes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(4, 107, 123, 1),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: allAttributes.map((attribute) {
                      return ChoiceChip(
                        label: Text(attribute),
                        selected: selectedAttributes.contains(attribute),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedAttributes.add(attribute);
                            } else {
                              selectedAttributes.remove(attribute);
                            }
                          });
                        },
                        selectedColor: const Color.fromRGBO(4, 107, 123, 1),
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: selectedAttributes.contains(attribute)
                              ? Colors.white
                              : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _approveSubmission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      'Approve',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _rejectSubmission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(
                      'Reject',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
