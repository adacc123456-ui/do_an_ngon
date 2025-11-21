import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Kiểm tra và yêu cầu quyền truy cập vị trí
  Future<bool> requestLocationPermission() async {
    // Kiểm tra xem dịch vụ vị trí có được bật không
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Kiểm tra quyền truy cập
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Lấy vị trí hiện tại
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Reverse geocoding: chuyển từ tọa độ sang địa chỉ
  Future<AddressInfo?> getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      final placemark = placemarks.first;
      return AddressInfo(
        street: placemark.street ?? '',
        ward: placemark.subLocality ?? placemark.locality ?? '',
        district: placemark.subAdministrativeArea ?? '',
        city: placemark.administrativeArea ?? '',
        country: placemark.country ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  /// Lấy địa chỉ từ vị trí hiện tại (tất cả trong một)
  Future<AddressInfo?> getCurrentAddress() async {
    final position = await getCurrentPosition();
    if (position == null) {
      return null;
    }
    return await getAddressFromPosition(position);
  }
}

class AddressInfo {
  final String street;
  final String ward;
  final String district;
  final String city;
  final String country;

  AddressInfo({
    required this.street,
    required this.ward,
    required this.district,
    required this.city,
    required this.country,
  });

  String get fullAddress {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (ward.isNotEmpty) parts.add(ward);
    if (district.isNotEmpty) parts.add(district);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(', ');
  }
}

