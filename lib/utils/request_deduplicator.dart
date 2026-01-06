import 'dart:async';

class RequestDeduplicator {
  static final Set<String> _pendingRequests = {};

  static Future<T?> deduplicate<T>(String key, Future<T> Function() request) async {
    if (_pendingRequests.contains(key)) {
      print('Request already in progress, deduplicating: $key');
      return null;
    }

    _pendingRequests.add(key);
    try {
      return await request();
    } finally {
      _pendingRequests.remove(key);
    }
  }
}