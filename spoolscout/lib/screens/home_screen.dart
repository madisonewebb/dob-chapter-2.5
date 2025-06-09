import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'filtered_filaments_screen.dart';
import 'filament_detail_screen.dart';
import 'profile_screen.dart';
import '../widgets/badge_icon.dart';
import 'dart:math';

class HomeScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

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
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              height: 48,
                              width: 48,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Home',
                              style: TextStyle(
                                fontFamily: 'ChickenWonder',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromRGBO(4, 107, 123, 1),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : const AssetImage(
                                        'assets/images/default_avatar.png')
                                    as ImageProvider,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // categories section
                  sectionHeader('Categories'),
                  horizontalBadgeList(
                    labels: [
                      'Tough',
                      'Heat-resistant',
                      'Impact-resistant',
                      'Lightweight',
                      'Rigid',
                      'Trans-  parent',
                      'Opaque',
                      'UV-  resistant',
                      'UV-    reactive',
                      'Matte',
                      'Glossy',
                      'Good Adhesion'
                    ],
                    context: context,
                    filterType: 'attribute',
                  ),

                  // popular brands section
                  sectionHeader('Popular Brands'),
                  horizontalBadgeList(
                    labels: [
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
                      'Esun',
                      'Extrudr'
                    ],
                    context: context,
                    filterType: 'brand',
                  ),

                  // popular filament types section
                  sectionHeader('Popular Filament Types'),
                  horizontalBadgeList(
                    labels: [
                      'PLA',
                      'ABS',
                      'PETG',
                      'TPU',
                      'Nylon',
                      'Carbon   Fiber',
                      'ASA',
                    ],
                    context: context,
                    filterType: 'type',
                  ),

                  // favorites Section
                  sectionHeader('Favorites'),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('favorites')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final favorites = snapshot.data?.docs ?? [];
                      if (favorites.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'No favorited filaments... yet!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }
                      return horizontalImageBadgeList(
                        context: context,
                        filaments: favorites
                            .map((doc) => doc.data() as Map<String, dynamic>)
                            .toList(),
                      );
                    },
                  ),

                  // "My Filaments" section
                  sectionHeader('My Filaments'),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('library')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final library = snapshot.data?.docs ?? [];
                      if (library.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'No filaments in library.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }
                      return horizontalImageBadgeList(
                        context: context,
                        filaments: library
                            .map((doc) => doc.data() as Map<String, dynamic>)
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'ChickenWonder',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color.fromRGBO(4, 107, 123, 1),
        ),
      ),
    );
  }

  Widget horizontalBadgeList({
    required List<String> labels,
    required BuildContext context,
    required String filterType,
  }) {
    final List<Color> randomColors = List.generate(
      labels.length,
      (index) => _generateRandomColor(),
    );

    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: labels.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilteredFilamentsScreen(
                    filter: label,
                    filterType: filterType,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: BadgeWidget(
                label: label,
                backgroundColor: randomColors[index],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Random Color Generator
  Color _generateRandomColor() {
    final List<Color> predefinedColors = [
      const Color.fromRGBO(249, 65, 68, 1),
      const Color.fromRGBO(243, 114, 44, 1),
      const Color.fromRGBO(248, 150, 30, 1),
      const Color.fromRGBO(249, 132, 74, 1),
      const Color.fromRGBO(249, 199, 79, 1),
      const Color.fromRGBO(144, 190, 109, 1),
      const Color.fromRGBO(67, 170, 139, 1),
      const Color.fromRGBO(77, 144, 142, 1),
      const Color.fromRGBO(87, 117, 144, 1),
      const Color.fromRGBO(39, 125, 161, 1),
    ];
    final Random random = Random();
    return predefinedColors[random.nextInt(predefinedColors.length)];
  }

  Widget horizontalImageBadgeList({
    required BuildContext context,
    required List<Map<String, dynamic>> filaments,
  }) {
    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filaments.map((filament) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FilamentDetailScreen(filament: filament),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 135,
                  height: 135,
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(135, 135),
                        painter: SolidCirclePainter(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      ),
                      CustomPaint(
                        size: const Size(135, 135),
                        painter: DashedCirclePainter(
                          color: Colors.black,
                          strokeWidth: 2,
                          dashLength: 5,
                          radiusFactor: 0.85,
                        ),
                      ),
                      ClipOval(
                        child: Image.network(
                          filament['imageUrl'],
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 120,
                  child: Text(
                    filament['brand'] ?? 'Unknown',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: const Color.fromRGBO(4, 107, 123, 1),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
