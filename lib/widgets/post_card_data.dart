import 'package:flutter/foundation.dart';
import '../data/models/share_model.dart';
import '../data/models/apartment_model.dart';

class InfoRowData {
  final String iconName;
  final String text;

  InfoRowData({required this.iconName, required this.text});
}

abstract class PostCardData {
  int get id;
  String get postType;
  bool get isFavorited;
  String? get currentUserReaction;
  ReactionCounts get reactionCounts;

  String get imageUrl;
  String get transactionTypeText;
  String get badgeId;
  bool get isUnderReview;
  bool get isClosed;
  String get closedText;
  String get title;
  String get subtitle;
  bool get isUserVerified;
  List<InfoRowData> get infoRows;
  int get views;
  String get shareButtonText;

  PostCardData withFavorite(bool isFavorited);
  PostCardData withReaction(
      String? reactionType, Map<String, dynamic> reactionSummary);
  PostCardData withReactionCounts(Map<String, dynamic> counts);
  PostCardData withManuallyDecrementedReaction(String reactionType);
}

class SharePostAdapter implements PostCardData {
  final Share _share;
  final bool _showOwner;

  Share get share => _share;

  SharePostAdapter(this._share, {required bool showOwner})
      : _showOwner = showOwner;

  @override
  int get id => _share.id;
  @override
  String get postType => _share.postType;
  @override
  bool get isFavorited => _share.isFavorited;
  @override
  String? get currentUserReaction => _share.currentUserReaction;
  @override
  ReactionCounts get reactionCounts => _share.reactionCounts;

  @override
  String get imageUrl => _share.sector.cover.img.isNotEmpty
      ? _share.sector.cover.img
      : 'assets/images/no_photo.jpg';
  @override
  String get transactionTypeText => _share.transactionTypeText;
  @override
  String get badgeId => '#${_share.id}';
  @override
  bool get isUnderReview => _share.approve == 0;
  @override
  bool get isClosed => _share.isClosed;
  @override
  String get closedText => _share.closedText;
  @override
  String get title =>
      '${_share.sector.sectorName.name} - ${_share.sector.sectorName.code}';
  @override
  String get subtitle =>
      '${_share.region.name} - أسهم تنظيمية / نية ${_share.transactionTypeText}';
  @override
  bool get isUserVerified => _share.user.isAuthenticated;
  @override
  int get views => _share.views;
  @override
  String get shareButtonText => _share.shareButton;

  @override
  List<InfoRowData> get infoRows {
    final rows = [
      InfoRowData(iconName: 'price.png', text: 'سعر السهم : ${_share.price}'),
      InfoRowData(
          iconName: 'quantity.png',
          text: 'الأسهم المطروحة : ${_share.quantity}'),
      InfoRowData(
          iconName: 'date.png', text: 'تاريخ النشر : ${_share.since}'),
    ];
    if (_showOwner) {
      rows.add(InfoRowData(
          iconName: 'user.png', text: 'الجهة العارضة : ${_share.ownerName}'));
    }
    return rows;
  }

  @override
  PostCardData withFavorite(bool isFavorited) {
    final newShare = Share.fromJson({
      ..._share.toJson(),
      'is_favorited': isFavorited,
    });
    return SharePostAdapter(newShare, showOwner: _showOwner);
  }

  @override
  PostCardData withReaction(
      String? reactionType, Map<String, dynamic> reactionSummary) {
    if (kDebugMode) {
      print('📊 Updating reaction summary from adapter: $reactionSummary');
    }
    final newShare = Share.fromJson({
      ..._share.toJson(),
      'current_user_reaction': reactionType,
      'reaction_counts': {
        'like_count': reactionSummary['like_count'] ?? 0,
        'love_count': reactionSummary['love_count'] ?? 0,
        'wow_count': reactionSummary['wow_count'] ?? 0,
        'sad_count': reactionSummary['sad_count'] ?? 0,
        'angry_count': reactionSummary['angry_count'] ?? 0,
        'total_count': reactionSummary['total_count'] ?? 0,
      },
    });
    return SharePostAdapter(newShare, showOwner: _showOwner);
  }

  @override
  PostCardData withReactionCounts(Map<String, dynamic> counts) {
    final newShare = Share.fromJson({
      ..._share.toJson(),
      'reaction_counts': counts,
    });
    return SharePostAdapter(newShare, showOwner: _showOwner);
  }

  @override
  PostCardData withManuallyDecrementedReaction(String reactionType) {
    final counts = _share.reactionCounts;
    final newCounts = {
      'like_count': counts.likeCount,
      'love_count': counts.loveCount,
      'wow_count': counts.wowCount,
      'sad_count': counts.sadCount,
      'angry_count': counts.angryCount,
      'total_count': counts.totalCount,
    };

    newCounts['${reactionType}_count'] =
        (newCounts['${reactionType}_count']! - 1)
            .clamp(0, double.infinity)
            .toInt();
    newCounts['total_count'] =
        (newCounts['total_count']! - 1).clamp(0, double.infinity).toInt();

    final newShare = Share.fromJson({
      ..._share.toJson(),
      'current_user_reaction': null,
      'reaction_counts': newCounts,
    });
    return SharePostAdapter(newShare, showOwner: _showOwner);
  }
}

class ApartmentPostAdapter implements PostCardData {
  final Apartment _apartment;
  final bool _showOwner;

  Apartment get apartment => _apartment;

  ApartmentPostAdapter(this._apartment, {required bool showOwner})
      : _showOwner = showOwner;

  @override
  int get id => _apartment.id;
  @override
  String get postType => _apartment.postType;
  @override
  bool get isFavorited => _apartment.isFavorited;
  @override
  String? get currentUserReaction => _apartment.currentUserReaction;
  @override
  ReactionCounts get reactionCounts => _apartment.reactionCounts;

  @override
  String get imageUrl => _apartment.sector.cover.img.isNotEmpty
      ? _apartment.sector.cover.img
      : 'assets/images/no_photo.jpg';
  @override
  String get transactionTypeText => _apartment.transactionTypeText;
  @override
  String get badgeId => '#${_apartment.id}';
  @override
  bool get isUnderReview => _apartment.approve == 0;
  @override
  bool get isClosed => _apartment.isClosed;
  @override
  String get closedText => _apartment.closedText;
  @override
  String get title =>
      '${_apartment.sector.sectorName.name} - ${_apartment.sector.sectorName.code}';
  @override
  String get subtitle =>
      '${_apartment.region.name} - ${_apartment.apartmentType.name} / نية ${_apartment.transactionTypeText}';
  @override
  bool get isUserVerified => _apartment.user.isAuthenticated;
  @override
  int get views => _apartment.views;
  @override
  String get shareButtonText => _apartment.shareButton;

  @override
  List<InfoRowData> get infoRows {
    final rows = <InfoRowData>[];
    
    // Always show price and equity
    rows.add(InfoRowData(iconName: 'price.png', text: 'السعر : ${_apartment.price}'));
    rows.add(InfoRowData(iconName: 'quantity.png', text: 'الحصة السهمية : ${_apartment.equity}'));
    
    // Show area if available
    if (_apartment.area > 0) {
      rows.add(InfoRowData(iconName: 'area.png', text: 'المساحة : ${_apartment.area} متر'));
    }
    
    // Show apartment status
    rows.add(InfoRowData(iconName: 'apartment_status.png', text: 'الحالة : ${_apartment.apartmentStatus.name}'));
    
    // Show direction
    rows.add(InfoRowData(iconName: 'direction.png', text: 'الاتجاه : ${_apartment.direction.name}'));
    
    // Show payment method if available
    if (_apartment.paymentMethod != null) {
      rows.add(InfoRowData(iconName: 'mobile.png', text: 'طريقة الدفع : ${_apartment.paymentMethod!.name}'));
    }
    
    // Show apartment details based on type fields
    final apartmentDetails = <String>[];
    
    if (_apartment.apartmentType.fields.contains('floor') && _apartment.floor > 0) {
      apartmentDetails.add('الطابق: ${_apartment.floor}');
    }
    if (_apartment.apartmentType.fields.contains('rooms_count') && _apartment.roomsCount > 0) {
     // apartmentDetails.add('عدد الغرف: ${_apartment.roomsCount}');
    }
    if (_apartment.apartmentType.fields.contains('salons_count') && _apartment.salonsCount > 0) {
     // apartmentDetails.add('عدد الصالونات: ${_apartment.salonsCount}');
    }
    if (_apartment.apartmentType.fields.contains('balcony_count') && _apartment.balconyCount > 0) {
     // apartmentDetails.add('عدد الشرفات: ${_apartment.balconyCount}');
    }
    if (_apartment.apartmentType.fields.contains('is_taras') && _apartment.isTaras == 1) {
     // apartmentDetails.add('تراس: نعم');
    }
    
/*     if (apartmentDetails.isNotEmpty) {
      rows.add(InfoRowData(
        iconName: 'features.png', 
        text: 'المواصفات : ${apartmentDetails.join(' , ')}'
      ));
    } */
    
    // Always show publication date
    rows.add(InfoRowData(iconName: 'date.png', text: 'تاريخ النشر : ${_apartment.since}'));
    
    // Show owner if allowed
    if (_showOwner) {
      rows.add(InfoRowData(
          iconName: 'user.png', text: 'الجهة العارضة : ${_apartment.ownerName}'));
    }
    
    return rows;
  }

  @override
  PostCardData withFavorite(bool isFavorited) {
    final newApartment = Apartment.fromJson({
      ..._apartment.toJson(),
      'is_favorited': isFavorited,
    });
    return ApartmentPostAdapter(newApartment, showOwner: _showOwner);
  }

  @override
  PostCardData withReaction(
      String? reactionType, Map<String, dynamic> reactionSummary) {
    if (kDebugMode) {
      print('📊 Updating apartment reaction summary: $reactionSummary');
    }
    final newApartment = Apartment.fromJson({
      ..._apartment.toJson(),
      'current_user_reaction': reactionType,
      'reaction_counts': {
        'like_count': reactionSummary['like_count'] ?? 0,
        'love_count': reactionSummary['love_count'] ?? 0,
        'wow_count': reactionSummary['wow_count'] ?? 0,
        'sad_count': reactionSummary['sad_count'] ?? 0,
        'angry_count': reactionSummary['angry_count'] ?? 0,
        'total_count': reactionSummary['total_count'] ?? 0,
      },
    });
    return ApartmentPostAdapter(newApartment, showOwner: _showOwner);
  }

  @override
  PostCardData withReactionCounts(Map<String, dynamic> counts) {
    final newApartment = Apartment.fromJson({
      ..._apartment.toJson(),
      'reaction_counts': counts,
    });
    return ApartmentPostAdapter(newApartment, showOwner: _showOwner);
  }

  @override
  PostCardData withManuallyDecrementedReaction(String reactionType) {
    final counts = _apartment.reactionCounts;
    final newCounts = {
      'like_count': counts.likeCount,
      'love_count': counts.loveCount,
      'wow_count': counts.wowCount,
      'sad_count': counts.sadCount,
      'angry_count': counts.angryCount,
      'total_count': counts.totalCount,
    };

    newCounts['${reactionType}_count'] =
        (newCounts['${reactionType}_count']! - 1)
            .clamp(0, double.infinity)
            .toInt();
    newCounts['total_count'] =
        (newCounts['total_count']! - 1).clamp(0, double.infinity).toInt();

    final newApartment = Apartment.fromJson({
      ..._apartment.toJson(),
      'current_user_reaction': null,
      'reaction_counts': newCounts,
    });
    return ApartmentPostAdapter(newApartment, showOwner: _showOwner);
  }
} 