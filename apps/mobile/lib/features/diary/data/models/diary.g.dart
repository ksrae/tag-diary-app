// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiarySourceAdapter extends TypeAdapter<DiarySource> {
  @override
  final int typeId = 1;

  @override
  DiarySource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiarySource(
      type: fields[0] as String,
      appName: fields[1] as String,
      contentPreview: fields[2] as String,
      selected: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DiarySource obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.appName)
      ..writeByte(2)
      ..write(obj.contentPreview)
      ..writeByte(3)
      ..write(obj.selected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiarySourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeatherAdapter extends TypeAdapter<Weather> {
  @override
  final int typeId = 2;

  @override
  Weather read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Weather(
      temp: fields[0] as double,
      condition: fields[1] as String,
      icon: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Weather obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.temp)
      ..writeByte(1)
      ..write(obj.condition)
      ..writeByte(2)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiaryAdapter extends TypeAdapter<Diary> {
  @override
  final int typeId = 0;

  @override
  Diary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Diary(
      id: fields[0] as String,
      userId: fields[1] as String,
      content: fields[2] as String,
      mood: fields[3] as String?,
      weather: fields[4] as Weather?,
      sources: (fields[5] as List).cast<DiarySource>(),
      photos: (fields[6] as List).cast<String>(),
      isAiGenerated: fields[7] as bool,
      editCount: fields[8] as int,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Diary obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.mood)
      ..writeByte(4)
      ..write(obj.weather)
      ..writeByte(5)
      ..write(obj.sources)
      ..writeByte(6)
      ..write(obj.photos)
      ..writeByte(7)
      ..write(obj.isAiGenerated)
      ..writeByte(8)
      ..write(obj.editCount)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DiarySourceImpl _$$DiarySourceImplFromJson(Map<String, dynamic> json) =>
    _$DiarySourceImpl(
      type: json['type'] as String,
      appName: json['appName'] as String,
      contentPreview: json['contentPreview'] as String,
      selected: json['selected'] as bool? ?? true,
    );

Map<String, dynamic> _$$DiarySourceImplToJson(_$DiarySourceImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'appName': instance.appName,
      'contentPreview': instance.contentPreview,
      'selected': instance.selected,
    };

_$WeatherImpl _$$WeatherImplFromJson(Map<String, dynamic> json) =>
    _$WeatherImpl(
      temp: (json['temp'] as num).toDouble(),
      condition: json['condition'] as String,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$$WeatherImplToJson(_$WeatherImpl instance) =>
    <String, dynamic>{
      'temp': instance.temp,
      'condition': instance.condition,
      'icon': instance.icon,
    };

_$DiaryImpl _$$DiaryImplFromJson(Map<String, dynamic> json) => _$DiaryImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      mood: json['mood'] as String?,
      weather: json['weather'] == null
          ? null
          : Weather.fromJson(json['weather'] as Map<String, dynamic>),
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => DiarySource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      editCount: (json['editCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$DiaryImplToJson(_$DiaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'content': instance.content,
      'mood': instance.mood,
      'weather': instance.weather,
      'sources': instance.sources,
      'photos': instance.photos,
      'isAiGenerated': instance.isAiGenerated,
      'editCount': instance.editCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$DiaryListResponseImpl _$$DiaryListResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$DiaryListResponseImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => Diary.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$$DiaryListResponseImplToJson(
        _$DiaryListResponseImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
