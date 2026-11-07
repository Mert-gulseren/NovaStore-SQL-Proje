/* ================================================================
   NovaStore E-Ticaret Veri Yonetim Sistemi
   Hazirlayan: Mert Gulseren
   Platform: Microsoft SQL Server
   Calistirma: Bu dosyayi SSMS'te tek seferde calistirin.
   ================================================================ */

-- Bolum 1 - Veri tabanini olustur
IF DB_ID(N'NovaStoreDB') IS NULL
    CREATE DATABASE NovaStoreDB;
GO
USE NovaStoreDB;
GO

-- Bolum 1 - Ana tablolar: Categories ve Customers
IF OBJECT_ID(N'dbo.Categories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Categories (
        CategoryID   int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Categories PRIMARY KEY,
        CategoryName varchar(50) NOT NULL CONSTRAINT UQ_Categories_CategoryName UNIQUE
    );
END;
GO

IF OBJECT_ID(N'dbo.Customers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Customers (
        CustomerID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Customers PRIMARY KEY,
        FullName   varchar(50) NOT NULL,
        City       varchar(20) NOT NULL,
        Email      varchar(100) NOT NULL CONSTRAINT UQ_Customers_Email UNIQUE
    );
END;
GO

-- Bolum 1 - Categories tablosuna bagli urunler
IF OBJECT_ID(N'dbo.Products', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Products (
        ProductID   int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Products PRIMARY KEY,
        ProductName varchar(100) NOT NULL,
        Price       decimal(10,2) NOT NULL CONSTRAINT CK_Products_Price CHECK (Price >= 0),
        Stock       int NOT NULL CONSTRAINT DF_Products_Stock DEFAULT (0),
        CategoryID  int NOT NULL,
        CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID)
            REFERENCES dbo.Categories(CategoryID)
    );
END;
GO

-- Bolum 1 - Siparis ana tablosu
IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders (
        OrderID     int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
        CustomerID  int NOT NULL,
        OrderDate   datetime NOT NULL CONSTRAINT DF_Orders_OrderDate DEFAULT (GETDATE()),
        TotalAmount decimal(10,2) NOT NULL CONSTRAINT CK_Orders_TotalAmount CHECK (TotalAmount >= 0),
        CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID)
            REFERENCES dbo.Customers(CustomerID)
    );
END;
GO

-- Bolum 1 - Siparis ile urun arasindaki coktan-coka iliski
IF OBJECT_ID(N'dbo.OrderDetails', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderDetails (
        DetailID  int IDENTITY(1,1) NOT NULL CONSTRAINT PK_OrderDetails PRIMARY KEY,
        OrderID   int NOT NULL,
        ProductID int NOT NULL,
        Quantity  int NOT NULL CONSTRAINT CK_OrderDetails_Quantity CHECK (Quantity > 0),
        CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID)
            REFERENCES dbo.Orders(OrderID),
        CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID)
            REFERENCES dbo.Products(ProductID),
        CONSTRAINT UQ_OrderDetails_Order_Product UNIQUE (OrderID, ProductID)
    );
END;
GO

-- Bolum 2 - 5 kategori
INSERT INTO dbo.Categories (CategoryName)
SELECT v.CategoryName
FROM (VALUES ('Elektronik'), ('Giyim'), ('Kitap'), ('Kozmetik'), ('Ev ve Yasam')) v(CategoryName)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Categories c WHERE c.CategoryName = v.CategoryName);
GO

-- Bolum 2 - 12 urun, her kategoriye en az iki urun
INSERT INTO dbo.Products (ProductName, Price, Stock, CategoryID)
SELECT v.ProductName, v.Price, v.Stock, c.CategoryID
FROM (VALUES
    ('Akilli Telefon', 24999.00, 8,  'Elektronik'),
    ('Dizustu Bilgisayar', 45999.00, 5, 'Elektronik'),
    ('Kablosuz Fare', 899.00, 18, 'Elektronik'),
    ('Kulaklik', 2199.00, 12, 'Elektronik'),
    ('Pamuklu Tisort', 599.00, 25, 'Giyim'),
    ('Kislik Mont', 2499.00, 7, 'Giyim'),
    ('Roman', 349.00, 30, 'Kitap'),
    ('SQL Server Rehberi', 799.00, 9, 'Kitap'),
    ('Cilt Bakim Seti', 1299.00, 14, 'Kozmetik'),
    ('Parfum', 1899.00, 6, 'Kozmetik'),
    ('Filtre Kahve Makinesi', 3499.00, 4, 'Ev ve Yasam'),
    ('Masa Lambasi', 1199.00, 16, 'Ev ve Yasam')
) v(ProductName, Price, Stock, CategoryName)
JOIN dbo.Categories c ON c.CategoryName = v.CategoryName
WHERE NOT EXISTS (SELECT 1 FROM dbo.Products p WHERE p.ProductName = v.ProductName);
GO

-- Bolum 2 - 6 musteri
INSERT INTO dbo.Customers (FullName, City, Email)
SELECT v.FullName, v.City, v.Email
FROM (VALUES
    ('Ahmet Yilmaz', 'Ankara', 'ahmet.yilmaz@example.com'),
    ('Zeynep Kaya', 'Istanbul', 'zeynep.kaya@example.com'),
    ('Mehmet Demir', 'Izmir', 'mehmet.demir@example.com'),
    ('Elif Aydin', 'Bursa', 'elif.aydin@example.com'),
    ('Can Sahin', 'Ankara', 'can.sahin@example.com'),
    ('Ayse Celik', 'Antalya', 'ayse.celik@example.com')
) v(FullName, City, Email)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Customers c WHERE c.Email = v.Email);
GO

-- Bolum 2 - 10 siparis, farkli tarihlerde
INSERT INTO dbo.Orders (CustomerID, OrderDate, TotalAmount)
SELECT c.CustomerID, v.OrderDate, v.TotalAmount
FROM (VALUES
    ('ahmet.yilmaz@example.com',  CONVERT(datetime,'2026-10-12T10:15:00',126), 46898.00),
    ('zeynep.kaya@example.com',   CONVERT(datetime,'2026-10-20T14:30:00',126), 3697.00),
    ('mehmet.demir@example.com',  CONVERT(datetime,'2026-10-25T09:10:00',126), 1148.00),
    ('elif.aydin@example.com',    CONVERT(datetime,'2026-11-01T16:45:00',126), 3198.00),
    ('can.sahin@example.com',     CONVERT(datetime,'2026-10-31T11:20:00',126), 27198.00),
    ('ayse.celik@example.com',    CONVERT(datetime,'2026-10-30T13:00:00',126), 4698.00),
    ('ahmet.yilmaz@example.com',  CONVERT(datetime,'2026-11-03T17:25:00',126), 24999.00),
    ('zeynep.kaya@example.com',   CONVERT(datetime,'2026-11-04T12:05:00',126), 698.00),
    ('elif.aydin@example.com',    CONVERT(datetime,'2026-11-05T18:40:00',126), 1198.00),
    ('mehmet.demir@example.com',  CONVERT(datetime,'2026-11-06T08:55:00',126), 2199.00)
) v(Email, OrderDate, TotalAmount)
JOIN dbo.Customers c ON c.Email = v.Email
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Orders o
    WHERE o.CustomerID = c.CustomerID AND o.OrderDate = v.OrderDate
);
GO

-- Bolum 2 - Siparis detaylari; tutarlar Orders.TotalAmount ile uyumludur
INSERT INTO dbo.OrderDetails (OrderID, ProductID, Quantity)
SELECT o.OrderID, p.ProductID, v.Quantity
FROM (VALUES
    ('ahmet.yilmaz@example.com', '2026-10-12T10:15:00', 'Dizustu Bilgisayar', 1),
    ('ahmet.yilmaz@example.com', '2026-10-12T10:15:00', 'Kablosuz Fare', 1),
    ('zeynep.kaya@example.com', '2026-10-20T14:30:00', 'Kislik Mont', 1),
    ('zeynep.kaya@example.com', '2026-10-20T14:30:00', 'Pamuklu Tisort', 2),
    ('mehmet.demir@example.com', '2026-10-25T09:10:00', 'SQL Server Rehberi', 1),
    ('mehmet.demir@example.com', '2026-10-25T09:10:00', 'Roman', 1),
    ('elif.aydin@example.com', '2026-11-01T16:45:00', 'Cilt Bakim Seti', 1),
    ('elif.aydin@example.com', '2026-11-01T16:45:00', 'Parfum', 1),
    ('can.sahin@example.com', '2026-10-31T11:20:00', 'Akilli Telefon', 1),
    ('can.sahin@example.com', '2026-10-31T11:20:00', 'Kulaklik', 1),
    ('ayse.celik@example.com', '2026-10-30T13:00:00', 'Filtre Kahve Makinesi', 1),
    ('ayse.celik@example.com', '2026-10-30T13:00:00', 'Masa Lambasi', 1),
    ('ahmet.yilmaz@example.com', '2026-11-03T17:25:00', 'Akilli Telefon', 1),
    ('zeynep.kaya@example.com', '2026-11-04T12:05:00', 'Roman', 2),
    ('elif.aydin@example.com', '2026-11-05T18:40:00', 'Pamuklu Tisort', 2),
    ('mehmet.demir@example.com', '2026-11-06T08:55:00', 'Kulaklik', 1)
) v(Email, OrderDateText, ProductName, Quantity)
JOIN dbo.Customers c ON c.Email = v.Email
JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
    AND o.OrderDate = CONVERT(datetime, v.OrderDateText, 126)
JOIN dbo.Products p ON p.ProductName = v.ProductName
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.OrderDetails od
    WHERE od.OrderID = o.OrderID AND od.ProductID = p.ProductID
);
GO

-- Bolum 3.1 - Stoku 20'den az urunleri stok miktarina gore azalan sirala
SELECT ProductName AS UrunAdi, Stock AS StokMiktari
FROM dbo.Products
WHERE Stock < 20
ORDER BY Stock DESC;
GO

-- Bolum 3.2 - Musteri ve siparis bilgileri
SELECT c.FullName AS MusteriAdi, c.City AS Sehir,
       o.OrderDate AS SiparisTarihi, o.TotalAmount AS ToplamTutar
FROM dbo.Customers c
INNER JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
ORDER BY o.OrderDate;
GO

-- Bolum 3.3 - Ahmet Yilmaz'in aldigi urunler ve kategoriler
SELECT c.FullName AS MusteriAdi, p.ProductName AS UrunAdi,
       p.Price AS BirimFiyat, cat.CategoryName AS Kategori
FROM dbo.Customers c
INNER JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
INNER JOIN dbo.OrderDetails od ON od.OrderID = o.OrderID
INNER JOIN dbo.Products p ON p.ProductID = od.ProductID
INNER JOIN dbo.Categories cat ON cat.CategoryID = p.CategoryID
WHERE c.FullName = 'Ahmet Yilmaz'
ORDER BY o.OrderDate, p.ProductName;
GO

-- Bolum 3.4 - Kategorilere gore urun sayisi (urunsuz kategoriler de gorunur)
SELECT c.CategoryName AS Kategori, COUNT(p.ProductID) AS UrunSayisi
FROM dbo.Categories c
LEFT JOIN dbo.Products p ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY c.CategoryName;
GO

-- Bolum 3.5 - Musteri bazinda toplam ciro; siparisi olmayanlar da 0 ile listelenir
SELECT c.FullName AS MusteriAdi,
       COALESCE(SUM(o.TotalAmount), 0.00) AS ToplamCiro
FROM dbo.Customers c
LEFT JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FullName
ORDER BY ToplamCiro DESC, c.FullName;
GO

-- Bolum 3.6 - Her siparisin bugune gore kac gun once verildigi
SELECT o.OrderID, o.OrderDate AS SiparisTarihi,
       DATEDIFF(DAY, o.OrderDate, GETDATE()) AS GecenGun
FROM dbo.Orders o
ORDER BY o.OrderDate;
GO

-- Bolum 4.1 - Siparis ozet gorunumu
CREATE OR ALTER VIEW dbo.vw_SiparisOzet
AS
    SELECT c.FullName AS MusteriAdi, o.OrderDate AS SiparisTarihi,
           p.ProductName AS UrunAdi, od.Quantity AS Adet
    FROM dbo.Customers c
    INNER JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
    INNER JOIN dbo.OrderDetails od ON od.OrderID = o.OrderID
    INNER JOIN dbo.Products p ON p.ProductID = od.ProductID;
GO

-- View'i goruntulemek icin:
SELECT * FROM dbo.vw_SiparisOzet ORDER BY SiparisTarihi, MusteriAdi;
GO

-- Bolum 4.2 - Yedekleme
-- Once C:\Yedek klasorunu olusturun ve SQL Server servis hesabina yazma izni verin.
-- Ardindan asagidaki komutun yorum isaretlerini kaldirip calistirin:
-- BACKUP DATABASE NovaStoreDB
-- TO DISK = N'C:\Yedek\NovaStoreDB.bak'
-- WITH INIT, NAME = N'NovaStoreDB Full Backup';
GO
