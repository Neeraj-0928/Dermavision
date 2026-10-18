import 'package:url_launcher/url_launcher.dart';

class ClinicService {
  static Future<bool> openNearbyDermatologists() async {
    // Standard Google Maps search query for nearby dermatologists
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=dermatologist+near+me',
    );

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}

    return false;
  }
}
