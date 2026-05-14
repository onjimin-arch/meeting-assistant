import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 모델 다운로드 진행 상태
class DownloadProgress {
  final String modelName;
  final int receivedBytes;
  final int totalBytes;
  final double percent;

  DownloadProgress({
    required this.modelName,
    required this.receivedBytes,
    required this.totalBytes,
  }) : percent = totalBytes <= 0 ? 0 : receivedBytes / totalBytes;
}

/// 모델 메타데이터
class ModelInfo {
  final String name;
  final String filename;
  final String url;
  final int expectedBytes;

  const ModelInfo({
    required this.name,
    required this.filename,
    required this.url,
    required this.expectedBytes,
  });
}

/// 모델 다운로드/캐싱 관리
///
/// APK 자체에는 모델을 포함하지 않고, 첫 실행 시 사용자 동의 하에 Wi-Fi로
/// 모델 파일을 받아 앱 전용 저장소에 캐싱한다.
///
/// 실제 URL은 ai-pipeline 에이전트가 최종 확정(HuggingFace mirror 또는
/// Google Cloud Storage). 아래는 자리표시자.
class ModelDownloader {
  static const ModelInfo whisperTiny = ModelInfo(
    name: 'Whisper Tiny',
    filename: 'whisper-tiny.bin',
    url: 'https://example.com/models/whisper-tiny.bin', // TODO: ai-pipeline
    expectedBytes: 78 * 1024 * 1024, // ≈75MB
  );

  static const ModelInfo gemma2B = ModelInfo(
    name: 'Gemma 2B (4-bit)',
    filename: 'gemma-2b-it-q4.bin',
    url: 'https://example.com/models/gemma-2b-it-q4.bin', // TODO: ai-pipeline
    expectedBytes: 1500 * 1024 * 1024, // ≈1.5GB
  );

  /// 앱 전용 모델 디렉토리 경로
  Future<Directory> _modelDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'models'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 특정 모델의 로컬 파일 경로
  Future<File> localFile(ModelInfo info) async {
    final dir = await _modelDir();
    return File(p.join(dir.path, info.filename));
  }

  /// 모델이 이미 받아져 있는지 확인
  Future<bool> isCached(ModelInfo info) async {
    final f = await localFile(info);
    if (!await f.exists()) return false;
    final size = await f.length();
    // 크기 검증은 느슨하게 (90% 이상이면 OK). 실제 운영에선 SHA256 권장.
    return size >= (info.expectedBytes * 0.9).toInt();
  }

  /// 모델 다운로드 (이미 캐시되어 있으면 즉시 반환)
  Future<File> download(
    ModelInfo info, {
    void Function(DownloadProgress)? onProgress,
  }) async {
    final file = await localFile(info);
    if (await isCached(info)) {
      debugPrint('[ModelDownloader] 캐시 사용: ${info.filename}');
      return file;
    }

    debugPrint('[ModelDownloader] 다운로드 시작: ${info.url}');
    final request = http.Request('GET', Uri.parse(info.url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception(
        '모델 다운로드 실패 (${response.statusCode}): ${info.url}',
      );
    }

    final total = response.contentLength ?? info.expectedBytes;
    final sink = file.openWrite();
    int received = 0;

    await response.stream.listen(
      (chunk) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(DownloadProgress(
          modelName: info.name,
          receivedBytes: received,
          totalBytes: total,
        ));
      },
      onDone: () async {
        await sink.flush();
        await sink.close();
      },
      onError: (e) async {
        await sink.close();
        if (await file.exists()) await file.delete();
        throw e;
      },
      cancelOnError: true,
    ).asFuture();

    debugPrint('[ModelDownloader] 다운로드 완료: ${file.path}');
    return file;
  }
}
