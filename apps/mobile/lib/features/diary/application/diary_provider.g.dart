// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$diaryDatesHash() => r'0599b9dc728dd3e4fd004011831b34d2b09c216a';

/// Provider for calendar markers (dates with entries)
///
/// Copied from [diaryDates].
@ProviderFor(diaryDates)
final diaryDatesProvider = AutoDisposeFutureProvider<List<DateTime>>.internal(
  diaryDates,
  name: r'diaryDatesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$diaryDatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DiaryDatesRef = AutoDisposeFutureProviderRef<List<DateTime>>;
String _$diaryDetailHash() => r'00ede1d0deadbfab22454a6b61ff9ec7439782c2';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider for single diary detail
///
/// Copied from [diaryDetail].
@ProviderFor(diaryDetail)
const diaryDetailProvider = DiaryDetailFamily();

/// Provider for single diary detail
///
/// Copied from [diaryDetail].
class DiaryDetailFamily extends Family<AsyncValue<Diary>> {
  /// Provider for single diary detail
  ///
  /// Copied from [diaryDetail].
  const DiaryDetailFamily();

  /// Provider for single diary detail
  ///
  /// Copied from [diaryDetail].
  DiaryDetailProvider call(
    String id,
  ) {
    return DiaryDetailProvider(
      id,
    );
  }

  @override
  DiaryDetailProvider getProviderOverride(
    covariant DiaryDetailProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'diaryDetailProvider';
}

/// Provider for single diary detail
///
/// Copied from [diaryDetail].
class DiaryDetailProvider extends AutoDisposeFutureProvider<Diary> {
  /// Provider for single diary detail
  ///
  /// Copied from [diaryDetail].
  DiaryDetailProvider(
    String id,
  ) : this._internal(
          (ref) => diaryDetail(
            ref as DiaryDetailRef,
            id,
          ),
          from: diaryDetailProvider,
          name: r'diaryDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$diaryDetailHash,
          dependencies: DiaryDetailFamily._dependencies,
          allTransitiveDependencies:
              DiaryDetailFamily._allTransitiveDependencies,
          id: id,
        );

  DiaryDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Diary> Function(DiaryDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DiaryDetailProvider._internal(
        (ref) => create(ref as DiaryDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Diary> createElement() {
    return _DiaryDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DiaryDetailRef on AutoDisposeFutureProviderRef<Diary> {
  /// The parameter `id` of this provider.
  String get id;
}

class _DiaryDetailProviderElement
    extends AutoDisposeFutureProviderElement<Diary> with DiaryDetailRef {
  _DiaryDetailProviderElement(super.provider);

  @override
  String get id => (origin as DiaryDetailProvider).id;
}

String _$yearAgoMemoryHash() => r'ec9eeb6a7d97e9ab2df1b830d6b766841e0e98fc';

/// Provider for 1-year-ago memory
///
/// Copied from [yearAgoMemory].
@ProviderFor(yearAgoMemory)
final yearAgoMemoryProvider = AutoDisposeFutureProvider<Diary?>.internal(
  yearAgoMemory,
  name: r'yearAgoMemoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$yearAgoMemoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef YearAgoMemoryRef = AutoDisposeFutureProviderRef<Diary?>;
String _$selectedDateHash() => r'63a03d318cb121ed7968cb801fe2c4c3dd623b34';

/// Selected date for diary feed (single date selection)
///
/// Copied from [SelectedDate].
@ProviderFor(SelectedDate)
final selectedDateProvider =
    AutoDisposeNotifierProvider<SelectedDate, DateTime>.internal(
  SelectedDate.new,
  name: r'selectedDateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedDateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDate = AutoDisposeNotifier<DateTime>;
String _$diaryFilterHash() => r'e1a6681a86bc5b78c728bdff06aa9ca7e8bd1e51';

/// Legacy filter provider for backward compatibility
///
/// Copied from [DiaryFilter].
@ProviderFor(DiaryFilter)
final diaryFilterProvider = AutoDisposeNotifierProvider<DiaryFilter,
    ({DateTime? start, DateTime? end})>.internal(
  DiaryFilter.new,
  name: r'diaryFilterProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$diaryFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DiaryFilter = AutoDisposeNotifier<({DateTime? start, DateTime? end})>;
String _$infiniteScrollDiaryListHash() =>
    r'7c682ec7fb53248df2329179ac0dad64bdb9fbde';

/// Provider for infinite scroll diary list
///
/// Copied from [InfiniteScrollDiaryList].
@ProviderFor(InfiniteScrollDiaryList)
final infiniteScrollDiaryListProvider = AutoDisposeNotifierProvider<
    InfiniteScrollDiaryList, InfiniteScrollState>.internal(
  InfiniteScrollDiaryList.new,
  name: r'infiniteScrollDiaryListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$infiniteScrollDiaryListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InfiniteScrollDiaryList = AutoDisposeNotifier<InfiniteScrollState>;
String _$diaryListHash() => r'b411cdbe6ad3a595d6544e8c12d8a81ac28c1d46';

/// Provider for diary list (Legacy - for backward compatibility)
///
/// Copied from [DiaryList].
@ProviderFor(DiaryList)
final diaryListProvider =
    AutoDisposeAsyncNotifierProvider<DiaryList, List<Diary>>.internal(
  DiaryList.new,
  name: r'diaryListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$diaryListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DiaryList = AutoDisposeAsyncNotifier<List<Diary>>;
String _$memoryBannerDismissedHash() =>
    r'59276110bea900adf29752934e52b2415cb0ce69';

/// Memory banner dismiss state (stored in SharedPreferences)
///
/// Copied from [MemoryBannerDismissed].
@ProviderFor(MemoryBannerDismissed)
final memoryBannerDismissedProvider =
    AutoDisposeAsyncNotifierProvider<MemoryBannerDismissed, bool>.internal(
  MemoryBannerDismissed.new,
  name: r'memoryBannerDismissedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$memoryBannerDismissedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MemoryBannerDismissed = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
