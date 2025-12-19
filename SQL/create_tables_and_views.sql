-- Create PostGIS extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Uncomment to set timezone
-- ALTER DATABASE [your_database_name] SET TIMEZONE TO 'Europe/Berlin';
-- SET TIMEZONE TO 'Europe/Berlin';

------------------------------- CREATE TABLES ---------------------------------
CREATE TABLE bu(
    bu_name text PRIMARY KEY,
    bu_short text,
    bu_lead text,

    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user
);

CREATE TABLE wea(
    wea_id serial PRIMARY KEY,
    bu_name text REFERENCES bu(bu_name) ON UPDATE CASCADE,
    
    model text,
    capacity text,
    ground_elev double precision,
    hub_ht double precision,
    rot_dia double precision,
    total_ht double precision,
    wea_nr text,
    fun_dia double precision,
    con_rad double precision,
    rot_wind double precision,
    status_wea text,
    nxw_share text,

    -- Coordinates
    latitude_dd double precision,
    longitude_dd double precision,
    latitude_dms text,
    longitude_dms text,
    utm_zone text,
    utm_easting double precision,
    utm_northing double precision,

    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,

    geom geometry(Point, 4326) NOT NULL
);

CREATE TABLE wea_planned (
    wea_id int PRIMARY KEY REFERENCES wea(wea_id) ON UPDATE CASCADE,
    scenario text,
    phase text,
    planned_cod date,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user
);

CREATE TABLE wea_existing (
    --no attribute definition done yet
    wea_id int PRIMARY KEY REFERENCES wea(wea_id) ON UPDATE CASCADE,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user
);

CREATE TABLE crane_site (
    cranesite_id serial PRIMARY KEY,
    wea_id int REFERENCES wea(wea_id) ON UPDATE CASCADE,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE access_road (
    accessroad_id serial PRIMARY KEY,
    bu_name text REFERENCES bu(bu_name) ON UPDATE CASCADE,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE over_swing_area (
    overswing_id serial PRIMARY KEY,
    accessroad_id int REFERENCES access_road(accessroad_id) ON UPDATE CASCADE,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE pool_area (
    poolarea_id serial PRIMARY KEY,
    bu_name text REFERENCES bu(bu_name) ON UPDATE CASCADE,
    poolarea_name text,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE pv_area (
    pvarea_id serial PRIMARY KEY,
    bu_name text REFERENCES bu(bu_name) ON UPDATE CASCADE,
    pvarea_name text,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE bess (
    bess_id serial PRIMARY KEY,
    bu_name text REFERENCES bu(bu_name) ON UPDATE CASCADE,
    bess_name text,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE cable_route (
    cable_id serial PRIMARY KEY,
    bu_name text REFERENCES bu(bu_name) ON UPDATE CASCADE,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    length_geom double precision,
    geom geometry(MultiLineString, 4326) NOT NULL
);

CREATE TABLE cable_route_planned (
    --no attribute definition done yet
    cable_id int PRIMARY KEY REFERENCES cable_route(cable_id) ON UPDATE CASCADE,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user
);

CREATE TABLE cable_route_existing (
    --no attribute definition done yet
    cable_id int PRIMARY KEY REFERENCES cable_route(cable_id) ON UPDATE CASCADE,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user
);

CREATE TABLE substation (
    substation_id serial PRIMARY KEY,
    bu_name text REFERENCES bu(bu_name) ON UPDATE CASCADE,
    substation_name text,
    power double precision,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE potential_area (
    potential_id serial PRIMARY KEY,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE land_owner (
    owner_id serial PRIMARY KEY,
    gender text,
    acc_title text,
    firstname text,
    secondname text,
    birthdate date,
    pcode text,
    town text,
    street text,
    houseno text,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user
);

CREATE TABLE bundesland (
    bl_name text PRIMARY KEY,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE landkreis (
    lk_name text PRIMARY KEY,
    bl_name text REFERENCES bundesland(bl_name) ON UPDATE CASCADE,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE gemeinde (
    gem_name text PRIMARY KEY,
    lk_name text REFERENCES landkreis(lk_name) ON UPDATE CASCADE,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE gemarkung (
    gemkg_id serial PRIMARY KEY,
    gem_name text REFERENCES gemeinde(gem_name) ON UPDATE CASCADE,
    gemkg_name text,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE flur (
    flur_id serial PRIMARY KEY,
    gemkg_id int REFERENCES gemarkung(gemkg_id) ON UPDATE CASCADE,
    flur_nr int,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE parcel (
    parcel_id serial PRIMARY KEY,
    bu_name text REFERENCES bu(bu_name) ON UPDATE CASCADE,
    flur_id int REFERENCES flur(flur_id) ON UPDATE CASCADE,
    kennz text,
    nenner int,
    zaehler int,
    parcel_nr text,
    grundbuchnr text,
    grundbuchpg text,
    buchflaeche text,
    securement text,
    contracttype text,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE planning_region (
    plr_name text PRIMARY KEY,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE vrg (
    vrg_id serial PRIMARY KEY,
    plr_name text REFERENCES planning_region(plr_name) ON UPDATE CASCADE,
    vrg_name text,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE fnp (
    fnp_id serial PRIMARY KEY,
    gem_name text REFERENCES gemeinde(gem_name) ON UPDATE CASCADE,
    fnp_name text,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE bplan (
    bplan serial PRIMARY KEY,
    gem_name text REFERENCES gemeinde(gem_name) ON UPDATE CASCADE,
    bplan_name text,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE pipe_conduit (
    pipe_id serial PRIMARY KEY,
    pipe_name text,
    pipe_type text,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    length_geom double precision,
    geom geometry(MultiLineString, 4326) NOT NULL
);

CREATE TABLE wea_extern (
    --no attribute definition done yet
    wea_extern_id serial PRIMARY KEY,
    -- Coordinates
    latitude_dd double precision,
    longitude_dd double precision,
    latitude_dms text,
    longitude_dms text,
    utm_zone text, 
    utm_easting double precision,
    utm_northing double precision,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    geom geometry(Point, 4326) NOT NULL
);

CREATE TABLE building (
    building_id serial PRIMARY KEY,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE forest (
    forest_id serial PRIMARY KEY,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE protected_area (
    protected_id serial PRIMARY KEY,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE heightrestriction_area (
    hres_id serial PRIMARY KEY,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE waterbody (
    waterbody_id serial PRIMARY KEY,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    area_geom double precision,
    geom geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE street (
    street_id serial PRIMARY KEY,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    length_geom double precision,
    geom geometry(MultiLineString, 4326) NOT NULL
);

CREATE TABLE railway (
    railway_id serial PRIMARY KEY,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    length_geom double precision,
    geom geometry(MultiLineString, 4326) NOT NULL
);

CREATE TABLE parcel_owner (
    parcel_id int REFERENCES parcel(parcel_id) ON DELETE CASCADE ON UPDATE CASCADE,
    owner_id int REFERENCES land_owner(owner_id) ON DELETE CASCADE ON UPDATE CASCADE,
    -- Metadata
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by text DEFAULT current_user,
    updated_by text DEFAULT current_user,
    PRIMARY KEY (parcel_id, owner_id)
);

-------------------------------- CREATE VIEWS ---------------------------------

CREATE SCHEMA gis_views

CREATE OR REPLACE VIEW gis_views.parcels_with_ownernames AS
SELECT
    p.geom,
    p.parcel_id,
    p.bu_name,
    p.kennz,
    STRING_AGG(
        TRIM(
            COALESCE(o.secondname, '') || ' ' || COALESCE(o.firstname, '')
        ),
        ', ' ORDER BY o.firstname, o.secondname
    ) AS owners
FROM parcel p
LEFT JOIN parcel_owner po ON po.parcel_id = p.parcel_id
LEFT JOIN land_owner o ON o.owner_id = po.owner_id
GROUP BY p.parcel_id, p.bu_name, p.kennz
ORDER BY p.parcel_id;


CREATE OR REPLACE VIEW gis_views.bundeswehr_approval AS
SELECT
  w.wea_id,
  w.bu_name                    AS "Name des Windparks",
  w.wea_nr                     AS "WEA-Bezeichnung",
  w.model                      AS "WEA-Typ",
  w.hub_ht                     AS "NH in m",
  w.rot_dia                    AS "RD in m",

  (substring(w.latitude_dms FROM $$([0-9]+)°$$))::INT 
    AS "Nord Grad",
  (substring(w.latitude_dms FROM $$([0-9]+)min$$))::INT
    AS "Nord Minute",
  (substring(w.latitude_dms FROM $$([0-9]+(?:\.[0-9]+)?)sek$$))::NUMERIC
    AS "Nord Sekunde",
  (substring(w.longitude_dms FROM $$([0-9]+)°$$))::INT
    AS "Ost Grad",
  (substring(w.longitude_dms FROM $$([0-9]+)min$$))::INT
    AS "Ost Minute",
  (substring(w.longitude_dms FROM $$([0-9]+(?:\.[0-9]+)?)sek$$))::NUMERIC
    AS "Ost Sekunde",

  w.capacity                   AS "Anlagennennleistung in KW",
  w.total_ht                   AS "Anlagenhöhe über Grund in m",
  w.ground_elev                AS "Geländehöhe m NHN im Bezugssystem",
  (COALESCE(w.total_ht,0) + COALESCE(w.ground_elev,0))
    AS "Gesamt-höhe mNHN",
  gm.gem_name                  AS "Gemarkung",
  fl.flur_nr                   AS "Flur",
  pa.parcel_nr                 AS "Flurstück",
  w.geom::geometry(Point,4326) AS geom

FROM  public.wea   w
LEFT JOIN LATERAL (
  SELECT g.gem_name
  FROM public.gemarkung g
  WHERE ST_Contains(ST_Transform(g.geom,4326), w.geom)
  LIMIT 1
) gm ON true
LEFT JOIN LATERAL (
  SELECT f.flur_nr
  FROM public.flur f
  WHERE ST_Contains(ST_Transform(f.geom,4326), w.geom)
  LIMIT 1
) fl ON true
LEFT JOIN LATERAL (
  SELECT p.parcel_nr
  FROM public.parcel p
  WHERE ST_Contains(ST_Transform(p.geom,4326), w.geom)
  LIMIT 1
) pa ON true;