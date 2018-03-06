/*
6. Reemplace el procedimiento del punto anterior, para que la operación se realice a
través de un TRIGGER sobre la tabla Product.
Construya también el Trigger, que debe funcionar ante modificaciones de cantidades
mediante el procedimiento almacenado o por modificación directa sobre la tabla.
*/
USE TP_SQL_Adventure_2017C1;
GO
CREATE TRIGGER Production.trigger_updateCost
ON Production.Product 
AFTER UPDATE
AS
IF UPDATE(StandardCost) 
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		--a)	
		UPDATE Production.ProductCostHistory 
		SET EndDate = GETDATE() 
		from deleted d
		where ProductCostHistory.ProductID = d.ProductID AND EndDate is NULL;
		IF @@ROWCOUNT = 0  --SI no se modifico nada, quiere decir que no se encontro el productID en el historial de costos
		BEGIN  
			INSERT INTO Production.ProductCostHistory
			(ProductID,StartDate,EndDate,StandardCost) 
			Select p.ProductID,p.ModifiedDate,getdate(),p.StandardCost 
			FROM Production.Product P JOIN deleted d 
			ON p.ProductID = d.ProductID;
		END
		--b)
		INSERT INTO Production.ProductCostHistory 
		(ProductID , StartDate, StandardCost) 
		select i.ProductID,getdate(),i.StandardCost
		from Inserted i;
		--c)
		UPDATE Production.Product
		SET StandardCost = i.StandardCost, ModifiedDate = getDate() 
		from inserted i 
		where Product.ProductID = i.ProductID
	END TRY
	BEGIN CATCH
		ROLLBACK
	END CATCH
	COMMIT
END;


/*
UPDATE Production.Product 
SET StandardCost = 4000
where ProductID = 3;

Select *
from Production.ProductCostHistory H
where ProductID = 3;

select productID, StandardCost, ModifiedDate
from Production.Product
where ProductID = 3;
*/