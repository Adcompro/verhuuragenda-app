import 'guest.dart';
import 'accommodation.dart';

class Booking {
  final int id;
  final String? bookingNumber;
  final Guest? guest;
  final Accommodation? accommodation;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int? children;
  final int? babies;
  final String status;
  final String source;
  final double totalAmount;
  final double? depositAmount;
  final double? cleaningFee;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final String? internalNotes;
  final String? portalUrl;
  final String? portalPin;
  final List<Payment> payments;
  final DateTime? createdAt;

  Booking({
    required this.id,
    this.bookingNumber,
    this.guest,
    this.accommodation,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    this.children,
    this.babies,
    required this.status,
    required this.source,
    required this.totalAmount,
    this.depositAmount,
    this.cleaningFee,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    this.internalNotes,
    this.portalUrl,
    this.portalPin,
    this.payments = const [],
    this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Parse guest safely
    Guest? guest;
    try {
      if (json['guest'] != null && json['guest'] is Map<String, dynamic>) {
        guest = Guest.fromJson(json['guest']);
      }
    } catch (e) {
      guest = null;
    }

    // Parse accommodation safely
    Accommodation? accommodation;
    try {
      if (json['accommodation'] != null && json['accommodation'] is Map<String, dynamic>) {
        accommodation = Accommodation.fromJson(json['accommodation']);
      }
    } catch (e) {
      accommodation = null;
    }

    // Parse payments safely
    List<Payment> payments = [];
    try {
      if (json['payments'] != null && json['payments'] is List) {
        payments = (json['payments'] as List)
            .map((p) => Payment.fromJson(p))
            .toList();
      }
    } catch (e) {
      payments = [];
    }

    return Booking(
      id: json['id'] ?? 0,
      bookingNumber: json['booking_number'],
      guest: guest,
      accommodation: accommodation,
      checkIn: DateTime.parse(json['check_in']),
      checkOut: DateTime.parse(json['check_out']),
      adults: json['adults'] ?? 1,
      children: json['children'],
      babies: json['babies'],
      status: json['status'] ?? 'inquiry',
      source: json['source'] ?? 'direct',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      depositAmount: json['deposit_amount']?.toDouble(),
      cleaningFee: json['cleaning_fee']?.toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'unpaid',
      internalNotes: json['internal_notes'],
      portalUrl: json['portal_url'],
      portalPin: json['portal_pin'],
      payments: payments,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  int get nights => checkOut.difference(checkIn).inDays;

  bool get isPaid => paymentStatus == 'paid';
  bool get isPartialPaid => paymentStatus == 'partial';
  bool get isUnpaid => paymentStatus == 'unpaid';

  bool get isConfirmed => status == 'confirmed';
  bool get isOption => status == 'option';
  bool get isInquiry => status == 'inquiry';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Bevestigd';
      case 'option':
        return 'Optie';
      case 'inquiry':
        return 'Aanvraag';
      case 'cancelled':
        return 'Geannuleerd';
      case 'completed':
        return 'Afgerond';
      default:
        return status;
    }
  }

  String get sourceLabel {
    switch (source) {
      case 'direct':
        return 'Direct';
      case 'airbnb':
        return 'Airbnb';
      case 'booking':
        return 'Booking.com';
      case 'vrbo':
        return 'VRBO';
      default:
        return source;
    }
  }
}

class Payment {
  final int id;
  final double amount;
  final String? method;
  final DateTime? paidAt;

  Payment({
    required this.id,
    required this.amount,
    this.method,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      amount: (json['amount'] ?? 0).toDouble(),
      method: json['method'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }

  String get methodLabel {
    switch (method) {
      case 'bank':
        return 'Bank';
      case 'cash':
        return 'Contant';
      case 'ideal':
        return 'iDEAL';
      case 'creditcard':
        return 'Creditcard';
      default:
        return method ?? 'Onbekend';
    }
  }
}
