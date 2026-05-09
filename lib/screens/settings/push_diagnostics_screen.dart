import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme.dart';
import '../../services/push_service.dart';

/// Debug screen so non-developers can see exactly where push
/// notifications are failing without us tailing logs.
class PushDiagnosticsScreen extends StatefulWidget {
  const PushDiagnosticsScreen({super.key});

  @override
  State<PushDiagnosticsScreen> createState() => _PushDiagnosticsScreenState();
}

class _PushDiagnosticsScreenState extends State<PushDiagnosticsScreen> {
  bool _refreshing = false;

  Future<void> _forceRegister() async {
    setState(() => _refreshing = true);
    await PushService.instance.registerToken();
    if (!mounted) return;
    setState(() => _refreshing = false);
    final ok = PushService.instance.currentToken != null;
    final err = PushService.instance.lastError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(ok
            ? 'Token geregistreerd ✓'
            : (err != null && err.length < 80
                ? 'Geen token: $err'
                : 'Geen token — scroll omhoog voor status')),
        backgroundColor: ok ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = PushService.instance;
    final fcm = svc.currentToken;
    final apns = svc.apnsToken;
    final err = svc.lastError;

    return Scaffold(
      appBar: AppBar(title: const Text('Push diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Status(
            label: 'Firebase initialized',
            ok: svc.isFirebaseUp,
          ),
          _Status(
            label: 'APNs token (Apple)',
            ok: apns != null && apns.isNotEmpty,
            detail: apns == null ? null : '${apns.substring(0, apns.length.clamp(0, 24))}…',
          ),
          _Status(
            label: 'FCM token (Firebase)',
            ok: fcm != null && fcm.isNotEmpty,
            detail: fcm == null ? null : '${fcm.substring(0, fcm.length.clamp(0, 24))}…',
          ),
          if (svc.lastAuthStatus != null)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 4),
              child: Text(
                'iOS authorization: ${svc.lastAuthStatus}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          if (err != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.warning_amber, color: Colors.red[700], size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Last error',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  SelectableText(
                    err,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _refreshing ? null : _forceRegister,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Force re-register'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          if (fcm != null) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy FCM token'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: fcm));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token gekopieerd')),
                  );
                }
              },
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Verwacht: alle drie ✓ → de server kan pushes naar dit '
            'apparaat sturen. Eén of meer ✗ → tap "Force re-register" '
            'en wacht ~5 seconden. Helpt dat niet, controleer of de app '
            'nog notificatie-permissie heeft via Instellingen → CasaMio → '
            'Notificaties.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final String label;
  final bool ok;
  final String? detail;

  const _Status({required this.label, required this.ok, this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.green : Colors.red,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
