CREATE DATABASE bicycle_shop;
GO
USE bicycle_shop;
GO

CREATE TABLE Customer(
    id_customer INT IDENTITY(1,1) PRIMARY KEY,
    Fname NVARCHAR(50) NOT NULL,
    Lname NVARCHAR(50) NOT NULL,
    email NVARCHAR(100) NOT NULL UNIQUE,
    pNumber NVARCHAR(20) NULL
);

CREATE TABLE Product(
    id_product INT IDENTITY(1,1) PRIMARY KEY,
    Pname NVARCHAR(150) NOT NULL,
    article NVARCHAR(50) NULL UNIQUE,
    Pprice DECIMAL(10,2) NOT NULL CHECK (Pprice >= 0),
    quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    Description NVARCHAR(1000) NULL
);

CREATE TABLE [Order](
    id_order INT IDENTITY(1,1) PRIMARY KEY,
    orderDate DATETIME2 DEFAULT SYSDATETIME(),
    orderStatus NVARCHAR(50) DEFAULT 'New',
    address NVARCHAR(200) NOT NULL,
    amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    id_customer INT NOT NULL REFERENCES Customer(id_customer)
);

CREATE TABLE Details(
    id_details INT IDENTITY(1,1) PRIMARY KEY,
    number INT NOT NULL CHECK (number > 0),
    price DECIMAL(10,2) NOT NULL,
    id_order INT NOT NULL REFERENCES [Order](id_order) ON DELETE CASCADE,
    id_product INT NOT NULL REFERENCES Product(id_product)
);
GO