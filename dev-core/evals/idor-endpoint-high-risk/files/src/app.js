const express = require("express");
const app = express();
app.use(express.json());

// Fake auth: the caller's user id comes from the x-user header
app.use((req, res, next) => {
  req.userId = req.header("x-user") || null;
  if (!req.userId) return res.status(401).json({ title: "Unauthorized" });
  next();
});

const orders = new Map([
  ["o1", { id: "o1", customerId: "alice", note: "", status: "PENDING" }],
  ["o2", { id: "o2", customerId: "bob", note: "", status: "PENDING" }],
]);

app.get("/orders/:id", (req, res) => {
  const order = orders.get(req.params.id);
  if (!order || order.customerId !== req.userId) return res.status(404).json({ title: "Not found" });
  res.json(order);
});

module.exports = { app, orders };
