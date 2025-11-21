import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/features/account/data/repositories/user_address_repository.dart';
import 'package:do_an_ngon/src/features/account/domain/entities/user_address.dart';
import 'package:go_router/go_router.dart';

class AddressSelectionBottomSheet extends StatefulWidget {
  final UserAddress? selectedAddress;
  final Function(UserAddress) onAddressSelected;

  const AddressSelectionBottomSheet({
    super.key,
    this.selectedAddress,
    required this.onAddressSelected,
  });

  @override
  State<AddressSelectionBottomSheet> createState() => _AddressSelectionBottomSheetState();
}

class _AddressSelectionBottomSheetState extends State<AddressSelectionBottomSheet> {
  final UserAddressRepository _addressRepository = GetIt.I<UserAddressRepository>();
  List<UserAddress> _addresses = [];
  bool _isLoading = true;
  String? _errorMessage;
  UserAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.selectedAddress;
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final addresses = await _addressRepository.getAddresses();
      setState(() {
        _addresses = addresses;
        if (_selectedAddress == null && addresses.isNotEmpty) {
          _selectedAddress = addresses.firstWhere(
            (addr) => addr.isDefault,
            orElse: () => addresses.first,
          );
        }
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách địa chỉ';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chọn địa chỉ giao hàng',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _loadAddresses,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else if (_addresses.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64.sp,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Bạn chưa có địa chỉ giao hàng',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/account-information');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      'Thêm địa chỉ',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  final isSelected = _selectedAddress?.id == address.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAddress = address;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.lightGrey,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.primary : AppColors.grey,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      address.label,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    if (address.isDefault) ...[
                                      SizedBox(width: 8.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                        child: Text(
                                          'Mặc định',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  address.recipientName,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  address.fullAddress,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                if (address.phone.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    'ĐT: ${address.phone}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (!_isLoading && _addresses.isNotEmpty) ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedAddress == null
                    ? null
                    : () {
                        widget.onAddressSelected(_selectedAddress!);
                        Navigator.of(context).pop();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Xác nhận',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

