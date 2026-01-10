USE AdventureWorks2019
GO

/* 1. Total Sales by time */

    -- Total sales by years
SELECT FORMAT(OrderDate, 'yyyy') as Year, ROUND(SUM(LineTotal), 0) as SalesAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
GROUP BY FORMAT(OrderDate, 'yyyy')
ORDER BY Year

    -- Total sales by months
SELECT FORMAT(OrderDate, 'yyyy-MM') as YearMonth, EOMONTH(OrderDate) AS EndDate, 
ROUND(SUM(LineTotal), 0) as SalesAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
GROUP BY FORMAT(OrderDate, 'yyyy-MM'), EOMONTH(OrderDate)
ORDER BY YearMonth, EndDate



/* 2. 'Bikes' sales by time series */

    -- 'Bikes' revenue over years
SELECT FORMAT(OrderDate, 'yyyy') as Year, c.ProductCategoryID, c.Name as ProductCategoryName, 
ROUND(SUM(LineTotal), 0) as SalesAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p on d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
WHERE c.Name = 'Bikes'
GROUP BY FORMAT(OrderDate, 'yyyy'), c.ProductCategoryID, c.Name
ORDER BY Year, c.ProductCategoryID

    -- 'Bikes' revenue over months
SELECT FORMAT(OrderDate, 'yyyy-MM') as YearMonth, EOMONTH(OrderDate) AS EndDate, c.ProductCategoryID, c.Name as ProductCategoryName, 
ROUND(SUM(LineTotal), 0) as SalesAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p on d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
WHERE c.Name = 'Bikes'
GROUP BY FORMAT(OrderDate, 'yyyy-MM'), EOMONTH(OrderDate), c.ProductCategoryID, c.Name
ORDER BY YearMonth, c.ProductCategoryID


/* 3. 'Bikes' versus over categories */

    -- All categories over years
SELECT FORMAT(OrderDate, 'yyyy') as Year, c.ProductCategoryID, c.Name as ProductCategoryName,
CONVERT(DECIMAL(18,0), SUM(LineTotal)) as SalesAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p on d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
GROUP BY FORMAT(OrderDate, 'yyyy'), c.ProductCategoryID, c.Name
ORDER BY Year, c.ProductCategoryID, c.Name
    -- 'Bikes' versus others
SELECT [Year], ProductCategoryID, ProductCategoryName, CONVERT(DECIMAL(18,0), SUM(LineTotal)) as SalesAmount
FROM
(SELECT FORMAT(OrderDate, 'yyyy') as Year,
    CASE WHEN c.Name='Bikes' THEN c.ProductCategoryID ELSE 0 END AS ProductCategoryID, 
    CASE WHEN c.Name='Bikes' THEN c.Name ELSE 'Others' END AS ProductCategoryName, 
    LineTotal
    FROM Sales.SalesOrderDetail d
    JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
    JOIN Production.Product p on d.ProductID = p.ProductID
    JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
    JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
) s
GROUP BY Year, ProductCategoryID, ProductCategoryName
ORDER BY Year, ProductCategoryID

    -- 'Bikes' distribution by years
;WITH s AS (
SELECT [Year], ProductCategoryID, ProductCategoryName, CONVERT(DECIMAL(18,0), SUM(LineTotal)) as SalesAmount
    FROM
    (SELECT FORMAT(OrderDate, 'yyyy') as Year,
        CASE WHEN c.Name='Bikes' THEN c.ProductCategoryID ELSE 0 END AS ProductCategoryID, 
        CASE WHEN c.Name='Bikes' THEN c.Name ELSE 'Others' END AS ProductCategoryName, 
        LineTotal
        FROM Sales.SalesOrderDetail d
        JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
        JOIN Production.Product p on d.ProductID = p.ProductID
        JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
        JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
    ) s
    GROUP BY Year, ProductCategoryID, ProductCategoryName
    -- ORDER BY Year, ProductCategoryID
), yearly AS (
SELECT [Year], 
    SUM(CASE WHEN ProductCategoryName='Bikes' THEN SalesAmount ELSE 0 END) AS Bikes,
    SUM(CASE WHEN ProductCategoryName='Others' THEN SalesAmount ELSE 0 END) AS Others,
    SUM(SalesAmount) AS [Total]
    FROM s
    GROUP BY [Year]
) 

SELECT [Year], Bikes - Others AS Difference, ROUND(Bikes / Others, 1) AS Ratio, 
ROUND(Bikes * 100 / Total, 2) AS BikesPercentOfTotal, ROUND(Others * 100 / Total, 2) AS OthersPercentOfTotal
FROM yearly
ORDER BY [YEAR]

    -- 'Bikes' distribution by months
;WITH s AS (
SELECT YearMonth, EndDate, ProductCategoryID, ProductCategoryName, CONVERT(DECIMAL(18,0), SUM(LineTotal)) as SalesAmount
    FROM
    (SELECT FORMAT(OrderDate, 'yyyy-MM') as YearMonth, EOMONTH(OrderDate) AS EndDate,
        CASE WHEN c.Name='Bikes' THEN c.ProductCategoryID ELSE 0 END AS ProductCategoryID, 
        CASE WHEN c.Name='Bikes' THEN c.Name ELSE 'Others' END AS ProductCategoryName, 
        LineTotal
        FROM Sales.SalesOrderDetail d
        JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
        JOIN Production.Product p on d.ProductID = p.ProductID
        JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
        JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
        WHERE YEAR(OrderDate) IN (2012, 2013)
    ) s
    GROUP BY YearMonth, EndDate, ProductCategoryID, ProductCategoryName
    --ORDER BY YearMonth, EndDate, ProductCategoryID
), monthly AS (
SELECT YearMonth, EndDate, 
    SUM(CASE WHEN ProductCategoryName='Bikes' THEN SalesAmount ELSE 0 END) AS Bikes,
    SUM(CASE WHEN ProductCategoryName='Others' THEN SalesAmount ELSE 0 END) AS Others,
    SUM(SalesAmount) AS [Total]
    FROM s
    GROUP BY YearMonth, EndDate
) 

SELECT YearMonth, EndDate, Bikes - Others AS Difference, ROUND(Bikes / Others, 1) AS Ratio, 
ROUND(Bikes * 100 / Total, 2) AS BikesPercentOfTotal, ROUND(Others * 100 / Total, 2) AS OthersPercentOfTotal
FROM monthly
ORDER BY YearMonth, EndDate


