<<<<<<< Updated upstream
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
=======
// FULLY COMMENTED VERSION OF AddProduct PAGE
// (Every important line explained in simple Hinglish)

import 'dart:io';
import 'package:flutter/foundation.dart'; // 👉 Detects if app is running on Web
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 👉 For picking logo & cover images from gallery
>>>>>>> Stashed changes

import 'package:prodhunt/services/product_submit_service.dart';

// -------------------------------
// MAIN PAGE
// -------------------------------
class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  // 👉 Form key for validation
  final _form = GlobalKey<FormState>();

  // ---------- TEXT FIELDS ----------
  final _nameCtrl = TextEditingController(); // Product name
  final _taglineCtrl = TextEditingController(); // Short line
  final _descCtrl = TextEditingController(); // Description
  final _categoryCtrl = TextEditingController(text: 'General'); // Default category
  final _tagsCtrl = TextEditingController(); // Comma-separated tags

  // ---------- IMAGES ----------
  final _picker = ImagePicker(); // 👉 Image picker instance

  XFile? _logoFile; // 👉 For mobile file
  Uint8List? _logoBytes; // 👉 For web byte image

  XFile? _coverFile;
  Uint8List? _coverBytes;

  // ---------- PUBLISH OPTIONS ----------
  bool _publishNow = true; // 👉 Publish now OR schedule later
  DateTime? _scheduledAt; // 👉 Time if scheduled

  bool _saving = false; // 👉 Show loading on submit

  @override
  void dispose() {
    // 👉 Clean controllers to avoid memory leak
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  // ----------------------------------------
  // PICK LOGO IMAGE
  // ----------------------------------------
  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null) return; // user cancelled

    if (kIsWeb) {
      // 👉 On web we store bytes
      _logoBytes = await picked.readAsBytes();
      _logoFile = null;
    } else {
      // 👉 On mobile we store file
      _logoFile = picked;
      _logoBytes = null;
    }
    setState(() {}); // refresh UI
  }

  // ----------------------------------------
  // PICK COVER IMAGE
  // ----------------------------------------
  Future<void> _pickCover() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null) return;

    if (kIsWeb) {
      _coverBytes = await picked.readAsBytes();
      _coverFile = null;
    } else {
      _coverFile = picked;
      _coverBytes = null;
    }
    setState(() {});
  }

  // ----------------------------------------
  // IMAGE PROVIDER: return correct UI image
  // ----------------------------------------
  ImageProvider? _imgProv({required XFile? file, required Uint8List? bytes}) {
    if (kIsWeb) {
      if (bytes != null) return MemoryImage(bytes);
    } else {
      if (file != null) return FileImage(File(file.path));
    }
    return null; // nothing selected
  }

  // ----------------------------------------
  // PICK SCHEDULE DATE + TIME
  // ----------------------------------------
  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now().add(const Duration(minutes: 5));

    // 👉 Pick date
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;

    // 👉 Pick time
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: (now.minute ~/ 5) * 5),
    );
    if (t == null) return;

    // 👉 Combine date + time
    setState(() {
      _scheduledAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  // ----------------------------------------
  // SUBMIT PRODUCT
  // ----------------------------------------
  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return; // form invalid

    // 👉 Handle scheduling
    if (!_publishNow && _scheduledAt == null) {
      _snack('Pick a schedule date & time');
      return;
    }
    if (!_publishNow && _scheduledAt!.isBefore(DateTime.now())) {
      _snack('Schedule must be in the future');
      return;
    }

    setState(() => _saving = true);
    try {
      // 👉 Extract tags from comma separated text
      final tags = _tagsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // 👉 Call service to upload data
      final productId = await ProductSubmitService.createProduct(
        name: _nameCtrl.text,
        tagline: _taglineCtrl.text,
        description: _descCtrl.text,
        category: _categoryCtrl.text.trim().isEmpty
            ? 'General'
            : _categoryCtrl.text.trim(),
        tags: tags,
        publishNow: _publishNow,
        scheduledAt: _publishNow ? null : _scheduledAt,

        // 👉 Images
        logoFile: _logoFile,
        logoBytes: _logoBytes,
        coverFile: _coverFile,
        coverBytes: _coverBytes,
      );

      // 👉 Success message
      _snack(
        _publishNow
            ? 'Published! (id: $productId)'
            : 'Scheduled! (id: $productId)',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ----------------------------------------
  // SNACKBAR HELPER
  // ----------------------------------------
  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ----------------------------------------
  // MAIN UI
  // ----------------------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Submit product')),
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 900; // 👉 responsive layout
          final form = _buildForm(cs);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: wide
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Row(
                        children: [
                          Expanded(child: form),
                          const SizedBox(width: 20),
                          Expanded(child: _buildPreviewCard(cs)),
                        ],
                      ),
                    ),
                  )
                : form,
          );
        },
      ),

      // 👉 Floating Submit Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _submit,
        label: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Submit'),
        icon: _saving ? null : const Icon(Icons.send),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ----------------------------------------
  // BUILD FORM UI
  // ----------------------------------------
  Widget _buildForm(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(title: 'Basics'),

            // NAME
            _Field(
              label: 'Name',
              child: TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'e.g., SuperApp'),
                validator: (v) => (v ?? '').trim().length < 2
                    ? 'At least 2 characters'
                    : null,
              ),
            ),

            // TAGLINE
            _Field(
              label: 'Tagline',
              child: TextFormField(
                controller: _taglineCtrl,
                decoration: const InputDecoration(hintText: 'One crisp line'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
            ),

            // DESCRIPTION
            _Field(
              label: 'Description',
              child: TextFormField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(hintText: 'What does it do…'),
              ),
            ),

            // CATEGORY + TAGS BLOCK
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'Category',
                    child: TextFormField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Productivity',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    label: 'Tags (comma separated)',
                    child: TextFormField(
                      controller: _tagsCtrl,
                      decoration: const InputDecoration(
                        hintText: 'ai, mobile, tools',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            _Section(title: 'Images'),

            // IMAGE PICK ROW
            Row(
              children: [
                Expanded(
                  child: _ImagePickTile(
                    label: 'Logo',
                    onTap: _pickLogo,
                    image: _imgProv(file: _logoFile, bytes: _logoBytes),
                    hint: 'Square logo',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImagePickTile(
                    label: 'Cover',
                    onTap: _pickCover,
                    image: _imgProv(file: _coverFile, bytes: _coverBytes),
                    hint: '16:9 cover',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            _Section(title: 'Launch'),

            // PUBLISH SWITCH
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publish now'),
              subtitle: const Text('Off = Schedule for later'),
              value: _publishNow,
              onChanged: (v) => setState(() => _publishNow = v),
            ),

            if (!_publishNow) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickScheduleDateTime,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _scheduledAt == null
                            ? 'Pick date & time'
                            : _scheduledAt!.toLocal().toString(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  // ----------------------------------------
  // PREVIEW CARD (LIVE PREVIEW OF PRODUCT)
  // ----------------------------------------
  Widget _buildPreviewCard(ColorScheme cs) {
    final logo = _imgProv(file: _logoFile, bytes: _logoBytes);
    final cover = _imgProv(file: _coverFile, bytes: _coverBytes);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COVER IMAGE PREVIEW
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: cover == null
                  ? Container(color: cs.surfaceContainerHigh)
                  : Image(image: cover, fit: BoxFit.cover),
            ),
          ),

          // TITLE + LOGO
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: logo,
                  backgroundColor: cs.surfaceContainerHigh,
                  child: logo == null
                      ? Icon(Icons.auto_awesome, size: 16, color: cs.onSurface)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _nameCtrl.text.isEmpty ? 'Your product' : _nameCtrl.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ----------------------------------------
// SMALL UI HELPERS BELOW
// ----------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ----------------------------------------
// FIELD WIDGET (Label + Input)
// ----------------------------------------
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  // 👉 Field label (example: Name, Tagline, Category)
  final String label;

  // 👉 The actual input widget (TextFormField)
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; // 👉 Theme colors

    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // spacing between fields
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👉 Label text
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: cs.onSurfaceVariant), // lighter label color
          ),

          const SizedBox(height: 6), // small spacing

          // 👉 The actual TextFormField / input widget
          child,
        ],
      ),
    );
  }
}

// ----------------------------------------
// IMAGE PICK TILE (Tap to pick logo/cover)
// ----------------------------------------
class _ImagePickTile extends StatelessWidget {
  const _ImagePickTile({
    required this.label, // 👉 Title: Logo / Cover
    required this.onTap, // 👉 Function to call on tap
    this.image, // 👉 Selected image preview
    this.hint, // 👉 Small hint under text
  });

  final String label;
  final VoidCallback onTap;
  final ImageProvider? image;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap, // 👉 Tapping opens gallery
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest, // card background
          border: Border.all(color: cs.outlineVariant), // subtle border
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 👉 Image preview circle
            CircleAvatar(
              radius: 28,
              backgroundImage: image, // show picked image
              backgroundColor: cs.surfaceContainerHigh, // fallback color
              child: image == null
                  ? Icon(Icons.image, color: cs.onSurface) // placeholder icon
                  : null,
            ),

            const SizedBox(width: 12),

            // 👉 Text column: Label + Hint
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hint ?? 'Tap to upload', // fallback hint
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 👉 Upload icon
            const Icon(Icons.upload_rounded),
          ],
        ),
      ),
    );
  }
}
  
