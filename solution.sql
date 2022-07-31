/* APPENDIX
 GLOBAL SITUATION
  */
CREATE VIEW forestation AS
SELECT f.country_code,
        f.year,
        f.country_name,
        r.region,
        l.total_area_sqkm,
        f.forest_area_sqkm,
            (f.forest_area_sqkm / l.total_area_sqkm)*100 AS forest_percent,
        r.income_group,
        CASE
            WHEN (f.forest_area_sqkm / l.total_area_sqkm) * 100 < 25 
                THEN 'less than 25'
            WHEN (f.forest_area_sqkm / l.total_area_sqkm) * 100 >= 25
                        AND (f.forest_area_sqkm / l.total_area_sqkm) * 100 < 50 
                THEN 'between 25 and 50'
            WHEN (f.forest_area_sqkm / l.total_area_sqkm) * 100 >= 50
                        AND (f.forest_area_sqkm / l.total_area_sqkm) * 100 < 75 
                THEN 'between 50 and 75'
            ELSE 'between 75 and 100'
            END AS quartiles
FROM forest_area f
JOIN (
    SELECT country_code,
        country_name,
        year,
        total_area_sq_mi * 2.59 total_area_sqkm
    FROM land_area
    WHERE total_area_sq_mi IS NOT NULL) l
ON f.country_code = l.country_code AND f.year = l.year
JOIN regions r
ON r.country_code = l.country_code
WHERE f.forest_area_sqkm IS NOT NULL AND l.total_area_sqkm IS NOT NULL
ORDER BY country_code, year
 

/*[1]*/
SELECT country_name, year, forest_area_sqkm
FROM forestation
WHERE (year = 1990 or year = 2016) AND country_name='World' 

/*[3]*/
SELECT (SELECT forest_area_sqkm
		FROM forestation
		WHERE year = 1990 AND country_name='World' )-
        (SELECT forest_area_sqkm
		FROM forestation
		WHERE year = 2016 AND country_name='World' ) AS Change_in_time
FROM forestation
LIMIT 1

/*[4]*/
SELECT (((SELECT forest_area_sqkm
		FROM forestation
		WHERE year = 1990 AND country_name='World' )/
        (SELECT forest_area_sqkm
		FROM forestation
		WHERE year = 2016 AND country_name='World' )-1)*100) AS percent_change_in_time
FROM forestation
LIMIT 1

/*[5]*/
SELECT country_name, total_area_sqkm
FROM forestation
WHERE year = '2016' AND total_area_sqkm < 1324449
ORDER BY total_area_sqkm DESC
LIMIT 1

/*REGIONAL OUTLOOK*/
/*[6]*/
SELECT SUM(f.total_area_sqkm) AS land_total_2016,
    SUM(f.forest_area_sqkm) AS forest_total_2016,
    ROUND(CAST((SUM(f.forest_area_sqkm) * 100 / SUM(f.total_area_sqkm)) AS
    NUMERIC),2) AS forest_percent
FROM (SELECT * 
    FROM forestation
    WHERE country_name != 'World') AS f
WHERE year = 2016

/*[7]*/
SELECT f.region, 
    sum(forest_area_sqkm)*100/sum(total_area_sqkm) AS percent_1990, 
    percent_2016.percent_2016
FROM forestation f
JOIN (SELECT ft.region, 
            sum(ft.forest_area_sqkm)*100/sum(ft.total_area_sqkm) 
            AS percent_2016
        FROM forestation ft
        WHERE ft.year = 2016 AND ft.forest_percent > 0 
            AND ft.region != 'World'
        GROUP BY ft.region) AS percent_2016 
ON f.region = percent_2016.region
WHERE year = 1990 AND forest_percent > 0 AND f.region != 'World'
GROUP BY f.region, percent_2016.percent_2016
ORDER BY percent_2016 DESC

/*[8]*/
SELECT SUM(total_area_sqkm) AS land_total_1990,
        SUM(forest_area_sqkm) AS forest_total_1990,
        SUM(forest_area_sqkm) * 100 / SUM(total_area_sqkm) AS forest_percent
FROM (SELECT * 
    FROM forestation
    WHERE country_name != 'World') AS f
WHERE year = 1990

/*COUNTRY-LEVEL DETAIL*/
SELECT f.country_name,
    f.region,
    f.year,
    f.forest_area_sqkm AS forest_area_sqkm_1990,
    forest_area_2016.forest_area_sqkm AS forest_area_sqkm_2016,
    forest_area_2016.forest_area_sqkm - f.forest_area_sqkm AS
    change_over_time
FROM forestation f
JOIN (SELECT ft.forest_area_sqkm, ft.country_name
        FROM forestation ft
        WHERE year = 2016) AS forest_area_2016
ON f.country_name = forest_area_2016.country_name
WHERE f.year = 1990 AND f.forest_area_sqkm > 0
    AND forest_area_2016.forest_area_sqkm > 0
ORDER BY change_over_time DESC

/*Table 3.1: Top 5 Amount Decrease in Forest Area by Country, 1990 & 2016*/
SELECT f.country_name,
region,
f.forest_area_sqkm AS forest_area_sqkm_1990,
forest_area_2016.forest_area_sqkm AS forest_area_sqkm_2016,
forest_area_2016.forest_area_sqkm - f.forest_area_sqkm AS
change_over_time 
FROM forestation f
JOIN (SELECT ft.forest_area_sqkm, ft.country_name
FROM forestation ft
WHERE year = 2016) AS forest_area_2016
ON f.country_name = forest_area_2016.country_name
WHERE f.year = 1990
    AND f.forest_area_sqkm IS NOT NULL
    AND forest_area_2016.forest_area_sqkm IS NOT NULL
    AND f.region != 'World'
ORDER BY change_over_time

/*Table 3.2: Top 5 Percent Decrease in Forest Area by Country, 1990 & 2016*/
SELECT f.country_name,
f.region,
f.forest_area_sqkm AS forest_area_sqkm_1990,
forest_area_2016.forest_area_sqkm AS forest_area_sqkm_2016,
ROUND(CAST(((forest_area_2016.forest_area_sqkm - f.forest_area_sqkm) /
forest_area_2016.forest_area_sqkm-1)*100 AS NUMERIC),2) AS change_over_time
FROM forestation f
JOIN (SELECT *
FROM forestation ft
WHERE year = 2016) AS forest_area_2016
ON f.country_name = forest_area_2016.country_name
WHERE f.year = 1990
AND f.forest_area_sqkm IS NOT NULL
AND forest_area_2016.forest_area_sqkm IS NOT NULL
AND forest_area_2016.forest_percent IS NOT NULL
AND f.forest_percent IS NOT NULL
AND f.region != 'World'
ORDER BY change_over_time
 
/* [Table 3.3: Count of Countries Grouped by Forestation Percent Quartiles, 2016] */
SELECT quartiles,
    COUNT(quartiles) AS q_count
FROM forestation
WHERE year = 2016
GROUP BY quartiles
ORDER BY q_count DESC

/* [Table 3.4: Top Quartile Countries, 2016]*/
SELECT *
FROM forestation
WHERE year = 2016 AND quartiles = 'between 75 and 100'
ORDER BY forest_percent DESC