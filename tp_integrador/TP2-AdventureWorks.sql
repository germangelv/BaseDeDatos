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


/* 
 Liste los depósitos (locations) que cuenten con al menos 100 elementos de cada
producto, para de todas las subcategorias.
*/

USE TP_SQL_Adventure_2017C1;
GO
select PPI.LocationID as Codigo,PL.name as deposito, count(distinct PP.ProductSubcategoryID ) as SubCategorias
from Production.Location PL join Production.ProductInventory PPI on PL.LocationID=PPI.LocationID join Production.Product PP on  PPI.ProductID=PP.ProductID
group by PPI.LocationID,PL.Name
having count(distinct PP.ProductSubcategoryID )=(select count(distinct ProductSubcategoryID)
												from Production.Product 
												)
and not exists	(	select 1
					from Production.ProductInventory PPI2 join Production.Product PP2 on PPI2.ProductID=PP2.ProductID
					group by PPI2.LocationID, PP2.ProductSubcategoryID
					having PPI2.LocationID=PPI.LocationID AND sum(PPI2.Quantity)<100
				)

					
					
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

Nota?, si el producto no tiene información en la tabla de histórico, el paso "A" debe
reemplazarse por: insertar una fila en el histórico de costos con el valor que tiene el
producto en la tabla de productos, colocando como fecha desde la fecha de
modificación del producto (modifiedDate en tabla product) y la fecha hasta debe
completarse con la fecha del día.

Nota ?2: El procedimiento debe llamarse s_updateCost
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


/*
7. Para normalizar los colores de los productos, se desea crear una nueva tabla,
llamada Color?, que contengan cada uno de los distintos colores posibles de los
productos (tabla Product) y vincular ésta con la tabla Product, eliminando el campo
Color. Para eso se requiere:
	a. Crear una nueva tabla, llamada Production.Color?, con las siguientes
columnas: ColorID? (numérico), ColorName ?(texto)

	b. Llenar la tabla Colors, usando una única sentencia SQL, con los posibles
valores del campo Color de la tabla Product. 
Atención?: Los distintos colores disponibles pueden variar en los distintos 
ambientes (desarrollo, calidad,producción). Esta sentencia SQL debería ser 
válida para ejecutarse encualquiera de estos ambientes.

	c. Vincule mediante la tabla Product con la nueva tabla Colors, asegurándose de
que sea posible obtener el color de cada producto siguiendo ese vínculo
(integridad referencial).

	d. Elimine de la tabla Product el campo Color, asegurandose que no tuvo pérdida
de información.

--Solo se puede ejecutar una vez. 
*/
USE TP_SQL_Adventure_2017C1;
GO
IF OBJECT_ID ('Color', 'T') IS NOT NULL  
	DROP TABLE dbo.Color ;   -- en realidad si existe deberia no hacerlo
GO 
CREATE TABLE Color ( -- dbo.
	ColorID int IDENTITY(1,1) NOT NULL,
	ColorName char(255),
	PRIMARY KEY (ColorID)
);
INSERT INTO Color (ColorName)
SELECT distinct  p.Color
FROM Production.Product p
WHERE Color IS NOT NULL;

ALTER  TABLE Production.Product 
ADD ColorID int NULL FOREIGN KEY REFERENCES Color;

Update Production.Product
set ColorID = c.ColorID
from Production.Product p, Color c
where p.Color = c.ColorName;

ALTER  TABLE Production.Product 
DROP column  Color;

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
CREATE VIEW Production.vProductListPriceHistory AS
SELECT ProductID,StartDate,ListPrice,ModifiedDate,
( 
	SELECT TOP(1) (p2.StartDate-1)
	FROM Production.ProductListPriceHistory_POC p1, Production.ProductListPriceHistory_POC p2
	WHERE p.ProductID = p1.ProductID AND p1.ProductID = p2.ProductID AND p1.StartDate < p2.StartDate AND p2.StartDate > p.StartDate

)as endDate_Calc
FROM Production.ProductListPriceHistory_POC P;
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



