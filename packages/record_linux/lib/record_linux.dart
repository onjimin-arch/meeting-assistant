library record_linux;

import 'dart:typed_data';
import 'package:record_platform_interface/record_platform_interface.dart';

/// Android 빌드에서 Dart 컴파일러가 record_linux를 포함하지만
/// 실제 런타임에서는 record_android가 사용되므로 모든 메서드는 스텁.
class RecordLinux extends RecordPlatform {
  @override
  Future<void> create(String recorderId) async {}

  @override
  Future<void> dispose(String recorderId) async {}

  @override
  Future<void> start(String recorderId, RecordConfig config) async {}

  @override
  Future<Stream<Uint8List>> startStream(
      String recorderId, RecordConfig config) async {
    return Stream<Uint8List>.empty();
  }

  @override
  Future<String?> stop(String recorderId) async => null;

  @override
  Future<void> pause(String recorderId) async {}

  @override
  Future<void> resume(String recorderId) async {}

  @override
  Future<bool> isPaused(String recorderId) async => false;

  @override
  Future<bool> isRecording(String recorderId) async => false;

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) async =>
      false;

  @override
  Future<Amplitude> getAmplitude(String recorderId) async =>
      Amplitude(current: -160, max: -160);
}
