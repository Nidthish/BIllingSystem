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

-- Masalas (Category 1)
INSERT INTO "products" (product_name, category_id, purchase_price, selling_price, stock, minimum_stock, gst, unit, barcode) VALUES
('Chettinad Chicken Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK002'),
('Kuzhambu Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK008'),
('SPL Kuzhambu Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK008A'),
('SPL Biryani Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK007'),
('Chicken Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK054'),
('Mutton Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK024'),
('Fish Fry Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK025'),
('SPL Chettinad Garam Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK048'),
('SPL Pepper Chicken Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK041'),
('SPL Fish Curry Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK045'),
('SPL Curry Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK046'),
('SPL Instant 65 Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK059'),
('SPL Sambar Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK033A'),
('SPL Avarei Sambar Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK033'),
('SPL Rasam Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK075A'),
('SPL Avarei Rasam Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK055'),
('SPL Idli Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK072G'),
('Black Sesame Idli Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK022A'),
('SPL Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK036'),
('SPL Kashmiri Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK043'),
('Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK030'),
('Coriander Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK035'),
('Roasted Country Coriander Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK050'),
('Roasted Pepper Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK004'),
('Cumin Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK038'),
('Turmeric Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK032'),
('SPL Garlic Satha Dal Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK066A'),
('Curry Leaves Idly Podi', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK082'),
('White Sesame Idli Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK019'),
('SPL Garlic Idly Podi', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK083'),
('Sombu Podi', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK049'),
('SPL ENDO 5 Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK065'),
('TEJA Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK042'),
('Crushed Idli Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK072H'),
('Oil Roasted Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK065A'),
('GUNDU Chilli Powder', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK084'),
('SPL Chicken 65 Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK059A'),
('Moringa Masala Podi', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK089'),
('SPL Vatha Kuzhambu Masala', 1, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK090'),

-- Masala Ingredients (Category 2)
('Finger Turmeric', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI001'),
('Chilli', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI002'),
('S10 Chilli', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI003'),
('ENDO 5 Chilli', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI004'),
('GUNDU Chilli', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI005'),
('Kashmiri Chilli', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI006'),
('TEJA Chilli', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI007'),
('Coriander', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI008'),
('Pepper', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI009'),
('Cumin', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI010'),
('Fennel', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI011'),
('Large Mustard', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI012'),
('Fenugreek', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI013'),
('Garlic', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI014'),
('Dry Ginger', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI015'),
('Asafoetida', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI016'),
('Salt', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI017'),
('Cowpea', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI018'),
('Red Rice', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI019'),
('Green Peas', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI020'),
('Rajma', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI021'),
('Tamarind', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI022'),
('Coconut Flower', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI023'),
('Sapaattu Rice', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI024'),
('Idli Rice', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI025'),
('Raw Rice', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI026'),
('Small Mustard', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI027'),
('Rava', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI028'),
('Maida', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI029'),
('Wheat', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI030'),
('Country Sugar', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI031'),
('Pearl Millet', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI032'),
('Ragi', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI033'),
('Black Kavuni Rice', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI034'),
('Samba Wheat', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI035'),
('Maize', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI036'),
('White Soya', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI037'),
('Pottu Kadalai', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI038'),
('White Sorghum', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI039'),
('Green Gram', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI040'),
('Almond', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI041'),
('Barley', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI042'),
('Sago', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI043'),
('Corn Flour', 2, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKMI044'),

-- Aroma Masala Ingredients (Category 3)
('Cinnamon', 3, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKAMI01'),
('Cloves', 3, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKAMI02'),
('Cardamom', 3, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKAMI03'),
('Star Anise', 3, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKAMI04'),
('Nutmeg', 3, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKAMI05'),
('Mace', 3, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKAMI06'),
('Biryani Leaf', 3, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKAMI07'),
('Rotti Mookku', 3, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKAMI08'),
('Sea Moss', 3, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKAMI09'),
('Kasa Kasa', 3, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKAMI10'),

-- Flour Varieties (Category 4)
('SPL Sathu Maavu', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK058'),
('Kadalai Maavu', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK068'),
('Almond Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0AK'),
('Green Gram Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0AR'),
('Raw Rice Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0AC'),
('Wheat Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0AQ'),
('Idiyappam Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK078'),
('Maida Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0AF'),
('Bajji Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK071'),
('Adai Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK079'),
('Ragi Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0AS'),
('Sivappu Arisi Idiyappam Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0AU'),
('Rava Dosa Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK076'),
('Pearl Millet Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0AT'),
('Navadhanya Dosa Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK080'),
('Murukku Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK077'),
('Black Kavuni Rice Flour', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0AY'),
('Karasev Mix', 4, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK081'),

-- Dal Varieties (Category 5)
('Bengal Gram Dal', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV01'),
('Red Gram Dal', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV02'),
('Black Urad Dal', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV03'),
('Whole Urad Dal', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV04'),
('White Urad Dal', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV05'),
('Split Moong Dal', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV06'),
('Pottu Kadalai', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV07'),
('Bengal Gram', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV08'),
('Green Gram', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV09'),
('Black Sesame', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV11'),
('Black Chickpeas', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV12'),
('White Chickpeas', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV13'),
('Green Gram Dal', 5, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKDV10'),

-- Cashew Varieties (Category 6)
('Cashew 1/2', 6, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKCV01'),
('Cashew 1/4', 6, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKCV02'),
('Cashew 1/8 SPL', 6, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKCV03'),
('Cashew Kurunai', 6, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKCV04'),
('PK Cashew', 6, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKCV05'),
('SW', 6, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SKCV06'),

-- Dry Fruits (Category 7)
('Cashew', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF1'),
('Almond', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF2'),
('Pistachio', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF3'),
('Black Raisins', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF4'),
('Narthangai Raisins', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF5'),
('Fig', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF6'),
('Dates', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF7'),
('Walnut', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF8'),
('Salted Pistachio', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF9'),
('Papaya Seeds', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF10'),
('Pumpkin Seeds', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF11'),
('Sunflower Seeds', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK0DF12'),
('Dry Fruits Mixture', 7, 0.0, 0.0, 1000, 5, 0.0, 'g', 'SK088');

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
