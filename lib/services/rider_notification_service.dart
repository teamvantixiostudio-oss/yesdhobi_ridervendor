import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yesdhobi_ridervendor/models/pickup_request_notification_model.dart';
import 'package:yesdhobi_ridervendor/screens/rider_order_details_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';

class RiderNotificationService with WidgetsBindingObserver {
  static final RiderNotificationService _instance =
      RiderNotificationService._internal();
  static RiderNotificationService get instance => _instance;

  RiderNotificationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<PickupRequestNotificationModel?> activeIncomingRequest =
      ValueNotifier<PickupRequestNotificationModel?>(null);

  final Set<String> _processedRequestIds = {};
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _isInitialized = false;

  bool get isAppForeground => _lifecycleState == AppLifecycleState.resumed;

  bool _isSafePlatform() {
    try {
      return _isInitialized;
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
      );

      _isInitialized = true;

      // Create Android Notification Channel
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'incoming_pickup_requests',
            'Incoming Pickup Requests',
            description:
                'Urgent notifications for customer pickup requests with lock screen and sound alerts',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (_) {
      // Graceful fallback in test/mock environments
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final actionId = response.actionId;

    final request = activeIncomingRequest.value ??
        PickupRequestNotificationModel.createDefaultSample();

    if (actionId == 'decline_pickup') {
      declinePickupRequest(request);
      return;
    }

    // Default tap or Accept Action -> Accept and Open Order Request
    acceptPickupRequest(request);
  }

  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    // Handled on app wakeup
  }

  Future<void> triggerIncomingPickup(
      PickupRequestNotificationModel request) async {
    // Offline check: do not offer new pickup requests to offline riders
    if (!RiderAuthService.instance.isOnline) {
      return;
    }

    // Deduplication check
    if (_processedRequestIds.contains(request.requestId) &&
        request.status != PickupRequestStatus.offered) {
      return;
    }
    _processedRequestIds.add(request.requestId);

    request.status = PickupRequestStatus.offered;
    activeIncomingRequest.value = request;

    // Show native system/lock-screen notification
    await _showNativeSystemNotification(request);
  }

  Future<void> _showNativeSystemNotification(
      PickupRequestNotificationModel request) async {
    if (!_isSafePlatform()) return;

    final androidDetails = AndroidNotificationDetails(
      'incoming_pickup_requests',
      'Incoming Pickup Requests',
      channelDescription:
          'Urgent notifications for customer pickup requests',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Urgent Pickup Request',
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'accept_pickup',
          'Accept Pickup',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'decline_pickup',
          'Decline',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
      styleInformation: BigTextStyleInformation(
        '${request.customerName}\n${request.pickupAddress}, ${request.pickupArea}\n'
        'Distance: ${request.formattedDistance} • Items: ${request.estimatedItemsText}\n'
        'Payout: ${request.formattedPayout} • Urgent response needed',
        contentTitle: 'New Request! (12s)',
        summaryText: 'Yes Dhobi Rider',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'PICKUP_REQUEST_CATEGORY',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        id: request.requestId.hashCode,
        title: 'New Request! • ${request.formattedPayout}',
        body:
            '${request.customerName} • ${request.formattedDistance} • ${request.estimatedItemsText}',
        notificationDetails: notificationDetails,
        payload: request.requestId,
      );
    } catch (_) {
      // Graceful fallback
    }
  }

  void acceptPickupRequest(PickupRequestNotificationModel request,
      {BuildContext? context}) {
    request.status = PickupRequestStatus.accepted;
    activeIncomingRequest.value = null;

    if (_isSafePlatform()) {
      try {
        _localNotifications.cancel(id: request.requestId.hashCode);
      } catch (_) {}
    }

    final orderState = request.toOrderFlowState();

    final navContext = context ?? navigatorKey.currentContext;
    if (navContext != null) {
      Navigator.of(navContext).push(
        MaterialPageRoute(
          builder: (_) => RiderOrderDetailsScreen(orderState: orderState),
        ),
      );
    }
  }

  void declinePickupRequest(PickupRequestNotificationModel request) {
    request.status = PickupRequestStatus.declined;
    activeIncomingRequest.value = null;

    if (_isSafePlatform()) {
      try {
        _localNotifications.cancel(id: request.requestId.hashCode);
      } catch (_) {}
    }
  }

  void expirePickupRequest(PickupRequestNotificationModel request) {
    request.status = PickupRequestStatus.expired;
    activeIncomingRequest.value = null;

    if (_isSafePlatform()) {
      try {
        _localNotifications.cancel(id: request.requestId.hashCode);
      } catch (_) {}
    }
  }

  void reset() {
    activeIncomingRequest.value = null;
    _processedRequestIds.clear();
  }
}
