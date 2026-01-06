import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tracked_providers.dart';

class AppProviderObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {
    TrackedProviders.add(provider);
    super.didAddProvider(provider, value, container);
  }

  @override
  void didDisposeProvider(
    ProviderBase provider,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();
    print("AppProviderObserver: Disposed $name");
    super.didDisposeProvider(provider, container);
  }

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();
    print("AppProviderObserver: Updated $name");
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }
}
