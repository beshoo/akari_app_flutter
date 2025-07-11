# Share Card Component

A comprehensive Flutter card component for displaying share information with interactive features like reactions, favorites, and sharing functionality.

## Features

### 🎨 Visual Design
- **Exact Layout Structure**: 350px height with 8px rounded corners
- **Background Image**: Sector cover image with fallback to placeholder
- **Gradient Badges**: Transaction type, ID, and approval status badges
- **Semi-transparent Overlays**: Content overlay with 90% opacity
- **Closed Deal Overlay**: Full-screen overlay for closed transactions

### 🔄 Interactive Elements
- **Reaction System**: 5 reaction types (Like, Love, Wow, Sad, Angry)
- **Floating Reaction Panel**: Animated reaction selector
- **Favorites**: Toggle favorite status with star icon
- **Share Functionality**: Native share integration
- **Bottom Modal**: Detailed reaction breakdown

### 📱 Responsive Features
- **RTL Support**: Full Arabic RTL layout support
- **Animations**: Smooth reaction animations and transitions
- **Touch Feedback**: Proper touch feedback for all interactive elements
- **State Management**: Optimistic UI updates with error handling

## Installation

### 1. Add Dependencies

```yaml
dependencies:
  # Core dependencies
  flutter:
    sdk: flutter
  provider: ^6.0.5
  
  # UI Components
  cached_network_image: ^3.3.0
  modal_bottom_sheet: ^3.0.0
  font_awesome_flutter: ^10.6.0
  
  # Share functionality
  share_plus: ^7.2.2
  
  # HTTP client
  dio: ^5.8.0+1
```

### 2. Add Required Assets

Ensure these icons are available in your `assets/images/icons/` directory:
- `gold.png` - Verification icon
- `price.png` - Price indicator
- `quantity.png` - Quantity indicator
- `date.png` - Date indicator
- `user.png` - User/owner indicator
- `view.png` - Views counter
- `no_photo.jpg` - Default placeholder image

### 3. Set Up Providers

```dart
// In your main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthStore()),
    ChangeNotifierProvider(create: (_) => ReactionStore()),
    // ... other providers
  ],
  child: YourApp(),
)
```

## Usage

### Basic Usage

```dart
import 'package:your_app/widgets/share_card.dart';
import 'package:your_app/data/models/share_model.dart';

class ShareListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ShareCard(
              share: yourShareObject,
              onShareUpdated: (updatedShare) {
                // Handle share updates (reactions, favorites)
                print('Share updated: ${updatedShare.id}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:your_app/widgets/share_card.dart';
import 'package:your_app/data/models/share_model.dart';

class ShareFeedPage extends StatefulWidget {
  @override
  _ShareFeedPageState createState() => _ShareFeedPageState();
}

class _ShareFeedPageState extends State<ShareFeedPage> {
  List<Share> shares = [];

  @override
  void initState() {
    super.initState();
    loadShares();
  }

  void loadShares() {
    // Load shares from API
    // shares = await shareRepository.getShares();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الأسهم'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: shares.length,
        itemBuilder: (context, index) {
          return ShareCard(
            share: shares[index],
            onShareUpdated: (updatedShare) {
              setState(() {
                shares[index] = updatedShare;
              });
            },
          );
        },
      ),
    );
  }
}
```

## Data Model

### Share Object Structure

```dart
class Share {
  final int id;
  final String transactionType; // 'sell' or 'buy'
  final String price;
  final String quantity;
  final String ownerName;
  final int views;
  final int approve; // 0 = pending, 1 = approved
  final int closed; // 0 = open, 1 = closed
  final ReactionCounts reactionCounts;
  final String? currentUserReaction;
  final bool isFavorited;
  final User user;
  final Region region;
  final Sector sector;
  // ... other fields
}
```

### Reaction Counts

```dart
class ReactionCounts {
  final int likeCount;
  final int loveCount;
  final int wowCount;
  final int sadCount;
  final int angryCount;
  final int totalCount;
}
```

## API Integration

### Reaction Store

The component uses `ReactionStore` for API interactions:

```dart
class ReactionStore extends ChangeNotifier {
  // Add reaction
  Future<Map<String, dynamic>> addReaction({
    required String type,
    required String postType,
    required int postId,
  });

  // Remove reaction
  Future<Map<String, dynamic>> removeReaction({
    required String postType,
    required int postId,
  });

  // Toggle favorite
  Future<Map<String, dynamic>> toggleFavorite({
    required String postType,
    required int postId,
  });
}
```

### API Endpoints

```bash
# Add/Update Reaction
POST /api/react
{
  "type": "like",
  "post_type": "share",
  "post_id": 66
}

# Remove Reaction
DELETE /api/react?post_type=share&post_id=66

# Toggle Favorite
POST /api/favorites/toggle
{
  "post_type": "share",
  "post_id": 66
}
```

## Component Architecture

### Layer Structure (Z-Index)

1. **Background Image** (Z: 0) - Sector cover image
2. **Status Badges** (Z: 10) - Transaction type, ID, approval
3. **Content Overlay** (Z: 10) - Bottom information panel
4. **Reaction Panel** (Z: 10) - Floating reaction selector
5. **Closed Overlay** (Z: 20) - Full-screen closed deal overlay

### State Management

- **Local State**: UI interactions (reaction panel visibility, animations)
- **Provider State**: API calls (reactions, favorites)
- **Optimistic Updates**: Immediate UI updates with error rollback

## Customization

### Colors

```dart
// Badge gradients
static const List<Color> badgeGradient = [
  Color(0xFF633E3D),
  Color(0xFF774B46),
  Color(0xFF8D5E52),
  Color(0xFFA47764),
  Color(0xFFBDA28C),
];

// Approval badge
static const List<Color> approvalGradient = [
  Color(0xFFE3A001),
  Color(0xFFB87005),
  Color(0xFF95560B),
  Color(0xFF7A460D),
  Color(0xFF7A460D),
];
```

### Dimensions

```dart
// Card dimensions
static const double cardHeight = 350;
static const double cardBorderRadius = 8;
static const double contentOverlayHeight = 140; // 40% of card height
```

## User Permissions

### Admin/Owner Features

- **Approval Badge**: Shows "قيد المراجعة" for pending approvals
- **Owner Information**: Displays owner name in content overlay
- **Extended Actions**: Additional management options

### User Features

- **Reactions**: All 5 reaction types
- **Favorites**: Toggle favorite status
- **Share**: Native share functionality
- **View Counter**: Read-only view count

## Error Handling

### Network Errors

- **Optimistic Updates**: Immediate UI changes
- **Error Rollback**: Revert changes on API failure
- **Toast Messages**: User-friendly error messages

### Image Loading

- **Placeholder**: Shows loading indicator
- **Fallback**: Uses default `no_photo.jpg`
- **Error Recovery**: Graceful degradation

## Accessibility

### RTL Support

- **Text Direction**: Automatic RTL/LTR detection
- **Layout Mirroring**: Proper badge positioning
- **Icon Alignment**: Consistent icon placement

### Screen Readers

- **Semantic Labels**: Proper accessibility labels
- **Action Descriptions**: Clear action descriptions
- **State Announcements**: Reaction state changes

## Performance

### Image Optimization

- **Cached Images**: Uses `cached_network_image`
- **Lazy Loading**: Efficient image loading
- **Memory Management**: Proper image disposal

### Animation Performance

- **60fps Animations**: Smooth reaction animations
- **Efficient Rebuilds**: Minimal widget rebuilds
- **Animation Disposal**: Proper controller cleanup

## Testing

### Unit Tests

```dart
// Test reaction logic
test('should update reaction count when reaction is added', () {
  // Test implementation
});

// Test favorite toggle
test('should toggle favorite status', () {
  // Test implementation
});
```

### Widget Tests

```dart
// Test component rendering
testWidgets('ShareCard displays correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ShareCard(share: mockShare),
    ),
  );
  
  expect(find.text('بيع'), findsOneWidget);
  expect(find.text('#66'), findsOneWidget);
});
```

## Troubleshooting

### Common Issues

1. **Missing Icons**: Ensure all required icons are in `assets/images/icons/`
2. **Provider Not Found**: Add `ReactionStore` to your provider list
3. **Network Errors**: Check API endpoints and authentication
4. **Animation Issues**: Verify `TickerProviderStateMixin` is properly implemented

### Debug Mode

Enable debug logs for API calls:

```dart
// In ApiService
if (kDebugMode) {
  print('🚀 REQUEST: ${options.method} ${options.uri}');
  print('✅ RESPONSE: ${response.statusCode}');
}
```

## Contributing

When contributing to the ShareCard component:

1. **Follow Architecture**: Maintain the existing layered structure
2. **RTL Compliance**: Ensure all changes support RTL layout
3. **Performance**: Consider performance implications of changes
4. **Testing**: Add tests for new features
5. **Documentation**: Update this README for new features

## License

This component is part of the Akari App project. 