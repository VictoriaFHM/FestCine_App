const sql = require("mssql/msnodesqlv8");

const config = {
  connectionString:
    "Driver={ODBC Driver 17 for SQL Server};" +
    "Server=HP15RYZEN7000\\SQLEXPRESS;" +
    "Database=FestCine;" +
    "Trusted_Connection=Yes;" +
    "TrustServerCertificate=Yes;"
};

async function getConnection() {
  try {
    const pool = await sql.connect(config);
    return pool;
  } catch (error) {
    console.error("Error conectando a SQL Server:");
    console.error(error);
    throw error;
  }
}

module.exports = {
  sql,
  getConnection
};