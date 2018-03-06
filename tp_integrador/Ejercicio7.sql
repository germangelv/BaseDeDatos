/*
7. Para normalizar los colores de los productos, se desea crear una nueva tabla,
llamada Color​, que contengan cada uno de los distintos colores posibles de los
productos (tabla Product) y vincular ésta con la tabla Product, eliminando el campo
Color. Para eso se requiere:
	a. Crear una nueva tabla, llamada Production.Color​, con las siguientes
columnas: ColorID​ (numérico), ColorName ​(texto)

	b. Llenar la tabla Colors, usando una única sentencia SQL, con los posibles
valores del campo Color de la tabla Product. 
Atención​: Los distintos colores disponibles pueden variar en los distintos 
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

