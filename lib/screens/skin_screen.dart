import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../main.dart';

class SkinScreen extends StatefulWidget {
  static const String routeName = '/skin';
  final String language;

  const SkinScreen({super.key, this.language = "en"});

  @override
  State<SkinScreen> createState() => _SkinScreenState();
}

class _SkinScreenState extends State<SkinScreen> {
  bool isAnalyzing = false;
  File? selectedImage;
  String? analysisResult;
  final ImagePicker _picker = ImagePicker();
  @override
  void didUpdateWidget(covariant SkinScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      setState(() {});
    }
  }

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Skin Analysis',
        'upload': 'Upload Skin Image',
        'upload_sub': 'Take a clear photo of the rash, spot or skin condition',
        'gallery': 'Gallery',
        'camera': 'Camera',
        'analyze': 'Analyze Condition',
        'analyzing': 'AI is analyzing your skin image...',
        'results': 'Analysis & Advice',
        'disclaimer': 'Disclaimer: AI analysis is for informational purposes only. Consult a dermatologist for medical diagnosis.',
        'share': 'Share',
        'save_pdf': 'Save PDF',
        'error': 'Error analyzing skin image',
        'failed': 'Analysis failed',
      },
      'hi': {
        'title': 'त्वचा विश्लेषण',
        'upload': 'त्वचा की छवि अपलोड करें',
        'upload_sub': 'दाने या त्वचा की स्थिति की एक स्पष्ट तस्वीर लें',
        'gallery': 'गैलरी',
        'camera': 'कैमरा',
        'analyze': 'स्थिति का विश्लेषण करें',
        'analyzing': 'AI आपकी त्वचा की छवि का विश्लेषण कर रहा है...',
        'results': 'विश्लेषण और सलाह',
        'disclaimer': 'अस्वीकरण: AI विश्लेषण केवल जानकारी के लिए है। चिकित्सा निदान के लिए त्वचा विशेषज्ञ से परामर्श लें।',
        'share': 'शेयर करें',
        'save_pdf': 'PDF सहेजें',
        'error': 'त्वचा की छवि विश्लेषण में त्रुटि',
        'failed': 'विश्लेषण विफल रहा',
      },
      'kn': {
        'title': 'ಚರ್ಮದ ವಿಶ್ಲೇಷಣೆ',
        'upload': 'ಚರ್ಮದ ಚಿತ್ರವನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
        'upload_sub': 'ಚರ್ಮದ ಸ್ಥಿತಿಯ ಸ್ಪಷ್ಟ ಫೋಟೋ ತೆಗೆದುಕೊಳ್ಳಿ',
        'gallery': 'ಗ್ಯಾಲರಿ',
        'camera': 'ಕ್ಯಾಮರಾ',
        'analyze': 'ಸ್ಥಿತಿಯನ್ನು ವಿಶ್ಲೇಷಿಸಿ',
        'analyzing': 'AI ನಿಮ್ಮ ಚರ್ಮದ ಚಿತ್ರವನ್ನು ವಿಶ್ಲೇಷಿಸುತ್ತಿದೆ...',
        'results': 'ವಿಶ್ಲೇಷಣೆ ಮತ್ತು ಸಲಹೆ',
        'disclaimer': 'ಹಕ್ಕುತ್ಯಾಗ: AI ವಿಶ್ಲೇಷಣೆಯು ಮಾಹಿತಿಗಾಗಿ ಮಾತ್ರ. ವೈದ್ಯಕೀಯ ರೋಗನಿರ್ಣಯಕ್ಕಾಗಿ ಚರ್ಮಶಾಸ್ತ್ರಜ್ಞರನ್ನು ಸಂಪರ್ಕಿಸಿ.',
        'share': 'ಹಂಚಿಕೊಳ್ಳಿ',
        'save_pdf': 'PDF ಉಳಿಸಿ',
        'error': 'ಚರ್ಮದ ಚಿತ್ರ ವಿಶ್ಲೇಷಿಸುವಲ್ಲಿ ದೋಷ',
        'failed': 'ವಿಶ್ಲೇಷಣೆ ವಿಫಲವಾಗಿದೆ',
      },
      'ta': {
        'title': 'தோல் பகுப்பாய்வு',
        'upload': 'தோல் படத்தைப் பதிவேற்றவும்',
        'upload_sub': 'தோல் நிலையின் தெளிவான புகைப்படத்தை எடுக்கவும்',
        'gallery': 'கேலரி',
        'camera': 'கேமரா',
        'analyze': 'நிலையைப் பகுப்பாய்வு செய்க',
        'analyzing': 'AI உங்கள் தோல் படத்தைப் பகுப்பாய்வு செய்கிறது...',
        'results': 'பகுப்பாய்வு & ஆலோசனை',
        'disclaimer': 'மறுப்பு: AI பகுப்பாய்வு தகவல் நோக்கங்களுக்காக மட்டுமே. மருத்துவ நோயறிதலுக்கு தோல் மருத்துவரை அணுகவும்.',
        'share': 'பகிர்',
        'save_pdf': 'PDF சேமி',
        'error': 'தோல் படத்தைப் பகுப்பாய்வு செய்வதில் பிழை',
        'failed': 'பகுப்பாய்வு தோல்வி',
      },
      'ml': {
        'title': 'ചർമ്മ വിശകലനം',
        'upload': 'ചർമ്മ ചിത്രം അപ്‌ലോഡ് ചെയ്യുക',
        'upload_sub': 'ചർമ്മത്തിന്റെ അവസ്ഥയുടെ വ്യക്തമായ ഫോട്ടോ എടുക്കുക',
        'gallery': 'ഗാലറി',
        'camera': 'ക്യാമറ',
        'analyze': 'അവസ്ഥ വിശകലനം ചെയ്യുക',
        'analyzing': 'AI നിങ്ങളുടെ ചർമ്മ ചിത്രം വിശകലനം ചെയ്യുന്നു...',
        'results': 'വിശകലനവും ഉപദേശവും',
        'disclaimer': 'നിരാകരണം: AI വിശകലനം വിവര ആവശ്യങ്ങൾക്ക് മാത്രമുള്ളതാണ്. മെഡിക്കൽ രോഗനിർണയത്തിനായി ഒരു ഡെർമറ്റോളജിസ്റ്റിനെ സമീപിക്കുക.',
        'share': 'പങ്കിടുക',
        'save_pdf': 'PDF സേവ് ചെയ്യുക',
        'error': 'ചർമ്മ ചിത്രം വിശകലനം ചെയ്യുന്നതിൽ പിശക്',
        'failed': 'വിശകലനം പരാജയപ്പെട്ടു',
      },
      'te': {
        'title': 'చర్మ విశ్లేషణ',
        'upload': 'చర్మ చిత్రాన్ని అప్‌లోడ్ చేయండి',
        'upload_sub': 'చర్మ స్థితి స్పష్టమైన ఫోటో తీయండి',
        'gallery': 'గ్యాలరీ',
        'camera': 'కెమెరా',
        'analyze': 'పరిస్థితిని విశ్లేషించండి',
        'analyzing': 'AI మీ చర్మ చిత్రాన్ని విశ్లేషిస్తోంది...',
        'results': 'విశ్లేషణ & సలహా',
        'disclaimer': 'నిరాకరణ: AI విశ్లేషణ సమాచార ప్రయోజనాల కోసం మాత్రమే. వైద్య నిర్ధారణ కోసం చర్మ వైద్యుడిని సంప్రదించండి.',
        'share': 'షేర్ చేయండి',
        'save_pdf': 'PDF సేవ్ చేయండి',
        'error': 'చర్మ చిత్రాన్ని విశ్లేషించడంలో లోపం',
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
        selectedImage = localFile;
        analysisResult = null;
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
        selectedImage = localFile;
        analysisResult = null;
      });
    }
  }

  Future<void> _analyzeSkin() async {
    if (selectedImage == null) return;

    setState(() {
      isAnalyzing = true;
      analysisResult = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final result = await ApiService.analyzeSkin(
        selectedImage!,
        lang: widget.language,
        userId: user?.id,
      );

      setState(() {
        analysisResult = result.isNotEmpty ? result : _getText('failed');
      });
      dashboardRefreshNotifier.value++;
    } catch (e) {
      setState(() {
        analysisResult = "${_getText('error')}: $e";
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
    final primaryColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);

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
            if (analysisResult != null && !isAnalyzing) _buildResultsCard(isDark, primaryColor),
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
          if (selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.file(
                    selectedImage!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        selectedImage = null;
                        analysisResult = null;
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
                  Icon(Icons.healing_outlined, size: 50, color: primaryColor),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _getText('upload_sub'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
                        fontSize: 13,
                      ),
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
            onPressed: isAnalyzing || selectedImage == null ? null : _analyzeSkin,
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
                child: Icon(Icons.healing_rounded, color: primaryColor, size: 20),
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
            data: analysisResult!,
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
            ),
            child: Text(
              _getText('disclaimer'),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                height: 1.4,
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
                  analysisResult!,
                  subject: _getText('title'),
                ),
                primaryColor: primaryColor,
              ),
              _buildResultAction(
                icon: Icons.picture_as_pdf_outlined,
                label: _getText('save_pdf'),
                onTap: () => ExportService.generateAndPrintPdf(
                  title: _getText('title'),
                  content: analysisResult!,
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
