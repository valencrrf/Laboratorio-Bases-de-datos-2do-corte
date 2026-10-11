USE online_game;

-- Básica 1: filtrado con dos condiciones
SELECT name, release_year
FROM videogame
WHERE name LIKE '%Mario%'
  AND release_year BETWEEN 2005 AND 2015
ORDER BY release_year, name;

-- Básica 2: JOIN de dos entidades
SELECT v.name, v.release_year, s.sales AS jp_sales
FROM videogame v
JOIN sale s ON s.videogame_id = v.id
WHERE s.region = 'JP'
ORDER BY s.sales DESC, v.name
LIMIT 10;

-- Básica 3: JOIN de más de tres entidades
SELECT v.name,
       pl.name AS platform,
       g.name AS genre,
       v.release_year,
       s.sales AS na_sales
FROM videogame v
JOIN platform pl ON pl.id = v.platform_id
JOIN genre g ON g.id = v.genre_id
JOIN publisher pub ON pub.id = v.publisher_id
JOIN sale s ON s.videogame_id = v.id AND s.region = 'NA'
WHERE pub.name = 'Nintendo'
  AND v.release_year > 2010
ORDER BY s.sales DESC, v.name
LIMIT 10;

-- Básica 4: agregación con GROUP BY
SELECT pl.name AS platform,
       COUNT(v.id) AS game_count
FROM platform pl
JOIN videogame v ON pl.id = v.platform_id
GROUP BY pl.id, pl.name
ORDER BY game_count DESC;

-- Análisis 1a: publishers con mayor total de ventas globales
SELECT pub.name AS publisher,
       COUNT(DISTINCT v.id) AS game_count,
       ROUND(SUM(s.sales), 2) AS total_sales,
       ROUND(SUM(s.sales) / COUNT(DISTINCT v.id), 2) AS avg_sales_per_game
FROM publisher pub
JOIN videogame v ON v.publisher_id = pub.id
JOIN sale s ON s.videogame_id = v.id
GROUP BY pub.id, pub.name
ORDER BY total_sales DESC
LIMIT 5;

-- Análisis 1b: promedio por juego, sin filtro de muestra
SELECT pub.name AS publisher,
       COUNT(DISTINCT v.id) AS game_count,
       ROUND(SUM(s.sales), 2) AS total_sales,
       ROUND(SUM(s.sales) / COUNT(DISTINCT v.id), 2) AS avg_sales_per_game
FROM publisher pub
JOIN videogame v ON v.publisher_id = pub.id
JOIN sale s ON s.videogame_id = v.id
GROUP BY pub.id, pub.name
ORDER BY avg_sales_per_game DESC
LIMIT 5;

-- Análisis 1c: promedio por juego, solo publishers con al menos 10 juegos
SELECT pub.name AS publisher,
       COUNT(DISTINCT v.id) AS game_count,
       ROUND(SUM(s.sales), 2) AS total_sales,
       ROUND(SUM(s.sales) / COUNT(DISTINCT v.id), 2) AS avg_sales_per_game
FROM publisher pub
JOIN videogame v ON v.publisher_id = pub.id
JOIN sale s ON s.videogame_id = v.id
GROUP BY pub.id, pub.name
HAVING COUNT(DISTINCT v.id) >= 10
ORDER BY avg_sales_per_game DESC
LIMIT 5;

-- Análisis 2: plataforma con más juegos de Action posteriores a 2015
SELECT pl.name AS platform,
       COUNT(v.id) AS game_count
FROM videogame v
JOIN platform pl ON v.platform_id = pl.id
JOIN genre g ON v.genre_id = g.id
WHERE g.name = 'Action'
  AND v.release_year > 2015
GROUP BY pl.id, pl.name
ORDER BY game_count DESC
LIMIT 5;

-- Análisis 3a: juegos con mayor diferencia a favor de Japón
SELECT v.name,
       pl.name AS platform,
       g.name AS genre,
       jp.sales AS jp_sales,
       na.sales AS na_sales,
       ROUND(jp.sales - na.sales, 2) AS sales_difference
FROM videogame v
JOIN sale jp ON jp.videogame_id = v.id AND jp.region = 'JP'
JOIN sale na ON na.videogame_id = v.id AND na.region = 'NA'
JOIN platform pl ON pl.id = v.platform_id
JOIN genre g ON g.id = v.genre_id
WHERE jp.sales > na.sales
ORDER BY sales_difference DESC, v.name
LIMIT 10;

-- Análisis 3b: patrón por género
SELECT g.name AS genre,
       COUNT(*) AS game_count,
       SUM(CASE WHEN jp.sales > na.sales THEN 1 ELSE 0 END) AS jp_over_na_count,
       ROUND(100 * SUM(CASE WHEN jp.sales > na.sales THEN 1 ELSE 0 END) / COUNT(*), 1) AS jp_over_na_percent
FROM videogame v
JOIN sale jp ON jp.videogame_id = v.id AND jp.region = 'JP'
JOIN sale na ON na.videogame_id = v.id AND na.region = 'NA'
JOIN genre g ON g.id = v.genre_id
GROUP BY g.id, g.name
ORDER BY jp_over_na_count DESC;

-- Análisis 3c: patrón por plataforma
SELECT pl.name AS platform,
       COUNT(*) AS game_count,
       SUM(CASE WHEN jp.sales > na.sales THEN 1 ELSE 0 END) AS jp_over_na_count,
       ROUND(100 * SUM(CASE WHEN jp.sales > na.sales THEN 1 ELSE 0 END) / COUNT(*), 1) AS jp_over_na_percent
FROM videogame v
JOIN sale jp ON jp.videogame_id = v.id AND jp.region = 'JP'
JOIN sale na ON na.videogame_id = v.id AND na.region = 'NA'
JOIN platform pl ON pl.id = v.platform_id
GROUP BY pl.id, pl.name
ORDER BY jp_over_na_count DESC
LIMIT 10;

-- Análisis 3d: casos JP > NA sin ventas en Norteamérica
SELECT COUNT(*) AS jp_over_na_zero_na
FROM sale jp
JOIN sale na ON na.videogame_id = jp.videogame_id AND na.region = 'NA'
WHERE jp.region = 'JP'
  AND jp.sales > na.sales
  AND na.sales = 0;

-- Análisis 3e: plataformas con 100 o más juegos donde más de la mitad vende más en Japón
SELECT pl.name AS platform,
       COUNT(*) AS game_count,
       SUM(CASE WHEN jp.sales > na.sales THEN 1 ELSE 0 END) AS jp_over_na_count,
       ROUND(100 * SUM(CASE WHEN jp.sales > na.sales THEN 1 ELSE 0 END) / COUNT(*), 1) AS jp_over_na_percent
FROM videogame v
JOIN sale jp ON jp.videogame_id = v.id AND jp.region = 'JP'
JOIN sale na ON na.videogame_id = v.id AND na.region = 'NA'
JOIN platform pl ON pl.id = v.platform_id
GROUP BY pl.id, pl.name
HAVING COUNT(*) >= 100
   AND SUM(CASE WHEN jp.sales > na.sales THEN 1 ELSE 0 END) / COUNT(*) > 0.5
ORDER BY jp_over_na_percent DESC;

-- Análisis 4: promedio de ventas por género frente a la cantidad de juegos
SELECT g.name AS genre,
       COUNT(DISTINCT v.id) AS game_count,
       ROUND(SUM(s.sales) / COUNT(DISTINCT v.id), 3) AS avg_global_sales,
       RANK() OVER (ORDER BY SUM(s.sales) / COUNT(DISTINCT v.id) DESC) AS avg_sales_rank,
       RANK() OVER (ORDER BY COUNT(DISTINCT v.id) DESC) AS game_count_rank
FROM genre g
JOIN videogame v ON v.genre_id = g.id
JOIN sale s ON s.videogame_id = v.id
GROUP BY g.id, g.name
ORDER BY avg_sales_rank;