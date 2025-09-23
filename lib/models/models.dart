class MobileUnit {
  final int id;
  final String name;
  final String phone;

  MobileUnit({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory MobileUnit.fromMap(Map<String, dynamic> map) {
    return MobileUnit(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }
}

class Site {
  final String id;
  final String name;
  final String address;
  final int mobileUnitId;
  final String status;
  final String motive;
  final String serviceSchedule;

  Site({
    required this.id,
    required this.name,
    required this.address,
    required this.mobileUnitId,
    required this.status,
    required this.motive,
    required this.serviceSchedule,
  });

  factory Site.fromMap(Map<String, dynamic> map) {
    return Site(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      mobileUnitId: map['mobile_unit_id'] as int,
      status: map['status'] as String,
      motive: map['motive'] as String,
      serviceSchedule: map['service_schedule'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'mobile_unit_id': mobileUnitId,
      'status': status,
      'motive': motive,
      'service_schedule': serviceSchedule,
    };
  }
}

class Well {
  final String id;
  final String name;
  final String address;
  final int mobileUnitId;
  final String status;
  final String serviceSchedule;

  Well({
    required this.id,
    required this.name,
    required this.address,
    required this.mobileUnitId,
    required this.status,
    required this.serviceSchedule,
  });

  factory Well.fromMap(Map<String, dynamic> map) {
    return Well(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      mobileUnitId: map['mobile_unit_id'] as int,
      status: map['status'] as String,
      serviceSchedule: map['service_schedule'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'mobile_unit_id': mobileUnitId,
      'status': status,
      'service_schedule': serviceSchedule,
    };
  }
}