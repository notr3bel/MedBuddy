import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

class ReportScreen extends StatefulWidget {
  static const String routeName = '/reports';
  final String language;

  const ReportScreen({super.key, this.language = "en"});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool isAnalyzing = false;
  File? selectedReport;
  String? summary;
  final ImagePicker _picker = ImagePicker();

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Medical Reports',
        'upload': 'Upload Lab Report',
        'upload_sub': 'Select an image of your test results',
        'gallery': 'Gallery',
        'camera': 'Camera',
        'analyze': 'Analyze with AI',
        'analyzing': 'AI is processing your report...',
        'results': 'Analysis Results',
        'share': 'Share',
        'save_pdf': 'Save PDF',
        'error': 'Error analyzing report',
        'failed': 'Analysis failed',
      },
      'hi': {
        'title': 'मेडिकल रिपोर्ट',
        'upload': 'लैब रिपोर्ट अपलोड करें',
        'upload_sub': 'अपने परीक्षण परिणामों की एक छवि चुनें',
        'gallery': 'गैलरी',
        'camera': 'कैमरा',
        'analyze': 'AI के साथ विश्लेषण करें',
        'analyzing': 'AI आपकी रिपोर्ट को प्रोसेस कर रहा है...',
        'results': 'विश्लेषण परिणाम',
        'share': 'शेयर करें',
        'save_pdf': 'PDF सहेजें',
        'error': 'रिपोर्ट विश्लेषण में त्रुटि',
        'failed': 'विश्लेषण विफल रहा',
      },
      'kn': {
        'title': 'ವೈದ್ಯಕೀಯ ವರದಿಗಳು',
        'upload': 'ಲ್ಯಾಬ್ ವರದಿಯನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
        'upload_sub': 'ನಿಮ್ಮ ಪರೀಕ್ಷಾ ಫಲಿತಾಂಶಗಳ ಚಿತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
        'gallery': 'ಗ್ಯಾಲರಿ',
        'camera': 'ಕ್ಯಾಮರಾ',
        'analyze': 'AI ನೊಂದಿಗೆ ವಿಶ್ಲೇಷಿಸಿ',
        'analyzing': 'AI ನಿಮ್ಮ ವರದಿಯನ್ನು ಪ್ರಕ್ರಿಯೆಗೊಳಿಸುತ್ತಿದೆ...',
        'results': 'ವಿಶ್ಲೇಷಣೆ ಫಲಿತಾಂಶಗಳು',
        'share': 'ಹಂಚಿಕೊಳ್ಳಿ',
        'save_pdf': 'PDF ಉಳಿಸಿ',
        'error': 'ವರದಿ ವಿಶ್ಲೇಷಿಸುವಲ್ಲಿ ದೋಷ',
        'failed': 'ವಿಶ್ಲೇಷಣೆ ವಿಫಲವಾಗಿದೆ',
      },
      'ta': {
        'title': 'மருத்துவ அறிக்கைகள்',
        'upload': 'ஆய்வக அறிக்கையைப் பதிவேற்றவும்',
        'upload_sub': 'உங்கள் சோதனை முடிவுகளின் படத்தைத் தேர்ந்தெடுக்கவும்',
        'gallery': 'கேலரி',
        'camera': 'கேமரா',
        'analyze': 'AI உடன் பகுப்பாய்வு செய்க',
        'analyzing': 'AI உங்கள் அறிக்கையைச் செயலாக்குகிறது...',
        'results': 'பகுப்பாய்வு முடிவுகள்',
        'share': 'பகிர்',
        'save_pdf': 'PDF சேமி',
        'error': 'அறிக்கையைப் பகுப்பாய்வு செய்வதில் பிழை',
        'failed': 'பகுப்பாய்வு தோல்வி',
      },
      'ml': {
        'title': 'മെഡിക്കൽ റിപ്പോർട്ടുകൾ',
        'upload': 'ലാബ് റിപ്പോർട്ട് അപ്‌ലോഡ് ചെയ്യുക',
        'upload_sub': 'നിങ്ങളുടെ പരിശോധനാ ഫലങ്ങളുടെ ഒരു ചിത്രം തിരഞ്ഞെടുക്കുക',
        'gallery': 'ഗാലറി',
        'camera': 'ക്യാമറ',
        'analyze': 'AI ഉപയോഗിച്ച് വിശകലനം ചെയ്യുക',
        'analyzing': 'AI നിങ്ങളുടെ റിപ്പോർട്ട് പ്രോസസ്സ് ചെയ്യുന്നു...',
        'results': 'വിശകലന ഫലങ്ങൾ',
        'share': 'പങ്കിടുക',
        'save_pdf': 'PDF സേവ് ചെയ്യുക',
        'error': 'റിപ്പോർട്ട് വിശകലനം ചെയ്യുന്നതിൽ പിശക്',
        'failed': 'വിശകലനം പരാജയപ്പെട്ടു',
      },
      'te': {
        'title': 'వైద్య నివేదికలు',
        'upload': 'ల్యాబ్ నివేదికను అప్‌లోడ్ చేయండి',
        'upload_sub': 'మీ పరీక్షా ఫలితాల చిత్రాన్ని ఎంచుకోండి',
        'gallery': 'గ్యాలరీ',
        'camera': 'కెమెరా',
        'analyze': 'AIతో విశ్లేషించండి',
        'analyzing': 'AI మీ నివేదికను ప్రాసెస్ చేస్తోంది...',
        'results': 'విశ్లేషణ ఫలితాలు',
        'share': 'షేర్ చేయండి',
        'save_pdf': 'PDF సేవ్ చేయండి',
        'error': 'నివేదిక విశ్లేషణలో లోపం',
        'failed': 'విశ్లేషణ విఫలమైంది',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedReport = File(pickedFile.path);
        summary = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        selectedReport = File(pickedFile.path);
        summary = null;
      });
    }
  }

  Future<void> _analyzeReport() async {
    if (selectedReport == null) return;

    setState(() {
      isAnalyzing = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      Map<String, dynamic> result = await ApiService.analyzeMedicalReport(
        selectedReport!,
        lang: widget.language,
        userId: user?.id,
      );

      setState(() {
        if (result['success'] == true) {
          summary = result['summary'];
        } else {
          summary = result['message'] ?? _getText('failed');
        }
      });
    } catch (e) {
      setState(() {
        summary = "${_getText('error')}: $e";
      });
    } finally {
      setState(() {
        isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_getText('title'), 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadCard(),
            const SizedBox(height: 25),
            if (isAnalyzing) _buildLoadingState(),
            if (summary != null && !isAnalyzing) _buildResultsCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (selectedReport != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.file(
                    selectedReport!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        selectedReport = null;
                        summary = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.1), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 50, color: Colors.teal.shade300),
                  const SizedBox(height: 12),
                  Text(_getText('upload'), 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                  const SizedBox(height: 4),
                  Text(_getText('upload_sub'), 
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: _pickImage,
                  icon: Icons.photo_library_outlined,
                  label: _getText('gallery'),
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  onPressed: _takePhoto,
                  icon: Icons.camera_alt_outlined,
                  label: _getText('camera'),
                  isPrimary: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            onPressed: isAnalyzing || selectedReport == null ? null : _analyzeReport,
            icon: Icons.auto_awesome,
            label: _getText('analyze'),
            isPrimary: true,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.teal : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.teal,
          elevation: isPrimary ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isPrimary ? BorderSide.none : BorderSide(color: Colors.teal.shade100),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircularProgressIndicator(color: Colors.teal),
          const SizedBox(height: 16),
          Text(_getText('analyzing'), 
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Text(_getText('results'), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          MarkdownBody(
            data: summary!,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
              h3: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                height: 2.0,
              ),
              listBullet: TextStyle(color: Colors.teal.shade700),
              blockquote: TextStyle(color: Colors.orange.shade900),
              blockquoteDecoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Colors.orange, width: 4),
                ),
              ),
              blockquotePadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => ExportService.shareText(
                  summary!,
                  subject: _getText('title'),
                ),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text(_getText('share')),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => ExportService.generateAndPrintPdf(
                  title: _getText('title'),
                  content: summary!,
                ),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text(_getText('save_pdf')),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
