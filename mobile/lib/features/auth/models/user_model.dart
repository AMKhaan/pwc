class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final String userType;
  final String verificationStatus;
  final String? linkedinUrl;
  final String? companyEmail;
  final String? universityEmail;
  final double trustScore;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String genderPreference;
  final String? gender;
  final DateTime? verificationSubmittedAt;
  final String? rejectionReason;

  // Professional fields
  final String? officeName;
  final String? jobTitle;
  final String? cnicNumber;
  final String? cnicPhotoUrl;
  final String? officeLinkedinUrl;

  // Student fields
  final String? universityName;
  final String? staffType;
  final String? degreeDesignation;
  final String? idCardPhotoUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatarUrl,
    required this.userType,
    required this.verificationStatus,
    this.linkedinUrl,
    this.companyEmail,
    this.universityEmail,
    required this.trustScore,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.genderPreference,
    this.gender,
    this.verificationSubmittedAt,
    this.rejectionReason,
    this.officeName,
    this.jobTitle,
    this.cnicNumber,
    this.cnicPhotoUrl,
    this.officeLinkedinUrl,
    this.universityName,
    this.staffType,
    this.degreeDesignation,
    this.idCardPhotoUrl,
  });

  String get fullName => '$firstName $lastName';

  bool get isVerified => verificationStatus == 'VERIFIED';
  bool get isRejected => verificationStatus == 'REJECTED';
  bool get isProfessional => userType == 'PROFESSIONAL';
  bool get isStudent => userType == 'STUDENT';
  bool get hasCompanyEmail => companyEmail != null;
  bool get hasUniversityEmail => universityEmail != null;
  bool get hasSubmittedProfile => verificationSubmittedAt != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      userType: json['userType'] as String,
      verificationStatus: json['verificationStatus'] as String,
      linkedinUrl: json['linkedinUrl'] as String?,
      companyEmail: json['companyEmail'] as String?,
      universityEmail: json['universityEmail'] as String?,
      trustScore: json['trustScore'] == null ? 0.0 : double.parse(json['trustScore'].toString()),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      genderPreference: json['genderPreference'] as String? ?? 'ANY',
      gender: json['gender'] as String?,
      verificationSubmittedAt: json['verificationSubmittedAt'] != null
          ? DateTime.tryParse(json['verificationSubmittedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      officeName: json['officeName'] as String?,
      jobTitle: json['jobTitle'] as String?,
      cnicNumber: json['cnicNumber'] as String?,
      cnicPhotoUrl: json['cnicPhotoUrl'] as String?,
      officeLinkedinUrl: json['officeLinkedinUrl'] as String?,
      universityName: json['universityName'] as String?,
      staffType: json['staffType'] as String?,
      degreeDesignation: json['degreeDesignation'] as String?,
      idCardPhotoUrl: json['idCardPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'userType': userType,
        'verificationStatus': verificationStatus,
        'linkedinUrl': linkedinUrl,
        'companyEmail': companyEmail,
        'universityEmail': universityEmail,
        'trustScore': trustScore,
        'isEmailVerified': isEmailVerified,
        'genderPreference': genderPreference,
        'gender': gender,
        'verificationSubmittedAt': verificationSubmittedAt?.toIso8601String(),
      };
}
