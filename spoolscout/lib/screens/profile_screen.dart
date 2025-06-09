import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'add_filament_screen.dart';
import 'admin_panel_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isAdmin = false;
  File? _profileImage;
  String? _name;
  final TextEditingController _nameController = TextEditingController();
  bool isGoogleLinked = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _loadUserProfile();
    _checkGoogleLinked();
  }

  Future<void> _checkAdminRole() async {
    if (user != null) {
      final idTokenResult = await user!.getIdTokenResult();
      setState(() {
        isAdmin = idTokenResult.claims?['admin'] == true;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _name = data?['nickname'] ?? user!.displayName ?? 'No Name';
          _nameController.text = _name!;
        });
      }
    }
  }

  Future<void> _checkGoogleLinked() async {
    final userProviderData =
        FirebaseAuth.instance.currentUser?.providerData ?? [];
    setState(() {
      isGoogleLinked = userProviderData.any(
          (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID);
    });
  }

  Future<void> _linkGoogleAccount() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.currentUser
          ?.linkWithCredential(googleCredential);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google account linked successfully!')),
      );

      setState(() {
        isGoogleLinked = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error linking Google account: $e')),
      );
    }
  }

  Future<void> _unlinkGoogleAccount() async {
    try {
      await FirebaseAuth.instance.currentUser
          ?.unlink(GoogleAuthProvider.PROVIDER_ID);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google account unlinked successfully!')),
      );

      setState(() {
        isGoogleLinked = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unlinking Google account: $e')),
      );
    }
  }

  Future<void> _saveUserProfile() async {
    if (user != null) {
      final ref = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      await ref
          .set({'nickname': _nameController.text}, SetOptions(merge: true));
      setState(() {
        _name = _nameController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated successfully!')),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: const Color.fromRGBO(37, 150, 190, 1),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/wallpaper.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : AssetImage('assets/images/default_avatar.png')
                                    as ImageProvider),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                      ),
                      onSubmitted: (_) => _saveUserProfile(),
                    ),
                    SizedBox(height: 8),
                    Text(
                      user?.email ?? 'No Email',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color.fromRGBO(
                            37, 150, 190, 1),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: isGoogleLinked
                          ? _unlinkGoogleAccount
                          : _linkGoogleAccount,
                      icon: Image.asset(
                        'assets/images/google-icon.png',
                        height: 24,
                        width: 24,
                      ),
                      label: Text(
                        isGoogleLinked
                            ? 'Unlink Google Account'
                            : 'Link Google Account',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'Logout',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                    
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddFilamentScreen()),
                        );
                      },
                      child: Text(
                        'Add New Filament',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                    if (isAdmin) ...[
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AdminPanelScreen()),
                          );
                        },
                        child: Text(
                          'Admin Panel',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
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
