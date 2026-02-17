class SyncAction {
  final String actionId;
  final String type;
  final Map<String, dynamic> payload;
  final int retryCount;
  final DateTime createdAt;

  SyncAction({
    required this.actionId,
    required this.type,
    required this.payload,
    this.retryCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'actionId': actionId,
      'type': type,
      'payload': payload,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncAction.fromMap(Map<dynamic, dynamic> map) {
    return SyncAction(
      actionId: map['actionId'],
      type: map['type'],
      payload: Map<String, dynamic>.from(map['payload']),
      retryCount: map['retryCount'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
