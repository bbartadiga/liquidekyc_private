import 'package:flutter/material.dart';

/// Building blocks yang dipakai semua section di result screen.
/// Dipisah dari screen supaya tiap section bisa berdiri sendiri sebagai widget.

Widget buildSectionHeader(String title, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

Widget buildSection({
  required String title,
  required IconData icon,
  required Color color,
  required List<Widget> children,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

Widget buildDetailRow(String label, String value, {int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

/// Helper yang selalu tampil, kasih placeholder kalau null
Widget buildDetailPlaceholder(
  String label,
  String? value, {
  int maxLines = 1,
  String placeholder = '(data dari API)',
}) {
  final displayValue = (value != null && value.isNotEmpty) ? value : placeholder;
  final isEmpty = value == null || value.isEmpty;

  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isEmpty ? Colors.grey.shade400 : Colors.black87,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

/// Dual display original kanji/katakana + romaji latin
Widget buildDetailWithRomaji({
  required String label,
  String? original,
  String? romajiSync,
  Future<String?>? romajiFuture,
  int maxLines = 1,
}) {
  // Fast path: sync romaji available (instant — kana field / cached)
  if (romajiSync != null && romajiSync.isNotEmpty && romajiSync != original) {
    return renderRomajiPair(label, original, romajiSync, maxLines);
  }
  // Async path: FutureBuilder untuk full kanji transliteration
  if (romajiFuture != null) {
    return FutureBuilder<String?>(
      future: romajiFuture,
      builder: (context, snap) {
        final r = snap.data;
        if (r != null && r.isNotEmpty && r != original) {
          return renderRomajiPair(label, original, r, maxLines);
        }
        return buildDetailPlaceholder(label, original, maxLines: maxLines);
      },
    );
  }
  // Plain display kalau no romaji available
  return buildDetailPlaceholder(label, original, maxLines: maxLines);
}

Widget renderRomajiPair(String label, String? original, String romaji, int maxLines) {
  final isMasked = (original == null || original.isEmpty);
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                original ?? '(kosong)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isMasked ? Colors.grey.shade400 : Colors.black87,
                  fontStyle: isMasked ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  romaji,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.indigo.shade700,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Address split (prefecture / city / other) dengan sync + async romaji
List<Widget> buildAddressSplitRowsWithRomajiAndAsync({
  String? prefOriginal,
  String? prefRomajiSync,
  Future<String?>? prefRomajiFuture,
  String? cityOriginal,
  String? cityRomajiSync,
  Future<String?>? cityRomajiFuture,
  String? otherOriginal,
  String? otherRomajiSync,
  Future<String?>? otherRomajiFuture,
}) {
  final rows = <Widget>[];
  if (prefOriginal != null && prefOriginal.isNotEmpty) {
    rows.add(buildDetailWithRomaji(
      label: 'Prefecture',
      original: prefOriginal,
      romajiSync: prefRomajiSync,
      romajiFuture: prefRomajiFuture,
    ));
  }
  if (cityOriginal != null && cityOriginal.isNotEmpty) {
    rows.add(buildDetailWithRomaji(
      label: 'City / Municipality',
      original: cityOriginal,
      romajiSync: cityRomajiSync,
      romajiFuture: cityRomajiFuture,
    ));
  }
  if (otherOriginal != null && otherOriginal.isNotEmpty) {
    rows.add(buildDetailWithRomaji(
      label: 'Address (Rest)',
      original: otherOriginal,
      romajiSync: otherRomajiSync,
      romajiFuture: otherRomajiFuture,
    ));
  }
  return rows;
}

/// Generic async address split (SDK `OcrResult` native getter style)
List<Widget> buildAddressSplitRowsAsync<T>(
  T source, {
  required String? Function(T) prefGetter,
  required String? Function(T) cityGetter,
  required String? Function(T) otherGetter,
  required Future<String?>? Function(T) prefRomajiFuture,
  required Future<String?>? Function(T) cityRomajiFuture,
  required Future<String?>? Function(T) otherRomajiFuture,
  String? Function(T)? prefSyncGetter,
  String? Function(T)? citySyncGetter,
  String? Function(T)? otherSyncGetter,
}) {
  return buildAddressSplitRowsWithRomajiAndAsync(
    prefOriginal: prefGetter(source),
    prefRomajiSync: prefSyncGetter?.call(source),
    prefRomajiFuture: prefRomajiFuture(source),
    cityOriginal: cityGetter(source),
    cityRomajiSync: citySyncGetter?.call(source),
    cityRomajiFuture: cityRomajiFuture(source),
    otherOriginal: otherGetter(source),
    otherRomajiSync: otherSyncGetter?.call(source),
    otherRomajiFuture: otherRomajiFuture(source),
  );
}

/// Combine 3 `Future<String?>` jadi satu `Future<String?>` yang joined dengan space
Future<String?> joinAddressFuture(
  Future<String?>? a,
  Future<String?>? b,
  Future<String?>? c,
) async {
  final ra = await a;
  final rb = await b;
  final rc = await c;
  return [ra, rb, rc].where((s) => s != null && s.isNotEmpty).join(' ');
}

/// Address/name change detection + remarks flag
List<Widget> buildChangeDetectionRows({
  String? addressChanged,
  String? nameChanged,
  String? remarksExist,
}) {
  final rows = <Widget>[];
  final addrText = formatChangeFlag(addressChanged, 'Alamat');
  if (addrText != null) rows.add(buildDetailPlaceholder(addrText.$1, addrText.$2));
  final nameText = formatChangeFlag(nameChanged, 'Nama');
  if (nameText != null) rows.add(buildDetailPlaceholder(nameText.$1, nameText.$2));
  final remarksText = formatChangeFlag(remarksExist, 'Remarks');
  if (remarksText != null) rows.add(buildDetailPlaceholder(remarksText.$1, remarksText.$2));
  return rows;
}

/// Returns (label, value) atau null kalau null/invalid
(String, String)? formatChangeFlag(String? value, String baseLabel) {
  if (value == null || value.isEmpty) return null;
  String display;
  switch (value) {
    case '1':
      display = 'Baru diubah (red flag)';
      break;
    case '0':
      // No change → skip, ga perlu ditampilkan
      return null;
    default:
      display = value;
  }
  return (baseLabel, display);
}

/// Driver License types array (utk Driving License case)
Widget? buildLicenseTypeRow(List<String>? types) {
  if (types == null || types.isEmpty) return null;
  return buildDetailPlaceholder('Tipe SIM', types.join(' • '));
}

Widget buildSourceTag(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade600,
      ),
    ),
  );
}

Widget buildIdentityField(
  BuildContext context, {
  required String label,
  required String value,
  String? code,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      if (code != null && code.isNotEmpty) ...[
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    ],
  );
}

/// null = N/A (tidak dijalankan), true = sukses, false = gagal
Widget buildStatusItem({
  required IconData icon,
  required String label,
  bool? status,
}) {
  final Color bgColor;
  final IconData iconData;
  final Color iconColor;

  if (status == null) {
    bgColor = Colors.grey.shade100;
    iconData = Icons.remove;
    iconColor = Colors.grey;
  } else if (status) {
    bgColor = Colors.green.shade100;
    iconData = Icons.check;
    iconColor = Colors.green;
  } else {
    bgColor = Colors.red.shade100;
    iconData = Icons.close;
    iconColor = Colors.red;
  }

  return Column(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData,
          color: iconColor,
          size: 20,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
      ),
    ],
  );
}

Widget buildApiStatusRow(String label, bool success, {int? count}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(
          success ? Icons.check_circle : Icons.error,
          size: 16,
          color: success ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count photos',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    ),
  );
}

String formatDate(String date) {
  if (date.length == 8) {
    return '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)}';
  }
  return date;
}

String formatSex(String sex) {
  switch (sex) {
    case '1':
      return 'Laki-laki';
    case '2':
      return 'Perempuan';
    default:
      return sex;
  }
}

/// 個人番号 hanya tampil 4 digit terakhir
String? maskMyNumber(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value.length <= 4) return '*******${value.substring(value.length - 4)}';
  return '*******${value.substring(value.length - 4)}';
}
