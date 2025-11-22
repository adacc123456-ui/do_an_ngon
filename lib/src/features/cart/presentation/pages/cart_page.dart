import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_event.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_state.dart';
import 'package:do_an_ngon/src/features/cart/domain/entities/cart_item.dart';
import 'package:do_an_ngon/src/features/orders/data/repositories/order_repository.dart';
import 'package:do_an_ngon/src/features/cart/presentation/widgets/address_selection_bottom_sheet.dart';
import 'package:do_an_ngon/src/features/home/data/repositories/restaurant_repository.dart';
import 'package:do_an_ngon/src/features/home/presentation/widgets/bottom_navigation_bar.dart' as home;

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Lưu danh sách các item đã chọn
  final Set<String> _selectedItemIds = <String>{};

  // Lấy restaurant ID của các item đã chọn (nếu có)
  String? _getSelectedRestaurantId(CartState state) {
    if (_selectedItemIds.isEmpty) return null;
    
    final selectedItems = state.items.where((item) => _selectedItemIds.contains(item.id));
    final restaurantIds = selectedItems
        .map((item) => item.restaurantId ?? item.food.restaurantId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    
    if (restaurantIds.length == 1) {
      return restaurantIds.first;
    }
    
    // Nếu không có restaurantId, thử dùng restaurantName
    final restaurantNames = selectedItems
        .map((item) => item.food.restaurantName.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    
    if (restaurantNames.length == 1) {
      return null; // Sẽ resolve bằng tên sau
    }
    
    return null;
  }

  // Kiểm tra xem item có thể được chọn không (cùng restaurant với các item đã chọn)
  bool _canSelectItem(CartState state, CartItem item) {
    if (_selectedItemIds.isEmpty) return true; // Chưa chọn gì thì chọn được
    
    final selectedRestaurantId = _getSelectedRestaurantId(state);
    final itemRestaurantId = item.restaurantId ?? item.food.restaurantId;
    
    if (selectedRestaurantId != null && itemRestaurantId != null) {
      return selectedRestaurantId == itemRestaurantId;
    }
    
    // Nếu không có restaurantId, so sánh bằng tên
    final selectedItems = state.items.where((i) => _selectedItemIds.contains(i.id));
    if (selectedItems.isEmpty) return true;
    
    final selectedRestaurantName = selectedItems.first.food.restaurantName.trim();
    final itemRestaurantName = item.food.restaurantName.trim();
    
    return selectedRestaurantName.isNotEmpty && 
           itemRestaurantName.isNotEmpty && 
           selectedRestaurantName == itemRestaurantName;
  }

  void _toggleItemSelection(CartState state, String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        final item = state.items.firstWhere((i) => i.id == itemId);
        if (_canSelectItem(state, item)) {
          _selectedItemIds.add(itemId);
        } else {
          // Hiển thị thông báo khi cố chọn món từ cửa hàng khác
          final selectedItems = _getSelectedItems(state);
          if (selectedItems.isNotEmpty) {
            final selectedRestaurantName = selectedItems.first.food.restaurantName;
            _showSnackBar(
              context,
              'Chỉ có thể đặt hàng các món từ cùng một cửa hàng. Món này thuộc cửa hàng khác với "${selectedRestaurantName}".',
            );
          }
        }
      }
    });
  }

  // Tính tổng giá của các item đã chọn
  double _getSelectedTotalPrice(CartState state) {
    return state.items
        .where((item) => _selectedItemIds.contains(item.id))
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Lấy danh sách các item đã chọn
  List<CartItem> _getSelectedItems(CartState state) {
    return state.items.where((item) => _selectedItemIds.contains(item.id)).toList();
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Đăng nhập',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: Text(
            'Bạn cần đăng nhập để đặt hàng. Vui lòng đăng nhập để tiếp tục.',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Đăng nhập',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: 'Giỏ hàng',
        showBackButton: false,
      ),
      bottomNavigationBar: const home.HomeBottomNavigationBar(currentIndex: 2),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80.sp,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Giỏ hàng trống',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Hãy thêm món ăn vào giỏ hàng',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final isSelected = _selectedItemIds.contains(item.id);
                    final canSelect = _canSelectItem(state, item);
                    return _CartItemCard(
                      item: item,
                      isSelected: isSelected,
                      canSelect: canSelect,
                      onToggleSelection: () => _toggleItemSelection(state, item.id),
                    );
                  },
                ),
              ),
              // Total and Checkout
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedItemIds.isEmpty ? 'Tổng cộng:' : 'Tổng đã chọn:',
                                style: TextStyle(
                                  color: AppColors.black,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedItemIds.isNotEmpty)
                                Text(
                                  '${_selectedItemIds.length}/${state.items.length} món',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 12.sp,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            '${(_selectedItemIds.isEmpty ? state.totalPrice : _getSelectedTotalPrice(state)).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Hiển thị cảnh báo nếu các món đã chọn không cùng cửa hàng
                      if (_selectedItemIds.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final selectedItems = _getSelectedItems(state);
                            final restaurantIds = selectedItems
                                .map((item) => item.restaurantId ?? item.food.restaurantId)
                                .whereType<String>()
                                .where((id) => id.isNotEmpty)
                                .toSet();
                            final restaurantNames = selectedItems
                                .map((item) => item.food.restaurantName.trim())
                                .where((name) => name.isNotEmpty)
                                .toSet();
                            
                            final isSameRestaurant = restaurantIds.length <= 1 && restaurantNames.length <= 1;
                            
                            if (!isSameRestaurant) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: Colors.orange, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20.sp),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          'Chỉ có thể đặt hàng các món từ cùng một cửa hàng',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) {
                          // Kiểm tra xem các món đã chọn có cùng cửa hàng không
                          final selectedItems = _getSelectedItems(state);
                          final restaurantIds = selectedItems
                              .map((item) => item.restaurantId ?? item.food.restaurantId)
                              .whereType<String>()
                              .where((id) => id.isNotEmpty)
                              .toSet();
                          final restaurantNames = selectedItems
                              .map((item) => item.food.restaurantName.trim())
                              .where((name) => name.isNotEmpty)
                              .toSet();
                          
                          final isSameRestaurant = restaurantIds.length <= 1 && restaurantNames.length <= 1;
                          final canCheckout = _selectedItemIds.isNotEmpty && isSameRestaurant;
                          
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: !canCheckout
                                  ? null
                                  : () {
                                      final authState = context.read<AuthBloc>().state;
                                      if (!authState.isAuthenticated) {
                                        _showLoginRequiredDialog(context);
                                        return;
                                      }
                                      _showAddressSelection(context, state);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'Đặt hàng',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddressSelection(BuildContext context, CartState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddressSelectionBottomSheet(
        onAddressSelected: (address) {
          _handleCheckout(context, state, address.id);
        },
      ),
    );
  }

  Future<void> _handleCheckout(
    BuildContext context,
    CartState state,
    String addressId,
  ) async {
    final selectedItems = _getSelectedItems(state);
    if (selectedItems.isEmpty) {
      _showSnackBar(context, 'Vui lòng chọn ít nhất một món để đặt hàng.');
      return;
    }

    final restaurantId = await _determineRestaurantId(context, state, selectedItems);
    if (restaurantId == null) {
      return;
    }
    final orderRepository = GetIt.I<OrderRepository>();
    final items = selectedItems
        .map(
          (item) => OrderRequestItem(
            menuItemId: item.food.id,
            quantity: item.quantity,
          ),
        )
        .toList();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await orderRepository.createOrder(
        restaurantId: restaurantId,
        items: items,
        paymentMethod: 'COD',
        addressId: addressId,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt hàng thành công!'),
            backgroundColor: AppColors.primary,
          ),
        );
        // Xóa các item đã đặt hàng khỏi giỏ
        for (final item in selectedItems) {
          context.read<CartBloc>().add(RemoveFromCartEvent(cartItemId: item.id));
        }
        // Reset selection
        setState(() {
          _selectedItemIds.clear();
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt hàng thất bại. Vui lòng thử lại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<String?> _determineRestaurantId(BuildContext context, CartState state, List<CartItem> selectedItems) async {
    // Chỉ kiểm tra các item đã chọn
    final restaurantIdSet = selectedItems
        .map((item) => item.restaurantId ?? item.food.restaurantId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (restaurantIdSet.isNotEmpty) {
      if (restaurantIdSet.length > 1) {
        _showSnackBar(
          context,
          'Vui lòng đặt hàng cho từng quán ăn riêng biệt.',
        );
        return null;
      }
      return restaurantIdSet.first;
    }

    final restaurantNames = selectedItems
        .map((item) => item.food.restaurantName.trim())
        .where((name) => name.isNotEmpty)
        .toSet();

    if (restaurantNames.length == 1) {
      final repository = GetIt.I<RestaurantRepository>();
      final fallbackName = restaurantNames.first;

      try {
        final resolvedId = await repository.findRestaurantIdByName(fallbackName);
        if (resolvedId != null && resolvedId.isNotEmpty) {
          return resolvedId;
        }
      } on ApiException catch (e) {
        _showSnackBar(context, e.message);
        return null;
      } catch (_) {
        // Ignore and show generic error below
      }
    }

    _showSnackBar(
      context,
      'Không thể xác định quán ăn cho các món đã chọn. Vui lòng xóa và thêm lại món ăn.',
    );
    return null;
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.redAccent,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool isSelected;
  final bool canSelect;
  final VoidCallback onToggleSelection;

  const _CartItemCard({
    required this.item,
    required this.isSelected,
    required this.canSelect,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Opacity(
            opacity: canSelect ? 1.0 : 0.5,
            child: Checkbox(
              value: isSelected,
              onChanged: canSelect ? (_) => onToggleSelection() : null,
              activeColor: AppColors.primary,
              checkColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Food Image
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(12.r),
              image: item.food.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(item.food.imageUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    )
                  : null,
            ),
            child: item.food.imageUrl.isEmpty
                ? Icon(
                    Icons.fastfood,
                    color: AppColors.grey,
                    size: 40.sp,
                  )
                : null,
          ),
          SizedBox(width: 12.w),
          // Food Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.food.name,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                if (item.food.restaurantName.isNotEmpty)
                  Text(
                    item.food.restaurantName,
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 8.h),
                Text(
                  '${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                // Quantity Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (item.quantity > 1) {
                          context.read<CartBloc>().add(
                                UpdateCartItemQuantityEvent(
                                  cartItemId: item.id,
                                  quantity: item.quantity - 1,
                                ),
                              );
                        } else {
                          context.read<CartBloc>().add(
                                RemoveFromCartEvent(cartItemId: item.id),
                              );
                        }
                      },
                      child: Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.lightGrey,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: AppColors.black,
                          size: 16.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      constraints: BoxConstraints(minWidth: 24.w),
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Text(
                        item.quantity.toString(),
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () {
                        context.read<CartBloc>().add(
                              UpdateCartItemQuantityEvent(
                                cartItemId: item.id,
                                quantity: item.quantity + 1,
                              ),
                            );
                      },
                      child: Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Delete Button
          GestureDetector(
            onTap: () {
              context.read<CartBloc>().add(
                    RemoveFromCartEvent(cartItemId: item.id),
                  );
            },
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

