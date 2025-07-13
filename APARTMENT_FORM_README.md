# Apartment Form Page

A comprehensive Flutter form page for creating and updating apartment listings with the same design patterns as the share form.

## Features

- **Create/Update Modes**: Support for both creating new apartments and updating existing ones
- **Dynamic Form Fields**: Fields shown/hidden based on selected apartment type
- **Real-time Validation**: Form validation with Arabic error messages
- **Dependent Dropdowns**: Cascading dropdowns for regions → sector types → sectors
- **Confirmation Dialog**: Shows summary before submission
- **Loading States**: Proper loading indicators for all async operations
- **Error Handling**: Comprehensive error handling with user-friendly messages

## Usage

### Creating a New Apartment

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ApartmentFormPage(
      mode: ApartmentFormMode.create,
    ),
  ),
);
```

### Updating an Existing Apartment

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ApartmentFormPage(
      mode: ApartmentFormMode.update,
      existingApartment: myApartment, // Pass the existing apartment data
    ),
  ),
);
```

## Form Fields

### Required Fields
- **Owner Name** (`owner_name`): Name of the property owner
- **Region** (`region_id`): Selected region from available regions
- **Sector** (`sector_id`): Selected sector within the region
- **Apartment Type** (`apartment_type_id`): Type of apartment (residential, commercial, etc.)
- **Direction** (`direction_id`): Property direction/orientation
- **Apartment Status** (`apartment_status_id`): Construction status
- **Area** (`area`): Property area in square meters
- **Equity** (`equity`): Number of available shares
- **Price** (`price`): Property price in Syrian Pounds

### Optional Fields
- **Payment Method** (`payment_method_id`): Payment method preference
- **Floor** (`floor`): Floor number (if applicable for apartment type)
- **Rooms Count** (`rooms_count`): Number of rooms (if applicable)
- **Salons Count** (`salons_count`): Number of salons (if applicable)
- **Balcony Count** (`balcony_count`): Number of balconies (if applicable)
- **Has Terrace** (`is_taras`): Whether property has a terrace (if applicable)

## Dynamic Fields

Fields are dynamically shown/hidden based on the selected apartment type:

```dart
// Example apartment types and their fields
{
  "id": 1,
  "name": "شقة سكنية",
  "fields": ["floor", "rooms_count", "salons_count", "balcony_count", "is_taras"]
},
{
  "id": 2, 
  "name": "محل تجاري",
  "fields": ["floor", "rooms_count", "salons_count", "balcony_count"]
},
{
  "id": 3,
  "name": "مكتب", 
  "fields": ["rooms_count"]
},
{
  "id": 4,
  "name": "مقسم كامل",
  "fields": []
}
```

## API Integration

The form integrates with the following API endpoints:

### Create Apartment
- **Buy**: `POST /apartment/buy`
- **Sell**: `POST /apartment/sell`

### Update Apartment
- **Update**: `POST /apartment/update/{apartment_id}`

### Load Options
- **Regions**: `GET /regions` (filtered by `has_apartment = 1`)
- **Sectors**: `GET /sectors_by_region/{region_id}`
- **Apartment Types**: `GET /apartment/types`
- **Directions**: `GET /direction`
- **Apartment Status**: `GET /apartment_status`
- **Payment Methods**: `GET /payment-methods`

## Form Validation

The form includes comprehensive validation:

```dart
// Required field validation
if (_formData['owner_name']?.isEmpty ?? true) {
  _errors['owner_name'] = 'يرجى إدخال اسم صاحب العلاقة';
}

// Numeric validation
final area = int.tryParse(_formData['area']!);
if (area == null || area <= 0) {
  _errors['area'] = 'يرجى إدخال مساحة صحيحة';
}

// Conditional field validation
if (_fieldsToShow.contains('floor') && (_formData['floor']?.isEmpty ?? true)) {
  _errors['floor'] = 'يرجى إدخال الطابق';
}
```

## Dependencies

The apartment form page depends on:

- **Models**: `ApartmentModel`, `RegionModel`
- **Repositories**: `ApartmentRepository`, `HomeRepository`, `ShareRepository`
- **Widgets**: `CustomDropdown`, `CustomTextField`, `CustomRadioButtons`, `CustomButton`, `CustomDialog`

## File Structure

```
lib/
├── pages/
│   └── apartment_form_page.dart         # Main form page
├── data/
│   ├── models/
│   │   └── apartment_model.dart         # Apartment data models
│   └── repositories/
│       └── apartment_repository.dart    # API integration
└── widgets/
    ├── custom_dropdown.dart             # Custom dropdown widget
    ├── custom_text_field.dart           # Custom text field widget
    ├── custom_radio_buttons.dart        # Custom radio buttons widget
    ├── custom_button.dart               # Custom button widget
    └── custom_dialog.dart               # Custom dialog widget
```

## Styling

The form follows the app's design system:

- **Colors**: Uses gradient colors `[#633E3D, #774B46, #8D5E52, #A47764, #BDA28C]`
- **Typography**: Uses 'Cairo' font family
- **Direction**: RTL (Right-to-Left) for Arabic text
- **Background**: Light cream color `#F7F5F2`

## Example Usage in Demo

Check `lib/pages/apartment_demo_page.dart` for a complete implementation example.

## Error Handling

The form handles various error scenarios:

- **Network errors**: Shows user-friendly error messages
- **Validation errors**: Highlights invalid fields with error messages
- **API errors**: Displays server error messages
- **Loading states**: Shows loading indicators during API calls

## Success Handling

On successful submission:
1. Shows success dialog
2. Closes the form page
3. Optionally navigates to the created/updated apartment details page

## Notes

- The form uses the same sector loading pattern as the share form
- All text is in Arabic for proper localization
- Form data is validated before submission
- Conditional fields are managed based on apartment type selection
- The form supports both create and update modes seamlessly 