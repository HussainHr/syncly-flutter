import 'dart:convert';
import 'dart:developer' as synclyLogger;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncly/core/models/notification/local_notification_model.dart';

class NotificationStorageService {
  static const String _key = 'stored_notifications';

  static Future<List<LocalNotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString(_key);

      if (notificationsJson == null) return [];

      final List<dynamic> notificationsList = json.decode(notificationsJson);
      return notificationsList
          .map((json) => LocalNotificationModel.fromJson(json)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Latest first
    } catch (e) {
      synclyLogger.log('Error loading notifications: $e');
      return [];
    }
  }

  static Future<void> saveNotification(LocalNotificationModel notification) async {
    try {
      final notifications = await getNotifications();

      // Check if notification already exists (avoid duplicates)
      final existingIndex = notifications.indexWhere((n) => n.id == notification.id);
      if (existingIndex != -1) {
        notifications[existingIndex] = notification;
      } else {
        notifications.insert(0, notification); // Add to beginning
      }

      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }

      await _saveNotifications(notifications);
    } catch (e) {
      synclyLogger.log('Error saving notification: $e');
    }
  }

  static Future<LocalNotificationModel?> getNotificationById(String id) async {
    try {
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) return notifications[index];
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);

      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await _saveNotifications(notifications);
      }
    } catch (e) {
      synclyLogger.log('Error marking notification as read: $e');
    }
  }

  static Future<void> markAllAsRead() async {
    try {
      final notifications = await getNotifications();
      final updatedNotifications = notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      await _saveNotifications(updatedNotifications);
    } catch (e) {
      synclyLogger.log('Error marking all notifications as read: $e');
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await getNotifications();
      notifications.removeWhere((n) => n.id == notificationId);
      await _saveNotifications(notifications);
    } catch (e) {
      synclyLogger.log('Error deleting notification: $e');
    }
  }

  static Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      synclyLogger.log('Error clearing notifications: $e');
    }
  }

  static Future<void> _saveNotifications(List<LocalNotificationModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = json.encode(
      notifications.map((n) => n.toJson()).toList(),
    );
    await prefs.setString(_key, notificationsJson);
  }

  static Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      synclyLogger.log('Error getting unread count: $e');
      return 0;
    }
  }
}