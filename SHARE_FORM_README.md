# Share Form Page

A comprehensive Flutter form page for creating and updating share posts in the Akari app. This form supports both buy and sell transactions with dependent dropdown menus and full validation.

## Features

### 🎯 Core Functionality
- **Create Mode**: Create new share posts for buy/sell transactions
- **Update Mode**: Edit existing share posts
- **Transaction Types**: Support for both buy and sell transactions
- **Form Validation**: Comprehensive validation with error messages
- **Dependent Dropdowns**: Region → Sector Type → Sector cascade selection
- **Confirmation Dialog**: Preview before submission

### 🎨 UI Components
- **Radio Buttons**: Custom buy/sell selection
- **Dropdown Menus**: Custom dropdowns with loading states
- **Text Fields**: Owner name, quantity, and price inputs
- **Loading States**: Proper loading indicators during API calls
- **Error Handling**: Clear error messages and validation feedback

### 📱 Responsive Design
- **RTL Support**: Full Arabic RTL layout support
- **Custom Widgets**: Reusable custom components
- **Consistent Styling**: App-wide design consistency
- **Form Layout**: Optimized form layout with proper spacing

## Installation

### 1. Dependencies

The form uses the following dependencies (already included in the project):
- `flutter/material.dart` - Core Flutter UI
- `flutter/services.dart` - Input formatters
- Custom widgets and repositories

### 2. Import Required Files

```dart
import 'package:akari_app/pages/share_form_page.dart';
import 'package:akari_app/utils/navigation_helper.dart';
```

## Usage

### Basic Usage - Create New Share

```dart
import 'package:flutter/material.dart';
import 'package:akari_app/pages/share_form_page.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ShareFormPage(
                  mode: ShareFormMode.create,
                ),
              ),
            );
          },
          child: Text('Create Share'),
        ),
      ),
    );
  }
}
```

### Update Existing Share

```dart
import 'package:flutter/material.dart';
import 'package:akari_app/pages/share_form_page.dart';
import 'package:akari_app/data/models/share_model.dart';

class EditShareButton extends StatelessWidget {
  final Share share;
  
  const EditShareButton({Key? key, required this.share}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShareFormPage(
              mode: ShareFormMode.update,
              existingShare: share,
            ),
          ),
        );
      },
      child: Text('Edit Share'),
    );
  }
}
```

### Using Navigation Helper

```dart
import 'package:akari_app/utils/navigation_helper.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => NavigationHelper.navigateToCreateShare(context),
          child: Text('Create Share'),
        ),
        ElevatedButton(
          onPressed: () => NavigationHelper.navigateToUpdateShare(context, myShare),
          child: Text('Update Share'),
        ),
      ],
    );
  }
}
```

## Integration with Existing Components

### CustomFAB Integration

```dart
import 'package:akari_app/widgets/custom_fab.dart';
import 'package:akari_app/utils/navigation_helper.dart';

CustomFAB(
  onAddApartment: () {
    // Navigate to apartment form
  },
  onAddShare: () {
    NavigationHelper.navigateToCreateShare(context);
  },
)
```

### CustomAppBar Integration

```dart
import 'package:akari_app/widgets/custom_app_bar.dart';

CustomAppBar(
  title: 'My Page',
  showAddAdButton: true,
  onAddAdPressed: () {
    NavigationHelper.navigateToCreateShare(context);
  },
)
```

## Form Fields

### Radio Buttons (Transaction Type)
- **Buy**: "أريد أن أشتري" (I want to buy)
- **Sell**: "أريد أن أبيع" (I want to sell)

### Dropdown Fields (Dependent)
1. **Region**: "المنطقة" - Filtered to only show regions with shares
2. **Sector Type**: "نوع المقسم" - Populated based on selected region
3. **Sector**: "المقسم" - Populated based on selected sector type

### Text Input Fields
- **Owner Name**: "صاحب العلاقة" - Required text field
- **Quantity**: "عدد الأسهم" - Required number field (changes label based on buy/sell)
- **Price**: "سعر السهم الواحد" - Required decimal field

## API Integration

### Endpoints Used

```bash
# Get regions
GET /api/region/list

# Get sectors by region
GET /api/sector/list/{region_id}

# Create buy share
POST /api/share/buy
{
  "region_id": 1,
  "sector_id": 1,
  "quantity": 10,
  "owner_name": "John Doe",
  "price": 50000
}

# Create sell share
POST /api/share/sell (multipart/form-data)
region_id=1
sector_id=1
quantity=10
owner_name=John Doe
price=50000

# Update share
POST /api/share/update/{share_id}
{
  "region_id": 1,
  "sector_id": 1,
  "quantity": 10,
  "owner_name": "John Doe",
  "price": 50000
}
```

### Response Handling

The form handles various response formats:
- Success responses with `success: true`
- Responses with `id` field for navigation
- Error responses with proper error messages

## Form Validation

### Required Fields
- Owner name (non-empty)
- Region selection
- Sector selection
- Quantity (positive integer)
- Price (positive decimal)

### Validation Messages
- Arabic validation messages for all fields
- Real-time validation feedback
- Error highlighting for invalid fields

## Confirmation Dialog

Before submission, the form shows a confirmation dialog with:
- **Transaction details** in Arabic
- **Formatted price** with comma separators
- **Confirm/Cancel** buttons
- **Transaction summary** including all selected values

## State Management

### Form State
- Form data stored in `Map<String, String>`
- Loading states for API calls
- Error states for validation and API errors
- Selected values for dependent dropdowns

### Loading States
- Region loading
- Sector loading
- Form submission loading
- Proper loading indicators and disabled states

## Error Handling

### Form Validation Errors
- Field-specific error messages
- Form-wide error display
- Validation on submit and real-time feedback

### API Errors
- Network error handling
- Server error messages
- Graceful fallback with user-friendly messages

## Customization

### Styling
- Uses app-wide color scheme
- Cairo font family for Arabic text
- Consistent button and input styling
- Proper spacing and layout

### Localization
- All text in Arabic
- RTL text direction support
- Proper Arabic number formatting
- Currency formatting for prices

## Testing

### Manual Testing Checklist
- [ ] Create new buy share
- [ ] Create new sell share
- [ ] Update existing share
- [ ] Form validation works
- [ ] Dependent dropdowns work
- [ ] API calls succeed
- [ ] Error handling works
- [ ] Confirmation dialog appears
- [ ] Navigation works properly

### Common Test Scenarios
1. **Happy Path**: Fill all fields correctly and submit
2. **Validation**: Try to submit empty form
3. **Network Error**: Test with poor connection
4. **Large Data**: Test with many regions/sectors
5. **Update Mode**: Test editing existing shares

## Troubleshooting

### Common Issues

**Form not submitting**
- Check all required fields are filled
- Verify API endpoints are accessible
- Check network connectivity

**Dropdowns not loading**
- Verify API responses are correct
- Check for authentication issues
- Ensure proper error handling

**Validation errors**
- Check field format requirements
- Verify number parsing (quantity/price)
- Ensure proper Arabic text input

### Debug Information
- API calls are logged in debug mode
- Form state is tracked
- Error messages are descriptive

## Future Enhancements

### Potential Improvements
- [ ] Draft save functionality
- [ ] Bulk share creation
- [ ] Share templates
- [ ] Advanced validation rules
- [ ] Offline mode support
- [ ] Image upload for shares
- [ ] Share scheduling
- [ ] Integration with calendar

### API Enhancements
- [ ] Search functionality
- [ ] Filtering options
- [ ] Sorting capabilities
- [ ] Export functionality
- [ ] Bulk operations 