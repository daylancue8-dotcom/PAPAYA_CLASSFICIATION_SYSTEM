import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: const Text(
          'About',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text('🍈', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  const Text(
                    'PapayaCheck',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _InfoCard(
              title: 'About the System',
              content:
                  'PapayaCheck is a real-time papaya ripeness detection system developed as a finals project. It uses a Convolutional Neural Network (CNN) based on ResNet50 architecture with transfer learning to classify papaya fruits into three ripeness stages: Unripe, Ripe, and Overripe.',
            ),

            const SizedBox(height: 16),

            _InfoCard(
              title: 'How It Works',
              content:
                  '1. Point your camera at a papaya fruit\n2. Tap the capture button\n3. The AI model analyzes the image\n4. Results are shown with confidence scores\n5. A recommendation is provided based on the detected ripeness stage.',
            ),

            const SizedBox(height: 16),

            _InfoCard(
              title: 'Model Information',
              content:
                  'Architecture: ResNet50 (Transfer Learning)\nFramework: TensorFlow Lite\nInput Size: 224 x 224 pixels\nClasses: Unripe, Ripe, Overripe\nDataset: Locally collected from Tacloban City, Leyte\nValidated by: DA Regional Field Office VIII',
            ),

            const SizedBox(height: 16),

            _InfoCard(
              title: 'Research Study',
              content:
                  'Development of a Real-Time Papaya Ripeness Detection and Classification System Using Convolutional Neural Network\n\nInstitution: [Your School Name]\nLocation: Tacloban City, Leyte\nAcademic Year: 2025-2026',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;

  const _InfoCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
