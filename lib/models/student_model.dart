class Student {
  final String id;
  final String franchiseId;
  final String name;
  final String status;
  final DateTime? dob;
  final String? gender;
  //final String? bloodGroup;
  final String? aadharNumber;
  final String? motherTongue;

  final String? religion;
  final String? nationality;
  final String? category;

  // Parent Info
  final String? fatherName;
  final String? motherName;
  // final String? fatherOccupation;
  // final String? motherOccupation;

  // final String? guardianName;
  // final String? guardianContact;
  // final String? guardianRelation;

  // Contact Info
  final String? phoneNumber;
  final String? phoneNumber2;
  final String? email;
  //final String? whatsappNo;

  // Address
  final String? address;
  //final String? postOffice;
  final String? pincode;
  //final String? policeStation;
  final String? district;

  // Academic Info
  final String admissionYearId;
  final String? admissionCode;
  final DateTime? refNoDate;
  final String classId;
  final String rollNumber;
  //final String? sectionId;
  //final String rollNumber;

  final DateTime createdAt;

  final String? photoUrl;


  Student({
    required this.id,
    required this.franchiseId,
    required this.name,
    required this.status,
    this.dob,
    this.gender,
    this.religion,
    this.nationality,
    this.category,
    this.aadharNumber,
    this.motherTongue,
    this.fatherName,
    this.motherName,
    this.phoneNumber,
    this.phoneNumber2,
    this.email,
    this.address,
    this.pincode,
    this.district,
    required this.admissionYearId,
    this.admissionCode,
    this.refNoDate,
    required this.classId,
    required this.rollNumber,
    required this.createdAt,
    this.photoUrl,
  });

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'franchise_id': franchiseId,
      'name': name,
      'status': status,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'religion': religion,
      'nationality': nationality,
      'category': category,
      'aadhar_number': aadharNumber,
      'mother_tongue': motherTongue,
      'father_name': fatherName,
      'mother_name': motherName,
      'phone_number': phoneNumber,
      'phone_number_2': phoneNumber2,
      'email': email,
      'address': address,
      'pincode': pincode,
      'district': district,
      'admission_year_id': admissionYearId,
      'admission_code': admissionCode,
      'ref_no_date': refNoDate?.toIso8601String(),
      'class_id': classId,
      'roll_number': rollNumber,
      'created_at': createdAt.toIso8601String(),
      'photo_url': photoUrl,
    };
  }

  // Create from Supabase data
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      franchiseId: map['franchise_id'] ?? '',
      name: map['name'] ?? '',
      status: map['status'] ?? '',
      dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
      gender: map['gender'],
      religion: map['religion'],
      nationality: map['nationality'],
      category: map['category'],
      aadharNumber: map['aadhar_number'],
      motherTongue: map['mother_tongue'],
      fatherName: map['father_name'],
      motherName: map['mother_name'],
      phoneNumber: map['phone_number'],
      phoneNumber2: map['phone_number_2'],
      email: map['email'],
      address: map['address'],
      pincode: map['pincode'],
      district: map['district'],
      admissionYearId: map['admission_year_id'] ?? '',
      admissionCode: map['admission_code'],
      refNoDate: map['ref_no_date'] != null ? DateTime.parse(map['ref_no_date']) : null,
      classId: map['class_id'] ?? '',
      rollNumber: map['roll_number'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      photoUrl: map['photo_url'],
    );
  }

  // Copy with method for editing
  Student copyWith({
    String? id,
    String? franchiseId,
    String? name,
    String? status,
    DateTime? dob,
    String? gender,
    String? religion,
    String? nationality,
    String? category,
    String? aadharNumber,
    String? motherTongue,
    String? fatherName,
    String? motherName,
    String? phoneNumber,
    String? phoneNumber2,
    String? email,
    String? address,
    String? pincode,
    String? district,
    String? admissionYearId,
    String? admissionCode,
    DateTime? refNoDate,
    String? classId,
    String? rollNumber,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return Student(
      id: id ?? this.id,
      franchiseId: franchiseId ?? this.franchiseId,
      name: name ?? this.name,
      status: status ?? this.status,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      religion: religion ?? this.religion,
      nationality: nationality ?? this.nationality,
      category: category ?? this.category,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      motherTongue: motherTongue ?? this.motherTongue,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneNumber2: phoneNumber2 ?? this.phoneNumber2,
      email: email ?? this.email,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      district: district ?? this.district,
      admissionYearId: admissionYearId ?? this.admissionYearId,
      admissionCode: admissionCode ?? this.admissionCode,
      refNoDate: refNoDate ?? this.refNoDate,
      classId: classId ?? this.classId,
      rollNumber: rollNumber ?? this.rollNumber,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}