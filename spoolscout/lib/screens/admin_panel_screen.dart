import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_submission_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  void approveFilament(BuildContext context, String id) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('submittedFilaments').doc(id);

      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        final filamentData = docSnapshot.data() as Map<String, dynamic>;

        // generate a unique ID for the approved filament
        final uniqueId =
            FirebaseFirestore.instance.collection('approvedFilaments').doc().id;

        // add the unique ID to the filament's data
        filamentData['id'] = uniqueId;

        await FirebaseFirestore.instance
            .collection('approvedFilaments')
            .doc(uniqueId)
            .set(filamentData);

        // delete the original submission
        await docRef.delete();

        // show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filament approved successfully!')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving filament: $error')),
      );
    }
  }

  void rejectFilament(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('submittedFilaments')
          .doc(id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Filament rejected successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting filament: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/wallpaper.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('submittedFilaments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No filaments to review.'));
                }

                final submittedFilaments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: submittedFilaments.length,
                  itemBuilder: (context, index) {
                    final filament = submittedFilaments[index].data()
                        as Map<String, dynamic>;
                    final id = submittedFilaments[index].id;

                    final attributes = filament['attributes'];
                    final attributeList = attributes is List
                        ? attributes
                        : attributes?.split(',').map((e) => e.trim()).toList();

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(filament['type'] ?? 'Unknown Type'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Brand: ${filament['brand'] ?? 'Unknown Brand'}'),
                            Text(
                                'Attributes: ${attributeList != null ? attributeList.join(', ') : 'None'}'),
                            if (filament['temperature'] != null)
                              Text('Ideal Temp: ${filament['temperature']}°C'),
                            if (filament['imageUrl'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Image.network(
                                  filament['imageUrl'],
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditSubmissionScreen(
                                      submission: submittedFilaments[index],
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () => approveFilament(context, id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => rejectFilament(context, id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
