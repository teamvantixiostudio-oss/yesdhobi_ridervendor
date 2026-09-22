import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';
import 'package:yesdhobi_ridervendor/screens/rider_dashboard_screen.dart';
import 'package:yesdhobi_ridervendor/screens/order_history_screen.dart';
import 'package:yesdhobi_ridervendor/screens/rider_earnings_screen.dart';
import 'package:yesdhobi_ridervendor/screens/rider_profile_screen.dart';

void main() {
  group('Rider Bottom Navigation & 3 New Rider Screens (History, Earnings, Profile) Tests', () {
    testWidgets('TEST 1: Home Tab -> Rider Dashboard Screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: RiderDashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yes Dhobi'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('TEST 2: Orders Tab -> Order History Screen UI and Cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: OrderHistoryScreen()),
      );
      await tester.pumpAndSettle();

      // Brand & Header
      expect(find.text('Yes Dhobi'), findsOneWidget);
      expect(find.text('RIDER'), findsOneWidget);
      expect(find.text('Order History'), findsOneWidget);
      expect(find.text('Overview of all your past orders'), findsOneWidget);

      // Filters
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('All Statuses'), findsOneWidget);

      // Order 1: #YD-90823
      expect(find.text('#YD-90823'), findsOneWidget);
      expect(find.text('12th Oct 2026'), findsOneWidget);
      expect(find.text('From: Rahul Sharma, Sector 45'), findsOneWidget);
      expect(find.text('To: Yes Dhobi Sector 44'), findsOneWidget);
      expect(find.text('₹65.00'), findsOneWidget);

      // Order 2: #YD-90761
      expect(find.text('#YD-90761'), findsOneWidget);
      expect(find.text('11th Oct 2026'), findsOneWidget);
      expect(find.text('From: Karan Mehra, Indiranagar'), findsOneWidget);
      expect(find.text('To: Yes Dhobi Indiranagar'), findsNWidgets(2)); // Order 2 and Order 3
      expect(find.text('₹140.00'), findsOneWidget);

      // Order 3: #YD-90512
      expect(find.text('#YD-90512'), findsOneWidget);
      expect(find.text('09th Oct 2026'), findsOneWidget);
      expect(find.text('From: Supriya Sen, Domlur'), findsOneWidget);
      expect(find.text('₹0.00'), findsOneWidget);

      // Order 4: #YD-90119
      expect(find.text('#YD-90119'), findsOneWidget);
      expect(find.text('07th Oct 2026'), findsOneWidget);
      expect(find.text('From: Gaurav Das, Koramangala'), findsOneWidget);
      expect(find.text('To: Yes Dhobi HSR'), findsOneWidget);
      expect(find.text('₹95.00'), findsOneWidget);
    });

    testWidgets('TEST 3: Earnings Tab -> My Earnings Screen UI and Features', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: RiderEarningsScreen()),
      );
      await tester.pumpAndSettle();

      // Brand & Header
      expect(find.text('Yes Dhobi'), findsOneWidget);
      expect(find.text('RIDER'), findsOneWidget);
      expect(find.text('My Earnings'), findsOneWidget);
      expect(find.text('Track your daily and weekly payouts'), findsOneWidget);

      // Period filters
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);

      // Total Outstanding Payout Card
      expect(find.text('TOTAL OUTSTANDING PAYOUT'), findsOneWidget);
      expect(find.text('₹4,890.00'), findsOneWidget);
      expect(find.text('Bank: State Bank of India • • • • 4012'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);

      // Withdraw Button
      expect(find.text('Withdraw to Bank Account'), findsOneWidget);
      await tester.tap(find.text('Withdraw to Bank Account'));
      await tester.pump();
      expect(find.text('Withdrawal request of ₹4,890.00 submitted to State Bank of India.'), findsOneWidget);

      // Recent Transactions
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('Pickup: Rahul Sharma'), findsOneWidget);
      expect(find.text('Today, 10:45 AM'), findsOneWidget);
      expect(find.text('₹65.00'), findsOneWidget);

      expect(find.text('Pickup: Anita Desai'), findsOneWidget);
      expect(find.text('Today, 09:12 AM'), findsOneWidget);
      expect(find.text('₹80.00'), findsOneWidget);

      expect(find.text('Pickup: Vijay K'), findsOneWidget);
      expect(find.text('Yesterday, 06:30 PM'), findsOneWidget);
      expect(find.text('₹75.00'), findsOneWidget);

      expect(find.text('Pickup: Zeenat Banu'), findsOneWidget);
      expect(find.text('Yesterday, 04:15 PM'), findsOneWidget);
      expect(find.text('₹120.00'), findsOneWidget);
    });

    testWidgets('TEST 4: Profile Tab -> My Profile Screen UI, Statistics, Vehicle Details', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: RiderProfileScreen()),
      );
      await tester.pumpAndSettle();

      // Brand & Header
      expect(find.text('Yes Dhobi'), findsOneWidget);
      expect(find.text('RIDER'), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Manage your personal and vehicle details'), findsOneWidget);

      // Profile Card
      expect(find.text('VERIFIED PARTNER'), findsOneWidget);
      expect(find.text('Zack Colah'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);

      // Statistics Row
      expect(find.text('240'), findsOneWidget);
      expect(find.text('All Deliveries'), findsOneWidget);
      expect(find.text('4.8★'), findsOneWidget);
      expect(find.text('My Rating'), findsOneWidget);
      expect(find.text('2.5 yrs'), findsOneWidget);
      expect(find.text('Tenure'), findsOneWidget);

      // Vehicle & Identity Card
      expect(find.text('Vehicle & Identity'), findsOneWidget);
      expect(find.text('Vehicle Registered'), findsOneWidget);
      expect(find.text('Honda Activa 5G (Electric Blue)'), findsOneWidget);
      expect(find.text('Vehicle Number'), findsOneWidget);
      expect(find.text('DL-3C-AL-9023'), findsOneWidget);
      expect(find.text('Aadhaar Status'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('License Status'), findsOneWidget);
      expect(find.text('Verified (Expires 2031)'), findsOneWidget);

      // Buttons
      expect(find.text('Edit Profile Settings'), findsOneWidget);
      expect(find.text('Logout Partner Portal'), findsOneWidget);
    });

    testWidgets('TEST 5: Order History -> Order Details -> Pickup Verification -> OTP -> Order Status flow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: OrderHistoryScreen()),
      );
      await tester.pumpAndSettle();

      // 1. Tap on Order 1 from Order History
      await tester.tap(find.text('#YD-90823'));
      await tester.pumpAndSettle();

      // 2. Opens Order Details
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('PickUp Laundry'), findsOneWidget);

      // 3. Tap PickUp Laundry -> Opens Pickup Verification & Pricing
      await tester.tap(find.text('PickUp Laundry'));
      await tester.pumpAndSettle();

      expect(find.text('Pickup Verification'), findsOneWidget);
      expect(find.text('+ Add Wash & Fold items'), findsOneWidget);

      // 4. Tap "+ Add Wash & Fold items" to open bottom sheet
      await tester.tap(find.text('+ Add Wash & Fold items'));
      await tester.pumpAndSettle();

      expect(find.text('Enter item weight'), findsOneWidget);

      // Enter weight '2.5' and add item
      final weightField = find.byType(TextField);
      await tester.enterText(weightField, '2.5');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();

      // Verified item added on Pickup Verification screen
      expect(find.text('2.5 kg • ₹200'), findsOneWidget);

      // 5. Tap "Confirm Pickup & Price" -> Opens Confirm Pickup (OTP)
      await tester.tap(find.text('Confirm Pickup & Price'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Pickup'), findsOneWidget);
      expect(find.text('Enter Pickup Confirmation OTP'), findsOneWidget);
      expect(find.text('Verify & Confirm Pickup'), findsOneWidget);

      // 6. Enter OTP and verify
      final otpFields = find.byType(TextField);
      await tester.enterText(otpFields.at(0), '5');
      await tester.enterText(otpFields.at(1), '8');
      await tester.enterText(otpFields.at(2), '1');
      await tester.enterText(otpFields.at(3), '2');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify & Confirm Pickup'));
      await tester.pumpAndSettle();

      // 7. Opens Order Status
      expect(find.text('Order Status'), findsOneWidget);
      expect(find.text('Navigate to Vendor'), findsOneWidget);
      expect(find.text('Confirm Drop-off'), findsOneWidget);
    });

    testWidgets('TEST 6: Profile -> Logout Partner Portal -> Rider Login Screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      RiderAuthService.instance.login(mobileNumber: '9999999999');
      expect(RiderAuthService.instance.isLoggedIn, isTrue);

      await tester.pumpWidget(
        const MaterialApp(home: RiderProfileScreen()),
      );
      await tester.pumpAndSettle();

      // Tap Logout Partner Portal
      await tester.tap(find.text('Logout Partner Portal'));
      await tester.pumpAndSettle();

      // Should land on PortalSelectionScreen (Welcome Page)
      expect(RiderAuthService.instance.isLoggedIn, isFalse);
      expect(find.text('Welcome to Yes Dhobi'), findsOneWidget);
      expect(find.text('Delivery Rider'), findsOneWidget);
    });
  });
}
