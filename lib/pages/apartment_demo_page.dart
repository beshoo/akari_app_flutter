import 'package:flutter/material.dart';
import '../data/models/apartment_model.dart';
import '../data/models/share_model.dart';
import '../widgets/post_card.dart';
import '../widgets/post_card_data.dart';

class ApartmentDemoPage extends StatelessWidget {
  const ApartmentDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apartment Card Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Sample apartment card - Residential
            PostCard(
              postData: ApartmentPostAdapter(_createSampleApartment1(), showOwner: true),
              onPostUpdated: (updatedPost) {
                // Handle apartment updates
              },
            ),
            
            const SizedBox(height: 20),
            
            // Sample apartment card - Commercial
            PostCard(
              postData: ApartmentPostAdapter(_createSampleApartment2(), showOwner: true),
              onPostUpdated: (updatedPost) {
                // Handle apartment updates
              },
            ),
          ],
        ),
      ),
    );
  }

  Apartment _createSampleApartment1() {
    return Apartment(
      id: 12,
      userId: 1,
      regionId: 1,
      sectorId: 1,
      directionId: 1,
      apartmentTypeId: 1,
      paymentMethodId: 2,
      floor: 3,
      area: 150,
      price: "20,001,111 ل.س",
      views: 98,
      roomsCount: 3,
      salonsCount: 1,
      balconyCount: 2,
      apartmentStatusId: 1,
      isTaras: 1,
      equity: "2000/2400",
      transactionType: "buy",
      ownerName: "أحمد محمد",
      createdAt: "2025-04-16T18:33:19.000000Z",
      updatedAt: "2025-07-01T18:37:58.000000Z",
      approve: 0,
      closed: 0,
      priceKey: 20001111,
      since: "منذ شهرين",
      userSentOrder: false,
      shareButton: "##شقة_سكنية_ماروتا_ستي\nطلب شراء شقة سكنية قيد التنفيذ - على الخريطة شرقي شمالي في منطقة ماروتا ستي",
      postType: "apartment",
      reactionCounts: const ReactionCounts(
        likeCount: 2,
        loveCount: 1,
        wowCount: 0,
        sadCount: 0,
        angryCount: 0,
        totalCount: 3,
      ),
      currentUserReaction: "like",
      isFavorited: true,
      paymentMethod: const PaymentMethod(id: 2, name: "تقسيط"),
      user: const User(id: 1, name: "محمد يزن", authenticated: 1),
      region: const Region(id: 1, name: "ماروتا ستي"),
      direction: const Direction(id: 1, name: "شرقي شمالي"),
      apartmentStatus: const ApartmentStatus(id: 1, name: "قيد التنفيذ - على الخريطة"),
      apartmentType: const ApartmentType(
        id: 1, 
        name: "شقة سكنية",
        fields: ["floor", "rooms_count", "salons_count", "balcony_count", "is_taras"]
      ),
      sector: const Sector(
        id: 1,
        regionId: 1,
        code: SectorCode(name: "سكني", viewCode: "مقسم H29", code: "H29"),
        codeId: "H29",
        codeType: "سكني",
        outerArea: "2850",
        residentialArea: "10586.38",
        commercialArea: "0",
        buildingArea: "0",
        floorsNumber: "13",
        totalFloorArea: "10586.38",
        shareCount: "1361807857",
        description: "سكني 13 طابق",
        active: true,
        createdAt: "2024-07-26T23:45:11.000000Z",
        updatedAt: "2025-06-11T19:28:08.000000Z",
        sectorName: SectorName(name: "سكني", code: "مقسم H29"),
        cover: Cover(img: "https://arrows-dev.versetech.net/media/1/H29.jpg"),
      ),
      media: const [],
      orderable: null,
    );
  }

  Apartment _createSampleApartment2() {
    return Apartment(
      id: 6,
      userId: 1,
      regionId: 1,
      sectorId: 55,
      directionId: 2,
      apartmentTypeId: 2,
      paymentMethodId: 2,
      floor: 1,
      area: 150,
      price: "30,000,000 ل.س",
      views: 222,
      roomsCount: 1,
      salonsCount: 0,
      balconyCount: 0,
      apartmentStatusId: 4,
      isTaras: 0,
      equity: "2400/2400",
      transactionType: "sell",
      ownerName: "محمد الحفار",
      createdAt: "2024-09-28T10:40:29.000000Z",
      updatedAt: "2025-07-01T13:35:31.000000Z",
      approve: 1,
      closed: 0,
      priceKey: 30000000,
      since: "منذ 9 أشهر",
      userSentOrder: false,
      shareButton: "##محل_تجاري_ماروتا_ستي\nعرض بيع محل تجاري مكتملة التنفيذ",
      postType: "apartment",
      reactionCounts: const ReactionCounts(
        likeCount: 1,
        loveCount: 0,
        wowCount: 0,
        sadCount: 0,
        angryCount: 0,
        totalCount: 1,
      ),
      currentUserReaction: null,
      isFavorited: false,
      paymentMethod: const PaymentMethod(id: 2, name: "تقسيط"),
      user: const User(id: 1, name: "محمد يزن", authenticated: 1),
      region: const Region(id: 1, name: "ماروتا ستي"),
      direction: const Direction(id: 2, name: "شرقي جنوبي"),
      apartmentStatus: const ApartmentStatus(id: 4, name: "مكتملة التنفيذ - كاملة الإكساء"),
      apartmentType: const ApartmentType(
        id: 2, 
        name: "محل تجاري",
        fields: ["floor", "rooms_count", "salons_count", "balcony_count"]
      ),
      sector: const Sector(
        id: 55,
        regionId: 1,
        code: SectorCode(name: "تجاري", viewCode: "مقسم QB209", code: "QB209"),
        codeId: "QB209",
        codeType: "تجاري",
        outerArea: "3501",
        residentialArea: "0",
        commercialArea: "7500.50",
        buildingArea: "0",
        floorsNumber: "22",
        totalFloorArea: "7500.50",
        shareCount: "750050000",
        description: "مقسم تجاري 5 طوابق",
        active: true,
        createdAt: "2024-07-26T23:45:11.000000Z",
        updatedAt: "2025-06-11T19:28:08.000000Z",
        sectorName: SectorName(name: "تجاري", code: "مقسم QB209"),
        cover: Cover(img: "https://arrows-dev.versetech.net/media/173/QB209.jpg"),
      ),
      media: const [],
      orderable: null,
    );
  }
} 