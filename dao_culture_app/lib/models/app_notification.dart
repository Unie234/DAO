import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String postId;
  final String commentId;
  final DateTime? createdAt;
  final String priority;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.postId,
    required this.commentId,
    required this.createdAt,
    required this.priority,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'new_post',
      title: json['title']?.toString() ?? 'Thông báo',
      message: json['message']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      commentId: json['comment_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      priority: json['priority']?.toString() ?? 'normal',
      isRead: json['is_read'] == true || json['is_read']?.toString() == '1',
    );
  }

  IconData get icon {
    switch (type) {
      case 'post_reaction':
        return Icons.favorite_rounded;
      case 'post_comment':
        return Icons.mode_comment_rounded;
      case 'comment_reply':
        return Icons.reply_rounded;
      case 'comment_reaction':
        return Icons.add_reaction_rounded;
      case 'featured_post':
        return Icons.local_fire_department_rounded;
      case 'community_violation':
      case 'post_hidden':
        return Icons.gpp_maybe_rounded;
      case 'new_post':
      default:
        return Icons.article_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'post_reaction':
        return const Color(0xFFE51B23);
      case 'post_comment':
      case 'comment_reply':
      case 'comment_reaction':
        return const Color(0xFF7657D8);
      case 'featured_post':
        return const Color(0xFFE49B2D);
      case 'community_violation':
      case 'post_hidden':
        return const Color(0xFFD93829);
      case 'new_post':
      default:
        return const Color(0xFF397FA8);
    }
  }
}
