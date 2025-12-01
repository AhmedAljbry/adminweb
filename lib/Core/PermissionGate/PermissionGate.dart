import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// واجهة تحدد الصلاحيات المطلوبة.
class AppPermissionsConfig {
  final bool askNotifications;
  final bool askLocation;
  final bool askLegacyStorage;

  const AppPermissionsConfig({
    this.askNotifications = true,
    this.askLocation = true,
    this.askLegacyStorage = false,
  });
}

class PermissionGate extends StatefulWidget {
  final Widget child;
  final AppPermissionsConfig config;

  const PermissionGate({
    super.key,
    required this.child,
    this.config = const AppPermissionsConfig(),
  });

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _checking = true;
  String? _errorMessage;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _checkAndRequest();
  }

  Future<void> _checkAndRequest() async {
    setState(() {
      _checking = true;
      _errorMessage = null;
    });

    try {
      final List<Permission> needed = [];

      // 🔹 صلاحيات الموقع
      if (widget.config.askLocation) {
        // نفس الاستدعاء لأندرويد و iOS عبر plugin
        needed.add(Permission.locationWhenInUse);
        // لو تحتاج background location فعلياً:
        // needed.add(Permission.locationAlways);
      }

      // 🔹 صلاحيات الإشعارات
      if (widget.config.askNotifications && _isAndroid) {
        needed.add(Permission.notification);
      }

      // 🔹 صلاحيات التخزين للأجهزة القديمة
      if (widget.config.askLegacyStorage && _isAndroid) {
        needed.add(Permission.storage);
      }

      // لو ما في أي صلاحيات مطلوبة → إكمل مباشرة
      if (needed.isEmpty) {
        setState(() {
          _checking = false;
          _errorMessage = null;
        });
        return;
      }

      // اطلب كل الصلاحيات
      final Map<Permission, PermissionStatus> result = await needed.request();

      // افحص النتائج
      final denied = result.entries.where(
            (e) =>
        e.value.isDenied ||
            e.value.isPermanentlyDenied ||
            e.value.isRestricted,
      );

      if (denied.isNotEmpty) {
        setState(() {
          _checking = false;
          _errorMessage =
          'بعض الصلاحيات مرفوضة. يرجى السماح بها من أجل عمل التطبيق بشكل صحيح.';
        });
        return;
      }

      setState(() {
        _checking = false;
        _errorMessage = null;
      });
    } catch (e, st) {
      debugPrint('PermissionGate error: $e\n$st');
      setState(() {
        _checking = false;
        _errorMessage = 'حدث خطأ أثناء طلب الصلاحيات: $e';
      });
    }
  }

  Future<void> _openSettings() async {
    final opened = await openAppSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الإعدادات')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('جاري التحقق من الصلاحيات...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('السماح بالصلاحيات')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.lock_person_outlined, size: 72),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _checkAndRequest,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('فتح الإعدادات'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'يمكنك منح الأذونات من إعدادات التطبيق في جهازك.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ✅ كل شيء تمام → أعرض التطبيق الحقيقي
    return widget.child;
  }
}
