class NotificationItem {
  final int id;
  final int memberId;
  final String type;
  final String title;
  final String body;
  final String link;
  final int? tableId;
  final String? readAt;
  final bool actioned;
  final String createdAt;

  const NotificationItem({
    required this.id,
    required this.memberId,
    required this.type,
    required this.title,
    required this.body,
    required this.link,
    this.tableId,
    this.readAt,
    required this.actioned,
    required this.createdAt,
  });

  bool get isRead => readAt != null;
  bool get isInvite => type == 'davet';

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['id'] as int,
        memberId: j['member_id'] as int? ?? 0,
        type: j['type'] as String? ?? 'genel',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        link: j['link'] as String? ?? '',
        tableId: j['table_id'] as int?,
        readAt: j['read_at'] as String?,
        actioned: j['actioned'] as bool? ?? false,
        createdAt: j['created_at'] as String? ?? '',
      );
}
