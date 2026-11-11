import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../main.dart';

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
  @override
  void didUpdateWidget(covariant ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      setState(() {});
    }
  }

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Medical Reports',
        'upload': 'Upload Lab Report',
        'upload_sub': 'Select an image or PDF of your test results',
        'gallery': 'Gallery',
        'camera': 'Camera',
        'upload_pdf': 'Upload PDF',
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
        'upload_sub': 'अपने परीक्षण परिणामों की छवि या PDF चुनें',
        'gallery': 'गैलरी',
        'camera': 'कैमरा',
        'upload_pdf': 'PDF अपलोड करें',
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
        'upload_sub': 'ನಿಮ್ಮ ಪರೀಕ್ಷಾ ಫಲಿತಾಂಶಗಳ ಚಿತ್ರ ಅಥವಾ PDF ಆಯ್ಕೆಮಾಡಿ',
        'gallery': 'ಗ್ಯಾಲರಿ',
        'camera': 'ಕ್ಯಾಮರಾ',
        'upload_pdf': 'PDF ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
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
        'upload_sub': 'உங்கள் சோதனை முடிவுகளின் படம் அல்லது PDF-ஐத் தேர்ந்தெடுக்கவும்',
        'gallery': 'கேலரி',
        'camera': 'கேமரா',
        'upload_pdf': 'PDF பதிவேற்றவும்',
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
        'upload_sub': 'നിങ്ങളുടെ പരിശോധനാ ഫലങ്ങളുടെ ചിത്രമോ PDF-ഓ തിരഞ്ഞെടുക്കുക',
        'gallery': 'ഗാലറി',
        'camera': 'ക്യാമറ',
        'upload_pdf': 'PDF അപ്‌ലോഡ് ചെയ്യുക',
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
        'upload_sub': 'మీ పరీక్ష ఫలితాల చిత్రం లేదా PDF ఎంచుకోండి',
        'gallery': 'గ్యాలరీ',
        'camera': 'కెమెరా',
        'upload_pdf': 'PDF అప్‌లోడ్ చేయండి',
        'analyze': 'AI తో విశ్లేషించండి',
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
      final appDir = await getApplicationDocumentsDirectory();
      final localFile = await File(pickedFile.path).copy('${appDir.path}/${pickedFile.name}');

      setState(() {
        selectedReport = localFile;
        summary = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final localFile = await File(pickedFile.path).copy('${appDir.path}/${pickedFile.name}');

      setState(() {
        selectedReport = localFile;
        summary = null;
      });
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final appDir = await getApplicationDocumentsDirectory();
        final targetName = file.name.isNotEmpty ? file.name : 'report.pdf';
        File? localFile;

        if (file.path != null && file.path!.isNotEmpty) {
          localFile = await File(file.path!).copy('${appDir.path}/$targetName');
        } else if (file.bytes != null) {
          localFile = await File('${appDir.path}/$targetName').writeAsBytes(file.bytes!);
        }

        if (localFile != null && mounted) {
          setState(() {
            selectedReport = localFile;
            summary = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open PDF picker: $e")),
        );
      }
    }
  }

  Future<void> _analyzeReport() async {
    if (selectedReport == null) return;

    setState(() {
      isAnalyzing = true;
      summary = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final result = await ApiService.analyzeMedicalReport(
        selectedReport!,
        lang: widget.language,
        userId: user?.id,
      );

      setState(() {
        summary = result["summary"] ?? result["message"] ?? _getText('failed');
      });
      dashboardRefreshNotifier.value++;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text(
          _getText('title'),
          style: TextStyle(
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadCard(isDark, primaryColor),
            const SizedBox(height: 25),
            if (isAnalyzing) _buildLoadingState(isDark, primaryColor),
            if (summary != null && !isAnalyzing) _buildResultsCard(isDark, primaryColor),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(bool isDark, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
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
                  if (selectedReport!.path.toLowerCase().endsWith('.pdf'))
                    Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf_rounded, size: 52, color: primaryColor),
                          const SizedBox(height: 12),
                          Text(
                            selectedReport!.path.split(Platform.pathSeparator).last,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "PDF Report Ready for AI Analysis",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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
                color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 50, color: primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    _getText('upload'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getText('upload_sub'),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
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
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  onPressed: _takePhoto,
                  icon: Icons.camera_alt_outlined,
                  label: _getText('camera'),
                  isPrimary: false,
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            onPressed: _pickPdf,
            icon: Icons.picture_as_pdf_outlined,
            label: _getText('upload_pdf'),
            isPrimary: false,
            fullWidth: true,
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            onPressed: isAnalyzing || selectedReport == null ? null : _analyzeReport,
            icon: Icons.auto_awesome,
            label: _getText('analyze'),
            isPrimary: true,
            fullWidth: true,
            isDark: isDark,
            primaryColor: primaryColor,
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
    required bool isDark,
    required Color primaryColor,
    bool fullWidth = false,
  }) {
    final bgColor = isPrimary
        ? primaryColor
        : (isDark ? const Color(0xFF0F172A) : Colors.white);
    final fgColor = isPrimary
        ? (isDark ? const Color(0xFF0F172A) : Colors.white)
        : primaryColor;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: isPrimary ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: isDark ? const Color(0xFF334155) : primaryColor.withValues(alpha: 0.3)),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, Color primaryColor) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text(
            _getText('analyzing'),
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(bool isDark, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
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
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.assignment_turned_in_outlined, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _getText('results'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          MarkdownBody(
            data: summary!,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDark ? const Color(0xFFF8FAFC) : Colors.grey.shade800,
              ),
              h3: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                height: 2.5,
              ),
              listBullet: TextStyle(color: primaryColor),
              blockquote: TextStyle(color: isDark ? const Color(0xFFFBBF24) : Colors.orange.shade900),
              blockquoteDecoration: BoxDecoration(
                color: isDark ? const Color(0xFF451A03) : Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Colors.orange, width: 4),
                ),
              ),
              blockquotePadding: const EdgeInsets.all(12),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1.0, color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResultAction(
                icon: Icons.share_outlined,
                label: _getText('share'),
                onTap: () => ExportService.shareText(
                  summary!,
                  subject: _getText('title'),
                ),
                primaryColor: primaryColor,
              ),
              _buildResultAction(
                icon: Icons.picture_as_pdf_outlined,
                label: _getText('save_pdf'),
                onTap: () => ExportService.generateAndPrintPdf(
                  title: _getText('title'),
                  content: summary!,
                ),
                primaryColor: primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
