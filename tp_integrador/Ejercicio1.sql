/* 
1.Liste las categorías de productos (ProductCategory) con menos productos (Product)
que el promedio de productos que tienen las categorías ordene el resultado de menor
a mayor.
ProductCategoryID	Name			cantidad
-----------------	-----			---------
		5			Cars			0
		4			Accessories		29
		3			Clothing		35

*/
USE TP_SQL_Adventure_2017C1;
GO
IF OBJECT_ID ('Production.View_Cantidad_Productos_x_Categoria', 'V') IS NOT NULL  
	DROP VIEW Production.View_Cantidad_Productos_x_Categoria ;  
GO

CREATE VIEW Production.View_Cantidad_Productos_x_Categoria AS
SELECT pc.ProductCategoryID,COUNT(pc.ProductCategoryID) AS Cantidad
FROM Production.ProductCategory pc join Production.ProductSubcategory pcs
ON pcs.ProductCategoryID = pc.ProductCategoryID join Production.Product p 
ON p.ProductSubcategoryID = pcs.ProductSubcategoryID
GROUP BY pc.ProductCategoryID;
GO

IF OBJECT_ID ('Production.view_Promedio_Productos_x_Categoria', 'V') IS NOT NULL  
	DROP VIEW Production.view_Promedio_Productos_x_Categoria ;  
GO

CREATE VIEW Production.view_Promedio_Productos_x_Categoria AS
SELECT AVG(vCant.Cantidad) AS Promedio
FROM Production.view_Cantidad_Productos_x_Categoria vCant;
GO

SELECT pc.ProductCategoryID,pc.Name, IsNull(vCantt.Cantidad, 0) AS Cantidad
FROM Production.ProductCategory pc LEFT JOIN Production.view_Cantidad_Productos_x_Categoria vCantt 
ON pc.ProductCategoryID = vCantt.ProductCategoryID
WHERE pc.ProductCategoryID NOT IN
(
	SELECT vCant.ProductCategoryID
	FROM Production.view_Cantidad_Productos_x_Categoria vCant
	WHERE vCant.Cantidad >
	(
		SELECT AVG(vCant.Cantidad) AS Promedio
		FROM Production.view_Cantidad_Productos_x_Categoria vCant
	)
)
ORDER BY vCantt.Cantidad;