import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/core/services/location_service.dart';
import 'package:do_an_ngon/src/features/account/data/repositories/user_address_repository.dart';
import 'package:do_an_ngon/src/features/account/domain/entities/user_address.dart';

class AddEditAddressPage extends StatefulWidget {
  final UserAddress? address;

  const AddEditAddressPage({super.key, this.address});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final UserAddressRepository _addressRepository = GetIt.I<UserAddressRepository>();
  final LocationService _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _wardController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isDefault = false;
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;

  bool get _isEditMode => widget.address != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final address = widget.address!;
      _labelController.text = address.label;
      _recipientNameController.text = address.recipientName;
      _phoneController.text = address.phone;
      _streetController.text = address.street;
      _wardController.text = address.ward;
      _districtController.text = address.district;
      _cityController.text = address.city;
      _noteController.text = address.note ?? '';
      _isDefault = address.isDefault;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _recipientNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final addressInfo = await _locationService.getCurrentAddress();
      
      if (!mounted) return;

      if (addressInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lấy vị trí. Vui lòng kiểm tra quyền truy cập vị trí và GPS.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Tự động điền các trường địa chỉ
      setState(() {
        _streetController.text = addressInfo.street;
        _wardController.text = addressInfo.ward;
        _districtController.text = addressInfo.district;
        _cityController.text = addressInfo.city;
        _isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lấy địa chỉ từ vị trí hiện tại'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lấy vị trí: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        await _addressRepository.updateAddress(
          addressId: widget.address!.id,
          label: _labelController.text.trim(),
          recipientName: _recipientNameController.text.trim(),
          phone: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          ward: _wardController.text.trim(),
          district: _districtController.text.trim(),
          city: _cityController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        await _addressRepository.createAddress(
          label: _labelController.text.trim(),
          recipientName: _recipientNameController.text.trim(),
          phone: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          ward: _wardController.text.trim(),
          district: _districtController.text.trim(),
          city: _cityController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          isDefault: _isDefault,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Đã cập nhật địa chỉ thành công' : 'Đã thêm địa chỉ thành công'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop(true); // Trả về true để báo cần reload
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
          SnackBar(
            content: Text(_isEditMode ? 'Không thể cập nhật địa chỉ' : 'Không thể thêm địa chỉ'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: _isEditMode ? 'Sửa địa chỉ' : 'Thêm địa chỉ',
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: 'Nhãn địa chỉ',
                controller: _labelController,
                hint: 'VD: Nhà riêng, Công ty',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập nhãn địa chỉ';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Tên người nhận',
                controller: _recipientNameController,
                hint: 'Nhập tên người nhận',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên người nhận';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Số điện thoại',
                controller: _phoneController,
                hint: 'Nhập số điện thoại',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              // Button to get current location
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lấy vị trí hiện tại',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Tự động điền địa chỉ từ GPS',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _isLoadingLocation
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.location_searching,
                              color: AppColors.primary,
                              size: 24.sp,
                            ),
                            onPressed: _getCurrentLocation,
                          ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Số nhà, tên đường',
                controller: _streetController,
                hint: 'VD: 123 Nguyễn Huệ',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số nhà, tên đường';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Phường/Xã',
                controller: _wardController,
                hint: 'VD: Phường Bến Nghé',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập phường/xã';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Quận/Huyện',
                controller: _districtController,
                hint: 'VD: Quận 1',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập quận/huyện';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Tỉnh/Thành phố',
                controller: _cityController,
                hint: 'VD: TP. Hồ Chí Minh',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tỉnh/thành phố';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Ghi chú (tùy chọn)',
                controller: _noteController,
                hint: 'VD: Nhà có chó, tầng 3',
                maxLines: 3,
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Đặt làm địa chỉ mặc định',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() => _isDefault = value);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
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
                          _isEditMode ? 'Cập nhật' : 'Thêm địa chỉ',
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
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          ),
        ),
      ],
    );
  }
}

