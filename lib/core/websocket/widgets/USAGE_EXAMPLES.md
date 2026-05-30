# Online Indicator Widget Usage Examples

This document provides examples of how to use the online presence indicator widgets.

## Basic Usage

### Simple Online Indicator

Display a green dot for online users, nothing for offline users:

```dart
import 'package:gharsewa/core/websocket/widgets/online_indicator.dart';

// In your widget
OnlineIndicator(
  userId: provider.id,
)
```

### Online Indicator with Offline State

Display a green dot for online users, gray dot for offline users:

```dart
OnlineIndicator(
  userId: provider.id,
  showOfflineIndicator: true,
)
```

### Online Indicator with Last Seen

Display last seen timestamp for offline users (useful on profile pages):

```dart
OnlineIndicator(
  userId: provider.id,
  showOfflineIndicator: true,
  showLastSeen: true,
  lastSeenAt: provider.lastSeenAt,
)
```

### Custom Size

Adjust the size of the indicator dot:

```dart
OnlineIndicator(
  userId: provider.id,
  size: 12.0, // Default is 10.0
)
```

## Advanced Variants

### Online Indicator with Label

Display online status with text label:

```dart
OnlineIndicatorWithLabel(
  userId: provider.id,
  dotSize: 8.0,
  spacing: 6.0,
)
```

### Online Indicator Badge

Small badge for overlaying on avatars:

```dart
Stack(
  children: [
    CircleAvatar(
      backgroundImage: NetworkImage(provider.avatar),
      radius: 30,
    ),
    Positioned(
      bottom: 0,
      right: 0,
      child: OnlineIndicatorBadge(
        userId: provider.id,
        size: 12.0,
        showBorder: true,
        borderWidth: 2.0,
      ),
    ),
  ],
)
```

### Provider-Specific Indicator

Optimized for provider lists (uses provider-specific presence check):

```dart
ProviderOnlineIndicator(
  providerId: provider.id,
  showOfflineIndicator: true,
  size: 10.0,
)
```

## Real-World Examples

### Provider List Item

```dart
class ProviderListItem extends StatelessWidget {
  final Provider provider;

  const ProviderListItem({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(provider.avatar),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: OnlineIndicatorBadge(
              userId: provider.id,
            ),
          ),
        ],
      ),
      title: Text(provider.name),
      subtitle: OnlineIndicatorWithLabel(
        userId: provider.id,
      ),
    );
  }
}
```

### Provider Profile Page

```dart
class ProviderProfilePage extends StatelessWidget {
  final Provider provider;

  const ProviderProfilePage({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(provider.name)),
      body: Column(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(provider.avatar),
            radius: 50,
          ),
          const SizedBox(height: 16),
          OnlineIndicator(
            userId: provider.id,
            showOfflineIndicator: true,
            showLastSeen: true,
            lastSeenAt: provider.lastSeenAt,
            size: 12.0,
          ),
          // ... rest of profile
        ],
      ),
    );
  }
}
```

### Provider Search Results

```dart
class ProviderSearchResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(providerSearchProvider);
    
    return ListView.builder(
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(provider.avatar),
            ),
            title: Row(
              children: [
                Text(provider.name),
                const SizedBox(width: 8),
                ProviderOnlineIndicator(
                  providerId: provider.id,
                ),
              ],
            ),
            subtitle: Text(provider.service),
          ),
        );
      },
    );
  }
}
```

## Requirements Satisfied

- **Requirement 12.1**: Show online indicator for users in presence channel ✓
- **Requirement 12.2**: Update indicator within 1 second of presence change ✓
- **Requirement 12.3**: Display green dot for online users ✓
- **Requirement 12.4**: Display gray dot or no indicator for offline users ✓
- **Requirement 12.5**: Show last seen timestamp for offline users on profile pages ✓

## Notes

- The widget automatically watches the presence state via Riverpod
- Updates are reactive and happen within 1 second of presence changes
- The `lastSeenAt` parameter must be provided by your backend/data layer
- All widgets are optimized for performance using `ConsumerWidget`
