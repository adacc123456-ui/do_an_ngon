import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:do_an_ngon/src/features/home/data/repositories/restaurant_repository.dart';
import 'package:do_an_ngon/src/features/vendor/data/repositories/vendor_repository.dart';
import 'package:do_an_ngon/src/features/vendor/presentation/pages/vendor_orders_page.dart';
import 'package:do_an_ngon/src/features/vendor/presentation/pages/vendor_products_page.dart';

class VendorDashboardPage extends StatefulWidget {
  const VendorDashboardPage({super.key});

  @override
  State<VendorDashboardPage> createState() => _VendorDashboardPageState();
}

class _VendorDashboardPageState extends State<VendorDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VendorRepository _vendorRepository = GetIt.I<VendorRepository>();
  final RestaurantRepository _restaurantRepository = GetIt.I<RestaurantRepository>();
  
  bool _isAcceptingOrders = false; // Trạng thái nhận đơn hàng
  bool _isLoadingStatus = true; // Đang load trạng thái
  String? _selectedRestaurantId; // ID nhà hàng đang được quản lý

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAcceptingOrdersStatus();
  }

  /// Load trạng thái nhận đơn từ nhà hàng đầu tiên
  Future<void> _loadAcceptingOrdersStatus() async {
    final authState = context.read<AuthBloc>().state;
    final managedRestaurants = authState.userProfile?['managedRestaurants'] as List<dynamic>?;
    
    if (managedRestaurants == null || managedRestaurants.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
      return;
    }

    // Lấy ID nhà hàng đầu tiên
    final firstRestaurantId = managedRestaurants.first;
    String? restaurantId;
    if (firstRestaurantId is String) {
      restaurantId = firstRestaurantId;
    } else if (firstRestaurantId is Map<String, dynamic>) {
      restaurantId = firstRestaurantId['_id']?.toString() ?? firstRestaurantId['id']?.toString();
    }

    if (restaurantId == null || restaurantId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
      return;
    }

    setState(() {
      _selectedRestaurantId = restaurantId;
    });

    try {
      final restaurant = await _restaurantRepository.getRestaurantDetail(restaurantId);
      if (mounted) {
        setState(() {
          _isAcceptingOrders = restaurant.isAcceptingOrders ?? true;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAcceptingOrders = true; // Default to true if can't load
          _isLoadingStatus = false;
        });
      }
    }
  }

  /// Toggle trạng thái nhận đơn hàng
  Future<void> _toggleAcceptingOrders() async {
    if (_selectedRestaurantId == null || _selectedRestaurantId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy nhà hàng để cập nhật'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newStatus = !_isAcceptingOrders;
    
    // Optimistic update
    setState(() {
      _isAcceptingOrders = newStatus;
    });

    try {
      await _vendorRepository.updateAcceptingOrders(
        restaurantId: _selectedRestaurantId!,
        isAcceptingOrders: newStatus,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Đã bật nhận đơn hàng' : 'Đã tắt nhận đơn hàng',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } on ApiException catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isAcceptingOrders = !newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isAcceptingOrders = !newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật trạng thái. Vui lòng thử lại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState.userProfile?['name']?.toString() ?? 
                     authState.userName ?? 
                     'Nhà hàng';

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: 'Quản lý nhà hàng',
        showBackButton: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.white),
              onPressed: () {
                context.go('/vendor-account-information');
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.white),
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutEvent());
                context.go('/login');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header với tên người dùng và nút bật/tắt
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.restaurant,
                        color: AppColors.white,
                        size: 30.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào,',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textGrey,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                // Nút bật/tắt nhận đơn hàng
                GestureDetector(
                  onTap: _isLoadingStatus ? null : _toggleAcceptingOrders,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    decoration: BoxDecoration(
                      color: _isAcceptingOrders ? Colors.green : (Colors.grey[300] ?? Colors.grey),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: (_isAcceptingOrders ? Colors.green : Colors.grey)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoadingStatus
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Text(
                                'Đang tải...',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60.w,
                                height: 60.w,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isAcceptingOrders ? Icons.check_circle : Icons.cancel,
                                  color: _isAcceptingOrders ? Colors.green : Colors.grey,
                                  size: 30.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Text(
                                _isAcceptingOrders ? 'Đang nhận đơn hàng' : 'Tạm dừng nhận đơn',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text('Đơn hàng', style: TextStyle(fontSize: 16.sp)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text('Sản phẩm', style: TextStyle(fontSize: 16.sp)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                VendorOrdersPage(),
                VendorProductsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

