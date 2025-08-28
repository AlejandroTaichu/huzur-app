// lib/screens/kible_bul_ekran.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class KibleBulEkrani extends StatefulWidget {
  const KibleBulEkrani({super.key});

  @override
  State<KibleBulEkrani> createState() => _KibleBulEkraniState();
}

class _KibleBulEkraniState extends State<KibleBulEkrani>
    with TickerProviderStateMixin {
  bool _hasPermissions = false;
  double? _heading;
  double? _qiblaDirection;
  Position? _currentPosition;
  String? _errorMessage;
  bool _isLoading = false;

  // Stream subscriptions - dispose için gerekli
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _positionSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final double _kaabaLatitude = 21.4225;
  final double _kaabaLongitude = 39.8262;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _checkInitialPermissions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _compassSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  // Sadece mevcut izin durumunu kontrol et
  Future<void> _checkInitialPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              "Konum servisleri kapalı. Lütfen telefonun ayarlarından açın.";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        setState(() {
          _hasPermissions = true;
        });
        await _startStreaming();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "İzin kontrolü sırasında hata: ${e.toString()}";
      });
    }
  }

  // Konum izni isteme ve konum servislerini başlatma
  Future<void> _requestLocationAndStart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Önce eski stream'leri temizle
      await _compassSubscription?.cancel();
      await _positionSubscription?.cancel();
      _compassSubscription = null;
      _positionSubscription = null;

      // Konum servislerinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              "Konum servisleri kapalı. Lütfen telefonun ayarlarından konum servislerini açın.";
          _isLoading = false;
        });
        return;
      }

      // Geolocator ile konum izni kontrolü ve isteme
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = "Konum izni kalıcı olarak reddedildi.";
          _isLoading = false;
        });
        _showSettingsDialog();
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = "Konum izni verilmedi.";
          _isLoading = false;
        });
        return;
      }

      // İzin alındı, servisleri başlat
      setState(() {
        _hasPermissions = true;
        _isLoading = false;
      });

      await _startStreaming();
    } catch (e) {
      setState(() {
        _errorMessage = "Konum izni alınırken hata: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  // Ayarları açması için kullanıcıya diyalog gösteren yardımcı fonksiyon
  void _showSettingsDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("Konum İzni Gerekiyor"),
          content: const Text(
              "Kıble yönünü bulabilmek için uygulamanın konum iznine ihtiyacı var. Lütfen uygulama ayarlarından konum iznini etkinleştirin."),
          actions: <Widget>[
            TextButton(
              child: const Text("Vazgeç"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Ayarları Aç"),
              onPressed: () async {
                await Geolocator.openAppSettings();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _startStreaming() async {
    try {
      // Compass stream'ini başlat
      _compassSubscription = FlutterCompass.events?.listen(
        (CompassEvent event) {
          if (mounted && event.heading != null) {
            setState(() => _heading = event.heading);
          }
        },
        onError: (error) {
          print('Compass error: $error');
          if (mounted) {
            setState(() {
              _errorMessage =
                  "Pusula sensörü hatası: Cihazınız pusula desteklemiyor olabilir.";
            });
          }
        },
      );

      // İlk konum al - timeout ile
      Position initialPosition;
      try {
        initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15), // 15 saniye timeout
        );

        if (mounted) {
          setState(() => _currentPosition = initialPosition);
          _calculateQiblaDirection(initialPosition);
        }
      } catch (e) {
        print('Initial position error: $e');
        // İlk konum alınamazsa, stream'den almaya çalış
        if (mounted) {
          setState(() {
            _errorMessage = "Konum alınıyor, lütfen bekleyin...";
          });
        }
      }

      // Position stream'ini başlat - daha gevşek ayarlarla
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // 5 metreden fazla değişim olunca güncelle
          timeLimit: Duration(seconds: 30), // 30 saniye timeout
        ),
      ).listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _errorMessage =
                  null; // Başarılı konum alındığında hata mesajını temizle
            });
            _calculateQiblaDirection(position);
          }
        },
        onError: (error) {
          print('Position stream error: $error');
          if (mounted) {
            // Zaten bir konum varsa, hata gösterme
            if (_currentPosition == null) {
              setState(() {
                _errorMessage =
                    "Konum güncellemesi başarısız. Mevcut konum kullanılıyor.";
              });

              // 3 saniye sonra hata mesajını temizle
              Timer(const Duration(seconds: 3), () {
                if (mounted &&
                    _errorMessage?.contains("güncellemesi") == true) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              });
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Sensör başlatma hatası: ${e.toString()}";
        });
      }
    }
  }

  void _calculateQiblaDirection(Position position) {
    final userLatitude = position.latitude;
    final userLongitude = position.longitude;

    final lat1 = _toRadians(userLatitude);
    final lon1 = _toRadians(userLongitude);
    final lat2 = _toRadians(_kaabaLatitude);
    final lon2 = _toRadians(_kaabaLongitude);

    final y = math.sin(lon2 - lon1) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1);

    final bearing = _toDegrees(math.atan2(y, x));

    setState(() => _qiblaDirection = (bearing + 360) % 360);
  }

  double _toRadians(double degree) => degree * (math.pi / 180);
  double _toDegrees(double radian) => radian * (180 / math.pi);

  double _getDistance() {
    if (_currentPosition == null) return 0;
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _kaabaLatitude,
          _kaabaLongitude,
        ) /
        1000; // km cinsinden
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text(
          'Kıble Pusulası',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Builder(
        builder: (context) {
          if (_errorMessage != null) return _buildErrorWidget();
          if (!_hasPermissions) return _buildPermissionSheet();
          if (_heading == null || _qiblaDirection == null) {
            return _buildLoadingIndicator();
          }
          return _buildModernCompass();
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestLocationAndStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCompass() {
    final double compassRotation = _heading ?? 0;
    final double qiblaOffset = (_qiblaDirection != null && _heading != null)
        ? (_qiblaDirection! - _heading!)
        : 0;

    return Column(
      children: [
        // Üst bilgi kartı
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.purple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                'Kıble Açısı',
                '${_qiblaDirection?.round() ?? 0}°',
                Icons.explore,
              ),
              _buildInfoItem(
                'Mesafe',
                '${_getDistance().toStringAsFixed(0)} km',
                Icons.place,
              ),
              _buildInfoItem(
                'Doğruluk',
                '${_currentPosition?.accuracy.toStringAsFixed(0) ?? 0}m',
                Icons.gps_fixed,
              ),
            ],
          ),
        ),

        // Ana pusula
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dış çember (sabit)
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.transparent,
                        Colors.blue.withOpacity(0.3),
                      ],
                      stops: const [0.7, 0.8, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),

                // Yön işaretleri (dönen)
                AnimatedRotation(
                  turns: -compassRotation / 360,
                  duration: const Duration(milliseconds: 300),
                  child: _buildCompassRose(),
                ),

                // İç pusula çemberi
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.3),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),

                // Merkez noktası
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Kıble oku (animasyonlu)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return AnimatedRotation(
                      turns: qiblaOffset / 360,
                      duration: const Duration(milliseconds: 300),
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          child: CustomPaint(
                            painter: QiblaArrowPainter(),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Kuzey oku (kırmızı)
                Transform.rotate(
                  angle: 0, // Kuzey her zaman yukarı
                  child: Container(
                    width: 80,
                    height: 80,
                    child: CustomPaint(
                      painter: NorthArrowPainter(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Alt bilgi kartı
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.1),
                Colors.blue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.green.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Mevcut Konumunuz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_currentPosition != null) ...[
                _buildCoordinateRow(
                  'Enlem',
                  _currentPosition!.latitude.toStringAsFixed(6),
                ),
                const SizedBox(height: 6),
                _buildCoordinateRow(
                  'Boylam',
                  _currentPosition!.longitude.toStringAsFixed(6),
                ),
                const SizedBox(height: 6),
                _buildCoordinateRow(
                  'Yükseklik',
                  '${_currentPosition!.altitude.toStringAsFixed(0)}m',
                ),
              ] else
                const Text(
                  'Konum bekleniyor...',
                  style: TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade300, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinateRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildCompassRose() {
    return Container(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: CompassRosePainter(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade300),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? "Konum ve pusula bilgisi alınıyor...",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
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
            Icon(Icons.location_on, size: 64, color: Colors.blue.shade300),
            const SizedBox(height: 16),
            const Text(
              'Kıble yönünü belirleyebilmek için konumunuza erişim izni gerekiyor.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade300),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text('Konumu Kullan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _requestLocationAndStart,
              ),
          ],
        ),
      ),
    );
  }
}

// Kıble okunu çizen painter
class QiblaArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade400
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final center = Offset(size.width / 2, size.height / 2);
    final arrowPath = Path();

    // Ana ok şekli
    arrowPath.moveTo(center.dx, center.dy - 40);
    arrowPath.lineTo(center.dx - 12, center.dy - 10);
    arrowPath.lineTo(center.dx - 6, center.dy - 10);
    arrowPath.lineTo(center.dx - 6, center.dy + 30);
    arrowPath.lineTo(center.dx + 6, center.dy + 30);
    arrowPath.lineTo(center.dx + 6, center.dy - 10);
    arrowPath.lineTo(center.dx + 12, center.dy - 10);
    arrowPath.close();

    // Gölge çiz
    canvas.drawPath(arrowPath, shadowPaint);

    // Ana ok çiz
    canvas.drawPath(arrowPath, paint);

    // Ok başı parlaklığı
    final highlightPaint = Paint()
      ..color = Colors.green.shade200
      ..style = PaintingStyle.fill;

    final highlightPath = Path();
    highlightPath.moveTo(center.dx, center.dy - 40);
    highlightPath.lineTo(center.dx - 8, center.dy - 15);
    highlightPath.lineTo(center.dx + 8, center.dy - 15);
    highlightPath.close();

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Kuzey okunu çizen painter
class NorthArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.shade400
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final arrowPath = Path();

    // Kuzey oku (üçgen)
    arrowPath.moveTo(center.dx, center.dy - 25);
    arrowPath.lineTo(center.dx - 8, center.dy - 5);
    arrowPath.lineTo(center.dx + 8, center.dy - 5);
    arrowPath.close();

    canvas.drawPath(arrowPath, paint);

    // "N" harfi
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + 10,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Pusula çiçeğini çizen painter
class CompassRosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Ana yön çizgileri
    final mainLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Ara yön çizgileri
    final subLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 8 ana yön için çizgiler
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final startRadius = radius - 30;
      final endRadius = radius - 15;

      final startX = center.dx + startRadius * math.sin(angle);
      final startY = center.dy - startRadius * math.cos(angle);
      final endX = center.dx + endRadius * math.sin(angle);
      final endY = center.dy - endRadius * math.cos(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        mainLinePaint,
      );
    }

    // 16 ara yön için çizgiler
    for (int i = 0; i < 16; i++) {
      if (i % 2 == 1) {
        // Sadece ara açılar
        final angle = (i * 22.5) * math.pi / 180;
        final startRadius = radius - 25;
        final endRadius = radius - 15;

        final startX = center.dx + startRadius * math.sin(angle);
        final startY = center.dy - startRadius * math.cos(angle);
        final endX = center.dx + endRadius * math.sin(angle);
        final endY = center.dy - endRadius * math.cos(angle);

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          subLinePaint,
        );
      }
    }

    // Yön harfleri
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    for (int i = 0; i < directions.length; i++) {
      final angle = (i * 45) * math.pi / 180;
      final textRadius = radius - 45;

      final textX = center.dx + textRadius * math.sin(angle);
      final textY = center.dy - textRadius * math.cos(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: TextStyle(
            color: i == 0 ? Colors.red.shade300 : Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          textX - textPainter.width / 2,
          textY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
