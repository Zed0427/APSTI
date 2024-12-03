// Create a new file called 'image_modal.dart'

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../themes.dart';

class ImageModal extends StatefulWidget {
  final String photoId;
  final Function(String) getUserById;
  final Future<String?> Function() getCurrentUserId;

  const ImageModal({
    Key? key,
    required this.photoId,
    required this.getUserById,
    required this.getCurrentUserId,
  }) : super(key: key);

  @override
  State<ImageModal> createState() => _ImageModalState();
}

class _ImageModalState extends State<ImageModal> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: StreamBuilder<DatabaseEvent>(
            stream: _dbRef.child('gallery/${widget.photoId}').onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final photoData = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map);

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.text),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Caption
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      photoData['caption'] ?? 'No Caption',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Image
                  SizedBox(
                    height: 200, // Fixed height for image
                    child: Image.network(
                      photoData['image'] ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.error));
                      },
                    ),
                  ),

                  // Likes
                  _buildLikesSection(photoData),

                  // Comments
                  Expanded(
                    child: _buildCommentsSection(photoData),
                  ),

                  // Comment Input
                  _buildCommentInput(photoData),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLikesSection(Map<String, dynamic> photoData) {
    return FutureBuilder<String?>(
      future: widget.getCurrentUserId(),
      builder: (context, userSnapshot) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  (photoData['likes_by_user']?[userSnapshot.data] == true)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color:
                      (photoData['likes_by_user']?[userSnapshot.data] == true)
                          ? Colors.red
                          : AppColors.textLight,
                ),
                onPressed: () => _handleLike(photoData, userSnapshot.data),
              ),
              Text(
                '${photoData['likes'] ?? 0} Likes',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsSection(Map<String, dynamic> photoData) {
    return StreamBuilder<DatabaseEvent>(
      stream: _dbRef.child('comments').onValue,
      builder: (context, commentsSnapshot) {
        if (!commentsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<String> commentIds =
            List<String>.from(photoData['comments'] ?? []);

        if (commentIds.isEmpty) {
          return const Center(child: Text('No comments yet'));
        }

        final allComments = commentsSnapshot.data!.snapshot.value as Map?;
        if (allComments == null) {
          return const Center(child: Text('No comments yet'));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: commentIds.length,
          itemBuilder: (context, index) {
            final commentId = commentIds[index];
            final commentData = allComments[commentId];
            if (commentData == null) return const SizedBox.shrink();

            return ListTile(
              title: Text(commentData['text']?.toString() ?? ''),
              subtitle: FutureBuilder(
                future:
                    widget.getUserById(commentData['user']?.toString() ?? ''),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasData) {
                    final userData = userSnapshot.data as Map<String, dynamic>;
                    return Text(
                      userData['name']?.toString() ?? 'Unknown User',
                      style: GoogleFonts.poppins(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const Text('Loading...');
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInput(Map<String, dynamic> photoData) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        top: 16.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.accent),
            onPressed: () => _handleComment(photoData),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLike(
      Map<String, dynamic> photoData, String? userId) async {
    if (userId == null) return;

    try {
      final likes = photoData['likes'] ?? 0;
      final isLiked = photoData['likes_by_user']?[userId] == true;

      if (isLiked) {
        await _dbRef
            .child('gallery/${widget.photoId}/likes_by_user/$userId')
            .remove();
        await _dbRef.child('gallery/${widget.photoId}/likes').set(likes - 1);
      } else {
        await _dbRef
            .child('gallery/${widget.photoId}/likes_by_user/$userId')
            .set(true);
        await _dbRef.child('gallery/${widget.photoId}/likes').set(likes + 1);
      }
    } catch (e) {
      debugPrint('Error handling like: $e');
    }
  }

  Future<void> _handleComment(Map<String, dynamic> photoData) async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final userId = await widget.getCurrentUserId();
      if (userId == null) throw Exception('User not found');

      // Create new comment
      final newCommentRef = _dbRef.child('comments').push();
      await newCommentRef.set({
        'text': _commentController.text.trim(),
        'user': userId,
        'timestamp': ServerValue.timestamp,
      });

      // Update gallery comments
      List<String> currentComments =
          List<String>.from(photoData['comments'] ?? []);
      currentComments.add(newCommentRef.key!);

      await _dbRef
          .child('gallery/${widget.photoId}/comments')
          .set(currentComments);

      _commentController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
