import '../models/cache_entry.dart';

/// Storage boundary for public, buffered HTTP cache entries.
abstract class CacheStore {
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, CacheEntry entry);
  Future<void> remove(String key);
  Future<void> clear();
}
