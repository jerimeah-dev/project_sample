import 'dart:typed_data';

import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/blog_service.dart';
import '../services/storage_service.dart';

class BlogRepository {
  final BlogService blogService;
  final StorageService? storageService;

  BlogRepository(this.blogService, [this.storageService]);

  Future<List<PostModel>> getPosts() async {
    final posts = await blogService.getPosts();

    return posts.map((post) {
      // Parse images from the response
      final images = <String>[];
      if (post['images'] != null) {
        images.addAll(List<String>.from(post['images'] as List));
      }

      return PostModel(
        id: post['id'] as String,
        authorId: post['author_id'] as String,
        authorName: post['author_name'] as String? ?? 'Anonymous',
        authorAvatar: post['author_avatar'] as String?,
        title: post['title'] as String,
        content: post['content'] as String,
        images: images,
        createdAt: DateTime.parse(post['created_at'] as String),
        updatedAt: DateTime.parse(post['updated_at'] as String),
      );
    }).toList();
  }

  Future<PostModel> getPostById(String postId) async {
    final post = await blogService.getPostById(postId);

    final images = <String>[];
    if (post['images'] != null) {
      images.addAll(List<String>.from(post['images'] as List));
    }

    return PostModel(
      id: post['id'] as String,
      authorId: post['author_id'] as String,
      authorName: post['author_name'] as String? ?? 'Anonymous',
      authorAvatar: post['author_avatar'] as String?,
      title: post['title'] as String,
      content: post['content'] as String,
      images: images,
      createdAt: DateTime.parse(post['created_at'] as String),
      updatedAt: DateTime.parse(post['updated_at'] as String),
    );
  }

  Future<PostModel> createPost({
    required String authorId,
    required String title,
    required String content,
  }) async {
    if (title.isEmpty || content.isEmpty) {
      throw Exception('Title and content are required');
    }

    final response = await blogService.createPost(
      authorId: authorId,
      title: title,
      content: content,
    );

    // If there are images attached via storageService, they should be added
    // by the caller after creating the post. For convenience, return the
    // post model without images; callers (notifier) can attach images.
    return PostModel(
      id: response['id'] as String,
      authorId: response['author_id'] as String,
      authorName: response.containsKey('author_name')
          ? response['author_name'] as String
          : 'Anonymous',
      title: response['title'] as String,
      content: response['content'] as String,
      images: [],
      createdAt: DateTime.parse(response['created_at'] as String),
      updatedAt: DateTime.parse(response['updated_at'] as String),
    );
  }

  Future<PostModel> updatePost({
    required String postId,
    required String title,
    required String content,
  }) async {
    if (title.isEmpty || content.isEmpty) {
      throw Exception('Title and content are required');
    }

    final response = await blogService.updatePost(
      postId: postId,
      title: title,
      content: content,
    );

    final images = <String>[];
    if (response['images'] != null) {
      images.addAll(List<String>.from(response['images'] as List));
    }

    return PostModel(
      id: response['id'] as String,
      authorId: response['author_id'] as String,
      authorName: response['author_name'] as String? ?? 'Anonymous',
      authorAvatar: response['author_avatar'] as String?,
      title: response['title'] as String,
      content: response['content'] as String,
      images: images,
      createdAt: DateTime.parse(response['created_at'] as String),
      updatedAt: DateTime.parse(response['updated_at'] as String),
    );
  }

  Future<void> deletePost(String postId) async {
    await blogService.deletePost(postId);
  }

  Future<List<CommentModel>> getCommentsByPostId(String postId) async {
    final comments = await blogService.getCommentsByPostId(postId);

    return comments.map((comment) {
      final images = <String>[];
      if (comment['images'] != null) {
        images.addAll(List<String>.from(comment['images'] as List));
      }

      return CommentModel(
        id: comment['id'] as String,
        postId: comment['post_id'] as String,
        authorId: comment['author_id'] as String,
        authorName: comment['author_name'] as String? ?? 'Anonymous',
        authorAvatar: comment['author_avatar'] as String?,
        content: comment['content'] as String,
        images: images,
        createdAt: DateTime.parse(comment['created_at'] as String),
        updatedAt: DateTime.parse(comment['updated_at'] as String),
      );
    }).toList();
  }

  Future<CommentModel> createComment({
    required String postId,
    required String authorId,
    required String content,
  }) async {
    if (content.isEmpty) {
      throw Exception('Comment content is required');
    }

    final response = await blogService.createComment(
      postId: postId,
      authorId: authorId,
      content: content,
    );

    return CommentModel(
      id: response['id'] as String,
      postId: response['post_id'] as String,
      authorId: response['author_id'] as String,
      authorName: response.containsKey('author_name')
          ? response['author_name'] as String
          : 'Anonymous',
      content: response['content'] as String,
      images: [],
      createdAt: DateTime.parse(response['created_at'] as String),
      updatedAt: DateTime.parse(response['updated_at'] as String),
    );
  }

  Future<CommentModel> updateComment({
    required String commentId,
    required String content,
  }) async {
    if (content.isEmpty) {
      throw Exception('Comment content is required');
    }

    final response = await blogService.updateComment(
      commentId: commentId,
      content: content,
    );

    final images = <String>[];
    if (response['images'] != null) {
      images.addAll(List<String>.from(response['images'] as List));
    }

    return CommentModel(
      id: response['id'] as String,
      postId: response['post_id'] as String,
      authorId: response['author_id'] as String,
      authorName: response['author_name'] as String? ?? 'Anonymous',
      authorAvatar: response['author_avatar'] as String?,
      content: response['content'] as String,
      images: images,
      createdAt: DateTime.parse(response['created_at'] as String),
      updatedAt: DateTime.parse(response['updated_at'] as String),
    );
  }

  Future<void> deleteComment(String commentId) async {
    await blogService.deleteComment(commentId);
  }

  // ----- Higher-level operations that orchestrate storage + DB -----
  Future<PostModel> createPostWithImages({
    required String authorId,
    required String title,
    required String content,
    List<Uint8List>? imageBytes,
    List<String>? fileNames,
  }) async {
    final post = await createPost(
      authorId: authorId,
      title: title,
      content: content,
    );

    if (imageBytes != null && imageBytes.isNotEmpty) {
      if (storageService == null) {
        throw Exception('StorageService required to upload images');
      }

      for (var i = 0; i < imageBytes.length; i++) {
        final name = (fileNames != null && i < fileNames.length)
            ? fileNames[i]
            : 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await storageService!.uploadPostImage(
          post.id,
          imageBytes[i],
          name,
        );
        await blogService.addPostImage(postId: post.id, url: url);
      }
    }

    // Return fresh post with images
    return getPostById(post.id);
  }

  Future<PostModel> updatePostWithImageChanges({
    required String postId,
    required String title,
    required String content,
    List<String>? deleteImageIds,
    List<String>? deleteImageUrls,
    List<Uint8List>? addImageBytes,
    List<String>? addFileNames,
  }) async {
    // Delete DB records and storage for images flagged for deletion
    if ((deleteImageIds != null && deleteImageIds.isNotEmpty) ||
        (deleteImageUrls != null && deleteImageUrls.isNotEmpty)) {
      // If ids provided, delete by id
      if (deleteImageIds != null) {
        for (final id in deleteImageIds) {
          // fetch the image record to get the url (optional)
          await blogService.deletePostImage(id);
        }
      }

      // If URLs provided, attempt to delete corresponding DB rows by finding images
      if (deleteImageUrls != null && deleteImageUrls.isNotEmpty) {
        // No direct API to delete by URL; assume caller will pass ids when possible.
        for (final url in deleteImageUrls) {
          // Try to extract filename and remove from storage as best-effort
          if (storageService != null) {
            try {
              final parts = url.split('/');
              final fileName = parts.isNotEmpty ? parts.last : null;
              if (fileName != null) {
                await storageService!.deletePostImage(postId, fileName);
              }
            } catch (_) {}
          }
        }
      }
    }

    // Add new images
    if (addImageBytes != null && addImageBytes.isNotEmpty) {
      if (storageService == null) {
        throw Exception('StorageService required to upload images');
      }

      for (var i = 0; i < addImageBytes.length; i++) {
        final name = (addFileNames != null && i < addFileNames.length)
            ? addFileNames[i]
            : 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await storageService!.uploadPostImage(
          postId,
          addImageBytes[i],
          name,
        );
        await blogService.addPostImage(postId: postId, url: url);
      }
    }

    // Update post fields
    return updatePost(postId: postId, title: title, content: content);
  }

  Future<CommentModel> createCommentWithImages({
    required String postId,
    required String authorId,
    required String content,
    List<Uint8List>? imageBytes,
    List<String>? fileNames,
  }) async {
    final comment = await createComment(
      postId: postId,
      authorId: authorId,
      content: content,
    );

    if (imageBytes != null && imageBytes.isNotEmpty) {
      if (storageService == null) {
        throw Exception('StorageService required to upload images');
      }

      for (var i = 0; i < imageBytes.length; i++) {
        final name = (fileNames != null && i < fileNames.length)
            ? fileNames[i]
            : 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await storageService!.uploadCommentImage(
          comment.id,
          imageBytes[i],
          name,
        );
        await blogService.addCommentImage(commentId: comment.id, url: url);
      }
    }

    return blogService.getCommentsByPostId(postId).then((_) async {
      // Return fresh comment by refetching comments and finding the created one
      final comments = await getCommentsByPostId(postId);
      return comments.firstWhere((c) => c.id == comment.id);
    });
  }

  Future<CommentModel> updateCommentWithImageChanges({
    required String commentId,
    required String content,
    List<String>? deleteImageIds,
    List<String>? deleteImageUrls,
    List<Uint8List>? addImageBytes,
    List<String>? addFileNames,
  }) async {
    // Delete image DB rows and storage as above
    if ((deleteImageIds != null && deleteImageIds.isNotEmpty) ||
        (deleteImageUrls != null && deleteImageUrls.isNotEmpty)) {
      if (deleteImageIds != null) {
        for (final id in deleteImageIds) {
          await blogService.deleteCommentImage(id);
        }
      }

      if (deleteImageUrls != null &&
          deleteImageUrls.isNotEmpty &&
          storageService != null) {
        for (final url in deleteImageUrls) {
          try {
            final parts = url.split('/');
            final fileName = parts.isNotEmpty ? parts.last : null;
            if (fileName != null) {
              await storageService!.deleteCommentImage(commentId, fileName);
            }
          } catch (_) {}
        }
      }
    }

    // Add new images
    if (addImageBytes != null && addImageBytes.isNotEmpty) {
      if (storageService == null) {
        throw Exception('StorageService required to upload images');
      }

      for (var i = 0; i < addImageBytes.length; i++) {
        final name = (addFileNames != null && i < addFileNames.length)
            ? addFileNames[i]
            : 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await storageService!.uploadCommentImage(
          commentId,
          addImageBytes[i],
          name,
        );
        await blogService.addCommentImage(commentId: commentId, url: url);
      }
    }

    return updateComment(commentId: commentId, content: content);
  }
}
