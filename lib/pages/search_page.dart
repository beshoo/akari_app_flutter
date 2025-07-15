import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/region_model.dart' as region_model;
import '../data/repositories/home_repository.dart';
import '../data/repositories/share_repository.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_radio_buttons.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dialog.dart';

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
  String _transactionType = 'sell'; // 'buy' or 'sell'

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

    _loadInitialData();
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

      // TODO: Reset apartment form data once implemented
    });

    if (_currentSearchType == 'share' && isShareAvailable) {
      _loadSectorsForRegion(region.id);
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
        // Convert transaction type
        final transactionTypeValue = _transactionType == 'sell' ? 1 : 2;
        
        final searchResult = await _shareRepository.searchShares(
          id: _shareFormData['id']?.isNotEmpty == true ? _shareFormData['id'] : null,
          regionId: _shareFormData['region_id']?.isNotEmpty == true ? int.tryParse(_shareFormData['region_id']!) : null,
          sectorId: _shareFormData['sector_id']?.isNotEmpty == true ? int.tryParse(_shareFormData['sector_id']!) : null,
          quantity: _shareFormData['quantity']?.isNotEmpty == true ? _shareFormData['quantity'] : null,
          quantityOperator: _quantityOperator,
          transactionType: transactionTypeValue,
          price: _shareFormData['price']?.isNotEmpty == true ? _shareFormData['price'] : null,
          priceOperator: _priceOperator,
        );

        setState(() {
          _isSearching = false;
        });

        // TODO: Navigate to search results page with the results
        // For now, show a dialog with the count
        if (mounted) {
          await showCustomDialog(
            context: context,
            title: 'نتائج البحث',
            message: 'تم العثور على ${searchResult.total} نتيجة',
            okButtonText: 'موافق',
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
      // TODO: Implement apartment search
      await showCustomDialog(
        context: context,
        title: 'قريباً',
        message: 'سيتم إضافة البحث في العقارات قريباً',
        okButtonText: 'موافق',
      );
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

  Future<void> _performApartmentSearch() async {
    // TODO: Implement apartment search
    await showCustomDialog(
      context: context,
      title: 'قريباً',
      message: 'سيتم إضافة البحث في العقارات قريباً',
      okButtonText: 'موافق',
    );
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
                TabBar(
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
                      'نوع العملية',
                      style: TextStyle(
                        fontSize: 16,
                       // fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomDropdown<String>(
                      value: _transactionType,
                      items: const [
                        '1',
                        '2',
                      ],
                      itemLabel: (value) => value == '1' ? 'عروض بيع' : 'طلبات شراء',
                      itemValue: (value) => value,
                      onChanged: (disableOtherFields || disableForServiceUnavailable) ? null : (value) {
                        if (value != null) {
                          setState(() {
                            _transactionType = value;
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
    // Disable all fields except Reference ID if Reference ID is filled
    bool disableOtherFields = _shareFormData['id'] != null && _shareFormData['id']!.isNotEmpty;
    // Disable all fields except region if apartment service is not available
    bool disableForServiceUnavailable = !availableSearchTypes.any((option) => option.id == 'apartment') && _selectedRegion != null;
    
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
                  onChanged: (region) {
                    _handleRegionChange(region);
                    if (region != null) {
                      _loadApartmentSectorsForRegion(region.id);
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

                // Sector type dropdown (disabled if Reference ID is filled or service unavailable)
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

                // Sector dropdown (disabled if Reference ID is filled or service unavailable)
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

                // Apartment search specific fields will be added here later
                const Text(
                  'سيتم إضافة حقول البحث الخاصة بالعقارات قريباً',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
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
                    : !availableSearchTypes.any((option) => option.id == 'apartment')
                        ? 'العقارات غير متوفرة'
                        : 'بحث',
                onPressed: availableSearchTypes.any((option) => option.id == 'apartment') ? _performApartmentSearch : null,
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