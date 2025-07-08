# Cloudinary Setup Guide for Lead Kart

This guide will help you set up Cloudinary for image storage and optimization in your Lead Kart app.

## 1. Create Cloudinary Account

1. Go to [Cloudinary](https://cloudinary.com/) and sign up for a free account
2. After verification, you'll be taken to your dashboard
3. Note down your credentials from the dashboard:
   - **Cloud Name** (e.g., `your-cloud-name`)
   - **API Key** (e.g., `123456789012345`)
   - **API Secret** (e.g., `abcdefghijklmnopqrstuvwxyz`)

## 2. Create Upload Preset

1. In your Cloudinary dashboard, go to **Settings** → **Upload**
2. Scroll down to **Upload presets**
3. Click **Add upload preset**
4. Configure the preset:
   - **Preset name**: `leadkart_products` (or any name you prefer)
   - **Signing Mode**: `Unsigned` (for client-side uploads)
   - **Folder**: `products` (optional, for organization)
   - **Transformation**: 
     - **Quality**: `Auto`
     - **Format**: `Auto`
     - **Resize**: `Limit` with width/height of 1024px
5. Click **Save**

## 3. Update Configuration

Update `lib/core/config/cloudinary_config.dart` with your credentials:

```dart
class CloudinaryConfig {
  // Replace with your actual Cloudinary credentials
  static const String cloudName = 'your-cloud-name'; // Your cloud name
  static const String apiKey = 'your-api-key'; // Your API key
  static const String apiSecret = 'your-api-secret'; // Your API secret
  static const String uploadPreset = 'leadkart_products'; // Your upload preset name

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  // ... rest of the configuration
}
```

## 4. Test Image Upload

1. Run your app: `flutter run`
2. Login as a seller
3. Go to "Add Product" 
4. Try uploading an image
5. Check your Cloudinary dashboard to see if the image appears

## 5. Image Optimization Features

The app automatically optimizes images:

### For Grid Views (Product Lists)
- Resized to 200x200px
- Auto quality and format
- Fast loading for better performance

### For Detail Views (Product Details)
- Resized to 400x400px
- Auto quality and format
- Better quality for detailed viewing

### Manual Optimization
```dart
// Get optimized URL
final cloudinaryService = CloudinaryService();
final optimizedUrl = cloudinaryService.getOptimizedImageUrl(
  originalUrl,
  width: 300,
  height: 300,
  quality: 'auto',
  format: 'auto',
);
```

## 6. Using the Custom Image Widgets

The app includes custom widgets for better image handling:

### CloudinaryImage
```dart
CloudinaryImage(
  imageUrl: product.imageUrl,
  width: 200,
  height: 200,
  isGrid: true, // Enables grid optimization
  borderRadius: BorderRadius.circular(12),
)
```

### CloudinaryImageWithFallback
```dart
CloudinaryImageWithFallback(
  imageUrl: product.imageUrl,
  width: 200,
  height: 200,
  isGrid: true,
  placeholderText: 'No Product Image',
  onTap: () => _showImagePicker(),
)
```

## 7. Free Tier Limits

Cloudinary free tier includes:
- **25 GB** storage
- **25 GB** monthly bandwidth
- **25,000** images and videos
- **1,000** transformations per month

This should be sufficient for development and small-scale production use.

## 8. Production Considerations

For production:

1. **Enable signed uploads** for better security
2. **Set up webhooks** for upload notifications
3. **Configure auto-backup** to cloud storage
4. **Monitor usage** to avoid exceeding limits
5. **Implement image compression** before upload

## 9. Troubleshooting

### Upload Fails
- Check internet connection
- Verify credentials in `cloudinary_config.dart`
- Ensure upload preset is set to "Unsigned"
- Check file size (max 10MB in current implementation)

### Images Don't Display
- Check if `cached_network_image` package is included
- Verify image URLs in database
- Check if images exist in Cloudinary dashboard

### Slow Loading
- Images are automatically optimized
- Enable auto format/quality in upload preset
- Consider using progressive JPEG format

## 10. Support

For issues:
- Check [Cloudinary Documentation](https://cloudinary.com/documentation)
- Review [Flutter Integration Guide](https://cloudinary.com/documentation/flutter_integration)
- Contact Cloudinary support for account issues

---

 