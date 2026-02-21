// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firestore_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreServiceHash() => r'0f8fc3ed9acdb2d77cdfb4f0d713961c9a50352e';

/// See also [firestoreService].
@ProviderFor(firestoreService)
final firestoreServiceProvider = AutoDisposeProvider<FirestoreService>.internal(
  firestoreService,
  name: r'firestoreServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firestoreServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FirestoreServiceRef = AutoDisposeProviderRef<FirestoreService>;
String _$userProfileStreamHash() => r'4416c1fe310e7e890c98026efa5ab3f3228f5035';

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

/// See also [userProfileStream].
@ProviderFor(userProfileStream)
const userProfileStreamProvider = UserProfileStreamFamily();

/// See also [userProfileStream].
class UserProfileStreamFamily extends Family<AsyncValue<UserProfile?>> {
  /// See also [userProfileStream].
  const UserProfileStreamFamily();

  /// See also [userProfileStream].
  UserProfileStreamProvider call(
    String uid,
  ) {
    return UserProfileStreamProvider(
      uid,
    );
  }

  @override
  UserProfileStreamProvider getProviderOverride(
    covariant UserProfileStreamProvider provider,
  ) {
    return call(
      provider.uid,
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
  String? get name => r'userProfileStreamProvider';
}

/// See also [userProfileStream].
class UserProfileStreamProvider
    extends AutoDisposeStreamProvider<UserProfile?> {
  /// See also [userProfileStream].
  UserProfileStreamProvider(
    String uid,
  ) : this._internal(
          (ref) => userProfileStream(
            ref as UserProfileStreamRef,
            uid,
          ),
          from: userProfileStreamProvider,
          name: r'userProfileStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userProfileStreamHash,
          dependencies: UserProfileStreamFamily._dependencies,
          allTransitiveDependencies:
              UserProfileStreamFamily._allTransitiveDependencies,
          uid: uid,
        );

  UserProfileStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
  }) : super.internal();

  final String uid;

  @override
  Override overrideWith(
    Stream<UserProfile?> Function(UserProfileStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserProfileStreamProvider._internal(
        (ref) => create(ref as UserProfileStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<UserProfile?> createElement() {
    return _UserProfileStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfileStreamProvider && other.uid == uid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserProfileStreamRef on AutoDisposeStreamProviderRef<UserProfile?> {
  /// The parameter `uid` of this provider.
  String get uid;
}

class _UserProfileStreamProviderElement
    extends AutoDisposeStreamProviderElement<UserProfile?>
    with UserProfileStreamRef {
  _UserProfileStreamProviderElement(super.provider);

  @override
  String get uid => (origin as UserProfileStreamProvider).uid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
