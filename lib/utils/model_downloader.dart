import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 다운로드 진행 상태
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

/// LLM 모델 다운로드/캐싱 관리.
///
/// APK 자체에는 모델을 포함하지 않고, 사용자가 동의했을 때 한 번만
/// 외부 CDN에서 받아 앱 전용 저장소에 캐싱한다. 이후엔 캐시 사용.
///
/// **주의: 모델 다운로드 URL은 변경될 수 있습니다.**
/// 설정 화면에서 사용자가 직접 URL을 덮어쓸 수 있도록 [downloadFromUrl]을 제공.
class ModelDownloader {
  /// 기본 모델: Gemma 3 1B Instruct, 4-bit quantized, ~530MB.
  /// MediaPipe LLM Inference의 .task 형식.
  ///
  /// ※ 이 URL은 Google이 호스팅하는 공개 미러를 가정한 자리표시자입니다.
  /// 실제 운영 시엔 다음 중 하나를 사용하세요:
  ///  - Kaggle (인증 필요): https://www.kaggle.com/models/google/gemma-3
  ///  - HuggingFace 미러 (공개): https://huggingface.co/litert-community
  ///  - 자체 Google Cloud Storage 버킷
  static const ModelInfo gemma3_1B = ModelInfo(
    name: 'Gemma 3 1B (Instruct, int4)',
    filename: 'gemma3-1b-it-int4.task',
    url:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task?download=true',
    expectedBytes: 555 * 1024 * 1024, // ≈530MB
  );

  /// 큰 모델 옵션 (품질 우선): Gemma 2B int4, ~1.5GB
  static const ModelInfo gemma2_2B = ModelInfo(
    name: 'Gemma 2 2B (Instruct, int4)',
    filename: 'gemma2-2b-it-int4.task',
    url:
        'https://huggingface.co/litert-community/Gemma2-2B-IT/resolve/main/gemma2-2b-it-cpu-int4.task?download=true',
    expectedBytes: 1500 * 1024 * 1024,
  );

  /// 기본으로 쓸 모델
  static const ModelInfo defaultModel = gemma3_1B;

  Future<Directory> _modelDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'models'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> localFile(ModelInfo info) async {
    final dir = await _modelDir();
    return File(p.join(dir.path, info.filename));
  }

  /// 캐시 여부 확인 (크기로 느슨하게 검증)
  Future<bool> isCached(ModelInfo info) async {
    final f = await localFile(info);
    if (!await f.exists()) return false;
    final size = await f.length();
    return size >= (info.expectedBytes * 0.85).toInt();
  }

  /// 표준 모델 다운로드
  Future<File> download(
    ModelInfo info, {
    void Function(DownloadProgress)? onProgress,
  }) async {
    return downloadFromUrl(
      url: info.url,
      filename: info.filename,
      modelName: info.name,
      expectedBytes: info.expectedBytes,
      onProgress: onProgress,
    );
  }

  /// 임의 URL에서 다운로드 (설정 화면에서 사용자가 URL 덮어쓰는 경우)
  Future<File> downloadFromUrl({
    required String url,
    required String filename,
    required String modelName,
    int expectedBytes = 0,
    void Function(DownloadProgress)? onProgress,
  }) async {
    final dir = await _modelDir();
    final file = File(p.join(dir.path, filename));

    if (await file.exists()) {
      final size = await file.length();
      if (expectedBytes == 0 || size >= (expectedBytes * 0.85).toInt()) {
        debugPrint('[ModelDownloader] 캐시 사용: $filename ($size bytes)');
        return file;
      }
      debugPrint('[ModelDownloader] 손상된 캐시 삭제: $filename');
      await file.delete();
    }

    debugPrint('[ModelDownloader] 다운로드 시작: $url');
    final request = http.Request('GET', Uri.parse(url));
    request.followRedirects = true;
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception(
        '모델 다운로드 실패 (HTTP ${response.statusCode}): $url',
      );
    }

    final total = response.contentLength ??
        (expectedBytes > 0 ? expectedBytes : 0);
    final sink = file.openWrite();
    int received = 0;

    try {
      await response.stream.forEach((chunk) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(DownloadProgress(
          modelName: modelName,
          receivedBytes: received,
          totalBytes: total,
        ));
      });
      await sink.flush();
      await sink.close();
    } catch (e) {
      await sink.close();
      if (await file.exists()) await file.delete();
      rethrow;
    }

    debugPrint('[ModelDownloader] 다운로드 완료: ${file.path} ($received bytes)');
    return file;
  }

  /// 캐시된 모델 파일 경로 조회 (없으면 null)
  Future<String?> cachedPath(ModelInfo info) async {
    if (await isCached(info)) {
      return (await localFile(info)).path;
    }
    return null;
  }

  /// 캐시 삭제 (디스크 정리)
  Future<void> deleteCache(ModelInfo info) async {
    final f = await localFile(info);
    if (await f.exists()) await f.delete();
  }
}
