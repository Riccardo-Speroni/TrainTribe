// Removed unused dart:typed_data import
import 'dart:io' show File; // For FileImage on non-web
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';

/// Encapsulates the result of a profile image selection.
class ProfileImageSelection {
  final XFile? pickedFile; // Raw picked image (not uploaded yet)
  final String? generatedAvatarUrl; // DiceBear (or other) avatar URL selected
  final bool removed; // User requested removal

  const ProfileImageSelection({this.pickedFile, this.generatedAvatarUrl, this.removed = false});

  bool get hasImage => pickedFile != null || generatedAvatarUrl != null;
}

typedef OnProfileImageSelection = Future<void> Function(ProfileImageSelection selection);

/// Reusable profile picture picker: shows current picture (or initials) and opens a dialog
/// to pick from gallery, generate avatars, select one, or remove the existing picture.
class ProfilePicturePicker extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? initialImageUrl; // Existing image URL or initials placeholder
  final double size;
  final OnProfileImageSelection onSelection;

  /// Seed override for avatar generation (defaults to username or 'user').
  final String? seedOverride;

  const ProfilePicturePicker({
    super.key,
    this.firstName,
    this.lastName,
    this.username,
    this.initialImageUrl,
    required this.onSelection,
    this.size = 70,
    this.seedOverride,
  });

  @override
  State<ProfilePicturePicker> createState() => _ProfilePicturePickerState();
}

class _ProfilePicturePickerState extends State<ProfilePicturePicker> {
  // Dialog state
  int _avatarPage = 1;
  List<String> _avatarUrls = [];
  bool _loadingAvatars = false;
  String? _selectedGeneratedAvatar;
  XFile? _pickedFile; // For preview before parent uploads

  Future<void> _generateAvatars({bool nextPage = false}) async {
    final base = (widget.seedOverride ?? widget.username ?? widget.firstName ?? 'user').trim();
    if (base.isEmpty) return; // nothing to seed with
    setState(() { _loadingAvatars = true; if (!nextPage) _avatarUrls = []; });
    await Future.delayed(const Duration(milliseconds: 50));
    setState(() {
      if (nextPage) {
        _avatarPage++;
      } else {
        _avatarPage = 1;
      }
      _avatarUrls = List.generate(10, (i) {
        final seed = '$base${(_avatarPage - 1) * 10 + i + 1}';
        return 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=$seed&backgroundType=gradientLinear,solid';
      });
      _loadingAvatars = false;
    });
  }

  Future<void> _pickImage(AppLocalizations l) async {
    XFile? picked;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        picked = XFile(result.files.single.path!);
      }
    } else {
      final picker = ImagePicker();
      picked = await picker.pickImage(source: ImageSource.gallery);
    }
    if (picked == null) return;
    setState(() {
      _pickedFile = picked;
      _selectedGeneratedAvatar = null; // clear avatar selection
    });
    await widget.onSelection(ProfileImageSelection(pickedFile: picked));
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _removeImage() async {
    setState(() { _pickedFile = null; _selectedGeneratedAvatar = null; });
    await widget.onSelection(const ProfileImageSelection(removed: true));
    if (mounted) Navigator.of(context).maybePop();
  }

  void _showDialog(AppLocalizations l) {
    _selectedGeneratedAvatar = null;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool showAvatarPicker = false;
        return StatefulBuilder(
          builder: (ctx, setStateLocal) {
            Widget body;
            if (!showAvatarPicker) {
              body = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: Text(l.translate('pick_image')),
                    onTap: () => _pickImage(l),
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: Text(l.translate('generate_avatars')),
                    onTap: () async {
                      setStateLocal(() { showAvatarPicker = true; });
                      await _generateAvatars();
                      if (mounted) setStateLocal(() {});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(l.translate('remove_image')),
                    onTap: _removeImage,
                  ),
                ],
              );
            } else {
              body = SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loadingAvatars)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      if (_avatarUrls.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('—', style: Theme.of(context).textTheme.bodySmall),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _avatarUrls.length,
                          itemBuilder: (c, i) {
                            final url = _avatarUrls[i];
                            final selected = _selectedGeneratedAvatar == url;
                            return InkWell(
                              onTap: () {
                                setStateLocal(() { _selectedGeneratedAvatar = url; _pickedFile = null; });
                              },
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                          width: 3,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: CircleAvatar(backgroundImage: NetworkImage(url)),
                                    ),
                                  ),
                                  if (selected)
                                    const Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    )
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () async { await _generateAvatars(nextPage: true); setStateLocal(() {}); },
                            child: Text(l.translate('more')),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () { setStateLocal(() { showAvatarPicker = false; }); },
                            child: Text(l.translate('back')),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _selectedGeneratedAvatar == null ? null : () async {
                              final chosen = _selectedGeneratedAvatar!;
                              await widget.onSelection(ProfileImageSelection(generatedAvatarUrl: chosen));
                              if (mounted) Navigator.of(dialogCtx).pop();
                            },
                            child: Text(l.translate('save')),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }
            return AlertDialog(
              title: Text(l.translate('choose_profile_picture')),
              content: body,
              actions: [
                if (!showAvatarPicker)
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: Text(l.translate('cancel')),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
  final displayImageProvider = _pickedFile != null
    ? (_pickedFile!.path.isNotEmpty && !kIsWeb ? FileImage(File(_pickedFile!.path)) as ImageProvider : NetworkImage(_pickedFile!.path))
        : (_selectedGeneratedAvatar != null
            ? NetworkImage(_selectedGeneratedAvatar!)
            : (widget.initialImageUrl != null && widget.initialImageUrl!.startsWith('http')
                ? NetworkImage(widget.initialImageUrl!)
                : null));

    // Fallback initials
    final initials = ((widget.firstName?.isNotEmpty ?? false) && (widget.lastName?.isNotEmpty ?? false))
        ? '${widget.firstName![0]}${widget.lastName![0]}'
        : (widget.username?.isNotEmpty ?? false)
            ? widget.username![0]
            : '?';

    return InkWell(
      onTap: () => _showDialog(l),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: widget.size / 2,
            backgroundImage: displayImageProvider,
            backgroundColor: Colors.teal,
            child: displayImageProvider == null
                ? Text(
                    initials.toUpperCase(),
                    style: TextStyle(fontSize: widget.size / 2.2, color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.edit, size: 14, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
