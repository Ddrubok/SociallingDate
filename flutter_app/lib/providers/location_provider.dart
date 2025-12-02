import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  Position? _currentPosition; // 현재 내 위치 저장소
  StreamSubscription<Position>? _positionSubscription;

  Position? get currentPosition => _currentPosition;

  // 위치 추적 시작 (앱 켜질 때 호출)
  void startTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen((
      position,
    ) {
      _currentPosition = position;
      notifyListeners(); // 위치 바뀌었다고 앱에 알림
    });
  }

  // 위치 추적 중지
  void stopTracking() {
    _positionSubscription?.cancel();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
