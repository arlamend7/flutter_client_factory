import 'dart:collection';
import '../contracts/cache_store.dart';
import '../models/cache_entry.dart';

/// In-memory LRU cache bounded by entry count and representation bytes.
class MemoryCacheStore implements CacheStore {
  MemoryCacheStore({this.maxEntries = 100, this.maxBytes = 16 * 1024 * 1024}) {
    if (maxEntries < 1 || maxBytes < 0) {
      throw ArgumentError('Invalid cache limits.');
    }
  }
  final int maxEntries;
  final int maxBytes;
  int _bytes = 0;
  final LinkedHashMap<String, CacheEntry> _entries = LinkedHashMap();
  @override
  Future<CacheEntry?> read(String key) async {
    final entry = _entries.remove(key);
    if (entry != null) _entries[key] = entry;
    return entry;
  }

  @override
  Future<void> write(String key, CacheEntry entry) async {
    await remove(key);
    if (entry.response.bytes.length > maxBytes) return;
    _entries[key] = entry;
    _bytes += entry.response.bytes.length;
    while (_entries.length > maxEntries || _bytes > maxBytes) {
      await remove(_entries.keys.first);
    }
  }

  @override
  Future<void> remove(String key) async {
    _bytes -= _entries.remove(key)?.response.bytes.length ?? 0;
  }

  @override
  Future<void> clear() async {
    _entries.clear();
    _bytes = 0;
  }
}
