-- 1) X-ray emissions in a circle of radius 10 from coordinates 0,0
SELECT TOP 10 "1RXS", "RAJ2000", "DEJ2000", "Count"
FROM "IX/10A/1rxs" as t
WHERE CONTAINS( POINT('ICRS', t.RAJ2000, t.DEJ2000), CIRCLE('ICRS', 0, 0, 10) ) = 1


-- 2) Stars inside the Orion constellation
--    that in 10'000 years will be moved 1 degree from their original positions
SELECT TOP 10 "GC", "Vmag", "SpType", "RA1950", "DE1950", "pmRA"/3600*15, "pmDE"/3600,
SQRT(POWER("pmRA"/3600*15, 2) + POWER("pmDE"/3600, 2)) as vel_degrees_per_year
FROM "I/113A/catalog"
WHERE 1=CONTAINS(POINT('ICRS', "RA1950", "DE1950"), 
                 POLYGON('ICRS', 90.4, -10.97, 90.4, 22.87, 60.75, 22.87, 60.75, -10.97))
AND SQRT(POWER("pmRA"/3600*15, 2) + POWER("pmDE"/3600, 2)) > 0.0001


-- 3) Galaxies with quasars
SELECT TOP 10 galaxies."RAJ2000", galaxies."DEJ2000", quasars."SDSS"
FROM "VII/275/glade1" AS galaxies, "VII/269/dr9q" as quasars
WHERE DISTANCE (POINT('ICRS', galaxies."RAJ2000", galaxies."DEJ2000"),
                POINT('ICRS', quasars."RAJ2000", quasars."DEJ2000")) < 1.0/3600 
				

-- 4) Data of stars of the most frequent spectral class
SELECT TOP 10 "GC", "Vmag", "SpType", "RA1950", "DE1950", "pmRA", "pmDE" -- stars
FROM "I/113A/catalog"
WHERE "SpType" IN (
    SELECT "SpType" -- spectral class with the highest frequency
    FROM "I/113A/catalog"
    GROUP BY "SpType"
    HAVING COUNT(*) IN (
        SELECT TOP 1 COUNT(*) AS count_all -- frequency of the most frequent spectral class
        FROM "I/113A/catalog"
        GROUP BY "SpType"
        ORDER BY count_all DESC
        )
    )

	
-- 5) Comets at Perihelion during a solar eclipse
SELECT TOP 10 comets."Code", comets."Name", solareclipse."Ecl"
FROM "VI/97/solar" AS solareclipse, "B/comets/comets" AS comets
WHERE solareclipse."Ecl" > comets."T0" - 2
AND   solareclipse."Ecl" < comets."T0" + 2
AND   comets."H1" < 7

				
-- 6) Radio pulsar with a X or gamma counterpart
SELECT TOP 10
	psr."Name" as psr_name, 
	
	x."Source" as x_source,
	DISTANCE( POINT('ICRS', psr.RAJ2000, psr.DEJ2000), 
					  POINT('ICRS', x.RA_ICRS, x.DE_ICRS))*3600 as distance_sec_psr_x,
	
	gamma."3FGL" as gamma_name,
	DISTANCE( POINT('ICRS', psr.RAJ2000, psr.DEJ2000), 
					  POINT('ICRS', gamma.RAJ2000, gamma.DEJ2000)) as distance_deg_psr_gamma
					  
FROM "B/psr/psr" as psr, "J/ApJS/218/23/table4" as gamma, "IX/47/3xmmeu" as x
WHERE DISTANCE( POINT('ICRS', psr.RAJ2000, psr.DEJ2000), 
							   POINT('ICRS', x.RA_ICRS, x.DE_ICRS)) <= 1.0/3600
AND   DISTANCE( POINT('ICRS', psr.RAJ2000, psr.DEJ2000), 
							POINT('ICRS', gamma.RAJ2000, gamma.DEJ2000)) <= 1


-- 7) Exoplanets in the abitable zone of their star
SELECT TOP 10 "KOI", "Epoch", "Per", "Sep", "M*"
FROM "J/ApJS/210/19/table1"
WHERE 
	(   "Sep" * 0.004638 > SQRT (0.23 * POWER("M*", 2.3)) * 0.8 
	AND "Sep" * 0.004638 < SQRT (0.23 * POWER("M*", 2.3)) * 1.2
	AND "M*" <= 0.43)
OR
	(	"Sep" * 0.004638 > POWER("M*", 4) * 0.8 
	AND "Sep" * 0.004638 < POWER("M*", 4) * 1.2
	AND "M*" > 0.43 AND "M*" <= 2)
OR
	(	"Sep" * 0.004638 > SQRT (1.5 * POWER("M*", 3.5)) * 0.8 
	AND "Sep" * 0.004638 < SQRT (1.5 * POWER("M*", 3.5)) * 1.2
	AND "M*" > 2 AND "M*" <= 20 )
OR
	(	"Sep" * 0.004638 > "M*" * 0.8 
	AND "Sep" * 0.004638 < "M*" * 1.2
	AND "M*" > 20 )

							
-- 8) Date of the first and last transit and number of transits of the exoplanets
--    from 26/11/2043 to 30/11/2043
SELECT TOP 10 "KOI", "Epoch", "Per", "_RA", "_DE",
 "Epoch" + CEILING((12746 - "Epoch")/"Per")*"Per" as first_transit,
 "Epoch" +   FLOOR((12750 - "Epoch")/"Per")*"Per" as last_transit,
 
 ("Epoch" +   FLOOR((12750 - "Epoch")/"Per")*"Per" -
 ("Epoch" + CEILING((12746 - "Epoch")/"Per")*"Per"))/"Per" + 1 as n_transits

FROM "J/ApJS/217/31/KOIs"
WHERE 
 ("Epoch" +   FLOOR((12750 - "Epoch")/"Per")*"Per") >=
 ("Epoch" + CEILING((12746 - "Epoch")/"Per")*"Per")

-- 8.1)
SELECT koi, epoch, per, _RA, _DE,
  epoch +  CEIL((12746 - epoch)/per)*per as first_transit,
  epoch + FLOOR((12750 - epoch)/per)*per as last_transit,
 
 (epoch + FLOOR((12750 - epoch)/per)*per -
 (epoch +  CEIL((12746 - epoch)/per)*per))/per + 1 as n_transits

FROM kepler 
WHERE
 (epoch + FLOOR((12750 - epoch)/per)*per) >
 (epoch +  CEIL((12746 - epoch)/per)*per)
AND   hadec2alt(_RA/15, _DE, 39) > 0
LIMIT 10;














