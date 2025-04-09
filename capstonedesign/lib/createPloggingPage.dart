import 'package:flutter/material.dart';
import 'showMapPage.dart';

class CreatePloggingPage extends StatefulWidget {
  const CreatePloggingPage({super.key});

  @override
  State<CreatePloggingPage> createState() => _CreatePloggingPageState();
}

class _CreatePloggingPageState extends State<CreatePloggingPage> {
  final distanceOptions = ['1km', '2km', '3km', '5km'];
  String selectedDistance = '3km';
  final destinationController = TextEditingController();
  final missionController = TextEditingController();

  void _onCreate() {
    final goal = selectedDistance;
    final destination = destinationController.text;
    final mission = missionController.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowMapPage(
          distance: goal,
          destination: destination,
          mission: mission,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          SizedBox.expand(
            child: Image.asset(
              'assets/images/background1.png',
              fit: BoxFit.cover,
            ),
          ),
          // 입력 카드들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
            child: Column(
              children: [
                _inputCard(
                  title: '목표 거리',
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedDistance,
                    icon: const Icon(Icons.arrow_drop_down),
                    underline: const SizedBox(),
                    items: distanceOptions
                        .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d, style: const TextStyle(fontSize: 18)),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedDistance = value!),
                  ),
                ),
                const SizedBox(height: 16),
                _inputCard(
                  title: '목표 지점',
                  child: TextField(
                    controller: destinationController,
                    decoration: const InputDecoration(border: InputBorder.none),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                _inputCard(
                  title: '무언가 할거',
                  child: TextField(
                    controller: missionController,
                    decoration: const InputDecoration(border: InputBorder.none),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _onCreate,
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '생성하기',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            '$title : ',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
