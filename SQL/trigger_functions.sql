---------------------- Helper functions ---------------------------

-- DD -> Geom
CREATE OR REPLACE FUNCTION make_geom_from_dd(lat double precision, lon double precision)
RETURNS geometry AS $$
BEGIN
  RETURN ST_SetSRID(ST_MakePoint(lon, lat), 4326);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Geom -> DD
CREATE OR REPLACE FUNCTION get_dd_from_geom(g geometry)
RETURNS TABLE(lat double precision, lon double precision) AS $$
BEGIN
  RETURN QUERY SELECT ST_Y(g), ST_X(g);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- DD -> DMS 
CREATE OR REPLACE FUNCTION to_dms_dd(val double precision, is_lat boolean)
RETURNS text AS $$
DECLARE
    deg integer;
    min integer;
    sec numeric;
    hemi text;
BEGIN
    -- Determine Hemisphere
    IF is_lat THEN
        IF val < 0 THEN
            hemi := 'S';
        ELSE
            hemi := 'N';
        END IF;
    ELSE
        IF val < 0 THEN
            hemi := 'W';
        ELSE
            hemi := 'E';
        END IF;
    END IF;

    val := abs(val);

    deg := floor(val);
    min := floor((val - deg) * 60);
    sec := round((((val - deg) * 60 - min) * 60)::numeric, 2);

    RETURN deg || '° ' || min || ''' ' || sec || '" ' || hemi;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- Geom -> UTM (returns SRID, Easting, Northing)
CREATE OR REPLACE FUNCTION get_utm_from_geom(g geometry)
RETURNS TABLE(utm_srid int, utm_easting double precision, utm_northing double precision) AS $$
DECLARE
    zone int;
    srid int;
    g_utm geometry;
BEGIN
    zone := floor((ST_X(g) + 180) / 6) + 1;

    IF zone < 28 OR zone > 38 THEN
       RAISE EXCEPTION 'Outside Europe: UTM Zone % not valid (ETRS89)', zone;
    END IF;

    srid := 25800 + zone;
    g_utm := ST_Transform(g, srid);

    RETURN QUERY SELECT srid, ST_X(g_utm), ST_Y(g_utm);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- UTM -> Geom
CREATE OR REPLACE FUNCTION make_geom_from_utm(srid int, easting double precision, northing double precision)
RETURNS geometry AS $$
BEGIN
    RETURN ST_Transform(ST_SetSRID(ST_MakePoint(easting, northing), srid), 4326);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

------------------- Create trigger functions -----------------------

CREATE OR REPLACE FUNCTION set_metadata()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    NEW.updated_by := current_user;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_metadata_point()
RETURNS TRIGGER AS $$
DECLARE
    dd_lat double precision;
    dd_lon double precision;
    srid int;
    easting double precision;
    northing double precision;
BEGIN
    NEW.updated_at := now();
	NEW.updated_by := current_user;

    -- Priority 1: Geom got changed
    IF NEW.geom IS DISTINCT FROM OLD.geom THEN
        -- geom remains as entered

    -- Priority 2: UTM got changed
    ELSIF (NEW.utm_zone IS DISTINCT FROM OLD.utm_zone
        OR NEW.utm_easting IS DISTINCT FROM OLD.utm_easting
        OR NEW.utm_northing IS DISTINCT FROM OLD.utm_northing) THEN
        NEW.geom := make_geom_from_utm(NEW.utm_zone::int, NEW.utm_easting, NEW.utm_northing);

    -- Priority 3: DD got changed
    ELSIF (NEW.latitude_dd IS DISTINCT FROM OLD.latitude_dd
        OR NEW.longitude_dd IS DISTINCT FROM OLD.longitude_dd) THEN
        NEW.geom := make_geom_from_dd(NEW.latitude_dd, NEW.longitude_dd);

    -- Priority 4: DMS changed (optional)
    -- One could build a parser here, but that's complex.
    END IF;

    -- Derive from geom: DD
    SELECT lat, lon INTO dd_lat, dd_lon FROM get_dd_from_geom(NEW.geom);
    NEW.latitude_dd := dd_lat;
    NEW.longitude_dd := dd_lon;

    -- DMS
    NEW.latitude_dms  := to_dms_dd(dd_lat, true);
    NEW.longitude_dms := to_dms_dd(dd_lon, false);

    -- UTM
    --SELECT g.srid::text, g.easting, g.northing
    --INTO NEW.utm_zone, NEW.utm_easting, NEW.utm_northing
    --FROM get_utm_from_geom(NEW.geom) AS g;

    -- UTM
    SELECT g.utm_srid::text, g.utm_easting, g.utm_northing
    INTO NEW.utm_zone, NEW.utm_easting, NEW.utm_northing
    FROM get_utm_from_geom(NEW.geom) AS g;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_metadata_linestring()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    NEW.updated_by := current_user;
    IF NEW.geom IS DISTINCT FROM OLD.geom THEN
        NEW.length_geom := ST_Length(ST_Transform(NEW.geom, 25832));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_metadata_polygon()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    NEW.updated_by := current_user;
    IF NEW.geom IS DISTINCT FROM OLD.geom THEN
        NEW.area_geom := ST_Area(ST_Transform(NEW.geom, 25832));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-------------------- Link trigger to tables -----------------------

DROP TRIGGER IF EXISTS set_metadata_trigger ON bu;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON bu
FOR EACH ROW
EXECUTE FUNCTION set_metadata();

DROP TRIGGER IF EXISTS set_metadata_trigger ON wea;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON wea
FOR EACH ROW
EXECUTE FUNCTION set_metadata_point();

DROP TRIGGER IF EXISTS set_metadata_trigger ON wea_planned;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON wea_planned
FOR EACH ROW
EXECUTE FUNCTION set_metadata();

DROP TRIGGER IF EXISTS set_metadata_trigger ON wea_existing;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON wea_existing
FOR EACH ROW
EXECUTE FUNCTION set_metadata();

DROP TRIGGER IF EXISTS set_metadata_trigger ON crane_site;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON crane_site
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON access_road;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON access_road
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON over_swing_area;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON over_swing_area
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON pool_area;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON pool_area
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON pv_area;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON pv_area
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON bess;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON bess
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON cable_route;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON cable_route
FOR EACH ROW
EXECUTE FUNCTION set_metadata_linestring();

DROP TRIGGER IF EXISTS set_metadata_trigger ON substation;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON substation
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON land_owner;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON land_owner
FOR EACH ROW
EXECUTE FUNCTION set_metadata();

DROP TRIGGER IF EXISTS set_metadata_trigger ON bundesland;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON bundesland
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON landkreis;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON landkreis
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON gemeinde;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON gemeinde
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON gemarkung;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON gemarkung
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON flur;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON flur
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON parcel;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON parcel
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON planning_region;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON planning_region
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON vorranggebiet_wind;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON vorranggebiet_wind
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON fnp;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON fnp
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON bplan;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON bplan
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON pipe_conduit;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON pipe_conduit
FOR EACH ROW
EXECUTE FUNCTION set_metadata_linestring();

DROP TRIGGER IF EXISTS set_metadata_trigger ON wea_extern;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON wea_extern
FOR EACH ROW
EXECUTE FUNCTION set_metadata_point();

DROP TRIGGER IF EXISTS set_metadata_trigger ON building;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON building
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON forest;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON forest
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON protected_area;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON protected_area
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON heightrestriction_area;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON heightrestriction_area
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON waterbody;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON waterbody
FOR EACH ROW
EXECUTE FUNCTION set_metadata_polygon();

DROP TRIGGER IF EXISTS set_metadata_trigger ON street;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON street
FOR EACH ROW
EXECUTE FUNCTION set_metadata_linestring();

DROP TRIGGER IF EXISTS set_metadata_trigger ON railway;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON railway
FOR EACH ROW
EXECUTE FUNCTION set_metadata_linestring();

DROP TRIGGER IF EXISTS set_metadata_trigger ON parcel_owner;
CREATE TRIGGER set_metadata_trigger
BEFORE INSERT OR UPDATE ON parcel_owner
FOR EACH ROW
EXECUTE FUNCTION set_metadata();