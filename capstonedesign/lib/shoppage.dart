import 'package:flutter/material.dart';

class ShopPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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

          // 3개 아이템을 Row로 배치 (중앙 위쪽에 위치)
          Positioned(
            bottom: 230, // 위치를 위로 조금 올림
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShopItem(context, '강아지 목도리', '₩300', Icons.checkroom),
                _buildShopItem(context, '강아지 모자', '₩500', Icons.shopping_bag),
                _buildShopItem(context, '간식 패키지', '₩200', Icons.fastfood),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 각 상점 아이템 UI
  Widget _buildShopItem(BuildContext context, String name, String price, IconData icon) {
    return GestureDetector(
      onTap: () {
        // 구매 다이얼로그
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('구매'),
            content: Text('$name을(를) 구매하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name 구매 완료!')),
                  );
                },
                child: Text('구매'),
              ),
            ],
          ),
        );
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
            Text(name, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(price, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
