USE bicycle_shop;
GO

CREATE TABLE dbo.SalesLogs
(
Id INT NOT NULL IDENTITY(1,1),
SalesId INT NOT NULL,
ModifyDate DATETIME NOT NULL
);
GO

CREATE OR ALTER TRIGGER tr_SalesLoging
ON dbo.Details
AFTER UPDATE
AS
BEGIN
INSERT dbo.SalesLogs(SalesId, ModifyDate)
SELECT id_details, GETDATE() FROM inserted;
END
GO

CREATE TABLE dbo.ProductInsertLogs
(
Id INT IDENTITY(1,1) PRIMARY KEY,
Pname NVARCHAR(150),
AttemptDate DATETIME NOT NULL DEFAULT GETDATE(),
UserName SYSNAME NOT NULL DEFAULT SUSER_SNAME()
);
GO

CREATE OR ALTER TRIGGER createOrdersTrigger
ON dbo.Product
INSTEAD OF INSERT
AS
BEGIN
IF ((DATEPART(DW, GETDATE()) = 7) OR (DATEPART(DW, GETDATE()) = 1))
BEGIN
INSERT dbo.ProductInsertLogs (Pname) SELECT Pname FROM inserted;
RAISERROR ('You cannot modify orders at Saturday or Sunday', 16, 1)
END
ELSE
INSERT INTO Product (Pname, article, Pprice, quantity)
SELECT Pname, article, Pprice, quantity FROM inserted;
END
GO

CREATE OR ALTER TRIGGER dbo.Details_AddChrckN
ON dbo.Details
AFTER INSERT
AS
BEGIN
DECLARE @prod INT, @ord INT;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
SELECT DISTINCT id_product, id_order FROM inserted;

OPEN c;
FETCH NEXT FROM c INTO @prod, @ord
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE Product
	SET Description = ISNULL(Description + N', ', N'Чек №') + CAST(@ord AS NVARCHAR(10))
	WHERE id_product = @prod;

	FETCH NEXT FROM c INTO @prod, @ord;
END

CLOSE c;
DEALLOCATE c;
END
GO