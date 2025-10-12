import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static const String _eventsKey = 'analytics_events';
  static const int _maxEvents = 1000;
  
  final SharedPreferences _prefs;

  AnalyticsService({required SharedPreferences prefs}) : _prefs = prefs;

  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    try {
      final event = {
        'event_name': eventName,
        'parameters': parameters ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': await _getSessionId(),
      };

      final events = await _getStoredEvents();
      events.add(event);

      // 最大イベント数を超えた場合、古いイベントを削除
      if (events.length > _maxEvents) {
        events.removeRange(0, events.length - _maxEvents);
      }

      await _prefs.setString(_eventsKey, json.encode(events));
      print('Analytics: $eventName logged with parameters: $parameters');
    } catch (e) {
      print('Analytics error: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', {'screen_name': screenName});
  }

  Future<void> logButtonTap(String buttonName, {String? screenName}) async {
    await logEvent('button_tap', {
      'button_name': buttonName,
      if (screenName != null) 'screen_name': screenName,
    });
  }

  Future<void> logPhoneCall(String phoneNumber) async {
    await logEvent('phone_call', {'phone_number': phoneNumber});
  }

  Future<void> logBookingAttempt(String source) async {
    await logEvent('booking_attempt', {'source': source});
  }

  Future<void> logMapOpen(String location) async {
    await logEvent('map_open', {'location': location});
  }

  Future<void> logServiceView(String serviceId, String serviceName) async {
    await logEvent('service_view', {
      'service_id': serviceId,
      'service_name': serviceName,
    });
  }

  Future<void> logGalleryImageView(String imageId) async {
    await logEvent('gallery_image_view', {'image_id': imageId});
  }

  Future<List<Map<String, dynamic>>> getStoredEvents() async {
    return await _getStoredEvents();
  }

  Future<void> clearEvents() async {
    try {
      await _prefs.remove(_eventsKey);
    } catch (e) {
      print('Error clearing analytics events: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getStoredEvents() async {
    try {
      final eventsJson = _prefs.getString(_eventsKey);
      if (eventsJson != null) {
        final List<dynamic> eventsList = json.decode(eventsJson);
        return eventsList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error reading stored events: $e');
    }
    return [];
  }

  Future<String> _getSessionId() async {
    const sessionKey = 'analytics_session_id';
    String? sessionId = _prefs.getString(sessionKey);
    
    if (sessionId == null) {
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _prefs.setString(sessionKey, sessionId);
    }
    
    return sessionId;
  }
}
