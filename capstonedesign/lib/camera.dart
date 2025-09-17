// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: TrashCamClassifierPage()));
}

class TrashCamClassifierPage extends StatefulWidget {
  const TrashCamClassifierPage({Key? key}) : super(key: key);
  @override
  State<TrashCamClassifierPage> createState() => _TrashCamClassifierPageState();
}

class _TrashCamClassifierPageState extends State<TrashCamClassifierPage> {
  // -------- App state --------
  CameraController? _camera;
  Interpreter? _interpreter;
  late List<String> _labels;

  bool _isRunning = false;
  String _status = 'Initializing...';
  String _resultText = '—';
  double _resultProb = 0.0;

  // -------- Model I/O (from training script) --------
  static const int modelH = 192;
  static const int modelW = 192;
  // output already softmax probs -> no extra softmax

  // throttle: infer every N-th frame
  static const int inferEveryNFrames = 3;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    try {
      // 1) labels
      final raw = await rootBundle.loadString('assets/labels.json');
      _labels = (jsonDecode(raw) as List).map((e) => e.toString()).toList();

      _interpreter = await Interpreter.fromAsset('assets/trash_classifier_fp16.tflite');

      // 3) camera
      final cams = await availableCameras();
      if (cams.isEmpty) return _fail('No camera found.');
      final back = cams.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      _camera = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _camera!.initialize();
      await _camera!.startImageStream(_onLatestImageAvailable);

      if (!mounted) return;
      setState(() => _status = 'Ready');
    } catch (e) {
      _fail('Init error: $e');
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() => _status = msg);
  }

  Future<void> _onLatestImageAvailable(CameraImage image) async {
    _frameCount++;
    if (_isRunning || _interpreter == null || _frameCount % inferEveryNFrames != 0) return;
    _isRunning = true;

    try {
      // 1) 입력 텐서 모양 확인 (보통 [1,192,192,3])
      final inShape = _interpreter!.getInputTensor(0).shape;
      final H = inShape[1], W = inShape[2], C = inShape[3];
      if (C != 3) { setState(() => _status = 'Model expects $C channels'); return; }
      // 1) YUV420 → RGB
      final rgb = _yuv420ToImage(image);

    // 2) (중요) 크롭 없이 바로 192x192 리사이즈  ← 학습 파이프라인과 맞추기
      final resized = img.copyResize(rgb, width: modelW, height: modelH);

      // 3) [1,H,W,3] float32 입력(0~1) 만들기  ←★ 핵심: 4차원 리스트
      final input = [
        List.generate(H, (y) =>
            List.generate(W, (x) {
              final p = resized.getPixel(x, y);
              return [
                img.getRed(p)   / 255.0,
                img.getGreen(p) / 255.0,
                img.getBlue(p)  / 255.0,
              ];
            })
        )
      ];

      // 4) 출력 버퍼 [1, numClasses]
      final numClasses = _labels.length;
      final output = [ List.filled(numClasses, 0.0) ];

      // 5) 추론
      _interpreter!.run(input, output);

      // 6) 결과 (이미 softmax 확률)
      final probs = output.first.cast<double>();
// probs 얻은 뒤:
      List<int> idx = List.generate(probs.length, (i) => i);
      idx.sort((a,b) => probs[b].compareTo(probs[a]));
      final top = idx.take(3).toList();

      final best = top.first;
      final label = _labels[best];
      final p = probs[best];

      if (!mounted) return;
      setState(() {
        _resultText = label;
        _resultProb = p;
        // 상태바에 디버그 정보 노출
        _status = 'OK (in 1x${modelH}x${modelW}x3)'
            '\nTop1: #$best ${_labels[best]} ${((probs[best]*100)).toStringAsFixed(1)}%'
            '\nTop2: #${top.length>1?top[1]:"-"} ${top.length>1?_labels[top[1]]:""} ${top.length>1?((probs[top[1]]*100)).toStringAsFixed(1):""}%'
            '\nTop3: #${top.length>2?top[2]:"-"} ${top.length>2?_labels[top[2]]:""} ${top.length>2?((probs[top[2]]*100)).toStringAsFixed(1):""}%';
      });


      if (!mounted) return;
      setState(() {
        _resultText = label;
        _resultProb = p;
        _status = 'OK (in ${inShape.join("x")})';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Inference error: $e');
    } finally {
      _isRunning = false;
    }
  }

  // ---------- image helpers (image: ^3.3.0 API) ----------
  img.Image _yuv420ToImage(CameraImage image) {
    final w = image.width, h = image.height;
    final y = image.planes[0].bytes;
    final u = image.planes[1].bytes;
    final v = image.planes[2].bytes;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 2;

    final out = img.Image(w, h); // v3 positional ctor
    int yp = 0;
    for (int j = 0; j < h; j++) {
      final pUV = uvRowStride * (j >> 1);
      for (int i = 0; i < w; i++) {
        final uvIndex = pUV + (i >> 1) * uvPixelStride;
        final Y = y[yp] & 0xff, U = u[uvIndex] & 0xff, V = v[uvIndex] & 0xff;
        final r = (Y + 1.370705 * (V - 128)).round();
        final g = (Y - 0.337633 * (U - 128) - 0.698001 * (V - 128)).round();
        final b = (Y + 1.732446 * (U - 128)).round();
        out.setPixelRgba(i, j, _clip(r), _clip(g), _clip(b), 255);
        yp++;
      }
    }
    return out;
  }

  img.Image _centerCrop(img.Image src) {
    final w = src.width, h = src.height;
    if (w == h) return src;
    if (w > h) {
      final x0 = ((w - h) / 2).floor();
      return img.copyCrop(src, x0, 0, h, h);
    } else {
      final y0 = ((h - w) / 2).floor();
      return img.copyCrop(src, 0, y0, w, w);
    }
  }

  int _clip(int v) => v < 0 ? 0 : (v > 255 ? 255 : v);

  int _argmax(List<double> a) {
    int bi = -1;
    double bv = -1e18;
    for (int i = 0; i < a.length; i++) {
      if (a[i] > bv) {
        bv = a[i];
        bi = i;
      }
    }
    return bi;
  }

  @override
  void dispose() {
    _camera?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _camera?.value.isInitialized == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Trash Classifier')),
      body: ready
          ? Stack(children: [
        CameraPreview(_camera!),
        Positioned(
          left: 12,
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black45,
            child: Text(_status, style: const TextStyle(color: Colors.white)),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 24,
          child: _ResultCard(label: _resultText, prob: _resultProb),
        ),
      ])
          : Center(child: Text(_status)),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final double prob;
  const _ResultCard({required this.label, required this.prob, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = (prob * 100).clamp(0, 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          Text('$p %', style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }
}
