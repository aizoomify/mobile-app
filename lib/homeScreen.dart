import 'dart:io';
import 'package:clipboard/clipboard.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  String _extractedText = '';
  bool _isScanning = false;

  // --- Core Logic ---
  Future<void> _processImage(String imagePath) async {
    setState(() {
      _imageFile = File(imagePath);
      _extractedText = '';
    });
  }

  Future<void> _pickImageFromGallery() async {
    if (await Permission.photos.request().isGranted) {
      try {
        final pickedFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile != null) await _processImage(pickedFile.path);
      } catch (e) {
        _showSnackBar('Failed to pick image: $e', isError: true);
      }
    } else {
      _showSnackBar('Gallery permission is required.');
    }
  }

  Future<void> _scanDocument() async {
    if (await Permission.camera.request().isGranted) {
      try {
        final imagePaths = await CunningDocumentScanner.getPictures() ?? [];
        if (imagePaths.isNotEmpty) await _processImage(imagePaths.first);
      } catch (e) {
        _showSnackBar('Failed to scan document: $e', isError: true);
      }
    } else {
      _showSnackBar('Camera permission is required.');
    }
  }

  Future<void> _performOcr() async {
    if (_imageFile == null) return;
    setState(() => _isScanning = true);
    try {
      final inputImage = InputImage.fromFilePath(_imageFile!.path);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      setState(() => _extractedText = recognizedText.text);
      textRecognizer.close();
    } catch (e) {
      _showSnackBar('Text recognition failed: $e', isError: true);
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _saveImage() async {
    if (_imageFile == null) return;
    try {
      await Gal.putImage(_imageFile!.path);
      _showSnackBar('Image saved to gallery!');
    } catch (e) {
      _showSnackBar('Error saving image: $e', isError: true);
    }
  }

  void _shareImage() {
    if (_imageFile == null) return;
    Share.shareXFiles([XFile(_imageFile!.path)], text: 'Scanned Document');
  }
  
  void _clearImage() {
    setState(() {
      _imageFile = null;
      _extractedText = '';
    });
  }

  void _copyText() {
    if (_extractedText.isEmpty) return;
    FlutterClipboard.copy(_extractedText).then((_) {
      _showSnackBar('Text copied to clipboard!');
    });
  }

  void _shareText() {
    if (_extractedText.isEmpty) return;
    Share.share(_extractedText, subject: 'Extracted Text');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // --- UI Builder Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Document Scanner'),
        centerTitle: true,
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildImageDisplay(),
          const SizedBox(height: 24),
          _buildPrimaryActions(),
          const SizedBox(height: 24),
          _buildConditionalActions(),
          const SizedBox(height: 24),
          _buildOcrResult(),
        ]
            .animate(interval: 100.ms)
            .fadeIn(duration: 200.ms, delay: 100.ms)
            .slideY(begin: 0.2, end: 0.0),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _imageFile == null
            ? _buildPlaceholder()
            : _buildImagePreview(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      key: const ValueKey('placeholder'),
      height: 350,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Scan or select a document',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      key: const ValueKey('image_preview'),
      height: 350,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_imageFile!, fit: BoxFit.contain),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _clearImage,
                tooltip: 'Clear Image',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _scanDocument,
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Scan Document'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickImageFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('From Gallery'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionalActions() {
    return AnimatedOpacity(
      opacity: _imageFile != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: _imageFile == null
          ? const SizedBox.shrink()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.save_alt_outlined, 'Save', _saveImage),
                _buildActionButton(Icons.share_outlined, 'Share', _shareImage),
                _buildActionButton(
                    Icons.text_fields_rounded, 'Extract Text', _performOcr),
              ],
            ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  Widget _buildOcrResult() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _isScanning
          ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
          : _extractedText.isNotEmpty
              ? _buildTextResultCard()
              : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
  
  Widget _buildTextResultCard() {
    return Card(
      key: const ValueKey('text_result'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Extracted Text', style: Theme.of(context).textTheme.titleLarge),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.copy), onPressed: _copyText, tooltip: 'Copy Text'),
                    IconButton(icon: const Icon(Icons.share), onPressed: _shareText, tooltip: 'Share Text'),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            SelectableText(_extractedText),
          ],
        ),
      ),
    );
  }
}
