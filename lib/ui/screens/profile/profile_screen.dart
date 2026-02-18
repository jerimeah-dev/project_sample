import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../common/widgets/app_image.dart';
import '../../../notifiers/auth_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  Uint8List? _avatarBytes;
  String? _avatarFileName;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _avatarBytes = file.bytes;
        _avatarFileName = file.name;
      });
    }
  }

  Future<void> _save() async {
    final auth = context.read<AuthNotifier>();
    try {
      await auth.updateProfile(
        displayName: _displayNameController.text.isEmpty
            ? null
            : _displayNameController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        avatarBytes: _avatarBytes,
        avatarFileName: _avatarFileName,
      );
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.currentUser;

    _displayNameController.text = user?.displayName ?? '';
    _bioController.text = user?.bio ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 48,
                child: user?.avatarUrl == null && _avatarBytes == null
                    ? const Icon(Icons.person, size: 48)
                    : _avatarBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _avatarBytes!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      )
                    : AppImage(
                        url: user!.avatarUrl ?? '',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        radius: BorderRadius.circular(48),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            auth.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
