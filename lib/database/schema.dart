const String initialSqlScript = '''
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL,
    description TEXT
);
INSERT INTO "categories" VALUES(1,'Masala Varieties','Spice mixes and masala powders');
INSERT INTO "categories" VALUES(2,'Masala Ingredients','Raw spices, grains, and ingredients');
INSERT INTO "categories" VALUES(3,'Aroma Masala Ingredients','Aromatic whole spices and flavouring items');
INSERT INTO "categories" VALUES(4,'Flour Varieties','Grain flours and ready mix powders');
INSERT INTO "categories" VALUES(5,'Dal Varieties','Lentils, pulses, and gram varieties');
INSERT INTO "categories" VALUES(6,'Cashew Varieties','Cashew nut splits, pieces, and whole grades');
INSERT INTO "categories" VALUES(7,'Dry Fruits','Nuts, dried fruits, and edible seeds');

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    city TEXT,
    gst_number TEXT,
    created_at TEXT
);
INSERT INTO "customers" VALUES(1,'Walk-in Customer','','','Coimbatore',NULL,NULL);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_name TEXT NOT NULL,
    category_id INTEGER,
    purchase_price REAL,
    selling_price REAL,
    stock INTEGER,
    minimum_stock INTEGER,
    gst REAL,
    unit TEXT,
    barcode TEXT,
    created_at TEXT,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Masala Varieties (Category 1)
INSERT INTO "products" (product_name, category_id, purchase_price, selling_price, stock, minimum_stock, gst, unit, barcode) VALUES
('Chettinadu Chicken Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK002'),
('Curry Chilli Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK008'),
('SPL Curry Chilli Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK008A'),
('SPL Biryani Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK007'),
('Chicken Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK054'),
('Mutton Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK024'),
('Fish Fry Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK025'),
('SPL Chettinadu Garam Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK048'),
('SPL Pepper Chicken Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK041'),
('SPL Fish Curry Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK045'),
('SPL Curry Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK046'),
('SPL Instant 65 Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK059'),
('SPL Sambar Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK033A'),
('SPL Ground Sambar Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK033'),
('SPL Rasam Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK075A'),
('SPL Ground Rasam Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK055'),
('SPL Idli Milagai Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK072G'),
('Black Sesame Idli Milagai Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK022A'),
('SPL Chilli Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK036'),
('SPL Kashmiri Chilli Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK043'),
('Chilli Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK030'),
('Coriander Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK035'),
('Roasted Country Coriander Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK050'),
('Roasted Pepper Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK004'),
('Cumin Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK038'),
('Turmeric Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK032'),
('SPL Garlic Paruppu Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK066A'),
('Curry Leaves Idly Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK082'),
('White Sesame Idli Milagai Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK019'),
('SPL Garlic Idli Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK083'),
('Fennel Powder (Sombu Podi)', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK049'),
('SPL ENDO 5 Chilli Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK065'),
('TEJA Chilli Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK042'),
('Crushed Idli Milagai Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK072H'),
('Oil Roasted Chilli Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK065A'),
('Gundu Chilli Powder', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK084'),
('SPL Chicken 65 Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK059A'),
('Moringa Masala Podi', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK089'),
('SPL Vatha Kuzhambu Masala', 1, 0.0, 0.0, 0, 5, 0.0, 'pcs', 'SK090');

-- Masala Ingredients (Category 2)
INSERT INTO "products" (product_name, category_id, purchase_price, selling_price, stock, minimum_stock, gst, unit, barcode) VALUES
('Finger Turmeric (Virali Manjal)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI001'),
('Red Chilli', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI002'),
('S10 Chilli', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI003'),
('ENDO 5 Chilli', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI004'),
('Gundu Chilli', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI005'),
('Kashmiri Chilli', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI006'),
('Teja Chilli', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI007'),
('Coriander Seeds', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI008'),
('Black Pepper', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI009'),
('Cumin Seeds (Jeera)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI010'),
('Fennel Seeds (Sombu)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI011'),
('Big Mustard Seeds', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI012'),
('Fenugreek Seeds', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI013'),
('Garlic', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI014'),
('Dry Ginger', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI015'),
('Asafoetida (Perungayam)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI016'),
('Salt', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI017'),
('Cowpeas (Thattapayiru)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI018'),
('Red Rice', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI019'),
('Green Peas', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI020'),
('Rajma (Kidney Beans)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI021'),
('Tamarind', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI022'),
('Desiccated Coconut', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI023'),
('Boiled Rice', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI024'),
('Idli Rice', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI025'),
('Raw Rice', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI026'),
('Small Mustard Seeds', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI027'),
('Rava (Semolina)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI028'),
('Maida (All Purpose Flour)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI029'),
('Whole Wheat', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI030'),
('Country Sugar', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI031'),
('Pearl Millet (Kambu)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI032'),
('Ragi (Finger Millet)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI033'),
('Black Kavuni Rice', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI034'),
('Samba Wheat', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI035'),
('Maize / Corn', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI036'),
('White Soya Beans', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI037'),
('Fried Gram (Pottu Kadalai)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI038'),
('White Sorghum', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI039'),
('Green Gram', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI040'),
('Almonds (Badam)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI041'),
('Barley', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI042'),
('Sago (Javvarisi)', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI043'),
('Corn Flour', 2, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKMI044');

-- Aroma Masala Ingredients (Category 3)
INSERT INTO "products" (product_name, category_id, purchase_price, selling_price, stock, minimum_stock, gst, unit, barcode) VALUES
('Cinnamon Bark', 3, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKAMI01'),
('Cloves', 3, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKAMI02'),
('Cardamom', 3, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKAMI03'),
('Star Anise', 3, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKAMI04'),
('Nutmeg', 3, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKAMI05'),
('Mace', 3, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKAMI06'),
('Biryani Bay Leaf', 3, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKAMI07'),
('Kapok Buds (Maratti Mokku)', 3, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKAMI08'),
('China Grass / Agar Agar', 3, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKAMI09'),
('Poppy Seeds (Kasakasa)', 3, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKAMI10');

-- Flour Varieties (Category 4)
INSERT INTO "products" (product_name, category_id, purchase_price, selling_price, stock, minimum_stock, gst, unit, barcode) VALUES
('SPL Health Mix Powder (Sathu Mavu)', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK058'),
('Gram Flour (Besan)', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK068'),
('Badam Mix Powder', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0AK'),
('Green Gram Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0AR'),
('Raw Rice Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0AC'),
('Wheat Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0AQ'),
('Idiyappam Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK078'),
('Maida Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0AF'),
('Bajji Mix Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK071'),
('Adai Mix Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK079'),
('Ragi Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0AS'),
('Red Rice Idiyappam Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0AU'),
('Rava Dosai Mix Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK076'),
('Kambu Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0AT'),
('Navadhanyam Dosai Mix Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK080'),
('Murukku Mix Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK077'),
('Black Kavuni Rice Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0AY'),
('Karasev Mix Flour', 4, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK081');

-- Dal Varieties (Category 5)
INSERT INTO "products" (product_name, category_id, purchase_price, selling_price, stock, minimum_stock, gst, unit, barcode) VALUES
('Chana Dal', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV01'),
('Toor Dal', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV02'),
('Black Urad Dal', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV03'),
('Whole White Urad Dal', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV04'),
('Split White Urad Dal', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV05'),
('Moong Dal', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV06'),
('Fried Gram', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV07'),
('Chickpeas (Kadalai)', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV08'),
('Green Chickpeas', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV09'),
('Whole Green Gram', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV10'),
('Black Sesame Seeds', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV11'),
('Black Chana (Sundal)', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV12'),
('White Chana (Kabuli)', 5, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKDV13');

-- Cashew Varieties (Category 6)
INSERT INTO "products" (product_name, category_id, purchase_price, selling_price, stock, minimum_stock, gst, unit, barcode) VALUES
('Cashew 1/2 (Split)', 6, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKCV01'),
('Cashew 1/4 (Quarter)', 6, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKCV02'),
('Cashew 1/8 SPL', 6, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKCV03'),
('Cashew Kurunai', 6, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKCV04'),
('PK Whole Cashew', 6, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKCV05'),
('SW Whole Cashew', 6, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SKCV06');

-- Dry Fruits (Category 7)
INSERT INTO "products" (product_name, category_id, purchase_price, selling_price, stock, minimum_stock, gst, unit, barcode) VALUES
('Whole Cashew', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF1'),
('Almonds (Badam)', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF2'),
('Pistachios', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF3'),
('Black Raisins', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF4'),
('Raisins (Dry Grapes)', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF5'),
('Dry Figs', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF6'),
('Dates', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF7'),
('Walnuts', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF8'),
('Salted Pistachios', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF9'),
('Pumpkin Seeds', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF10'),
('Watermelon Seeds', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF11'),
('Sunflower Seeds', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK0DF12'),
('Dry Fruits Mixture', 7, 0.0, 0.0, 0, 5, 0.0, 'kg', 'SK088');

CREATE TABLE sales (
    sale_id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_no TEXT NOT NULL,
    customer_id INTEGER,
    customer_name TEXT,
    date TEXT,
    subtotal REAL,
    discount REAL,
    gst REAL,
    grand_total REAL,
    payment_method TEXT,
    gst_rate REAL DEFAULT 0,
    cgst_rate REAL DEFAULT 0,
    sgst_rate REAL DEFAULT 0,
    taxable_amount REAL DEFAULT 0,
    cgst_amount REAL DEFAULT 0,
    sgst_amount REAL DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE sale_items (
    sale_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    sale_id INTEGER,
    product_id INTEGER,
    quantity REAL,
    price REAL,
    total REAL,
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE settings (
    settings_id INTEGER PRIMARY KEY AUTOINCREMENT,
    shop_name TEXT,
    address TEXT,
    phone TEXT,
    gst_number TEXT,
    invoice_prefix TEXT
);

INSERT INTO "settings" VALUES(1,'SK TRADERS','Mullai Street, Sanjeevi Nagar','0422-2345678','33ABCDE1234F1Z5','INV');
''';
