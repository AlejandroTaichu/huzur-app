import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class KibleBulEkrani extends StatefulWidget {
  const KibleBulEkrani({super.key});

  @override
  State<KibleBulEkrani> createState() => _KibleBulEkraniState();
}

class _KibleBulEkraniState extends State<KibleBulEkrani> {
  bool _hasPermissions = false;
  double? _heading; // Cihazın baktığı yön (pusula)
  double? _qiblaDirection; // Kıble yönü

  // Kabe'nin koordinatları
  final double _kaabaLatitude = 21.4225;
  final double _kaabaLongitude = 39.8262;

  @override
  void initState() {
    super.initState();
    _fetchPermissionStatus();
  }

  // 1. Konum iznini kontrol et ve iste
  // 1. Konum iznini kontrol et ve iste (GELİŞMİŞ VERSİYON)
  void _fetchPermissionStatus() async {
    // Mevcut durumu kontrol et
    var status = await Permission.location.status;

    // Konsola mevcut durumu yazdırarak ne olduğunu anlayalım
    print("Mevcut izin durumu: $status");

    // Eğer izin verilmemişse, tekrar iste
    if (status.isDenied) {
      status = await Permission.location.request();
      print("İzin istendi, yeni durum: $status");
    }
    // Eğer izin "bir daha sorma" ile reddedilmişse, kullanıcıyı ayarlara yönlendir
    else if (status.isPermanentlyDenied) {
      print("İzin kalıcı olarak reddedilmiş, ayarlar açılıyor.");
      await openAppSettings();
    }

    // Son durumu state'e yansıt
    if (mounted) {
      setState(() {
        _hasPermissions = (status == PermissionStatus.granted);
      });
      if (_hasPermissions) {
        _startStreaming();
      }
    }
  }

  // 2. İzin varsa, konum ve pusula verilerini dinlemeye başla
  void _startStreaming() {
    // Pusula verisini dinle
    FlutterCompass.events!.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
        });
      }
    });

    // Konum verisini al ve kıbleyi hesapla
    Geolocator.getPositionStream().listen((Position position) {
      if (mounted) {
        _calculateQiblaDirection(position);
      }
    });
  }

  // 3. Kıble yönünü hesapla
  void _calculateQiblaDirection(Position position) {
    final userLatitude = position.latitude;
    final userLongitude = position.longitude;

    // Dereceleri radyana çevir
    final lat1 = _toRadians(userLatitude);
    final lon1 = _toRadians(userLongitude);
    final lat2 = _toRadians(_kaabaLatitude);
    final lon2 = _toRadians(_kaabaLongitude);

    // Formülü uygula
    final y = math.sin(lon2 - lon1) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1);

    // Sonucu radyan'dan dereceye çevir
    final bearing = _toDegrees(math.atan2(y, x));

    setState(() {
      _qiblaDirection = (bearing + 360) % 360;
    });
  }

  // Helper fonksiyonlar
  double _toRadians(double degree) => degree * (math.pi / 180);
  double _toDegrees(double radian) => radian * (180 / math.pi);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kıble Bul'),
      ),
      body: Builder(
        builder: (context) {
          if (!_hasPermissions) return _buildPermissionSheet();
          if (_heading == null || _qiblaDirection == null)
            return _buildLoadingIndicator();

          return _buildCompass();
        },
      ),
    );
  }

  // --- WIDGET'LAR ---

  Widget _buildCompass() {
    // Kıble okunun pusulaya göre açısını hesapla
    final angle = _toRadians((_qiblaDirection! - _heading!));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Pusuladaki yeşil ok Kıble yönünü göstermektedir.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 40),
        Stack(
          alignment: Alignment.center,
          children: [
            // Pusula arkaplanı
            Transform.rotate(
              angle: _toRadians(-_heading!),
              child: Image.asset(
                  'assets/images/compass.png'), // Bu asset'i ekleyeceğiz
            ),
            // Kıble oku
            Transform.rotate(
              angle: angle,
              child: const Icon(Icons.arrow_upward_rounded,
                  size: 80, color: Colors.green),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Konum bilgisi alınıyor..."),
        ],
      ),
    );
  }

  Widget _buildPermissionSheet() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu özelliği kullanmak için konum izni vermeniz gerekmektedir.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('İzin Ver'),
              onPressed: _fetchPermissionStatus,
            ),
          ],
        ),
      ),
    );
  }
}
