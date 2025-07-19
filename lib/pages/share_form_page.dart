import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/region_model.dart' as region_model;
import '../data/models/share_model.dart';
import '../data/repositories/home_repository.dart';
import '../data/repositories/share_repository.dart';
import '../utils/toast_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_radio_buttons.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dialog.dart';

enum ShareFormMode { create, update }

// Helper classes for dropdown options
class SectorTypeOption {
  final String id;
  final String name;

  SectorTypeOption({required this.id, required this.name});
}

class SectorOption {
  final int id;
  final String name;
  final String code;

  SectorOption({required this.id, required this.name, required this.code});
}

class ShareFormPage extends StatefulWidget {
  final ShareFormMode mode;
  final Share? existingShare; // For update mode

  const ShareFormPage({
    super.key,
    required this.mode,
    this.existingShare,
  });

  @override
  State<ShareFormPage> createState() => _ShareFormPageState();
}

class _ShareFormPageState extends State<ShareFormPage> {
  final HomeRepository _homeRepository = HomeRepository();
  final ShareRepository _shareRepository = ShareRepository();

  // Form controllers and state
  String _currentType = 'buy';
  final Map<String, String> _formData = {
    'owner_name': '',
    'region_id': '',
    'sector_id': '',
    'quantity': '',
    'price': '',
  };

  // Dropdown data
  List<region_model.Region> _regions = [];
  List<SectorTypeOption> _sectorTypes = [];
  List<SectorOption> _sectors = [];
  Map<String, dynamic>? _mainSectors;

  // Loading states
  bool _isLoadingRegions = false;
  bool _isLoadingSectors = false;
  bool _isSubmitting = false;

  // Error states
  final Map<String, String> _errors = {};
  final Map<String, bool> _hasErrors = {};
  String? _generalError;

  // Selected values for dependent dropdowns
  region_model.Region? _selectedRegion;
  SectorTypeOption? _selectedSectorType;
  SectorOption? _selectedSector;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.mode == ShareFormMode.update && widget.existingShare != null) {
      final share = widget.existingShare!;
      _currentType = share.transactionType;
      _formData['owner_name'] = share.ownerName;
      _formData['region_id'] = share.regionId.toString();
      _formData['sector_id'] = share.sectorId.toString();
      _formData['quantity'] = share.quantityKey; // Use the raw value for the form
      _formData['price'] = share.priceKey.toString();
    }
  }

  Future<void> _loadInitialData() async {
    await _loadRegions();
    
    // If updating, load dependent data
    if (widget.mode == ShareFormMode.update && widget.existingShare != null) {
      final share = widget.existingShare!;
      await _loadSectorsForRegion(share.regionId);
      _setInitialValues(share);
    }
  }

  void _setInitialValues(Share share) {
    // Find and set region
    final foundRegion = _regions.where((region) => region.id == share.regionId).toList();
    if (foundRegion.isNotEmpty) {
      _selectedRegion = foundRegion.first;
    }

    // Find and set sector type and populate sectors
    if (_mainSectors != null && _mainSectors!['data'] != null) {
      final data = _mainSectors!['data'] as List;
      for (int i = 0; i < data.length; i++) {
        final sectorItem = data[i] as Map<String, dynamic>;
        if (sectorItem['key'] == share.sector.codeType) {
          _selectedSectorType = SectorTypeOption(id: i.toString(), name: sectorItem['key']);
          
          // Populate sectors for this sector type
          final sectorCodes = sectorItem['code'] as List?;
          if (sectorCodes != null) {
            _sectors = sectorCodes.map((code) {
              final codeMap = code as Map<String, dynamic>;
              return SectorOption(
                id: codeMap['id'] ?? 0,
                name: codeMap['name'] ?? '',
                code: codeMap['code'] ?? '',
              );
            }).toList();
          }
          break;
        }
      }
    }

    // Set sector info
    _selectedSector = SectorOption(
      id: share.sectorId,
      name: share.sector.sectorName.name ?? '',
      code: share.sector.code.code ?? '',
    );
  }

  Future<void> _loadRegions() async {
    setState(() {
      _isLoadingRegions = true;
    });

    try {
      final regions = await _homeRepository.fetchRegions();
      setState(() {
        _regions = regions.where((region) => region.hasShare).toList();
        _isLoadingRegions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRegions = false;
      });
    }
  }

  Future<void> _loadSectorsForRegion(int regionId) async {
    setState(() {
      _isLoadingSectors = true;
      _sectorTypes.clear();
      _sectors.clear();
      _selectedSectorType = null;
      _selectedSector = null;
    });

    try {
      final response = await _shareRepository.fetchSectorsByRegion(regionId);
      _mainSectors = response.data;
      
      final sectorTypesSelection = <SectorTypeOption>[];
      if (_mainSectors?['data'] != null) {
        final data = _mainSectors!['data'] as List;
        for (int index = 0; index < data.length; index++) {
          final sectorItem = data[index] as Map<String, dynamic>;
          sectorTypesSelection.add(SectorTypeOption(
            id: index.toString(),
            name: sectorItem['key'] ?? '',
          ));
        }
      }

      setState(() {
        _sectorTypes = sectorTypesSelection;
        _isLoadingSectors = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSectors = false;
      });
    }
  }

  void _onRegionChanged(region_model.Region? region) {
    if (region != null) {
      setState(() {
        _selectedRegion = region;
        _formData['region_id'] = region.id.toString();
        _errors.remove('region');
        _hasErrors.remove('region');
      });
      _loadSectorsForRegion(region.id);
    }
  }

  void _onSectorTypeChanged(SectorTypeOption? sectorType) {
    if (sectorType != null && _mainSectors != null) {
      setState(() {
        _selectedSectorType = sectorType;
        _errors.remove('sector_type');
        _hasErrors.remove('sector_type');
        _sectors.clear();
        _selectedSector = null;
      });

      final sectorIndex = int.parse(sectorType.id);
      final data = _mainSectors!['data'] as List;
      if (sectorIndex < data.length) {
        final selectedSectorData = data[sectorIndex] as Map<String, dynamic>;
        final sectorCodes = selectedSectorData['code'] as List?;
        
        if (sectorCodes != null) {
          final sectorOptions = sectorCodes.map((code) {
            final codeMap = code as Map<String, dynamic>;
            return SectorOption(
              id: codeMap['id'] ?? 0,
              name: codeMap['name'] ?? '',
              code: codeMap['code'] ?? '',
            );
          }).toList();

          setState(() {
            _sectors = sectorOptions;
          });
        }
      }
    }
  }

  void _onSectorChanged(SectorOption? sector) {
    if (sector != null) {
      setState(() {
        _selectedSector = sector;
        _formData['sector_id'] = sector.id.toString();
        _errors.remove('sector');
        _hasErrors.remove('sector');
      });
    }
  }

  // Form validation
  bool _validateForm() {
    _errors.clear();
    _hasErrors.clear();

    if (_formData['owner_name']?.isEmpty ?? true) {
      _hasErrors['owner_name'] = true;
    }

    if (_selectedRegion == null) {
      _hasErrors['region'] = true;
    }

    if (_selectedSectorType == null) {
      _hasErrors['sector_type'] = true;
    }

    if (_selectedSector == null) {
      _hasErrors['sector'] = true;
    }

    if (_formData['quantity']?.isEmpty ?? true) {
      _hasErrors['quantity'] = true;
    } else {
      final quantity = int.tryParse(_formData['quantity']!);
      if (quantity == null || quantity <= 0) {
        _hasErrors['quantity'] = true;
      }
    }

    if (_formData['price']?.isEmpty ?? true) {
      _hasErrors['price'] = true;
    } else {
      final price = double.tryParse(_formData['price']!);
      if (price == null || price <= 0) {
        _hasErrors['price'] = true;
      }
    }

    return _hasErrors.isEmpty;
  }

  // Generate confirmation message
  String _getConfirmationMessage() {
    final action = _currentType == 'buy' ? 'شراء' : 'بيع';
    final actionVerb = _currentType == 'buy' ? 'تشتري' : 'تبيع';
    final regionName = _selectedRegion?.name ?? '';
    final sectorTypeName = _selectedSectorType?.name ?? '';
    final sectorName = _selectedSector?.code ?? '';
    final quantity = _formatNumber(_formData['quantity'] ?? '');
    final price = _formatNumber(_formData['price'] ?? '');

    return 'أنت تريد أن $actionVerb $quantity سهم في المقسم $sectorName من نوع $sectorTypeName في منطقة $regionName بسعر $price ليرة سورية للسهم الواحد.';
  }

  String _formatNumber(String number) {
    if (number.isEmpty) return '';
    return number.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  void _showConfirmation() async {
    if (!_validateForm()) {
      setState(() {});
      await showCustomDialog(
        context: context,
        title: 'خطأ في التحقق',
        message: 'يرجى إكمال كافة الحقول المطلوبة',
        okButtonText: 'موافق',
      );
      return;
    }

    await showCustomDialog(
      context: context,
      title: widget.mode == ShareFormMode.create ? 'تأكيد الإعلان' : 'تأكيد التحديث',
      message: _getConfirmationMessage(),
      okButtonText: widget.mode == ShareFormMode.create ? 'تأكيد' : 'تحديث',
      cancelButtonText: 'إلغاء',
      onOkPressed: _submitForm,
    );
  }

  Future<void> _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final quantity = int.tryParse(_formData['quantity'] ?? '') ?? 0;
      final price = double.tryParse(_formData['price'] ?? '') ?? 0.0;
      final regionId = int.tryParse(_formData['region_id'] ?? '') ?? 0;
      final sectorId = int.tryParse(_formData['sector_id'] ?? '') ?? 0;

      Map<String, dynamic> response;

      if (widget.mode == ShareFormMode.create) {
        if (_currentType == 'buy') {
          response = await _shareRepository.createBuyShare(
            regionId: regionId,
            sectorId: sectorId,
            quantity: quantity,
            ownerName: _formData['owner_name']!,
            price: price,
          );
        } else {
          response = await _shareRepository.createSellShare(
            regionId: regionId,
            sectorId: sectorId,
            quantity: quantity,
            ownerName: _formData['owner_name']!,
            price: price,
          );
        }
      } else {
        response = await _shareRepository.updateShare(
          shareId: widget.existingShare!.id,
          regionId: regionId,
          sectorId: sectorId,
          quantity: quantity,
          ownerName: _formData['owner_name']!,
          price: price,
          transactionType: _currentType, // Add transaction_type for update
        );
      }

      setState(() {
        _isSubmitting = false;
      });

      if (response['success'] == true || response.containsKey('id')) {
        if (mounted) {
          await showCustomDialog(
            context: context,
            title: widget.mode == ShareFormMode.create ? 'تم الإنشاء بنجاح' : 'تم التحديث بنجاح',
            message: widget.mode == ShareFormMode.create 
                ? 'تم إنشاء الإعلان بنجاح'
                : 'تم تحديث الإعلان بنجاح',
            onOkPressed: () {
              if (widget.mode == ShareFormMode.update) {
                // For update mode, return a result to trigger reload
                Navigator.of(context).pop(true); // Return true to indicate successful update
              } else {
                // For create mode, just pop back
                Navigator.of(context).pop();
                // Optionally navigate to specific share page
                if (response.containsKey('id')) {
                  // Navigate to share details page with ID: response['id']
                }
              }
            },
          );
        }
      } else {
        final errorMessage = response['message'] as String? ?? 'فشل في ${widget.mode == ShareFormMode.create ? "إنشاء" : "تحديث"} الإعلان';
        if (mounted) {
          ToastHelper.showToast(context, errorMessage, isError: true);
        }
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      String errorMessage = 'حدث خطأ: ${e.toString()}';
      if (e is DioException && e.response?.data is Map) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }

      if (mounted) {
        ToastHelper.showToast(context, errorMessage, isError: true);
      }

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F2),
        appBar: CustomAppBar(
          onBackPressed: () => Navigator.of(context).pop(),
          onLogoPressed: () => Navigator.of(context).pop(),
        ),
        body: _buildFormContent(),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Page title
                Text(
                  widget.mode == ShareFormMode.create 
                      ? 'إضافة إعلان عن أسهم تنظيمية'
                      : 'تعديل إعلان الأسهم',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Cairo',
                  ),
                ),

                // Buy/Sell radio buttons
                CustomRadioButtons(
                  radioButtons: [
                    RadioOption(
                      id: 'buy',
                      label: 'أريد أن أشتري',
                      value: 'buy',
                    ),
                    RadioOption(
                      id: 'sell',
                      label: 'أريد أن أبيع',
                      value: 'sell',
                    ),
                  ],
                  selectedId: _currentType,
                  onChanged: (value) {
                    setState(() {
                      _currentType = value;
                    });
                  },
                ),

               // const SizedBox(height: 2),

                                                 // Region dropdown
                CustomDropdown<region_model.Region>(
                  labelText: 'المنطقة',
                  value: _selectedRegion,
                  items: _regions,
                  itemLabel: (region) => region.name,
                  itemValue: (region) => region.id.toString(),
                  onChanged: _onRegionChanged,
                  hintText: 'اختر المنطقة',
                  emptyMessage: 'لا توجد مناطق متاحة',
                  hasError: _hasErrors['region'] ?? false,
                  isLoading: _isLoadingRegions,
                ),

                const SizedBox(height: 16),

                // Sector type dropdown
                CustomDropdown<SectorTypeOption>(
                  labelText: 'نوع المقسم',
                  value: _selectedSectorType,
                  items: _sectorTypes,
                  itemLabel: (sectorType) => sectorType.name,
                  itemValue: (sectorType) => sectorType.id,
                  onChanged: _onSectorTypeChanged,
                  hintText: 'اختر نوع المقسم',
                  emptyMessage: 'يرجى اختيار المنطقة أولاً',
                  isLoading: _isLoadingSectors,
                  isEnabled: _selectedRegion != null,
                  hasError: _hasErrors['sector_type'] ?? false,
                ),

                const SizedBox(height: 16),

                // Sector dropdown
                CustomDropdown<SectorOption>(
                  labelText: 'المقسم',
                  value: _selectedSector,
                  items: _sectors,
                  itemLabel: (sector) => sector.code,
                  itemValue: (sector) => sector.id.toString(),
                  onChanged: _onSectorChanged,
                  hintText: 'اختر المقسم',
                  emptyMessage: 'يرجى اختيار نوع المقسم أولاً',
                  isEnabled: _selectedSectorType != null,
                  hasError: _hasErrors['sector'] ?? false,
                ),

                const SizedBox(height: 16),

                // Owner name input
                CustomTextField(
                  labelText: 'صاحب العلاقة',
                  hintText: 'أدخل اسم صاحب العلاقة',
                  value: _formData['owner_name'],
                  onChanged: (value) {
                    _formData['owner_name'] = value;
                    if (value.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _errors.remove('owner_name');
                            _hasErrors.remove('owner_name');
                          });
                        }
                      });
                    }
                  },
                  onClear: () {
                    setState(() {
                      _formData['owner_name'] = '';
                      _errors.remove('owner_name');
                      _hasErrors.remove('owner_name');
                    });
                  },
                  hasError: _hasErrors['owner_name'] ?? false,
                ),

                const SizedBox(height: 16),

                // Quantity input
                CustomTextField(
                  labelText: 'عدد الأسهم (${_currentType == 'buy' ? 'المطلوبة' : 'المعروضة'})',
                  hintText: 'أدخل عدد الأسهم',
                  value: _formData['quantity'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    _formData['quantity'] = value;
                    if (value.isNotEmpty && (int.tryParse(value) ?? 0) > 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _errors.remove('quantity');
                            _hasErrors.remove('quantity');
                          });
                        }
                      });
                    }
                  },
                  onClear: () {
                    setState(() {
                      _formData['quantity'] = '';
                      _errors.remove('quantity');
                      _hasErrors.remove('quantity');
                    });
                  },
                  hasError: _hasErrors['quantity'] ?? false,
                ),

                const SizedBox(height: 16),

                // Price input
                CustomTextField(
                  labelText: 'سعر السهم الواحد (ليرة سورية)',
                  hintText: 'أدخل السعر',
                  value: _formData['price'],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (value) {
                    _formData['price'] = value;
                    if (value.isNotEmpty && (double.tryParse(value) ?? 0) > 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _errors.remove('price');
                            _hasErrors.remove('price');
                          });
                        }
                      });
                    }
                  },
                  onClear: () {
                    setState(() {
                      _formData['price'] = '';
                      _errors.remove('price');
                      _hasErrors.remove('price');
                    });
                  },
                  hasError: _hasErrors['price'] ?? false,
                ),
              ],
            ),
          ),
        ),

        // Submit button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CustomButton(
                title: widget.mode == ShareFormMode.create 
                    ? 'إضافة إعلان ${_currentType == 'buy' ? 'الشراء' : 'البيع'}'
                    : 'تحديث الإعلان',
                onPressed: _showConfirmation,
                hasGradient: true,
                gradientColors: const [
                  Color(0xFF633E3D),
                  Color(0xFF774B46),
                  Color(0xFF8D5E52),
                  Color(0xFFA47764),
                  Color(0xFFBDA28C),
                ],
                isLoading: _isSubmitting,
                height: 45,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 