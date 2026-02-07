import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AiService {
  final Dio _dio;
  
  AiService(this._dio);

  Future<String> generateDiary({
    required List<File> images,
    required String contextData,
    String? mood,
    Map<String, dynamic>? weather,
    List<Map<String, dynamic>>? sources,
    String? userPrompt,
  }) async {
    try {
      // Convert images to base64 with compression
      final List<String> base64Images = [];
      for (final image in images) {
        // Compress image before encoding
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          image.absolute.path,
          minWidth: 1024,
          minHeight: 1024,
          quality: 70,
        );
        
        if (compressedBytes != null) {
          base64Images.add(base64Encode(compressedBytes));
        }
      }

      final response = await _dio.post('/api/ai/generate', data: {
        'prompt': userPrompt,
        'mood': mood,
        'weather': weather,
        'sources': sources,
        'context_data': contextData,
        'images': base64Images,
      });

      if (response.statusCode == 200) {
        final content = response.data['content'] as String?;
        if (content == null || content.isEmpty) {
           throw Exception('일기를 생성하지 못했습니다. (응답 없음)');
        }
        return content;
      } else {
        throw Exception('서버 오류가 발생했습니다. (Status: ${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('서버에 접속할 수 없습니다. 인터넷 연결을 확인해주세요.');
      }
      throw Exception('서버 요청 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('알 수 없는 오류가 발생했습니다: $e');
    }
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  const baseUrl = 'https://tag-diary-app.vercel.app';
  
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 45),
  ));
  
  return AiService(dio);
});
