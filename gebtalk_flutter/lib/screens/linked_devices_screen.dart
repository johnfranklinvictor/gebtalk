import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';

/// WhatsApp Linked Devices screen for managing web/desktop sessions
class LinkedDevicesScreen extends StatefulWidget {
  const LinkedDevicesScreen({super.key});

  @override
  State<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends State<LinkedDevicesScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    final devices = await ApiService.getLinkedDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Linked Devices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Banner graphic
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.laptop_chromebook_rounded, color: AppColors.primary, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Use GebTalk on Web & Desktop',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Send and receive messages without keeping your phone online.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black),
                            label: const Text('Link a Device', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                            ),
                            onPressed: () => _simulateDeviceLink(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Device status header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DEVICE STATUS',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_devices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text('No active linked devices', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                      ),
                    )
                  else
                    ..._devices.map((dev) => _buildDeviceTile(dev)),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceTile(Map<String, dynamic> dev) {
    final did = dev['id'] ?? '';
    final name = dev['device_name'] ?? 'GebTalk Web';
    final type = dev['device_type'] ?? 'web';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Icon(
          type == 'desktop' ? Icons.desktop_windows_rounded : Icons.language_rounded,
          color: AppColors.primary,
          size: 26,
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        subtitle: const Text('Active now', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
          onPressed: () => _confirmUnlink(did, name),
          tooltip: 'Log out device',
        ),
      ),
    );
  }

  void _simulateDeviceLink(BuildContext context) async {
    await ApiService.linkDevice('Chrome (Windows)', deviceType: 'web');
    _fetchDevices();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device linked successfully!'), backgroundColor: AppColors.primaryDark),
      );
    }
  }

  void _confirmUnlink(String did, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Log out from $name?', style: const TextStyle(color: Colors.white)),
        content: const Text('You will be logged out of GebTalk on this device.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.unlinkDevice(did);
              _fetchDevices();
            },
            child: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
