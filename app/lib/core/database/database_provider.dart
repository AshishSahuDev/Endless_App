import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'isar_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  throw UnimplementedError('Override isarServiceProvider in main.dart');
});

final isarProvider = Provider<Isar>((ref) {
  return ref.watch(isarServiceProvider).isar;
});
