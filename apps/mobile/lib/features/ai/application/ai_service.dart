import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      // Convert images to base64
      final List<String> base64Images = [];
      for (final image in images) {
        final bytes = await image.readAsBytes();
        base64Images.add(base64Encode(bytes));
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
        return response.data['content'] ?? '일기를 생성하지 못했습니다.';
      } else {
        return '서버 오류가 발생했습니다. (Status: ${response.statusCode})';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout) {
        return '서버에 접속할 수 없습니다. 일기를 작성할 수 없습니다.';
      }
      return '서버 요청 중 오류가 발생했습니다: ${e.message}';
    } catch (e) {
      return '알 수 없는 오류가 발생했습니다: $e';
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
