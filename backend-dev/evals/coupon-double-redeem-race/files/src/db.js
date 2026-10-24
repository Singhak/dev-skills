const { DatabaseSync } = require("node:sqlite");

// Async data access, like a networked database driver (pg, mysql2): each call
// yields to the event loop, so concurrent requests interleave between queries.
function createDb(file = ":memory:") {
  const conn = new DatabaseSync(file);
  conn.exec(`
    CREATE TABLE coupons (code TEXT PRIMARY KEY, remaining INTEGER NOT NULL);
    CREATE TABLE redemptions (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL, user_id TEXT NOT NULL,
                              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
  `);
  const tick = () => new Promise((resolve) => setImmediate(resolve));
  return {
    async get(sql, ...params) { await tick(); return conn.prepare(sql).get(...params); },
    async all(sql, ...params) { await tick(); return conn.prepare(sql).all(...params); },
    async run(sql, ...params) { await tick(); return conn.prepare(sql).run(...params); }, // returns { changes, lastInsertRowid }
    async exec(sql) { await tick(); conn.exec(sql); },
    close() { conn.close(); },
  };
}
module.exports = { createDb };
