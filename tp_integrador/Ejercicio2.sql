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

					
					