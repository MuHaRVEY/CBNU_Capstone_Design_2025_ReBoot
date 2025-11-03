import 'package:flutter/material.dart';

class StaticMapWidget extends StatelessWidget {
  final String encoded;

  const StaticMapWidget({Key? key, required this.encoded}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildRoutePreview(encoded);
  }

  Widget _buildRoutePreview(String encoded) {
    print("🗺 지도 미리보기 생성 중...");
    // 1. 자체 도메인 설정 (Node.js 서버와 일치시킬 것)
    const String myProxyAuthority = "staticmap.inno505.duckdns.org";

    // 2. Node.js 서버에서 설정한 엔드포인트
    const String myProxyEndpoint = "/getStaticMap";

    // 3. 지도 이미지 URL 생성에 필요한 매개변수 설정
    final Map<String, String> mapParameters = {
      'size': '600x300',
      'path': 'color:0x0000ff|weight:5|enc:$encoded',
      // (선택 사항) 시작점과 끝점에 마커 추가
      // 'markers': 'color:green|label:S|enc:$encoded', 
    };

    // 4. Uri 클래스를 사용해 최종 URL 생성
    // (https://maps.내도메인.com/getStaticMap?size=...&path=...)
    final Uri secureUri = Uri.https(
      myProxyAuthority,
      myProxyEndpoint,
      mapParameters,
    );
    
    final String staticMapUrl = secureUri.toString();
    print("🌍 정적 지도 URL: $staticMapUrl");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(staticMapUrl,
          height: 300,
          width: 600, // HTML size와 달라도 Flutter가 fit 조절
          fit: BoxFit.cover,
          // 로딩 중에 보여줄 위젯
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child; // 로딩 완료
              return Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            
            // 에러 발생 시 보여줄 위젯
            errorBuilder: (context, error, stackTrace) {
              print("🚨 정적 지도 이미지 로드 오류: $error");
              return Container(
                height: 300,
                color: Colors.grey[300],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: Colors.red, size: 40),
                    SizedBox(height: 8),
                    Text(
                      "지도 프리뷰를 불러올 수 없습니다.\n(서버 연결 확인)",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}