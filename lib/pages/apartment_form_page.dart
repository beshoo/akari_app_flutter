import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../data/models/region_model.dart' as region_model;
import '../data/models/apartment_model.dart';
import '../data/repositories/home_repository.dart';
import '../data/repositories/share_repository.dart';
import '../data/repositories/apartment_repository.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_radio_buttons.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dialog.dart';
import '../utils/toast_helper.dart';
import '../services/secure_storage.dart';
import '../utils/logger.dart';

enum ApartmentFormMode { create, update }

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

class ApartmentFormPage extends StatefulWidget {
  final ApartmentFormMode mode;
  final Apartment? existingApartment; // For update mode

  const ApartmentFormPage({
    super.key,
    required this.mode,
    this.existingApartment,
  });

  @override
  State<ApartmentFormPage> createState() => _ApartmentFormPageState();
}

class _ApartmentFormPageState extends State<ApartmentFormPage> {
  final HomeRepository _homeRepository = HomeRepository();
  final ShareRepository _shareRepository = ShareRepository();
  final ApartmentRepository _apartmentRepository = ApartmentRepository();

  // Form controllers and state
  String _currentType = 'buy';
  final Map<String, String> _formData = {
    'owner_name': '',
    'region_id': '',
    'sector_id': '',
    'direction_id': '',
    'apartment_type_id': '',
    'payment_method_id': '',
    'apartment_status_id': '',
    'area': '',
    'floor': '',
    'rooms_count': '',
    'salons_count': '',
    'balcony_count': '',
    'is_taras': '0',
    'equity': '',
    'price': '',
  };

  // Dropdown data
  List<region_model.Region> _regions = [];
  List<SectorTypeOption> _sectorTypes = [];
  List<SectorOption> _sectors = [];
  List<ApartmentType> _apartmentTypes = [];
  List<Direction> _directions = [];
  List<ApartmentStatus> _apartmentStatuses = [];
  List<PaymentMethod> _paymentMethods = [];
  Map<String, dynamic>? _mainSectors;

  // Loading states
  bool _isLoadingRegions = false;
  bool _isLoadingSectors = false;
  bool _isLoadingApartmentTypes = false;
  bool _isLoadingDirections = false;
  bool _isLoadingApartmentStatuses = false;
  bool _isLoadingPaymentMethods = false;
  bool _isSubmitting = false;

  // Error states
  final Map<String, String> _errors = {};
  final Map<String, bool> _hasErrors = {};

  // Validation toggle
  final bool _isValidationEnabled = true;

  // Selected values for dependent dropdowns
  region_model.Region? _selectedRegion;
  SectorTypeOption? _selectedSectorType;
  SectorOption? _selectedSector;
  ApartmentType? _selectedApartmentType;
  Direction? _selectedDirection;
  ApartmentStatus? _selectedApartmentStatus;
  PaymentMethod? _selectedPaymentMethod;

  // Fields to show based on apartment type
  List<String> _fieldsToShow = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.mode == ApartmentFormMode.update && widget.existingApartment != null) {
      final apartment = widget.existingApartment!;
      _currentType = apartment.transactionType;
      _formData['owner_name'] = apartment.ownerName;
      _formData['region_id'] = apartment.regionId.toString();
      _formData['sector_id'] = apartment.sectorId.toString();
      _formData['direction_id'] = apartment.directionId.toString();
      _formData['apartment_type_id'] = apartment.apartmentTypeId.toString();
      _formData['payment_method_id'] = apartment.paymentMethodId.toString();
      _formData['apartment_status_id'] = apartment.apartmentStatusId.toString();
      _formData['area'] = apartment.area.toString();
      _formData['floor'] = apartment.floor.toString();
      _formData['rooms_count'] = apartment.roomsCount.toString();
      _formData['salons_count'] = apartment.salonsCount.toString();
      _formData['balcony_count'] = apartment.balconyCount.toString();
      _formData['is_taras'] = apartment.isTaras.toString();
      _formData['equity'] = apartment.equity;
      _formData['price'] = apartment.price;
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadRegions(),
      _loadApartmentTypes(),
      _loadDirections(),
      _loadApartmentStatuses(),
      _loadPaymentMethods(),
    ]);
    
    // If updating, load dependent data
    if (widget.mode == ApartmentFormMode.update && widget.existingApartment != null) {
      final apartment = widget.existingApartment!;
      await _loadSectorsForRegion(apartment.regionId);
      _setInitialValues(apartment);
    }
  }

  void _setInitialValues(Apartment apartment) {
    // Find and set region
    final foundRegion = _regions.where((region) => region.id == apartment.regionId).toList();
    if (foundRegion.isNotEmpty) {
      _selectedRegion = foundRegion.first;
    }

    // Find and set apartment type
    final foundApartmentType = _apartmentTypes.where((type) => type.id == apartment.apartmentTypeId).toList();
    if (foundApartmentType.isNotEmpty) {
      _selectedApartmentType = foundApartmentType.first;
      _fieldsToShow = foundApartmentType.first.fields;
    }

    // Find and set direction
    final foundDirection = _directions.where((direction) => direction.id == apartment.directionId).toList();
    if (foundDirection.isNotEmpty) {
      _selectedDirection = foundDirection.first;
    }

    // Find and set apartment status
    final foundApartmentStatus = _apartmentStatuses.where((status) => status.id == apartment.apartmentStatusId).toList();
    if (foundApartmentStatus.isNotEmpty) {
      _selectedApartmentStatus = foundApartmentStatus.first;
    }

    // Find and set payment method
    final foundPaymentMethod = _paymentMethods.where((method) => method.id == apartment.paymentMethodId).toList();
    if (foundPaymentMethod.isNotEmpty) {
      _selectedPaymentMethod = foundPaymentMethod.first;
    }
    
    // Set sector info
    _selectedSector = SectorOption(
      id: apartment.sectorId,
      name: apartment.sector.sectorName.name ?? '',
      code: apartment.sector.code.code ?? '',
    );
  }

  Future<void> _loadRegions() async {
    setState(() {
      _isLoadingRegions = true;
    });

    try {
      final regions = await _homeRepository.fetchRegions();
      setState(() {
        _regions = regions.where((region) => region.hasApartment).toList();
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

  Future<void> _loadApartmentTypes() async {
    setState(() {
      _isLoadingApartmentTypes = true;
    });

    try {
      // Try to load from cache first
      List<Map<String, dynamic>>? cachedTypes = await SecureStorage.getApartmentDropdownData('types');
      
      if (cachedTypes != null && cachedTypes.isNotEmpty) {
        Logger.log('Loading apartment types from cache');
        final types = cachedTypes.map((json) => ApartmentType.fromJson(json)).toList();
        setState(() {
          _apartmentTypes = types;
          _isLoadingApartmentTypes = false;
        });
      } else {
        Logger.log('Loading apartment types from API');
        final apartmentTypes = await _apartmentRepository.fetchApartmentTypes();
        await SecureStorage.setApartmentDropdownData('types', apartmentTypes.map((t) => t.toJson()).toList());
        setState(() {
          _apartmentTypes = apartmentTypes;
          _isLoadingApartmentTypes = false;
        });
      }
    } catch (e) {
      Logger.log('Error loading apartment types: $e');
      setState(() {
        _isLoadingApartmentTypes = false;
      });
    }
  }

  Future<void> _loadDirections() async {
    setState(() {
      _isLoadingDirections = true;
    });

    try {
      // Try to load from cache first
      List<Map<String, dynamic>>? cachedDirections = await SecureStorage.getApartmentDropdownData('directions');
      
      if (cachedDirections != null && cachedDirections.isNotEmpty) {
        Logger.log('Loading directions from cache');
        final directions = cachedDirections.map((json) => Direction.fromJson(json)).toList();
        setState(() {
          _directions = directions;
          _isLoadingDirections = false;
        });
      } else {
        Logger.log('Loading directions from API');
        final directions = await _apartmentRepository.fetchDirections();
        await SecureStorage.setApartmentDropdownData('directions', directions.map((d) => d.toJson()).toList());
        setState(() {
          _directions = directions;
          _isLoadingDirections = false;
        });
      }
    } catch (e) {
      Logger.log('Error loading directions: $e');
      setState(() {
        _isLoadingDirections = false;
      });
    }
  }

  Future<void> _loadApartmentStatuses() async {
    setState(() {
      _isLoadingApartmentStatuses = true;
    });

    try {
      // Try to load from cache first
      List<Map<String, dynamic>>? cachedStatuses = await SecureStorage.getApartmentDropdownData('statuses');
      
      if (cachedStatuses != null && cachedStatuses.isNotEmpty) {
        Logger.log('Loading apartment statuses from cache');
        final statuses = cachedStatuses.map((json) => ApartmentStatus.fromJson(json)).toList();
        setState(() {
          _apartmentStatuses = statuses;
          _isLoadingApartmentStatuses = false;
        });
      } else {
        Logger.log('Loading apartment statuses from API');
        final apartmentStatuses = await _apartmentRepository.fetchApartmentStatuses();
        await SecureStorage.setApartmentDropdownData('statuses', apartmentStatuses.map((s) => s.toJson()).toList());
        setState(() {
          _apartmentStatuses = apartmentStatuses;
          _isLoadingApartmentStatuses = false;
        });
      }
    } catch (e) {
      Logger.log('Error loading apartment statuses: $e');
      setState(() {
        _isLoadingApartmentStatuses = false;
      });
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingPaymentMethods = true;
    });

    try {
      // Try to load from cache first
      List<Map<String, dynamic>>? cachedPaymentMethods = await SecureStorage.getApartmentDropdownData('payment_methods');
      
      if (cachedPaymentMethods != null && cachedPaymentMethods.isNotEmpty) {
        Logger.log('Loading payment methods from cache');
        final paymentMethods = cachedPaymentMethods.map((json) => PaymentMethod.fromJson(json)).toList();
        setState(() {
          _paymentMethods = paymentMethods;
          _isLoadingPaymentMethods = false;
        });
      } else {
        Logger.log('Loading payment methods from API');
        final paymentMethods = await _apartmentRepository.fetchPaymentMethods();
        await SecureStorage.setApartmentDropdownData('payment_methods', paymentMethods.map((p) => p.toJson()).toList());
        setState(() {
          _paymentMethods = paymentMethods;
          _isLoadingPaymentMethods = false;
        });
      }
    } catch (e) {
      Logger.log('Error loading payment methods: $e');
      setState(() {
        _isLoadingPaymentMethods = false;
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

  void _onApartmentTypeChanged(ApartmentType? apartmentType) {
    if (apartmentType != null) {
      setState(() {
        _selectedApartmentType = apartmentType;
        _formData['apartment_type_id'] = apartmentType.id.toString();
        _fieldsToShow = apartmentType.fields;
        _errors.remove('apartment_type');
        _hasErrors.remove('apartment_type');
      });
    }
  }

  void _onDirectionChanged(Direction? direction) {
    if (direction != null) {
      setState(() {
        _selectedDirection = direction;
        _formData['direction_id'] = direction.id.toString();
        _errors.remove('direction');
        _hasErrors.remove('direction');
      });
    }
  }

  void _onApartmentStatusChanged(ApartmentStatus? apartmentStatus) {
    if (apartmentStatus != null) {
      setState(() {
        _selectedApartmentStatus = apartmentStatus;
        _formData['apartment_status_id'] = apartmentStatus.id.toString();
        _errors.remove('apartment_status');
        _hasErrors.remove('apartment_status');
      });
    }
  }

  void _onPaymentMethodChanged(PaymentMethod? paymentMethod) {
    if (paymentMethod != null) {
      setState(() {
        _selectedPaymentMethod = paymentMethod;
        _formData['payment_method_id'] = paymentMethod.id.toString();
        _errors.remove('payment_method');
        _hasErrors.remove('payment_method');
      });
    }
  }

  // Form validation
  bool _validateForm() {
    _errors.clear();
    _hasErrors.clear();

    // Bypass validation if disabled
    if (!_isValidationEnabled) {
      return true;
    }

    // Required dropdowns
    if (_selectedRegion == null) {
      _hasErrors['region'] = true;
    }

    if (_selectedSectorType == null) {
      _hasErrors['sector_type'] = true;
    }
    
    if (_selectedSector == null) {
      _hasErrors['sector'] = true;
    }

    if (_selectedApartmentType == null) {
      _hasErrors['apartment_type'] = true;
    }

    if (_selectedDirection == null) {
      _hasErrors['direction'] = true;
    }

    if (_selectedApartmentStatus == null) {
      _hasErrors['apartment_status'] = true;
    }

    if (_selectedPaymentMethod == null) {
      _hasErrors['payment_method'] = true;
    }

    // Required text fields
    if (_formData['owner_name']?.isEmpty ?? true) {
      _hasErrors['owner_name'] = true;
    }

    if (_formData['area']?.isEmpty ?? true) {
      _hasErrors['area'] = true;
    } else {
      final area = int.tryParse(_formData['area']!);
      if (area == null || area <= 0) {
        _hasErrors['area'] = true;
      }
    }

    if (_formData['equity']?.isEmpty ?? true) {
      _hasErrors['equity'] = true;
    } else {
      final equity = int.tryParse(_formData['equity']!);
      if (equity == null || equity <= 0) {
        _hasErrors['equity'] = true;
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

    // Conditional field validations based on apartment type
    if (_fieldsToShow.contains('floor')) {
      if (_formData['floor']?.isEmpty ?? true) {
        _hasErrors['floor'] = true;
      } else {
        final floor = int.tryParse(_formData['floor']!);
        if (floor == null || floor < 0) {
          _hasErrors['floor'] = true;
        }
      }
    }

    if (_fieldsToShow.contains('rooms_count')) {
      if (_formData['rooms_count']?.isEmpty ?? true) {
        _hasErrors['rooms_count'] = true;
      } else {
        final roomsCount = int.tryParse(_formData['rooms_count']!);
        if (roomsCount == null || roomsCount <= 0) {
          _hasErrors['rooms_count'] = true;
        }
      }
    }

    if (_fieldsToShow.contains('salons_count')) {
      if (_formData['salons_count']?.isEmpty ?? true) {
        _hasErrors['salons_count'] = true;
      } else {
        final salonsCount = int.tryParse(_formData['salons_count']!);
        if (salonsCount == null || salonsCount < 0) {
          _hasErrors['salons_count'] = true;
        }
      }
    }

    if (_fieldsToShow.contains('balcony_count')) {
      if (_formData['balcony_count']?.isEmpty ?? true) {
        _hasErrors['balcony_count'] = true;
      } else {
        final balconyCount = int.tryParse(_formData['balcony_count']!);
        if (balconyCount == null || balconyCount < 0) {
          _hasErrors['balcony_count'] = true;
        }
      }
    }

    // is_taras validation is not needed as it's a radio button with default value
    
    return _hasErrors.isEmpty;
  }

  // Generate confirmation message
  String _getConfirmationMessage() {
    final actionVerb = _currentType == 'buy' ? 'تشتري' : 'تبيع';
    final regionName = _selectedRegion?.name ?? '';
    final sectorTypeName = _selectedSectorType?.name ?? '';
    final sectorName = _selectedSector?.code ?? '';
    final apartmentTypeName = _selectedApartmentType?.name ?? '';
    final paymentMethodName = _selectedPaymentMethod?.name ?? '';
    final price = _formatNumber(_formData['price'] ?? '');

    String message = 'أنت تريد أن $actionVerb عقار من نوع $apartmentTypeName في المقسم $sectorName من نوع $sectorTypeName في منطقة $regionName بسعر $price ليرة سورية';
    
    if (_selectedPaymentMethod != null) {
      message += ' وطريقة الدفع $paymentMethodName';
    }
    
    message += '.';

    return message;
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
        message: ' يرجى إكمال كافة الحقول المطلوبة',
        okButtonText: 'موافق',
      );
      return;
    }

    await showCustomDialog(
      context: context,
      title: widget.mode == ApartmentFormMode.create ? 'تأكيد الإعلان' : 'تأكيد التحديث',
      message: _getConfirmationMessage(),
      okButtonText: widget.mode == ApartmentFormMode.create ? 'تأكيد' : 'تحديث',
      cancelButtonText: 'إلغاء',
      onOkPressed: _submitForm,
    );
  }

  Future<void> _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final regionId = int.tryParse(_formData['region_id'] ?? '') ?? 0;
      final sectorId = int.tryParse(_formData['sector_id'] ?? '') ?? 0;
      final directionId = int.tryParse(_formData['direction_id'] ?? '') ?? 0;
      final apartmentTypeId = int.tryParse(_formData['apartment_type_id'] ?? '') ?? 0;
      final apartmentStatusId = int.tryParse(_formData['apartment_status_id'] ?? '') ?? 0;
      final paymentMethodId = int.tryParse(_formData['payment_method_id'] ?? '') ?? 0;
      final area = int.tryParse(_formData['area'] ?? '') ?? 0;
      final price = _formData['price']!;
      final equity = _formData['equity']!;
      final ownerName = _formData['owner_name']!;

      // Optional fields
      final floor = _fieldsToShow.contains('floor') ? int.tryParse(_formData['floor'] ?? '') : null;
      final roomsCount = _fieldsToShow.contains('rooms_count') ? int.tryParse(_formData['rooms_count'] ?? '') : null;
      final salonsCount = _fieldsToShow.contains('salons_count') ? int.tryParse(_formData['salons_count'] ?? '') : null;
      final balconyCount = _fieldsToShow.contains('balcony_count') ? int.tryParse(_formData['balcony_count'] ?? '') : null;
      final isTaras = _fieldsToShow.contains('is_taras') ? _formData['is_taras'] : '0';

      Map<String, dynamic> response;

      if (widget.mode == ApartmentFormMode.create) {
        if (_currentType == 'buy') {
          response = await _apartmentRepository.createBuyApartment(
            regionId: regionId,
            sectorId: sectorId,
            directionId: directionId,
            apartmentTypeId: apartmentTypeId,
            paymentMethodId: paymentMethodId,
            apartmentStatusId: apartmentStatusId,
            area: area,
            ownerName: ownerName,
            price: price,
            equity: equity,
            floor: floor,
            roomsCount: roomsCount,
            salonsCount: salonsCount,
            balconyCount: balconyCount,
            isTaras: isTaras,
          );
        } else {
          response = await _apartmentRepository.createSellApartment(
            regionId: regionId,
            sectorId: sectorId,
            directionId: directionId,
            apartmentTypeId: apartmentTypeId,
            paymentMethodId: paymentMethodId,
            apartmentStatusId: apartmentStatusId,
            area: area,
            ownerName: ownerName,
            price: price,
            equity: equity,
            floor: floor,
            roomsCount: roomsCount,
            salonsCount: salonsCount,
            balconyCount: balconyCount,
            isTaras: isTaras,
          );
        }
      } else {
        response = await _apartmentRepository.updateApartment(
          apartmentId: widget.existingApartment!.id,
          regionId: regionId,
          sectorId: sectorId,
          directionId: directionId,
          apartmentTypeId: apartmentTypeId,
          paymentMethodId: paymentMethodId,
          apartmentStatusId: apartmentStatusId,
          area: area,
          ownerName: ownerName,
          price: price,
          equity: equity,
          floor: floor,
          roomsCount: roomsCount,
          salonsCount: salonsCount,
          balconyCount: balconyCount,
          isTaras: isTaras,
        );
      }

      if (response['success'] == true || response.containsKey('id')) {
        setState(() {
          _isSubmitting = false;
        });

        if (mounted) {
          await showCustomDialog(
            context: context,
            title: widget.mode == ApartmentFormMode.create ? 'تم الإنشاء بنجاح' : 'تم التحديث بنجاح',
            message: widget.mode == ApartmentFormMode.create 
                ? 'تم إنشاء الإعلان بنجاح'
                : 'تم تحديث الإعلان بنجاح',
            onOkPressed: () {
              Navigator.of(context).pop(); // Pop the form page
              // Optionally navigate to specific apartment page
              if (response.containsKey('id')) {
                // Navigate to apartment details page with ID: response['id']
              }
            },
          );
        }
      } else {
        final errorMessage = response['message'] as String? ?? 'فشل في ${widget.mode == ApartmentFormMode.create ? "إنشاء" : "تحديث"} الإعلان';
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
                  widget.mode == ApartmentFormMode.create 
                      ? 'إضافة إعلان عن عقار'
                      : 'تعديل إعلان العقار',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Cairo',
                  ),
                ),

                const SizedBox(height: 16),

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

                const SizedBox(height: 16),

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

                // Direction dropdown
                CustomDropdown<Direction>(
                  labelText: 'اتجاه العقار',
                  value: _selectedDirection,
                  items: _directions,
                  itemLabel: (direction) => direction.name,
                  itemValue: (direction) => direction.id.toString(),
                  onChanged: _onDirectionChanged,
                  hintText: 'اختر اتجاه العقار',
                  emptyMessage: 'لا توجد اتجاهات متاحة',
                  hasError: _hasErrors['direction'] ?? false,
                  isLoading: _isLoadingDirections,
                ),

                const SizedBox(height: 16),

                // Apartment type dropdown
                CustomDropdown<ApartmentType>(
                  labelText: 'نوع العقار',
                  value: _selectedApartmentType,
                  items: _apartmentTypes,
                  itemLabel: (apartmentType) => apartmentType.name,
                  itemValue: (apartmentType) => apartmentType.id.toString(),
                  onChanged: _onApartmentTypeChanged,
                  hintText: 'اختر نوع العقار',
                  emptyMessage: 'لا توجد أنواع عقارات متاحة',
                  hasError: _hasErrors['apartment_type'] ?? false,
                  isLoading: _isLoadingApartmentTypes,
                ),

                const SizedBox(height: 16),

                // Apartment status dropdown
                CustomDropdown<ApartmentStatus>(
                  labelText: 'حالة العقار',
                  value: _selectedApartmentStatus,
                  items: _apartmentStatuses,
                  itemLabel: (apartmentStatus) => apartmentStatus.name,
                  itemValue: (apartmentStatus) => apartmentStatus.id.toString(),
                  onChanged: _onApartmentStatusChanged,
                  hintText: 'اختر حالة العقار',
                  emptyMessage: 'لا توجد حالات عقارات متاحة',
                  hasError: _hasErrors['apartment_status'] ?? false,
                  isLoading: _isLoadingApartmentStatuses,
                ),

                const SizedBox(height: 16),

                // Area input
                CustomTextField(
                  labelText: 'المساحة',
                  hintText: 'أدخل المساحة',
                  value: _formData['area'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    _formData['area'] = value;
                    if (value.isNotEmpty && (int.tryParse(value) ?? 0) > 0) {
                      setState(() {
                        _errors.remove('area');
                        _hasErrors.remove('area');
                      });
                    }
                  },
                  hasError: _hasErrors['area'] ?? false,
                ),

                const SizedBox(height: 16),

                // Conditional fields based on apartment type
                if (_fieldsToShow.contains('floor')) ...[
                  CustomTextField(
                    labelText: 'الطابق',
                    hintText: 'أدخل الطابق',
                    value: _formData['floor'],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      _formData['floor'] = value;
                      if (value.isNotEmpty && (int.tryParse(value) ?? -1) >= 0) {
                        setState(() {
                          _errors.remove('floor');
                          _hasErrors.remove('floor');
                        });
                      }
                    },
                    hasError: _hasErrors['floor'] ?? false,
                  ),
                  const SizedBox(height: 16),
                ],

                if (_fieldsToShow.contains('rooms_count')) ...[
                  CustomTextField(
                    labelText: 'عدد الغرف',
                    hintText: 'أدخل عدد الغرف',
                    value: _formData['rooms_count'],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      _formData['rooms_count'] = value;
                      if (value.isNotEmpty && (int.tryParse(value) ?? 0) > 0) {
                        setState(() {
                          _errors.remove('rooms_count');
                          _hasErrors.remove('rooms_count');
                        });
                      }
                    },
                    hasError: _hasErrors['rooms_count'] ?? false,
                  ),
                  const SizedBox(height: 16),
                ],

                if (_fieldsToShow.contains('salons_count')) ...[
                  CustomTextField(
                    labelText: 'عدد الصالونات',
                    hintText: 'أدخل عدد الصالونات',
                    value: _formData['salons_count'],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      _formData['salons_count'] = value;
                      if (value.isNotEmpty && (int.tryParse(value) ?? -1) >= 0) {
                        setState(() {
                          _errors.remove('salons_count');
                          _hasErrors.remove('salons_count');
                        });
                      }
                    },
                    hasError: _hasErrors['salons_count'] ?? false,
                  ),
                  const SizedBox(height: 16),
                ],

                if (_fieldsToShow.contains('balcony_count')) ...[
                  CustomTextField(
                    labelText: 'عدد البلكونات',
                    hintText: 'أدخل عدد البلكونات',
                    value: _formData['balcony_count'],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      _formData['balcony_count'] = value;
                      if (value.isNotEmpty && (int.tryParse(value) ?? -1) >= 0) {
                        setState(() {
                          _errors.remove('balcony_count');
                          _hasErrors.remove('balcony_count');
                        });
                      }
                    },
                    hasError: _hasErrors['balcony_count'] ?? false,
                  ),
                  const SizedBox(height: 16),
                ],

                // Owner name input
                CustomTextField(
                  labelText: 'صاحب العلاقة',
                  hintText: 'أدخل اسم صاحب العلاقة',
                  value: _formData['owner_name'],
                  onChanged: (value) {
                    _formData['owner_name'] = value;
                    if (value.isNotEmpty) {
                      setState(() {
                        _errors.remove('owner_name');
                        _hasErrors.remove('owner_name');
                      });
                    }
                  },
                  hasError: _hasErrors['owner_name'] ?? false,
                ),

                const SizedBox(height: 16),

                // Equity input
                CustomTextField(
                  labelText: 'عدد الأسهم المتاحة (${_currentType == 'buy' ? 'المطلوبة' : 'المعروضة'})',
                  hintText: 'أدخل عدد الأسهم',
                  value: _formData['equity'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    _formData['equity'] = value;
                    if (value.isNotEmpty && (int.tryParse(value) ?? 0) > 0) {
                      setState(() {
                        _errors.remove('equity');
                        _hasErrors.remove('equity');
                      });
                    }
                  },
                  hasError: _hasErrors['equity'] ?? false,
                ),

                const SizedBox(height: 16),

                // Price input
                CustomTextField(
                  labelText: 'سعر العقار (ليرة سورية)',
                  hintText: 'أدخل السعر',
                  value: _formData['price'],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (value) {
                    _formData['price'] = value;
                    if (value.isNotEmpty && (double.tryParse(value) ?? 0) > 0) {
                      setState(() {
                        _errors.remove('price');
                        _hasErrors.remove('price');
                      });
                    }
                  },
                  hasError: _hasErrors['price'] ?? false,
                ),

                const SizedBox(height: 16),

                // Payment method dropdown
                CustomDropdown<PaymentMethod>(
                  labelText: 'طريقة الدفع',
                  value: _selectedPaymentMethod,
                  items: _paymentMethods,
                  itemLabel: (paymentMethod) => paymentMethod.name,
                  itemValue: (paymentMethod) => paymentMethod.id.toString(),
                  onChanged: _onPaymentMethodChanged,
                  hintText: 'اختر طريقة الدفع',
                  emptyMessage: 'لا توجد طرق دفع متاحة',
                  hasError: _hasErrors['payment_method'] ?? false,
                  isLoading: _isLoadingPaymentMethods,
                ),

                const SizedBox(height: 16),

                // Taras radio buttons (only if apartment type supports it)
                if (_fieldsToShow.contains('is_taras')) ...[
                  CustomRadioButtons(
                    radioButtons: [
                      RadioOption(
                        id: '1',
                        label: 'يحتوي على تراس',
                        value: '1',
                      ),
                      RadioOption(
                        id: '0',
                        label: 'لا يحتوي على تراس',
                        value: '0',
                      ),
                    ],
                    selectedId: _formData['is_taras'] ?? '0',
                    onChanged: (value) {
                      setState(() {
                        _formData['is_taras'] = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
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
                title: widget.mode == ApartmentFormMode.create 
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