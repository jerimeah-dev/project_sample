import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../notifiers/auth_notifier.dart';
import '../../../notifiers/blog_notifier.dart';
import '../../../ui/common/widgets/app_image.dart';
import 'package:file_picker/file_picker.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  List<Uint8List> _commentImageBytes = [];
  List<String> _commentImageNames = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlogNotifier>().loadPostDetail(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleAddComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      final authNotifier = context.read<AuthNotifier>();
      final blogNotifier = context.read<BlogNotifier>();

      if (authNotifier.currentUser == null) {
        throw Exception('User not logged in');
      }

      await blogNotifier.createComment(
        postId: widget.postId,
        authorId: authNotifier.currentUser!.id,
        content: _commentController.text,
        imageBytes: _commentImageBytes.isNotEmpty ? _commentImageBytes : null,
        fileNames: _commentImageNames.isNotEmpty ? _commentImageNames : null,
      );

      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _handleDeletePost() async {
    try {
      final blogNotifier = context.read<BlogNotifier>();

      await blogNotifier.deletePost(widget.postId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          Consumer2<AuthNotifier, BlogNotifier>(
            builder: (context, authNotifier, blogNotifier, _) {
              final isAuthor =
                  authNotifier.currentUser?.id ==
                  blogNotifier.currentPost?.authorId;

              if (!isAuthor) return const SizedBox.shrink();

              return PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Edit'),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditPostScreen(post: blogNotifier.currentPost!),
                          ),
                        );
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('Delete'),
                    onTap: _handleDeletePost,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<BlogNotifier>(
        builder: (context, blogNotifier, _) {
          if (blogNotifier.isLoadingPostDetail) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                margin: const EdgeInsets.all(16),
                height: 200,
                color: Colors.white,
              ),
            );
          }

          final post = blogNotifier.currentPost;
          if (post == null) {
            return const Center(child: Text('Post not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author info
                      Row(
                        children: [
                          if (post.authorAvatar != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: AppImage(
                                url: post.authorAvatar!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade300,
                              ),
                              child: const Icon(Icons.person),
                            ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                post.createdAt.toString().split('.')[0],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Content
                      Text(
                        post.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Images
                if (post.images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppImage(
                              url: post.images[index],
                              width: 300,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(),
                // Comments section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Add comment
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    allowMultiple: true,
                                    type: FileType.image,
                                    withData: true,
                                  );
                              if (result != null) {
                                setState(() {
                                  for (final f in result.files) {
                                    if (f.bytes != null) {
                                      _commentImageBytes.add(f.bytes!);
                                      _commentImageNames.add(f.name);
                                    }
                                  }
                                });
                              }
                            },
                            icon: const Icon(Icons.image),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _handleAddComment,
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                      if (_commentImageBytes.isNotEmpty)
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _commentImageBytes.length,
                            itemBuilder: (context, i) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      _commentImageBytes[i],
                                      width: 100,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _commentImageBytes.removeAt(i);
                                            _commentImageNames.removeAt(i);
                                          });
                                        },
                                        child: Container(
                                          color: Colors.black54,
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Comments list
                      if (blogNotifier.isLoadingComments)
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(height: 100, color: Colors.white),
                        )
                      else if (blogNotifier.currentPostComments.isEmpty)
                        const Text('No comments yet')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: blogNotifier.currentPostComments.length,
                          itemBuilder: (context, index) {
                            final comment =
                                blogNotifier.currentPostComments[index];

                            return CommentTile(
                              comment: comment,
                              canEdit:
                                  context
                                      .read<AuthNotifier>()
                                      .currentUser
                                      ?.id ==
                                  comment.authorId,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CommentTile extends StatefulWidget {
  final dynamic comment;
  final bool canEdit;

  const CommentTile({super.key, required this.comment, required this.canEdit});

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  late TextEditingController _editController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _handleUpdateComment() async {
    try {
      await context.read<BlogNotifier>().updateComment(
        commentId: widget.comment.id,
        content: _editController.text,
      );

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _handleDeleteComment() async {
    try {
      await context.read<BlogNotifier>().deleteComment(widget.comment.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (widget.comment.authorAvatar != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AppImage(
                      url: widget.comment.authorAvatar!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                    ),
                    child: const Icon(Icons.person, size: 16),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comment.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.comment.createdAt.toString().split('.')[0],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.canEdit)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: _handleDeleteComment,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Content
            if (_isEditing)
              Column(
                children: [
                  TextField(
                    controller: _editController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleUpdateComment,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              )
            else
              Text(
                widget.comment.content,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
              ),
            // Images
            if (widget.comment.images.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.comment.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: AppImage(
                          url: widget.comment.images[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
