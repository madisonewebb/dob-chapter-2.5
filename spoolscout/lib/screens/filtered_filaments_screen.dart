import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'filament_detail_screen.dart';

class FilteredFilamentsScreen extends StatelessWidget {
  final String filter;
  final String filterType; // Added filterType to support different filters

  const FilteredFilamentsScreen({
    Key? key,
    required this.filter,
    required this.filterType,
  }) : super(key: key);

  Stream<QuerySnapshot> getStreamBasedOnFilterType() {
    final collection =
        FirebaseFirestore.instance.collection('approvedFilaments');

    if (filterType == 'attribute') {
      return collection.where('attributes', arrayContains: filter).snapshots();
    } else if (filterType == 'brand') {
      return collection.where('brand', isEqualTo: filter).snapshots();
    } else if (filterType == 'type') {
      return collection.where('type', isEqualTo: filter).snapshots();
    } else {
      throw ArgumentError('Invalid filterType: $filterType');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('$filter ($filterType)'), // Updated title to show filterType
        backgroundColor: const Color.fromRGBO(4, 107, 123, 1),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getStreamBasedOnFilterType(), // Use dynamic filtering logic
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No filaments match this filter.'));
          }

          final filaments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: filaments.length,
            itemBuilder: (context, index) {
              final filament = filaments[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: ClipOval(
                  child: Image.network(
                    filament['imageUrl'] ?? '',
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
                title: Text(filament['type'] ?? 'Unknown Type'),
                subtitle: Text(filament['brand'] ?? 'Unknown Brand'),
                trailing: Text('${filament['temperature']}°C'),
                onTap: () {
                  // Navigate to FilamentDetailScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FilamentDetailScreen(filament: filament),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
