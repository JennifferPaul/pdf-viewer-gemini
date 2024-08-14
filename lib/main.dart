import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';



// Define a class to hold language options
class LanguageOption {
  final String languageCode;
  final String languageName;

  LanguageOption({required this.languageCode, required this.languageName});
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyMate',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String? _pdfPath;
  String _selectedText = '';
  String _summary = '';
  String _explanation = '';
  String _translation = '';
  bool _isLoading = false;
  bool _showSummary = false;
  bool _showExplanation = false;
  bool _showTranslate = false;
  // Added for showing translate
  bool _showCopyIcon = false;
  bool _isMobileView = false;
  PdfViewerController? _pdfViewerController;
  Rect? _selectionRect;

  bool _showHighlightIcon = false;
  LanguageOption? _selectedSourceLanguage;
  LanguageOption? _selectedTargetLanguage;
  bool _isZoomedOut = false;
  // Define language options
  List<LanguageOption> sourceLanguages = [
    LanguageOption(languageCode: 'en', languageName: 'English'),
    LanguageOption(languageCode: 'fr', languageName: 'French'),
    LanguageOption(languageCode: 'id', languageName: 'Indonesian'),
    // Add more source languages as needed
  ];

  List<LanguageOption> targetLanguages = [
    LanguageOption(languageCode: 'es', languageName: 'Spanish'),
    LanguageOption(languageCode: 'it', languageName: 'Italian'),
    LanguageOption(languageCode: 'de', languageName: 'German'),
    LanguageOption(languageCode: 'hi', languageName: 'Hindi'),
    LanguageOption(languageCode: 'ar', languageName: 'Arabic'),
    LanguageOption(languageCode: 'en', languageName: 'English'),
    LanguageOption(languageCode: 'fr', languageName: 'French'),
    LanguageOption(languageCode: 'id', languageName: 'Indonesian'),
    LanguageOption(languageCode: 'pt', languageName: 'Portuguese'),
    LanguageOption(languageCode: 'ru', languageName: 'Russian'),
    LanguageOption(languageCode: 'ja', languageName: 'Japanese'),
    LanguageOption(languageCode: 'ko', languageName: 'Korean'),
    LanguageOption(languageCode: 'zh', languageName: 'Chinese'),
    LanguageOption(languageCode: 'nl', languageName: 'Dutch'),
    LanguageOption(languageCode: 'sv', languageName: 'Swedish'),
    LanguageOption(languageCode: 'pl', languageName: 'Polish'),
    LanguageOption(languageCode: 'tr', languageName: 'Turkish'),
    LanguageOption(languageCode: 'vi', languageName: 'Vietnamese'),
    LanguageOption(languageCode: 'th', languageName: 'Thai'),
    LanguageOption(languageCode: 'el', languageName: 'Greek'),
    LanguageOption(languageCode: 'he', languageName: 'Hebrew'),
    LanguageOption(languageCode: 'hu', languageName: 'Hungarian'),
    LanguageOption(languageCode: 'cs', languageName: 'Czech'),
    LanguageOption(languageCode: 'da', languageName: 'Danish'),
    LanguageOption(languageCode: 'fi', languageName: 'Finnish'),
    LanguageOption(languageCode: 'no', languageName: 'Norwegian'),
    LanguageOption(languageCode: 'uk', languageName: 'Ukrainian'),
    LanguageOption(languageCode: 'ro', languageName: 'Romanian'),
    LanguageOption(languageCode: 'bg', languageName: 'Bulgarian'),
    LanguageOption(languageCode: 'hr', languageName: 'Croatian'),
    LanguageOption(languageCode: 'sr', languageName: 'Serbian'),
    LanguageOption(languageCode: 'sk', languageName: 'Slovak'),
    LanguageOption(languageCode: 'sl', languageName: 'Slovenian'),
    LanguageOption(languageCode: 'ms', languageName: 'Malay'),
    LanguageOption(languageCode: 'bn', languageName: 'Bengali'),
    LanguageOption(languageCode: 'fa', languageName: 'Persian'),

    // Add more target languages as needed
  ];
  void _zoomIn() {
    setState(() {
      _pdfViewerController!.zoomLevel += 0.5; // Increase zoom level
      _isZoomedOut = false; // Update zoom state
    });
  }
  void _zoomOut() {
    setState(() {
      _pdfViewerController!.zoomLevel -= 0.5; // Decrease zoom level
      _isZoomedOut = true; // Update zoom state
    });
  }
  void _adjustZoomToFitLineLength() {
    if (_pdfViewerController != null) {
      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;

      // Get current zoom level from PdfViewerController
      double currentZoomLevel = _pdfViewerController!.zoomLevel;

      // Calculate effective viewport dimensions based on current zoom level
      double viewportWidth = screenWidth / currentZoomLevel;
      double viewportHeight = screenHeight / currentZoomLevel;

      // Calculate zoom level to fit the line length within visible viewport dimensions
      double zoomWidth = screenWidth / viewportWidth;
      double zoomHeight = screenHeight / viewportHeight;

      // Adjust zoom level based on the smaller ratio (width or height)
      double zoomLevel = zoomWidth < zoomHeight ? zoomWidth : zoomHeight;

      // Clamp zoom level to a sensible range
      zoomLevel = zoomLevel.clamp(0.5, 2.0);

      // Update PdfViewerController with new zoom level
      _pdfViewerController!.zoomLevel = zoomLevel;

      setState(() {
        _isZoomedOut = false; // Update zoom state
      });
    } else {
      print("PdfViewerController is not initialized.");
    }
  }

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }
  double getAdjustedScreenWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return _isZoomedOut ? screenWidth * 0.8 : screenWidth;
  }
  void _openFileExplorer() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfPath = result.files.single.path!;
        _selectedText = '';
        _summary = '';
        _explanation = '';
        _translation = ''; // Reset translation
        _showTranslate = false; // Reset translate visibility
      });

      print('Selected PDF Path: $_pdfPath');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File selection canceled')),
      );
    }
  }

  Future<void> _summarizeText(String text) async {
    final apiKey = ''
        '';
    final apiUrl =
        'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                  'Please provide a brief summary of the following text in approximately 5 lines but do not limit it strictly to 5 lines: $text'
                },
              ],
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('candidates') &&
            jsonResponse['candidates'] is List &&
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0].containsKey('content') &&
            jsonResponse['candidates'][0]['content'].containsKey('parts') &&
            jsonResponse['candidates'][0]['content']['parts'] is List &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          List<dynamic> parts =
          jsonResponse['candidates'][0]['content']['parts'];
          String summary =
          parts.map((part) => part['text']).join('\n');

          setState(() {
            _summary = summary;
            _showSummary = true;
          });
        } else {
          print(
              'Failed to parse response correctly. Response: $jsonResponse');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to summarize text')),
          );
        }
      } else {
        print(
            'Failed to summarize text. Status Code: ${response.statusCode}, Error: ${response.reasonPhrase}');
        print('Response Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to summarize text. Check API key and try again.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('Error occurred during summarization. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _explainText(String text) async {
    final apiKey = '';
    final apiUrl =
        'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'Please provide an explanation for the following text: $text'},
              ],
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('candidates') &&
            jsonResponse['candidates'] is List &&
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0].containsKey('content') &&
            jsonResponse['candidates'][0]['content'].containsKey('parts') &&
            jsonResponse['candidates'][0]['content']['parts'] is List &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          List<dynamic> parts =
          jsonResponse['candidates'][0]['content']['parts'];
          String explanation =
          parts.map((part) => part['text']).join('\n');

          setState(() {
            _explanation = explanation;
            _showExplanation = true;
          });
        } else {
          print(
              'Failed to parse response correctly. Response: $jsonResponse');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to explain text')),
          );
        }
      } else {
        print(
            'Failed to explain text. Status Code: ${response.statusCode}, Error: ${response.reasonPhrase}');
        print('Response Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to explain text. Check API key and try again.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('Error occurred during explanation. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _translateText(String text, String sourceLang, String targetLang) async {
    final apiKey = '';
    final apiUrl =
        'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                  'Please translate the following text from $sourceLang to $targetLang: $text '
                },
              ],
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('candidates') &&
            jsonResponse['candidates'] is List &&
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0].containsKey('content') &&
            jsonResponse['candidates'][0]['content'].containsKey('parts') &&
            jsonResponse['candidates'][0]['content']['parts'] is List &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          List<dynamic> parts =
          jsonResponse['candidates'][0]['content']['parts'];
          String translation =
          parts.map((part) => part['text']).join('\n');

          setState(() {
            _translation = translation;
            _showTranslate = true; // Show translation
          });
        } else {
          print(
              'Failed to parse response correctly. Response: $jsonResponse');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to translate text')),
          );
        }
      } else {
        print(
            'Failed to translate text. Status Code: ${response.statusCode}, Error: ${response.reasonPhrase}');
        print('Response Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to translate text. Check API key and try again.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('Error occurred during translation. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _copySelectedTextToClipboard() {
    Clipboard.setData(ClipboardData(text: _selectedText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard: $_selectedText')),
    );
  }
  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Source and Target Languages'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<LanguageOption>(
                value: _selectedSourceLanguage,
                onChanged: (LanguageOption? newValue) {
                  setState(() {
                    _selectedSourceLanguage = newValue!;
                  });
                },
                items: sourceLanguages.map((LanguageOption option) {
                  return DropdownMenuItem<LanguageOption>(
                    value: option,
                    child: Text(option.languageName),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Source Language'),
              ),
              DropdownButtonFormField<LanguageOption>(
                value: _selectedTargetLanguage,
                onChanged: (LanguageOption? newValue) {
                  setState(() {
                    _selectedTargetLanguage = newValue!;
                  });
                },
                items: targetLanguages.map((LanguageOption option) {
                  return DropdownMenuItem<LanguageOption>(
                    value: option,
                    child: Text(option.languageName),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Target Language'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedSourceLanguage != null &&
                    _selectedTargetLanguage != null) {
                  Navigator.of(context).pop();
                  _translateText(_selectedText, _selectedSourceLanguage!.languageCode,
                      _selectedTargetLanguage!.languageCode);
                }
              },
              child: Text('Translate'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StudyMate'),
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: _zoomOut,
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _openFileExplorer,
            child: Text('Open PDF'),
          ),
          Expanded(
            child: _pdfPath == null
                ? Center(child: Text('Please select a PDF file'))
                : SfPdfViewer.file(
              File(_pdfPath!),
              controller: _pdfViewerController,
              onTextSelectionChanged:
                  (PdfTextSelectionChangedDetails details) {
                setState(() {
                  _selectedText = details.selectedText ?? '';
                  _showSummary = false;
                  _showExplanation = false;
                  _showTranslate = false;
                  _showCopyIcon = _selectedText.isNotEmpty;
                  _showHighlightIcon = _selectedText.isNotEmpty;
                });
              },
            ),
          ),
          if (_selectedText.isNotEmpty)
            Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Adjust as needed
                  children: [
                    ElevatedButton(
                      onPressed: () => _summarizeText(_selectedText),
                      child: Text('Summarize'),
                    ),
                    ElevatedButton(
                      onPressed: () => _explainText(_selectedText),
                      child: Text('Explain'),
                    ),
                    IconButton(
                      icon: Icon(Icons.translate),
                      onPressed: _showLanguageSelectionDialog,
                    ),

                  ],
                ),
                if (_showCopyIcon )

                  IconButton(
                    icon: Icon(Icons.content_copy),
                    onPressed: _copySelectedTextToClipboard,
                  ),

              ],
            ),




          if (_isLoading) Center(child: CircularProgressIndicator()),
          if (_showSummary && !_isLoading)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: Colors.grey[300],
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Summary:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _showSummary = false;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(_summary),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.content_copy),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: _summary));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_showExplanation && !_isLoading)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: Colors.grey[300],
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Explanation:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.content_copy),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _explanation));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Copied to clipboard')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _showExplanation = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(_explanation),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_showTranslate && !_isLoading)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: Colors.grey[300],
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Translation:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.content_copy),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _translation));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Copied to clipboard')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _showTranslate = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(_translation),
                      ],
                    ),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }
}


