import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_uploader.dart';
import '../l10n/app_localizations.dart';

// Result model ---------------------------------------------------------------
class ProfileImageSelection {
  final XFile? pickedFile; // Raw picked image (not (auto) uploaded yet)
  final String? generatedAvatarUrl; // Chosen generated avatar URL OR uploaded file URL
  final bool removed;
  const ProfileImageSelection({this.pickedFile, this.generatedAvatarUrl, this.removed = false});
  bool get hasImage => pickedFile != null || generatedAvatarUrl != null;
}

typedef OnProfileImageSelection = Future<void> Function(ProfileImageSelection selection);
typedef ProfileImageUploader = Future<String?> Function(XFile file);

class ProfilePicturePicker extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? initialImageUrl;
  final OnProfileImageSelection onSelection;
  final double size;
  final String? seedOverride; // overrides all other seed sources
  final ProfileImageUploader? uploader; // custom uploader (else ImageUploader)
  final bool autoUpload; // if true and uploader available, uploads automatically
  final int ringWidth; // decorative ring width
  final Future<XFile?> Function()? imagePickerOverride; // test hook
  final bool debugAutoOpenDialog; // test helper: open dialog automatically
  final bool debugUsePlaceholders; // test helper: avoid network images

  const ProfilePicturePicker({
    super.key,
    this.firstName,
    this.lastName,
    this.username,
    this.initialImageUrl,
    required this.onSelection,
    this.size = 70,
    this.seedOverride,
    this.uploader,
    this.autoUpload = true,
    this.ringWidth = 0,
    this.imagePickerOverride,
  this.debugAutoOpenDialog = false,
  this.debugUsePlaceholders = false,
  });

  @override
  State<ProfilePicturePicker> createState() => _ProfilePicturePickerState();
}

class _ProfilePicturePickerState extends State<ProfilePicturePicker> {
  // Generation state
  int _page = 1;
  bool _generating = false;
  List<String> _avatarUrls = [];
  String? _selectedGenerated;

  // File pick state
  XFile? _pickedFile;
  bool _uploading = false;
  String? _uploadedUrl; // result of auto upload
  bool _dialogAvatarMode = false; // whether dialog is showing avatar grid
  bool _dialogOpenedScheduled = false; // ensure auto-open only once

  Future<String?> _defaultUploader(XFile f) => ImageUploader.uploadProfileImage(xfile: f);

  String _seedBase() {
    final s = (widget.seedOverride?.trim().isNotEmpty ?? false)
        ? widget.seedOverride!.trim()
        : (widget.username?.trim().isNotEmpty ?? false)
            ? widget.username!.trim()
            : (widget.firstName?.trim().isNotEmpty ?? false)
                ? widget.firstName!.trim()
                : 'user';
    return s;
  }

  Future<void> _generate({bool next = false, StateSetter? localSet}) async {
    if (_generating) return;
    final apply = localSet ?? setState;
    apply(() {
      _generating = true;
      if (!next) _avatarUrls = [];
    });
    await Future.delayed(const Duration(milliseconds: 40));
    if (next) {
      _page++;
    } else {
      _page = 1;
    }
    final base = _seedBase();
    final startIndex = (_page - 1) * 10 + 1;
    final urls = List.generate(10, (i) {
      final seed = '$base${startIndex + i}';
      return 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=$seed&backgroundType=gradientLinear,solid';
    });
    if (!mounted) return;
    apply(() {
      _avatarUrls = urls;
      _generating = false;
    });
  }

  Future<void> _pickImage(AppLocalizations l) async {
    XFile? x;
    if (widget.imagePickerOverride != null) {
      x = await widget.imagePickerOverride!();
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      final res = await FilePicker.platform.pickFiles(type: FileType.image);
      if (res != null && res.files.single.path != null) {
        x = XFile(res.files.single.path!);
      }
    } else {
      final picker = ImagePicker();
      x = await picker.pickImage(source: ImageSource.gallery);
    }
    if (x == null) return; // cancelled
    setState(() {
      _pickedFile = x;
      _selectedGenerated = null;
      _uploadedUrl = null;
    });
    if (widget.autoUpload && (widget.uploader != null || !kIsWeb)) {
      setState(() => _uploading = true);
      final uploader = widget.uploader ?? _defaultUploader;
      final url = await uploader(x);
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadedUrl = url; // may be null on failure
      });
      if (url != null) {
        await widget.onSelection(ProfileImageSelection(generatedAvatarUrl: url));
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
    }
    // fallback: deliver raw file (parent may upload later)
    await widget.onSelection(ProfileImageSelection(pickedFile: x));
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _remove() async {
    setState(() {
      _pickedFile = null;
      _selectedGenerated = null;
      _uploadedUrl = null;
    });
    await widget.onSelection(const ProfileImageSelection(removed: true));
    if (mounted) Navigator.of(context).maybePop();
  }

  void _openDialog(AppLocalizations l) {
  _dialogAvatarMode = false;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          Widget content;
      if (!_dialogAvatarMode) {
            content = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  key: const Key('pp_picker_pick_image'),
                  leading: const Icon(Icons.photo_library),
                  title: Text(l.translate('pick_image')),
                  onTap: () => _pickImage(l),
                ),
                ListTile(
                  key: const Key('pp_picker_generate'),
                  leading: const Icon(Icons.auto_awesome),
                  title: Text(l.translate('generate_avatars')),
                  onTap: () async {
                    setLocal(() => _dialogAvatarMode = true);
                    await _generate(localSet: setLocal);
                  },
                ),
                ListTile(
                  key: const Key('pp_picker_remove'),
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l.translate('remove_image')),
                  onTap: _remove,
                ),
              ],
            );
          } else {
            content = SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_generating)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(key: Key('pp_generate_loading')),
                    )
                  else ...[
                    GridView.builder(
                      key: const Key('pp_avatar_grid'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _avatarUrls.length,
                      itemBuilder: (_, i) {
                        final url = _avatarUrls[i];
                        final selected = url == _selectedGenerated;
                        return InkWell(
                          key: Key('pp_avatar_$i'),
                          onTap: () async {
                            setLocal(() => _selectedGenerated = url);
                            await widget.onSelection(ProfileImageSelection(generatedAvatarUrl: url));
                          },
                          child: Stack(children: [
                            Positioned.fill(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: widget.debugUsePlaceholders
                                    ? CircleAvatar(
                                        backgroundColor: Colors.grey.shade400,
                                        child: Text(
                                          (i + 1).toString(),
                                          style: const TextStyle(fontSize: 12, color: Colors.black),
                                        ),
                                      )
                                    : CircleAvatar(backgroundImage: NetworkImage(url)),
                              ),
                            ),
                            if (selected)
                              const Positioned(
                                right: 0,
                                bottom: 0,
                                child: Icon(Icons.check_circle, size: 20, color: Colors.green),
                              ),
                          ]),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      FilledButton(
                        key: const Key('pp_generate_more'),
                        onPressed: () async { await _generate(next: true, localSet: setLocal); },
                        child: Text(l.translate('more')),
                      ),
                      const Spacer(),
                      TextButton(
                        key: const Key('pp_close'),
                        onPressed: () {
                          if (_selectedGenerated != null) {
                            Navigator.of(dialogCtx).pop();
                          } else {
                            setLocal(() => _dialogAvatarMode = false);
                          }
                        },
                        child: Text(_selectedGenerated != null ? l.translate('finish') : l.translate('back')),
                      ),
                    ])
                  ]
                ],
              ),
            );
          }
          return AlertDialog(
            title: Text(l.translate('choose_profile_picture')),
            content: content,
            actions: [
              if (!_dialogAvatarMode)
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(l.translate('cancel')),
                ),
            ],
          );
        });
      },
    );
  }

  ImageProvider? _currentImageProvider() {
  if (widget.debugUsePlaceholders) return null; // suppress network loads in tests
  if (_uploadedUrl != null) return NetworkImage(_uploadedUrl!);
  if (_selectedGenerated != null) return NetworkImage(_selectedGenerated!);
    if (_pickedFile != null) {
      if (!kIsWeb && _pickedFile!.path.isNotEmpty) {
        return FileImage(File(_pickedFile!.path));
      } else {
        return NetworkImage(_pickedFile!.path); // web blob/url
      }
    }
    if (widget.initialImageUrl != null && widget.initialImageUrl!.startsWith('http')) {
      return NetworkImage(widget.initialImageUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (widget.debugAutoOpenDialog && !_dialogOpenedScheduled) {
      _dialogOpenedScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openDialog(l);
      });
    }
    final img = _currentImageProvider();
    final initials = ((widget.firstName?.isNotEmpty ?? false) && (widget.lastName?.isNotEmpty ?? false))
        ? '${widget.firstName![0]}${widget.lastName![0]}'
        : (widget.username?.isNotEmpty ?? false)
            ? widget.username![0]
            : '?';

    return InkWell(
      key: const Key('pp_root'),
      onTap: () => _openDialog(l),
      customBorder: const CircleBorder(),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Stack(alignment: Alignment.bottomRight, children: [
        Container(
          decoration: widget.ringWidth > 0
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: widget.ringWidth.toDouble()),
                )
              : null,
          child: CircleAvatar(
            radius: widget.size / 2,
            backgroundImage: img,
            backgroundColor: Colors.teal,
            child: img == null
                ? Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      fontSize: widget.size / 2.2,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
        if (_uploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white, key: Key('pp_uploading_indicator')),
              ),
            ),
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
      ]),
    );
  }
}
