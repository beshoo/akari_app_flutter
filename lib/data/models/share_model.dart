import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class Share extends Equatable {
  final int id;
  final int userId;
  final int regionId;
  final int sectorId;
  final String quantity;
  final String createdAt;
  final String updatedAt;
  final String ownerName;
  final String transactionType;
  final String price;
  final int views;
  final int approve;
  final int closed;
  final int priceKey;
  final String since;
  final bool userSentOrder;
  final String shareButton;
  final String postType;
  final ReactionCounts reactionCounts;
  final String? currentUserReaction;
  final bool isFavorited;
  final User user;
  final Region region;
  final Sector sector;
  final dynamic orderable;
  final List<dynamic> media;

  const Share({
    required this.id,
    required this.userId,
    required this.regionId,
    required this.sectorId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.ownerName,
    required this.transactionType,
    required this.price,
    required this.views,
    required this.approve,
    required this.closed,
    required this.priceKey,
    required this.since,
    required this.userSentOrder,
    required this.shareButton,
    required this.postType,
    required this.reactionCounts,
    this.currentUserReaction,
    required this.isFavorited,
    required this.user,
    required this.region,
    required this.sector,
    this.orderable,
    required this.media,
  });

  factory Share.fromJson(Map<String, dynamic> json) {
    return Share(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      regionId: json['region_id'] ?? 0,
      sectorId: json['sector_id'] ?? 0,
      quantity: json['quantity'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      ownerName: json['owner_name'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      price: json['price'] ?? '',
      views: json['views'] ?? 0,
      approve: json['approve'] ?? 0,
      closed: json['closed'] ?? 0,
      priceKey: json['price_key'] ?? 0,
      since: json['since'] ?? '',
      userSentOrder: json['user_sent_order'] ?? false,
      shareButton: json['share_button'] ?? '',
      postType: json['post_type'] ?? '',
      reactionCounts: ReactionCounts.fromJson(json['reaction_counts'] ?? {}),
      currentUserReaction: json['current_user_reaction'],
      isFavorited: json['is_favorited'] ?? false,
      user: User.fromJson(json['user'] ?? {}),
      region: Region.fromJson(json['region'] ?? {}),
      sector: Sector.fromJson(json['sector'] ?? {}),
      orderable: json['orderable'],
      media: json['media'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'region_id': regionId,
      'sector_id': sectorId,
      'quantity': quantity,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'owner_name': ownerName,
      'transaction_type': transactionType,
      'price': price,
      'views': views,
      'approve': approve,
      'closed': closed,
      'price_key': priceKey,
      'since': since,
      'user_sent_order': userSentOrder,
      'share_button': shareButton,
      'post_type': postType,
      'reaction_counts': reactionCounts.toJson(),
      'current_user_reaction': currentUserReaction,
      'is_favorited': isFavorited,
      'user': user.toJson(),
      'region': region.toJson(),
      'sector': sector.toJson(),
      'orderable': orderable,
      'media': media,
    };
  }

  // Helper methods
  String get transactionTypeText {
    return transactionType == 'sell' ? 'بيع' : 'شراء';
  }

  String get closedText {
    return transactionType == 'sell' ? 'تم البيع' : 'تم الشراء';
  }

  bool get isApproved => approve == 1;
  bool get isClosed => closed == 1;
  bool get isOwner => user.id == userId;

  // Create a copy with updated values (for state management)
  Share copyWith({
    int? id,
    int? userId,
    int? regionId,
    int? sectorId,
    String? quantity,
    String? createdAt,
    String? updatedAt,
    String? ownerName,
    String? transactionType,
    String? price,
    int? views,
    int? approve,
    int? closed,
    int? priceKey,
    String? since,
    bool? userSentOrder,
    String? shareButton,
    String? postType,
    ReactionCounts? reactionCounts,
    ValueGetter<String?>? currentUserReaction,
    bool? isFavorited,
    User? user,
    Region? region,
    Sector? sector,
    dynamic orderable,
    List<dynamic>? media,
  }) {
    return Share(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      regionId: regionId ?? this.regionId,
      sectorId: sectorId ?? this.sectorId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerName: ownerName ?? this.ownerName,
      transactionType: transactionType ?? this.transactionType,
      price: price ?? this.price,
      views: views ?? this.views,
      approve: approve ?? this.approve,
      closed: closed ?? this.closed,
      priceKey: priceKey ?? this.priceKey,
      since: since ?? this.since,
      userSentOrder: userSentOrder ?? this.userSentOrder,
      shareButton: shareButton ?? this.shareButton,
      postType: postType ?? this.postType,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      currentUserReaction: currentUserReaction != null ? currentUserReaction() : this.currentUserReaction,
      isFavorited: isFavorited ?? this.isFavorited,
      user: user ?? this.user,
      region: region ?? this.region,
      sector: sector ?? this.sector,
      orderable: orderable ?? this.orderable,
      media: media ?? this.media,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        regionId,
        sectorId,
        quantity,
        createdAt,
        updatedAt,
        ownerName,
        transactionType,
        price,
        views,
        approve,
        closed,
        priceKey,
        since,
        userSentOrder,
        shareButton,
        postType,
        reactionCounts,
        currentUserReaction,
        isFavorited,
        user,
        region,
        sector,
        orderable,
        media,
      ];
}

class ReactionCounts extends Equatable {
  final int likeCount;
  final int loveCount;
  final int wowCount;
  final int sadCount;
  final int angryCount;
  final int totalCount;

  const ReactionCounts({
    required this.likeCount,
    required this.loveCount,
    required this.wowCount,
    required this.sadCount,
    required this.angryCount,
    required this.totalCount,
  });

  factory ReactionCounts.fromJson(Map<String, dynamic> json) {
    return ReactionCounts(
      likeCount: json['like_count'] ?? 0,
      loveCount: json['love_count'] ?? 0,
      wowCount: json['wow_count'] ?? 0,
      sadCount: json['sad_count'] ?? 0,
      angryCount: json['angry_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'like_count': likeCount,
      'love_count': loveCount,
      'wow_count': wowCount,
      'sad_count': sadCount,
      'angry_count': angryCount,
      'total_count': totalCount,
    };
  }

  @override
  List<Object> get props => [
        likeCount,
        loveCount,
        wowCount,
        sadCount,
        angryCount,
        totalCount,
      ];
}

class User extends Equatable {
  final int id;
  final String name;
  final int authenticated;

  const User({
    required this.id,
    required this.name,
    required this.authenticated,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      authenticated: json['authenticated'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'authenticated': authenticated,
    };
  }

  bool get isAuthenticated => authenticated == 1;

  @override
  List<Object> get props => [id, name, authenticated];
}

class Region extends Equatable {
  final int id;
  final String name;

  const Region({
    required this.id,
    required this.name,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object> get props => [id, name];
}

class Sector extends Equatable {
  final int id;
  final int regionId;
  final SectorCode code;
  final String codeId;
  final String codeType;
  final String outerArea;
  final String residentialArea;
  final String commercialArea;
  final String buildingArea;
  final String floorsNumber;
  final String totalFloorArea;
  final String shareCount;
  final dynamic owners;
  final dynamic contractor;
  final dynamic engineers;
  final String description;
  final bool active;
  final String createdAt;
  final String updatedAt;
  final SectorName sectorName;
  final Cover cover;
  final List<dynamic> photos;

  const Sector({
    required this.id,
    required this.regionId,
    required this.code,
    required this.codeId,
    required this.codeType,
    required this.outerArea,
    required this.residentialArea,
    required this.commercialArea,
    required this.buildingArea,
    required this.floorsNumber,
    required this.totalFloorArea,
    required this.shareCount,
    this.owners,
    this.contractor,
    this.engineers,
    required this.description,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    required this.sectorName,
    required this.cover,
    required this.photos,
  });

  factory Sector.fromJson(Map<String, dynamic> json) {
    return Sector(
      id: json['id'] ?? 0,
      regionId: json['region_id'] ?? 0,
      code: SectorCode.fromJson(json['code'] ?? {}),
      codeId: json['code_id'] ?? '',
      codeType: json['code_type'] ?? '',
      outerArea: json['outer_area'] ?? '',
      residentialArea: json['residential_area'] ?? '',
      commercialArea: json['commercial_area'] ?? '',
      buildingArea: json['building_area'] ?? '',
      floorsNumber: json['floors_number'] ?? '',
      totalFloorArea: json['total_floor_area'] ?? '',
      shareCount: json['share_count'] ?? '',
      owners: json['owners'],
      contractor: json['contractor'],
      engineers: json['engineers'],
      description: json['description'] ?? '',
      active: json['active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      sectorName: SectorName.fromJson(json['sector_name'] ?? {}),
      cover: Cover.fromJson(json['cover'] ?? {}),
      photos: json['photos'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region_id': regionId,
      'code': code.toJson(),
      'code_id': codeId,
      'code_type': codeType,
      'outer_area': outerArea,
      'residential_area': residentialArea,
      'commercial_area': commercialArea,
      'building_area': buildingArea,
      'floors_number': floorsNumber,
      'total_floor_area': totalFloorArea,
      'share_count': shareCount,
      'owners': owners,
      'contractor': contractor,
      'engineers': engineers,
      'description': description,
      'active': active,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sector_name': sectorName.toJson(),
      'cover': cover.toJson(),
      'photos': photos,
    };
  }

  @override
  List<Object?> get props => [
        id,
        regionId,
        code,
        codeId,
        codeType,
        outerArea,
        residentialArea,
        commercialArea,
        buildingArea,
        floorsNumber,
        totalFloorArea,
        shareCount,
        owners,
        contractor,
        engineers,
        description,
        active,
        createdAt,
            updatedAt,
    sectorName,
    cover,
    photos,
  ];
}

class SectorCode extends Equatable {
  final String name;
  final String viewCode;
  final String code;

  const SectorCode({
    required this.name,
    required this.viewCode,
    required this.code,
  });

  factory SectorCode.fromJson(Map<String, dynamic> json) {
    return SectorCode(
      name: json['name'] ?? '',
      viewCode: json['view_code'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'view_code': viewCode,
      'code': code,
    };
  }

  @override
  List<Object> get props => [name, viewCode, code];
}

class SectorName extends Equatable {
  final String name;
  final String code;

  const SectorName({
    required this.name,
    required this.code,
  });

  factory SectorName.fromJson(Map<String, dynamic> json) {
    return SectorName(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }

  @override
  List<Object> get props => [name, code];
}

class Cover extends Equatable {
  final String img;

  const Cover({
    required this.img,
  });

  factory Cover.fromJson(Map<String, dynamic> json) {
    return Cover(
      img: json['img'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'img': img,
    };
  }

  @override
  List<Object> get props => [img];
} 