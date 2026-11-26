import 'package:flutter/foundation.dart';

import '../local/local_store.dart';
import '../models/collection_model.dart';
import '../models/vocabulary_model.dart';
import '../remote/api_client.dart';

/// Trạng thái tải dữ liệu của một màn hình danh sách (Loading / Error / Ready).
enum LoadStatus { initial, loading, ready, error }

/// Store trung tâm của module Thư viện (Track A — FE1).
///
/// - Là nguồn dữ liệu duy nhất cho Màn 05, 06, 07, 09, 22, 24, 28 và thống kê Màn 15.
/// - Hiện thực hợp đồng tích hợp đặc tả §5.1: `addWords(collectionId, words)`
///   để Track B (Lưu từ AI — Màn 14) gọi vào.
/// - Bắt đầu trống, người dùng tự tạo học phần / thêm từ. Có [storage] thì mọi thay đổi được
///   lưu trên máy và nạp lại khi mở app; có [apiClient] kèm phiên đăng nhập thì tự đồng bộ
///   học phần & từ vựng lên backend PostgreSQL.
class CollectionStore extends ChangeNotifier {
  CollectionStore({
    List<CollectionModel>? collections,
    List<VocabularyModel>? vocabularies,
    this.latency = const Duration(milliseconds: 400),
    LocalStore? storage,
    ApiClient? apiClient,
    bool perUser = false,
  })  : _collections = collections ?? [],
        _vocabularies = vocabularies ?? [],
        _storage = storage,
        _api = apiClient,
        _perUser = perUser {
    if (!perUser && storage != null && collections == null && vocabularies == null) _restore(storage);
  }

  /// Instance dùng chung toàn app, lưu vào [LocalStore.app] theo từng tài khoản:
  /// trống cho tới khi [switchUser] được gọi lúc đăng nhập (xem `TrackSync`).
  static final CollectionStore instance = CollectionStore(
    storage: LocalStore.app,
    apiClient: ApiClient.instance,
    perUser: true,
  );

  /// `true`: dữ liệu tách theo tài khoản, khoá lưu có hậu tố [_userKey].
  final bool _perUser;

  /// Tài khoản đang mở dữ liệu (email chuẩn hoá), `null` khi chưa đăng nhập.
  String? _userKey;

  final LocalStore? _storage;
  final ApiClient? _api;

  final List<CollectionModel> _collections;
  final List<VocabularyModel> _vocabularies;

  /// Ánh xạ id tạm cục bộ → UUID thật do BE trả về khi tạo học phần / từ mới.
  final Map<String, String> _remoteIds = {};

  /// Hàng đợi tuần tự đảm bảo các thao tác tạo học phần → thêm từ đi đúng thứ tự lên BE.
  Future<void> _syncQueue = Future<void>.value();

  /// Độ trễ giả lập mạng khi tải dữ liệu (chỉ dùng khi offline).
  final Duration latency;

  /// Bật để giả lập lỗi mạng ở lần `load()` tiếp theo (kiểm thử Error State).
  bool simulateNetworkError = false;

  LoadStatus _status = LoadStatus.initial;
  String? _errorMessage;
  int _idSeq = 0;

  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get _canSync => _api != null && _api.hasSession;

  /// Chờ các thao tác đồng bộ đang chạy hoàn tất (dùng trước khi gửi quiz lên BE).
  Future<void> get pendingSync => _syncQueue;

  /// Đổi id cục bộ (nếu đã đồng bộ xong) sang UUID thật trên backend.
  String resolveRemoteId(String id) {
    var cur = id;
    for (var i = 0; i < 4; i++) {
      final next = _remoteIds[cur];
      if (next == null || next == cur) break;
      cur = next;
    }
    return cur;
  }

  List<CollectionModel> get collections => List.unmodifiable(_collections);

  /// Mọi từ vựng ở mọi học phần (vd làm đáp án nhiễu cho quiz, hàng đợi ôn tập).
  List<VocabularyModel> get allWords => List.unmodifiable(_vocabularies);
  int get totalWordCount => _vocabularies.length;

  // ---------------------------------------------------------------------------
  // Tải dữ liệu
  // ---------------------------------------------------------------------------

  /// Tải danh sách học phần. [silent] = true (kéo để làm mới) giữ nguyên dữ liệu đang hiển thị
  /// thay vì chuyển sang Loading State.
  Future<void> load({bool silent = false}) async {
    if (!silent || _status != LoadStatus.ready) {
      _status = LoadStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    if (simulateNetworkError) {
      await Future<void>.delayed(latency);
      simulateNetworkError = false;
      _status = LoadStatus.error;
      _errorMessage = 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.';
      notifyListeners();
      return;
    }

    if (_canSync) {
      try {
        await _syncQueue;
        await _fetchAllFromBackend();
        _syncAllCounts();
        _status = LoadStatus.ready;
      } on ApiException catch (e) {
        // Khi ngoại tuyến mà máy đã có dữ liệu cache thì vẫn cho dùng tiếp.
        if (e.isNetworkError && _collections.isNotEmpty) {
          _syncAllCounts();
          _status = LoadStatus.ready;
        } else {
          _status = LoadStatus.error;
          _errorMessage = e.message;
        }
      } on Object {
        if (_collections.isNotEmpty) {
          _syncAllCounts();
          _status = LoadStatus.ready;
        } else {
          _status = LoadStatus.error;
          _errorMessage = 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.';
        }
      }
      notifyListeners();
      return;
    }

    await Future<void>.delayed(latency);
    _syncAllCounts();
    _status = LoadStatus.ready;
    notifyListeners();
  }

  /// Chỉ tải khi chưa từng tải thành công (tránh nháy Loading khi quay lại tab).
  Future<void> ensureLoaded() async {
    if (_status == LoadStatus.initial || _status == LoadStatus.error) {
      await load();
    }
  }

  // ---------------------------------------------------------------------------
  // Truy vấn
  // ---------------------------------------------------------------------------

  CollectionModel? findCollection(String id) {
    final resolved = resolveRemoteId(id);
    for (final c in _collections) {
      if (c.id == id || c.id == resolved) return c;
    }
    return null;
  }

  VocabularyModel? findWord(String id) {
    final resolved = resolveRemoteId(id);
    for (final w in _vocabularies) {
      if (w.id == id || w.id == resolved) return w;
    }
    return null;
  }

  /// Lọc học phần theo chủ đề và từ khoá (tên + mô tả, không phân biệt hoa thường).
  List<CollectionModel> search({String query = '', String category = 'all'}) {
    final q = query.trim().toLowerCase();
    return _collections.where((c) {
      final matchesCategory = category == 'all' || c.category == category;
      final matchesQuery = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<VocabularyModel> wordsOf(String collectionId, {String query = ''}) {
    final resolvedCol = resolveRemoteId(collectionId);
    final q = query.trim().toLowerCase();
    return _vocabularies.where((w) {
      if (w.collectionId != collectionId && w.collectionId != resolvedCol) return false;
      if (q.isEmpty) return true;
      return w.term.toLowerCase().contains(q) ||
          w.definitionVi.toLowerCase().contains(q) ||
          w.definitionEn.toLowerCase().contains(q);
    }).toList();
  }

  bool isTitleTaken(String title, {String? excludeId}) {
    final t = title.trim().toLowerCase();
    final resolvedExclude = excludeId == null ? null : resolveRemoteId(excludeId);
    return _collections.any(
      (c) => c.id != excludeId && c.id != resolvedExclude && c.title.trim().toLowerCase() == t,
    );
  }

  bool isTermTaken(String collectionId, String term, {String? excludeId}) {
    final t = termKey(term);
    final resolvedCol = resolveRemoteId(collectionId);
    final resolvedExclude = excludeId == null ? null : resolveRemoteId(excludeId);
    return _vocabularies.any((w) =>
        (w.collectionId == collectionId || w.collectionId == resolvedCol) &&
        w.id != excludeId &&
        w.id != resolvedExclude &&
        termKey(w.term) == t);
  }

  /// Khoá so trùng từ vựng, giống `termKey()` của BE: trim, gộp khoảng trắng, viết thường.
  static String termKey(String term) =>
      term.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  // ---------------------------------------------------------------------------
  // Học phần (Màn 22)
  // ---------------------------------------------------------------------------

  /// Tạo học phần mới, chèn lên đầu danh sách.
  /// Ném [ArgumentError] nếu tên trùng với học phần đã có.
  CollectionModel createCollection({
    required String title,
    String description = '',
    String category = CollectionModel.defaultCategory,
  }) {
    final cleanTitle = title.trim();
    if (isTitleTaken(cleanTitle)) {
      throw ArgumentError('Tên học phần "$cleanTitle" đã tồn tại');
    }
    final localId = _newId('col');
    final collection = CollectionModel(
      id: localId,
      title: cleanTitle,
      description: description.trim(),
      category: category,
      iconName: iconForCategory(category),
      totalWords: 0,
    );
    _collections.insert(0, collection);
    notifyListeners();

    if (_canSync) {
      _enqueueSync(() async {
        final data = await _api!.post('/collections', body: {
          'title': collection.title,
          if (collection.description.isNotEmpty) 'description': collection.description,
          'category': collection.category,
          'iconName': collection.iconName,
        });
        if (data is Map<String, dynamic>) {
          final serverCol = _collectionFromBe(data);
          _replaceCollectionId(localId, serverCol);
        }
      });
    }
    return collection;
  }

  /// Sửa tên, mô tả, chủ đề của học phần. Ném [ArgumentError] nếu tên trùng
  /// học phần khác; trả về `null` nếu không tìm thấy.
  CollectionModel? updateCollection(
    String id, {
    required String title,
    String description = '',
    String category = CollectionModel.defaultCategory,
  }) {
    final resolved = resolveRemoteId(id);
    final index = _collections.indexWhere((c) => c.id == id || c.id == resolved);
    if (index == -1) return null;
    final cleanTitle = title.trim();
    if (isTitleTaken(cleanTitle, excludeId: id)) {
      throw ArgumentError('Tên học phần "$cleanTitle" đã tồn tại');
    }
    final updated = _collections[index].copyWith(
      title: cleanTitle,
      description: description.trim(),
      category: category,
      iconName: iconForCategory(category),
    );
    _collections[index] = updated;
    notifyListeners();

    if (_canSync) {
      _enqueueSync(() async {
        final targetId = resolveRemoteId(updated.id);
        await _api!.patch('/collections/$targetId', body: {
          'title': updated.title,
          'description': updated.description,
          'category': updated.category,
          'iconName': updated.iconName,
        });
      });
    }
    return updated;
  }

  /// Xoá học phần cùng toàn bộ từ vựng trong đó. Trả về học phần vừa xoá hoặc `null`.
  CollectionModel? deleteCollection(String id) {
    final resolved = resolveRemoteId(id);
    final index = _collections.indexWhere((c) => c.id == id || c.id == resolved);
    if (index == -1) return null;
    final removed = _collections.removeAt(index);
    _vocabularies.removeWhere((w) => w.collectionId == id || w.collectionId == resolved);
    notifyListeners();

    if (_canSync) {
      _enqueueSync(() async {
        final targetId = resolveRemoteId(removed.id);
        await _api!.delete('/collections/$targetId');
      });
    }
    return removed;
  }

  static String iconForCategory(String category) {
    switch (category) {
      case 'academic':
        return 'school_rounded';
      case 'travel':
        return 'flight_takeoff_rounded';
      case 'life':
        return 'chat_bubble_outline_rounded';
      case 'career':
        return 'work_outline_rounded';
      default:
        return 'folder_rounded';
    }
  }

  // ---------------------------------------------------------------------------
  // Từ vựng (Màn 24, 09, 28)
  // ---------------------------------------------------------------------------

  /// Thêm một từ. Nếu `id` rỗng sẽ tự sinh id mới. Trả về bản ghi đã lưu.
  VocabularyModel addWord(VocabularyModel word) {
    final effectiveColId = resolveRemoteId(word.collectionId);
    final saved = (word.id.isEmpty ? word.copyWith(id: _newId('voc')) : word)
        .copyWith(collectionId: effectiveColId);
    _vocabularies.insert(0, saved);
    _syncCount(effectiveColId);
    notifyListeners();

    if (_canSync) {
      _enqueueSync(() async {
        final targetColId = resolveRemoteId(saved.collectionId);
        final data = await _api!.post(
          '/collections/$targetColId/words',
          body: _vocabToBeBody(saved),
        );
        if (data is Map<String, dynamic>) {
          final serverWord = _vocabFromBe(data, fallback: saved);
          _replaceWordId(saved.id, serverWord);
        }
      });
    }
    return saved;
  }

  /// Hợp đồng tích hợp với Track B (Màn 14 — Lưu từ AI vào học phần).
  ///
  /// Giống `POST /vocabularies/batch-save` của BE: bỏ qua từ đã có trong học phần
  /// (không phân biệt hoa thường, kể cả trùng nhau trong cùng lần lưu) và trả về
  /// danh sách term bị bỏ qua (BE `skippedTerms`).
  List<String> addWords(String collectionId, List<VocabularyModel> words) {
    final effectiveColId = resolveRemoteId(collectionId);
    final seen = {
      for (final w in _vocabularies)
        if (w.collectionId == collectionId || w.collectionId == effectiveColId) termKey(w.term),
    };
    final skipped = <String>[];
    final addedWords = <VocabularyModel>[];
    for (final w in words) {
      if (!seen.add(termKey(w.term))) {
        skipped.add(w.term);
        continue;
      }
      final withId = w.id.isEmpty ? w.copyWith(id: _newId('voc')) : w;
      final normalized = withId.copyWith(collectionId: effectiveColId, term: w.term.trim());
      _vocabularies.add(normalized);
      addedWords.add(normalized);
    }
    if (addedWords.isNotEmpty) {
      _syncCount(effectiveColId);
      notifyListeners();

      if (_canSync) {
        _enqueueSync(() async {
          final targetColId = resolveRemoteId(collectionId);
          // BE giới hạn @ArrayMaxSize(50) cho mỗi batch-save.
          for (var i = 0; i < addedWords.length; i += 50) {
            final chunk = addedWords.sublist(
              i,
              i + 50 > addedWords.length ? addedWords.length : i + 50,
            );
            final data = await _api!.post('/vocabularies/batch-save', body: {
              'collectionId': targetColId,
              'words': [for (final w in chunk) _vocabToBeBody(w)],
            });
            if (data is Map<String, dynamic> && data['vocabularies'] is List) {
              final byKey = {
                for (final raw in data['vocabularies'] as List)
                  if (raw is Map<String, dynamic>)
                    termKey((raw['term'] as String?) ?? ''): raw,
              };
              for (final local in chunk) {
                final remote = byKey[termKey(local.term)];
                if (remote != null) {
                  _replaceWordId(local.id, _vocabFromBe(remote, fallback: local));
                }
              }
            }
          }
        });
      }
    }
    return skipped;
  }

  /// Cập nhật một từ đã có. Trả về `false` nếu không tìm thấy.
  bool updateWord(VocabularyModel word) {
    final resolvedId = resolveRemoteId(word.id);
    final index = _vocabularies.indexWhere((w) => w.id == word.id || w.id == resolvedId);
    if (index == -1) return false;
    final current = _vocabularies[index];
    final previousCollection = current.collectionId;
    final nextWord = word.copyWith(
      id: current.id,
      collectionId: resolveRemoteId(word.collectionId),
    );
    _vocabularies[index] = nextWord;
    _syncCount(previousCollection);
    if (previousCollection != nextWord.collectionId) _syncCount(nextWord.collectionId);
    notifyListeners();

    if (_canSync) {
      _enqueueSync(() async {
        final targetId = resolveRemoteId(nextWord.id);
        await _api!.put('/vocabularies/$targetId', body: _vocabToBeBody(nextWord));
      });
    }
    return true;
  }

  /// Xoá một từ, trả về bản ghi vừa xoá (để hỗ trợ "Hoàn tác") hoặc `null`.
  VocabularyModel? deleteWord(String id) {
    final resolvedId = resolveRemoteId(id);
    final index = _vocabularies.indexWhere((w) => w.id == id || w.id == resolvedId);
    if (index == -1) return null;
    final removed = _vocabularies.removeAt(index);
    _deletedIndex[removed.id] = index;
    _syncCount(removed.collectionId);
    notifyListeners();

    if (_canSync) {
      _enqueueSync(() async {
        final targetId = resolveRemoteId(removed.id);
        await _api!.delete('/vocabularies/$targetId');
      });
    }
    return removed;
  }

  /// Vị trí cũ của các từ vừa xoá, để "Hoàn tác" trả từ về đúng chỗ trong danh sách.
  final Map<String, int> _deletedIndex = {};

  /// Khôi phục một từ vừa xoá (nút "Hoàn tác" trên Toast) về vị trí cũ.
  void restoreWord(VocabularyModel word) {
    if (findWord(word.id) != null) return;
    final index = _deletedIndex.remove(word.id) ?? 0;
    final effectiveColId = resolveRemoteId(word.collectionId);
    final restored = word.copyWith(collectionId: effectiveColId);
    _vocabularies.insert(index.clamp(0, _vocabularies.length), restored);
    _syncCount(effectiveColId);
    notifyListeners();

    if (_canSync) {
      _enqueueSync(() async {
        final targetColId = resolveRemoteId(restored.collectionId);
        final data = await _api!.post(
          '/collections/$targetColId/words',
          body: _vocabToBeBody(restored),
        );
        if (data is Map<String, dynamic>) {
          _replaceWordId(restored.id, _vocabFromBe(data, fallback: restored));
        }
      });
    }
  }

  /// Xoá toàn bộ học phần và từ vựng (đăng xuất khỏi tài khoản / kiểm thử).
  void clear() {
    _collections.clear();
    _vocabularies.clear();
    _remoteIds.clear();
    _syncQueue = Future<void>.value();
    _status = LoadStatus.initial;
    _errorMessage = null;
    simulateNetworkError = false;
    notifyListeners();
  }

  /// Đổi sang dữ liệu của tài khoản [userKey] (đăng nhập) hoặc về trống khi `null` (đăng xuất).
  /// Mỗi tài khoản có học phần và từ vựng riêng, không thấy dữ liệu của nhau.
  void switchUser(String? userKey) {
    if (!_perUser || userKey == _userKey) return;
    _userKey = userKey;
    _collections.clear();
    _vocabularies.clear();
    _deletedIndex.clear();
    _remoteIds.clear();
    _syncQueue = Future<void>.value();
    _status = LoadStatus.initial;
    _errorMessage = null;
    final storage = _storage;
    if (storage != null && userKey != null) _restore(storage);
    super.notifyListeners();
  }

  /// Khoá lưu trữ; `null` khi không được lưu (store theo tài khoản mà chưa đăng nhập).
  String? _key(String base) {
    if (!_perUser) return base;
    final user = _userKey;
    return user == null ? null : StorageKeys.forUser(base, user);
  }

  /// Mỗi lần dữ liệu đổi (đi qua [notifyListeners]) thì lưu lại trên máy.
  @override
  void notifyListeners() {
    final storage = _storage;
    final colKey = _key(StorageKeys.collections);
    final wordKey = _key(StorageKeys.vocabularies);
    if (storage != null && colKey != null && wordKey != null) {
      storage.writeJson(colKey, [for (final c in _collections) c.toJson()]);
      storage.writeJson(wordKey, [for (final w in _vocabularies) w.toJson()]);
    }
    super.notifyListeners();
  }

  void _restore(LocalStore storage) {
    final colKey = _key(StorageKeys.collections);
    final wordKey = _key(StorageKeys.vocabularies);
    if (colKey == null || wordKey == null) return;
    final cols = storage.readJson(colKey);
    final words = storage.readJson(wordKey);
    try {
      if (cols is List) _collections.addAll([for (final c in cols) CollectionModel.fromJson(c as Map<String, dynamic>)]);
      if (words is List) {
        _vocabularies.addAll([for (final w in words) VocabularyModel.fromJson(w as Map<String, dynamic>)]);
      }
    } on Object {
      // Dữ liệu lưu bị hỏng: bỏ qua, bắt đầu trống thay vì treo app.
      _collections.clear();
      _vocabularies.clear();
    }
  }

  // ---------------------------------------------------------------------------
  // Đồng bộ Backend & Ánh xạ DTO
  // ---------------------------------------------------------------------------

  void _enqueueSync(Future<void> Function() action) {
    _syncQueue = _syncQueue.then((_) async {
      try {
        await action();
      } on Object {
        // Giữ dữ liệu cục bộ an toàn khi mất mạng hoặc BE tạm lỗi; không làm treo UI.
      }
    });
  }

  Future<void> _fetchAllFromBackend() async {
    final api = _api!;
    final fetchedCols = <CollectionModel>[];
    var page = 1;
    while (true) {
      final data = await api.get('/collections?page=$page&limit=50');
      if (data is! Map<String, dynamic>) break;
      final items = data['items'];
      if (items is List) {
        for (final raw in items) {
          if (raw is Map<String, dynamic>) fetchedCols.add(_collectionFromBe(raw));
        }
      }
      final meta = data['meta'];
      final totalPages = meta is Map ? (meta['totalPages'] as num?)?.toInt() ?? 1 : 1;
      if (page >= totalPages) break;
      page++;
    }

    final existingById = {for (final w in _vocabularies) w.id: w};
    final wordLists = await Future.wait([
      for (final c in fetchedCols) api.get('/collections/${c.id}/words'),
    ]);
    final fetchedWords = <VocabularyModel>[];
    for (final list in wordLists) {
      if (list is List) {
        for (final raw in list) {
          if (raw is Map<String, dynamic>) {
            final id = raw['id'] as String?;
            fetchedWords.add(_vocabFromBe(raw, fallback: id != null ? existingById[id] : null));
          }
        }
      }
    }

    _collections
      ..clear()
      ..addAll(fetchedCols);
    _vocabularies
      ..clear()
      ..addAll(fetchedWords);
  }

  void _replaceCollectionId(String localId, CollectionModel serverCol) {
    _remoteIds[localId] = serverCol.id;
    var changed = false;
    final idx = _collections.indexWhere((c) => c.id == localId);
    if (idx != -1) {
      _collections[idx] = serverCol.copyWith(totalWords: _collections[idx].totalWords);
      changed = true;
    }
    for (var i = 0; i < _vocabularies.length; i++) {
      if (_vocabularies[i].collectionId == localId) {
        _vocabularies[i] = _vocabularies[i].copyWith(collectionId: serverCol.id);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void _replaceWordId(String localId, VocabularyModel serverWord) {
    _remoteIds[localId] = serverWord.id;
    final idx = _vocabularies.indexWhere((w) => w.id == localId);
    if (idx != -1) {
      _vocabularies[idx] = serverWord;
      notifyListeners();
    }
  }

  static CollectionModel _collectionFromBe(Map<String, dynamic> json) {
    final category = (json['category'] as String?) ?? CollectionModel.defaultCategory;
    return CollectionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      category: category,
      iconName: (json['iconName'] as String?) ?? iconForCategory(category),
      totalWords: (json['totalWords'] as num?)?.toInt() ?? 0,
    );
  }

  static VocabularyModel _vocabFromBe(Map<String, dynamic> json, {VocabularyModel? fallback}) {
    final progress = json['progress'];
    final isMastered = progress is Map &&
        (progress['status'] == 'mastered' || (progress['repetitionLevel'] as num?)?.toInt() == 5);
    final ipaUk = (json['ipaUk'] as String?) ?? '';
    final ipaUs = (json['ipaUs'] as String?) ?? '';
    return VocabularyModel(
      id: json['id'] as String,
      collectionId: json['collectionId'] as String,
      term: json['term'] as String,
      partOfSpeech: (json['partOfSpeech'] as String?) ?? 'noun',
      ipa: ipaUk.isNotEmpty ? ipaUk : (ipaUs.isNotEmpty ? ipaUs : (fallback?.ipa ?? '')),
      definitionVi: (json['definitionVi'] as String?) ?? '',
      definitionEn: (json['definitionEn'] as String?) ?? '',
      exampleSentence: (json['exampleSentence'] as String?) ?? '',
      cefrLevel: (json['cefrLevel'] as String?) ?? 'B1',
      isMastered: isMastered,
      synonyms: fallback?.synonyms ?? const [],
      antonyms: fallback?.antonyms ?? const [],
      note: fallback?.note ?? '',
    );
  }

  static const Set<String> _bePos = {'noun', 'verb', 'adj', 'adv', 'idiom'};
  static const Set<String> _beCefr = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};

  static Map<String, dynamic> _vocabToBeBody(VocabularyModel w) {
    final defVi = w.definitionVi.trim();
    final defEn = w.definitionEn.trim();
    final ipa = w.ipa.trim();
    final example = w.exampleSentence.trim();
    return {
      'term': w.term.trim(),
      'partOfSpeech': _bePos.contains(w.partOfSpeech) ? w.partOfSpeech : 'noun',
      if (ipa.isNotEmpty) 'ipaUk': ipa,
      if (defEn.isNotEmpty) 'definitionEn': defEn,
      'definitionVi': defVi.isNotEmpty ? defVi : (defEn.isNotEmpty ? defEn : '-'),
      if (example.isNotEmpty) 'exampleSentence': example,
      'cefrLevel': _beCefr.contains(w.cefrLevel) ? w.cefrLevel : 'B1',
    };
  }

  // ---------------------------------------------------------------------------
  // Nội bộ
  // ---------------------------------------------------------------------------

  String _newId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}';

  void _syncCount(String collectionId) {
    final resolved = resolveRemoteId(collectionId);
    final index = _collections.indexWhere((c) => c.id == collectionId || c.id == resolved);
    if (index == -1) return;
    final col = _collections[index];
    final count = _vocabularies
        .where((w) => w.collectionId == col.id || w.collectionId == collectionId)
        .length;
    _collections[index] = col.copyWith(totalWords: count);
  }

  void _syncAllCounts() {
    for (final c in List<CollectionModel>.from(_collections)) {
      _syncCount(c.id);
    }
  }
}
