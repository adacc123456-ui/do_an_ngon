import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/features/orders/data/repositories/order_repository.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderRepository _orderRepository = GetIt.I<OrderRepository>();
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _timeline = [];
  bool _isLoading = true;
  bool _isLoadingTimeline = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
    _loadTimeline();
  }

  Future<void> _loadOrderDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final order = await _orderRepository.getOrderDetail(widget.orderId);
      final data = order['data'] as Map<String, dynamic>? ?? order;
      
      if (!mounted) return;
      setState(() {
        _order = data;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải chi tiết đơn hàng';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTimeline() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTimeline = true;
    });

    try {
      final timeline = await _orderRepository.getOrderTimeline(widget.orderId);
      if (!mounted) return;
      setState(() {
        _timeline = timeline;
        _isLoadingTimeline = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingTimeline = false;
      });
    }
  }

  bool _isConfirming = false;

  Future<void> _confirmDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Xác nhận nhận hàng',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        content: Text(
          'Bạn đã nhận được đơn hàng? Sau khi xác nhận, bạn có thể đánh giá nhà hàng và món ăn.',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Xác nhận',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isConfirming = true);

    try {
      await _orderRepository.confirmDelivery(widget.orderId);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xác nhận nhận hàng thành công!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          action: SnackBarAction(
            label: 'Đánh giá',
            textColor: Colors.white,
            onPressed: () async {
              final result = await context.push(
                '/orders/${widget.orderId}/review',
                extra: _order,
              );
              if (result == true && mounted) {
                _loadOrderDetail();
              }
            },
          ),
        ),
      );
      
      _loadOrderDetail();
      _loadTimeline();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xác nhận nhận hàng. Vui lòng thử lại.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _orderRepository.cancelOrder(orderId: widget.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy đơn hàng thành công'),
          backgroundColor: AppColors.primary,
        ),
      );
      _loadOrderDetail();
      _loadTimeline();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể hủy đơn hàng. Vui lòng thử lại.'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
        title: 'Chi tiết đơn hàng',
        showBackButton: true,
      ),
      body: _isLoading
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
                        onPressed: _loadOrderDetail,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Không tìm thấy đơn hàng'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Card
                          Container(
                            margin: EdgeInsets.all(16.w),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_order!['status']?.toString())
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag,
                                    color: _getStatusColor(_order!['status']?.toString()),
                                    size: 24.sp,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getStatusText(_order!['status']?.toString()),
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Đơn #${widget.orderId.length > 6 ? widget.orderId.substring(widget.orderId.length - 6) : widget.orderId}',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Restaurant Info
                          Builder(
                            builder: (context) {
                              final restaurant = _order!['restaurant'] as Map<String, dynamic>?;
                              final restaurantName = _order!['restaurantName']?.toString() ??
                                  restaurant?['name']?.toString() ??
                                  'Nhà hàng';
                              final restaurantImage = restaurant?['heroImage']?.toString();
                              
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 16.w),
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  children: [
                                    // Restaurant Image
                                    if (restaurantImage != null && restaurantImage.isNotEmpty)
                                      Container(
                                        width: 60.w,
                                        height: 60.w,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8.r),
                                          image: DecorationImage(
                                            image: NetworkImage(restaurantImage),
                                            fit: BoxFit.cover,
                                            onError: (_, __) {},
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 60.w,
                                        height: 60.w,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8.r),
                                          color: AppColors.lightGrey,
                                        ),
                                        child: Icon(
                                          Icons.restaurant,
                                          size: 30.sp,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    SizedBox(width: 12.w),
                                    // Restaurant Name
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nhà hàng',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: AppColors.textGrey,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            restaurantName,
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.black,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16.h),
                          // Items
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 16.w),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Món đã đặt',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                ...((_order!['items'] as List<dynamic>? ?? []).map((item) {
                                  final itemMap = item as Map<String, dynamic>;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 60.w,
                                          height: 60.w,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8.r),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                itemMap['imageUrl']?.toString() ??
                                                    'assets/images/monan.png',
                                              ),
                                              fit: BoxFit.cover,
                                              onError: (_, __) {},
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                itemMap['name']?.toString() ?? '',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                'Số lượng: ${itemMap['quantity'] ?? 1}',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: AppColors.textGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatPrice(itemMap['totalPrice'] ?? itemMap['price']),
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Charges
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 16.w),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tổng tiền',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _buildChargeRow('Tạm tính', _order!['charges']?['subtotal']),
                                _buildChargeRow('Phí giao hàng', _order!['charges']?['deliveryFee']),
                                if ((_order!['charges']?['discount'] as num? ?? 0) > 0)
                                  _buildChargeRow('Giảm giá', _order!['charges']?['discount'], isDiscount: true),
                                Divider(height: 24.h),
                                _buildChargeRow('Tổng cộng', _order!['charges']?['total'], isTotal: true),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Delivery Address
                          if (_order!['deliveryAddress'] != null)
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 16.w),
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 20.sp, color: AppColors.primary),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Địa chỉ giao hàng',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  _buildAddressInfo(_order!['deliveryAddress'] as Map<String, dynamic>),
                                ],
                              ),
                            ),
                          SizedBox(height: 16.h),
                          // Timeline
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 16.w),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tiến trình đơn hàng',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _isLoadingTimeline
                                    ? const Center(child: CircularProgressIndicator())
                                    : _timeline.isEmpty
                                        ? Text(
                                            'Chưa có thông tin',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: AppColors.textGrey,
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: _timeline.asMap().entries.map((entry) {
                                              final index = entry.key;
                                              final item = entry.value;
                                              final isLast = index == _timeline.length - 1;
                                              return _TimelineItem(
                                                status: item['status']?.toString(),
                                                note: item['note']?.toString(),
                                                createdAt: item['createdAt']?.toString(),
                                                isLast: isLast,
                                                getStatusText: _getStatusText,
                                                getStatusColor: _getStatusColor,
                                                formatDate: _formatDate,
                                              );
                                            }).toList(),
                                          ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Action buttons
                          if (_order!['status']?.toString() == 'delivering')
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isConfirming ? null : _confirmDelivery,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(vertical: 16.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    disabledBackgroundColor: Colors.grey,
                                  ),
                                  child: _isConfirming
                                      ? SizedBox(
                                          height: 20.h,
                                          width: 20.w,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle, size: 20.sp, color: AppColors.white),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Xác nhận đã nhận hàng',
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          if (_order!['status']?.toString() != 'delivered' &&
                              _order!['status']?.toString() != 'cancelled' &&
                              _order!['status']?.toString() != 'delivering')
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _cancelOrder,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    padding: EdgeInsets.symmetric(vertical: 16.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: Text(
                                    'Hủy đơn hàng',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Review Section
                          if (_order!['status']?.toString() == 'delivered') ...[
                            // Check if order has review
                            Builder(
                              builder: (context) {
                                final hasReview = _order!['hasReview'] as bool? ?? false;
                                final review = _order!['review'] as Map<String, dynamic>?;
                                
                                if (hasReview && review != null) {
                                  // Show review status
                                  final restaurantReview = review['restaurant'] as Map<String, dynamic>?;
                                  final itemsReview = review['items'] as Map<String, dynamic>? ?? {};
                                  
                                  return Container(
                                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 24.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Đã đánh giá',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (restaurantReview != null) ...[
                                          SizedBox(height: 12.h),
                                          Row(
                                            children: [
                                              ...List.generate(5, (index) {
                                                final rating = restaurantReview['rating'] as int? ?? 5;
                                                return Icon(
                                                  index < rating ? Icons.star : Icons.star_border,
                                                  size: 16.sp,
                                                  color: Colors.amber,
                                                );
                                              }),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Text(
                                                  'Nhà hàng',
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    color: AppColors.textGrey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (restaurantReview['comment'] != null &&
                                              restaurantReview['comment'].toString().isNotEmpty) ...[
                                            SizedBox(height: 8.h),
                                            Text(
                                              restaurantReview['comment'].toString(),
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: AppColors.textGrey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ],
                                        if (itemsReview.isNotEmpty) ...[
                                          SizedBox(height: 12.h),
                                          Text(
                                            'Đã đánh giá ${itemsReview.length} món ăn',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: AppColors.textGrey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                } else {
                                  // Show review button
                                  return SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final result = await context.push(
                                          '/orders/${widget.orderId}/review',
                                          extra: _order,
                                        );
                                        if (result == true && mounted) {
                                          // Reload order detail after review
                                          _loadOrderDetail();
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 16.h),
                                        side: BorderSide(color: AppColors.primary, width: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.star, size: 20.sp, color: AppColors.primary),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Đánh giá đơn hàng',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildChargeRow(String label, dynamic value, {bool isTotal = false, bool isDiscount = false}) {
    final price = value is num ? value : 0;
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
              color: AppColors.black,
            ),
          ),
          Text(
            isDiscount ? '-${_formatPrice(price)}' : _formatPrice(price),
            style: TextStyle(
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInfo(Map<String, dynamic> address) {
    final parts = <String>[];
    if (address['recipientName'] != null) parts.add(address['recipientName'].toString());
    if (address['phone'] != null) parts.add(address['phone'].toString());
    if (address['street'] != null) parts.add(address['street'].toString());
    if (address['ward'] != null) parts.add(address['ward'].toString());
    if (address['district'] != null) parts.add(address['district'].toString());
    if (address['city'] != null) parts.add(address['city'].toString());
    
    return Text(
      parts.join(', '),
      style: TextStyle(
        fontSize: 14.sp,
        color: AppColors.textGrey,
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String? status;
  final String? note;
  final String? createdAt;
  final bool isLast;
  final String Function(String?) getStatusText;
  final Color Function(String?) getStatusColor;
  final String Function(String?) formatDate;

  const _TimelineItem({
    required this.status,
    required this.note,
    required this.createdAt,
    required this.isLast,
    required this.getStatusText,
    required this.getStatusColor,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: getStatusColor(status),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 40.h,
                color: AppColors.lightGrey,
              ),
          ],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getStatusText(status),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                if (note != null && note!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    note!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                if (createdAt != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

