# Backend Observability, Performance and Resilience

## Observability
- **Structured logs** (JSON) with level, timestamp, request/correlation ID, user/tenant ID (not PII), and event name. Never log secrets, tokens, passwords, full card numbers.
- **Metrics**: RED (rate, errors, duration) per endpoint; queue depth/lag; DB pool usage.
- **Tracing**: OpenTelemetry propagation across services and queues.
- Health endpoints: liveness (process alive) and readiness (dependencies reachable).

## Performance and resilience
- Measure before optimizing; add a benchmark or load test (k6, Gatling, Locust, JMeter) for performance-sensitive changes.
- Cache with explicit TTL and invalidation strategy; never cache per-user data under shared keys.
- Bound everything: thread/connection pools, queue sizes, payload sizes, timeouts.
- Graceful shutdown: stop accepting work, drain in-flight requests/jobs.
