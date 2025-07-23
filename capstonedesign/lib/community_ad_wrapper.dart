import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ad_block_util.dart';
import 'ad_model.dart';

class CommunityAdWrapper extends StatefulWidget {
  final Widget child;
  const CommunityAdWrapper({super.key, required this.child});

  @override
  State<CommunityAdWrapper> createState() => _CommunityAdWrapperState();
}

class _CommunityAdWrapperState extends State<CommunityAdWrapper> {
  bool _showAd = false;
  bool _dontShowToday = false;
  AdModel? _ad;

  @override
  void initState() {
    super.initState();
    _checkAdBlockAndLoad();
  }

  Future<void> _checkAdBlockAndLoad() async {
    final blocked = await isAdBlocked();
    if (!blocked) {
      final ad = await _fetchRandomAd();
      if (ad != null) {
        setState(() {
          _ad = ad;
          _showAd = true;
        });
      }
    }
  }

  Future<AdModel?> _fetchRandomAd() async {
    final ref = FirebaseDatabase.instance.ref('ads');
    final snapshot = await ref.get();

    if (!snapshot.exists) return null;

    final ads = <AdModel>[];
    final now = DateTime.now();

    for (final child in snapshot.children) {
      final adMap = child.value as Map<dynamic, dynamic>;
      final ad = AdModel.fromMap(adMap);
      if (ad.expiresAt.isAfter(now)) {
        ads.add(ad);
      }
    }

    if (ads.isEmpty) return null;

    return ads[Random().nextInt(ads.length)];
  }

  Future<void> _dismissAd() async {
    if (_dontShowToday) {
      await blockAdForToday();
    }
    setState(() {
      _showAd = false;
    });
  }

  Future<void> _launchAdLink(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback: 내부 WebView로 열기
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } catch (e) {
      debugPrint("❗ 링크 열기 실패: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showAd && _ad != null) {
      return Scaffold(
        body: Stack(
          children: [
            Opacity(
              opacity: 0.6,
              child: widget.child,
            ),
            Center(
              child: GestureDetector(
                onTap: () => _launchAdLink(_ad!.link),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(blurRadius: 10, color: Colors.black26),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _ad!.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _dismissAd,
              ),
            ),
            Positioned(
              bottom: 50,
              left: 20,
              child: Row(
                children: [
                  Checkbox(
                    value: _dontShowToday,
                    onChanged: (val) =>
                        setState(() => _dontShowToday = val ?? false),
                  ),
                  const Text('오늘 하루 보지 않기'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }
}
