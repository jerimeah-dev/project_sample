import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../repositories/blog_repository.dart';

class BlogNotifier extends ChangeNotifier {
  final BlogRepository _blogRepository;

  List<PostModel> _posts = [];
  PostModel? _currentPost;
  List<CommentModel> _currentPostComments = [];

  bool _isLoadingPosts = false;
  bool _isLoadingComments = false;
  bool _isLoadingPostDetail = false;

  String? _error;

  BlogNotifier(this._blogRepository);

  // Getters
  List<PostModel> get posts => _posts;
  PostModel? get currentPost => _currentPost;
  List<CommentModel> get currentPostComments => _currentPostComments;

  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingComments => _isLoadingComments;
  bool get isLoadingPostDetail => _isLoadingPostDetail;

  String? get error => _error;

  Future<void> loadPosts() async {
    _isLoadingPosts = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await _blogRepository.getPosts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<void> loadPostDetail(String postId) async {
    _isLoadingPostDetail = true;
    _error = null;
    notifyListeners();

    try {
      _currentPost = await _blogRepository.getPostById(postId);
      await loadComments(postId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingPostDetail = false;
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String authorId,
    required String title,
    required String content,
    List<Uint8List>? imageBytes,
    List<String>? fileNames,
  }) async {
    _error = null;

    try {
      final newPost = await _blogRepository.createPostWithImages(
        authorId: authorId,
        title: title,
        content: content,
        imageBytes: imageBytes,
        fileNames: fileNames,
      );

      _posts.insert(0, newPost);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> updatePost({
    required String postId,
    required String title,
    required String content,
    List<String>? deleteImageIds,
    List<String>? deleteImageUrls,
    List<Uint8List>? addImageBytes,
    List<String>? addFileNames,
  }) async {
    _error = null;

    try {
      final updatedPost = await _blogRepository.updatePostWithImageChanges(
        postId: postId,
        title: title,
        content: content,
        deleteImageIds: deleteImageIds,
        deleteImageUrls: deleteImageUrls,
        addImageBytes: addImageBytes,
        addFileNames: addFileNames,
      );

      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
      }

      if (_currentPost?.id == postId) {
        _currentPost = updatedPost;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    _error = null;

    try {
      await _blogRepository.deletePost(postId);

      _posts.removeWhere((p) => p.id == postId);
      if (_currentPost?.id == postId) {
        _currentPost = null;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> loadComments(String postId) async {
    _isLoadingComments = true;
    _error = null;
    notifyListeners();

    try {
      _currentPostComments = await _blogRepository.getCommentsByPostId(postId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingComments = false;
      notifyListeners();
    }
  }

  Future<void> createComment({
    required String postId,
    required String authorId,
    required String content,
    List<Uint8List>? imageBytes,
    List<String>? fileNames,
  }) async {
    _error = null;

    try {
      final newComment = await _blogRepository.createCommentWithImages(
        postId: postId,
        authorId: authorId,
        content: content,
        imageBytes: imageBytes,
        fileNames: fileNames,
      );

      _currentPostComments.add(newComment);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> updateComment({
    required String commentId,
    required String content,
    List<String>? deleteImageIds,
    List<String>? deleteImageUrls,
    List<Uint8List>? addImageBytes,
    List<String>? addFileNames,
  }) async {
    _error = null;

    try {
      final updatedComment = await _blogRepository
          .updateCommentWithImageChanges(
            commentId: commentId,
            content: content,
            deleteImageIds: deleteImageIds,
            deleteImageUrls: deleteImageUrls,
            addImageBytes: addImageBytes,
            addFileNames: addFileNames,
          );

      final index = _currentPostComments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        _currentPostComments[index] = updatedComment;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    _error = null;

    try {
      await _blogRepository.deleteComment(commentId);

      _currentPostComments.removeWhere((c) => c.id == commentId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentPost() {
    _currentPost = null;
    _currentPostComments = [];
    notifyListeners();
  }
}
