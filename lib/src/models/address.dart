import 'package:location/location.dart';

import '../helpers/custom_trace.dart';

class Address {
  String id;
  String description;
  String address;
  String street;
  String city;
  String phone;
  double latitude;
  double longitude;
  bool isDefault;
  String userId;

  Address();

  Address.fromJSON(Map<String, dynamic> jsonMap) {
    try {
      id = jsonMap['id'].toString();
      description = jsonMap['description'] != null ? jsonMap['description'].toString() : null;
      address = jsonMap['region'] != null ? jsonMap['region'] : null;
      street = jsonMap['street'] != null ? jsonMap['street'] : null;
      city = jsonMap['city'] != null ? jsonMap['city'] : null;
      phone = jsonMap['telephone'] != null ? jsonMap['telephone'] : null;
      latitude = jsonMap['latitude'] != null
          ? jsonMap['latitude'] is String
              ? double.parse(jsonMap['latitude'])
              : jsonMap['latitude']
          : 0.0;
      longitude = jsonMap['longitude'] != null
          ? jsonMap['longitude'] is String
              ? double.parse(jsonMap['longitude'])
              : jsonMap['longitude']
          : 0.0;
      isDefault = jsonMap['is_default'] ?? false;
    } catch (e) {
      print(CustomTrace(StackTrace.current, message: e));
    }
  }

  bool isUnknown() {
    return latitude == null || longitude == null;
  }

  Map toMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["description"] = description;
    map["street"] = street;
    map["city"] = city;
    map["phone"] = phone;
    map["address"] = address;
    map["latitude"] = latitude;
    map["longitude"] = longitude;
    map["is_default"] = isDefault;
    map["user_id"] = userId;
    return map;
  }

  LocationData toLocationData() {
    return LocationData.fromMap({
      "latitude": latitude,
      "longitude": longitude,
    });
  }
}
