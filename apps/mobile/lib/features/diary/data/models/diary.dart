import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'diary.freezed.dart';
part 'diary.g.dart';

/// Source of collected data
@freezed
@HiveType(typeId: 1)
class DiarySource with _$DiarySource {
  const factory DiarySource({
    @HiveField(0) required String type,
    @HiveField(1) required String appName,
    @HiveField(2) required String contentPreview,
    @HiveField(3) @Default(true) bool selected,
  }) = _DiarySource;

  factory DiarySource.fromJson(Map<String, dynamic> json) =>
      _$DiarySourceFromJson(json);
}

/// Weather data
@freezed
@HiveType(typeId: 2)
class Weather with _$Weather {
  const factory Weather({
    @HiveField(0) required double temp,
    @HiveField(1) required String condition,
    @HiveField(2) String? icon,
  }) = _Weather;

  factory Weather.fromJson(Map<String, dynamic> json) =>
      _$WeatherFromJson(json);
}

/// Diary entry model
@freezed
@HiveType(typeId: 0)
class Diary with _$Diary {
  const factory Diary({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    @HiveField(2) required String content,
    @HiveField(3) String? mood,
    @HiveField(4) Weather? weather,
    @HiveField(5) @Default([]) List<DiarySource> sources,
    @HiveField(6) @Default([]) List<String> photos,
    @HiveField(7) @Default(false) bool isAiGenerated,
    @HiveField(8) @Default(0) int editCount,
    @HiveField(9) required DateTime createdAt,
    @HiveField(10) DateTime? updatedAt,
  }) = _Diary;

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);
}

/// Paginated diary list response
@freezed
class DiaryListResponse with _$DiaryListResponse {
  const factory DiaryListResponse({
    required List<Diary> items,
    required int total,
    required int page,
    required int limit,
  }) = _DiaryListResponse;

  factory DiaryListResponse.fromJson(Map<String, dynamic> json) =>
      _$DiaryListResponseFromJson(json);
}
