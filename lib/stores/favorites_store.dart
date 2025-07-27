import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../widgets/custom_dialog.dart';
import '../services/api_service.dart';

class FavoritesStore extends ChangeNotifier {
  int currentTab = 0; // 0: shares, 1: apartments
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isDeleting = false;
  bool disposed = false;
  List<Map<String, dynamic>> shareFavorites = [];
  List<Map<String, dynamic>> apartmentFavorites = [];
  Map<String, dynamic>? _pendingDeleteFavorite;
  String? _pendingDeleteType;
  
  // Pagination variables
  int shareCurrentPage = 1;
  int apartmentCurrentPage = 1;
  bool shareHasMore = true;
  bool apartmentHasMore = true;
  


  void setTab(int tab) {
    if (currentTab != tab) {
      currentTab = tab;
      // Reset pagination for the new tab and force reload
      if (tab == 0) {
        shareCurrentPage = 1;
        shareHasMore = true;
        shareFavorites.clear();
      } else {
        apartmentCurrentPage = 1;
        apartmentHasMore = true;
        apartmentFavorites.clear();
      }
      loadFavorites(force: true);
      if (!disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> loadFavorites({bool force = false}) async {
    if (disposed) return;
    
    if (force) {
      // Reset pagination when forcing refresh
      shareCurrentPage = 1;
      apartmentCurrentPage = 1;
      shareHasMore = true;
      apartmentHasMore = true;
      shareFavorites.clear();
      apartmentFavorites.clear();
    }
    
    isLoading = true;
    if (!disposed) {
      notifyListeners();
    }
    
    try {
      if (currentTab == 0) {
        final response = await ApiService.instance.get('/favorites', queryParameters: {
          'type': 'shares',
          'page': shareCurrentPage
        });
        if (!disposed) {
          final newFavorites = List<Map<String, dynamic>>.from(response.data['data']['data'] ?? []);
          if (force) {
            shareFavorites = newFavorites;
          } else {
            shareFavorites.addAll(newFavorites);
          }
          shareHasMore = response.data['data']['next_page_url'] != null;
        }
      } else {
        final response = await ApiService.instance.get('/favorites', queryParameters: {
          'type': 'apartments',
          'page': apartmentCurrentPage
        });
        if (!disposed) {
          final newFavorites = List<Map<String, dynamic>>.from(response.data['data']['data'] ?? []);
          if (force) {
            apartmentFavorites = newFavorites;
          } else {
            apartmentFavorites.addAll(newFavorites);
          }
          apartmentHasMore = response.data['data']['next_page_url'] != null;
        }
      }
    } catch (e) {
      Logger.log('حدث خطأ أثناء تحميل المفضلة: $e');
      if (!disposed) {
        if (currentTab == 0) shareFavorites = [];
        if (currentTab == 1) apartmentFavorites = [];
      }
    } finally {
      if (!disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreFavorites() async {
    if (isLoadingMore || disposed) return;
    
    if (currentTab == 0 && !shareHasMore) return;
    if (currentTab == 1 && !apartmentHasMore) return;
    
    isLoadingMore = true;
    if (!disposed) {
      notifyListeners();
    }
    
    try {
      if (currentTab == 0) {
        shareCurrentPage++;
        final response = await ApiService.instance.get('/favorites', queryParameters: {
          'type': 'shares',
          'page': shareCurrentPage
        });
        if (!disposed) {
          final newFavorites = List<Map<String, dynamic>>.from(response.data['data']['data'] ?? []);
          shareFavorites.addAll(newFavorites);
          shareHasMore = response.data['data']['next_page_url'] != null;
        }
      } else {
        apartmentCurrentPage++;
        final response = await ApiService.instance.get('/favorites', queryParameters: {
          'type': 'apartments',
          'page': apartmentCurrentPage
        });
        if (!disposed) {
          final newFavorites = List<Map<String, dynamic>>.from(response.data['data']['data'] ?? []);
          apartmentFavorites.addAll(newFavorites);
          apartmentHasMore = response.data['data']['next_page_url'] != null;
        }
      }
    } catch (e) {
      Logger.log('حدث خطأ أثناء تحميل المزيد من المفضلة: $e');
    } finally {
      if (!disposed) {
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  bool get hasMoreData => currentTab == 0 ? shareHasMore : apartmentHasMore;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
  




  Future<void> confirmDelete(BuildContext context, Map<String, dynamic> favorite, String type) async {
    _pendingDeleteFavorite = favorite;
    _pendingDeleteType = type;
    if (context.mounted) {
      await showCustomDialog(
        context: context,
        title: 'تأكيد الحذف',
        message: 'هل أنت متأكد من حذف هذا العنصر من المفضلة؟',
        okButtonText: 'تأكيد',
        cancelButtonText: 'الغاء',
        onOkPressed: () {
          _deleteFavorite(context);
        },
        isWarning: true,
      );
    }
  }

  Future<void> _deleteFavorite(BuildContext context) async {
    if (_pendingDeleteFavorite == null || _pendingDeleteType == null) return;
    
    final favoriteToDelete = _pendingDeleteFavorite!;
    final typeToDelete = _pendingDeleteType!;
    
    try {
      // Immediately remove from UI for better UX
      _removeFromLocalList(favoriteToDelete);
      notifyListeners();
      
      final favoriteId = favoriteToDelete['favoritable']['id'];
      final type = typeToDelete == 'share' ? 'share' : 'apartment';
      
      final response = await ApiService.instance.delete('/favorites/$type/$favoriteId');
      
      if (response.statusCode != 200) {
        // If delete failed, add the item back to the list
        _addBackToLocalList(favoriteToDelete, typeToDelete);
        notifyListeners();
      }
    } catch (e) {
      Logger.log('حدث خطأ أثناء حذف العنصر من المفضلة: $e');
      // If delete failed, add the item back to the list
      _addBackToLocalList(favoriteToDelete, typeToDelete);
      notifyListeners();
    } finally {
      _pendingDeleteFavorite = null;
      _pendingDeleteType = null;
    }
  }
  
  void _removeFromLocalList(Map<String, dynamic> favorite) {
    if (currentTab == 0) {
      shareFavorites.removeWhere((item) => 
        item['favoritable']['id'] == favorite['favoritable']['id']);
    } else {
      apartmentFavorites.removeWhere((item) => 
        item['favoritable']['id'] == favorite['favoritable']['id']);
    }
  }
  
  void _addBackToLocalList(Map<String, dynamic> favorite, String type) {
    if (type == 'share' && currentTab == 0) {
      shareFavorites.add(favorite);
    } else if (type == 'apartment' && currentTab == 1) {
      apartmentFavorites.add(favorite);
    }
  }
} 