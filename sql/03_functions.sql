USE bicycle_shop;
GO

CREATE OR ALTER FUNCTION dbo.ct_goods(@new_price DECIMAL(10, 2))
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM Product WHERE Pprice < @new_price);
END
GO

CREATE OR ALTER FUNCTION dbo.MostExpensiveSold(@SaleDate DATE)
RETURNS NVARCHAR(200)
AS
BEGIN
DECLARE @res NVARCHAR(200);

SELECT TOP 1 @res = p.Pname
FROM [Order] o
JOIN Details d ON d.id_order = o.id_order
JOIN Product p ON p.id_product = d.id_product
WHERE o.orderDate >= @SaleDate
	AND o.orderDate < DATEADD(DAY, 1, @SaleDate)
ORDER BY d.price DESC, p.Pname;

IF @res IS NULL
	SET @res = N'Товар не був реалізований у ' + CONVERT(NVARCHAR(10), @SaleDate, 104);

RETURN @res;
END
GO

CREATE OR ALTER FUNCTION dbo.SoldProductsByDate(@SaleDate DATE)
RETURNS TABLE
AS
RETURN (
SELECT
p.id_product, p.Pname,
SUM(d.number) AS qty,
MAX(d.price) AS price,
SUM(d.number * d.price) AS sum
FROM [Order] o
JOIN Details d ON d.id_order = o.id_order
JOIN Product p ON p.id_product = d.id_product
WHERE o.orderDate >= @SaleDate AND o.orderDate < DATEADD(DAY, 1, @SaleDate)
GROUP BY p.id_product, p.Pname
);

GO