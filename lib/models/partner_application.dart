import 'package:cloud_firestore/cloud_firestore.dart';

enum PartnerApplicationType { restaurant, courier }

enum PartnerApplicationStatus { pending, approved, rejected }

class PartnerApplication {
  final String applicantUid;
  final PartnerApplicationType type;
  final PartnerApplicationStatus status;
  final String applicantName;
  final String email;
  final String phone;
  final String? restaurantName;
  final String? address;
  final GeoPoint? location;
  final DateTime? createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const PartnerApplication({
    required this.applicantUid,
    required this.type,
    required this.status,
    required this.applicantName,
    required this.email,
    required this.phone,
    this.restaurantName,
    this.address,
    this.location,
    this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  static PartnerApplication? fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    final type = PartnerApplicationType.values.asNameMap()[
      data['applicationType']
    ];
    final status = PartnerApplicationStatus.values.asNameMap()[data['status']];
    final applicantName = data['applicantName'];
    final email = data['email'];
    final phone = data['phone'];
    if (type == null ||
        status == null ||
        applicantName is! String ||
        email is! String ||
        phone is! String) {
      return null;
    }

    final location = data['location'];
    if (type == PartnerApplicationType.restaurant &&
        (data['restaurantName'] is! String ||
            data['address'] is! String ||
            location is! GeoPoint)) {
      return null;
    }

    return PartnerApplication(
      applicantUid: uid,
      type: type,
      status: status,
      applicantName: applicantName,
      email: email,
      phone: phone,
      restaurantName: data['restaurantName'] as String?,
      address: data['address'] as String?,
      location: location is GeoPoint ? location : null,
      createdAt: _dateOrNull(data['createdAt']),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: _dateOrNull(data['reviewedAt']),
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  static Map<String, dynamic> pendingData({
    required String uid,
    required PartnerApplicationType type,
    required String applicantName,
    required String email,
    required String phone,
    String? restaurantName,
    String? address,
    GeoPoint? location,
  }) {
    final data = <String, dynamic>{
      'applicantUid': uid,
      'applicationType': type.name,
      'status': PartnerApplicationStatus.pending.name,
      'applicantName': applicantName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (type == PartnerApplicationType.restaurant) {
      data.addAll({
        'restaurantName': restaurantName?.trim() ?? '',
        'address': address?.trim() ?? '',
        'location': location,
      });
    }
    return data;
  }

  static DateTime? _dateOrNull(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
