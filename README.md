# Lead Kart - College E-Commerce App

A Flutter e-commerce application designed specifically for college students and staff, built with Supabase backend and Cloudinary for image management.

## Features

### For Customers (Students/Staff)
- **Authentication**: Email/password signup and login
- **Product Browsing**: View products with categories (Food/Other)
- **Search & Filter**: Find products by name and category
- **Real-time Updates**: See seller online/offline status
- **Order Management**: Place orders and track status
- **Direct Contact**: Contact information available

### For Sellers
- **Seller Dashboard**: Manage products and orders
- **Product Management**: Add, edit, delete products with images
- **Order Processing**: View and update order status
- **Real-time Notifications**: Get notified of new orders
- **Status Control**: Toggle online/offline status

## Technology Stack

- **Frontend**: Flutter 3.7.2+
- **Backend**: Supabase (PostgreSQL, Auth, Real-time)
- **Image Storage**: Cloudinary
- **State Management**: Provider
- **External Communication**: URL launcher for external links

## Prerequisites

- Flutter SDK 3.7.2 or higher
- Dart SDK 3.0+
- Android Studio / VS Code
- Supabase account
- Cloudinary account

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd leadkart
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Supabase Setup

#### Create a Supabase Project
1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note down your project URL and anon key from Settings > API

#### Database Setup
Run the following SQL in your Supabase SQL editor:

```sql
-- Create the users table for customers (students/staff)
CREATE TABLE users (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  user_type TEXT NOT NULL, -- "Student" or "Staff"
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create the sellers table
CREATE TABLE sellers (
  seller_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  brand_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  status TEXT DEFAULT 'offline'::text NOT NULL, -- "online" or "offline"
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create the products table
CREATE TABLE products (
  product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID REFERENCES sellers(seller_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price REAL NOT NULL,
  stock INTEGER NOT NULL,
  category TEXT NOT NULL, -- "Food" or "Other"
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create the orders table
CREATE TABLE orders (
  order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
  seller_id UUID REFERENCES sellers(seller_id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(product_id) ON DELETE SET NULL,
  quantity INTEGER NOT NULL,
  total_price REAL NOT NULL,
  delivery_location TEXT,
  status TEXT DEFAULT 'Pending'::text NOT NULL, -- "Pending" or "Delivered"
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Realtime on tables
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE sellers;
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
```

#### Row Level Security (RLS) Policies
Add these RLS policies for security:

```sql
-- Users table policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = auth_user_id);

-- Sellers table policies
ALTER TABLE sellers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Sellers can read own data" ON sellers
  FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Public can read seller status" ON sellers
  FOR SELECT USING (true);

CREATE POLICY "Sellers can insert own data" ON sellers
  FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "Sellers can update own data" ON sellers
  FOR UPDATE USING (auth.uid() = auth_user_id);

-- Products table policies
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read products" ON products
  FOR SELECT USING (true);

CREATE POLICY "Sellers can manage own products" ON products
  FOR ALL USING (seller_id IN (
    SELECT seller_id FROM sellers WHERE auth_user_id = auth.uid()
  ));

-- Orders table policies
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own orders" ON orders
  FOR SELECT USING (customer_id IN (
    SELECT user_id FROM users WHERE auth_user_id = auth.uid()
  ));

CREATE POLICY "Sellers can read orders for their products" ON orders
  FOR SELECT USING (seller_id IN (
    SELECT seller_id FROM sellers WHERE auth_user_id = auth.uid()
  ));

CREATE POLICY "Customers can create orders" ON orders
  FOR INSERT WITH CHECK (customer_id IN (
    SELECT user_id FROM users WHERE auth_user_id = auth.uid()
  ));

CREATE POLICY "Sellers can update order status" ON orders
  FOR UPDATE USING (seller_id IN (
    SELECT seller_id FROM sellers WHERE auth_user_id = auth.uid()
  ));
```

### 4. Cloudinary Setup

1. Create a Cloudinary account at [cloudinary.com](https://cloudinary.com)
2. Go to your Dashboard and note:
   - Cloud Name
   - API Key
   - API Secret
3. Create an upload preset:
   - Go to Settings > Upload
   - Scroll down to "Upload presets"
   - Click "Add upload preset"
   - Set it to "Unsigned"
   - Note the preset name

### 5. Configure Environment Variables

Update the configuration files with your credentials:

#### lib/core/config/supabase_config.dart
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace with your actual Supabase URL and anon key
  static const String supabaseUrl = '--url--';
  static const String supabaseAnonKey =
      ' --key--';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}

```

#### lib/core/config/cloudinary_config.dart
```dart
  // Demo Cloudinary credentials - 
  static const String cloudName = '--name--'; 
  static const String apiKey = '--api-key--';
  static const String apiSecret =
      '--secret--'; 
  static const String uploadPreset =
      'ml_default'; 

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

```

### 6. Run the Application

```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── config/           # Configuration files
│   ├── providers/        # State management providers
│   └── services/         # Core services (auth, cloudinary, notifications)
├── features/
│   ├── auth/            # Authentication screens
│   ├── customer/        # Customer-specific features
│   └── seller/          # Seller-specific features
├── models/              # Data models
└── main.dart           # App entry point
```

## Usage

### Customer Flow
1. **Login/Signup**: Create account or login as customer
2. **Browse Products**: View products in grid layout
3. **Filter/Search**: Use category filter and search functionality
4. **Product Details**: View product details and place order
5. **Order Tracking**: Track order status in Orders tab
6. **Contact Seller**: View seller contact information

### Seller Flow
1. **Seller Login/Signup**: Create seller account or login
2. **Manage Products**: Add, edit, delete products with images
3. **Process Orders**: View and update order status
4. **Customer Communication**: View customer contact information
5. **Status Management**: Toggle online/offline status

## Features Implementation Status

✅ **Completed**
- Authentication system (Customer & Seller)
- Database schema and RLS policies
- Core services (Auth, Cloudinary, Notifications)
- State management with Provider
- Basic app structure and navigation

🔄 **In Progress**
- Tab content implementation
- Product management UI
- Order management UI
- Real-time features
- Image upload functionality

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Security Notes

- Never commit API keys or secrets to version control
- Use environment variables for sensitive configuration
- Enable RLS policies on all Supabase tables
- Validate all user inputs
- Implement proper error handling

## Troubleshooting

### Common Issues

1. **Supabase Connection Issues**
   - Verify URL and API key are correct
   - Check if RLS policies are properly configured

2. **Image Upload Issues**
   - Ensure Cloudinary credentials are correct
   - Verify upload preset is set to "Unsigned"

3. **Notification Issues**
   - Test on physical devices
   - Check notification permissions

4. **Build Issues**
   - Run `flutter clean && flutter pub get`
   - Check Flutter and Dart SDK versions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Open an issue on GitHub
- Check the documentation
- Review the troubleshooting section

---

**Note**: This is a college e-commerce platform designed for educational and practical use within college communities. Ensure compliance with your institution's policies before deployment.
