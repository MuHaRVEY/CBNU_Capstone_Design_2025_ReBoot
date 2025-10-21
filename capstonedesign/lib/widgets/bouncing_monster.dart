import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 화면 가장자리에서 반사되며 떠다니는 몬스터 오버레이
class BouncingMonsterOverlay extends StatefulWidget {
  final String asset;                 // 이미지 경로
  final double spriteSize;            // 이미지 크기(px)
  final EdgeInsets bouncePadding;     // 충돌 영역에서 제외할 패딩(예: 상단 정보패널 높이만큼 top)
  final VoidCallback? onTap;          // 탭 시 콜백

  const BouncingMonsterOverlay({
    super.key,
    required this.asset,
    this.spriteSize = 96,
    this.bouncePadding = EdgeInsets.zero,
    this.onTap,
  });

  @override
  State<BouncingMonsterOverlay> createState() => _BouncingMonsterOverlayState();
}

class _BouncingMonsterOverlayState extends State<BouncingMonsterOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  // 위치(px)
  double _x = 0;
  double _y = 0;

  // 속도(px/sec)
  late double _vx;
  late double _vy;

  // 경계(화면 크기)
  double _w = 0;
  double _h = 0;

  Duration _last = Duration.zero;
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    // 초기 속도 랜덤(너무 느리지 않게)
    _vx = (_rand.nextBool() ? 1 : -1) * (_rand.nextDouble() * 80 + 80); // 80~160 px/s
    _vy = (_rand.nextBool() ? 1 : -1) * (_rand.nextDouble() * 80 + 80);

    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration now) {
    if (!mounted) return;
    if (_last == Duration.zero) {
      _last = now;
      return;
    }
    final dt = (now - _last).inMilliseconds / 1000.0; // sec
    _last = now;

    if (_w == 0 || _h == 0) return; // 아직 레이아웃 안 나왔으면 대기

    // 유효한 이동 가능 영역(패딩 제외)
    final left = widget.bouncePadding.left;
    final top = widget.bouncePadding.top;
    final right = _w - widget.bouncePadding.right - widget.spriteSize;
    final bottom = _h - widget.bouncePadding.bottom - widget.spriteSize;

    // 처음 진입 시, 화면 중앙 근처로 배치
    if (_x == 0 && _y == 0) {
      _x = (left + right) / 2;
      _y = (top + bottom) / 2;
    }

    // 위치 업데이트
    var nx = _x + _vx * dt;
    var ny = _y + _vy * dt;

    // 좌우 충돌 체크
    if (nx < left) {
      nx = left + (left - nx);
      _vx = -_vx;
    } else if (nx > right) {
      nx = right - (nx - right);
      _vx = -_vx;
    }

    // 상하 충돌 체크
    if (ny < top) {
      ny = top + (top - ny);
      _vy = -_vy;
    } else if (ny > bottom) {
      ny = bottom - (ny - bottom);
      _vy = -_vy;
    }

    setState(() {
      _x = nx;
      _y = ny;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 파악
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      if (size.width != _w || size.height != _h) {
        setState(() {
          _w = size.width;
          _h = size.height;
        });
      }
    });

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Image.asset(
          widget.asset,
          width: widget.spriteSize,
          height: widget.spriteSize,
        ),
      ),
    );
  }
}
