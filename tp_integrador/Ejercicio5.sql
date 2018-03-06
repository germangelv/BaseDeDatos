/*
5. se requiere generar un procedimiento almacenado que permita actualizar el costo
de producción de un producto. El procedimiento debe recibir 2 parámetros. El id del
producto y el nuevo costo de producción. El proceso debe realizar lo siguiente.
	a) actualizar el registro que indica el costo actual en la tabla de históricos
(ProductCostHistory)
	b) insertar una nueva fila en la tabla de costos históricos con el nuevo valor ingresado
por parámetro, tomando la fecha de la ejecución como fecha de inicio de dicho costo
(columna StartDate)
	c) actualizar la tabla producto con el nuevo costo actual.

Nota​, si el producto no tiene información en la tabla de histórico, el paso "A" debe
reemplazarse por: insertar una fila en el histórico de costos con el valor que tiene el
producto en la tabla de productos, colocando como fecha desde la fecha de
modificación del producto (modifiedDate en tabla product) y la fecha hasta debe
completarse con la fecha del día.

Nota ​2: El procedimiento debe llamarse s_updateCost
Es obligatorio el uso de una transacción que englobe la modificación de ambas tablas,
y la utilización de una cláusula Try-Catch para en caso de error realizar ROLLBACK de
la operación y así evitar datos corruptos.
*/

USE TP_SQL_Adventure_2017C1;
GO
IF OBJECT_ID ('Production.s_updateCost', 'P') IS NOT NULL  
    DROP PROCEDURE Production.s_updateCost ;   
GO
CREATE PROCEDURE  Production.s_updateCost   
    @ProductID INT,   
    @StandardCost MONEY   
AS
BEGIN TRANSACTION
BEGIN TRY
	--a)	
	UPDATE Production.ProductCostHistory 
	SET EndDate = GETDATE() 
	where ProductID = @ProductID AND EndDate is NULL;
	IF @@ROWCOUNT = 0  --SI no se modifico nada, quiere decir que no se encontro el productID en el historial de costos
	BEGIN
		INSERT INTO Production.ProductCostHistory
		(ProductID,StartDate,EndDate,StandardCost) 
		Select ProductID,ModifiedDate,getdate(),StandardCost 
		FROM Production.Product
		Where ProductID = @ProductID;
	END 
	--b)
	INSERT INTO Production.ProductCostHistory 
	(ProductID , StartDate, StandardCost) VALUES
	(@ProductID, getDate(),@StandardCost);

	--c)
	UPDATE Production.Product
	SET StandardCost = @StandardCost, ModifiedDate = getDate() --esto no lo dice el enunciado pero supongo que si modifico el producto tengo que actualizar este campo.
	where ProductID = @ProductID
END TRY
BEGIN CATCH
	ROLLBACK
END CATCH
COMMIT
GO

/*
EXECUTE Production.s_updateCost 2,2000;
--EL Producto 2 no tiene historico,al ejectuar el procedimiento 
--guardo en la tabla de historico el valor anterior con fecha de cierre de hoy
--y tambien guardo el nuevo costo sin fecha de cierr
--obviamente se actualiza el precio en la tabla product de 0 a 2000

Select *
from Production.ProductCostHistory H
where ProductID = 2

select productID, StandardCost, ModifiedDate
from Production.Product
where ProductID = 2;
*/