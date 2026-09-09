/// A single recent-search (history) record.
///
/// History is stored two ways — per selected module and a global
/// (no-module) bucket — and each entry remembers what was tapped:
/// an item suggestion, a store suggestion, or a free-text keyword.
/// In global mode the [moduleId] / [moduleType] let the UI resolve the
/// module image and the "is a … Item / Restaurant" subtitle.
enum RecentSearchKind { item, store, keyword }

class RecentSearchEntry {
  final String name;
  final RecentSearchKind kind;
  final int? moduleId;
  final String? moduleType;
  final String? moduleName;
  final String? moduleImage;

  const RecentSearchEntry({required this.name, required this.kind,
    this.moduleId, this.moduleType, this.moduleName, this.moduleImage,
  });

  factory RecentSearchEntry.keyword(String name, {int? moduleId, String? moduleType, String? moduleName, String? moduleImage}) => RecentSearchEntry(
    name: name, kind: RecentSearchKind.keyword, moduleId: moduleId, moduleType: moduleType, moduleName: moduleName, moduleImage: moduleImage,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'kind': kind.name,
    'module_id': moduleId,
    'module_type': moduleType,
    'module_name': moduleName,
    'module_image': moduleImage,
  };

  factory RecentSearchEntry.fromJson(Map<String, dynamic> json) => RecentSearchEntry(
    name: json['name'] ?? '',
    kind: RecentSearchKind.values.firstWhere(
      (RecentSearchKind k) => k.name == json['kind'],
      orElse: () => RecentSearchKind.keyword,
    ),
    moduleId: json['module_id'],
    moduleType: json['module_type'],
    moduleName: json['module_name'],
    moduleImage: json['module_image'],
  );
}
