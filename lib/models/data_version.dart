// lib/models/data_version.dart

import 'package:hive/hive.dart';

part 'data_version.g.dart';

@HiveType(typeId: 1)
class DataVersion extends HiveObject {
  @HiveField(0)
  final String version;

  @HiveField(1)
  final DateTime lastUpdated;

  DataVersion({
    required this.version,
    required this.lastUpdated,
  });
}
