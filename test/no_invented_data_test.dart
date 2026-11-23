import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard: **nggak ngarang data domain**.
///
/// Tabel/daftar nilai yang berasal dari kartu, OCR, spec Liquid, atau API BE
/// (kode status tinggal, label kebangsaan, daftar dropdown, ...) wajib punya
/// sumber yang jelas di doc comment TEPAT DI ATAS deklarasinya — nomor
/// halaman spec, nama endpoint BE, atau file + fungsi di host app.
///
/// Tabel tanpa sumber = karangan. Aturan ini datang dari CONSTRAINTS.md.
///
/// Pengecualian (token desain & daftar key sensitif) ada di [_exempted].
void main() {
  test('setiap tabel data domain punya sumber', () {
    final violations = <String>[];

    for (final file in _dartFilesIn('lib')) {
      if (_exempted.contains(file.path)) continue;

      final content = file.readAsStringSync();
      for (final table in _domainTables(content)) {
        if (!_hasSourceMarkerAbove(content, table.offset)) {
          violations.add(
            '${file.path}:${table.line} — tabel "${table.name}" nggak ada '
            'penanda sumber di atas deklarasinya '
            '(tambah "SUMBER: ..." / "Refs: ..." di doc comment-nya)',
          );
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Tabel data domain tanpa sumber:\n${violations.join('\n')}',
    );
  });
}

/// File yang tabelnya bukan data domain (token desain, daftar key).
const Set<String> _exempted = <String>{
  'lib/core/constant/app_colors.dart',
  'lib/persentation/styles/app_theme.dart',
  'lib/core/services/log_sanitizer.dart',
};

/// Penanda sumber yang sahih.
final RegExp _sourceMarker = RegExp(
  r'SUMBER\s*:|sumber\s*:|Source\s*:|Refs?\s*:|https?://|host app|\bspec\b',
  caseSensitive: false,
);

/// True kalau doc comment tepat di atas deklarasi [offset] punya sumber.
bool _hasSourceMarkerAbove(String content, int offset) {
  final before = content.substring(0, offset);
  final lines = before.split('\n');

  // Doc comment = baris `///` yang nempel langsung di atas deklarasi.
  // Elemen terakhir hasil split biasanya kosong (deklarasi mulai di baris
  // baru) — lewatin dulu.
  var start = lines.length - 1;
  if (start >= 0 && lines[start].trim().isEmpty) start--;

  final docLines = <String>[];
  for (var i = start; i >= 0; i--) {
    final line = lines[i].trim();
    if (line.startsWith('///')) {
      docLines.add(line);
      continue;
    }
    break;
  }
  return docLines.any(_sourceMarker.hasMatch);
}

/// Tabel data domain yang isinya >= 5 entri.
class _DomainTable {
  final String name;
  final int offset;
  final int line;

  const _DomainTable(this.name, this.offset, this.line);
}

List<_DomainTable> _domainTables(String content) {
  final tables = <_DomainTable>[];

  // const Map<String, String> nama = <String, String>{ ... }
  final mapPattern = RegExp(
    r'(?:static\s+)?(?:const|final)\s+Map<String,\s*String>\s+(\w+)\s*=\s*<String,\s*String>\{',
  );
  for (final match in mapPattern.allMatches(content)) {
    if (_entryCount(content, match.end) >= 5) {
      tables.add(_DomainTable(
        match.group(1)!,
        match.start,
        '\n'.allMatches(content.substring(0, match.start)).length + 1,
      ));
    }
  }

  // static const List<String> nama = <String>[ ... ]
  final listPattern = RegExp(
    r'(?:static\s+)?(?:const|final)\s+List<String>\s+(\w+)\s*=\s*<String>\[',
  );
  for (final match in listPattern.allMatches(content)) {
    if (_entryCount(content, match.end) >= 5) {
      tables.add(_DomainTable(
        match.group(1)!,
        match.start,
        '\n'.allMatches(content.substring(0, match.start)).length + 1,
      ));
    }
  }

  return tables;
}

/// Berapa entri yang ada di dalam literal yang dibuka di [offset].
int _entryCount(String content, int offset) {
  var depth = 1;
  var entries = 0;
  var inString = false;
  var quote = '';

  for (var i = offset; i < content.length; i++) {
    final char = content[i];

    if (inString) {
      if (char == quote && content[i - 1] != r'\') inString = false;
      continue;
    }

    if (char == "'" || char == '"') {
      inString = true;
      quote = char;
      continue;
    }

    if (char == '{' || char == '[') depth++;
    if (char == '}' || char == ']') {
      depth--;
      if (depth == 0) return entries;
    }
    if (char == ',' && depth == 1) entries++;
  }
  return entries;
}

List<File> _dartFilesIn(String directoryPath) {
  final directory = Directory(directoryPath);
  if (!directory.existsSync()) return const <File>[];

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}
