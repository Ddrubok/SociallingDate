import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  // 1. 현재 위치 가져오기
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스 켜져 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // 위치 서비스 꺼짐
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // 권한 거부됨
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // 영구 거부됨
    }

    // 현재 위치 반환
    return await Geolocator.getCurrentPosition();
  }

  // 2. 거리 계산 (미터 단위)
  double getDistanceInMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1000,
      ),
    );
  }

  // 3. 외부 지도 앱 열기 (구글 지도)
  Future<void> openMap(double lat, double lng) async {
    // 구글 지도 URL 스키마
    final googleUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      throw '지도를 열 수 없습니다.';
    }
  }
}
