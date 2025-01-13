-- Database: cw_5

-- DROP DATABASE IF EXISTS cw_5;

CREATE DATABASE cw_5
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1252'
    LC_CTYPE = 'Polish_Poland.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

CREATE EXTENSION postgis;

CREATE TABLE obiekt (
	nazwa VARCHAR,
	id INT, 
	geom GEOMETRY
);

-- Zad 1
--a

INSERT INTO obiekt VALUES (
	'obiekt1', 1, ST_GeomFromText('
		COMPOUNDCURVE(
			LINESTRING(0 1, 1 1), 
			CIRCULARSTRING(1 1, 2 0, 3 1), 
			CIRCULARSTRING(3 1, 4 2, 5 1), 
			LINESTRING(5 1, 6 1) 
		)'
	, 0)
);

SELECT geom FROM obiekt WHERE id = 1;

-- Zad 1
--b

INSERT INTO obiekt VALUES (
	'obiekt2', 2, ST_GeomFromText('
			GEOMETRYCOLLECTION(
				COMPOUNDCURVE(
					CIRCULARSTRING(11 2, 12 3, 13 2),
					CIRCULARSTRING(13 2, 12 1, 11 2)
				),
				COMPOUNDCURVE(
					LINESTRING(10 6, 14 6),
					CIRCULARSTRING(14 6, 16 4, 14 2),
					CIRCULARSTRING(14 2, 12 0, 10 2),
					LINESTRING(10 2, 10 6)
				)
			)'
	, 0)
);

SELECT geom FROM obiekt WHERE id = 2;

-- Zad 1
--c

INSERT INTO obiekt VALUES (
	'obiekt3', 3, ST_GeomFromText('
			COMPOUNDCURVE(
				LINESTRING(7 15, 10 17),
				LINESTRING(10 17, 12 13),
				LINESTRING(12 13, 7 15)
			)
	')
);

SELECT geom FROM obiekt WHERE id = 3;

-- Zad 1
--d

INSERT INTO obiekt VALUES (
	'obiekt4', 4, ST_GeomFromText('
		COMPOUNDCURVE(
			LINESTRING(20 20, 25 25),
			LINESTRING(25 25, 27 24),
			LINESTRING(27 24, 25 22),
			LINESTRING(25 22, 26 21),
			LINESTRING(26 21, 22 19),
			LINESTRING(22 19, 20.5 19.5)
		)
	')
);

SELECT geom FROM obiekt WHERE id = 4;

-- Zad 1
--e

INSERT INTO obiekt VALUES (
	'obiekt5', 5, ST_GeomFromText('
		GEOMETRYCOLLECTION(
			POINT Z(30 30 59),
			POINT Z(38 32 234)
		)
	')
);

SELECT geom FROM obiekt WHERE id = 5;

-- Zad 1
--f

INSERT INTO obiekt VALUES (
	'obiekt6', 6, ST_GeomFromText('
		GEOMETRYCOLLECTION(
			POINT(4 2),
			LINESTRING(1 1, 3 2)
		)
	')
);

SELECT geom FROM obiekt WHERE id = 6;

SELECT * FROM obiekt;

-- Zad 2

SELECT ST_Area(
	ST_Buffer(
		ST_ShortestLine(
			(SELECT geom FROM obiekt WHERE id = 3),
			(SELECT geom FROM obiekt WHERE id = 4)
		), 5
	)
);

-- Zad 3

UPDATE obiekt SET geom = ST_GeomFromText('
    POLYGON((
        20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5, 20 20
    ))
') WHERE id = 4;

SELECT geom FROM obiekt WHERE id = 4;

-- Zad 4

INSERT INTO obiekt VALUES (
	'obiekt7', 7, 
	ST_Union(
		(SELECT geom FROM obiekt WHERE id = 3),
		(SELECT geom FROM obiekt WHERE id = 4)
	)
);

SELECT geom FROM obiekt WHERE id = 7;

-- Zad 5

SELECT ST_Area(ST_Buffer(geom, 5)) 
FROM obiekt WHERE NOT ST_HasArc(geom);