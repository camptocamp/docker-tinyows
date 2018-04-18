CREATE EXTENSION postgis;

CREATE TABLE polygons (
    name TEXT NOT NULL,
    value INT NOT NULL,
    PRIMARY KEY (name)
);
SELECT AddGeometryColumn('polygons', 'geom', 4326, 'POLYGON', 2);

INSERT INTO polygons (name, value, geom) VALUES ('foo', 1, ST_GeomFromText('POLYGON((-50 -50,50 -50,50 50,-50 -50))', 4326));
