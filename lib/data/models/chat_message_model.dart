enum MessageStatus { sent, delivered, read }

enum SenderType { user, ai }

enum MessageType { text, link }

class MessagePart {
  final String text;
  final bool isLink;
  final String? linkType; // 'apartment' or 'share'
  final String? referenceId;
  final bool isBold;

  MessagePart({
    required this.text,
    this.isLink = false,
    this.linkType,
    this.referenceId,
    this.isBold = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isLink': isLink,
        'linkType': linkType,
        'referenceId': referenceId,
        'isBold': isBold,
      };

  factory MessagePart.fromJson(Map<String, dynamic> json) => MessagePart(
        text: json['text'],
        isLink: json['isLink'] ?? false,
        linkType: json['linkType'],
        referenceId: json['referenceId'],
        isBold: json['isBold'] ?? false,
      );
}

class ChatMessage {
  final String id;
  final String text;
  final SenderType senderType;
  final DateTime timestamp;
  final MessageStatus status;
  final List<MessagePart> parsedParts;
  final MessageType messageType;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderType,
    required this.timestamp,
    this.status = MessageStatus.sent,
    required this.parsedParts,
    this.messageType = MessageType.text,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    SenderType? senderType,
    DateTime? timestamp,
    MessageStatus? status,
    List<MessagePart>? parsedParts,
    MessageType? messageType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      senderType: senderType ?? this.senderType,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      parsedParts: parsedParts ?? this.parsedParts,
      messageType: messageType ?? this.messageType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'senderType': senderType.name,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'parsedParts': parsedParts.map((part) => part.toJson()).toList(),
        'messageType': messageType.name,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        text: json['text'],
        senderType: SenderType.values.byName(json['senderType']),
        timestamp: DateTime.parse(json['timestamp']),
        status: MessageStatus.values.byName(json['status']),
        parsedParts: (json['parsedParts'] as List)
            .map((part) => MessagePart.fromJson(part))
            .toList(),
        messageType: MessageType.values.byName(json['messageType']),
      );
} 