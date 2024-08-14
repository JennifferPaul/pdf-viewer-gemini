import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class SyncfusionPdfViewerPage extends StatefulWidget {
  @override
  _SyncfusionPdfViewerPageState createState() => _SyncfusionPdfViewerPageState();
}

class _SyncfusionPdfViewerPageState extends State<SyncfusionPdfViewerPage> {
  String? _pdfPath;
  PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      print('Storage permission granted.');
    } else {
      print('Storage permission denied.');
    }
  }

  Future<void> _openFileExplorer() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfPath = result.files.single.path!;
        _isLoading = true;
        print('File selected: $_pdfPath');
      });
    }
  }

  void _onPdfViewReady(PdfViewerController controller) {
    setState(() {
      _isLoading = false;
      print('PDF view is ready.');
    });
  }

  void _copyText() async {
    if (_selectedText != null && _selectedText!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _selectedText!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied to clipboard: $_selectedText')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No text selected.')),
      );
    }
  }

  void _pasteText() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pasting text is not supported in this viewer.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Syncfusion PDF Viewer'),
        actions: [
          IconButton(
            icon: Icon(Icons.content_copy),
            onPressed: _copyText,
          ),
          IconButton(
            icon: Icon(Icons.content_paste),
            onPressed: _pasteText,
          ),
        ],
      ),
      body: Center(
        child: _pdfPath == null
            ? ElevatedButton(
          onPressed: _openFileExplorer,
          child: Text('Open PDF'),
        )
            : _isLoading
            ? CircularProgressIndicator()
            : SfPdfViewer.file(
          File(_pdfPath!),
          controller: _pdfViewerController,
          onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
            setState(() {
              _selectedText = details.selectedText;
            });
          },
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            _onPdfViewReady(_pdfViewerController);
          },
        ),
      ),
    );
  }
}
