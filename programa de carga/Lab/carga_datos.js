const fs = require('fs');
const { parse } = require('csv-parse/sync');
const mysql = require('mysql2/promise');

const CSV_PATH = process.argv[2] || 'Online_game.csv';
const ERROR_LOG_PATH = 'errores_carga.log';
const MAX_ERRORS_SHOWN = 50;
const UNKNOWN_PUBLISHER = 'Unknown';
const FIRST_DATA_ROW_NUMBER = 2;

const REGION_COLUMNS = { NA_Sales: 'NA', EU_Sales: 'EU', JP_Sales: 'JP', Other_Sales: 'Other' };
const TABLE_NAMES = ['platform', 'genre', 'publisher', 'videogame', 'sale'];

const stats = {
  rowsRead: 0,
  videogames: 0,
  sales: 0,
  rejected: 0,
  unknownPublisher: 0,
  missingYear: 0,
};
const errors = [];

function rejectRow(rowNumber, reason) {
  stats.rejected++;
  errors.push(`Fila ${rowNumber}: ${reason}`);
}

function recordInsertedGame(game) {
  stats.videogames++;
  stats.sales += game.sales.length;
  if (game.releaseYear === null) stats.missingYear++;
  if (game.publisher === null) stats.unknownPublisher++;
}

function isMissing(text) {
  return text === '' || text.toUpperCase() === 'N/A';
}

function readText(csvRow, column) {
  return (csvRow[column] || '').trim();
}

function readCsv(path) {
  try {
    return parse(fs.readFileSync(path, 'utf8'), {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    });
  } catch (error) {
    throw new Error(`No se pudo leer el CSV (${path}): ${error.message}`);
  }
}

function connectToDatabase() {
  return mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'online_game',
  });
}

function parseReleaseYear(yearText) {
  if (isMissing(yearText)) return null;
  return Math.trunc(Number(yearText));
}

function parsePublisher(publisherText) {
  return isMissing(publisherText) ? null : publisherText;
}

function parseSales(csvRow) {
  const sales = [];
  for (const [column, region] of Object.entries(REGION_COLUMNS)) {
    const amount = Number(csvRow[column]);
    if (csvRow[column] === undefined || csvRow[column] === '' || Number.isNaN(amount) || amount < 0) {
      return { reason: `${column} inválido: "${csvRow[column]}"` };
    }
    sales.push({ region, amount });
  }
  return { sales };
}

function buildGame(csvRow) {
  const name = readText(csvRow, 'Name');
  const platform = readText(csvRow, 'Platform');
  const genre = readText(csvRow, 'Genre');
  if (!name || !platform || !genre) {
    return { reason: 'Name, Platform o Genre vacío' };
  }

  const releaseYear = parseReleaseYear(readText(csvRow, 'Year'));
  if (releaseYear !== null && !Number.isInteger(releaseYear)) {
    return { reason: `Year inválido: "${csvRow.Year}"` };
  }

  const { sales, reason } = parseSales(csvRow);
  if (reason) return { reason };

  const publisher = parsePublisher(readText(csvRow, 'Publisher'));
  return { game: { name, platform, genre, publisher, releaseYear, sales } };
}

async function getOrCreateId(connection, cache, table, name) {
  if (cache.has(name)) return cache.get(name);
  const [result] = await connection.execute(`INSERT INTO ${table} (name) VALUES (?)`, [name]);
  cache.set(name, result.insertId);
  return result.insertId;
}

async function getReferenceIds(connection, idCaches, game) {
  return {
    platformId: await getOrCreateId(connection, idCaches.platform, 'platform', game.platform),
    genreId: await getOrCreateId(connection, idCaches.genre, 'genre', game.genre),
    publisherId: await getOrCreateId(
      connection,
      idCaches.publisher,
      'publisher',
      game.publisher ?? UNKNOWN_PUBLISHER
    ),
  };
}

async function insertVideogame(connection, game, referenceIds) {
  const [result] = await connection.execute(
    'INSERT INTO videogame (name, release_year, platform_id, genre_id, publisher_id) VALUES (?, ?, ?, ?, ?)',
    [game.name, game.releaseYear, referenceIds.platformId, referenceIds.genreId, referenceIds.publisherId]
  );
  return result.insertId;
}

async function insertSales(connection, videogameId, sales) {
  const saleRows = sales.map(({ region, amount }) => [region, amount, videogameId]);
  await connection.query('INSERT INTO sale (region, sales, videogame_id) VALUES ?', [saleRows]);
}

async function insertGame(connection, idCaches, game) {
  const referenceIds = await getReferenceIds(connection, idCaches, game);
  const videogameId = await insertVideogame(connection, game, referenceIds);
  await insertSales(connection, videogameId, game.sales);
}

async function loadGames(connection, csvRows) {
  const idCaches = { platform: new Map(), genre: new Map(), publisher: new Map() };

  for (let index = 0; index < csvRows.length; index++) {
    const rowNumber = index + FIRST_DATA_ROW_NUMBER;
    const { game, reason } = buildGame(csvRows[index]);
    if (!game) {
      rejectRow(rowNumber, reason);
      continue;
    }

    await insertGame(connection, idCaches, game).catch((error) => {
      rejectRow(rowNumber, `Error de BD (${error.code || 'sin código'}): ${error.message}`);
      throw error;
    });
    recordInsertedGame(game);
  }
}

async function runInTransaction(connection, work) {
  await connection.beginTransaction();
  try {
    await work();
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  }
}

function printErrors() {
  if (errors.length === 0) return;
  console.log(`\n=== ERRORES (${errors.length}) ===`);
  errors.slice(0, MAX_ERRORS_SHOWN).forEach((message) => console.log(message));
  if (errors.length > MAX_ERRORS_SHOWN) {
    console.log(`... y ${errors.length - MAX_ERRORS_SHOWN} más`);
  }
  fs.writeFileSync(ERROR_LOG_PATH, errors.join('\n'));
  console.log(`Detalle completo en ${ERROR_LOG_PATH}`);
}

function printLoadSummary() {
  const summary = [
    ['Filas leídas del CSV', stats.rowsRead],
    ['Videojuegos insertados', stats.videogames],
    ['Registros de ventas', stats.sales],
    ['Filas rechazadas', stats.rejected],
    ['Año nulo (N/A)', stats.missingYear],
    ['Publisher asignado Unknown', stats.unknownPublisher],
  ];
  console.log('\nRESUMEN DE LA CARGA');
  summary.forEach(([label, value]) => console.log(`${label.padEnd(30)} ${value}`));
}

async function printTableCounts(connection) {
  console.log('\nCONTEO POR TABLA EN LA BD');
  for (const table of TABLE_NAMES) {
    const [[{ total }]] = await connection.query(`SELECT COUNT(*) AS total FROM ${table}`);
    console.log(`${table.padEnd(10)} ${total}`);
  }
}

function reportAbortedLoad(error) {
  console.error('\nCARGA ABORTADA, se hizo rollback. Motivo:', error.message);
  printErrors();
}

async function main() {
  const csvRows = readCsv(CSV_PATH);
  stats.rowsRead = csvRows.length;

  const connection = await connectToDatabase();
  try {
    await runInTransaction(connection, () => loadGames(connection, csvRows));
  } catch (error) {
    reportAbortedLoad(error);
    process.exitCode = 1;
    await connection.end();
    return;
  }

  printLoadSummary();
  printErrors();
  await printTableCounts(connection);
  await connection.end();
}

main().catch((error) => {
  console.error('La carga no pudo completarse:', error.message);
  process.exit(1);
});