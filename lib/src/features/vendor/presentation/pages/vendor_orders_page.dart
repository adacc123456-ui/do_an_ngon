import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/features/vendor/data/repositories/vendor_repository.dart';
import 'package:intl/intl.dart';

class VendorOrdersPage extends StatefulWidget {
  const VendorOrdersPage({super.key});

  @override
  State<VendorOrdersPage> createState() => _VendorOrdersPageState();
}

class _VendorOrdersPageState extends State<VendorOrdersPage> {
  final VendorRepository _vendorRepository = GetIt.I<VendorRepository>();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'pending';
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
      final orders = await _vendorRepository.getVendorOrders(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
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
          SnackBar(
            content: const Text('Không thể tải danh sách đơn hàng'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _vendorRepository.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái đơn hàng'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
        _loadOrders();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể cập nhật trạng thái'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
    }
  }

  Future<bool> _updateDeliveryEstimate({
    required String orderId,
    required int minMinutes,
    required int maxMinutes,
    int? preparationMinutes,
    String? note,
  }) async {
    try {
      await _vendorRepository.updateDeliveryEstimate(
        orderId: orderId,
        minMinutes: minMinutes,
        maxMinutes: maxMinutes,
        preparationTimeMinutes: preparationMinutes,
        note: note,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã cập nhật thời gian giao dự kiến'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
        _loadOrders();
      }
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể cập nhật thời gian giao dự kiến'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
      return false;
    }
  }

  void _showOrderDetail(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailSheet(
        order: order,
        onUpdateStatus: _updateOrderStatus,
        onUpdateEstimate: _updateDeliveryEstimate,
        getStatusText: _getStatusText,
        getStatusColor: _getStatusColor,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter buttons
        Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
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
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              return _OrderCard(
                                order: order,
                                onTap: () => _showOrderDetail(context, order),
                                getStatusText: _getStatusText,
                                getStatusColor: _getStatusColor,
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
        _loadOrders();
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textGrey,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13.sp,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.lightGrey,
          width: 1,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final String Function(String?) getStatusText;
  final Color Function(String?) getStatusColor;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.getStatusText,
    required this.getStatusColor,
  });

  String _formatPrice(dynamic price) {
    if (price == null) return '0 đ';
    final value = (price is int || price is double) ? price : double.tryParse(price.toString()) ?? 0;
    return '${value.toInt().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (_) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString();
    final customerName = order['deliveryAddress']?['recipientName']?.toString() ??
        'Khách hàng';
    final customerPhone = order['deliveryAddress']?['phone']?.toString() ??
        order['user']?['phone']?.toString() ??
        '';
    final orderId = order['_id']?.toString() ?? order['id']?.toString() ?? '';
    final total = order['total']?.toString() ??
        order['totalAmount']?.toString() ??
        order['charges']?['total']?.toString() ??
        '0';
    final items = order['items'] as List<dynamic>? ?? [];
    final itemCount = items.length;
    final createdAt = order['createdAt'];
    final deliveryAddress = order['deliveryAddress'] as Map<String, dynamic>?;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Order ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_long, size: 18.sp, color: AppColors.primary),
                              SizedBox(width: 6.w),
                              Text(
                                'Đơn #${orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId}',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                          if (createdAt != null) ...[
                            SizedBox(height: 4.h),
                            Text(
                              _formatDate(createdAt),
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
                        color: getStatusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: getStatusColor(status).withOpacity(0.3),
                          width: 1,
                        ),
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
                SizedBox(height: 16.h),
                Divider(height: 1, color: AppColors.lightGrey),
                SizedBox(height: 12.h),
                // Customer Info
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.person, size: 18.sp, color: AppColors.primary),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          if (customerPhone.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              customerPhone,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (deliveryAddress != null) ...[
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.location_on, size: 18.sp, color: Colors.green),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(
                            'Địa chỉ giao hàng',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${deliveryAddress['street'] ?? ''}, ${deliveryAddress['ward'] ?? ''}, ${deliveryAddress['district'] ?? ''}, ${deliveryAddress['city'] ?? ''}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 12.h),
                // Items preview
                if (items.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.restaurant_menu, size: 18.sp, color: Colors.orange),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$itemCount món',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            // Show first 2 items with images
                            ...items.take(2).map((item) {
                              final itemMap = item as Map<String, dynamic>;
                              final itemName = itemMap['name']?.toString() ?? 'Món ăn';
                              final quantity = itemMap['quantity'] ?? 1;
                              final imageUrl = itemMap['imageUrl']?.toString() ??
                                  itemMap['menuItem']?['imageUrl']?.toString();
                              return Padding(
                                padding: EdgeInsets.only(bottom: 6.h),
                                child: Row(
                                  children: [
                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      Container(
                                        width: 40.w,
                                        height: 40.w,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6.r),
                                          image: DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                            onError: (_, __) {},
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 40.w,
                                        height: 40.w,
                                        decoration: BoxDecoration(
                                          color: AppColors.lightGrey,
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Icon(Icons.fastfood, size: 20.sp, color: AppColors.grey),
                                      ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        '$itemName x$quantity',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: AppColors.textGrey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (items.length > 2)
                              Text(
                                '... và ${items.length - 2} món khác',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.primary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
                Divider(height: 1, color: AppColors.lightGrey),
                SizedBox(height: 12.h),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng tiền',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      _formatPrice(total),
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

class _OrderDetailSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final Future<void> Function(String, String) onUpdateStatus;
  final Future<bool> Function({
    required String orderId,
    required int minMinutes,
    required int maxMinutes,
    int? preparationMinutes,
    String? note,
  }) onUpdateEstimate;
  final String Function(String?) getStatusText;
  final Color Function(String?) getStatusColor;

  const _OrderDetailSheet({
    required this.order,
    required this.onUpdateStatus,
    required this.onUpdateEstimate,
    required this.getStatusText,
    required this.getStatusColor,
  });

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  bool _isUpdating = false;
  bool _isUpdatingEstimate = false;

  late final TextEditingController _minEstimateController;
  late final TextEditingController _maxEstimateController;
  late final TextEditingController _preparationController;
  late final TextEditingController _estimateNoteController;

  int? _currentMinEstimate;
  int? _currentMaxEstimate;
  int? _currentPreparationTime;
  String? _currentEstimateNote;

  @override
  void initState() {
    super.initState();
    final estimateData = widget.order['estimatedDeliveryTime'] as Map<String, dynamic>?;
    _currentMinEstimate = _parseInt(estimateData?['min'] ?? estimateData?['minimum']);
    _currentMaxEstimate = _parseInt(estimateData?['max'] ?? estimateData?['maximum']);
    _currentPreparationTime = _parseInt(widget.order['preparationTimeMinutes'] ?? widget.order['preparationTime']);
    _currentEstimateNote = widget.order['estimateNote']?.toString() ?? widget.order['vendorEstimateNote']?.toString();

    _minEstimateController = TextEditingController(
      text: (_currentMinEstimate ?? 25).toString(),
    );
    _maxEstimateController = TextEditingController(
      text: (_currentMaxEstimate ?? 40).toString(),
    );
    _preparationController = TextEditingController(
      text: _currentPreparationTime?.toString() ?? '',
    );
    _estimateNoteController = TextEditingController(
      text: _currentEstimateNote ?? '',
    );
  }

  @override
  void dispose() {
    _minEstimateController.dispose();
    _maxEstimateController.dispose();
    _preparationController.dispose();
    _estimateNoteController.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0 đ';
    final value = (price is int || price is double) ? price : double.tryParse(price.toString()) ?? 0;
    return '${value.toInt().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (_) {
      return date.toString();
    }
  }

  Future<void> _handleStatusUpdate(String status) async {
    setState(() => _isUpdating = true);
    final orderId = widget.order['_id']?.toString() ?? widget.order['id']?.toString() ?? '';
    await widget.onUpdateStatus(orderId, status);
    if (mounted) {
      Navigator.pop(context);
    }
    setState(() => _isUpdating = false);
  }

  Future<void> _handleEstimateUpdate() async {
    final minText = _minEstimateController.text.trim();
    final maxText = _maxEstimateController.text.trim();
    final prepText = _preparationController.text.trim();
    final noteText = _estimateNoteController.text.trim();

    final minValue = int.tryParse(minText);
    final maxValue = int.tryParse(maxText);
    final prepValue = prepText.isEmpty ? null : int.tryParse(prepText);

    if (minValue == null || minValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập thời gian tối thiểu hợp lệ')),
      );
      return;
    }

    if (maxValue == null || maxValue < minValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian tối đa phải lớn hơn tối thiểu')),
      );
      return;
    }

    if (prepText.isNotEmpty && prepValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian chuẩn bị phải là số phút hợp lệ')),
      );
      return;
    }

    setState(() => _isUpdatingEstimate = true);
    final orderId = widget.order['_id']?.toString() ?? widget.order['id']?.toString() ?? '';
    final success = await widget.onUpdateEstimate(
      orderId: orderId,
      minMinutes: minValue,
      maxMinutes: maxValue,
      preparationMinutes: prepValue,
      note: noteText.isNotEmpty ? noteText : null,
    );

    if (success && mounted) {
      setState(() {
        _currentMinEstimate = minValue;
        _currentMaxEstimate = maxValue;
        _currentPreparationTime = prepValue;
        _currentEstimateNote = noteText.isNotEmpty ? noteText : null;
      });
    }

    if (mounted) {
      setState(() => _isUpdatingEstimate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status']?.toString() ?? 'pending';
    final customerName = widget.order['deliveryAddress']?['recipientName']?.toString()  ??
        'Khách hàng';
    final customerPhone = widget.order['deliveryAddress']?['phone']?.toString() ??
        '';
    final orderId = widget.order['_id']?.toString() ?? widget.order['id']?.toString() ?? '';
    final items = widget.order['items'] as List<dynamic>? ?? [];
    final charges = widget.order['charges'] as Map<String, dynamic>?;
    final deliveryAddress = widget.order['deliveryAddress'] as Map<String, dynamic>?;
    final createdAt = widget.order['createdAt'];
    final paymentMethod = widget.order['payment']?['method']?.toString() ?? 'COD';
    final estimateSection = _buildEstimateSection(status);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chi tiết đơn hàng',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Đơn #${orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: widget.getStatusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: widget.getStatusColor(status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.getStatusText(status),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: widget.getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Info
                      _buildSection(
                        icon: Icons.person,
                        iconColor: AppColors.primary,
                        title: 'Thông tin khách hàng',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            if (customerPhone.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 16.sp, color: AppColors.textGrey),
                                  SizedBox(width: 6.w),
                                  Text(
                                    customerPhone,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Delivery Address
                      if (deliveryAddress != null)
                        _buildSection(
                          icon: Icons.location_on,
                          iconColor: Colors.green,
                          title: 'Địa chỉ giao hàng',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // if (deliveryAddress['recipientName'] != null)
                              //   Text(
                              //     deliveryAddress['recipientName'].toString(),
                              //     style: TextStyle(
                              //       fontSize: 15.sp,
                              //       fontWeight: FontWeight.w600,
                              //       color: AppColors.black,
                              //     ),
                              //   ),
                              // SizedBox(height: 6.h),
                              Text(
                                '${deliveryAddress['street'] ?? ''}, ${deliveryAddress['ward'] ?? ''}, ${deliveryAddress['district'] ?? ''}, ${deliveryAddress['city'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              if (deliveryAddress['phone'] != null) ...[
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 16.sp, color: AppColors.textGrey),
                                    SizedBox(width: 6.w),
                                    Text(
                                      deliveryAddress['phone'].toString(),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (deliveryAddress != null) SizedBox(height: 16.h),
                      // Order Items
                      _buildSection(
                        icon: Icons.restaurant_menu,
                        iconColor: Colors.orange,
                        title: 'Sản phẩm',
                        child: Column(
                          children: items.map((item) {
                            final itemMap = item as Map<String, dynamic>;
                            final itemName = itemMap['name']?.toString() ??
                                itemMap['menuItem']?['name']?.toString() ??
                                'Món ăn';
                            final quantity = itemMap['quantity'] ?? 1;
                            final price = itemMap['totalPrice'] ??
                                itemMap['price'] ??
                                itemMap['menuItem']?['price'] ??
                                0;
                            final imageUrl = itemMap['imageUrl']?.toString() ??
                                itemMap['menuItem']?['imageUrl']?.toString();
                            final notes = itemMap['notes']?.toString();
                            final selectedOptions = itemMap['selectedOptions'] as List<dynamic>?;

                            return Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: AppColors.lightGrey, width: 1),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  Container(
                                    width: 70.w,
                                    height: 70.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.r),
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
                                        ? Icon(Icons.fastfood, size: 30.sp, color: AppColors.grey)
                                        : null,
                                  ),
                                  SizedBox(width: 12.w),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemName,
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          'Số lượng: $quantity',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                        if (selectedOptions != null && selectedOptions.isNotEmpty) ...[
                                          SizedBox(height: 4.h),
                                          ...selectedOptions.map((option) {
                                            final optMap = option as Map<String, dynamic>? ?? {};
                                            return Text(
                                              '• ${optMap['name'] ?? ''}',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: AppColors.textGrey,
                                              ),
                                            );
                                          }),
                                        ],
                                        if (notes != null && notes.isNotEmpty) ...[
                                          SizedBox(height: 4.h),
                                          Text(
                                            'Ghi chú: $notes',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: AppColors.primary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                        SizedBox(height: 6.h),
                                        Text(
                                          _formatPrice(price),
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Charges
                      if (charges != null)
                        _buildSection(
                          icon: Icons.receipt,
                          iconColor: Colors.blue,
                          title: 'Tổng tiền',
                          child: Column(
                            children: [
                              _buildChargeRow('Tạm tính', charges['subtotal']),
                              if ((charges['deliveryFee'] as num? ?? 0) > 0)
                                _buildChargeRow('Phí giao hàng', charges['deliveryFee']),
                              if ((charges['discount'] as num? ?? 0) > 0)
                                _buildChargeRow('Giảm giá', charges['discount'], isDiscount: true),
                              Divider(height: 24.h),
                              _buildChargeRow('Tổng cộng', charges['total'], isTotal: true),
                            ],
                          ),
                        ),
                      if (charges != null) SizedBox(height: 16.h),
                      // Payment Method
                      _buildSection(
                        icon: Icons.payment,
                        iconColor: Colors.purple,
                        title: 'Phương thức thanh toán',
                        child: Text(
                          paymentMethod == 'COD' ? 'Thanh toán khi nhận hàng' : paymentMethod,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      if (estimateSection != null) ...[
                        estimateSection,
                        SizedBox(height: 16.h),
                      ],
                      // Order Date
                      if (createdAt != null)
                        _buildSection(
                          icon: Icons.access_time,
                          iconColor: Colors.grey,
                          title: 'Thời gian đặt hàng',
                          child: Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildActionButtons(status),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 20.sp, color: iconColor),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildChargeRow(String label, dynamic amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.black : AppColors.textGrey,
            ),
          ),
          Text(
            isDiscount ? '-${_formatPrice(amount)}' : _formatPrice(amount),
            style: TextStyle(
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : (isDiscount ? Colors.green : AppColors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildEstimateSection(String status) {
    final canEdit = status == 'pending' || status == 'confirmed';
    final hasEstimateData = _currentMinEstimate != null && _currentMaxEstimate != null;
    final hasAdditionalInfo = _currentPreparationTime != null || (_currentEstimateNote?.isNotEmpty ?? false);

    if (!canEdit && !hasEstimateData && !hasAdditionalInfo) {
      return null;
    }

    return _buildSection(
      icon: Icons.timer,
      iconColor: Colors.teal,
      title: 'Thời gian giao dự kiến',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEstimateSummary(hasEstimateData || hasAdditionalInfo),
          if (canEdit) ...[
            SizedBox(height: 16.h),
            Text(
              'Chỉnh sửa ước tính trước khi xác nhận',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _buildEstimateNumberField(
                    label: 'Tối thiểu (phút)',
                    controller: _minEstimateController,
                    hintText: '25',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildEstimateNumberField(
                    label: 'Tối đa (phút)',
                    controller: _maxEstimateController,
                    hintText: '40',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildEstimateNumberField(
              label: 'Thời gian chuẩn bị (phút)',
              controller: _preparationController,
              hintText: '15',
              helperText: 'Tùy chọn - giúp khách hiểu tiến độ bếp',
            ),
            SizedBox(height: 12.h),
            _buildEstimateNoteField(),
            SizedBox(height: 12.h),
            _buildEstimateSuggestions(),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdatingEstimate ? null : _handleEstimateUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: _isUpdatingEstimate
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_outlined),
                          SizedBox(width: 8.w),
                          const Text('Cập nhật thời gian giao'),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstimateSummary(bool hasData) {
    final min = _currentMinEstimate;
    final max = _currentMaxEstimate;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                hasData ? '' : 'Chưa có thời gian dự kiến',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (hasData && min != null && max != null) ...[
            Text(
              'Giao trong khoảng $min - $max phút',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ] else ...[
            Text(
              'Hãy đặt khoảng thời gian giao để khách chuẩn bị nhận hàng.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textGrey,
              ),
            ),
          ],
          if (_currentPreparationTime != null) ...[
            SizedBox(height: 6.h),
            Text(
              'Thời gian chuẩn bị: $_currentPreparationTime phút',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textGrey),
            ),
          ],
          if (_currentEstimateNote?.isNotEmpty ?? false) ...[
            SizedBox(height: 6.h),
            Text(
              'Ghi chú: ${_currentEstimateNote!}',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstimateNumberField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppColors.lightGrey.withOpacity(0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: 4.h),
          Text(
            helperText,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
          ),
        ],
      ],
    );
  }

  Widget _buildEstimateNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông báo cho khách (tùy chọn)',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: _estimateNoteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ví dụ: Giao sau giờ cao điểm nên có thể chậm vài phút',
            filled: true,
            fillColor: AppColors.lightGrey.withOpacity(0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimateSuggestions() {
    final presets = [
      {'label': '20 - 30 phút', 'min': 20, 'max': 30},
      {'label': '25 - 40 phút', 'min': 25, 'max': 40},
      {'label': '30 - 50 phút', 'min': 30, 'max': 50},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thiết lập nhanh',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: presets.map((preset) {
            return ActionChip(
              label: Text(preset['label'].toString()),
              onPressed: () {
                setState(() {
                  _minEstimateController.text = preset['min'].toString();
                  _maxEstimateController.text = preset['max'].toString();
                });
              },
              backgroundColor: AppColors.white,
              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              labelStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String status) {
    if (_isUpdating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleStatusUpdate('cancelled'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Từ chối',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _handleStatusUpdate('confirmed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Nhận đơn',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'confirmed') {
      return ElevatedButton(
        onPressed: () => _handleStatusUpdate('preparing'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          minimumSize: Size(double.infinity, 50.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Bắt đầu chuẩn bị',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'preparing') {
      return ElevatedButton(
        onPressed: () => _handleStatusUpdate('delivering'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          minimumSize: Size(double.infinity, 50.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Bắt đầu giao hàng',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'delivering') {
      return ElevatedButton(
        onPressed: () => _handleStatusUpdate('delivered'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          minimumSize: Size(double.infinity, 50.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Hoàn thành đơn hàng',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
