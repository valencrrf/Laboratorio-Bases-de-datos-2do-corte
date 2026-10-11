# Laboratorio: Modelado y análisis de datos con SQL

Del archivo plano `Online_game.csv` (ventas de videojuegos) a un modelo relacional normalizado en MySQL, cargado con un programa en Node.js y explotado con consultas SQL.

**Autoras:** Valentina Cruz Fabra, Yadi Mariana Javier Arias y Maria Sofía Socha Estupiñan
**Curso:** Facultad de Ingeniería, Universidad San Buenaventura, Bogotá, Colombia

## Contenido del repositorio

| Archivo o carpeta | Descripción |
|---|---|
| `DDL.sql` | Script DDL: crea el esquema `online_game` con las cinco tablas (`platform`, `genre`, `publisher`, `videogame`, `sale`). |
| `programa de carga/Lab/` | Programa de carga en Node.js. Contiene `carga_datos.js` (lee el CSV, valida las filas e inserta todo en una sola transacción), `package.json` y `package-lock.json` (dependencias `mysql2` y `csv-parse`) y `Online_game.csv` (dataset de origen, 16 598 registros). |
| `consultas lab.sql` | Las consultas del laboratorio: 4 básicas y las de análisis del dataset asignado. |

## Modelo

Se descartan dos columnas derivadas (`Rank` y `Global_Sales`). El resto se descompone en cinco tablas en tercera forma normal:

- `platform`, `genre`, `publisher`: catálogos con `id` y `name`.
- `videogame`: un lanzamiento (título en una plataforma), con `release_year` y claves foráneas a los tres catálogos.
- `sale`: una fila por lanzamiento y región (`NA`, `EU`, `JP`, `Other`), con clave primaria `(videogame_id, region)`.

La justificación completa de las exclusiones y de cada forma normal está en el informe.

## Cómo ejecutarlo

Requisitos: MySQL 8 y Node.js.

1. Crear el esquema (desde MySQL Workbench, abriendo y ejecutando `DDL.sql`, o desde la línea de comandos en la raíz del repositorio):

   ```bash
   mysql -u root -p < DDL.sql
   ```

2. Entrar a la carpeta del programa de carga e instalar dependencias:

   ```bash
   cd "programa de carga/Lab"
   npm install
   ```

3. Configurar la conexión con variables de entorno. Si no se definen, se usan los valores por defecto (`localhost`, `root`, base `online_game`):

   ```bash
   export DB_HOST=localhost
   export DB_USER=root
   export DB_PASSWORD=su_contraseña
   export DB_NAME=online_game
   ```

4. Ejecutar la carga desde esa misma carpeta (la ruta del CSV es opcional; por defecto `Online_game.csv`):

   ```bash
   npm start
   ```

   La carga es una única transacción: si una inserción falla se hace rollback y el programa termina con error, así que no deja cargas parciales. Las filas con datos inválidos se registran con su número de fila en `errores_carga.log`.

   > La carga no es idempotente: ejecutarla dos veces sobre la misma base duplica los datos. Para repetirla, vacíe las tablas o recree el esquema con `DDL.sql`.

5. Ejecutar las consultas abriendo `consultas lab.sql` en MySQL Workbench.

## Verificación de la carga

Al terminar, el programa imprime el resumen y el conteo por tabla. Resultado esperado:

| Concepto | Valor |
|---|---|
| Filas leídas | 16 598 |
| Videojuegos insertados | 16 598 |
| Registros de ventas | 66 392 (16 598 × 4 regiones) |
| Filas rechazadas | 0 |
| Plataformas / géneros / publicadores | 31 / 12 / 578 |

## Consultas

`consultas lab.sql` contiene, cada una con un comentario que indica qué pregunta responde:

- **Básicas:** filtrado con dos condiciones, JOIN de dos entidades, JOIN de tres o más entidades y agregación con `GROUP BY`.
- **Análisis:** (1) publicador con mayor total de ventas y si el liderazgo se sostiene por promedio, (2) plataforma con más juegos de un género posteriores a un año, (3) juegos que venden más en Japón que en Norteamérica y su patrón por género y plataforma, y (4) género con mayor promedio de ventas frente a su cantidad de juegos.

La interpretación de cada resultado está en el informe.
