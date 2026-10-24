# CI/CD and Container Templates

## GitHub Actions — PR pipeline (adapt to GitLab CI, Azure Pipelines, Jenkins, CircleCI)
```yaml
name: ci
on: [pull_request]
permissions: { contents: read }
jobs:
  verify:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env: { POSTGRES_PASSWORD: test }
        ports: ["5432:5432"]
        options: --health-cmd pg_isready --health-interval 5s --health-retries 10
    steps:
      - uses: actions/checkout@v4          # pin third-party actions by SHA in real repos
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npm run lint && npm run typecheck
      - run: npm test -- --coverage
      - run: npm run test:integration
        env: { DATABASE_URL: postgres://postgres:test@localhost:5432/postgres }
      - run: npm audit --audit-level=high
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@v2
      - run: pipx run semgrep scan --config auto --error
```

## Main-branch delivery outline
```
build image (tag = git SHA) → scan (trivy image --exit-code 1 --severity HIGH,CRITICAL)
→ push → deploy staging → smoke + e2e → [approval] → deploy prod (same SHA)
→ post-deploy smoke → auto-rollback on failure
```
Use OIDC (`permissions: id-token: write`) to assume a cloud role; no static cloud keys in secrets.

## Dockerfile — Node example (same principles for any language)
```dockerfile
# syntax=docker/dockerfile:1
FROM node:22-slim AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:22-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM gcr.io/distroless/nodejs22-debian12 AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
USER nonroot
EXPOSE 8080
CMD ["dist/server.js"]
```
Python: `python:3.12-slim` builder with `uv sync --frozen --no-dev`, copy `.venv` into a slim/distroless runtime, `USER 10001`. Java: build with Maven/Gradle stage, run on `eclipse-temurin:21-jre` or distroless java, consider layered jars. Go: `CGO_ENABLED=0` static binary on `gcr.io/distroless/static`.

`.dockerignore` minimum: `.git`, `.env*`, `node_modules`, `**/__pycache__`, `coverage`, `tests`, `*.log`, `Dockerfile*`, IaC state files.

## Kubernetes probes and shutdown
```yaml
livenessProbe:  { httpGet: { path: /health/live,  port: 8080 }, periodSeconds: 10, failureThreshold: 3 }
readinessProbe: { httpGet: { path: /health/ready, port: 8080 }, periodSeconds: 5,  failureThreshold: 3 }
startupProbe:   { httpGet: { path: /health/live,  port: 8080 }, failureThreshold: 30, periodSeconds: 2 }
terminationGracePeriodSeconds: 30
securityContext: { runAsNonRoot: true, readOnlyRootFilesystem: true, allowPrivilegeEscalation: false }
resources: { requests: { cpu: 100m, memory: 256Mi }, limits: { memory: 512Mi } }
```

## docker-compose for local dev
Mirror production services (DB, cache, broker) with pinned versions and healthchecks; app reads the same env var names as production.
