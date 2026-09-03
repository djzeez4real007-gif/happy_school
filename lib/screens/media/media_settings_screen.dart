import 'package:flutter/material.dart';
import '../../core/school_profile_controller.dart';
import '../../core/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/welcome_media.dart';
import '../../services/welcome_media_storage.dart';
import '../../widgets/welcome_image.dart';

class MediaSettingsScreen extends StatefulWidget {
  const MediaSettingsScreen({super.key});

  @override
  State<MediaSettingsScreen> createState() => _MediaSettingsScreenState();
}

class _MediaSettingsScreenState extends State<MediaSettingsScreen> {
  List<WelcomeSlide> slides = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final list = await WelcomeMediaStorage.getSlides();
    if (!mounted) return;
    setState(() {
      slides = list;
      loading = false;
    });
  }

  Future<String?> _pickImageKey() async {
    try {
      // High res for posters/flyers (portrait or landscape)
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 3200,
        imageQuality: 95,
      );
      if (x == null) return null;
      final bytes = await x.readAsBytes();
      if (bytes.length > 6 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large (max ~6MB). Pick a smaller photo.'),
            ),
          );
        }
        return null;
      }
      return WelcomeMediaStorage.saveImageBytes(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _edit(int index) async {
    final s = slides[index];
    final urlCtrl = TextEditingController(
      text: s.imageUrl.startsWith('data:') ? '' : s.imageUrl,
    );
    final capCtrl = TextEditingController(text: s.caption);
    final subCtrl = TextEditingController(text: s.subtitle);
    String imageKey = s.imageKey;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text('Edit slide ${index + 1}'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 140,
                          child: WelcomeImage(
                            source: urlCtrl.text,
                            imageKey: imageKey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final key = await _pickImageKey();
                          if (key != null) {
                            setLocal(() {
                              imageKey = key;
                              urlCtrl.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Pick image from device'),
                      ),
                      if (imageKey.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            '✓ Photo stored in app',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Or paste a direct image URL',
                          hintText: 'https://…/photo.jpg',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onChanged: (_) => setLocal(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: capCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Title / caption',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: subCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    final updated = WelcomeSlide(
      id: s.id,
      imageUrl: urlCtrl.text.trim(),
      imageKey: imageKey,
      caption: capCtrl.text.trim(),
      subtitle: subCtrl.text.trim(),
    );
    setState(() => slides[index] = updated);
    await WelcomeMediaStorage.saveAll(slides);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slide saved — open welcome page to preview')),
    );
    await _load();
  }

  Future<void> _add() async {
    if (slides.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 8 slides')),
      );
      return;
    }
    final urlCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: 'New moment');
    final subCtrl = TextEditingController(text: SchoolProfileController.instance.name);
    String imageKey = '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Add slide'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final key = await _pickImageKey();
                          if (key != null) {
                            setLocal(() => imageKey = key);
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Pick image from device'),
                      ),
                      if (imageKey.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('✓ Photo selected',
                              style: TextStyle(color: Colors.green)),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Or image URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: capCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Caption',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: subCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;

    await WelcomeMediaStorage.addSlide(
      caption: capCtrl.text.trim(),
      subtitle: subCtrl.text.trim(),
      imageUrl: urlCtrl.text.trim(),
      imageKey: imageKey,
    );
    await _load();
  }

  Future<void> _delete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete slide?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await WelcomeMediaStorage.deleteAt(index);
    await _load();
  }

  Future<void> _resetDefaults() async {
    await WelcomeMediaStorage.saveAll(WelcomeMediaStorage.defaults());
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Media settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reset defaults',
            onPressed: _resetDefaults,
            icon: const Icon(Icons.restore_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add slide'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'Welcome page shows the first 5 slides.\n'
                    'Use “Pick image from device” — photos are stored in the app.\n'
                    'After saving, log out to see the welcome page.',
                    style: TextStyle(height: 1.45, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                ...List.generate(slides.length, (i) {
                  final s = slides[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: WelcomeImage(
                            source: s.imageUrl,
                            imageKey: s.imageKey,
                          ),
                        ),
                      ),
                      title: Text(
                        s.caption.isEmpty ? 'Slide ${i + 1}' : s.caption,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        s.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _edit(i);
                          if (v == 'delete') _delete(i);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () => _edit(i),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
