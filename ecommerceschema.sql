-- E-commerce Store Relational Schema for MySQL
-- File: ecommerce_schema.sql
-- Engine: InnoDB, Charset: utf8mb4

--1) Create database
CREATE DATABASE IF NOT EXISTS 'ecommerce_db' CHARACTER SET = 'utf8mb4' COLLATE = 'utf8mb4_unicode_ci';
USE 'ecommerce_db';

--2) Users (customers & system users)
CREATE TABLE 'users' (
  'user_id' INT UNSIGNED NOT NULL AUTO_INCREMENT,
  'email' VARCHAR(255) NOT NULL,
  'password_hash' VARCHAR(255) NOT NULL,
  'username' VARCHAR(100) DEFAULT NULL,
  'phone' VARCHAR(20) DEFAULT NULL,
  'is_active' TINYINT(1) NOT NULL DEFAULT 1,
  'created_at' DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  'updated_at' DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY ('user_id'),
  UNIQUE KEY 'uq_users_email' ('email'),
  UNIQUE KEY 'uq_users_username' ('username')
) ENGINE=InnoDB;

-- 1-to-1: user_profiles (optional one-to-one with users)
CREATE TABLE 'user-profiles' (
  'profile_id' INT UNSIGNED NOT NULL AUTO_INCREMENT,
  'user_id' INT UNSIGNED NOT NULL,
  'first_name' VARCHAR(100) DEFAULT NULL,
  'last_name' VARCHAR(100) DEFAULT NULL,
  'date_of_birth' DATE DEFAULT NULL,
  'gender' ENUM('male', 'female', 'other') DEFAULT NULL,
  'bio' TEXT DEFAULT NULL,
  PRIMARY KEY ('profile_id'),
  UNIQUE KEY 'uq_user_profiles_userid' ('user_id'),
  CONSTRAINT 'fk_user_profiles_user' FOREIGN KEY ('user_id') REFERENCES 'users' ('user_id') ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Addresses: One user -> many addresses
CREATE TABLE 'addresses' (
  'address_id' INT UNSIGNED NOT NULL AUTO_INCREMENT,
  'user_id' INT UNSIGNED NOT NULL,
  'label' VARCHAR(50) DEFAULT 'home', --e.g., home, work
  'street' VARCHAR(255) NOT NULL,
  'city' VARCHAR(100) NOT NULL
  'state' VARCHAR(100) DEFAULT NULL,
  'postal_code' VARCHAR(20) DEFAULT NULL,
  'country' VARCHAR(100) NOT NULL,
  'is_default' TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY ('address_id'),
  INDEX 'idx_addresses_user' ('user_id'),
  CONSTRAINT 'fk_addresses_user' FOREIGN KEY ('user_id') REFERENCES 'users' ('user_id') ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Categories (hierarchical using parent_id_)
CREATE TABLE 'categories' (
  'category_id' INT UNSIGNED NOT NULL AUTO_ICREMENT,
  'name' VARCHAR(100) NOT NULL,
  'slug' VARCHAR(120) NOT NULL,
  'description' TEXT DEFAULT NULL,
  'parent_id' INT UNSIGNED DEFAULT NULL,
  'created-at' DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ('category_id'),
  UNIQUE KEY 'uq_categories_slug' ('slug'),
  CONSTRAINT 'fk_categories_parent' FOREIGN KEY ('parent-id') REFERENCES 'categories' ('category_id') ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Products
CREATE TABLE 'products' (
  'product_id' INT UNSIGNED NOT NULL AUTO_INCREMENT,
  'sku' VARCHAR(60) NOT NULL,
  'name' VARCHAR(255) NOT NULL,
  'description' TEXT DEFAULT NULL,
  'price' DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  'is_active' TINYINT(1) NOT NULL DEFAULT 1,
  'created_at' DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  'updated_at' DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY ('product_id'),
  UNIQUE KEY 'uq_products_sku' ('sku')
) ENGINE=InnoDB;

-- Many-to-Many: product <-> category
CREATE TABLE 'product_categories' (
  'product_id' INT UNSIGNED NOT NULL,
  'category_id' INT UNSIGNED NOT NULL,
  PRIMARY KEY ('product_id', 'category_id'),
  CONSTRAINT 'fk_pc_product' FOREIGN KEY ('product-id') REFERENCES 'products' ('product_id')ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT 'fk_pc_category' FOREIGN KEY ('category_id') REFERENCES 'categories' ('category_id') ON DELETE CASCADE ON UPDATE CASCADE,
) ENGINE=InnoDB;

-- Product images (one-to-many)
CREATE TABLE 'product_images' (
  'image_id' INT UNSIGNED NOT NULL AUTO_INCREMENT,
  'product_id' INT UNSIGNED NOT NULL,
  'url' VARCHAR(500) NOT NULL,
  'alt_text' VARCHAR(255) DEFAULT NULL,
  'position' INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY ('image_id'),
  INDEX 'idx_product_images_product' ('product_id'),
  CONSTRAINT 'fk_product_images_product' FOREIGN KEY ('product_id') REFERENCES 'products' ('product_id') ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Inventory: tracks stock per product (simple model) --can be extended per warehouse
CREATE TABLE 'inventory' (
  'inventory_id' INT UNSIGNED NOT NULL AUTO_INCREMENT,
  'product-id' INT UNSIGNED NOT NULL,
  'quantity' INT NOT NULL DEFAULT 0,
  'reorder_threshold' INT NOT NULL DEFAULT 0,
  'last_updated' DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURENT_TIMESTAMP,
  PRIMARY KEY ('inventory_id'),
  UNIQUE KEY 'uq_inventory_product' ('product_id'),
  CONSTRAINT 'fk_inventory_product' FOREIGN KEY ('product_id') REFERENCES 'products' ('product_id') ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Coupons / Discount codes
CREATE TABLE 'coupons' (
  'coupon_id' INT UNSIGNED NOT NULL AUTO_INCREMENT,
  'code' VARCHAR(50) NOT NULL,
  'description' VARCHAR(255) DEFAULT NULL,
  'discount_percent' DECIMAL(5,2) DEFAULT NULL,
  'discount_amount' DECIMAL(12,2) DEFAULT NULL,
  'valid_from' DATETIME DEFAULT NULL,
  'valid_until' DATETIME DEFAULT NULL,
  'is_active' TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY ('coupon_id'),
  UNIQUE KEY 'uq_coupons_code' ('code')
) ENGINE=InnoDB;

-- Orders (one user -> many orders)
CREATE TABLE 'orders' (
  'order_id' BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  'user_id' INT UNSIGNED NOT NULL,
  'order_number' VARCHAR(50) NOT NULL,
  'address_id' INT UNSIGNED NOT NULL,
  'coupon_id' INT UNSIGNED DEFAULT NULL,
  'status' ENUM('pending', 'processing','shipped','delivered','cancelled','refunded' ) NOT NULL DEFAULT 'pending',
  'subtotal' DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  'discount' DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  'shipping_fee' DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  'tax' DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  'placed_at' DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ('order_id'),
  UNIQUE KEY 'uq_orders_ordernumber' ('order_number'),
  INDEX 'idx_orders_user' ('user_id'),
  CONSTRAINT 'fk_orders_user' FOREIGN KEY ('user_id') REFERENCES 'users' ('user_id') ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT 'fk_orders_address' FOREIGN KEY ('address_id') REFERENCES 'addresses' ('address_id') ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT 'fk_orders_coupon' FOREIGN KEY ('coupon_id') REFERENCES 'coupons' ('coupon_id') ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

  -- Order items (order -> many order items). product referenced for historical price.
  CREATE TABLE 'order_items' (
    'order_item_id' BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    'order_id' BIGINT UNSIGNED NOT NULL,
    'product_id' INT UNSIGNED NOT NULL,
    'product_name' VARCHAR(255) NOT NULL,
    'sku' VARCHAR(60) DEFAULT NULL,
    'unit_price' DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    'quantity' INT UNSIGNED NOT NULL DEFAULT 1,
    'line_total' DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY ('order_item_id'),
    INDEX 'idx_order_items_order' ('order_id'),
    CONSTRAINT 'fk_order_items_order' FOREIGN KEY ('order_id') REFERENCES 'orders' ('order_id') ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT 'fk_order_items_product' FOREIGN KEY ('product_id') REFERENCES 'products' ('product_id') ON DELETE RESTRICT ON UPDATE CASCADE
  ) ENGINE=InnoDB;

  -- Payments (one-to-one-ish with orders, or multiple payments per order allowed)
  CREATE TABLE 'payments' (
    'payment_id' BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    'order_id' BIGINT UNSIGNED NOT NULL,
    'payment_method' ENUM('card', 'mobile_money', 'bank_transfer', 'cash_on_delivery') NOT NULL,
    'amount' DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    'currency' VARCHAR(10) NOT NULL DEFAULT 'USD',
    'status' ENUM('pending', 'paid', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
    'transaction_reference' VARCHAR(255) DEFAULT NULL,
    'paid_at' DATETIME DEFAULT NULL,
    PRIMARY KEY ('payment_id'),
    UNIQUE KEY 'uq_payments_txref' ('transaction_reference'),
    INDEX 'idx_payments_order' ('order_id'),
    CONSTRAINT 'fk_payments_order' FOREIGN KEY ('order_id') REFERENCES 'orders' ('order_id') ON DELETE CASCADE ON UPDATE CASCADE
  ) ENGINE=InnoDB;

  -- Shipments (an order can have multiple shipments)
  CREATE TABLE 'shipments' (
    'shipment_id' BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    'order_id' BIGINT UNSIGNED NOT NULL,
    'carrier' VARCHAR(100) DEFAULT NULL,
    'tracking_number' VARCHAR(255) DEFAULT NULL,
    'shipped_at' DATETIME DEFAULT NULL,
    'delivered_at' DATETIME DEFAULT NULL,
    'status' ENUM('ready', 'in_transit', 'delivered', 'lost', 'returned') NOT NULL DEFAULT 'ready',
    PRIMARY KEY ('shipment_id'),
    INDEX 'idx_shipments_order' ('order_id'),
    CONSTRAINT 'fk_shipments_order' FOREIGN KEY ('order_id') REFERENCES 'orders' ('order_id') ON DELETE CASCADE ON UPDATE CASCADE
  ) ENGINE=InnoDB;

  -- Product reviews (one user can leave many reviews, one review per product user)
  CREATE TABLE 'reviews' (
    'review_id' BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    'product_id' INT UNSIGNED NOT NULL,
    'user_id' INT UNSIGNED NOT NULL,
    'rating' TINYINT UNSIGNED NOT NULL CHECK ('rating' BETWEEN 1 AND 5),
    'title' VARCHAR(255) DEFAULT NULL,
    'body' TEXT DEFAULT NULL,
    'created_at' DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('review_id'),
    UNIQUE KEY 'uq_reviews_product_user' ('product_id', 'user_id'),
    INDEX 'idx_reviews_product' ('product_id')
    CONSTRAINT 'fk_reviews_product' FOREIGN KEY ('product_id') REFERENCES 'products' ('product_id') ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT 'fk_reviews_user' FOREIGN KEY (user_id) REFERENCES 'users' ('user_id') ON DELETE CASCADE ON UPDATE CASCADE
  ) ENGINE=InnoDB;

  -- Wishlists (many-to-many between users and products)
  CREATE TABLE 'wishlists' (
    'user_id' INT UNSIGNED NOT NULL,
    'product_id' INT UNSIGNED NOT NULL,
    'added_at' DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('user_id', 'product_id'),
    CONSTRAINT 'fk_wishlists_user' FOREIGN KEY ('user_id') REFERENCES 'users' ('user_id') ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT 'fk_wishlists_product' FOREIGN KEY ('product_id') REFERENCES 'products' ('product_id') ON DELETE CASCADE ON UPDATE CASCADE
  ) ENGINE=InnoDB;

  -- Audit log (simplified)
  CREATE TABLE 'audit_logs' (
    'log_id' BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    'entity' VARCHAR(100) NOT NULL,
    'entity_id' VARCHAR(100) DEFAULT NULL,
    'action' VARCHAR(50) NOT NULL,
    'performed_by' INT UNSIGNED DEFAULT NULL,
    'details' JSON DEFAULT NULL,
    'created_at' DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('log_id'),
    INDEX 'idx_audit_performed_by' ('performed_by'),
    CONSTRAINT 'fk_audit_performed_by' FOREIGN KEY ('performed_by') REFERENCES 'users' ('user_id') ON DELETE SET NULL ON UPDATE CASCADE
  ) ENGINE=InnoDB;

  -- Useful sample views (optional)
  DROP VIEW IF EXISTS 'vw_order_summary';
  CREATE VIEW 'vw_order_summary' AS
  SELECT o.order_id, o.order_number, o.user_id, u.email AS user_email, o.status, o.total, o.placed_at
  FROM orders one
  JOIN users u ON u u.user_id = o.user_id;

  -- End of schema
  -- Notes:
  -- * Adjust types, lengths and constraints as needed for production (e.g., stronger password storage, audit requirements).
  -- * You may add triggers to decrement inventory on payment or order creation, add stored procedures for complex operations.

  COMMIT;