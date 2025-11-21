import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/features/orders/data/repositories/order_repository.dart';
import 'package:do_an_ngon/src/features/home/presentation/widgets/bottom_navigation_bar.dart' as home;

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderRepository _orderRepository = GetIt.I<OrderRepository>();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedStatus; // null = all, 'pending', 'confirmed', etc.
  Timer? _autoRefreshTimer;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      _loadOrders(showLoading: false);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool showLoading = true}) async {
    if (_isFetching) return;
    if (!mounted) return;
    _isFetching = true;

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _orderRepository.getOrders(
        status: _selectedStatus,
        limit: 50,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final items = data?['items'] as List<dynamic>? ?? [];

      if (!mounted) return;
      setState(() {
        _orders = items.map((item) => item as Map<String, dynamic>).toList();
        if (showLoading) {
          _isLoading = false;
        }
        _errorMessage = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _errorMessage = 'Không thể tải danh sách đơn hàng';
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải danh sách đơn hàng'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'delivering':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status ?? 'Không xác định';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'delivering':
        return Colors.cyan;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatPrice(num? price) {
    if (price == null) return '0 đ';
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    ) + ' đ';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: 'Đơn hàng',
        showBackButton: false,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            color: AppColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Tất cả'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('pending', 'Chờ xác nhận'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('confirmed', 'Đã xác nhận'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('preparing', 'Đang chuẩn bị'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('delivering', 'Đang giao'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('delivered', 'Đã giao'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('cancelled', 'Đã hủy'),
                ],
              ),
            ),
          ),
          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64.sp, color: AppColors.grey),
                            SizedBox(height: 16.h),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.textGrey, fontSize: 16.sp),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 80.sp, color: AppColors.grey),
                                SizedBox(height: 16.h),
                                Text(
                                  'Chưa có đơn hàng',
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadOrders(showLoading: false),
                            child: ListView.builder(
                              padding: EdgeInsets.all(16.w),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                final order = _orders[index];
                                return _OrderCard(
                                  order: order,
                                  onTap: () {
                                    final orderId = order['_id']?.toString() ?? order['id']?.toString() ?? '';
                                    if (orderId.isNotEmpty) {
                                      context.push('/orders/$orderId');
                                    }
                                  },
                                  getStatusText: _getStatusText,
                                  getStatusColor: _getStatusColor,
                                  formatPrice: _formatPrice,
                                  formatDate: _formatDate,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: const home.HomeBottomNavigationBar(currentIndex: 3),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status || (status == 'all' && _selectedStatus == null);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status == 'all' ? null : status;
        });
        _loadOrders();
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textGrey,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final String Function(String?) getStatusText;
  final Color Function(String?) getStatusColor;
  final String Function(num?) formatPrice;
  final String Function(String?) formatDate;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.getStatusText,
    required this.getStatusColor,
    required this.formatPrice,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString();
    final orderId = order['_id']?.toString() ?? order['id']?.toString() ?? '';
    final charges = order['charges'] as Map<String, dynamic>? ?? {};
    final total = charges['total'] as num? ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];
    final createdAt = order['createdAt']?.toString();
    final restaurant = order['restaurant'] as Map<String, dynamic>?;
    // Use restaurantName field first, fallback to restaurant.name
    final restaurantName = order['restaurantName']?.toString() ??
        restaurant?['name']?.toString() ??
        'Nhà hàng';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Order ID, Date, Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đơn #${orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          if (createdAt != null) ...[
                            SizedBox(height: 4.h),
                            Text(
                              formatDate(createdAt),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        getStatusText(status),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Restaurant Name
                Row(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        restaurantName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Order Items
                if (items.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sản phẩm',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...items.take(3).map((item) {
                          final itemMap = item as Map<String, dynamic>;
                          final itemName = itemMap['name']?.toString() ??
                              itemMap['menuItem']?['name']?.toString() ??
                              'Món ăn';
                          final quantity = itemMap['quantity'] ?? 1;
                          final imageUrl = itemMap['imageUrl']?.toString() ??
                              itemMap['menuItem']?['imageUrl']?.toString();
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              children: [
                                // Item Image
                                Container(
                                  width: 50.w,
                                  height: 50.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.r),
                                    color: AppColors.lightGrey,
                                    image: imageUrl != null && imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                            onError: (_, __) {},
                                          )
                                        : null,
                                  ),
                                  child: imageUrl == null || imageUrl.isEmpty
                                      ? Icon(
                                          Icons.fastfood,
                                          size: 24.sp,
                                          color: AppColors.grey,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 12.w),
                                // Item Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        itemName,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Số lượng: $quantity',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (items.length > 3) ...[
                          SizedBox(height: 4.h),
                          Text(
                            'và ${items.length - 3} món khác...',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
                // Total Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng tiền',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      formatPrice(total),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

