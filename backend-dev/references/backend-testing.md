# Backend Testing Patterns

## Contents
1. Unit test a use case with a fake repository
2. Integration test with Testcontainers
3. API test incl. authorization
4. Contract testing
5. Async / event tests
6. Test data isolation strategies
7. CI layout

## 1. Unit test a use case (fake repository)
TypeScript (Vitest):
```ts
class InMemoryOrders implements OrderRepository {
  private rows = new Map<string, Order>();
  async save(o: Order) { this.rows.set(o.id, o); }
  async findById(id: string) { return this.rows.get(id) ?? null; }
}

it("rejects cancelling an order that has shipped", async () => {
  const repo = new InMemoryOrders();
  await repo.save(anOrder({ id: "o1", status: "SHIPPED" }));
  const cancel = new CancelOrder(repo, fixedClock("2026-01-01"));
  await expect(cancel.execute({ orderId: "o1", userId: "u1" }))
    .rejects.toBeInstanceOf(OrderAlreadyShipped);
});
```
Python (pytest):
```python
def test_rejects_cancelling_shipped_order():
    repo = InMemoryOrders([an_order(id="o1", status="SHIPPED")])
    with pytest.raises(OrderAlreadyShipped):
        CancelOrder(repo, clock=fixed_clock("2026-01-01")).execute("o1", user_id="u1")
```

## 2. Integration test with Testcontainers
Java (JUnit 5 + Spring Boot):
```java
@SpringBootTest @Testcontainers
class OrderRepositoryIT {
  @Container @ServiceConnection
  static PostgreSQLContainer<?> db = new PostgreSQLContainer<>("postgres:16-alpine");
  @Autowired OrderRepository repo;

  @Test void findsOnlyOrdersOfOwner() {
    repo.save(order("o1", "alice")); repo.save(order("o2", "bob"));
    assertThat(repo.findAllByOwner("alice")).extracting(Order::id).containsExactly("o1");
  }
}
```
Python:
```python
@pytest.fixture(scope="session")
def pg():
    with PostgresContainer("postgres:16-alpine") as c:
        run_migrations(c.get_connection_url())
        yield c
```
Go: `testcontainers-go/modules/postgres`; Node: `@testcontainers/postgresql`; .NET: `Testcontainers.PostgreSql`.

If Docker is unavailable in the environment, say so; don't silently swap in SQLite for a Postgres app.

## 3. API test including authorization
```ts
it("returns 404 when user requests another user's order", async () => {
  const order = await seedOrder({ ownerId: "alice" });
  const res = await request(app).get(`/v1/orders/${order.id}`).set(authAs("bob"));
  expect(res.status).toBe(404);
});

it("returns 422 with field errors for invalid payload", async () => {
  const res = await request(app).post("/v1/orders").set(authAs("alice")).send({ quantity: -1 });
  expect(res.status).toBe(422);
  expect(res.body.errors).toContainEqual(expect.objectContaining({ field: "quantity" }));
});
```
Python (pytest + FastAPI TestClient; same idea with Django's test client):
```python
def test_returns_404_for_another_users_order(client, seed_order, auth_as):
    order = seed_order(owner_id="alice")
    res = client.get(f"/v1/orders/{order.id}", headers=auth_as("bob"))
    assert res.status_code == 404
```
Go (net/http/httptest, table-driven):
```go
func TestGetOrder_Authorization(t *testing.T) {
    srv := newTestServer(t)               // real router + test DB
    order := seedOrder(t, srv, "alice")
    cases := []struct{ name, user string; want int }{
        {"no token", "", http.StatusUnauthorized},
        {"other owner", "bob", http.StatusNotFound},
        {"owner", "alice", http.StatusOK},
    }
    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            req := httptest.NewRequest(http.MethodGet, "/v1/orders/"+order.ID, nil)
            if tc.user != "" { req.Header.Set("Authorization", tokenFor(t, tc.user)) }
            rec := httptest.NewRecorder()
            srv.ServeHTTP(rec, req)
            if rec.Code != tc.want { t.Fatalf("got %d, want %d", rec.Code, tc.want) }
        })
    }
}
```
Make a reusable matrix for each protected endpoint: no token → 401, wrong role → 403, other owner → 403/404, valid → 2xx.

## 4. Contract testing
- Consumer writes Pact tests describing expected requests/responses; pact files published to a broker; provider verifies them in CI.
- For public APIs, validate responses against OpenAPI in API tests and run schema-based fuzzing (Schemathesis) to find 500s.

## 5. Async / event tests
- Publish to a real broker container (Kafka, RabbitMQ, Redis); assert consumer side effects with polling: `await().atMost(5, SECONDS).untilAsserted(...)` or a `waitFor` helper.
- Test idempotency: deliver the same message twice; assert one side effect.
- Test poison messages go to a dead-letter queue.

## 6. Test data isolation
| Strategy | Pros | Cons |
|---|---|---|
| Transaction rollback per test | fast, clean | doesn't work when code under test opens its own transactions/threads |
| Truncate tables between tests | simple, reliable | slower on large schemas |
| Unique IDs/tenant per test | parallel-friendly | data accumulates; needs cleanup per run |
| Fresh container per suite | full isolation | slowest startup |

## 7. CI layout
1. Lint + type-check + unit (fast, every push)
2. Integration + API + contract (containers)
3. Security: SAST, dependency audit, secret scan
4. Build image; scan image (Trivy)
5. Deploy to staging → e2e smoke + DAST baseline (ZAP)
