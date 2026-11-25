USE bicycle_shop;
GO

INSERT INTO Customer (Fname, Lname, email, pNumber) VALUES
(N'Іван', N'Петренко', 'ivan@mail.com', '0501112233'),
(N'Олена', N'Коваль', 'olena@mail.com', '0672223344'),
(N'Андрій', N'Бойко', 'andriy@mail.com', NULL);

INSERT INTO Product (Pname, article, Pprice, quantity) VALUES
(N'Trek Marlin 6', 'TRK-001', 25000, 5),
(N'Giant Talon 3', 'GNT-002', 24000, 8),
(N'Cannondale SuperSix', 'CND-003', 120000, 2),
(N'Scott Aspect', 'SCT-004', 27000, 3),
(N'Шолом Specialized Align', 'SPC-005', 2500, 18),
(N'Ліхтар Merida Front', 'MRD-006', 1000, 44);

INSERT INTO [Order] (orderDate, orderStatus, address, amount, id_customer) VALUES
('2026-11-01 10:15', 'Completed', N'Харків', 51000, 1),
('2026-11-01 14:40', 'Completed', N'Київ', 24000, 2),
('2026-11-02 11:05', 'Completed', N'Харків', 7500, 1),
('2026-11-03 09:30', 'Shipped', N'Львів', 120000, 3),
('2026-11-03 16:20', 'New', N'Київ', 2000, 2);

INSERT INTO Details (number, price, id_order, id_product) VALUES
(2, 25000, 1, 1), (1, 1000, 1, 6),
(1, 24000, 2, 2),
(3, 2500, 3, 5),
(1, 120000, 4, 3),
(2, 1000, 5, 6);
GO