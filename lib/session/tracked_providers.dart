import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackedProviders {
  TrackedProviders._();

  static final Set<ProviderBase> _tracked = {};

  /// Define provider names to exclude
  static final Set<String> _excludedProviderNames = {
    'languageProvider',
    // Add more provider names here
  };

  /// Adds a provider to the tracking set if not excluded
  static void add(ProviderBase provider) {
    final name = provider.name ?? provider.runtimeType.toString();
    final isExcluded = _excludedProviderNames.contains(name);

    if (!isExcluded) {
      _tracked.add(provider);
      print("TrackedProviders: ✅ Tracked $name");
    } else {
      print("TrackedProviders: ❌ Excluded $name");
    }
  }

  /// Manually track a provider
  static void track(ProviderBase provider) => add(provider);

  /// Invalidate all tracked providers
  static Future<void> invalidateAll(WidgetRef ref) async {
    print("TrackedProviders: 🔁 Starting invalidation of ${_tracked.length} providers.");
    for (final provider in _tracked) {
      try {
        final name = provider.name ?? provider.runtimeType.toString();
        print("TrackedProviders: Invalidating $name");
        ref.invalidate(provider);
      } catch (e, s) {
        final name = provider.name ?? provider.runtimeType.toString();
        print("TrackedProviders: ❌ Error invalidating $name: $e");
        print(s);
      }
    }
    print("TrackedProviders: ✅ All tracked providers invalidated.");
    _tracked.clear();
  }

  /// Invalidate providers conditionally using a predicate
  static Future<void> invalidateWhere(
    WidgetRef ref, {
    required bool Function(ProviderBase provider) test,
  }) async {
    final toInvalidate = _tracked.where(test).toList();
    print("TrackedProviders: 🔍 Found ${toInvalidate.length} providers to invalidate.");
    for (final provider in toInvalidate) {
      try {
        final name = provider.name ?? provider.runtimeType.toString();
        print("TrackedProviders: Invalidating $name");
        ref.invalidate(provider);
      } catch (e, s) {
        final name = provider.name ?? provider.runtimeType.toString();
        print("TrackedProviders: ❌ Error invalidating $name: $e");
        print(s);
      }
    }
    _tracked.removeAll(toInvalidate);
  }

  /// Reset tracking
  static void resetTracking() {
    print("TrackedProviders: 🧹 Resetting tracking. Cleared ${_tracked.length} providers.");
    _tracked.clear();
  }

  /// Debug print all tracked providers
  static void printTrackedProviders() {
    if (_tracked.isEmpty) {
      print("TrackedProviders: ℹ️ No providers are currently tracked.");
      return;
    }

    print("TrackedProviders: 📦 Tracked providers (${_tracked.length}):");
    for (final provider in _tracked) {
      final name = provider.name ?? provider.runtimeType.toString();
      print("- $name");
    }
  }
}
