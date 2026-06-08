class AppConfig {
  int id;
  String? name;
  String? surname;
  String? givenName;
  String? dob;
  String? email;
  String? mobile;
  String? fatherName;
  String? motherName;
  String? presentAddress;
  String? permanentAddress;
  String? passportNumber;
  String? passportExpiry;
  String? workPermitNumber;
  String? workPermitExpiry;
  String? verificationType;
  String? fullAddress;
  String? nationality;
  String? gender;
  String? locale;
  String? theme;
  String? token;
  String? refreshToken;
  int? userId;
  int? kycStatus;
  String? driverId;
  String? tempMobile;
  String? tempPassword;
  String? userCountryCode;

  AppConfig({
    required this.id,
    this.locale,
    this.name,
    this.surname,
    this.givenName,
    this.email,
    this.mobile,
    this.passportNumber,
    this.passportExpiry,
    this.workPermitNumber,
    this.workPermitExpiry,
    this.verificationType,
    this.fullAddress,
    this.dob,
    this.fatherName,
    this.motherName,
    this.presentAddress,
    this.permanentAddress,
    this.nationality,
    this.gender,
    this.theme,
    this.token,
    this.refreshToken,
    this.userId,
    this.kycStatus,
    this.driverId,
    this.tempMobile,
    this.tempPassword,
    this.userCountryCode,
  });

  /// Create an AppConfig object from a Map
  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      id: map['id'],
      name: map['name'],
      surname: map['surname'],
      givenName: map['given_name'],
      email: map['email'],
      mobile: map['mobile'],
      passportNumber: map['passport_number'],
      passportExpiry: map['passport_expiry'],
      workPermitNumber: map['work_permit_no'],
      workPermitExpiry: map['work_permit_expiry'],
      verificationType: map['verification_type'],
      dob: map['dob'],
      fatherName: map['father_name'],
      motherName: map['mother_name'],
      presentAddress: map['present_address'],
      permanentAddress: map['permanent_address'],
      fullAddress: map['full_address'],
      nationality: map['nationality'],
      gender: map['gender'],
      locale: map['locale'],
      theme: map['theme'],
      token: map['token'],
      refreshToken: map['refreshToken'],
      userId: map['userId'],
      kycStatus: map['kyc_verified'],
      driverId: map['driverId'],
      tempMobile: map['tempMobile'],
      tempPassword: map['tempPassword'],
      userCountryCode: map['userCountryCode'],
    );
  }

  /// Convert an AppConfig object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dob': dob,
      'name': name,
      'surname': surname,
      'given_name': givenName,
      'email': email,
      'mobile': mobile,
      'father_name': fatherName,
      'mother_name': motherName,
      'passport_number': passportNumber,
      'passport_expiry': passportExpiry,
      'work_permit_no': workPermitNumber,
      'work_permit_expiry': workPermitExpiry,
      'verification_type': verificationType,
      'present_address': presentAddress,
      'permanent_address': permanentAddress,
      'full_address': fullAddress,
      'locale': locale,
      'theme': theme,
      'token': token,
      'refreshToken': refreshToken,
      'userId': userId,
      'kyc_verified': kycStatus,
      'driverId': driverId,
      'tempMobile': tempMobile,
      'tempPassword': tempPassword,
      'userCountryCode': userCountryCode,
    };
  }
}
