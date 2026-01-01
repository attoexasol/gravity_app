import 'package:flutter/foundation.dart';
import 'package:gravityapp/data/model/message.dart';

/// Pure helper class for message-related operations
/// Contains all business logic for filtering, mapping, and calculating unread counts
class MessageUtils {
  /// Parse user ID from API response (handles both direct fields and nested user objects)
  static int? parseUserId(dynamic userIdValue) {
    if (userIdValue == null) return null;
    if (userIdValue is int) return userIdValue;
    if (userIdValue is String) {
      return int.tryParse(userIdValue);
    }
    return null;
  }

  /// Extract from_user_id from message JSON
  static int? extractFromUserId(Map<String, dynamic> messageJson) {
    final fromUserId = messageJson['from_user_id'] ?? messageJson['from_user']?['id'];
    return parseUserId(fromUserId);
  }

  /// Extract to_user_id from message JSON
  static int? extractToUserId(Map<String, dynamic> messageJson) {
    final toUserId = messageJson['to_user_id'] ?? messageJson['to_user']?['id'];
    return parseUserId(toUserId);
  }

  /// Filter messages for a conversation between currentUser and otherUser
  /// Returns only messages that belong to this conversation
  static List<Map<String, dynamic>> filterConversationMessages(
    List<Map<String, dynamic>> allMessages,
    int currentUserId,
    int otherUserId,
  ) {
    if (currentUserId == otherUserId) {
      debugPrint('⚠️ MessageUtils: Cannot filter messages for self-conversation');
      return [];
    }

    return allMessages.where((msg) {
      final fromUserId = extractFromUserId(msg);
      final toUserId = extractToUserId(msg);

      if (fromUserId == null || toUserId == null) {
        return false;
      }

      // Message belongs to conversation if:
      // - from_user_id is currentUser AND to_user_id is otherUser, OR
      // - from_user_id is otherUser AND to_user_id is currentUser
      final isFromCurrentToOther = fromUserId == currentUserId && toUserId == otherUserId;
      final isFromOtherToCurrent = fromUserId == otherUserId && toUserId == currentUserId;

      return isFromCurrentToOther || isFromOtherToCurrent;
    }).toList();
  }

  /// Map API message JSON to Message model
  static Message mapApiMessage(
    Map<String, dynamic> json,
    int? currentUserId,
  ) {
    final messageId = json['id']?.toString() ?? json['message_id']?.toString() ?? '';
    final fromUserId = extractFromUserId(json);
    final messageText = json['message'] ?? json['message_content'] ?? json['text'] ?? '';

    // Determine if message is sent by current user
    final isSent = currentUserId != null && fromUserId == currentUserId;

    // Parse timestamp - prefer updated_at if available (indicates message was edited)
    DateTime timestamp = DateTime.now();
    String? timestampStr = json['updated_at']?.toString() ?? json['created_at']?.toString();
    if (timestampStr != null) {
      try {
        final parsedTime = DateTime.parse(timestampStr);
        // Convert UTC to local time if the timestamp is in UTC
        timestamp = parsedTime.isUtc ? parsedTime.toLocal() : parsedTime;
      } catch (e) {
        debugPrint('⚠️ MessageUtils: Error parsing timestamp: $e');
        timestamp = DateTime.now(); // Fallback to current time
      }
    }

    // Parse is_read field - handle both integer (0/1) and boolean values
    bool isRead = false;
    final isReadValue = json['is_read'];
    if (isReadValue != null) {
      if (isReadValue is bool) {
        isRead = isReadValue;
      } else if (isReadValue is int) {
        isRead = isReadValue == 1; // 0 = false (unread), 1 = true (read)
      } else if (isReadValue is String) {
        isRead = isReadValue == '1' || isReadValue.toLowerCase() == 'true';
      }
    } else {
      // Fallback to 'read' field if 'is_read' is not present
      final readValue = json['read'];
      if (readValue != null) {
        if (readValue is bool) {
          isRead = readValue;
        } else if (readValue is int) {
          isRead = readValue == 1;
        } else if (readValue is String) {
          isRead = readValue == '1' || readValue.toLowerCase() == 'true';
        }
      }
    }

    return Message(
      id: messageId,
      senderId: fromUserId?.toString() ?? 'unknown',
      text: messageText.toString(),
      timestamp: timestamp,
      isRead: isRead,
      isSent: isSent,
    );
  }

  /// Calculate unread count from a list of messages
  /// Only counts messages that are:
  /// - Not sent by current user (isSent == false)
  /// - Not read (isRead == false)
  static int calculateUnreadCount(List<Message> messages) {
    return messages.where((m) => !m.isSent && !m.isRead).length;
  }

  /// Remove duplicate messages by ID (keeps the first occurrence)
  static List<Message> removeDuplicateMessages(List<Message> messages) {
    final seenIds = <String>{};
    final uniqueMessages = <Message>[];

    for (final message in messages) {
      if (!seenIds.contains(message.id)) {
        seenIds.add(message.id);
        uniqueMessages.add(message);
      }
    }

    return uniqueMessages;
  }

  /// Sort messages by timestamp (ascending - oldest first)
  static List<Message> sortMessagesByTimestamp(List<Message> messages) {
    final sorted = List<Message>.from(messages);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }
}

