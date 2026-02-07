// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DiarySource _$DiarySourceFromJson(Map<String, dynamic> json) {
  return _DiarySource.fromJson(json);
}

/// @nodoc
mixin _$DiarySource {
  @HiveField(0)
  String get type => throw _privateConstructorUsedError;
  @HiveField(1)
  String get appName => throw _privateConstructorUsedError;
  @HiveField(2)
  String get contentPreview => throw _privateConstructorUsedError;
  @HiveField(3)
  bool get selected => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DiarySourceCopyWith<DiarySource> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiarySourceCopyWith<$Res> {
  factory $DiarySourceCopyWith(
          DiarySource value, $Res Function(DiarySource) then) =
      _$DiarySourceCopyWithImpl<$Res, DiarySource>;
  @useResult
  $Res call(
      {@HiveField(0) String type,
      @HiveField(1) String appName,
      @HiveField(2) String contentPreview,
      @HiveField(3) bool selected});
}

/// @nodoc
class _$DiarySourceCopyWithImpl<$Res, $Val extends DiarySource>
    implements $DiarySourceCopyWith<$Res> {
  _$DiarySourceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? appName = null,
    Object? contentPreview = null,
    Object? selected = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      appName: null == appName
          ? _value.appName
          : appName // ignore: cast_nullable_to_non_nullable
              as String,
      contentPreview: null == contentPreview
          ? _value.contentPreview
          : contentPreview // ignore: cast_nullable_to_non_nullable
              as String,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiarySourceImplCopyWith<$Res>
    implements $DiarySourceCopyWith<$Res> {
  factory _$$DiarySourceImplCopyWith(
          _$DiarySourceImpl value, $Res Function(_$DiarySourceImpl) then) =
      __$$DiarySourceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String type,
      @HiveField(1) String appName,
      @HiveField(2) String contentPreview,
      @HiveField(3) bool selected});
}

/// @nodoc
class __$$DiarySourceImplCopyWithImpl<$Res>
    extends _$DiarySourceCopyWithImpl<$Res, _$DiarySourceImpl>
    implements _$$DiarySourceImplCopyWith<$Res> {
  __$$DiarySourceImplCopyWithImpl(
      _$DiarySourceImpl _value, $Res Function(_$DiarySourceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? appName = null,
    Object? contentPreview = null,
    Object? selected = null,
  }) {
    return _then(_$DiarySourceImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      appName: null == appName
          ? _value.appName
          : appName // ignore: cast_nullable_to_non_nullable
              as String,
      contentPreview: null == contentPreview
          ? _value.contentPreview
          : contentPreview // ignore: cast_nullable_to_non_nullable
              as String,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiarySourceImpl implements _DiarySource {
  const _$DiarySourceImpl(
      {@HiveField(0) required this.type,
      @HiveField(1) required this.appName,
      @HiveField(2) required this.contentPreview,
      @HiveField(3) this.selected = true});

  factory _$DiarySourceImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiarySourceImplFromJson(json);

  @override
  @HiveField(0)
  final String type;
  @override
  @HiveField(1)
  final String appName;
  @override
  @HiveField(2)
  final String contentPreview;
  @override
  @JsonKey()
  @HiveField(3)
  final bool selected;

  @override
  String toString() {
    return 'DiarySource(type: $type, appName: $appName, contentPreview: $contentPreview, selected: $selected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiarySourceImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.appName, appName) || other.appName == appName) &&
            (identical(other.contentPreview, contentPreview) ||
                other.contentPreview == contentPreview) &&
            (identical(other.selected, selected) ||
                other.selected == selected));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, appName, contentPreview, selected);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiarySourceImplCopyWith<_$DiarySourceImpl> get copyWith =>
      __$$DiarySourceImplCopyWithImpl<_$DiarySourceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiarySourceImplToJson(
      this,
    );
  }
}

abstract class _DiarySource implements DiarySource {
  const factory _DiarySource(
      {@HiveField(0) required final String type,
      @HiveField(1) required final String appName,
      @HiveField(2) required final String contentPreview,
      @HiveField(3) final bool selected}) = _$DiarySourceImpl;

  factory _DiarySource.fromJson(Map<String, dynamic> json) =
      _$DiarySourceImpl.fromJson;

  @override
  @HiveField(0)
  String get type;
  @override
  @HiveField(1)
  String get appName;
  @override
  @HiveField(2)
  String get contentPreview;
  @override
  @HiveField(3)
  bool get selected;
  @override
  @JsonKey(ignore: true)
  _$$DiarySourceImplCopyWith<_$DiarySourceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Weather _$WeatherFromJson(Map<String, dynamic> json) {
  return _Weather.fromJson(json);
}

/// @nodoc
mixin _$Weather {
  @HiveField(0)
  double get temp => throw _privateConstructorUsedError;
  @HiveField(1)
  String get condition => throw _privateConstructorUsedError;
  @HiveField(2)
  String? get icon => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WeatherCopyWith<Weather> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeatherCopyWith<$Res> {
  factory $WeatherCopyWith(Weather value, $Res Function(Weather) then) =
      _$WeatherCopyWithImpl<$Res, Weather>;
  @useResult
  $Res call(
      {@HiveField(0) double temp,
      @HiveField(1) String condition,
      @HiveField(2) String? icon});
}

/// @nodoc
class _$WeatherCopyWithImpl<$Res, $Val extends Weather>
    implements $WeatherCopyWith<$Res> {
  _$WeatherCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temp = null,
    Object? condition = null,
    Object? icon = freezed,
  }) {
    return _then(_value.copyWith(
      temp: null == temp
          ? _value.temp
          : temp // ignore: cast_nullable_to_non_nullable
              as double,
      condition: null == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as String,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WeatherImplCopyWith<$Res> implements $WeatherCopyWith<$Res> {
  factory _$$WeatherImplCopyWith(
          _$WeatherImpl value, $Res Function(_$WeatherImpl) then) =
      __$$WeatherImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) double temp,
      @HiveField(1) String condition,
      @HiveField(2) String? icon});
}

/// @nodoc
class __$$WeatherImplCopyWithImpl<$Res>
    extends _$WeatherCopyWithImpl<$Res, _$WeatherImpl>
    implements _$$WeatherImplCopyWith<$Res> {
  __$$WeatherImplCopyWithImpl(
      _$WeatherImpl _value, $Res Function(_$WeatherImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temp = null,
    Object? condition = null,
    Object? icon = freezed,
  }) {
    return _then(_$WeatherImpl(
      temp: null == temp
          ? _value.temp
          : temp // ignore: cast_nullable_to_non_nullable
              as double,
      condition: null == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as String,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WeatherImpl implements _Weather {
  const _$WeatherImpl(
      {@HiveField(0) required this.temp,
      @HiveField(1) required this.condition,
      @HiveField(2) this.icon});

  factory _$WeatherImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeatherImplFromJson(json);

  @override
  @HiveField(0)
  final double temp;
  @override
  @HiveField(1)
  final String condition;
  @override
  @HiveField(2)
  final String? icon;

  @override
  String toString() {
    return 'Weather(temp: $temp, condition: $condition, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeatherImpl &&
            (identical(other.temp, temp) || other.temp == temp) &&
            (identical(other.condition, condition) ||
                other.condition == condition) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, temp, condition, icon);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WeatherImplCopyWith<_$WeatherImpl> get copyWith =>
      __$$WeatherImplCopyWithImpl<_$WeatherImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeatherImplToJson(
      this,
    );
  }
}

abstract class _Weather implements Weather {
  const factory _Weather(
      {@HiveField(0) required final double temp,
      @HiveField(1) required final String condition,
      @HiveField(2) final String? icon}) = _$WeatherImpl;

  factory _Weather.fromJson(Map<String, dynamic> json) = _$WeatherImpl.fromJson;

  @override
  @HiveField(0)
  double get temp;
  @override
  @HiveField(1)
  String get condition;
  @override
  @HiveField(2)
  String? get icon;
  @override
  @JsonKey(ignore: true)
  _$$WeatherImplCopyWith<_$WeatherImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Diary _$DiaryFromJson(Map<String, dynamic> json) {
  return _Diary.fromJson(json);
}

/// @nodoc
mixin _$Diary {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get userId => throw _privateConstructorUsedError;
  @HiveField(2)
  String get content => throw _privateConstructorUsedError;
  @HiveField(3)
  String? get mood => throw _privateConstructorUsedError;
  @HiveField(4)
  Weather? get weather => throw _privateConstructorUsedError;
  @HiveField(5)
  List<DiarySource> get sources => throw _privateConstructorUsedError;
  @HiveField(6)
  List<String> get photos => throw _privateConstructorUsedError;
  @HiveField(7)
  bool get isAiGenerated => throw _privateConstructorUsedError;
  @HiveField(8)
  int get editCount => throw _privateConstructorUsedError;
  @HiveField(9)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @HiveField(10)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DiaryCopyWith<Diary> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiaryCopyWith<$Res> {
  factory $DiaryCopyWith(Diary value, $Res Function(Diary) then) =
      _$DiaryCopyWithImpl<$Res, Diary>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String userId,
      @HiveField(2) String content,
      @HiveField(3) String? mood,
      @HiveField(4) Weather? weather,
      @HiveField(5) List<DiarySource> sources,
      @HiveField(6) List<String> photos,
      @HiveField(7) bool isAiGenerated,
      @HiveField(8) int editCount,
      @HiveField(9) DateTime createdAt,
      @HiveField(10) DateTime? updatedAt});

  $WeatherCopyWith<$Res>? get weather;
}

/// @nodoc
class _$DiaryCopyWithImpl<$Res, $Val extends Diary>
    implements $DiaryCopyWith<$Res> {
  _$DiaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? content = null,
    Object? mood = freezed,
    Object? weather = freezed,
    Object? sources = null,
    Object? photos = null,
    Object? isAiGenerated = null,
    Object? editCount = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      mood: freezed == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String?,
      weather: freezed == weather
          ? _value.weather
          : weather // ignore: cast_nullable_to_non_nullable
              as Weather?,
      sources: null == sources
          ? _value.sources
          : sources // ignore: cast_nullable_to_non_nullable
              as List<DiarySource>,
      photos: null == photos
          ? _value.photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isAiGenerated: null == isAiGenerated
          ? _value.isAiGenerated
          : isAiGenerated // ignore: cast_nullable_to_non_nullable
              as bool,
      editCount: null == editCount
          ? _value.editCount
          : editCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $WeatherCopyWith<$Res>? get weather {
    if (_value.weather == null) {
      return null;
    }

    return $WeatherCopyWith<$Res>(_value.weather!, (value) {
      return _then(_value.copyWith(weather: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DiaryImplCopyWith<$Res> implements $DiaryCopyWith<$Res> {
  factory _$$DiaryImplCopyWith(
          _$DiaryImpl value, $Res Function(_$DiaryImpl) then) =
      __$$DiaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String userId,
      @HiveField(2) String content,
      @HiveField(3) String? mood,
      @HiveField(4) Weather? weather,
      @HiveField(5) List<DiarySource> sources,
      @HiveField(6) List<String> photos,
      @HiveField(7) bool isAiGenerated,
      @HiveField(8) int editCount,
      @HiveField(9) DateTime createdAt,
      @HiveField(10) DateTime? updatedAt});

  @override
  $WeatherCopyWith<$Res>? get weather;
}

/// @nodoc
class __$$DiaryImplCopyWithImpl<$Res>
    extends _$DiaryCopyWithImpl<$Res, _$DiaryImpl>
    implements _$$DiaryImplCopyWith<$Res> {
  __$$DiaryImplCopyWithImpl(
      _$DiaryImpl _value, $Res Function(_$DiaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? content = null,
    Object? mood = freezed,
    Object? weather = freezed,
    Object? sources = null,
    Object? photos = null,
    Object? isAiGenerated = null,
    Object? editCount = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$DiaryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      mood: freezed == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String?,
      weather: freezed == weather
          ? _value.weather
          : weather // ignore: cast_nullable_to_non_nullable
              as Weather?,
      sources: null == sources
          ? _value._sources
          : sources // ignore: cast_nullable_to_non_nullable
              as List<DiarySource>,
      photos: null == photos
          ? _value._photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isAiGenerated: null == isAiGenerated
          ? _value.isAiGenerated
          : isAiGenerated // ignore: cast_nullable_to_non_nullable
              as bool,
      editCount: null == editCount
          ? _value.editCount
          : editCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiaryImpl implements _Diary {
  const _$DiaryImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.userId,
      @HiveField(2) required this.content,
      @HiveField(3) this.mood,
      @HiveField(4) this.weather,
      @HiveField(5) final List<DiarySource> sources = const [],
      @HiveField(6) final List<String> photos = const [],
      @HiveField(7) this.isAiGenerated = false,
      @HiveField(8) this.editCount = 0,
      @HiveField(9) required this.createdAt,
      @HiveField(10) this.updatedAt})
      : _sources = sources,
        _photos = photos;

  factory _$DiaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiaryImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String userId;
  @override
  @HiveField(2)
  final String content;
  @override
  @HiveField(3)
  final String? mood;
  @override
  @HiveField(4)
  final Weather? weather;
  final List<DiarySource> _sources;
  @override
  @JsonKey()
  @HiveField(5)
  List<DiarySource> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  final List<String> _photos;
  @override
  @JsonKey()
  @HiveField(6)
  List<String> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  @override
  @JsonKey()
  @HiveField(7)
  final bool isAiGenerated;
  @override
  @JsonKey()
  @HiveField(8)
  final int editCount;
  @override
  @HiveField(9)
  final DateTime createdAt;
  @override
  @HiveField(10)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Diary(id: $id, userId: $userId, content: $content, mood: $mood, weather: $weather, sources: $sources, photos: $photos, isAiGenerated: $isAiGenerated, editCount: $editCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.weather, weather) || other.weather == weather) &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            (identical(other.isAiGenerated, isAiGenerated) ||
                other.isAiGenerated == isAiGenerated) &&
            (identical(other.editCount, editCount) ||
                other.editCount == editCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      content,
      mood,
      weather,
      const DeepCollectionEquality().hash(_sources),
      const DeepCollectionEquality().hash(_photos),
      isAiGenerated,
      editCount,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiaryImplCopyWith<_$DiaryImpl> get copyWith =>
      __$$DiaryImplCopyWithImpl<_$DiaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiaryImplToJson(
      this,
    );
  }
}

abstract class _Diary implements Diary {
  const factory _Diary(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String userId,
      @HiveField(2) required final String content,
      @HiveField(3) final String? mood,
      @HiveField(4) final Weather? weather,
      @HiveField(5) final List<DiarySource> sources,
      @HiveField(6) final List<String> photos,
      @HiveField(7) final bool isAiGenerated,
      @HiveField(8) final int editCount,
      @HiveField(9) required final DateTime createdAt,
      @HiveField(10) final DateTime? updatedAt}) = _$DiaryImpl;

  factory _Diary.fromJson(Map<String, dynamic> json) = _$DiaryImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get userId;
  @override
  @HiveField(2)
  String get content;
  @override
  @HiveField(3)
  String? get mood;
  @override
  @HiveField(4)
  Weather? get weather;
  @override
  @HiveField(5)
  List<DiarySource> get sources;
  @override
  @HiveField(6)
  List<String> get photos;
  @override
  @HiveField(7)
  bool get isAiGenerated;
  @override
  @HiveField(8)
  int get editCount;
  @override
  @HiveField(9)
  DateTime get createdAt;
  @override
  @HiveField(10)
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$DiaryImplCopyWith<_$DiaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiaryListResponse _$DiaryListResponseFromJson(Map<String, dynamic> json) {
  return _DiaryListResponse.fromJson(json);
}

/// @nodoc
mixin _$DiaryListResponse {
  List<Diary> get items => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DiaryListResponseCopyWith<DiaryListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiaryListResponseCopyWith<$Res> {
  factory $DiaryListResponseCopyWith(
          DiaryListResponse value, $Res Function(DiaryListResponse) then) =
      _$DiaryListResponseCopyWithImpl<$Res, DiaryListResponse>;
  @useResult
  $Res call({List<Diary> items, int total, int page, int limit});
}

/// @nodoc
class _$DiaryListResponseCopyWithImpl<$Res, $Val extends DiaryListResponse>
    implements $DiaryListResponseCopyWith<$Res> {
  _$DiaryListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Diary>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiaryListResponseImplCopyWith<$Res>
    implements $DiaryListResponseCopyWith<$Res> {
  factory _$$DiaryListResponseImplCopyWith(_$DiaryListResponseImpl value,
          $Res Function(_$DiaryListResponseImpl) then) =
      __$$DiaryListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Diary> items, int total, int page, int limit});
}

/// @nodoc
class __$$DiaryListResponseImplCopyWithImpl<$Res>
    extends _$DiaryListResponseCopyWithImpl<$Res, _$DiaryListResponseImpl>
    implements _$$DiaryListResponseImplCopyWith<$Res> {
  __$$DiaryListResponseImplCopyWithImpl(_$DiaryListResponseImpl _value,
      $Res Function(_$DiaryListResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(_$DiaryListResponseImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Diary>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiaryListResponseImpl implements _DiaryListResponse {
  const _$DiaryListResponseImpl(
      {required final List<Diary> items,
      required this.total,
      required this.page,
      required this.limit})
      : _items = items;

  factory _$DiaryListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiaryListResponseImplFromJson(json);

  final List<Diary> _items;
  @override
  List<Diary> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  final int limit;

  @override
  String toString() {
    return 'DiaryListResponse(items: $items, total: $total, page: $page, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiaryListResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), total, page, limit);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiaryListResponseImplCopyWith<_$DiaryListResponseImpl> get copyWith =>
      __$$DiaryListResponseImplCopyWithImpl<_$DiaryListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiaryListResponseImplToJson(
      this,
    );
  }
}

abstract class _DiaryListResponse implements DiaryListResponse {
  const factory _DiaryListResponse(
      {required final List<Diary> items,
      required final int total,
      required final int page,
      required final int limit}) = _$DiaryListResponseImpl;

  factory _DiaryListResponse.fromJson(Map<String, dynamic> json) =
      _$DiaryListResponseImpl.fromJson;

  @override
  List<Diary> get items;
  @override
  int get total;
  @override
  int get page;
  @override
  int get limit;
  @override
  @JsonKey(ignore: true)
  _$$DiaryListResponseImplCopyWith<_$DiaryListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
