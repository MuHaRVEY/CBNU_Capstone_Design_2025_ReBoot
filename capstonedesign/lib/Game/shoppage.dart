import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'coin_provider.dart';

class ShopPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final coinProvider = Provider.of<CoinProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 상점 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/shopBackground.png',
              fit: BoxFit.cover,
            ),
          ),

          // 상단 코인/포인트 표시
          Positioned(
            top: 40,
            right: 20,
            left: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _chip(
                  icon: Icons.monetization_on,
                  label: '${coinProvider.coins}',
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                _chip(
                  icon: Icons.directions_walk,
                  label: '${coinProvider.ploggingPoints}', // ★ 플로깅 포인트
                  color: Colors.green,
                ),
              ],
            ),
          ),

          // 아이템/교환 목록
          Positioned(
            bottom: 230,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // ★ 교환 카드 (500 코인 -> 5 포인트)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildExchangeCard(context),
                  ],
                ),
                const SizedBox(height: 16),
                // 일반 아이템들
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShopItem(context, '강아지 목도리', '₩300', 300, Icons.checkroom),
                    _buildShopItem(context, '강아지 모자', '₩500', 500, Icons.shopping_bag),
                    _buildShopItem(context, '간식 패키지', '₩200', 200, Icons.fastfood),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ★ 교환 카드
  Widget _buildExchangeCard(BuildContext context) {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);

    return GestureDetector(
      onTap: () async {
        // 확인 다이얼로그
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('교환'),
            content: const Text('500 코인을 사용해 플로깅 포인트 5개로 교환할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('교환'),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        final ok = await coinProvider.exchangeCoinsForPloggingPoints(
          coinCost: 500,
          points: 5,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '교환 완료! (포인트 +5)' : '코인이 부족합니다.'),
          ),
        );
      },
      child: Container(
        width: 220,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black87, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.swap_horiz, size: 36),
            SizedBox(height: 8),
            Text(
              '500 코인 → 플로깅 포인트 5',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              '탭하여 교환',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem(
      BuildContext context,
      String name,
      String displayPrice,
      int actualPrice,
      IconData icon,
      ) {
    final coinProvider = Provider.of<CoinProvider>(context);
    final isOwned = coinProvider.hasItem(name);

    return GestureDetector(
      onTap: () async {
        if (isOwned) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name은 이미 구매한 아이템입니다.')),
          );
          return;
        }

        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('구매'),
            content: Text('$name을(를) $displayPrice에 구매하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('구매'),
              ),
            ],
          ),
        );

        if (result == true) {
          final success = await coinProvider.purchaseItem(name, actualPrice);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? '$name 구매 완료!' : '코인이 부족합니다.'),
            ),
          );
        }
      },
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black87, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text(
              isOwned ? '구매 완료' : displayPrice,
              style: TextStyle(
                fontSize: 12,
                color: isOwned ? Colors.green : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
