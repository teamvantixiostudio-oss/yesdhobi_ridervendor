import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/widgets/app_logo.dart';
import 'package:yesdhobi_ridervendor/widgets/app_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/screens/rider_order_details_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';
import 'package:yesdhobi_ridervendor/models/pickup_request_notification_model.dart';
import 'package:yesdhobi_ridervendor/services/rider_notification_service.dart';
import 'package:yesdhobi_ridervendor/widgets/incoming_pickup_request_dialog.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';
import 'package:yesdhobi_ridervendor/models/order_flow_model.dart';
import 'package:yesdhobi_ridervendor/screens/portal_selection_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen>
    with WidgetsBindingObserver {
  bool get isOnline => RiderAuthService.instance.isOnline;
  List<Map<String, dynamic>> _activeOrders = [];
  double _todayEarnings = 0.0;
  int _completedCount = 0;
  bool _isLoading = false;
  Timer? _riderLocationTimer;
  String _currentGpsStatusText = 'Fetching live GPS...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RiderNotificationService.instance.activeIncomingRequest
        .addListener(_onIncomingRequest);
    if (RiderAuthService.instance.isOnline) {
      RiderNotificationService.instance.startListeningForRequests();
      _startRiderLocationHeartbeat();
    }
    _loadDashboardData();

    // Enforce Location on startup - Rider position is required for dispatch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestGoOnline();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isOnline) {
      _requestGoOnline();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _riderLocationTimer?.cancel();
    _riderLocationTimer = null;
    RiderNotificationService.instance.stopListeningForRequests();
    RiderNotificationService.instance.activeIncomingRequest
        .removeListener(_onIncomingRequest);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final ordersRes = await RiderApiService.instance.getRiderOrders(status: 'active');
      _activeOrders = List<Map<String, dynamic>>.from(ordersRes);
    } catch (e) {
      debugPrint('Error loading rider active orders: $e');
    }

    try {
      final earningsRes = await RiderApiService.instance.getRiderEarnings();
      if (earningsRes['today'] != null && earningsRes['today']['amount'] != null) {
        _todayEarnings = (earningsRes['today']['amount'] as num).toDouble();
      }
      if (earningsRes['today'] != null && earningsRes['today']['count'] != null) {
        _completedCount = (earningsRes['today']['count'] as num).toInt();
      }
    } catch (e) {
      debugPrint('Error loading rider earnings: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onIncomingRequest() {
    final req =
        RiderNotificationService.instance.activeIncomingRequest.value;
    if (req != null &&
        req.status == PickupRequestStatus.offered &&
        mounted) {
      IncomingPickupRequestDialog.show(context, request: req);
    }
  }

  void _applyOnlineToggle(bool val) async {
    setState(() {
      RiderAuthService.instance.setOnline(val);
    });
    if (val) {
      RiderNotificationService.instance.startListeningForRequests();
    } else {
      _riderLocationTimer?.cancel();
      _riderLocationTimer = null;
      RiderNotificationService.instance.stopListeningForRequests();
    }
    try {
      await RiderApiService.instance.setAvailability(val ? 'ONLINE' : 'OFFLINE');
    } catch (e) {
      debugPrint('Availability update note: $e');
    }
  }

  void _startRiderLocationHeartbeat() {
    _riderLocationTimer?.cancel();
    _riderLocationTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      if (!mounted || !RiderAuthService.instance.isOnline) return;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        await RiderApiService.instance.updateLocation(pos.latitude, pos.longitude);
        if (mounted) {
          setState(() {
            _currentGpsStatusText =
                'Live GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
          });
        }
      } catch (e) {
        debugPrint('Rider location heartbeat error: $e');
      }
    });
  }

  void _showLocationRequiredDialog({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                label: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestGoOnline() async {
    // 1. Verify GPS service is enabled on device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      _showLocationRequiredDialog(
        title: 'Device GPS Required',
        message: 'Yes Dhobi requires device location/GPS to be enabled so you can receive nearby delivery requests and calculate driving routes accurately.',
        actionLabel: 'Turn On Location',
        onAction: () async {
          Navigator.pop(context);
          await Geolocator.openLocationSettings();
        },
      );
      return;
    }

    // 2. Verify GPS permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      _showLocationRequiredDialog(
        title: 'Location Permission Required',
        message: 'To receive orders in your area and track pickups, please grant location access in device settings.',
        actionLabel: 'Open App Settings',
        onAction: () async {
          Navigator.pop(context);
          await Geolocator.openAppSettings();
        },
      );
      return;
    }

    // 3. Immediately fetch real coordinates & send to backend dispatch
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await RiderApiService.instance.updateLocation(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentGpsStatusText =
              'Live GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      debugPrint('Initial rider GPS sync: $e');
    }

    // 4. Set online & start heartbeat
    _applyOnlineToggle(true);
    _startRiderLocationHeartbeat();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are now ONLINE with live GPS dispatch active!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleOnlineStatus() {
    final bool currentStatus = RiderAuthService.instance.isOnline;
    if (currentStatus) {
      // Going ONLINE -> OFFLINE with active order check
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Go Offline?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          content: const Text(
            'You will stop receiving new pickup requests, but your current order will remain active.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _applyOnlineToggle(false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Go Offline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    _requestGoOnline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const YesDhobiLogo(
          height: 28,
          variant: LogoVariant.navy,
        ),
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D2B4)),
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout Rider'),
                  content: const Text(
                      'Are you sure you want to log out of your rider account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await RiderApiService.instance.logout();
                RiderAuthService.instance.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PortalSelectionScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Rider Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage your status and available deliveries',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Rider Availability',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOnline ? 'ON' : 'OFF',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch.adaptive(
                            value: isOnline,
                            activeColor: const Color(0xFF10B981),
                            activeTrackColor: const Color(0xFFD1FAE5),
                            inactiveThumbColor: const Color(0xFF94A3B8),
                            inactiveTrackColor: const Color(0xFFE2E8F0),
                            onChanged: (val) {
                              if (val) {
                                _requestGoOnline();
                              } else {
                                _toggleOnlineStatus();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Today's Earnings",
                        value: '₹${_todayEarnings.toStringAsFixed(0)}',
                        subtitle: 'Live synced',
                        subtitleColor: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Completed',
                        value: '$_completedCount Orders',
                        subtitle: 'Today\'s deliveries',
                        subtitleColor: const Color(0xFF64748B),
                        valueColor: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

              // Real Live GPS Tracking & Dispatch Status Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOnline ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isOnline
                          ? const Color(0xFF10B981).withOpacity(0.08)
                          : Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isOnline ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                        color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isOnline ? 'Live GPS Dispatch Active' : 'Rider is Offline',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isOnline ? const Color(0xFF15803D) : const Color(0xFF475569),
                                ),
                              ),
                              if (isOnline) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isOnline
                                ? 'Real-time location active (15s dispatch timer) • $_currentGpsStatusText'
                                : 'Switch Rider Availability ON above to start receiving delivery requests',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? const Color(0xFF166534) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Active Orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '(${_activeOrders.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_activeOrders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.pedal_bike_rounded,
                          size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No Active Orders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOnline
                            ? 'You are Online. Looking for new pickup and delivery requests nearby...'
                            : 'You are currently Offline. Turn availability ON to receive orders.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._activeOrders.map((order) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildActiveOrderCard(orderData: order),
                    )),
              const SizedBox(height: 32),
              
              // Pickup History
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pickup History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildHistoryCard(
                name: 'Rahul Sharma',
                address: 'B-402, Shanti Vihar, Sector 45',
                items: '12-15 items',
                timeInfo: 'Completed: 14 Mar • 10:42 AM',
                amount: '₹120',
              ),
              const SizedBox(height: 16),
              _buildHistoryCard(
                name: 'Priya Patel',
                address: 'Flat 12A, Royal Crest Towers, HSR',
                items: '8-10 items',
                timeInfo: 'Completed: 14 Mar • 11:15 AM',
                amount: '₹95',
              ),
              const SizedBox(height: 16),
              _buildHistoryCard(
                name: 'Amit Verma',
                address: 'No. 45, Ground Floor, 5th Cross, Indiranagar',
                items: '20+ items',
                timeInfo: 'Completed: 13 Mar • 6:20 PM',
                amount: '₹185',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: const AppBottomNav(currentIndex: 0),
  );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    Color valueColor = AppTheme.primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard({Map<String, dynamic>? orderData}) {
    final OrderFlowState state = orderData != null
        ? OrderFlowState.fromApiJson(orderData)
        : OrderFlowState(
            orderId: '#YD-20240318-001',
            customerName: 'Sneha Kapoor',
            customerInitials: 'SK',
            customerAddress: 'B-402, Shanti Vihar, Sector 45',
            estimatedLoad: '8-12 items',
          );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            state.stage.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.customerAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          state.estimatedLoad,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            state.orderId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RiderOrderDetailsScreen(orderState: state),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'View Order',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String name,
    required String address,
    required String items,
    required String timeInfo,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                items,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                timeInfo,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
