# Photo & Gallery Permissions Setup

This document explains how photo and gallery permissions are implemented in the Lead Kart Flutter app.

## Overview

The app uses the `image_picker` package to allow sellers to:
- Select product images from the photo gallery
- Take new photos using the camera
- Upload images to Cloudinary for storage

## Permissions Required

### iOS Permissions (Info.plist)

The following permissions are configured in `ios/Runner/Info.plist`:

```xml
<!-- Photo Library Permission -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to select product images for upload.</string>

<!-- Camera Permission -->
<key>NSCameraUsageDescription</key>
<string>This app needs access to your camera to take product photos.</string>
```

### Android Permissions (AndroidManifest.xml)

The following permissions are configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Photo/Gallery permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>

<!-- For Android 13+ (API level 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

## Implementation Features

### 1. Source Selection Dialog

When users tap to add/edit a product image, they see a dialog with options:
- **Camera**: Take a new photo
- **Gallery**: Select from existing photos
- **Cancel**: Close dialog

### 2. Enhanced Error Handling

The app provides specific error messages for permission issues:
- Photo access denied
- Camera access denied
- General permission denied
- Settings guidance

### 3. User Feedback

- Success message when image is selected
- Error messages with actionable guidance
- Settings button to help users enable permissions

## Permission Flow

### First Time Usage

1. User taps "Add Product Image"
2. Source selection dialog appears
3. User selects Camera or Gallery
4. System permission dialog appears (first time only)
5. User grants or denies permission
6. App responds accordingly

### Permission Denied Handling

If permissions are denied:
1. Specific error message is shown
2. SnackBar includes "Settings" action button
3. Guidance on how to enable permissions manually

### Subsequent Usage

Once permissions are granted:
1. Image picker opens directly
2. User selects image
3. Success confirmation is shown
4. Image is prepared for upload

## Testing Permissions

### iOS Testing

1. Reset permissions: Settings > General > Reset > Reset Location & Privacy
2. Launch app and test image selection
3. Verify permission dialogs appear
4. Test both Allow and Don't Allow scenarios

### Android Testing

1. Clear app data or uninstall/reinstall
2. Launch app and test image selection
3. Verify permission dialogs appear
4. Test Allow, Deny, and "Don't ask again" scenarios

## Error Scenarios

### Common Issues

1. **Permission Denied**: Clear error message with settings guidance
2. **No Image Selected**: Graceful handling, no error shown
3. **File Access Error**: Specific error message about file access
4. **Network Issues**: Separate handling for upload failures

### Error Messages

- `"Photo access denied. Please enable photo permissions in Settings."`
- `"Camera access denied. Please enable camera permissions in Settings."`
- `"Permission denied. Please allow photo access in Settings."`

## Best Practices Implemented

### 1. Progressive Disclosure
- Only request permissions when needed
- Explain why permissions are required

### 2. Graceful Degradation
- App continues to work without images
- Clear indication when images can't be added

### 3. User Guidance
- Specific error messages
- Actionable guidance for fixing issues
- Settings navigation hints

### 4. Platform Considerations
- iOS: Uses NSPhotoLibraryUsageDescription
- Android: Handles both legacy and modern permissions
- Android 13+: Uses READ_MEDIA_IMAGES for better privacy

## Code Structure

### Image Picker Implementation

```dart
Future<void> _pickImage() async {
  try {
    // Show source selection dialog
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image != null) {
      // Handle successful selection
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  } catch (e) {
    // Handle permission errors and other issues
    _handleImagePickerError(e);
  }
}
```

### Error Handling

```dart
void _handleImagePickerError(dynamic error) {
  String errorMessage = 'Error picking image';
  
  if (error.toString().contains('photo_access_denied')) {
    errorMessage = 'Photo access denied. Please enable photo permissions in Settings.';
  } else if (error.toString().contains('camera_access_denied')) {
    errorMessage = 'Camera access denied. Please enable camera permissions in Settings.';
  }
  
  // Show error with settings guidance
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorMessage),
      action: SnackBarAction(
        label: 'Settings',
        onPressed: () => _showSettingsGuidance(),
      ),
    ),
  );
}
```

## Future Enhancements

### Possible Improvements

1. **Direct Settings Navigation**: Use `app_settings` package to open settings directly
2. **Permission Status Check**: Check permission status before showing picker
3. **Batch Image Selection**: Allow multiple image selection
4. **Image Cropping**: Add image editing capabilities
5. **Permission Rationale**: Show explanation dialog before requesting permissions

### Advanced Features

1. **Runtime Permission Requests**: More granular permission handling
2. **Limited Photo Access**: Handle iOS 14+ limited photo access
3. **Background Upload**: Continue uploads when app is backgrounded
4. **Offline Support**: Queue images for upload when connection returns

## Troubleshooting

### Common Issues

1. **Permissions not working**: Check Info.plist and AndroidManifest.xml
2. **App crashes on image selection**: Verify all permissions are declared
3. **Images not uploading**: Check Cloudinary configuration
4. **Poor image quality**: Adjust imageQuality parameter

### Debug Steps

1. Check device logs for permission errors
2. Verify app permissions in device settings
3. Test on different Android/iOS versions
4. Clear app data and test fresh install

## Security Considerations

### Privacy

- Only request necessary permissions
- Explain permission usage clearly
- Handle permission denial gracefully
- Don't store sensitive image data locally

### Data Protection

- Images uploaded to secure Cloudinary storage
- No local caching of sensitive images
- Proper error handling prevents data leaks
- User can remove images anytime

This implementation ensures a smooth user experience while respecting platform-specific permission requirements and user privacy preferences. 