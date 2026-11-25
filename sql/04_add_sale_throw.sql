USE bicycle_shop;
GO

CREATE OR ALTER PROCEDURE dbo.AddSale
    @ProductName NVARCHAR(150),
    @OrderId INT = NULL,
    @Quantity INT = 1,
    @CustomerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ProductId INT, @Price DECIMAL(10,2), @Stock INT, @Msg NVARCHAR(200);

    IF @Quantity IS NULL OR @Quantity <= 0
        THROW 50002, N'Кількість має бути додатною', 1;

    SELECT TOP 1 @ProductId = id_product, @Price = Pprice, @Stock = quantity
    FROM Product
    WHERE Pname LIKE N'%' + @ProductName + N'%'
    ORDER BY Pname;

    IF @ProductId IS NULL
    BEGIN
        SET @Msg = N'Товар «' + @ProductName + N'» не знайдено';
        THROW 50001, @Msg, 1;
    END

    IF @Stock < @Quantity
    BEGIN
        SET @Msg = N'Недостатньо товару на складі. Залишок: ' + CAST(@Stock AS NVARCHAR(10));
        THROW 50003, @Msg, 1;
    END

    IF @OrderId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM [Order] WHERE id_order = @OrderId)
    BEGIN
        SET @Msg = N'Чек №' + CAST(@OrderId AS NVARCHAR(10)) + N' не існує';
        THROW 50004, @Msg, 1;
    END

    IF @OrderId IS NULL
       AND (@CustomerId IS NULL
            OR NOT EXISTS (SELECT 1 FROM Customer WHERE id_customer = @CustomerId))
        THROW 50005, N'Для нового чека вкажіть існуючого клієнта', 1;

    BEGIN TRY
        BEGIN TRAN;

        IF @OrderId IS NULL
        BEGIN
            INSERT INTO [Order] (address, id_customer) VALUES (N'Самовивіз', @CustomerId);
            SET @OrderId = SCOPE_IDENTITY();
        END

        INSERT INTO Details (number, price, id_order, id_product)
        VALUES (@Quantity, @Price, @OrderId, @ProductId);

        UPDATE Product SET quantity -= @Quantity WHERE id_product = @ProductId;
        UPDATE [Order]  SET amount   += @Price * @Quantity WHERE id_order = @OrderId;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH

    SELECT @OrderId AS id_order, @ProductId AS id_product, @Quantity AS quantity;
END
GO