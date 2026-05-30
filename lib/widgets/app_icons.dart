import 'package:flutter/material.dart';

/// Maps the prototype's Lucide-style icon names to the closest Material icon.
/// The design notes that its glyphs map closely to Lucide; Material's outlined
/// set is the nearest dependency-free equivalent.
const Map<String, IconData> _icons = {
  'search': Icons.search,
  'plus': Icons.add,
  'qr': Icons.qr_code_2,
  'qrScan': Icons.qr_code_scanner,
  'copy': Icons.copy_rounded,
  'check': Icons.check_rounded,
  'checkCircle': Icons.check_circle,
  'chevR': Icons.chevron_right,
  'chevL': Icons.chevron_left,
  'chevDown': Icons.keyboard_arrow_down_rounded,
  'x': Icons.close_rounded,
  'settings': Icons.settings,
  'drive': Icons.add_to_drive,
  'cloud': Icons.cloud_outlined,
  'cloudCheck': Icons.cloud_done_outlined,
  'cloudOff': Icons.cloud_off_outlined,
  'cloudUp': Icons.backup_outlined,
  'fingerprint': Icons.fingerprint,
  'faceid': Icons.face_outlined,
  'lock': Icons.lock_outline,
  'shield': Icons.verified_user_outlined,
  'trash': Icons.delete_outline,
  'edit': Icons.edit_outlined,
  'key': Icons.vpn_key_outlined,
  'clock': Icons.schedule,
  'flash': Icons.bolt,
  'image': Icons.photo_library_outlined,
  'sun': Icons.wb_sunny_outlined,
  'user': Icons.person_outline,
  'bell': Icons.notifications_outlined,
  'info': Icons.info_outline,
  'sort': Icons.swap_vert,
  'refresh': Icons.refresh,
};

/// An app icon by its design name.
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const AppIcon(this.name, {super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      _icons[name] ?? Icons.help_outline,
      size: size,
      color: color ?? const Color(0xFFF4F4F2),
    );
  }
}
