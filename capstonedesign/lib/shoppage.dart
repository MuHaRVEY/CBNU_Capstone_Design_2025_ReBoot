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

          // 상단 코인 표시 + 충전 버튼
          Positioned(
            top: 40,
            right: 20,
            left: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    coinProvider.addCoins(500); // 테스트용 충전
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('+500 코인 충전')),
                    );
                  },
                  child: Text('+500 코인'),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.amber),
                      SizedBox(width: 6),
                      Text(
                        '${coinProvider.coins}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 아이템 목록
          Positioned(
            bottom: 230,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShopItem(context, '강아지 목도리', '₩300', 300, Icons.checkroom),
                _buildShopItem(context, '강아지 모자', '₩500', 500, Icons.shopping_bag),
                _buildShopItem(context, '간식 패키지', '₩200', 200, Icons.fastfood),
              ],
            ),
          ),
        ],
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

        final result = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('구매'),
            content: Text('$name을(를) $displayPrice에 구매하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('구매'),
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
          boxShadow: [
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
            SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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


