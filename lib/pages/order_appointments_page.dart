import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../stores/orders_store.dart';
import '../utils/navigation_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/custom_spinner.dart';

class OrderAppointmentsPage extends StatelessWidget {
  const OrderAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrdersStore(),
      child: const _OrderAppointmentsView(),
    );
  }
}

class _OrderAppointmentsView extends StatefulWidget {
  const _OrderAppointmentsView();

  @override
  State<_OrderAppointmentsView> createState() => _OrderAppointmentsViewState();
}

class _OrderAppointmentsViewState extends State<_OrderAppointmentsView> with TickerProviderStateMixin {
  late OrdersStore store;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    store = Provider.of<OrdersStore>(context, listen: false);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      store.setTab(_tabController.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F2),
        appBar: CustomAppBar(
          showBackButton: true,
          showFavoritesButton: true,
          showSearchButton: true,
          showHelpButton: true,
          showNotificationButton: true,
          showLogo: true,
          titleStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF633e3d),
            fontFamily: 'Cairo',
          ),
        ),
        body: Column(
          children: [
            Consumer<OrdersStore>(
              builder: (context, store, _) => _buildTabs(store),
            ),
            Expanded(
              child: Consumer<OrdersStore>(
                builder: (context, store, _) => _buildOrderList(store),
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 1, // Appointments tab
          onTap: (index) {
            // Navigation is handled by CustomBottomNavBar
          },
        ),
      ),
    );
  }

  Widget _buildTabs(OrdersStore store) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF633e3d),
        labelColor: const Color(0xFF633e3d),
        unselectedLabelColor: const Color(0xFFBDBDBD),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
        tabs: const [
          Tab(text: 'مواعيد الأسهم'),
          Tab(text: 'مواعيد العقارات'),
        ],
      ),
    );
  }

  Widget _buildOrderList(OrdersStore store) {
    if (store.isLoading) {
      return const Center(child: CustomSpinner(size: 50.0));
    }
    final orders = store.currentTab == 0 ? store.shareOrders : store.apartmentOrders;
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => store.loadOrders(force: true),
        color: const Color(0xFF633e3d),
        backgroundColor: const Color(0xFFF7F5F2),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(store.currentTab),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => store.loadOrders(force: true),
      color: const Color(0xFF633e3d),
      backgroundColor: const Color(0xFFF7F5F2),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            if (store.hasMoreData && !store.isLoadingMore) {
              store.loadMoreOrders();
            }
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: orders.length + (store.hasMoreData ? 1 : 0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          itemBuilder: (context, index) {
            if (index == orders.length) {
              // Show loading indicator at the bottom
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: store.isLoadingMore 
                    ? const CustomSpinner(size: 30.0)
                    : const SizedBox.shrink(),
                ),
              );
            }
            final order = orders[index];
            return _OrderListItem(
              order: order,
              type: store.currentTab == 0 ? 'share' : 'apartment',
              onDelete: () => store.confirmDelete(context, order, store.currentTab == 0 ? 'share' : 'apartment'),
              onTap: () => NavigationHelper.navigateToDetails(context, order['model_id'], store.currentTab == 0 ? 'share' : 'apartment'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(int tab) {
    final instructions = tab == 0
        ? 'يمكنك ترتيب موعد لعرض أو شراء أسهم تنظيمية من صفحة تفاصيل السهم، ثم التواصل مع فريق عقاري ومن ثم ترتيب موعد '
        : 'يمكنك ترتيب موعد لعرض أو شراء عقار من صفحة تفاصيل العقار ، ثم التواصل مع فريق عقاري ومن ثم ترتيب موعد';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/no_data.png', width: 120, height: 120),
            const SizedBox(height: 24),
            const Text(
              'لم تقم بترتيب مواعيد حتى الآن',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF633e3d)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              instructions,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Color(0xFF888888)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final Map<String, dynamic> order;
  final String type;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _OrderListItem({
    required this.order,
    required this.type,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sector = order['orderable']['sector'];
    final region = order['orderable']['region'];
    final coverImg = sector?['cover']?['img'] ?? '';
    final imageUrl = coverImg.isNotEmpty ? coverImg : 'assets/images/no_photo.jpg';
    final transactionType = order['orderable']['transaction_type'] == 'sell' ? 'نية بيع' : 'نية شراء';
    final sectorName = sector?['sector_name']?['name'] ?? '';
    final sectorCode = sector?['sector_name']?['code'] ?? '';
    final price = order['orderable']['price'].toString();
    final regionName = region?['name'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color.fromARGB(255, 231, 226, 219),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF633e3d)),
                                ),
                              ),
                            );
                          },
                  errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/no_photo.jpg', width: 72, height: 72, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$regionName - $transactionType', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('$sectorName - $sectorCode', style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Color(0xFF888888))),
                    const SizedBox(height: 4),
                    Text('السعر: $price', style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Color(0xFF633e3d))),
                  ],
                ),
              ),
              IconButton(
                icon: Image.asset(
                  'assets/images/icons/delete_icon.png', 
                  width: 28, 
                  height: 28,
                  color: Colors.red,
                ),
                onPressed: onDelete,
                tooltip: 'حذف',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 