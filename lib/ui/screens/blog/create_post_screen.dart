import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../notifiers/auth_notifier.dart';
import '../../../notifiers/blog_notifier.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Uint8List> _imageBytes = [];
  List<String> _imageNames = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleCreatePost() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authNotifier = context.read<AuthNotifier>();
      final blogNotifier = context.read<BlogNotifier>();

      if (authNotifier.currentUser == null) {
        throw Exception('User not logged in');
      }

      await blogNotifier.createPost(
        authorId: authNotifier.currentUser!.id,
        title: _titleController.text,
        content: _contentController.text,
        imageBytes: _imageBytes,
        fileNames: _imageNames,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
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
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Content is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.image,
                        withData: true,
                      );
                      if (result != null) {
                        setState(() {
                          for (final f in result.files) {
                            if (f.bytes != null) {
                              _imageBytes.add(f.bytes!);
                              _imageNames.add(f.name);
                            }
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Add images'),
                  ),
                ),
                if (_imageBytes.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageBytes.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.memory(
                                _imageBytes[index],
                                width: 120,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageBytes.removeAt(index);
                                    _imageNames.removeAt(index);
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                Consumer<BlogNotifier>(
                  builder: (context, blogNotifier, _) {
                    return ElevatedButton(
                      onPressed: _handleCreatePost,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Create Post'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
