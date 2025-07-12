import 'package:flutter/material.dart';
import '../data/models/share_model.dart';
import '../widgets/post_card.dart';
import '../widgets/post_card_data.dart';

class ShareDemoPage extends StatelessWidget {
  const ShareDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Card Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Sample share card
            PostCard(
              postData: SharePostAdapter(_createSampleShare(), showOwner: true),
              onPostUpdated: (updatedPost) {
                // Handle share updates
              },
            ),
            
            const SizedBox(height: 20),
            
            // Another sample with different data
            PostCard(
              postData: SharePostAdapter(_createSampleShare2(), showOwner: true),
              onPostUpdated: (updatedPost) {
                // Handle share updates
              },
            ),
          ],
        ),
      ),
    );
  }

  Share _createSampleShare() {
    return Share(
      id: 66,
      userId: 1,
      regionId: 1,
      sectorId: 84,
      quantity: "600,000,000",
      createdAt: "2024-09-30T18:43:58.000000Z",
      updatedAt: "2025-07-01T18:36:18.000000Z",
      ownerName: "اوبا",
      transactionType: "sell",
      price: "50 ل.س",
      views: 154,
      approve: 1,
      closed: 0,
      priceKey: 50,
      since: "منذ 9 أشهر",
      userSentOrder: false,
      shareButton: "##أسهم_تنظيمية_في_منطقة_ماروتا_ستي\nعرض بيع أسهم تنظيمية في منطقة ماروتا ستي\nالرقم المرجعي: 66 مقسم S176 سكني مختلط\nعدد الأسهم: 600,000,000 سهم\nالسعر : 50 ل.س للسهم الواحد\n\n📱 لمزيد من التفاصيل، يمكنك تحميل تطبيق #عقاري_دمشق من خلال الرابط:\nhttps://play.google.com/store/apps/details?id=akari.versetech.net",
      postType: "share",
      reactionCounts: const ReactionCounts(
        likeCount: 1,
        loveCount: 1,
        wowCount: 1,
        sadCount: 1,
        angryCount: 0,
        totalCount: 4,
      ),
      currentUserReaction: "sad",
      isFavorited: true,
      user: const User(
        id: 1,
        name: "محمد يزن",
        authenticated: 1,
      ),
      region: const Region(
        id: 1,
        name: "ماروتا ستي",
      ),
      sector: const Sector(
        id: 84,
        regionId: 1,
        code: SectorCode(
          name: "سكني مختلط",
          viewCode: "مقسم S176",
          code: "S176",
        ),
        codeId: "S176",
        codeType: "سكني مختلط",
        outerArea: "1434",
        residentialArea: "13110.33",
        commercialArea: "1333.25",
        buildingArea: "0",
        floorsNumber: "23",
        totalFloorArea: "14443.58",
        shareCount: "1361807857",
        description: "سكني مختلط ارضي واول تجاري و21 طابق سكني",
        active: true,
        createdAt: "2024-07-26T23:45:11.000000Z",
        updatedAt: "2025-06-11T19:28:08.000000Z",
        sectorName: SectorName(
          name: "سكني مختلط",
          code: "مقسم S176",
        ),
        cover: Cover(
          img: "https://arrows-dev.versetech.net/media/241/S176.jpg",
        ),
      ),
      media: const [],
    );
  }

  Share _createSampleShare2() {
    return Share(
      id: 67,
      userId: 2,
      regionId: 1,
      sectorId: 85,
      quantity: "300,000,000",
      createdAt: "2024-10-15T10:30:00.000000Z",
      updatedAt: "2025-07-01T18:36:18.000000Z",
      ownerName: "أحمد علي",
      transactionType: "buy",
      price: "75 ل.س",
      views: 89,
      approve: 0,
      closed: 1,
      priceKey: 75,
      since: "منذ 8 أشهر",
      userSentOrder: false,
      shareButton: "##أسهم_تنظيمية_في_منطقة_ماروتا_ستي\nعرض شراء أسهم تنظيمية في منطقة ماروتا ستي\nالرقم المرجعي: 67 مقسم S177 تجاري\nعدد الأسهم: 300,000,000 سهم\nالسعر : 75 ل.س للسهم الواحد",
      postType: "share",
      reactionCounts: const ReactionCounts(
        likeCount: 2,
        loveCount: 0,
        wowCount: 1,
        sadCount: 0,
        angryCount: 1,
        totalCount: 4,
      ),
      currentUserReaction: "like",
      isFavorited: false,
      user: const User(
        id: 2,
        name: "أحمد علي",
        authenticated: 0,
      ),
      region: const Region(
        id: 1,
        name: "ماروتا ستي",
      ),
      sector: const Sector(
        id: 85,
        regionId: 1,
        code: SectorCode(
          name: "تجاري",
          viewCode: "مقسم S177",
          code: "S177",
        ),
        codeId: "S177",
        codeType: "تجاري",
        outerArea: "800",
        residentialArea: "0",
        commercialArea: "7500.50",
        buildingArea: "0",
        floorsNumber: "5",
        totalFloorArea: "7500.50",
        shareCount: "750050000",
        description: "مقسم تجاري 5 طوابق",
        active: true,
        createdAt: "2024-07-26T23:45:11.000000Z",
        updatedAt: "2025-06-11T19:28:08.000000Z",
        sectorName: SectorName(
          name: "تجاري",
          code: "مقسم S177",
        ),
        cover: Cover(
          img: "", // Empty image to test placeholder
        ),
      ),
      media: const [],
    );
  }
} 