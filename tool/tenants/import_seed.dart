// Unpack a tenant package directory or JSON into assets/tenants/<id>/.
//
// Usage:
//   dart run tool/tenants/import_seed.dart --input path/to/dir --output assets/tenants/tomsk
//   dart run tool/tenants/import_seed.dart --input package.json --output assets/tenants/demo
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  String? input;
  String? output;
  String? id;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--input':
        input = args[++i];
      case '--output':
        output = args[++i];
      case '--id':
        id = args[++i];
    }
  }
  if (input == null || output == null) {
    stderr.writeln(
      'Usage: dart run tool/tenants/import_seed.dart --input <dir|json> --output assets/tenants/<id> [--id slug]',
    );
    exit(1);
  }
  final inputPath = Directory(input).existsSync()
      ? Directory(input)
      : File(input);
  late Map<String, dynamic> json;
  final imageNames = <String>[];
  if (inputPath is Directory) {
    final dir = inputPath;
    final jsonFile = File('${dir.path}/tenant.json');
    final legacy = File('${dir.path}/${dir.uri.pathSegments.where((s) => s.isNotEmpty).last}.json');
    final pick = jsonFile.existsSync()
        ? jsonFile
        : (legacy.existsSync() ? legacy : null);
    if (pick == null) {
      stderr.writeln('No tenant.json or *.json in $input');
      exit(1);
    }
    json = jsonDecode(await pick.readAsString()) as Map<String, dynamic>;
    id ??= '${json['id'] ?? ''}'.trim();
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name.endsWith('.json')) continue;
      imageNames.add(name);
    }
  } else {
    final file = inputPath as File;
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map) {
      stderr.writeln('JSON root must be an object');
      exit(1);
    }
    json = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    id ??= '${json['id'] ?? ''}'.trim();
    final b64 = json['imagesBase64'];
    if (b64 is Map) {
      final outDir = Directory(output);
      outDir.createSync(recursive: true);
      for (final e in b64.entries) {
        final name = '${e.key}';
        final bytes = base64Decode('${e.value}');
        await File('${outDir.path}/$name').writeAsBytes(bytes);
        imageNames.add(name);
      }
      json.remove('imagesBase64');
    }
  }
  if (id == null || id!.isEmpty) {
    stderr.writeln('Missing tenant id');
    exit(1);
  }
  json['id'] = id;
  final outDir = Directory(output);
  outDir.createSync(recursive: true);
  await File('${outDir.path}/tenant.json')
      .writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  if (inputPath is Directory) {
    for (final name in imageNames) {
      final src = File('${inputPath.path}/$name');
      if (src.existsSync()) {
        await src.copy('${outDir.path}/$name');
      }
    }
  }
  stdout.writeln('Wrote ${outDir.path}/tenant.json and ${imageNames.length} image(s).');
}
