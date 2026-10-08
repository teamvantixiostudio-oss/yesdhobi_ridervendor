import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yesdhobi_ridervendor/models/pickup_request_notification_model.dart';
import 'package:yesdhobi_ridervendor/models/order_flow_model.dart';
import 'package:yesdhobi_ridervendor/screens/rider_order_details_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';
import 'package:yesdhobi_ridervendor/widgets/incoming_pickup_request_dialog.dart';

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
  bool _isDialogOpen = false;
  Timer? _pollingTimer;

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

    if (actionId == 'accept_pickup') {
      acceptPickupRequest(request);
      return;
    }

    // Default tap on the notification:
    // Interrupts current screen and shows the big screen popup dialog!
    showIncomingDialogGlobally(request);
  }

  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    // Handled on app wakeup
  }

  void showIncomingDialogGlobally(PickupRequestNotificationModel request) {
    if (_isDialogOpen) return;
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      _isDialogOpen = true;
      IncomingPickupRequestDialog.show(ctx, request: request).then((_) {
        _isDialogOpen = false;
      });
    }
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

    // Global in-app big screen interrupt dialog
    showIncomingDialogGlobally(request);
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
      category: AndroidNotificationCategory.call,
      vibrationPattern: Int64List.fromList([0, 600, 250, 600]),
      color: const Color(0xFF2563EB),
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
        contentTitle: 'New Request! (15s)',
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

  void startListeningForRequests() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!RiderAuthService.instance.isOnline) return;
      if (activeIncomingRequest.value != null && !activeIncomingRequest.value!.isExpired) return;

      try {
        final requests = await RiderApiService.instance.getRiderRequests();
        if (requests.isNotEmpty) {
          final first = requests.first;
          final model = PickupRequestNotificationModel.fromApiJson(first);
          if (!_processedRequestIds.contains(model.requestId) && !model.isExpired) {
            triggerIncomingPickup(model);
          }
        }
      } catch (e) {
        debugPrint('Polling rider requests: $e');
      }
    });
  }

  void stopListeningForRequests() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> acceptPickupRequest(PickupRequestNotificationModel request,
      {BuildContext? context}) async {
    request.status = PickupRequestStatus.accepted;
    activeIncomingRequest.value = null;

    if (_isSafePlatform()) {
      try {
        _localNotifications.cancel(id: request.requestId.hashCode);
      } catch (_) {}
    }

    // The server is the only thing that decides who owns this order. If the
    // accept is refused - another rider got there first, or the 15 second
    // window ran out - we must NOT carry on into the pickup flow. Swallowing
    // the error here used to take the rider to a job the server had already
    // given to someone else: they would walk to the customer, and then every
    // OTP step afterwards failed because they were not the assigned rider.
    OrderFlowState orderState = request.toOrderFlowState();
    final isRealRequest = request.requestId.isNotEmpty &&
        !request.requestId.startsWith('sample') &&
        !request.requestId.startsWith('REQ-');
    if (isRealRequest) {
      try {
        final orderRes = await RiderApiService.instance.acceptRequest(request.requestId);
        if (orderRes.isNotEmpty && (orderRes.containsKey('id') || orderRes.containsKey('orderNumber'))) {
          orderState = OrderFlowState.fromApiJson(orderRes);
        }
      } catch (e) {
        debugPrint('Accept refused by backend: $e');
        request.status = PickupRequestStatus.expired;
        final message = e.toString().replaceAll('Exception:', '').trim();
        final ctx = context ?? navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(message.isEmpty
                  ? 'That request is no longer available.'
                  : message),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => RiderOrderDetailsScreen(orderState: orderState),
      ),
    );
  }

  Future<void> declinePickupRequest(PickupRequestNotificationModel request) async {
    request.status = PickupRequestStatus.declined;
    activeIncomingRequest.value = null;

    if (_isSafePlatform()) {
      try {
        _localNotifications.cancel(id: request.requestId.hashCode);
      } catch (_) {}
    }

    try {
      if (request.requestId.isNotEmpty && !request.requestId.startsWith('sample') && !request.requestId.startsWith('REQ-')) {
        await RiderApiService.instance.declineRequest(request.requestId);
      }
    } catch (e) {
      debugPrint('Error declining request on backend: $e');
    }
  }

  Future<void> expirePickupRequest(PickupRequestNotificationModel request) async {
    request.status = PickupRequestStatus.expired;
    activeIncomingRequest.value = null;

    if (_isSafePlatform()) {
      try {
        _localNotifications.cancel(id: request.requestId.hashCode);
      } catch (_) {}
    }

    try {
      if (request.requestId.isNotEmpty && !request.requestId.startsWith('sample') && !request.requestId.startsWith('REQ-')) {
        await RiderApiService.instance.declineRequest(request.requestId);
      }
    } catch (e) {
      debugPrint('Error expiring request on backend: $e');
    }
  }

  void reset() {
    stopListeningForRequests();
    activeIncomingRequest.value = null;
    _processedRequestIds.clear();
  }
}
