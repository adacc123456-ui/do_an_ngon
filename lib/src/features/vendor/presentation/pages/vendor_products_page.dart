import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/features/home/data/repositories/restaurant_repository.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/restaurant.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/vendor/data/repositories/vendor_repository.dart';
import 'package:do_an_ngon/src/core/constants/menu_categories.dart';

class VendorProductsPage extends StatefulWidget {
  const VendorProductsPage({super.key});

  @override
  State<VendorProductsPage> createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage> {
  final RestaurantRepository _restaurantRepository = GetIt.I<RestaurantRepository>();
  final VendorRepository _vendorRepository = GetIt.I<VendorRepository>();

  List<Food> _products = [];
  List<Restaurant> _managedRestaurants = [];
  bool _isLoadingRestaurants = true;
  bool _isLoadingProducts = true;
  String? _restaurantsError;
  String? _productsError;
  String? _selectedRestaurantId;

  @override
  void initState() {
    super.initState();
    _loadManagedRestaurants();
  }

  Future<void> _loadManagedRestaurants() async {
    final authState = context.read<AuthBloc>().state;
    final managedRestaurants = authState.userProfile?['managedRestaurants'] as List<dynamic>?;
    if (managedRestaurants == null || managedRestaurants.isEmpty) {
      setState(() {
        _restaurantsError = 'Tài khoản của bạn chưa được gán nhà hàng nào. Vui lòng liên hệ quản trị viên.';
        _isLoadingRestaurants = false;
        _isLoadingProducts = false;
      });
      return;
    }

    setState(() {
      _isLoadingRestaurants = true;
      _restaurantsError = null;
    });

    final ids = managedRestaurants.map((entry) {
      if (entry is String) return entry;
      if (entry is Map<String, dynamic>) {
        return entry['_id']?.toString() ?? entry['id']?.toString();
      }
      return null;
    }).whereType<String>().toList();

    try {
      final restaurants = <Restaurant>[];
      for (final id in ids) {
        if (id.isEmpty) continue;
        final restaurant = await _restaurantRepository.getRestaurantDetail(id);
        restaurants.add(restaurant);
      }
      if (restaurants.isEmpty) {
        throw const ApiException(message: 'Không tìm thấy thông tin nhà hàng.');
      }
      setState(() {
        _managedRestaurants = restaurants;
        _selectedRestaurantId ??= restaurants.first.id;
        _isLoadingRestaurants = false;
      });
      await _loadProducts();
    } on ApiException catch (e) {
      setState(() {
        _restaurantsError = e.message;
        _isLoadingRestaurants = false;
        _isLoadingProducts = false;
      });
    } catch (_) {
      setState(() {
        _restaurantsError = 'Không thể tải danh sách nhà hàng.';
        _isLoadingRestaurants = false;
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    final restaurantId = _selectedRestaurantId;
    if (restaurantId == null || restaurantId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _productsError = 'Vui lòng chọn nhà hàng để xem sản phẩm.';
        _isLoadingProducts = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final menuItemsData = await _vendorRepository.getVendorMenuItems(
        restaurantId: restaurantId,
      );
      
      // Convert Map to Food
      final products = menuItemsData.map((item) {
        final restaurant = item['restaurant'] as Map<String, dynamic>? ?? {};
        return Food(
          id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          imageUrl: item['imageUrl']?.toString() ?? 'assets/images/monan.png',
          restaurantName: restaurant['name']?.toString() ?? '',
          restaurantAddress: restaurant['address']?.toString() ?? '',
          restaurantId: restaurant['_id']?.toString() ?? restaurant['id']?.toString() ?? restaurantId,
          price: (item['price'] as num?)?.toDouble(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _productsError = e.message;
        _isLoadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _productsError = 'Không thể tải danh sách sản phẩm';
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _deleteProduct(Food product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc chắn muốn xóa "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _vendorRepository.deleteMenuItem(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa sản phẩm thành công'),
            backgroundColor: AppColors.primary,
          ),
        );
        _loadProducts();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xóa sản phẩm. Vui lòng thử lại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  List<String> _parseCommaSeparated(String input) {
    return input
        .split(RegExp(r'[,\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _managedRestaurants.isEmpty ? null : _showCreateProductSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text(
          'Thêm sản phẩm',
          style: TextStyle(color: AppColors.white, fontSize: 16.sp),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingRestaurants) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_restaurantsError != null) {
      return _ErrorState(
        message: _restaurantsError!,
        onRetry: _loadManagedRestaurants,
      );
    }
    if (_managedRestaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory, size: 80.sp, color: AppColors.grey),
            SizedBox(height: 16.h),
            Text(
              'Bạn chưa có cửa hàng nào',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Vui lòng đăng ký cửa hàng hoặc liên hệ quản trị viên để được cấp quyền.',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Padding(
        //   padding: EdgeInsets.all(16.w),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         'Cửa hàng',
        //         style: TextStyle(
        //           color: AppColors.black,
        //           fontSize: 14.sp,
        //           fontWeight: FontWeight.w600,
        //         ),
        //       ),
        //       SizedBox(height: 8.h),
        //       DropdownButtonFormField<String>(
        //         value: selectedRestaurant.id,
        //         items: _managedRestaurants
        //             .map(
        //               (restaurant) => DropdownMenuItem(
        //                 value: restaurant.id,
        //                 child: Text(restaurant.name),
        //               ),
        //             )
        //             .toList(),
        //         onChanged: (value) {
        //           setState(() {
        //             _selectedRestaurantId = value;
        //           });
        //           _loadProducts();
        //         },
        //         decoration: InputDecoration(
        //           filled: true,
        //           fillColor: AppColors.white,
        //           border: OutlineInputBorder(
        //             borderRadius: BorderRadius.circular(12.r),
        //             borderSide: BorderSide(color: AppColors.lightGrey),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        Expanded(
          child: _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : _productsError != null
                  ? _ErrorState(
                      message: _productsError!,
                      onRetry: _loadProducts,
                    )
                  : _products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu, size: 80.sp, color: AppColors.grey),
                              SizedBox(height: 16.h),
                              Text(
                                'Chưa có sản phẩm',
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Nhấn nút + để thêm sản phẩm mới',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return _ProductCard(
                                product: product,
                                onEdit: () => _showEditProductSheet(product),
                                onDelete: () => _deleteProduct(product),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  void _showCreateProductSheet() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final imageUrlController = TextEditingController();
    final tagsController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = MenuCategories.rice;
    String? restaurantId = _selectedRestaurantId;
    bool isSubmitting = false;

    final categories = [
      {'key': MenuCategories.rice, 'label': MenuCategories.resolveName(MenuCategories.rice)},
      {'key': MenuCategories.noodles, 'label': MenuCategories.resolveName(MenuCategories.noodles)},
      {'key': MenuCategories.seafood, 'label': MenuCategories.resolveName(MenuCategories.seafood)},
      {'key': MenuCategories.coffee, 'label': MenuCategories.resolveName(MenuCategories.coffee)},
      {'key': MenuCategories.snacks, 'label': MenuCategories.resolveName(MenuCategories.snacks)},
      {'key': MenuCategories.fastFood, 'label': MenuCategories.resolveName(MenuCategories.fastFood)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16.h,
                top: 16.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Thêm sản phẩm mới',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            FocusScope.of(sheetContext).unfocus();
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      ],
                    ),
                    if (_managedRestaurants.length > 1) ...[
                      Text(
                        'Chọn cửa hàng',
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      DropdownButtonFormField<String>(
                        value: restaurantId ?? _managedRestaurants.first.id,
                        items: _managedRestaurants
                            .map(
                              (restaurant) => DropdownMenuItem(
                                value: restaurant.id,
                                child: Text(restaurant.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            restaurantId = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: AppColors.lightGrey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: AppColors.lightGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                    _buildModalTextField(
                      controller: nameController,
                      label: 'Tên món',
                      requiredField: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildModalTextField(
                      controller: descriptionController,
                      label: 'Mô tả',
                      maxLines: 3,
                    ),
                    SizedBox(height: 16.h),
                    _buildModalTextField(
                      controller: priceController,
                      label: 'Giá (đ)',
                      keyboardType: TextInputType.number,
                      requiredField: true,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Danh mục',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category['key'],
                              child: Text(category['label'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.lightGrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.lightGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildModalTextField(
                      controller: imageUrlController,
                      label: 'Hình ảnh (URL)',
                      requiredField: true,
                      hint: 'https://cdn.example.com/image.jpg',
                    ),
                    SizedBox(height: 16.h),
                    _buildModalTextField(
                      controller: tagsController,
                      label: 'Tags (phân tách bằng dấu phẩy)',
                      hint: 'bun bo, cay, buoi trua',
                    ),
                    SizedBox(height: 16.h),
                    _buildModalTextField(
                      controller: notesController,
                      label: 'Tùy chọn (mô tả ngắn)',
                      hint: 'VD: Thêm trứng 5k, thêm chả 8k',
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                // Lưu giá trị từ controllers vào biến local trước khi async
                                final name = nameController.text.trim();
                                final priceText = priceController.text.trim();
                                final imageUrl = imageUrlController.text.trim();
                                final description = descriptionController.text.trim();
                                final tags = tagsController.text;
                                
                                final price = double.tryParse(priceText);
                                if (name.isEmpty ||
                                    price == null ||
                                    price <= 0 ||
                                    imageUrl.isEmpty) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vui lòng nhập đầy đủ và chính xác thông tin.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }
                                if (restaurantId == null || restaurantId!.isEmpty) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vui lòng chọn nhà hàng.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() => isSubmitting = true);
                                try {
                                  await _vendorRepository.createMenuItem(
                                    name: name,
                                    price: price,
                                    category: selectedCategory,
                                    imageUrl: imageUrl,
                                    restaurantId: restaurantId,
                                    description: description.isEmpty ? null : description,
                                    tags: _parseCommaSeparated(tags),
                                  );
                                  if (!mounted) return;
                                  FocusScope.of(sheetContext).unfocus();
                                  Navigator.of(sheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã thêm sản phẩm thành công.'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                  _loadProducts();
                                } on ApiException catch (e) {
                                  try {
                                    setSheetState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(
                                        content: Text(e.message),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  } catch (_) {
                                    // Sheet đã đóng, bỏ qua
                                  }
                                } catch (_) {
                                  try {
                                    setSheetState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      const SnackBar(
                                        content: Text('Không thể tạo sản phẩm. Vui lòng thử lại.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  } catch (_) {
                                    // Sheet đã đóng, bỏ qua
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                ),
                              )
                            : Text(
                                'Tạo sản phẩm',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Delay dispose để đảm bảo tất cả focus events đã được xử lý
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          nameController.dispose();
          descriptionController.dispose();
          priceController.dispose();
          imageUrlController.dispose();
          tagsController.dispose();
          notesController.dispose();
        });
      });
    });
  }

  void _showEditProductSheet(Food product) {
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController();
    final priceController = TextEditingController(text: (product.price ?? 0).toStringAsFixed(0));
    final imageUrlController = TextEditingController(text: product.imageUrl);
    final tagsController = TextEditingController();
    String? selectedCategory = MenuCategories.rice; // Default, will need to fetch from API if needed
    bool isSubmitting = false;

    final categories = [
      {'key': MenuCategories.rice, 'label': MenuCategories.resolveName(MenuCategories.rice)},
      {'key': MenuCategories.noodles, 'label': MenuCategories.resolveName(MenuCategories.noodles)},
      {'key': MenuCategories.seafood, 'label': MenuCategories.resolveName(MenuCategories.seafood)},
      {'key': MenuCategories.coffee, 'label': MenuCategories.resolveName(MenuCategories.coffee)},
      {'key': MenuCategories.snacks, 'label': MenuCategories.resolveName(MenuCategories.snacks)},
      {'key': MenuCategories.fastFood, 'label': MenuCategories.resolveName(MenuCategories.fastFood)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16.h,
                top: 16.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sửa sản phẩm',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            FocusScope.of(sheetContext).unfocus();
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      ],
                    ),
                    _buildModalTextField(
                      controller: nameController,
                      label: 'Tên món',
                      requiredField: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildModalTextField(
                      controller: descriptionController,
                      label: 'Mô tả',
                      maxLines: 3,
                    ),
                    SizedBox(height: 16.h),
                    _buildModalTextField(
                      controller: priceController,
                      label: 'Giá (đ)',
                      keyboardType: TextInputType.number,
                      requiredField: true,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Danh mục',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category['key'],
                              child: Text(category['label'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.lightGrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.lightGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildModalTextField(
                      controller: imageUrlController,
                      label: 'Hình ảnh (URL)',
                      requiredField: true,
                      hint: 'https://cdn.example.com/image.jpg',
                    ),
                    SizedBox(height: 16.h),
                    _buildModalTextField(
                      controller: tagsController,
                      label: 'Tags (phân tách bằng dấu phẩy)',
                      hint: 'bun bo, cay, buoi trua',
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                // Lưu giá trị từ controllers vào biến local trước khi async
                                final name = nameController.text.trim();
                                final priceText = priceController.text.trim();
                                final imageUrl = imageUrlController.text.trim();
                                final description = descriptionController.text.trim();
                                final tags = tagsController.text;
                                
                                final price = double.tryParse(priceText);
                                if (name.isEmpty ||
                                    price == null ||
                                    price <= 0 ||
                                    imageUrl.isEmpty) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vui lòng nhập đầy đủ và chính xác thông tin.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }
                                if (selectedCategory == null || selectedCategory!.isEmpty) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vui lòng chọn danh mục.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() => isSubmitting = true);
                                try {
                                  await _vendorRepository.updateMenuItem(
                                    menuItemId: product.id,
                                    name: name,
                                    price: price,
                                    category: selectedCategory!,
                                    imageUrl: imageUrl,
                                    description: description.isEmpty ? null : description,
                                    tags: _parseCommaSeparated(tags).isEmpty
                                        ? null
                                        : _parseCommaSeparated(tags),
                                  );
                                  if (!mounted) return;
                                  FocusScope.of(sheetContext).unfocus();
                                  Navigator.of(sheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã cập nhật sản phẩm thành công.'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                  _loadProducts();
                                } on ApiException catch (e) {
                                  try {
                                    setSheetState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(
                                        content: Text(e.message),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  } catch (_) {
                                    // Sheet đã đóng, bỏ qua
                                  }
                                } catch (_) {
                                  try {
                                    setSheetState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      const SnackBar(
                                        content: Text('Không thể cập nhật sản phẩm. Vui lòng thử lại.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  } catch (_) {
                                    // Sheet đã đóng, bỏ qua
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                ),
                              )
                            : Text(
                                'Cập nhật sản phẩm',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Delay dispose để đảm bảo tất cả focus events đã được xử lý
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          nameController.dispose();
          descriptionController.dispose();
          priceController.dispose();
          imageUrlController.dispose();
          tagsController.dispose();
        });
      });
    });
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool requiredField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${requiredField ? ' *' : ''}',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Food product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isRemoteImage = product.imageUrl.startsWith('http');

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
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              bottomLeft: Radius.circular(12.r),
            ),
            child: isRemoteImage
                ? Image.network(
                    product.imageUrl,
                    width: 100.w,
                    height: 100.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100.w,
                        height: 100.w,
                        color: AppColors.lightGrey,
                        child: Icon(Icons.restaurant, color: AppColors.grey),
                      );
                    },
                  )
                : Image.asset(
                    product.imageUrl,
                    width: 100.w,
                    height: 100.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100.w,
                        height: 100.w,
                        color: AppColors.lightGrey,
                        child: Icon(Icons.restaurant, color: AppColors.grey),
                      );
                    },
                  ),
          ),
          // Product info
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${(product.price ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 20.sp, color: AppColors.primary),
                        onPressed: onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: 16.w),
                      IconButton(
                        icon: Icon(Icons.delete, size: 20.sp, color: Colors.redAccent),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.grey),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              message,
              style: TextStyle(color: AppColors.textGrey, fontSize: 16.sp),
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }
}

