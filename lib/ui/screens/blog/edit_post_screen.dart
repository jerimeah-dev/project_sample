import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../models/post_model.dart';
import '../../../notifiers/blog_notifier.dart';
import '../../../ui/common/widgets/app_image.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();

  List<String> _existingImageUrls = [];
  List<String> _removedImageUrls = [];

  List<Uint8List> _newImageBytes = [];
  List<String> _newImageNames = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _existingImageUrls = List.from(widget.post.images);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickNewImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      for (final f in result.files) {
        if (f.bytes != null) {
          setState(() {
            _newImageBytes.add(f.bytes!);
            _newImageNames.add(f.name);
          });
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<BlogNotifier>().updatePost(
        postId: widget.post.id,
        title: _titleController.text,
        content: _contentController.text,
        deleteImageUrls: _removedImageUrls,
        addImageBytes: _newImageBytes,
        addFileNames: _newImageNames,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post updated')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Title required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 6,
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Content required' : null,
                ),
                const SizedBox(height: 12),
                // existing images
                if (_existingImageUrls.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: _existingImageUrls.map((url) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: AppImage(
                              url: url,
                              width: 100,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _existingImageUrls.remove(url);
                                  _removedImageUrls.add(url);
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
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _pickNewImages,
                  icon: const Icon(Icons.image),
                  label: const Text('Add images'),
                ),
                if (_newImageBytes.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _newImageBytes.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(
                            _newImageBytes[i],
                            width: 120,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
