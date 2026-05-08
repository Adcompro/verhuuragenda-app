import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/theme.dart';
import '../../core/api/api_client.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  String _type = 'bug';
  bool _busy = false;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    } catch (_) {/* ignore */}
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.post(
        '/feedback',
        data: {
          'type': _type,
          'subject': _subjectController.text.trim(),
          'body': _bodyController.text.trim(),
          'app_version': _appVersion,
          'platform': Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
          'os_version': Platform.operatingSystemVersion,
        },
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.check_circle, color: Colors.green[600], size: 48),
          title: const Text('Verzonden'),
          content: const Text(
              'Bedankt! We hebben je bericht ontvangen en kijken er zo snel mogelijk naar.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Sluiten'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString() ??
              'Versturen mislukt'
          : 'Versturen mislukt';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback / Bug')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Wat wil je doorgeven?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'bug',
                    label: Text('Bug'),
                    icon: Icon(Icons.bug_report_outlined),
                  ),
                  ButtonSegment(
                    value: 'feature',
                    label: Text('Idee'),
                    icon: Icon(Icons.lightbulb_outline),
                  ),
                  ButtonSegment(
                    value: 'question',
                    label: Text('Vraag'),
                    icon: Icon(Icons.help_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _subjectController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Onderwerp',
                  hintText: _hintForType,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Vul een korte titel in'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 8,
                minLines: 5,
                maxLength: 5000,
                decoration: InputDecoration(
                  labelText: 'Beschrijving',
                  hintText: _bodyHintForType(_type),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Geef wat meer detail mee'
                    : null,
              ),
              const SizedBox(height: 8),
              if (_appVersion != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'App-versie ${_appVersion} · ${Platform.isIOS ? "iOS" : "Android"} wordt automatisch meegestuurd om je sneller te helpen.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: const Text('Versturen'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _hintForType = 'Bv. "Kalender opent niet"';

  String _bodyHintForType(String t) {
    switch (t) {
      case 'feature':
        return 'Beschrijf je idee. Wat wil je kunnen doen, en waarom helpt dat je?';
      case 'question':
        return 'Stel je vraag. Hoe specifieker, hoe beter we kunnen helpen.';
      default:
        return 'Wat ging er mis? Welke stappen heb je gevolgd? Wat had je verwacht?';
    }
  }
}
