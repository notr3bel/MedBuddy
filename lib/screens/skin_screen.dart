import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

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

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Skin Analysis',
        'upload': 'Check Skin Condition',
        'upload_sub': 'Select a clear image of the area',
        'gallery': 'Gallery',
        'camera': 'Camera',
        'analyze': 'Start Skin Analysis',
        'analyzing': 'Analyzing skin patterns...',
        'results': 'AI Assessment',
        'note': 'Note: This analysis is for informational purposes only and does not replace professional medical advice.',
        'error': 'Error analyzing skin',
      },
      'hi': {
        'title': 'त्वचा विश्लेषण',
        'upload': 'त्वचा की स्थिति की जाँच करें',
        'upload_sub': 'क्षेत्र की एक स्पष्ट छवि चुनें',
        'gallery': 'गैलरी',
        'camera': 'कैमरा',
        'analyze': 'त्वचा विश्लेषण शुरू करें',
        'analyzing': 'त्वचा के पैटर्न का विश्लेषण कर रहा है...',
        'results': 'AI मूल्यांकन',
        'note': 'नोट: यह विश्लेषण केवल सूचनात्मक उद्देश्यों के लिए है और पेशेवर चिकित्सा सलाह की जगह नहीं लेता है।',
        'error': 'त्वचा विश्लेषण में त्रुटि',
      },
      'kn': {
        'title': 'ಚರ್ಮದ ವಿಶ್ಲೇಷಣೆ',
        'upload': 'ಚರ್ಮದ ಸ್ಥಿತಿಯನ್ನು ಪರೀಕ್ಷಿಸಿ',
        'upload_sub': 'ಪ್ರದೇಶದ ಸ್ಪಷ್ಟ ಚಿತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
        'gallery': 'ಗ್ಯಾಲರಿ',
        'camera': 'ಕ್ಯಾಮರಾ',
        'analyze': 'ಚರ್ಮದ ವಿಶ್ಲೇಷಣೆ ಪ್ರಾರಂಭಿಸಿ',
        'analyzing': 'ಚರ್ಮದ ಮಾದರಿಗಳನ್ನು ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ...',
        'results': 'AI ಮೌಲ್ಯಮಾಪನ',
        'note': 'ಸೂಚನೆ: ಈ ವಿಶ್ಲೇಷಣೆಯು ಮಾಹಿತಿ ಉದ್ದೇಶಗಳಿಗಾಗಿ ಮಾತ್ರ ಮತ್ತು ವೃತ್ತಿಪರ ವೈದ್ಯಕೀಯ ಸಲಹೆಯನ್ನು ಬದಲಿಸುವುದಿಲ್ಲ.',
        'error': 'ಚರ್ಮವನ್ನು ವಿಶ್ಲೇಷಿಸುವಲ್ಲಿ ದೋಷ',
      },
      'ta': {
        'title': 'சருமப் பகுப்பாய்வு',
        'upload': 'சரும நிலையைச் சரிபார்க்கவும்',
        'upload_sub': 'பகுதியின் தெளிவான படத்தைத் தேர்ந்தெடுக்கவும்',
        'gallery': 'கேலரி',
        'camera': 'கேமரா',
        'analyze': 'சருமப் பகுப்பாய்வைத் தொடங்கவும்',
        'analyzing': 'சரும முறைகளை பகுப்பாய்வு செய்கிறது...',
        'results': 'AI மதிப்பீடு',
        'note': 'குறிப்பு: இந்த பகுப்பாய்வு தகவல் நோக்கங்களுக்காக மட்டுமே மற்றும் தொழில்முறை மருத்துவ ஆலோசனையை மாற்றாது.',
        'error': 'சருமத்தைப் பகுப்பாய்வு செய்வதில் பிழை',
      },
      'ml': {
        'title': 'ചർമ്മ വിശകലനം',
        'upload': 'ചർമ്മത്തിന്റെ അവസ്ഥ പരിശോധിക്കുക',
        'upload_sub': 'പ്രദേശത്തിന്റെ വ്യക്തമായ ചിത്രം തിരഞ്ഞെടുക്കുക',
        'gallery': 'ഗാലറി',
        'camera': 'ക്യാമറ',
        'analyze': 'ചർമ്മ വിശകലനം ആരംഭിക്കുക',
        'analyzing': 'ചർമ്മ പാറ്റേണുകൾ വിശകലനം ചെയ്യുന്നു...',
        'results': 'AI വിലയിരുത്തൽ',
        'note': 'ശ്രദ്ധിക്കുക: ഈ വിശകലനം വിവരദായക ആവശ്യങ്ങൾക്കായി മാത്രമുള്ളതാണ്, പ്രൊഫഷണൽ മെഡിക്കൽ ഉപദേശത്തിന് പകരമാവില്ല.',
        'error': 'ചർമ്മം വിശകലനം ചെയ്യുന്നതിൽ പിശക്',
      },
      'te': {
        'title': 'చర్మ విశ్లేషణ',
        'upload': 'చర్మ పరిస్థితిని తనిఖీ చేయండి',
        'upload_sub': 'ప్రాంతం యొక్క స్పష్టమైన చిత్రాన్ని ఎంచుకోండి',
        'gallery': 'గ్యాలరీ',
        'camera': 'కెమెరా',
        'analyze': 'చర్మ విశ్లేషణ ప్రారంభించండి',
        'analyzing': 'చర్మ నమూనాలను విశ్లేషిస్తోంది...',
        'results': 'AI అంచనా',
        'note': 'గమనిక: ఈ విశ్లేషణ సమాచార ప్రయోజనాల కోసం మాత్రమే మరియు వృత్తిపరమైన వైద్య సలహాకు ప్రత్యామ్నాయం కాదు.',
        'error': 'చర్మ విశ్లేషణలో లోపం',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        analysisResult = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        analysisResult = null;
      });
    }
  }

  Future<void> _analyzeSkin() async {
    if (selectedImage == null) return;

    setState(() {
      isAnalyzing = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      String result = await ApiService.analyzeSkin(
        selectedImage!,
        lang: widget.language,
        userId: user?.id,
      );

      setState(() {
        analysisResult = result;
      });
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
            if (analysisResult != null && !isAnalyzing) _buildResultsCard(),
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
                color: Colors.teal.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.1), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_front_outlined, size: 50, color: Colors.teal.shade300),
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
            onPressed: isAnalyzing || selectedImage == null ? null : _analyzeSkin,
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
                child: const Icon(Icons.health_and_safety_outlined, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Text(_getText('results'), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          MarkdownBody(
            data: analysisResult!,
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
                height: 2.5,
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
                  analysisResult!,
                  subject: _getText('title'),
                ),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text('Share'), // Note: Should probably add translation
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => ExportService.generateAndPrintPdf(
                  title: _getText('title'),
                  content: analysisResult!,
                ),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text('Save PDF'),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getText('note'),
                    style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
