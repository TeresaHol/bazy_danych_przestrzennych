--2
CREATE DATABASE cw3;

--3
CREATE EXTENSION postgis;

--4
CREATE TABLE buildings (
	id INT,
	geometry GEOMETRY,
	name VARCHAR(255)
);

CREATE TABLE roads (
	id INT,
	geometry GEOMETRY,
	name VARCHAR(255)
);

CREATE TABLE poi (
	id INT,
	geometry GEOMETRY,
	name VARCHAR(255)
);

--5
INSERT INTO roads (id, name, geometry) VALUES 
(1, 'RoadX', 'LINESTRING(0 4.5, 12 4.5)'),
(2, 'RoadY', 'LINESTRING(7.5 10.5, 7.5 0)');

INSERT INTO buildings (id, name, geometry) VALUES 
(3, 'BuildingA', 'POLYGON((8 4, 10.5 4, 10.5 2.5, 8 1.5, 8 4))'),
(4, 'BuildingB', 'POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))'),
(5, 'BuildingC', 'POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))'),
(6, 'BuildingD', 'POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))'),
(7, 'BuildingF', 'POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))');

INSERT INTO poi (id, name, geometry) VALUES
(8, 'G', 'POINT(1 3.5)'),
(9, 'H', 'POINT(5.5 1.5)'),
(10, 'I', 'POINT(6.5 6)'),
(11, 'J', 'POINT(9.5 6)'),
(12, 'K', 'POINT(6 9.5)');

--6
--a
SELECT SUM(ST_Length(geometry)) FROM roads;
--b
SELECT geometry, ST_Area(geometry) AS pole, ST_perimeter(geometry) AS obwod 
FROM buildings
WHERE name = 'BuildingA';
--c
SELECT name, ST_Area(geometry) FROM buildings ORDER BY name ASC;
--d
SELECT 
	name, 
	ST_Perimeter(geometry) AS obwod 
FROM buildings ORDER BY ST_Area(geometry) DESC LIMIT 2;
--e
SELECT ST_Distance(
	(SELECT geometry FROM buildings WHERE name = 'BuildingC'),
	(SELECT geometry FROM poi WHERE name = 'K')
);
--f
SELECT ST_Area(
	ST_Difference(
		(SELECT geometry FROM buildings WHERE name = 'BuildingC'),
		ST_Buffer((SELECT geometry FROM buildings WHERE name = 'BuildingB'), 0.5)
	)
) AS area;
--g
SELECT name FROM buildings WHERE ST_Y(ST_Centroid(geometry)) > 4.5;
--h
INSERT INTO buildings (id, name, geometry) VALUES 
(13, 'poligonH', 'POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))');
SELECT ST_Area(
	ST_SymDifference(
		(SELECT geometry FROM buildings WHERE name = 'BuildingC'),
		(SELECT geometry FROM buildings WHERE name = 'poligonH')
	)
) AS nie_wspolne_pole;



