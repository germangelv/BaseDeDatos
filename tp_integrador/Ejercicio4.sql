/* 
4. Genere una función llamada f_getCost() que retorne el costo total de producción
que conllevó generar todos los elementos de dicho producto. Esta función debe recibir
como parámetro el id del producto y debe retornar un solo valor, tipo MONEY, que
realice el cálculo de lo que cuesta realizar un producto, según el promedio de su costo,
actual e histórico (ProductCostHistory) por la cantidad de productos que se tiene en stock
Ejemplo de Uso:
	SELECT production.f_getTotalCost(945);

Resultado esperado (según la ejecución anterior):
34650,2248
*/
USE TP_SQL_Adventure_2017C1;
GO
IF OBJECT_ID ('f_getTotalCost') IS NOT NULL  
	DROP FUNCTION Production.f_getTotalCost ;   -- en realidad si existe deberia no hacerlo
GO 
CREATE FUNCTION Production.f_getTotalCost(@ProductID int)
RETURNS MONEY
BEGIN
	DECLARE @resultado MONEY;
	SELECT @resultado  = (P.StandardCost+H.CostoHistorico)/2*I.Stock 
		FROM Production.Product P JOIN (
		SELECT PCH.ProductID, AVG(PCH.StandardCost) as CostoHistorico
		FROM Production.ProductCostHistory PCH 
		WHERE PCH.ProductID = @ProductID
		GROUP BY PCH.ProductID
		) H ON P.ProductID = H.ProductID JOIN (
			SELECT II.ProductID, SUM(II.Quantity) AS Stock
			FROM Production.ProductInventory II 
			WHERE II.ProductID = @ProductID
			GROUP BY II.ProductID
		) I
		ON H.ProductID = I.ProductID
	IF (@resultado IS NULL)   
		SET @resultado = 0;
	RETURN @resultado
END;

SELECT production.f_getTotalCost(945) AS Costo_Total;
