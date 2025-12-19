-- Script 4.2 Insert a new wind turbine
INSERT INTO wea (bu_name, model, capacity, ground_elev, hub_ht,
    rot_dia, total_ht, wea_nr, fun_dia, con_rad, rot_wind,
    status_wea, nxw_share, geom)
VALUES ('Altmark', 'N-175', '6.8', '45', '179', '175', '266',
    'W01', '30', '106', '45', 'In Planning', '100%',
    ST_SetSRID(ST_MakePoint(11.4512112, 52.7386130), 4326));

-- Script 4.3 Update an attribute
UPDATE wea SET status_wea = 'In Operation'
WHERE bu_name = 'Altmark' AND wea_nr = 'W01';

-- Script 4.4 Delete an outdated object
DELETE FROM potential_area WHERE potential_id = '42';

-- Script 4.5 Average length of all cable routes
SELECT AVG(length_geom) AS avg_cable_length_m FROM cable_route;

-- Script 4.6 Owner with the most parcels (+ parcel list)
SELECT o.firstname, o.secondname, COUNT(p.parcel_id) AS parcel_count, STRING_AGG(p.parcel_nr, ', ') AS parcel_list
FROM land_owner o
JOIN parcel_owner po ON o.owner_id = po.owner_id
JOIN parcel p ON p.parcel_id = po.parcel_id
GROUP BY o.owner_id
ORDER BY parcel_count DESC
LIMIT 1;

-- Script 4.7 Rank Business Units by distance to Buxtehude
-- Assume the centroid of all WEA defines the BU location.
SELECT 
    bu_name,
    ST_Distance(
        ST_Centroid(ST_Collect(w.geom))::geography,
        ST_SetSRID(ST_MakePoint(9.7036, 53.4763), 4326)::geography
    ) AS distance_m
FROM wea AS w
GROUP BY bu_name
ORDER BY distance_m;