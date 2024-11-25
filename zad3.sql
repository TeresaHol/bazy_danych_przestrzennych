--1
CREATE VIEW buildings_diff AS 
SELECT ST_Difference(tkb2018.geom, tkb2019.geom) AS diff
FROM t2018_kar_buildings tkb2018 
INNER JOIN t2019_kar_buildings tkb2019 
ON tkb2018.polygon_id = tkb2019.polygon_id
WHERE NOT ST_IsEmpty(ST_Difference(tkb2018.geom, tkb2019.geom));

CREATE INDEX ON buildings_diff USING GIST (diff);

--2
CREATE VIEW ptd AS
SELECT ST_Difference(tkpt2018.geom, tkpt2019.geom) AS diff, tkpt2019.type AS type
FROM t2018_kar_poi_table tkpt2018
INNER JOIN t2019_kar_poi_table tkpt2019
ON tkpt2018.poi_id  = tkpt2019.poi_id
WHERE NOT ST_IsEmpty(ST_Difference(tkpt2018.geom, tkpt2019.geom));

CREATE INDEX ON ptd USING GIST (diff);

SELECT ptd.type, COUNT(ptd.type) AS type_count 
FROM buildings_diff bd
JOIN ptd 
ON ST_DWithin(bd.diff, ptd.diff, 500)
GROUP BY ptd.type;

--3
CREATE TABLE streets_reprojected AS 
SELECT gid AS id, ST_Transform(ST_SetSRID(geom, 4326), 3068) AS geom
FROM t2019_kar_streets;

--4,5
CREATE TABLE input_points (id integer, geom geometry);

INSERT INTO input_points (id, geom)
VALUES 
(1, ST_Transform(ST_SetSRID(ST_MakePoint(8.36093, 49.03174), 4326), 3068)),
(2, ST_Transform(ST_SetSRID(ST_MakePoint(8.39876, 49.00644), 4326), 3068));

--6
WITH input_line AS (
  SELECT ST_MakeLine(geom ORDER BY id) AS line_geom
  FROM input_points
)
SELECT DISTINCT tksn.geom 
FROM t2019_kar_street_node tksn, input_line il
WHERE ST_DWithin(il.line_geom, tksn.geom, 200);

--7
CREATE INDEX ON t2019_kar_land_use_a USING GIST (geom);
CREATE INDEX ON t2018_kar_poi_table USING GIST (geom);

SELECT COUNT(poi.geom) AS poi_count 
FROM t2018_kar_poi_table poi 
JOIN t2019_kar_land_use_a land 
ON ST_DWithin(land.geom, poi.geom, 300)
WHERE poi.type = 'Sporting Goods Store';

--8
CREATE INDEX ON t2019_kar_water_lines USING GIST (geom);
CREATE INDEX ON t2019_kar_railways USING GIST (geom);

CREATE TABLE T2019_KAR_BRIDGES AS 
SELECT ST_Intersection(a.geom, b.geom) AS geom
FROM t2019_kar_water_lines a
JOIN t2019_kar_railways b
ON ST_Intersects(a.geom, b.geom);
