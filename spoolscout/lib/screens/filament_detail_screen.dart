import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class FilamentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> filament;

  const FilamentDetailScreen({Key? key, required this.filament})
      : super(key: key);

  @override
  _FilamentDetailScreenState createState() => _FilamentDetailScreenState();
}

class _FilamentDetailScreenState extends State<FilamentDetailScreen> {
  bool isFavorite = false;
  bool inLibrary = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    if (user == null || widget.filament['id'] == null) return;

    try {
      final favoritesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .doc(widget.filament['id']);

      final libraryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('library')
          .doc(widget.filament['id']);

      final isFavoriteDoc = await favoritesRef.get();
      final inLibraryDoc = await libraryRef.get();

      setState(() {
        isFavorite = isFavoriteDoc.exists;
        inLibrary = inLibraryDoc.exists;
      });
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (user == null || widget.filament['id'] == null) {
      debugPrint('User or filament ID is null');
      return;
    }

    final favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(widget.filament['id']);

    try {
      if (isFavorite) {
        await favoritesRef.delete();
        debugPrint('Removed from favorites: ${widget.filament['id']}');
      } else {
        await favoritesRef.set(widget.filament);
        debugPrint('Added to favorites: ${widget.filament['id']}');
      }

      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> _toggleLibrary() async {
    if (user == null || widget.filament['id'] == null) {
      debugPrint('User or filament ID is null');
      return;
    }

    final libraryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('library')
        .doc(widget.filament['id']);

    try {
      if (inLibrary) {
        await libraryRef.delete();
        debugPrint('Removed from library: ${widget.filament['id']}');
      } else {
        await libraryRef.set(widget.filament);
        debugPrint('Added to library: ${widget.filament['id']}');
      }
      setState(() {
        inLibrary = !inLibrary;
      });
    } catch (e) {
      debugPrint('Error toggling library: $e');
    }
  }

  Widget buildStarRating(double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (rating >= i) {
        stars.add(Icon(Icons.star, color: Colors.amber));
      } else if (rating >= i - 0.5) {
        stars.add(Icon(Icons.star_half, color: Colors.amber));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.amber));
      }
    }
    return Row(children: stars);
  }

  Widget buildAverageRating() {
    final filamentId = widget.filament['id'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('filaments')
          .doc(filamentId)
          .collection('reviews')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              buildStarRating(0), // Placeholder empty stars while loading
              SizedBox(width: 8),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
              ),
            ],
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Row(
            children: [
              buildStarRating(0), // Empty stars for no reviews
              SizedBox(width: 8),
              Text(
                'No reviews yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
              ),
            ],
          );
        }

        final reviews = snapshot.data!.docs;
        final totalRating = reviews.fold<double>(
          0.0,
          (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['rating'] as num).toDouble();
          },
        );
        final averageRating = totalRating / reviews.length;

        return Row(
          children: [
            buildStarRating(averageRating),
            SizedBox(width: 8),
            Text(
              '${averageRating.toStringAsFixed(1)} / 5.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black,
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget buildReviews() {
    final filamentId = widget.filament['id'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('filaments')
          .doc(filamentId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(
            'No reviews yet. Be the first to leave a review!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          );
        }

        final reviews = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index].data() as Map<String, dynamic>;
            return buildReviewCard(review);
          },
        );
      },
    );
  }

  void showReviewDialog(BuildContext context) {
    final TextEditingController reviewController = TextEditingController();
    int selectedRating = 0;
    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black.withOpacity(0.8),
              title: Text(
                'Leave a Review',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                          icon: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Write your review...',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.2),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    if (selectedImage != null)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              File(selectedImage!.path),
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                selectedImage = null;
                              });
                            },
                            icon: Icon(Icons.delete),
                            label: Text('Remove Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            selectedImage = image;
                          });
                        }
                      },
                      icon: Icon(Icons.photo),
                      label: Text('Add a Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.7),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedRating > 0 &&
                        reviewController.text.isNotEmpty) {
                      // Submit the review
                      await submitReview(
                        widget.filament['id'],
                        selectedRating,
                        reviewController.text,
                        selectedImage,
                      );
                      Navigator.pop(context); // Close dialog
                    } else {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please provide a rating and a review!',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(4, 107, 123, 1),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> submitReview(
      String filamentId, int rating, String text, XFile? photo) async {
    String? photoUrl;

    if (photo != null) {
      try {
        final storageRef =
            FirebaseStorage.instance.ref().child('reviews/${photo.name}');
        final uploadTask = await storageRef.putFile(File(photo.path));
        photoUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Error uploading photo: $e');
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'Anonymous';

      await FirebaseFirestore.instance
          .collection('filaments')
          .doc(filamentId)
          .collection('reviews')
          .add({
        'rating': rating.toDouble(), // Ensure rating is stored as double
        'text': text,
        'photoUrl': photoUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': userName,
      });

      setState(() {}); // Refresh the reviews immediately after adding
      debugPrint('Review submitted successfully!');
    } catch (e) {
      debugPrint('Error submitting review: $e');
    }
  }

  Widget buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] is int)
        ? (review['rating'] as int).toDouble()
        : (review['rating'] ?? 0.0) as double;

    return Card(
      color: Colors.black.withOpacity(0.6),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                buildStarRating(rating),
                SizedBox(width: 8),
                Text(
                  review['userName'] ?? 'Anonymous',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (review['photoUrl'] != null)
              Image.network(
                review['photoUrl'],
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            SizedBox(height: 8),
            Text(
              review['text'] ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.filament['type'] ?? 'Filament Details',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/wallpaper.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      widget.filament['imageUrl'] ?? '',
                      height: 400,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported,
                        size: 200,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.filament['type'] ?? 'Unknown Type',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Brand: ${widget.filament['brand'] ?? 'Unknown Brand'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black,
                          ),
                    ),
                    SizedBox(height: 16),
                    buildAverageRating(), // Display dynamic average rating
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Color.fromRGBO(4, 107, 123, 1),
                      ),
                      label: Text(
                        isFavorite
                            ? 'Remove from Favorites'
                            : 'Add to Favorites',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.7),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _toggleLibrary,
                      icon: Icon(
                        inLibrary ? Icons.library_add_check : Icons.library_add,
                        color: Color.fromRGBO(4, 107, 123, 1),
                      ),
                      label: Text(
                        inLibrary ? 'Remove from Library' : 'Add to Library',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.7),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DetailRow(
                            label: 'Weight:',
                            value: '${widget.filament['weight']} g',
                          ),
                          DetailRow(
                            label: 'Optimal Temp:',
                            value: '${widget.filament['temperature']}°C',
                          ),
                          DetailRow(
                            label: 'Price:',
                            value: '\$${widget.filament['price']}',
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Attributes:',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.filament['attributes'] is List
                                ? (widget.filament['attributes'] as List)
                                    .join(', ')
                                : widget.filament['attributes'] ??
                                    'No attributes available.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Reviews',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => showReviewDialog(context),
                      icon: Icon(Icons.add_comment),
                      label: Text('Leave a Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.7),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    buildReviews(),
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
