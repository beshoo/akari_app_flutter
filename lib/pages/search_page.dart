import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/region_model.dart' as region_model;
import '../data/repositories/home_repository.dart';
import '../data/repositories/share_repository.dart';
import '../data/repositories/apartment_repository.dart';
import '../data/models/apartment_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_radio_buttons.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dialog.dart';
import '../services/secure_storage.dart';
import '../utils/logger.dart';
import 'search_results_page.dart';

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

class PriceOperatorOption {
  final String id;
  final String name;

  PriceOperatorOption({required this.id, required this.name});
}

class SearchPage extends StatefulWidget {
  final int? regionId;
  final String? currentTab;

  const SearchPage({
    super.key,
    this.regionId,
    this.currentTab,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final HomeRepository _homeRepository = HomeRepository();
  final ShareRepository _shareRepository = ShareRepository();
  final ApartmentRepository _apartmentRepository = ApartmentRepository();

  // Current search type
  String _currentSearchType = 'share';

  // Form data for shares
  final Map<String, String> _shareFormData = {
    'id': '',
    'region_id': '',
    'sector_id': '',
    'quantity': '',
    'price': '',
  };

  // Transaction type for shares (buy/sell)
  String _shareTransactionType = '1'; // '1' for sell, '2' for buy

  // Operators
  String _priceOperator = '=';
  String _quantityOperator = '=';

  // Dropdown data
  List<region_model.Region> _regions = [];
  List<SectorTypeOption> _sectorTypes = [];
  List<SectorOption> _sectors = [];
  Map<String, dynamic>? _mainSectors;

  // Price operators
  final List<PriceOperatorOption> _priceOperators = [
    PriceOperatorOption(id: '=', name: 'مساوي'),
    PriceOperatorOption(id: '>', name: 'أكبر'),
    PriceOperatorOption(id: '<', name: 'أصغر'),
    PriceOperatorOption(id: '>=', name: 'أكبر أو مساوي'),
    PriceOperatorOption(id: '<=', name: 'أصغر أو مساوي'),
  ];

  // Loading states
  bool _isLoadingRegions = false;
  bool _isLoadingSectors = false;
  bool _isSearching = false;

  // Selected values for dependent dropdowns
  region_model.Region? _selectedRegion;
  SectorTypeOption? _selectedSectorType;
  SectorOption? _selectedSector;
  PriceOperatorOption? _selectedPriceOperator;
  PriceOperatorOption? _selectedQuantityOperator;

  // Alert state for service unavailable
  Map<String, dynamic>? _pendingRegionChange;

  // Apartment tab state
  List<SectorTypeOption> _apartmentSectorTypes = [];
  List<SectorOption> _apartmentSectors = [];
  SectorTypeOption? _apartmentSelectedSectorType;
  SectorOption? _apartmentSelectedSector;
  Map<String, dynamic>? _apartmentMainSectors;
  bool _apartmentIsLoadingSectors = false;

  // 1. Add Apartment Search State Variables and Stores
  String _apartmentTransactionType = '1';
  List<ApartmentType> _apartmentTypes = [];
  List<Direction> _directions = [];
  List<ApartmentStatus> _apartmentStatuses = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _apartmentIsLoadingTypes = false;
  bool _apartmentIsLoadingDirections = false;
  bool _apartmentIsLoadingStatuses = false;
  bool _apartmentIsLoadingPayments = false;
  ApartmentType? _apartmentSelectedType;
  Direction? _apartmentSelectedDirection;
  ApartmentStatus? _apartmentSelectedStatus;
  PaymentMethod? _apartmentSelectedPayment;
  List<String> _apartmentFieldsToShow = [];

  String _apartmentPriceOperator = '=';
  String _apartmentEquityOperator = '=';
  PriceOperatorOption? _selectedApartmentPriceOperator;
  PriceOperatorOption? _selectedApartmentEquityOperator;

  // Apartment search form data
  final Map<String, String> _apartmentFormData = {
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Set initial tab based on parameter or default to share
    if (widget.currentTab == 'apartments') {
      _tabController.index = 1;
      _currentSearchType = 'apartment';
    } else {
      _tabController.index = 0;
      _currentSearchType = 'share';
    }

    // Set initial operators
    _selectedPriceOperator = _priceOperators.first;
    _selectedQuantityOperator = _priceOperators.first;
    _selectedApartmentPriceOperator = _priceOperators.first;
    _selectedApartmentEquityOperator = _priceOperators.first;


    _loadInitialData();
    _loadApartmentDropdowns();
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // Apartment tab selected
        _loadApartmentDropdowns();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadRegions();
    
    // If region ID is provided from navigation, auto-select it
    if (widget.regionId != null) {
      // Wait for the next frame to ensure setState from _loadRegions has been applied
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleRegionChangeFromParams(widget.regionId!);
      });
    }
  }

  Future<void> _loadRegions() async {
    setState(() {
      _isLoadingRegions = true;
    });

    try {
      final regions = await _homeRepository.fetchRegions();
      setState(() {
        _regions = regions; // Keep all regions for search
        _isLoadingRegions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRegions = false;
      });
    }
  }

  void _handleRegionChangeFromParams(int regionId) {
    final region = _regions.where((r) => r.id == regionId).toList();
    if (region.isNotEmpty) {
      _handleRegionChange(region.first);
    }
  }

  Future<void> _loadSectorsForRegion(int regionId) async {
    setState(() {
      _isLoadingSectors = true;
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

      if (mounted) {
        setState(() {
          _sectorTypes = sectorTypesSelection;
          _isLoadingSectors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSectors = false;
        });
      }
    }
  }

  void _handleRegionChange(region_model.Region? region) {
    if (region != null) {
      final isShareAvailable = region.hasShare;
      final isApartmentAvailable = region.hasApartment;
      
      // Check if current service becomes unavailable
      bool shouldShowAlert = false;
      String message = '';
      
      if (_currentSearchType == 'share' && !isShareAvailable && isApartmentAvailable) {
        shouldShowAlert = true;
        message = 'الأسهم التنظيمية غير متوفرة في منطقة ${region.name}. سيتم التبديل إلى العقارات.';
      } else if (_currentSearchType == 'apartment' && !isApartmentAvailable && isShareAvailable) {
        shouldShowAlert = true;
        message = 'العقارات غير متوفرة في منطقة ${region.name}. سيتم التبديل إلى الأسهم التنظيمية.';
      }
      
      if (shouldShowAlert) {
        _pendingRegionChange = {
          'region': region,
          'isShareAvailable': isShareAvailable,
          'isApartmentAvailable': isApartmentAvailable,
        };
        showCustomDialog(
          context: context,
          title: 'تغيير المنطقة',
          message: message,
          okButtonText: 'تأكيد',
          cancelButtonText: 'إلغاء',
          onOkPressed: () {
            if (_pendingRegionChange != null) {
              final data = _pendingRegionChange!;
              _proceedWithRegionChange(
                data['region'] as region_model.Region,
                data['isShareAvailable'] as bool,
                data['isApartmentAvailable'] as bool,
              );
              _pendingRegionChange = null;
            }
          },
        );
        return;
      }
      
      _proceedWithRegionChange(region, isShareAvailable, isApartmentAvailable);
    }
  }

  void _proceedWithRegionChange(region_model.Region region, bool isShareAvailable, bool isApartmentAvailable) {
    // Switch tab if current service is not available
    if (_currentSearchType == 'share' && !isShareAvailable && isApartmentAvailable) {
      _tabController.animateTo(1);
      setState(() {
        _currentSearchType = 'apartment';
      });
    } else if (_currentSearchType == 'apartment' && !isApartmentAvailable && isShareAvailable) {
      _tabController.animateTo(0);
      setState(() {
        _currentSearchType = 'share';
      });
    }

    setState(() {
      _selectedRegion = region;
      _shareFormData['region_id'] = region.id.toString();

      // Clear dependent fields for share form
      _sectorTypes.clear();
      _sectors.clear();
      _selectedSectorType = null;
      _selectedSector = null;

      // Reset apartment dropdowns and reload them for the new region
      _apartmentSelectedType = null;
      _apartmentSelectedDirection = null;
      _apartmentSelectedStatus = null;
      _apartmentSelectedPayment = null;
      _apartmentTypes.clear();
      _directions.clear();
      _apartmentStatuses.clear();
      _paymentMethods.clear();
      _apartmentFieldsToShow.clear();
    });

    if (_currentSearchType == 'share' && isShareAvailable) {
      _loadSectorsForRegion(region.id);
    }
    if (_currentSearchType == 'apartment' && isApartmentAvailable) {
      _loadApartmentDropdowns();
    }
  }
  
  void _onSectorTypeChanged(SectorTypeOption? sectorType) {
    if (sectorType != null && _mainSectors != null) {
      setState(() {
        _selectedSectorType = sectorType;
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

          if (mounted) {
            setState(() {
              _sectors = sectorOptions;
            });
          }
        }
      }
    }
  }

  void _onSectorChanged(SectorOption? sector) {
    if (sector != null) {
      setState(() {
        _selectedSector = sector;
        _shareFormData['sector_id'] = sector.id.toString();
      });
    }
  }

  List<RadioOption> get _availableSearchTypes {
    if (_selectedRegion == null) {
      return [
        RadioOption(id: 'share', label: 'أسهم تنظيمية', value: 'share'),
        RadioOption(id: 'apartment', label: 'عقارات', value: 'apartment'),
      ];
    }

    final options = <RadioOption>[];
    if (_selectedRegion!.hasShare) {
      options.add(RadioOption(id: 'share', label: 'أسهم تنظيمية', value: 'share'));
    }
    if (_selectedRegion!.hasApartment) {
      options.add(RadioOption(id: 'apartment', label: 'عقارات', value: 'apartment'));
    }

    return options;
  }

  Future<void> _performSearch() async {
    if (_currentSearchType == 'share') {
      setState(() {
        _isSearching = true;
      });

      try {
        final searchResult = await _shareRepository.searchShares(
          id: _shareFormData['id']?.isNotEmpty == true ? _shareFormData['id'] : null,
          regionId: _shareFormData['region_id']?.isNotEmpty == true ? int.tryParse(_shareFormData['region_id']!) : null,
          sectorId: _shareFormData['sector_id']?.isNotEmpty == true ? int.tryParse(_shareFormData['sector_id']!) : null,
          quantity: _shareFormData['quantity']?.isNotEmpty == true ? _shareFormData['quantity'] : null,
          quantityOperator: _quantityOperator,
          transactionType: int.tryParse(_shareTransactionType),
          price: _shareFormData['price']?.isNotEmpty == true ? _shareFormData['price'] : null,
          priceOperator: _priceOperator,
        );

        setState(() {
          _isSearching = false;
        });

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchResultsPage(
                searchType: 'share',
                searchData: searchResult.toJson(),
                searchQuery: 'بحث الأسهم',
                originalSearchParams: {
                  'id': _shareFormData['id']?.isNotEmpty == true ? _shareFormData['id'] : null,
                  'regionId': _shareFormData['region_id']?.isNotEmpty == true ? int.tryParse(_shareFormData['region_id']!) : null,
                  'sectorId': _shareFormData['sector_id']?.isNotEmpty == true ? int.tryParse(_shareFormData['sector_id']!) : null,
                  'quantity': _shareFormData['quantity']?.isNotEmpty == true ? _shareFormData['quantity'] : null,
                  'quantityOperator': _quantityOperator,
                  'transactionType': int.tryParse(_shareTransactionType),
                  'price': _shareFormData['price']?.isNotEmpty == true ? _shareFormData['price'] : null,
                  'priceOperator': _priceOperator,
                  'ownerName': null,
                },
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isSearching = false;
        });
        
        if (mounted) {
          await showCustomDialog(
            context: context,
            title: 'خطأ في البحث',
            message: 'حدث خطأ أثناء البحث: ${e.toString()}',
            okButtonText: 'موافق',
          );
        }
      }
    } else {
      setState(() {
        _isSearching = true;
      });

      try {
        final searchResult = await _apartmentRepository.searchApartments(
          regionId: _apartmentFormData['region_id']?.isNotEmpty == true
              ? int.tryParse(_apartmentFormData['region_id']!)
              : null,
          sectorId: _apartmentFormData['sector_id']?.isNotEmpty == true
              ? int.tryParse(_apartmentFormData['sector_id']!)
              : null,
          directionId: _apartmentFormData['direction_id']?.isNotEmpty == true
              ? int.tryParse(_apartmentFormData['direction_id']!)
              : null,
          apartmentTypeId:
              _apartmentFormData['apartment_type_id']?.isNotEmpty == true
                  ? int.tryParse(_apartmentFormData['apartment_type_id']!)
                  : null,
          paymentMethodId:
              _apartmentFormData['payment_method_id']?.isNotEmpty == true
                  ? int.tryParse(_apartmentFormData['payment_method_id']!)
                  : null,
          apartmentStatusId:
              _apartmentFormData['apartment_status_id']?.isNotEmpty == true
                  ? int.tryParse(_apartmentFormData['apartment_status_id']!)
                  : null,
          area: _apartmentFormData['area'],
          floor: _apartmentFormData['floor'],
          roomsCount: _apartmentFormData['rooms_count'],
          salonsCount: _apartmentFormData['salons_count'],
          balconyCount: _apartmentFormData['balcony_count'],
          isTaras: _apartmentFormData['is_taras'],
          equity: _apartmentFormData['equity'],
          price: _apartmentFormData['price'],
          transactionType: _apartmentTransactionType,
          priceOperator: _apartmentPriceOperator,
          equityOperator: _apartmentEquityOperator,
          ownerName: _apartmentFormData['owner_name'],
        );

        setState(() {
          _isSearching = false;
        });

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchResultsPage(
                searchType: 'apartment',
                searchData: searchResult.toJson(),
                searchQuery: 'بحث العقارات',
                originalSearchParams: {
                  'regionId': _apartmentFormData['region_id']?.isNotEmpty == true
                      ? int.tryParse(_apartmentFormData['region_id']!)
                      : null,
                  'sectorId': _apartmentFormData['sector_id']?.isNotEmpty == true
                      ? int.tryParse(_apartmentFormData['sector_id']!)
                      : null,
                  'directionId': _apartmentFormData['direction_id']?.isNotEmpty == true
                      ? int.tryParse(_apartmentFormData['direction_id']!)
                      : null,
                  'apartmentTypeId': _apartmentFormData['apartment_type_id']?.isNotEmpty == true
                      ? int.tryParse(_apartmentFormData['apartment_type_id']!)
                      : null,
                  'paymentMethodId': _apartmentFormData['payment_method_id']?.isNotEmpty == true
                      ? int.tryParse(_apartmentFormData['payment_method_id']!)
                      : null,
                  'apartmentStatusId': _apartmentFormData['apartment_status_id']?.isNotEmpty == true
                      ? int.tryParse(_apartmentFormData['apartment_status_id']!)
                      : null,
                  'area': _apartmentFormData['area'],
                  'floor': _apartmentFormData['floor'],
                  'roomsCount': _apartmentFormData['rooms_count'],
                  'salonsCount': _apartmentFormData['salons_count'],
                  'balconyCount': _apartmentFormData['balcony_count'],
                  'isTaras': _apartmentFormData['is_taras'],
                  'equity': _apartmentFormData['equity'],
                  'price': _apartmentFormData['price'],
                  'priceOperator': _apartmentPriceOperator,
                  'equityOperator': _apartmentEquityOperator,
                  'ownerName': _apartmentFormData['owner_name'],
                },
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isSearching = false;
        });

        if (mounted) {
          await showCustomDialog(
            context: context,
            title: 'خطأ في البحث',
            message: 'حدث خطأ أثناء البحث: ${e.toString()}',
            okButtonText: 'موافق',
          );
        }
      }
    }
  }

  Future<void> _loadApartmentSectorsForRegion(int regionId) async {
    setState(() {
      _apartmentIsLoadingSectors = true;
    });

    try {
      final response = await _shareRepository.fetchSectorsByRegion(regionId);
      _apartmentMainSectors = response.data;

      final sectorTypesSelection = <SectorTypeOption>[];
      if (_apartmentMainSectors?['data'] != null) {
        final data = _apartmentMainSectors!['data'] as List;
        for (int index = 0; index < data.length; index++) {
          final sectorItem = data[index] as Map<String, dynamic>;
          sectorTypesSelection.add(SectorTypeOption(
            id: index.toString(),
            name: sectorItem['key'] ?? '',
          ));
        }
      }

      if (mounted) {
        setState(() {
          _apartmentSectorTypes = sectorTypesSelection;
          _apartmentIsLoadingSectors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apartmentIsLoadingSectors = false;
        });
      }
    }
  }

  void _onApartmentSectorTypeChanged(SectorTypeOption? sectorType) {
    if (sectorType != null && _apartmentMainSectors != null) {
      setState(() {
        _apartmentSelectedSectorType = sectorType;
        _apartmentSectors.clear();
        _apartmentSelectedSector = null;
      });

      final sectorIndex = int.parse(sectorType.id);
      final data = _apartmentMainSectors!['data'] as List;
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

          if (mounted) {
            setState(() {
              _apartmentSectors = sectorOptions;
            });
          }
        }
      }
    }
  }

  void _onApartmentSectorChanged(SectorOption? sector) {
    if (sector != null) {
      setState(() {
        _apartmentSelectedSector = sector;
        // Set in apartment form data if you have it
      });
    }
  }

  // 2. Add fetch methods for dropdowns (call in initState)
  Future<void> _loadApartmentDropdowns() async {
    setState(() {
      _apartmentIsLoadingTypes = true;
      _apartmentIsLoadingDirections = true;
      _apartmentIsLoadingStatuses = true;
      _apartmentIsLoadingPayments = true;
    });

    try {
      // Try to load from cache first
      List<Map<String, dynamic>>? cachedDirections = await SecureStorage.getApartmentDropdownData('directions');
      List<Map<String, dynamic>>? cachedTypes = await SecureStorage.getApartmentDropdownData('types');
      List<Map<String, dynamic>>? cachedStatuses = await SecureStorage.getApartmentDropdownData('statuses');
      List<Map<String, dynamic>>? cachedPaymentMethods = await SecureStorage.getApartmentDropdownData('payment_methods');

      List<Direction> directions = [];
      List<ApartmentType> types = [];
      List<ApartmentStatus> statuses = [];
      List<PaymentMethod> paymentMethods = [];

      // Load directions
      if (cachedDirections != null && cachedDirections.isNotEmpty) {
        Logger.log('Loading directions from cache');
        directions = cachedDirections.map((json) => Direction.fromJson(json)).toList();
        setState(() {
          _directions = directions;
          _apartmentIsLoadingDirections = false;
        });
      } else {
        Logger.log('Loading directions from API');
        directions = await _apartmentRepository.fetchDirections();
        await SecureStorage.setApartmentDropdownData('directions', directions.map((d) => d.toJson()).toList());
        setState(() {
          _directions = directions;
          _apartmentIsLoadingDirections = false;
        });
      }

      // Load apartment types
      if (cachedTypes != null && cachedTypes.isNotEmpty) {
        Logger.log('Loading apartment types from cache');
        types = cachedTypes.map((json) => ApartmentType.fromJson(json)).toList();
        setState(() {
          _apartmentTypes = types;
          _apartmentIsLoadingTypes = false;
        });
      } else {
        Logger.log('Loading apartment types from API');
        types = await _apartmentRepository.fetchApartmentTypes();
        await SecureStorage.setApartmentDropdownData('types', types.map((t) => t.toJson()).toList());
        setState(() {
          _apartmentTypes = types;
          _apartmentIsLoadingTypes = false;
        });
      }

      // Load apartment statuses
      if (cachedStatuses != null && cachedStatuses.isNotEmpty) {
        Logger.log('Loading apartment statuses from cache');
        statuses = cachedStatuses.map((json) => ApartmentStatus.fromJson(json)).toList();
        setState(() {
          _apartmentStatuses = statuses;
          _apartmentIsLoadingStatuses = false;
        });
      } else {
        Logger.log('Loading apartment statuses from API');
        statuses = await _apartmentRepository.fetchApartmentStatuses();
        await SecureStorage.setApartmentDropdownData('statuses', statuses.map((s) => s.toJson()).toList());
        setState(() {
          _apartmentStatuses = statuses;
          _apartmentIsLoadingStatuses = false;
        });
      }

      // Load payment methods
      if (cachedPaymentMethods != null && cachedPaymentMethods.isNotEmpty) {
        Logger.log('Loading payment methods from cache');
        paymentMethods = cachedPaymentMethods.map((json) => PaymentMethod.fromJson(json)).toList();
        setState(() {
          _paymentMethods = paymentMethods;
          _apartmentIsLoadingPayments = false;
        });
      } else {
        Logger.log('Loading payment methods from API');
        paymentMethods = await _apartmentRepository.fetchPaymentMethods();
        await SecureStorage.setApartmentDropdownData('payment_methods', paymentMethods.map((p) => p.toJson()).toList());
        setState(() {
          _paymentMethods = paymentMethods;
          _apartmentIsLoadingPayments = false;
        });
      }

    } catch (e) {
      Logger.log('Error loading apartment dropdowns: $e');
      setState(() {
        _apartmentIsLoadingTypes = false;
        _apartmentIsLoadingDirections = false;
        _apartmentIsLoadingStatuses = false;
        _apartmentIsLoadingPayments = false;
      });
    }
  }

  // 3. Add handlers for dropdowns and fields
  void _onApartmentTypeChanged(ApartmentType? type) {
    if (type != null) {
      setState(() {
        _apartmentSelectedType = type;
        _apartmentFormData['apartment_type_id'] = type.id.toString();
        _apartmentFieldsToShow = type.fields;
      });
    }
  }
  void _onApartmentDirectionChanged(Direction? dir) {
    if (dir != null) {
      setState(() {
        _apartmentSelectedDirection = dir;
        _apartmentFormData['direction_id'] = dir.id.toString();
      });
    }
  }
  void _onApartmentStatusChanged(ApartmentStatus? status) {
    if (status != null) {
      setState(() {
        _apartmentSelectedStatus = status;
        _apartmentFormData['apartment_status_id'] = status.id.toString();
      });
    }
  }
  void _onApartmentPaymentChanged(PaymentMethod? pay) {
    if (pay != null) {
      setState(() {
        _apartmentSelectedPayment = pay;
        _apartmentFormData['payment_method_id'] = pay.id.toString();
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
        body: Stack(
          children: [
            Column(
              children: [
                // Page title (changes based on selected tab, updates on tab slide as well)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      final tabIndex = _tabController.index;
                      final title = tabIndex == 1
                          ? 'البحث عن عقار'
                          : 'البحث عن أسهم تنظيمية';
                      return Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Cairo',
                        ),
                      );
                    },
                  ),
                ),
                // Page title
                            // Tab bar
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: Offset(0, 5), // Only bottom
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF633e3d),
                    unselectedLabelColor: const Color(0xFF8C7A6A),
                    indicatorColor: const Color(0xFF633e3d),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Cairo',
                    ),
                    onTap: (index) {
                      if (index == 0) {
                        if (_selectedRegion?.hasShare == true || _selectedRegion == null) {
                          setState(() {
                            _currentSearchType = 'share';
                          });
                        }
                      } else {
                        if (_selectedRegion?.hasApartment == true || _selectedRegion == null) {
                          setState(() {
                            _currentSearchType = 'apartment';
                          });
                        }
                      }
                    },
                    tabs: const [
                      Tab(text: 'أسهم تنظيمية'),
                      Tab(text: 'عقارات'),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFd7c1c0),
                ),
              ],
            ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildShareSearchForm(),
                      _buildApartmentSearchForm(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareSearchForm() {
    final availableSearchTypes = _availableSearchTypes;
    // Disable all fields except Reference ID if Reference ID is filled
    bool disableOtherFields = _shareFormData['id'] != null && _shareFormData['id']!.isNotEmpty;
    // Disable all fields except region if share service is not available
    bool disableForServiceUnavailable = !availableSearchTypes.any((option) => option.id == 'share') && _selectedRegion != null;
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Service availability message
                if (availableSearchTypes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      'يرجى اختيار منطقة أولاً أو هذه المنطقة لا تحتوي على خدمات متاحة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  )
                else if (!availableSearchTypes.any((option) => option.id == 'share'))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA17462).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA17462).withOpacity(0.5)),
                    ),
                    child: Text(
                      'الأسهم التنظيمية غير متوفرة في منطقة ${_selectedRegion?.name ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFA17462),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Reference ID input (disabled if service unavailable)
                CustomTextField(
                  labelText: 'الرقم المرجعي',
                  hintText: 'أدخل الرقم المرجعي',
                  value: _shareFormData['id'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    setState(() {
                      _shareFormData['id'] = value;
                    });
                  },
                  enabled: !disableForServiceUnavailable,
                ),

                const SizedBox(height: 16),

                // Region dropdown (always enabled)
                CustomDropdown<region_model.Region>(
                  labelText: 'المنطقة',
                  value: _selectedRegion,
                  items: _regions,
                  itemLabel: (region) => region.name,
                  itemValue: (region) => region.id.toString(),
                  onChanged: _handleRegionChange,
                  hintText: 'اختر المنطقة',
                  emptyMessage: 'لا توجد مناطق متاحة',
                  isLoading: _isLoadingRegions,
                  isEnabled: true,
                  borderColor: disableForServiceUnavailable ? const Color(0xFFA47764) : null,
                ),

                const SizedBox(height: 16),

                // Sector type dropdown (disabled if Reference ID is filled or service unavailable)
                CustomDropdown<SectorTypeOption>(
                  labelText: 'نوع المقسم',
                  value: _selectedSectorType,
                  items: _sectorTypes,
                  itemLabel: (sectorType) => sectorType.name,
                  itemValue: (sectorType) => sectorType.id,
                  onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : _onSectorTypeChanged,
                  hintText: 'اختر نوع المقسم',
                  emptyMessage: 'يرجى اختيار المنطقة أولاً',
                  isLoading: _isLoadingSectors,
                  isEnabled: !(disableOtherFields || disableForServiceUnavailable) && _selectedRegion != null && !_isLoadingSectors,
                ),

                const SizedBox(height: 16),

                // Sector dropdown (disabled if Reference ID is filled or service unavailable)
                CustomDropdown<SectorOption>(
                  labelText: 'المقسم',
                  value: _selectedSector,
                  items: _sectors,
                  itemLabel: (sector) => sector.code,
                  itemValue: (sector) => sector.id.toString(),
                  onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : _onSectorChanged,
                  hintText: 'اختر المقسم',
                  emptyMessage: 'يرجى اختيار نوع المقسم أولاً',
                  isEnabled: !(disableOtherFields || disableForServiceUnavailable) && _selectedSectorType != null,
                ),

                const SizedBox(height: 16),

                // Transaction type select menu (disabled if Reference ID is filled or service unavailable)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الإعلانات التي ترغب في البحث عنها',
                      style: TextStyle(
                        fontSize: 16,
                       // fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomDropdown<String>(
                      value: _shareTransactionType,
                      items: const [
                        '1',
                        '2',
                      ],
                      itemLabel: (value) => value == '1' ? 'إعلانات بيع' : 'إعلانات شراء',
                      itemValue: (value) => value,
                      onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : (value) {
                        if (value != null) {
                          setState(() {
                            _shareTransactionType = value;
                          });
                        }
                      },
                      hintText: 'اختر نوع العملية',
                      isEnabled: !(disableOtherFields || disableForServiceUnavailable),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

                // Price with operator (disabled if Reference ID is filled or service unavailable)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'السعر',
                      style: TextStyle(
                        fontSize: 16,
                        //fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CustomDropdown<PriceOperatorOption>(
                            value: _selectedPriceOperator,
                            items: _priceOperators,
                            itemLabel: (operator) => operator.name,
                            itemValue: (operator) => operator.id,
                            onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : (operator) {
                              if (operator != null) {
                                setState(() {
                                  _selectedPriceOperator = operator;
                                  _priceOperator = operator.id;
                                });
                              }
                            },
                            hintText: '',
                            isEnabled: !(disableOtherFields || disableForServiceUnavailable),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            hintText: 'السعر',
                            value: _shareFormData['price'],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : (value) {
                              _shareFormData['price'] = value;
                            },
                            enabled: !(disableOtherFields || disableForServiceUnavailable),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

                // Quantity with operator (disabled if Reference ID is filled or service unavailable)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'عدد الأسهم',
                      style: TextStyle(
                        fontSize: 16,
                        //fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CustomDropdown<PriceOperatorOption>(
                            value: _selectedQuantityOperator,
                            items: _priceOperators,
                            itemLabel: (operator) => operator.name,
                            itemValue: (operator) => operator.id,
                            onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : (operator) {
                              if (operator != null) {
                                setState(() {
                                  _selectedQuantityOperator = operator;
                                  _quantityOperator = operator.id;
                                });
                              }
                            },
                            hintText: '',
                            isEnabled: !(disableOtherFields || disableForServiceUnavailable),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            hintText: 'عدد الأسهم',
                            value: _shareFormData['quantity'],
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : (value) {
                              _shareFormData['quantity'] = value;
                            },
                            enabled: !(disableOtherFields || disableForServiceUnavailable),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              ],
            ),
          ),
        ),

        // Search button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CustomButton(
                title: availableSearchTypes.isEmpty 
                    ? 'لا تتوفر خدمات في هذه المنطقة'
                    : !availableSearchTypes.any((option) => option.id == 'share')
                        ? 'الأسهم التنظيمية غير متوفرة'
                        : 'بحث',
                onPressed: availableSearchTypes.any((option) => option.id == 'share') ? _performSearch : null,
                hasGradient: true,
                gradientColors: const [
                  Color(0xFF633E3D),
                  Color(0xFF774B46),
                  Color(0xFF8D5E52),
                  Color(0xFFA47764),
                  Color(0xFFBDA28C),
                ],
                isLoading: _isSearching,
                height: 45,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApartmentSearchForm() {
    final availableSearchTypes = _availableSearchTypes;
    bool disableOtherFields = false;
    bool disableForServiceUnavailable = !availableSearchTypes.any((option) => option.id == 'apartment') && _selectedRegion != null;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (availableSearchTypes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      'يرجى اختيار منطقة أولاً أو هذه المنطقة لا تحتوي على خدمات متاحة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  )
                else if (!availableSearchTypes.any((option) => option.id == 'apartment'))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA17462).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA17462).withOpacity(0.5)),
                    ),
                    child: Text(
                      'العقارات غير متوفرة في منطقة ${_selectedRegion?.name ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFA17462),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                // Region dropdown
                CustomDropdown<region_model.Region>(
                  labelText: 'المنطقة',
                  value: _selectedRegion,
                  items: _regions,
                  itemLabel: (region) => region.name,
                  itemValue: (region) => region.id.toString(),
                  onChanged: (region) {
                    _handleRegionChange(region);
                    if (region != null) {
                      _loadApartmentDropdowns();
                      setState(() {
                        _apartmentSectorTypes.clear();
                        _apartmentSectors.clear();
                        _apartmentSelectedSectorType = null;
                        _apartmentSelectedSector = null;
                      });
                    }
                  },
                  hintText: 'اختر المنطقة',
                  emptyMessage: 'لا توجد مناطق متاحة',
                  isLoading: _isLoadingRegions,
                  isEnabled: true,
                  borderColor: disableForServiceUnavailable ? const Color(0xFFA47764) : null,
                ),
                const SizedBox(height: 16),
                // Sector type dropdown
                CustomDropdown<SectorTypeOption>(
                  labelText: 'نوع المقسم',
                  value: _apartmentSelectedSectorType,
                  items: _apartmentSectorTypes,
                  itemLabel: (sectorType) => sectorType.name,
                  itemValue: (sectorType) => sectorType.id,
                  onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : _onApartmentSectorTypeChanged,
                  hintText: 'اختر نوع المقسم',
                  emptyMessage: 'يرجى اختيار المنطقة أولاً',
                  isLoading: _apartmentIsLoadingSectors,
                  isEnabled: !(disableOtherFields || disableForServiceUnavailable) && _selectedRegion != null && !_apartmentIsLoadingSectors,
                ),
                const SizedBox(height: 16),
                // Sector dropdown
                CustomDropdown<SectorOption>(
                  labelText: 'المقسم',
                  value: _apartmentSelectedSector,
                  items: _apartmentSectors,
                  itemLabel: (sector) => sector.code,
                  itemValue: (sector) => sector.id.toString(),
                  onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : _onApartmentSectorChanged,
                  hintText: 'اختر المقسم',
                  emptyMessage: 'يرجى اختيار نوع المقسم أولاً',
                  isEnabled: !(disableOtherFields || disableForServiceUnavailable) && _apartmentSelectedSectorType != null,
                ),
                const SizedBox(height: 16),

                // Transaction type select menu (disabled if Reference ID is filled or service unavailable)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الإعلانات التي ترغب في البحث عنها',
                      style: TextStyle(
                        fontSize: 16,
                       // fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomDropdown<String>(
                      value: _apartmentTransactionType,
                      items: const [
                        '1',
                        '2',
                      ],
                      itemLabel: (value) => value == '1' ? 'إعلانات بيع' : 'إعلانات شراء',
                      itemValue: (value) => value,
                      onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : (value) {
                        if (value != null) {
                          setState(() {
                            _apartmentTransactionType = value;
                          });
                        }
                      },
                      hintText: 'اختر نوع العملية',
                      isEnabled: !(disableOtherFields || disableForServiceUnavailable),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                const SizedBox(height: 16),
                // Direction dropdown
                CustomDropdown<Direction>(
                  labelText: 'اتجاه العقار',
                  value: _apartmentSelectedDirection,
                  items: _directions,
                  itemLabel: (direction) => direction.name,
                  itemValue: (direction) => direction.id.toString(),
                  onChanged: _onApartmentDirectionChanged,
                  hintText: 'اختر اتجاه العقار',
                  emptyMessage: 'لا توجد اتجاهات متاحة',
                  isLoading: _apartmentIsLoadingDirections,
                ),
                const SizedBox(height: 16),
                // Apartment type dropdown
                CustomDropdown<ApartmentType>(
                  labelText: 'نوع العقار',
                  value: _apartmentSelectedType,
                  items: _apartmentTypes,
                  itemLabel: (apartmentType) => apartmentType.name,
                  itemValue: (apartmentType) => apartmentType.id.toString(),
                  onChanged: _onApartmentTypeChanged,
                  hintText: 'اختر نوع العقار',
                  emptyMessage: 'لا توجد أنواع عقارات متاحة',
                  isLoading: _apartmentIsLoadingTypes,
                ),
                const SizedBox(height: 16),
                // Apartment status dropdown
                CustomDropdown<ApartmentStatus>(
                  labelText: 'حالة العقار',
                  value: _apartmentSelectedStatus,
                  items: _apartmentStatuses,
                  itemLabel: (apartmentStatus) => apartmentStatus.name,
                  itemValue: (apartmentStatus) => apartmentStatus.id.toString(),
                  onChanged: _onApartmentStatusChanged,
                  hintText: 'اختر حالة العقار',
                  emptyMessage: 'لا توجد حالات عقارات متاحة',
                  isLoading: _apartmentIsLoadingStatuses,
                ),
                const SizedBox(height: 16),
                // Area input
                CustomTextField(
                  labelText: 'المساحة',
                  hintText: 'أدخل المساحة',
                  value: _apartmentFormData['area'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    _apartmentFormData['area'] = value;
                  },
                ),
                const SizedBox(height: 16),
                // Conditional fields
                if (_apartmentFieldsToShow.contains('floor')) ...[
                  CustomTextField(
                    labelText: 'الطابق',
                    hintText: 'أدخل الطابق',
                    value: _apartmentFormData['floor'],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      _apartmentFormData['floor'] = value;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (_apartmentFieldsToShow.contains('rooms_count')) ...[
                  CustomTextField(
                    labelText: 'عدد الغرف',
                    hintText: 'أدخل عدد الغرف',
                    value: _apartmentFormData['rooms_count'],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      _apartmentFormData['rooms_count'] = value;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (_apartmentFieldsToShow.contains('salons_count')) ...[
                  CustomTextField(
                    labelText: 'عدد الصالونات',
                    hintText: 'أدخل عدد الصالونات',
                    value: _apartmentFormData['salons_count'],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      _apartmentFormData['salons_count'] = value;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (_apartmentFieldsToShow.contains('balcony_count')) ...[
                  CustomTextField(
                    labelText: 'عدد البلكونات',
                    hintText: 'أدخل عدد البلكونات',
                    value: _apartmentFormData['balcony_count'],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      _apartmentFormData['balcony_count'] = value;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Owner name input
                CustomTextField(
                  labelText: 'صاحب العلاقة',
                  hintText: 'أدخل اسم صاحب العلاقة',
                  value: _apartmentFormData['owner_name'],
                  onChanged: (value) {
                    _apartmentFormData['owner_name'] = value;
                  },
                ),
                const SizedBox(height: 16),
                // Equity input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'عدد الأسهم',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CustomDropdown<PriceOperatorOption>(
                            value: _selectedApartmentEquityOperator,
                            items: _priceOperators,
                            itemLabel: (operator) => operator.name,
                            itemValue: (operator) => operator.id,
                            onChanged: (operator) {
                              if (operator != null) {
                                setState(() {
                                  _selectedApartmentEquityOperator = operator;
                                  _apartmentEquityOperator = operator.id;
                                });
                              }
                            },
                            hintText: '',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            hintText: 'عدد الأسهم',
                            value: _apartmentFormData['equity'],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (value) {
                              _apartmentFormData['equity'] = value;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Price input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'السعر',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CustomDropdown<PriceOperatorOption>(
                            value: _selectedApartmentPriceOperator,
                            items: _priceOperators,
                            itemLabel: (operator) => operator.name,
                            itemValue: (operator) => operator.id,
                            onChanged: (operator) {
                              if (operator != null) {
                                setState(() {
                                  _selectedApartmentPriceOperator = operator;
                                  _apartmentPriceOperator = operator.id;
                                });
                              }
                            },
                            hintText: '',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            hintText: 'السعر',
                            value: _apartmentFormData['price'],
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'))
                            ],
                            onChanged: (value) {
                              _apartmentFormData['price'] = value;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Payment method dropdown
                CustomDropdown<PaymentMethod>(
                  labelText: 'طريقة الدفع',
                  value: _apartmentSelectedPayment,
                  items: _paymentMethods,
                  itemLabel: (paymentMethod) => paymentMethod.name,
                  itemValue: (paymentMethod) => paymentMethod.id.toString(),
                  onChanged: _onApartmentPaymentChanged,
                  hintText: 'اختر طريقة الدفع',
                  emptyMessage: 'لا توجد طرق دفع متاحة',
                  isLoading: _apartmentIsLoadingPayments,
                ),
                const SizedBox(height: 16),
                // Taras radio buttons
                if (_apartmentFieldsToShow.contains('is_taras')) ...[
                  CustomRadioButtons(
                    radioButtons: [
                      RadioOption(id: '1', label: 'يحتوي على تراس', value: '1'),
                      RadioOption(id: '0', label: 'لا يحتوي على تراس', value: '0'),
              ],
                    selectedId: _apartmentFormData['is_taras'] ?? '0',
                    onChanged: (value) {
                      setState(() {
                        _apartmentFormData['is_taras'] = value;
                      });
                    },
          ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        // Search button (keep as is, or update to use new form data)
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CustomButton(
                title: availableSearchTypes.isEmpty 
                    ? 'لا تتوفر خدمات في هذه المنطقة'
                    : !availableSearchTypes.any((option) => option.id == 'apartment')
                        ? 'العقارات غير متوفرة'
                        : 'بحث',
                onPressed: availableSearchTypes.any((option) => option.id == 'apartment') ? _performSearch : null,
                hasGradient: true,
                gradientColors: const [
                  Color(0xFF633E3D),
                  Color(0xFF774B46),
                  Color(0xFF8D5E52),
                  Color(0xFFA47764),
                  Color(0xFFBDA28C),
                ],
                isLoading: _isSearching,
                height: 45,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 