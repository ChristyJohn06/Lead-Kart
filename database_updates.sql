-- Database Updates for Lead Kart
-- Run these commands in your Supabase SQL Editor

-- 1. Add missing columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS name TEXT;

-- 2. Add missing columns to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_in_stock BOOLEAN DEFAULT true;
ALTER TABLE products ADD COLUMN IF NOT EXISTS seller_phone TEXT;

-- 3. Add missing columns to orders table  
ALTER TABLE orders ADD COLUMN IF NOT EXISTS product_name TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS seller_name TEXT;

-- 4. Update existing products to have is_in_stock based on stock
UPDATE products SET is_in_stock = (stock > 0) WHERE is_in_stock IS NULL;

-- 5. Create a function to automatically update is_in_stock when stock changes
CREATE OR REPLACE FUNCTION update_product_stock_status()
RETURNS TRIGGER AS $$
BEGIN
    NEW.is_in_stock = (NEW.stock > 0);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Create trigger to auto-update is_in_stock
DROP TRIGGER IF EXISTS trigger_update_stock_status ON products;
CREATE TRIGGER trigger_update_stock_status
    BEFORE UPDATE OF stock ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_product_stock_status();

-- 7. Create a function to populate seller_phone in products from sellers table
CREATE OR REPLACE FUNCTION sync_seller_phone_to_products()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE products 
    SET seller_phone = NEW.phone 
    WHERE seller_id = NEW.seller_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger to sync seller phone changes to products
DROP TRIGGER IF EXISTS trigger_sync_seller_phone ON sellers;
CREATE TRIGGER trigger_sync_seller_phone
    AFTER UPDATE OF phone ON sellers
    FOR EACH ROW
    EXECUTE FUNCTION sync_seller_phone_to_products();

-- 9. Initial sync of seller phones to existing products
UPDATE products 
SET seller_phone = sellers.phone 
FROM sellers 
WHERE products.seller_id = sellers.seller_id 
AND products.seller_phone IS NULL;

-- 10. Create function to populate order details when order is created
CREATE OR REPLACE FUNCTION populate_order_details()
RETURNS TRIGGER AS $$
BEGIN
    -- Get product and seller names
    SELECT p.name, s.username
    INTO NEW.product_name, NEW.seller_name
    FROM products p
    JOIN sellers s ON p.seller_id = s.seller_id
    WHERE p.product_id = NEW.product_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 11. Create trigger to auto-populate order details
DROP TRIGGER IF EXISTS trigger_populate_order_details ON orders;
CREATE TRIGGER trigger_populate_order_details
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION populate_order_details();

-- 12. Populate existing orders with product and seller names
UPDATE orders 
SET 
    product_name = p.name,
    seller_name = s.username
FROM products p
JOIN sellers s ON p.seller_id = s.seller_id
WHERE orders.product_id = p.product_id 
AND (orders.product_name IS NULL OR orders.seller_name IS NULL);

-- 13. Update users table to use username as name for existing records
UPDATE users SET name = username WHERE name IS NULL;

-- 14. Create view for orders with full details (optional, for easier querying)
CREATE OR REPLACE VIEW order_details AS
SELECT 
    o.*,
    u.username as customer_name,
    u.phone as customer_phone,
    p.name as product_name_from_product,
    p.image_url as product_image,
    s.username as seller_name_from_seller,
    s.phone as seller_phone_from_seller
FROM orders o
LEFT JOIN users u ON o.customer_id = u.user_id
LEFT JOIN products p ON o.product_id = p.product_id
LEFT JOIN sellers s ON o.seller_id = s.seller_id;

-- Enable RLS if not already enabled (recommended for security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions (adjust based on your RLS policies)
GRANT ALL ON orders TO authenticated;
GRANT ALL ON products TO authenticated;
GRANT ALL ON sellers TO authenticated;
GRANT ALL ON users TO authenticated; 