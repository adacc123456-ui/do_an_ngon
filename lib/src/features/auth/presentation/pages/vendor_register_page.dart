import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/core/widgets/svg_icon.dart';
import 'package:do_an_ngon/src/features/auth/data/repositories/auth_repository.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_event.dart';

class VendorRegisterPage extends StatefulWidget {
  const VendorRegisterPage({super.key});

  @override
  State<VendorRegisterPage> createState() => _VendorRegisterPageState();
}

class _VendorRegisterPageState extends State<VendorRegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _restaurantIdsController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  final _restaurantDescriptionController = TextEditingController();
  final _restaurantPhoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _wardController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _deliveryMinController = TextEditingController();
  final _deliveryMaxController = TextEditingController();

  bool _createNewRestaurant = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthRepository get _authRepository => GetIt.I<AuthRepository>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _restaurantIdsController.dispose();
    _restaurantNameController.dispose();
    _restaurantDescriptionController.dispose();
    _restaurantPhoneController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _categoriesController.dispose();
    _tagsController.dispose();
    _deliveryFeeController.dispose();
    _deliveryMinController.dispose();
    _deliveryMaxController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      (_createNewRestaurant ? _isVendorRestaurantValid : _restaurantIdsController.text.trim().isNotEmpty);

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,4}$');
    return emailRegex.hasMatch(value);
  }

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 && digits.length <= 12;
  }

  List<String> _parseRestaurantIds(String input) {
    return input
        .split(RegExp(r'[,\n]'))
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  List<String> _parseCommaSeparated(String input) {
    return input
        .split(RegExp(r'[,\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  bool get _isVendorRestaurantValid {
    return _restaurantNameController.text.trim().isNotEmpty &&
        _restaurantPhoneController.text.trim().isNotEmpty &&
        _streetController.text.trim().isNotEmpty &&
        _wardController.text.trim().isNotEmpty &&
        _districtController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty;
  }

  Map<String, dynamic> _buildVendorRestaurantPayload() {
    final categories = _parseCommaSeparated(_categoriesController.text);
    final tags = _parseCommaSeparated(_tagsController.text);
    final deliveryFee = double.tryParse(_deliveryFeeController.text.trim());
    final deliveryMin = int.tryParse(_deliveryMinController.text.trim());
    final deliveryMax = int.tryParse(_deliveryMaxController.text.trim());

    final payload = <String, dynamic>{
      'name': _restaurantNameController.text.trim(),
      'description': _restaurantDescriptionController.text.trim(),
      'phone': _restaurantPhoneController.text.trim(),
      'address': {
        'street': _streetController.text.trim(),
        'ward': _wardController.text.trim(),
        'district': _districtController.text.trim(),
        'city': _cityController.text.trim(),
      },
    };

    if (categories.isNotEmpty) {
      payload['categories'] = categories;
    }
    if (tags.isNotEmpty) {
      payload['tags'] = tags;
    }
    if (deliveryFee != null || deliveryMin != null || deliveryMax != null) {
      payload['delivery'] = {
        if (deliveryFee != null) 'baseFee': deliveryFee,
        if (deliveryMin != null || deliveryMax != null)
          'estimatedTime': {
            if (deliveryMin != null) 'min': deliveryMin,
            if (deliveryMax != null) 'max': deliveryMax,
          },
      };
    }

    return payload;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập họ và tên.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Email không hợp lệ.');
      return;
    }
    if (!_isValidPhone(phone)) {
      setState(() => _errorMessage = 'Số điện thoại không hợp lệ.');
      return;
    }
    final restaurantIds = _createNewRestaurant ? <String>[] : _parseRestaurantIds(_restaurantIdsController.text);

    if (password.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp.');
      return;
    }
    if (_createNewRestaurant && !_isVendorRestaurantValid) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ thông tin cửa hàng.');
      return;
    }
    if (!_createNewRestaurant && restaurantIds.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập ít nhất một ID nhà hàng do quản trị viên cung cấp.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await _authRepository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        accountType: 'vendor',
        managedRestaurantIds: _createNewRestaurant ? null : restaurantIds,
        vendorRestaurant: _createNewRestaurant ? _buildVendorRestaurantPayload() : null,
      );

      if (!mounted) return;
      
      // Backend mới: không tạo tài khoản ngay, chỉ lưu tạm và gửi mã xác minh
      // Response: { requiresVerification: true, email: "..." }
      // Không gọi CompleteAuthEvent ở đây - chỉ login sau khi xác minh email thành công

      if (!mounted) return;
      final successMessage = _createNewRestaurant
          ? 'Đã gửi mã xác minh đến email của bạn. Vui lòng xác minh email để tạo tài khoản và bắt đầu quản lý cửa hàng.'
          : 'Đã gửi mã xác minh đến email của bạn. Vui lòng xác minh email để tạo tài khoản và quản lý các cửa hàng đã được cấp quyền.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 5),
        ),
      );
      context.go('/verify-email', extra: email);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(
        title: '',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            // App Logo/Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(
                  assetPath: 'assets/svgs/fork_knife.svg',
                  width: 32,
                  height: 32,
                  color: AppColors.primary,
                  fallbackIcon: Icons.restaurant,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Hôm nay ăn gì',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            // Screen Title
            Text(
              'Đăng ký chủ cửa hàng',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tạo tài khoản để quản lý cửa hàng của bạn',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phương thức đăng ký',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Bạn có thể tạo cửa hàng mới ngay hoặc nhập ID cửa hàng do quản trị viên cấp.',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SwitchListTile(
                    value: _createNewRestaurant,
                    onChanged: (value) {
                      setState(() {
                        _createNewRestaurant = value;
                      });
                    },
                    title: Text(
                      _createNewRestaurant ? 'Tạo cửa hàng mới' : 'Nhập ID cửa hàng đã có',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _createNewRestaurant
                          ? 'Backend sẽ tự tạo nhà hàng và cấp quyền cho bạn.'
                          : 'Sử dụng ID nhà hàng đã tồn tại trong hệ thống.',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12.sp,
                      ),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            if (_createNewRestaurant) ...[
              Text(
                'Thông tin cửa hàng',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Tên cửa hàng',
                controller: _restaurantNameController,
                hint: 'VD: Bún bò 24h',
                requiredField: true,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Mô tả',
                controller: _restaurantDescriptionController,
                hint: 'Giới thiệu ngắn gọn về cửa hàng',
                maxLines: 3,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Số điện thoại cửa hàng',
                controller: _restaurantPhoneController,
                keyboardType: TextInputType.phone,
                requiredField: true,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Địa chỉ - Số nhà, đường',
                controller: _streetController,
                requiredField: true,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Phường/Xã',
                controller: _wardController,
                requiredField: true,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Quận/Huyện',
                controller: _districtController,
                requiredField: true,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Tỉnh/Thành phố',
                controller: _cityController,
                requiredField: true,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Danh mục (phân tách bằng dấu phẩy)',
                controller: _categoriesController,
                hint: 'Cơm, Đồ ăn nhanh...',
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Tags (phân tách bằng dấu phẩy)',
                controller: _tagsController,
                hint: 'bun bo, gia dinh...',
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Phí giao hàng (đ)',
                      controller: _deliveryFeeController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTextField(
                      label: 'Thời gian tối thiểu (phút)',
                      controller: _deliveryMinController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTextField(
                      label: 'Thời gian tối đa (phút)',
                      controller: _deliveryMaxController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
            ] else ...[
              Text(
                'Nhập ID nhà hàng (Mongo ObjectId)',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _restaurantIdsController,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Nhập ID nhà hàng, phân tách bằng dấu phẩy hoặc xuống dòng',
                  helperText: 'Liên hệ quản trị viên để được cấp ID nhà hàng hợp lệ.',
                  helperStyle: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12.sp,
                  ),
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
              SizedBox(height: 24.h),
            ],
            // Name Field
            Text(
              'Họ và tên',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nhập họ và tên',
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
            SizedBox(height: 24.h),
            // Email Field
            Text(
              'Email',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nhập email',
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
            SizedBox(height: 24.h),
            // Phone Number Field
            Text(
              'Số điện thoại',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nhập số điện thoại',
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
            SizedBox(height: 24.h),
            // Password Field
            Text(
              'Mật khẩu',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nhập mật khẩu',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
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
            SizedBox(height: 24.h),
            // Confirm Password Field
            Text(
              'Xác nhận mật khẩu',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nhập lại mật khẩu',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
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
            SizedBox(height: 32.h),
            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || !_isFormValid ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Text(
                        'Đăng ký',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 12.h),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13.sp,
                ),
              ),
            ],
            SizedBox(height: 16.h),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Đã có tài khoản? Đăng nhập',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool requiredField = false,
    TextInputType? keyboardType,
    int maxLines = 1,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
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

