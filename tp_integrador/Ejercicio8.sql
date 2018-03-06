/*
8.Nuestro equipo de Ingeniería ha detectado que la tabla ProductListPriceHistory
contiene información redundante. El dato almacenado en la columna EndDate puede
ser inferido en función del StartDate del registro siguiente. Por tal motivo nos
solicitaron realizar una prueba de concepto para determinar si es posible eliminar esa
columna. Por consiguiente se solicita:
	a.Crear una nueva tabla, llamada ProductListPriceHistory_POC que contenga las
	mismas columnas (y tipo de datos) de la tabla ProductListPriceHistory, con
	excepción del campo EndDate, el cual no existirá en la nueva tabla
	b. Extraer los datos de ProductListPriceHistory y volcarlos en
	ProductListPriceHistory_POC, utilizando una única sentencia SQL
	c. Crear una Vista, llamada vProductListPriceHistory, que reconstruya el valor de
	EndDate, en función de los datos contenidos en ProductListPriceHistory_POC
	d. Verificar que el contenido de la vista coincide con los datos de la tabla original.
*/
USE TP_SQL_Adventure_2017C1 ;  
GO  

--a y b)  Con esto obtengo una copia de ProductListPriceHistory sin la columna endDate
IF OBJECT_ID ('Production.ProductListPriceHistory_POC', 'U') IS NOT NULL  
    DROP TABLE Production.ProductListPriceHistory_POC ;  
SELECT ProductID,StartDate,ListPrice,ModifiedDate 
INTO Production.ProductListPriceHistory_POC 
FROM Production.ProductListPriceHistory;

--c) uso AR
IF OBJECT_ID ('Production.vProductListPriceHistory', 'V') IS NOT NULL  
    DROP VIEW Production.vProductListPriceHistory ;  
GO 
CREATE VIEW Production.vProductListPriceHistory ASSELECT ProductID,StartDate,ListPrice,ModifiedDate,( 	SELECT TOP(1) (p2.StartDate-1)
	FROM Production.ProductListPriceHistory_POC p1, Production.ProductListPriceHistory_POC p2
	WHERE p.ProductID = p1.ProductID AND p1.ProductID = p2.ProductID AND p1.StartDate < p2.StartDate AND p2.StartDate > p.StartDate)as endDate_CalcFROM Production.ProductListPriceHistory_POC P;
GO
--d) 
IF ( ( SELECT 1 
		FROM (
		   		SELECT  COUNT(*) as Cantidad
				FROM Production.ProductListPriceHistory P 
			 ) cantPro	
		WHERE cantPro.Cantidad = (
				SELECT  COUNT(*)
				FROM Production.vProductListPriceHistory vP JOIN Production.ProductListPriceHistory P 
				ON p.ProductID = vp.ProductID AND p.StartDate = vp.StartDate and ( p.EndDate = vp.endDate_Calc OR (p.EndDate is null AND vp.endDate_Calc is null))
				)
	) = 1)
PRINT 'El contenido de la vista coincide con los datos de la tabla original.'
ELSE
PRINT 'Algo esta mal'

