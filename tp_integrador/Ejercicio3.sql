/* 
3. Liste los depósitos (locations) que tengan al menos 3 productos asociados en su
inventario, pero que al momento no tengan stock.
Resultado esperado:
código	nombre	depósito
------	--------------------
7		Finished Goods Storage
*/
USE TP_SQL_Adventure_2017C1;
GO
SELECT L.LocationID, L.Name
FROM Production.Location L JOIN Production.ProductInventory I
ON L.LocationID = I.LocationID 
WHERE I.Quantity = 0
GROUP BY L.LocationID,L.Name
HAVING COUNT(I.ProductID) >= 2