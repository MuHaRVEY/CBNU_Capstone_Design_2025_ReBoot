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

  @override
  Widget build(BuildContext context) {
    if (_showAd && _ad != null) {
      return Scaffold(
        body: Stack(
          children: [
            // 뒷배경 어둡게
            Opacity(
              opacity: 0.6,
              child: widget.child,
            ),
            Center(
              child: GestureDetector(
                onTap: () async {
                  if (await canLaunchUrl(Uri.parse(_ad!.link))) {
                    launchUrl(Uri.parse(_ad!.link));
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _ad!.imageUrl,
                      fit: BoxFit.contain,
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

