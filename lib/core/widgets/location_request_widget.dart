import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

/// Widget لطلب الموقع الجغرافي أثناء التسجيل
class LocationRequestWidget extends StatefulWidget {
  final VoidCallback? onLocationSaved;
  final bool isRequired;
  final String title;
  final String subtitle;

  const LocationRequestWidget({
    Key? key,
    this.onLocationSaved,
    this.isRequired = true,
    this.title = 'تحديد موقعك',
    this.subtitle = 'نحتاج إلى موقعك لعرض التبرعات القريبة منك',
  }) : super(key: key);

  @override
  State<LocationRequestWidget> createState() => _LocationRequestWidgetState();
}

class _LocationRequestWidgetState extends State<LocationRequestWidget> {
  bool _isLoading = false;
  bool _locationSaved = false;
  Position? _currentPosition;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان والأيقونة
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: _locationSaved ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // حالة الموقع
            if (_locationSaved) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✅ تم حفظ موقعك بنجاح',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_currentPosition != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'خط العرض: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'خط الطول: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // أزرار العمل
            Row(
              children: [
                if (!_locationSaved) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _requestLocation,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_isLoading ? 'جاري التحديد...' : 'تحديد موقعي'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _requestLocation,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_isLoading ? 'جاري التحديث...' : 'تحديث الموقع'),
                    ),
                  ),
                ],
                
                if (!widget.isRequired) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      if (widget.onLocationSaved != null) {
                        widget.onLocationSaved!();
                      }
                    },
                    child: const Text('تخطي'),
                  ),
                ],
              ],
            ),

            // معلومات إضافية
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لماذا نحتاج موقعك؟',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• عرض التبرعات القريبة منك\n'
                          '• تحسين تجربة التطبيق\n'
                          '• تسهيل عملية التوصيل',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// طلب الموقع وحفظه
  Future<void> _requestLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // الحصول على الموقع الحالي
      Position? position = await LocationService.getCurrentLocation(context);
      
      if (position != null) {
        // حفظ الموقع في قاعدة البيانات
        bool saved = await LocationService.saveUserLocation(
          position.latitude,
          position.longitude,
          context: context,
        );

        if (saved) {
          setState(() {
            _currentPosition = position;
            _locationSaved = true;
            _errorMessage = null;
          });

          // استدعاء callback عند النجاح
          if (widget.onLocationSaved != null) {
            widget.onLocationSaved!();
          }

          // فحص التكرار في البيانات
          await LocationService.checkForDuplicateLocations();
        } else {
          setState(() {
            _errorMessage = 'فشل في حفظ الموقع. يرجى المحاولة مرة أخرى.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Widget مبسط لطلب الموقع
class SimpleLocationButton extends StatefulWidget {
  final VoidCallback? onLocationSaved;
  final String buttonText;
  final IconData icon;

  const SimpleLocationButton({
    Key? key,
    this.onLocationSaved,
    this.buttonText = 'تحديد موقعي',
    this.icon = Icons.my_location,
  }) : super(key: key);

  @override
  State<SimpleLocationButton> createState() => _SimpleLocationButtonState();
}

class _SimpleLocationButtonState extends State<SimpleLocationButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _requestLocation,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon),
      label: Text(_isLoading ? 'جاري التحديد...' : widget.buttonText),
    );
  }

  Future<void> _requestLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await LocationService.getCurrentLocationAndSave(context);
      
      if (success && widget.onLocationSaved != null) {
        widget.onLocationSaved!();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Dialog لطلب الموقع
class LocationRequestDialog extends StatelessWidget {
  final VoidCallback? onLocationSaved;
  final bool isRequired;

  const LocationRequestDialog({
    Key? key,
    this.onLocationSaved,
    this.isRequired = true,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onLocationSaved,
    bool isRequired = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isRequired,
      builder: (context) => LocationRequestDialog(
        onLocationSaved: onLocationSaved,
        isRequired: isRequired,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.location_on, color: Colors.orange),
          SizedBox(width: 12),
          Text('تحديد الموقع'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نحتاج إلى موقعك لتحسين تجربة استخدام التطبيق وعرض التبرعات القريبة منك.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'موقعك آمن ولن يتم مشاركته مع أطراف خارجية',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!isRequired)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('تخطي'),
          ),
        ElevatedButton(
          onPressed: () async {
            bool success = await LocationService.getCurrentLocationAndSave(context);
            if (success) {
              if (onLocationSaved != null) {
                onLocationSaved!();
              }
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('تحديد موقعي'),
        ),
      ],
    );
  }
}