import 'package:uuid/uuid.dart';

enum CubicleStatus {
  active,
  archived,
  deleting,
}

class Cubicle {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final CubicleStatus status;
  final String? lastCommand;

  Cubicle({
    String? id,
    required this.name,
    required this.path,
    DateTime? createdAt,
    this.status = CubicleStatus.active,
    this.lastCommand,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Cubicle copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? createdAt,
    CubicleStatus? status,
    String? lastCommand,
  }) {
    return Cubicle(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      lastCommand: lastCommand ?? this.lastCommand,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'lastCommand': lastCommand,
    };
  }

  factory Cubicle.fromJson(Map<String, dynamic> json) {
    return Cubicle(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: CubicleStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CubicleStatus.active,
      ),
      lastCommand: json['lastCommand'] as String?,
    );
  }
}

class AiOffice {
  final String id;
  final String mainProjectPath;
  final String officePath;
  final List<Cubicle> cubicles;

  AiOffice({
    String? id,
    required this.mainProjectPath,
    required this.officePath,
    this.cubicles = const [],
  }) : id = id ?? const Uuid().v4();

  AiOffice copyWith({
    String? id,
    String? mainProjectPath,
    String? officePath,
    List<Cubicle>? cubicles,
  }) {
    return AiOffice(
      id: id ?? this.id,
      mainProjectPath: mainProjectPath ?? this.mainProjectPath,
      officePath: officePath ?? this.officePath,
      cubicles: cubicles ?? this.cubicles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mainProjectPath': mainProjectPath,
      'officePath': officePath,
      'cubicles': cubicles.map((c) => c.toJson()).toList(),
    };
  }

  factory AiOffice.fromJson(Map<String, dynamic> json) {
    return AiOffice(
      id: json['id'] as String,
      mainProjectPath: json['mainProjectPath'] as String,
      officePath: json['officePath'] as String,
      cubicles: (json['cubicles'] as List<dynamic>)
          .map((c) => Cubicle.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
