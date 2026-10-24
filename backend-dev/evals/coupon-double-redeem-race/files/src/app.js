const express = require("express");
function createApp(db) {
  const app = express();
  app.use(express.json());
  app.use((req, res, next) => {
    req.userId = req.header("x-user");
    if (!req.userId) return res.status(401).json({ title: "Unauthorized" });
    next();
  });
  app.get("/coupons/:code", (req, res) => {
    const c = db.prepare("SELECT code, remaining FROM coupons WHERE code = ?").get(req.params.code);
    if (!c) return res.status(404).json({ title: "Not found" });
    res.json(c);
  });
  return app;
}
module.exports = { createApp };
