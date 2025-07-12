import 'share_model.dart'; // For shared models like User, Region, Sector, ReactionCounts

class PaymentMethod {
  final int id;
  final String name;

  const PaymentMethod({
    required this.id,
    required this.name,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
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
}

class Direction {
  final int id;
  final String name;

  const Direction({
    required this.id,
    required this.name,
  });

  factory Direction.fromJson(Map<String, dynamic> json) {
    return Direction(
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
}

class ApartmentStatus {
  final int id;
  final String name;

  const ApartmentStatus({
    required this.id,
    required this.name,
  });

  factory ApartmentStatus.fromJson(Map<String, dynamic> json) {
    return ApartmentStatus(
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
}

class ApartmentType {
  final int id;
  final String name;
  final List<String> fields;

  const ApartmentType({
    required this.id,
    required this.name,
    required this.fields,
  });

  factory ApartmentType.fromJson(Map<String, dynamic> json) {
    return ApartmentType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      fields: List<String>.from(json['fields'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fields': fields,
    };
  }
}

class Apartment {
  final int id;
  final int userId;
  final int regionId;
  final int sectorId;
  final int directionId;
  final int apartmentTypeId;
  final int paymentMethodId;
  final int floor;
  final int area;
  final String price;
  final int views;
  final int roomsCount;
  final int salonsCount;
  final int balconyCount;
  final int apartmentStatusId;
  final int isTaras;
  final String equity;
  final String transactionType;
  final String ownerName;
  final String createdAt;
  final String updatedAt;
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
  final PaymentMethod? paymentMethod;
  final User user;
  final Region region;
  final Direction direction;
  final ApartmentStatus apartmentStatus;
  final ApartmentType apartmentType;
  final Sector sector;
  final List<dynamic> media;
  final dynamic orderable;

  const Apartment({
    required this.id,
    required this.userId,
    required this.regionId,
    required this.sectorId,
    required this.directionId,
    required this.apartmentTypeId,
    required this.paymentMethodId,
    required this.floor,
    required this.area,
    required this.price,
    required this.views,
    required this.roomsCount,
    required this.salonsCount,
    required this.balconyCount,
    required this.apartmentStatusId,
    required this.isTaras,
    required this.equity,
    required this.transactionType,
    required this.ownerName,
    required this.createdAt,
    required this.updatedAt,
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
    this.paymentMethod,
    required this.user,
    required this.region,
    required this.direction,
    required this.apartmentStatus,
    required this.apartmentType,
    required this.sector,
    required this.media,
    this.orderable,
  });

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      regionId: json['region_id'] ?? 0,
      sectorId: json['sector_id'] ?? 0,
      directionId: json['direction_id'] ?? 0,
      apartmentTypeId: json['apartment_type_id'] ?? 0,
      paymentMethodId: json['payment_method_id'] ?? 0,
      floor: json['floor'] ?? 0,
      area: json['area'] ?? 0,
      price: json['price'] ?? '',
      views: json['views'] ?? 0,
      roomsCount: json['rooms_count'] ?? 0,
      salonsCount: json['salons_count'] ?? 0,
      balconyCount: json['balcony_count'] ?? 0,
      apartmentStatusId: json['apartment_status_id'] ?? 0,
      isTaras: json['is_taras'] ?? 0,
      equity: json['equity'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      ownerName: json['owner_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      approve: json['approve'] ?? 0,
      closed: json['closed'] ?? 0,
      priceKey: json['price_key'] ?? 0,
      since: json['since'] ?? '',
      userSentOrder: json['user_sent_order'] ?? false,
      shareButton: json['share_button'] ?? '',
      postType: json['post_type'] ?? 'apartment',
      reactionCounts: ReactionCounts.fromJson(json['reaction_counts'] ?? {}),
      currentUserReaction: json['current_user_reaction'],
      isFavorited: json['is_favorited'] ?? false,
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.fromJson(json['payment_method'])
          : null,
      user: User.fromJson(json['user'] ?? {}),
      region: Region.fromJson(json['region'] ?? {}),
      direction: Direction.fromJson(json['direction'] ?? {}),
      apartmentStatus: ApartmentStatus.fromJson(json['apartment_status'] ?? {}),
      apartmentType: ApartmentType.fromJson(json['apartment_type'] ?? {}),
      sector: Sector.fromJson(json['sector'] ?? {}),
      media: json['media'] ?? [],
      orderable: json['orderable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'region_id': regionId,
      'sector_id': sectorId,
      'direction_id': directionId,
      'apartment_type_id': apartmentTypeId,
      'payment_method_id': paymentMethodId,
      'floor': floor,
      'area': area,
      'price': price,
      'views': views,
      'rooms_count': roomsCount,
      'salons_count': salonsCount,
      'balcony_count': balconyCount,
      'apartment_status_id': apartmentStatusId,
      'is_taras': isTaras,
      'equity': equity,
      'transaction_type': transactionType,
      'owner_name': ownerName,
      'created_at': createdAt,
      'updated_at': updatedAt,
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
      'payment_method': paymentMethod?.toJson(),
      'user': user.toJson(),
      'region': region.toJson(),
      'direction': direction.toJson(),
      'apartment_status': apartmentStatus.toJson(),
      'apartment_type': apartmentType.toJson(),
      'sector': sector.toJson(),
      'media': media,
      'orderable': orderable,
    };
  }

  // Helper getters
  String get transactionTypeText {
    return transactionType == 'sell' ? 'بيع' : 'شراء';
  }

  bool get isClosed {
    return closed == 1;
  }

  String get closedText {
    return 'مُباع';
  }

  bool get isAuthenticated {
    return user.authenticated == 1;
  }

  // Create a copy with updated values (for state management)
  Apartment copyWith({
    int? id,
    int? userId,
    int? regionId,
    int? sectorId,
    int? directionId,
    int? apartmentTypeId,
    int? paymentMethodId,
    int? floor,
    int? area,
    String? price,
    int? views,
    int? roomsCount,
    int? salonsCount,
    int? balconyCount,
    int? apartmentStatusId,
    int? isTaras,
    String? equity,
    String? transactionType,
    String? ownerName,
    String? createdAt,
    String? updatedAt,
    int? approve,
    int? closed,
    int? priceKey,
    String? since,
    bool? userSentOrder,
    String? shareButton,
    String? postType,
    ReactionCounts? reactionCounts,
    String? currentUserReaction,
    bool? isFavorited,
    PaymentMethod? paymentMethod,
    User? user,
    Region? region,
    Direction? direction,
    ApartmentStatus? apartmentStatus,
    ApartmentType? apartmentType,
    Sector? sector,
    List<dynamic>? media,
    dynamic orderable,
  }) {
    return Apartment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      regionId: regionId ?? this.regionId,
      sectorId: sectorId ?? this.sectorId,
      directionId: directionId ?? this.directionId,
      apartmentTypeId: apartmentTypeId ?? this.apartmentTypeId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      floor: floor ?? this.floor,
      area: area ?? this.area,
      price: price ?? this.price,
      views: views ?? this.views,
      roomsCount: roomsCount ?? this.roomsCount,
      salonsCount: salonsCount ?? this.salonsCount,
      balconyCount: balconyCount ?? this.balconyCount,
      apartmentStatusId: apartmentStatusId ?? this.apartmentStatusId,
      isTaras: isTaras ?? this.isTaras,
      equity: equity ?? this.equity,
      transactionType: transactionType ?? this.transactionType,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approve: approve ?? this.approve,
      closed: closed ?? this.closed,
      priceKey: priceKey ?? this.priceKey,
      since: since ?? this.since,
      userSentOrder: userSentOrder ?? this.userSentOrder,
      shareButton: shareButton ?? this.shareButton,
      postType: postType ?? this.postType,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      currentUserReaction: currentUserReaction ?? this.currentUserReaction,
      isFavorited: isFavorited ?? this.isFavorited,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      user: user ?? this.user,
      region: region ?? this.region,
      direction: direction ?? this.direction,
      apartmentStatus: apartmentStatus ?? this.apartmentStatus,
      apartmentType: apartmentType ?? this.apartmentType,
      sector: sector ?? this.sector,
      media: media ?? this.media,
      orderable: orderable ?? this.orderable,
    );
  }
}

class ApartmentResponse {
  final int currentPage;
  final List<Apartment> apartments;
  final String firstPageUrl;
  final int from;
  final int lastPage;
  final String lastPageUrl;
  final List<dynamic> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int to;
  final int total;

  const ApartmentResponse({
    required this.currentPage,
    required this.apartments,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory ApartmentResponse.fromJson(Map<String, dynamic> json) {
    return ApartmentResponse(
      currentPage: json['current_page'] ?? 1,
      apartments: (json['data'] as List<dynamic>? ?? [])
          .map((item) => Apartment.fromJson(item))
          .toList(),
      firstPageUrl: json['first_page_url'] ?? '',
      from: json['from'] ?? 0,
      lastPage: json['last_page'] ?? 1,
      lastPageUrl: json['last_page_url'] ?? '',
      links: json['links'] ?? [],
      nextPageUrl: json['next_page_url'],
      path: json['path'] ?? '',
      perPage: json['per_page'] ?? 20,
      prevPageUrl: json['prev_page_url'],
      to: json['to'] ?? 0,
      total: json['total'] ?? 0,
    );
  }

  bool get hasNextPage => nextPageUrl != null;
} 