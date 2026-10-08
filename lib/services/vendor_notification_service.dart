import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yesdhobi_ridervendor/models/vendor_order_model.dart';
import 'package:yesdhobi_ridervendor/services/rider_notification_service.dart';
import 'package:yesdhobi_ridervendor/services/vendor_order_service.dart';
import 'package:yesdhobi_ridervendor/widgets/incoming_vendor_order_dialog.dart';

class VendorNotificationService with WidgetsBindingObserver {
  static final VendorNotificationService _instance =
      VendorNotificationService._internal();
  static VendorNotificationService get instance => _instance;

  VendorNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final Set<String> _processedOrderIds = {};
  bool _isInitialized = false;
  bool _isDialogOpen = false;
  Timer? _pollingTimer;

  final ValueNotifier<VendorOrderModel?> activeIncomingOrder =
      ValueNotifier<VendorOrderModel?>(null);

  GlobalKey<NavigatorState> get navigatorKey =>
      RiderNotificationService.instance.navigatorKey;

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
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'incoming_vendor_orders',
            'Incoming Laundry Orders',
            description:
                'Urgent incoming laundry order requests with sound and full screen interrupt alerts',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.requestNotificationsPermission();
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Vendor notification service init fallback: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final actionId = response.actionId;
    final order = activeIncomingOrder.value;
    if (order == null) return;

    if (actionId == 'decline_vendor_order') {
      VendorOrderService.instance.rejectNewRequest(order.orderId);
      activeIncomingOrder.value = null;
      return;
    }

    if (actionId == 'accept_vendor_order') {
      VendorOrderService.instance.acceptNewRequest(order);
      activeIncomingOrder.value = null;
      return;
    }

    // Default tap on the notification:
    // Interrupts screen and shows the big screen popup dialog!
    showIncomingDialogGlobally(order);
  }

  Future<void> triggerIncomingVendorOrder(VendorOrderModel order) async {
    final key = order.rawId ?? order.orderId;
    if (_processedOrderIds.contains(key)) return;
    _processedOrderIds.add(key);

    activeIncomingOrder.value = order;

    // 1. Show native system notification with high urgency heads-up interruption
    await _showNativeSystemNotification(order);

    // 2. Interrupt any screen currently open in the app with Big Screen Popup
    showIncomingDialogGlobally(order);
  }

  Future<void> _showNativeSystemNotification(VendorOrderModel order) async {
    final androidDetails = AndroidNotificationDetails(
      'incoming_vendor_orders',
      'Incoming Laundry Orders',
      channelDescription:
          'Urgent incoming laundry order requests with sound and interrupt alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Urgent Laundry Request',
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.call,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      color: const Color(0xFF2563EB),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'accept_vendor_order',
          'Accept Order',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'decline_vendor_order',
          'Decline',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
      styleInformation: BigTextStyleInformation(
        '${order.customerName} placed a new order\n'
        '${order.itemsDescription}\n'
        'Value: ₹${order.totalAmount > 0 ? order.totalAmount.toStringAsFixed(2) : "112.00"} • Urgent response needed',
        contentTitle: 'New Order Request! • ${order.orderId}',
        summaryText: 'Yes Dhobi Vendor',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'VENDOR_ORDER_REQUEST_CATEGORY',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        id: order.orderId.hashCode,
        title: 'New Order Request! • ₹${order.totalAmount > 0 ? order.totalAmount.toStringAsFixed(2) : "112.00"}',
        body: '${order.customerName} • ${order.itemCount} Items • ${order.serviceType}',
        notificationDetails: notificationDetails,
        payload: order.orderId,
      );
    } catch (_) {}
  }

  void showIncomingDialogGlobally(VendorOrderModel order) {
    if (_isDialogOpen) return;
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      _isDialogOpen = true;
      IncomingVendorOrderDialog.show(ctx, order: order).then((_) {
        _isDialogOpen = false;
        if (activeIncomingOrder.value?.orderId == order.orderId) {
          activeIncomingOrder.value = null;
        }
      });
    }
  }

  void startListeningForVendorOrders() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final requests = VendorOrderService.instance.newRequests;
        if (requests.isNotEmpty) {
          final first = requests.first;
          final key = first.rawId ?? first.orderId;
          if (!_processedOrderIds.contains(key)) {
            triggerIncomingVendorOrder(first);
          }
        }
      } catch (e) {
        debugPrint('Polling vendor orders note: $e');
      }
    });
  }

  void stopListeningForVendorOrders() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void reset() {
    stopListeningForVendorOrders();
    activeIncomingOrder.value = null;
    _processedOrderIds.clear();
    _isDialogOpen = false;
  }
}
