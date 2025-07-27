import 'package:flutter/material.dart';
import '../data/repositories/share_repository.dart';
import '../data/repositories/apartment_repository.dart';
import '../utils/logger.dart';
import '../widgets/custom_dialog.dart';
import '../services/api_service.dart';

class OrdersStore extends ChangeNotifier {
  int currentTab = 0; // 0: shares, 1: apartments
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isDeleting = false;
  List<Map<String, dynamic>> shareOrders = [];
  List<Map<String, dynamic>> apartmentOrders = [];
  Map<String, dynamic>? _pendingDeleteOrder;
  String? _pendingDeleteType;
  
  // Pagination variables
  int shareCurrentPage = 1;
  int apartmentCurrentPage = 1;
  bool shareHasMore = true;
  bool apartmentHasMore = true;

  final ShareRepository _shareRepo = ShareRepository();
  final ApartmentRepository _apartmentRepo = ApartmentRepository();

  void setTab(int tab) {
    if (currentTab != tab) {
      currentTab = tab;
      // Reset pagination for the new tab and force reload
      if (tab == 0) {
        shareCurrentPage = 1;
        shareHasMore = true;
        shareOrders.clear();
      } else {
        apartmentCurrentPage = 1;
        apartmentHasMore = true;
        apartmentOrders.clear();
      }
      loadOrders(force: true);
      notifyListeners();
    }
  }

  Future<void> loadOrders({bool force = false}) async {
    if (force) {
      // Reset pagination when forcing refresh
      shareCurrentPage = 1;
      apartmentCurrentPage = 1;
      shareHasMore = true;
      apartmentHasMore = true;
      shareOrders.clear();
      apartmentOrders.clear();
    }
    
    isLoading = true;
    notifyListeners();
    try {
      if (currentTab == 0) {
        final response = await ApiService.instance.get('/share/orders/list', queryParameters: {'page': shareCurrentPage});
        final newOrders = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        if (force) {
          shareOrders = newOrders;
        } else {
          shareOrders.addAll(newOrders);
        }
        shareHasMore = response.data['next_page_url'] != null;
      } else {
        final response = await ApiService.instance.get('/apartment/orders/list', queryParameters: {'page': apartmentCurrentPage});
        final newOrders = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        if (force) {
          apartmentOrders = newOrders;
        } else {
          apartmentOrders.addAll(newOrders);
        }
        apartmentHasMore = response.data['next_page_url'] != null;
      }
    } catch (e) {
      Logger.log('حدث خطأ أثناء تحميل المواعيد: $e');
      if (currentTab == 0) shareOrders = [];
      if (currentTab == 1) apartmentOrders = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreOrders() async {
    if (isLoadingMore) return;
    
    if (currentTab == 0 && !shareHasMore) return;
    if (currentTab == 1 && !apartmentHasMore) return;
    
    isLoadingMore = true;
    notifyListeners();
    
    try {
      if (currentTab == 0) {
        shareCurrentPage++;
        final response = await ApiService.instance.get('/share/orders/list', queryParameters: {'page': shareCurrentPage});
        final newOrders = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        shareOrders.addAll(newOrders);
        shareHasMore = response.data['next_page_url'] != null;
      } else {
        apartmentCurrentPage++;
        final response = await ApiService.instance.get('/apartment/orders/list', queryParameters: {'page': apartmentCurrentPage});
        final newOrders = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        apartmentOrders.addAll(newOrders);
        apartmentHasMore = response.data['next_page_url'] != null;
      }
    } catch (e) {
      Logger.log('حدث خطأ أثناء تحميل المزيد من المواعيد: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  bool get hasMoreData => currentTab == 0 ? shareHasMore : apartmentHasMore;

  Future<void> confirmDelete(BuildContext context, Map<String, dynamic> order, String type) async {
    _pendingDeleteOrder = order;
    _pendingDeleteType = type;
    await showCustomDialog(
      context: context,
      title: 'تأكيد الإلغاء',
      message: 'هل أنت متأكد من إلغاء الموعد؟',
      okButtonText: 'تأكيد',
      cancelButtonText: 'الغاء',
      onOkPressed: () {
        _deleteOrder(context);
      },
      isWarning: true,
    );
  }

  Future<void> _deleteOrder(BuildContext context) async {
    if (_pendingDeleteOrder == null || _pendingDeleteType == null) return;
    
    final orderToDelete = _pendingDeleteOrder!;
    final typeToDelete = _pendingDeleteType!;
    
    try {
      // Immediately remove from UI for better UX
      _removeFromLocalList(orderToDelete);
      notifyListeners();
      
      final orderId = orderToDelete['id'];
      Map<String, dynamic> result;
      if (typeToDelete == 'share') {
        result = await _shareRepo.cancelOrder(orderId);
      } else {
        result = await _apartmentRepo.cancelOrder(orderId);
      }
      
      if (result['success'] != true) {
        // If delete failed, add the item back to the list
        _addBackToLocalList(orderToDelete, typeToDelete);
        notifyListeners();
      }
    } catch (e) {
      Logger.log('حدث خطأ أثناء حذف الموعد: $e');
      // If delete failed, add the item back to the list
      _addBackToLocalList(orderToDelete, typeToDelete);
      notifyListeners();
    } finally {
      _pendingDeleteOrder = null;
      _pendingDeleteType = null;
    }
  }
  
  void _removeFromLocalList(Map<String, dynamic> order) {
    final orderId = order['id'];
    
    if (currentTab == 0) {
      shareOrders.removeWhere((item) => item['id'] == orderId);
    } else {
      apartmentOrders.removeWhere((item) => item['id'] == orderId);
    }
  }
  
  void _addBackToLocalList(Map<String, dynamic> order, String type) {
    if (type == 'share' && currentTab == 0) {
      shareOrders.add(order);
    } else if (type == 'apartment' && currentTab == 1) {
      apartmentOrders.add(order);
    }
  }
} 