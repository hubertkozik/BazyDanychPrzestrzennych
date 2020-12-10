-- W CMD
-- raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\Hubert\Desktop\AGH\5sem\bdp\cw5\rasters\srtm_1arc_v3.tif rasters.dem > C:\Users\Hubert\Desktop\AGH\5sem\bdp\cw5\rasters\dem.sql

create extension postgis_raster;

-- W CMD
-- raster2pgsql -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\Hubert\Desktop\AGH\5sem\bdp\cw5\rasters\srtm_1arc_v3.tif rasters.dem | psql -d cw5_hk -h localhost -U postgres -p 5432 
-- raster2pgsql -s 3763 -N -32767 -t 128x128 -I -C -M -d C:\Users\Hubert\Desktop\AGH\5sem\bdp\cw5\rasters\Landsat8_L1TP_RGBN.TIF rasters.landsat8 | psql -d cw5_hk -h localhost -U postgres -p 5432

--zad1
CREATE TABLE kozik.intersects AS SELECT a.rast, b.municipality FROM rasters.dem AS a, vectors.porto_parishes AS b WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

alter table kozik.intersects
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON kozik.intersects USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kozik'::name, 'intersects'::name,'rast'::name);

--zad2
CREATE TABLE kozik.clip AS SELECT ST_Clip(a.rast, b.geom, true), b.municipality FROM rasters.dem AS a, vectors.porto_parishes AS b WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

--zad3
CREATE TABLE kozik.union AS SELECT ST_Union(ST_Clip(a.rast, b.geom, true)) FROM rasters.dem AS a, vectors.porto_parishes AS b WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

--zad4
CREATE TABLE kozik.porto_parishes AS WITH r AS ( SELECT rast FROM rasters.dem LIMIT 1 )
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast FROM vectors.porto_parishes AS a, r WHERE a.municipality ilike 'porto';

--zad5
DROP TABLE kozik.porto_parishes;
CREATE TABLE kozik.porto_parishes AS
WITH r AS ( SELECT rast FROM rasters.dem LIMIT 1 )
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast FROM vectors.porto_parishes AS a, r WHERE a.municipality ilike 'porto';

--zad6
DROP TABLE kozik.porto_parishes;
CREATE TABLE kozik.porto_parishes AS
WITH r AS ( SELECT rast FROM rasters.dem LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast FROM vectors.porto_parishes AS a, r WHERE a.municipality ilike 'porto';

--zad7
CREATE TABLE kozik.intersection as
SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val FROM rasters.landsat8 AS a, vectors.porto_parishes AS b WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--zad8
CREATE TABLE kozik.dumppolygons AS
SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val FROM rasters.landsat8 AS a, vectors.porto_parishes AS b  WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--zad9
CREATE TABLE kozik.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast FROM rasters.landsat8;

--zad10
CREATE TABLE kozik.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast FROM rasters.dem AS a, vectors.porto_parishes AS b WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--zad11
CREATE TABLE kozik.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast FROM kozik.paranhos_dem AS a;

--zad12
CREATE TABLE kozik.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3', '32BF',0) FROM kozik.paranhos_slope AS a;

--zad13
SELECT st_summarystats(a.rast) AS stats FROM kozik.paranhos_dem AS a;

--zad14
SELECT st_summarystats(ST_Union(a.rast)) FROM kozik.paranhos_dem AS a;

--zad15
WITH t AS ( SELECT st_summarystats(ST_Union(a.rast)) AS stats FROM kozik.paranhos_dem AS a )
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--zad16
WITH t AS ( SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast, b.geom,true))) AS stats FROM rasters.dem AS a, vectors.porto_parishes AS b WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast) group by b.parish )
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--zad17
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom) FROM rasters.dem a, vectors.places AS b WHERE ST_Intersects(a.rast,b.geom) ORDER BY b.name;

--zad18
CREATE TABLE kozik.tpi30 as SELECT ST_TPI(a.rast,1) AS rast FROM rasters.dem a;

--zad19
CREATE INDEX idx_tpi30_rast_gist ON kozik.tpi30 USING gist (ST_ConvexHull(rast));

--zad20
SELECT AddRasterConstraints('kozik'::name, 'tpi30'::name,'rast'::name);

--zad21 PROBLEM DO SAMODZIELNEGO ROZWIAZANIA
CREATE TABLE kozik.tpi30_portoonly as SELECT ST_TPI(a.rast,1) as rast FROM rasters.dem a, vectors.porto_parishes AS b WHERE  ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

CREATE INDEX idx_tpi30_portoonly_rast_gist ON kozik.tpi30_portoonly USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kozik'::name, 'tpi30_portoonly'::name,'rast'::name);

--zad22
CREATE TABLE kozik.porto_ndvi AS WITH r AS ( SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast FROM rasters.landsat8 AS a, vectors.porto_parishes AS b WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast) )
SELECT r.rid,ST_MapAlgebra( r.rast, 1, r.rast, 4, '([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF' ) AS rast FROM r;

--zad23
CREATE INDEX idx_porto_ndvi_rast_gist ON kozik.porto_ndvi USING gist (ST_ConvexHull(rast));

--zad24
SELECT AddRasterConstraints('kozik'::name, 'porto_ndvi'::name,'rast'::name);

--zad25
create or replace function kozik.ndvi( value double precision [] [] [], pos integer [][], VARIADIC userargs text [] )
RETURNS double precision AS $$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
	RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value [1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

--zad26
CREATE TABLE kozik.porto_ndvi2 AS
WITH r AS ( SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast FROM rasters.landsat8 AS a, vectors.porto_parishes AS b WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast) )
SELECT r.rid,ST_MapAlgebra( r.rast, ARRAY[1,4], 'kozik.ndvi(double precision[], integer[],text[])'::regprocedure, '32BF'::text ) AS rast FROM r;

--zad27
CREATE INDEX idx_porto_ndvi2_rast_gist ON kozik.porto_ndvi2 USING gist (ST_ConvexHull(rast));

--zad28
SELECT AddRasterConstraints('kozik'::name, 'porto_ndvi2'::name,'rast'::name);

--zad29
SELECT ST_AsTiff(ST_Union(rast)) FROM kozik.porto_ndvi;

--zad30
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9']) FROM kozik.porto_ndvi;

--zad31
CREATE TABLE tmp_out AS SELECT lo_from_bytea(0, ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9']) ) AS loid FROM kozik.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'C:\Users\Hubert\Desktop\AGH\5sem\bdp\cw5\myraster.tif')
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out;

--zad32
gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 PG:"host=localhost port=5432 dbname=cw5_hk user=postgres password=zaq1 schema=kozik table=porto_ndvi mode=2" porto_ndvi.tiff

--zad33
MAP
	NAME 'map'
	SIZE 800 650
	STATUS ON
	EXTENT -58968 145487 30916 206234
	UNITS METERS
	WEB
		METADATA
		'wms_title' 'Terrain wms'
		'wms_srs' 'EPSG:3763 EPSG:4326 EPSG:3857'
		'wms_enable_request' '*'
		'wms_onlineresource' 'http://54.37.13.53/mapservices/srtm'
		END
	END
	PROJECTION 
		'init=epsg:3763'
	END
	LAYER
		NAME srtm
		TYPE raster
		STATUS OFF
		DATA "PG:host=localhost port=5432 dbname='cw5_hk' user='postgres' password='zaq1' schema='rasters' table='dem' mode='2'"
		PROCESSING "SCALE=AUTO"
		PROCESSING "NODATA=-32767"
		OFFSITE 0 0 0
		METADATA
			'wms_title' 'srtm'
		END
	END
END



