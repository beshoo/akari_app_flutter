import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';
import '../widgets/custom_dialog.dart';

class AdsStore extends ChangeNotifier {
  int currentTab = 0; // 0: shares, 1: apartments
  String currentFilter = 'all'; // 'all', 'buy', 'sell'
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isDeleting = false;
  
  // Share ads data
  List<Map<String, dynamic>> shareBuyAds = [];
  List<Map<String, dynamic>> shareSellAds = [];
  int shareBuyCurrentPage = 1;
  int shareSellCurrentPage = 1;
  bool shareBuyHasMore = true;
  bool shareSellHasMore = true;
  
  // Apartment ads data
  List<Map<String, dynamic>> apartmentBuyAds = [];
  List<Map<String, dynamic>> apartmentSellAds = [];
  int apartmentBuyCurrentPage = 1;
  int apartmentSellCurrentPage = 1;
  bool apartmentBuyHasMore = true;
  bool apartmentSellHasMore = true;
  
  Map<String, dynamic>? _pendingDeleteAd;
  String? _pendingDeleteType;

  void setTab(int tab) {
    if (currentTab != tab) {
      currentTab = tab;
      _resetPagination();
      loadAds(force: true);
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    if (currentFilter != filter) {
      currentFilter = filter;
      _resetPagination();
      loadAds(force: true);
      notifyListeners();
    }
  }

  void _resetPagination() {
    shareBuyCurrentPage = 1;
    shareSellCurrentPage = 1;
    apartmentBuyCurrentPage = 1;
    apartmentSellCurrentPage = 1;
    shareBuyHasMore = true;
    shareSellHasMore = true;
    apartmentBuyHasMore = true;
    apartmentSellHasMore = true;
    shareBuyAds.clear();
    shareSellAds.clear();
    apartmentBuyAds.clear();
    apartmentSellAds.clear();
  }

  List<Map<String, dynamic>> get currentAds {
    if (currentTab == 0) {
      // Shares tab
      if (currentFilter == 'buy') return shareBuyAds;
      if (currentFilter == 'sell') return shareSellAds;
      return [...shareBuyAds, ...shareSellAds];
    } else {
      // Apartments tab
      if (currentFilter == 'buy') return apartmentBuyAds;
      if (currentFilter == 'sell') return apartmentSellAds;
      return [...apartmentBuyAds, ...apartmentSellAds];
    }
  }

  bool get hasMoreData {
    if (currentTab == 0) {
      if (currentFilter == 'buy') return shareBuyHasMore;
      if (currentFilter == 'sell') return shareSellHasMore;
      return shareBuyHasMore || shareSellHasMore;
    } else {
      if (currentFilter == 'buy') return apartmentBuyHasMore;
      if (currentFilter == 'sell') return apartmentSellHasMore;
      return apartmentBuyHasMore || apartmentSellHasMore;
    }
  }

  Future<void> loadAds({bool force = false}) async {
    if (force) {
      _resetPagination();
    }
    
    isLoading = true;
    notifyListeners();
    
    try {
      if (currentTab == 0) {
        await _loadShareAds(force);
      } else {
        await _loadApartmentAds(force);
      }
    } catch (e) {
      Logger.log('حدث خطأ أثناء تحميل الإعلانات: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadShareAds(bool force) async {
    if (currentFilter == 'all' || currentFilter == 'buy') {
      if (force || shareBuyAds.isEmpty) {
        final response = await ApiService.instance.get('/profile/share/listAll/buy', 
          queryParameters: {'page': shareBuyCurrentPage});
        final newAds = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        if (force) {
          shareBuyAds = newAds;
        } else {
          shareBuyAds.addAll(newAds);
        }
        shareBuyHasMore = response.data['next_page_url'] != null;
      }
    }
    
    if (currentFilter == 'all' || currentFilter == 'sell') {
      if (force || shareSellAds.isEmpty) {
        final response = await ApiService.instance.get('/profile/share/listAll/sell', 
          queryParameters: {'page': shareSellCurrentPage});
        final newAds = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        if (force) {
          shareSellAds = newAds;
        } else {
          shareSellAds.addAll(newAds);
        }
        shareSellHasMore = response.data['next_page_url'] != null;
      }
    }
  }

  Future<void> _loadApartmentAds(bool force) async {
    if (currentFilter == 'all' || currentFilter == 'buy') {
      if (force || apartmentBuyAds.isEmpty) {
        final response = await ApiService.instance.get('/profile/apartment/listAll/buy', 
          queryParameters: {'page': apartmentBuyCurrentPage});
        final newAds = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        if (force) {
          apartmentBuyAds = newAds;
        } else {
          apartmentBuyAds.addAll(newAds);
        }
        apartmentBuyHasMore = response.data['next_page_url'] != null;
      }
    }
    
    if (currentFilter == 'all' || currentFilter == 'sell') {
      if (force || apartmentSellAds.isEmpty) {
        final response = await ApiService.instance.get('/profile/apartment/listAll/sell', 
          queryParameters: {'page': apartmentSellCurrentPage});
        final newAds = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        if (force) {
          apartmentSellAds = newAds;
        } else {
          apartmentSellAds.addAll(newAds);
        }
        apartmentSellHasMore = response.data['next_page_url'] != null;
      }
    }
  }

  Future<void> loadMoreAds() async {
    if (isLoadingMore) return;
    
    isLoadingMore = true;
    notifyListeners();
    
    try {
      if (currentTab == 0) {
        await _loadMoreShareAds();
      } else {
        await _loadMoreApartmentAds();
      }
    } catch (e) {
      Logger.log('حدث خطأ أثناء تحميل المزيد من الإعلانات: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _loadMoreShareAds() async {
    if (currentFilter == 'all' || currentFilter == 'buy') {
      if (shareBuyHasMore) {
        shareBuyCurrentPage++;
        final response = await ApiService.instance.get('/profile/share/listAll/buy', 
          queryParameters: {'page': shareBuyCurrentPage});
        final newAds = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        shareBuyAds.addAll(newAds);
        shareBuyHasMore = response.data['next_page_url'] != null;
      }
    }
    
    if (currentFilter == 'all' || currentFilter == 'sell') {
      if (shareSellHasMore) {
        shareSellCurrentPage++;
        final response = await ApiService.instance.get('/profile/share/listAll/sell', 
          queryParameters: {'page': shareSellCurrentPage});
        final newAds = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        shareSellAds.addAll(newAds);
        shareSellHasMore = response.data['next_page_url'] != null;
      }
    }
  }

  Future<void> _loadMoreApartmentAds() async {
    if (currentFilter == 'all' || currentFilter == 'buy') {
      if (apartmentBuyHasMore) {
        apartmentBuyCurrentPage++;
        final response = await ApiService.instance.get('/profile/apartment/listAll/buy', 
          queryParameters: {'page': apartmentBuyCurrentPage});
        final newAds = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        apartmentBuyAds.addAll(newAds);
        apartmentBuyHasMore = response.data['next_page_url'] != null;
      }
    }
    
    if (currentFilter == 'all' || currentFilter == 'sell') {
      if (apartmentSellHasMore) {
        apartmentSellCurrentPage++;
        final response = await ApiService.instance.get('/profile/apartment/listAll/sell', 
          queryParameters: {'page': apartmentSellCurrentPage});
        final newAds = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        apartmentSellAds.addAll(newAds);
        apartmentSellHasMore = response.data['next_page_url'] != null;
      }
    }
  }

  Future<void> confirmDelete(BuildContext context, Map<String, dynamic> ad, String type) async {
    _pendingDeleteAd = ad;
    _pendingDeleteType = type;
    await showCustomDialog(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد من حذف هذا الإعلان؟',
      okButtonText: 'تأكيد',
      cancelButtonText: 'الغاء',
      onOkPressed: () {
        _deleteAd(context);
      },
      isWarning: true,
    );
  }

  Future<void> _deleteAd(BuildContext context) async {
    if (_pendingDeleteAd == null || _pendingDeleteType == null) return;
    
    final adToDelete = _pendingDeleteAd!;
    final typeToDelete = _pendingDeleteType!;
    
    try {
      // Immediately remove from UI for better UX
      _removeFromLocalList(adToDelete);
      notifyListeners();
      
      final adId = adToDelete['id'];
      String endpoint;
      
      if (typeToDelete == 'share') {
        endpoint = '/share/delete/$adId';
      } else {
        endpoint = '/apartment/delete/$adId';
      }
      
      final response = await ApiService.instance.delete(endpoint);
      
      if (response.statusCode != 200) {
        // If delete failed, add the item back to the list
        _addBackToLocalList(adToDelete, typeToDelete);
        notifyListeners();
      }
    } catch (e) {
      Logger.log('حدث خطأ أثناء حذف الإعلان: $e');
      // If delete failed, add the item back to the list
      _addBackToLocalList(adToDelete, typeToDelete);
      notifyListeners();
    } finally {
      _pendingDeleteAd = null;
      _pendingDeleteType = null;
    }
  }
  
  void _removeFromLocalList(Map<String, dynamic> ad) {
    final adId = ad['id'];
    final transactionType = ad['transaction_type'];
    
    if (currentTab == 0) {
      // Shares
      if (transactionType == 'buy') {
        shareBuyAds.removeWhere((item) => item['id'] == adId);
      } else {
        shareSellAds.removeWhere((item) => item['id'] == adId);
      }
    } else {
      // Apartments
      if (transactionType == 'buy') {
        apartmentBuyAds.removeWhere((item) => item['id'] == adId);
      } else {
        apartmentSellAds.removeWhere((item) => item['id'] == adId);
      }
    }
  }
  
  void _addBackToLocalList(Map<String, dynamic> ad, String type) {
    final transactionType = ad['transaction_type'];
    
    if (type == 'share') {
      if (transactionType == 'buy') {
        shareBuyAds.add(ad);
      } else {
        shareSellAds.add(ad);
      }
    } else {
      if (transactionType == 'buy') {
        apartmentBuyAds.add(ad);
      } else {
        apartmentSellAds.add(ad);
      }
    }
  }
} 