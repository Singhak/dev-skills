const Database = require("better-sqlite3");
function createDb(file = ":memory:") {
  const db = new Database(file);
  db.exec(`
    CREATE TABLE coupons (code TEXT PRIMARY KEY, remaining INTEGER NOT NULL);
    CREATE TABLE redemptions (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL, user_id TEXT NOT NULL,
                              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
  `);
  return db;
}
module.exports = { createDb };
