const request = require("supertest");
const { app } = require("../src/app");

test("owner can read their order", async () => {
  const res = await request(app).get("/orders/o1").set("x-user", "alice");
  expect(res.status).toBe(200);
});

test("other customer gets 404", async () => {
  const res = await request(app).get("/orders/o1").set("x-user", "bob");
  expect(res.status).toBe(404);
});
