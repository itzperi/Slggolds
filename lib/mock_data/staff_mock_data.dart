// lib/mock_data/staff_mock_data.dart

import 'package:intl/intl.dart';

class StaffMockData {
  // Mock staff credentials
  static final Map<String, String> staffCredentials = {
    'SLG001': 'staff123',
    'SLG002': 'staff123',
  };

  // Mock staff info
  static final Map<String, dynamic> staffInfo = {
    'SLG001': {
      'name': 'Rajesh Kumar',
      'phone': '+91 9988776655',
      'email': 'rajesh@slggolds.com',
      'role': 'Collection Agent',
      'joinDate': '2024-01-01',
      'assignedCustomers': 42,
    },
    'SLG002': {
      'name': 'Priya Sharma',
      'phone': '+91 9876543210',
      'email': 'priya@slggolds.com',
      'role': 'Collection Agent',
      'joinDate': '2024-02-15',
      'assignedCustomers': 38,
    },
  };

  // ASSIGNED customers for staff (42 total) - ALL amounts are double, ALL String fields have values
  static List<Map<String, dynamic>> assignedCustomers = [
    {
      'id': 'C001',
      'name': 'Ravi Kumar',
      'phone': '+91 9876543210',
      'customerId': 'C12345',
      'address': '123 Main Street, Bangalore, Karnataka 560001',
      'scheme': 'Gold Scheme 3',
      'schemeNumber': 3,
      'frequency': 'Daily',
      'minAmount': 550.0,
      'maxAmount': 1000.0,
      'dueAmount': 750.0,
      'totalPayments': 245,
      'missedPayments': 2,
      'paidToday': false,
    },
    {
      'id': 'C002',
      'name': 'Priya Sharma',
      'phone': '+91 9123456789',
      'customerId': 'C67890',
      'address': '456 Park Avenue, Mumbai, Maharashtra 400001',
      'scheme': 'Silver Scheme 1',
      'schemeNumber': 1,
      'frequency': 'Weekly',
      'minAmount': 50.0,
      'maxAmount': 200.0,
      'dueAmount': 120.0,
      'totalPayments': 35,
      'missedPayments': 0,
      'paidToday': false,
    },
    {
      'id': 'C003',
      'name': 'Arjun Patel',
      'phone': '+91 9988776655',
      'customerId': 'C11111',
      'address': '789 MG Road, Delhi, Delhi 110001',
      'scheme': 'Gold Scheme 5',
      'schemeNumber': 5,
      'frequency': 'Daily',
      'minAmount': 1550.0,
      'maxAmount': 2000.0,
      'dueAmount': 1750.0,
      'totalPayments': 180,
      'missedPayments': 3,
      'paidToday': false,
    },
    {
      'id': 'C004',
      'name': 'Sneha Reddy',
      'phone': '+91 9345678901',
      'customerId': 'C22222',
      'address': '321 Church Street, Chennai, Tamil Nadu 600001',
      'scheme': 'Silver Scheme 5',
      'schemeNumber': 5,
      'frequency': 'Monthly',
      'minAmount': 30000.0,
      'maxAmount': 40000.0,
      'dueAmount': 35000.0,
      'totalPayments': 8,
      'missedPayments': 1,
      'paidToday': false,
    },
    {
      'id': 'C005',
      'name': 'Vikram Singh',
      'phone': '+91 9456789012',
      'customerId': 'C33333',
      'address': '654 Commercial Street, Hyderabad, Telangana 500001',
      'scheme': 'Gold Scheme 5',
      'schemeNumber': 5,
      'frequency': 'Daily',
      'minAmount': 1550.0,
      'maxAmount': 2000.0,
      'dueAmount': 1775.0,
      'totalPayments': 300,
      'missedPayments': 0,
      'paidToday': false,
    },
    {
      'id': 'C006',
      'name': 'Anita Desai',
      'phone': '+91 9567890123',
      'customerId': 'C44444',
      'address': '222 Brigade Road, Ahmedabad, Gujarat 380001',
      'scheme': 'Silver Scheme 3',
      'schemeNumber': 3,
      'frequency': 'Weekly',
      'minAmount': 5000.0,
      'maxAmount': 6000.0,
      'dueAmount': 5500.0,
      'totalPayments': 42,
      'missedPayments': 2,
      'paidToday': false,
    },
    {
      'id': 'C007',
      'name': 'Rohit Mehta',
      'phone': '+91 9678901234',
      'customerId': 'C55555',
      'address': '333 Residency Road, Jaipur, Rajasthan 302001',
      'scheme': 'Gold Scheme 7',
      'schemeNumber': 7,
      'frequency': 'Daily',
      'minAmount': 2500.0,
      'maxAmount': 3000.0,
      'dueAmount': 2750.0,
      'totalPayments': 200,
      'missedPayments': 3,
      'paidToday': false,
    },
    {
      'id': 'C008',
      'name': 'Kavita Nair',
      'phone': '+91 9789012345',
      'customerId': 'C66666',
      'address': '444 MG Road, Lucknow, Uttar Pradesh 226001',
      'scheme': 'Silver Scheme 2',
      'schemeNumber': 2,
      'frequency': 'Daily',
      'minAmount': 300.0,
      'maxAmount': 450.0,
      'dueAmount': 375.0,
      'totalPayments': 150,
      'missedPayments': 1,
      'paidToday': false,
    },
    {
      'id': 'C009',
      'name': 'Manoj Joshi',
      'phone': '+91 9890123456',
      'customerId': 'C77777',
      'address': '555 Connaught Place, Chandigarh, Punjab 160001',
      'scheme': 'Gold Scheme 9',
      'schemeNumber': 9,
      'frequency': 'Monthly',
      'minAmount': 150000.0,
      'maxAmount': 180000.0,
      'dueAmount': 165000.0,
      'totalPayments': 10,
      'missedPayments': 0,
      'paidToday': false,
    },
    {
      'id': 'C010',
      'name': 'Deepa Iyer',
      'phone': '+91 9901234567',
      'customerId': 'C88888',
      'address': '666 Park Street, Indore, Madhya Pradesh 452001',
      'scheme': 'Silver Scheme 8',
      'schemeNumber': 8,
      'frequency': 'Weekly',
      'minAmount': 20000.0,
      'maxAmount': 25000.0,
      'dueAmount': 22500.0,
      'totalPayments': 48,
      'missedPayments': 0,
      'paidToday': false,
    },
    {
      'id': 'C011',
      'name': 'Suresh Kumar',
      'phone': '+91 9012345678',
      'customerId': 'C99999',
      'address': '987 Gandhi Nagar, Pune, Maharashtra 411001',
      'scheme': 'Gold Scheme 2',
      'schemeNumber': 2,
      'frequency': 'Daily',
      'minAmount': 300.0,
      'maxAmount': 450.0,
      'dueAmount': 375.0,
      'totalPayments': 320,
      'missedPayments': 0,
      'paidToday': false,
    },
    {
      'id': 'C012',
      'name': 'Lakshmi Menon',
      'phone': '+91 9123456780',
      'customerId': 'C00000',
      'address': '111 Nehru Road, Kolkata, West Bengal 700001',
      'scheme': 'Silver Scheme 4',
      'schemeNumber': 4,
      'frequency': 'Daily',
      'minAmount': 1200.0,
      'maxAmount': 1350.0,
      'dueAmount': 1275.0,
      'totalPayments': 280,
      'missedPayments': 2,
      'paidToday': false,
    },
    // Add 30 more customers to reach 42 total
    ...List.generate(30, (index) {
      final customerNum = index + 13;
      return {
        'id': 'C${customerNum.toString().padLeft(3, '0')}',
        'name': 'Customer $customerNum',
        'phone': '+91 ${9000000000 + customerNum}',
        'customerId': 'C${(10000 + customerNum).toString()}',
        'address': '${customerNum * 10} Street, City ${customerNum}, State ${customerNum % 5 + 1} ${(100000 + customerNum).toString()}',
        'scheme': customerNum % 2 == 0 ? 'Gold Scheme ${(customerNum % 9) + 1}' : 'Silver Scheme ${(customerNum % 9) + 1}',
        'schemeNumber': (customerNum % 9) + 1,
        'frequency': ['Daily', 'Weekly', 'Monthly'][customerNum % 3],
        'minAmount': (100.0 * (customerNum % 10 + 1)),
        'maxAmount': (200.0 * (customerNum % 10 + 1)),
        'dueAmount': (150.0 * (customerNum % 10 + 1)),
        'totalPayments': 50 + (customerNum * 5),
        'missedPayments': customerNum % 5 == 0 ? 1 : 0,
        'paidToday': customerNum % 7 == 0, // Some customers already paid today
      };
    }),
  ];

  // Keep customers for backward compatibility
  static List<Map<String, dynamic>> get customers => assignedCustomers;

  // Daily target for staff
  static final double dailyTargetAmount = 45000.0; // ₹45,000
  static final int dailyTargetCustomers = 42; // All assigned customers

  // Payment history - ALL amounts are double
  static Map<String, List<Map<String, dynamic>>> paymentHistory = {
    'C001': [
      {'date': '2024-12-05', 'amount': 750.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-12-04', 'amount': 750.0, 'status': 'paid', 'method': 'upi'},
      {'date': '2024-12-03', 'amount': 800.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-12-02', 'amount': 0.0, 'status': 'missed', 'method': 'none'},
      {'date': '2024-12-01', 'amount': 0.0, 'status': 'missed', 'method': 'none'},
      {'date': '2024-11-30', 'amount': 1000.0, 'status': 'paid', 'method': 'upi'},
      {'date': '2024-11-29', 'amount': 550.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-11-28', 'amount': 750.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-11-27', 'amount': 900.0, 'status': 'paid', 'method': 'gpay'},
      {'date': '2024-11-26', 'amount': 750.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-11-25', 'amount': 600.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-11-24', 'amount': 750.0, 'status': 'paid', 'method': 'gpay'},
      {'date': '2024-11-23', 'amount': 850.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-11-22', 'amount': 750.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-11-21', 'amount': 950.0, 'status': 'paid', 'method': 'gpay'},
    ],
    'C002': [
      {'date': '2024-12-04', 'amount': 120.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-11-27', 'amount': 150.0, 'status': 'paid', 'method': 'gpay'},
      {'date': '2024-11-20', 'amount': 100.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-11-13', 'amount': 200.0, 'status': 'paid', 'method': 'gpay'},
      {'date': '2024-11-06', 'amount': 120.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-10-30', 'amount': 150.0, 'status': 'paid', 'method': 'gpay'},
      {'date': '2024-10-23', 'amount': 180.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-10-16', 'amount': 120.0, 'status': 'paid', 'method': 'cash'},
      {'date': '2024-10-09', 'amount': 200.0, 'status': 'paid', 'method': 'gpay'},
      {'date': '2024-10-02', 'amount': 150.0, 'status': 'paid', 'method': 'cash'},
    ],
  };

  // Today's collections - ALL amounts are double
  static List<Map<String, dynamic>> todayCollections = [
    {'customerId': 'C001', 'customerName': 'Ravi Kumar', 'scheme': 'Gold Scheme 3', 'amount': 750.0, 'method': 'cash', 'time': '2:30 PM'},
    {'customerId': 'C002', 'customerName': 'Priya Sharma', 'scheme': 'Silver Scheme 1', 'amount': 120.0, 'method': 'upi', 'time': '11:00 AM'},
  ];

  // Reports data - ALL amounts are double
  static final Map<String, dynamic> todayReport = {
    'total': 45000.0,
    'customersVisited': 38,
    'totalCustomers': 42,
    'paymentsMade': 38,
    'pending': 4,
  };

  static final Map<String, dynamic> weekReport = {
    'total': 210000.0,
    'customersVisited': 210,
    'totalCustomers': 252,
    'missed': 42,
  };

  // Pending customers - ALL amounts are double
  static final List<Map<String, dynamic>> pendingCustomers = [
    {'name': 'Priya Sharma', 'amount': 120.0, 'dueDate': 'Today', 'customerId': 'C002'},
    {'name': 'Arjun Patel', 'amount': 1550.0, 'dueDate': 'Yesterday', 'customerId': 'C003'},
    {'name': 'Sneha Reddy', 'amount': 35000.0, 'dueDate': 'Today', 'customerId': 'C004'},
    {'name': 'Anita Desai', 'amount': 5500.0, 'dueDate': 'Today', 'customerId': 'C006'},
  ];

  // Record payment (can handle multiple payments at once)
  static void recordPayment({
    required String customerId,
    required double amount,
    required String method, // 'cash' or 'upi'
    required String date,
  }) {
    final customer = assignedCustomers.firstWhere((c) => c['id'] == customerId);
    final minAmount = customer['minAmount'] as double;
    final maxAmount = customer['maxAmount'] as double;

    // Calculate how many payments this amount covers
    int paymentsCount = 1;
    double amountPerPayment = amount;

    if (amount > maxAmount) {
      // Paying multiple missed payments
      paymentsCount = (amount / minAmount).floor();
      amountPerPayment = amount / paymentsCount;
    }

    // Create payment records
    for (int i = 0; i < paymentsCount; i++) {
      final payment = {
        'date': date,
        'amount': amountPerPayment,
        'status': 'paid',
        'method': method,
      };

      if (paymentHistory[customerId] == null) {
        paymentHistory[customerId] = [];
      }
      paymentHistory[customerId]!.insert(0, payment);
    }

    // Update customer data
    customer['totalPayments'] = (customer['totalPayments'] as int) + paymentsCount;
    customer['paidToday'] = true;

    // Reduce missed payments if any
    final missedCount = customer['missedPayments'] as int;
    if (missedCount > 0) {
      customer['missedPayments'] = (missedCount - paymentsCount).clamp(0, missedCount);
    }

    // Add to today's collections
    todayCollections.insert(0, {
      'customerId': customerId,
      'customerName': customer['name'] as String,
      'scheme': customer['scheme'] as String,
      'amount': amount,
      'method': method,
      'time': _getCurrentTime(),
    });
  }

  // Get statistics
  static int getCollectedCount() {
    return assignedCustomers.where((c) => c['paidToday'] == true).length;
  }

  static double getCollectedAmount() {
    return todayCollections.fold(0.0, (sum, p) => sum + (p['amount'] as double));
  }

  static int getPendingCount() {
    return assignedCustomers.where((c) => c['paidToday'] == false).length;
  }

  static double getTargetProgress() {
    final collected = getCollectedAmount();
    return collected / dailyTargetAmount;
  }

  static List<Map<String, dynamic>> getDueToday() {
    return assignedCustomers
        .where((c) => c['paidToday'] == false && (c['missedPayments'] as int) == 0)
        .toList();
  }

  static List<Map<String, dynamic>> getPending() {
    return assignedCustomers.where((c) => c['paidToday'] == false).toList();
  }

  // Get current time in 12-hour format
  static String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${now.minute.toString().padLeft(2, '0')} $period';
  }

  // Get today's total collections
  static double getTodayTotal() {
    return todayCollections.fold(0.0, (sum, p) => sum + (p['amount'] as double));
  }

  // Get payment history for a customer
  static List<Map<String, dynamic>> getPaymentHistory(String customerId) {
    return paymentHistory[customerId] ?? [];
  }

  // Today's statistics
  static Map<String, dynamic> getTodayStats() {
    final cashAmount = todayCollections
        .where((c) => c['method'] == 'cash')
        .fold(0.0, (sum, c) => sum + (c['amount'] as double));

    final upiAmount = todayCollections
        .where((c) => c['method'] == 'upi')
        .fold(0.0, (sum, c) => sum + (c['amount'] as double));

    final missedPaymentsCount = assignedCustomers
        .where((c) => (c['missedPayments'] as int) > 0)
        .length;

    return {
      'totalAmount': getCollectedAmount(),
      'customersCollected': getCollectedCount(),
      'totalCustomers': assignedCustomers.length,
      'completionPercent': assignedCustomers.isNotEmpty
          ? (getCollectedCount() / assignedCustomers.length) * 100
          : 0.0,
      'pendingCount': getPendingCount(),
      'missedPaymentsCount': missedPaymentsCount,
      'cashAmount': cashAmount,
      'upiAmount': upiAmount,
    };
  }

  // Week statistics (mock data for now)
  static Map<String, dynamic> getWeekStats() {
    return {
      'totalAmount': 185000.0,
      'customersServed': 168,
      'avgPerCustomer': 1101.0,
      'bestDay': 'Dec 12',
      'bestDayAmount': 42000.0,
    };
  }

  // Priority customers (with missed payments, sorted by count)
  static List<Map<String, dynamic>> getPriorityCustomers() {
    final priority = assignedCustomers
        .where((c) => (c['missedPayments'] as int) > 0)
        .toList();

    priority.sort((a, b) =>
        (b['missedPayments'] as int).compareTo(a['missedPayments'] as int));

    return priority;
}

  // Collection breakdown by scheme type
  static Map<String, double> getSchemeBreakdown() {
    double goldTotal = 0.0;
    double silverTotal = 0.0;

    for (var collection in todayCollections) {
      final customer = assignedCustomers.firstWhere(
        (c) => c['id'] == collection['customerId'],
        orElse: () => <String, dynamic>{},
      );

      if (customer.isEmpty) continue;

      final scheme = customer['scheme'] as String;
      final amount = collection['amount'] as double;

      if (scheme.contains('Gold')) {
        goldTotal += amount;
      } else if (scheme.contains('Silver')) {
        silverTotal += amount;
      }
    }

    return {'Gold': goldTotal, 'Silver': silverTotal};
  }

  // Calculate total due for customer (including missed)
  static double calculateTotalDue(Map<String, dynamic> customer) {
    final missedCount = customer['missedPayments'] as int;
    final dueAmount = customer['dueAmount'] as double;
    final minAmount = customer['minAmount'] as double;

    return (missedCount * minAmount) + dueAmount;
  }
}
