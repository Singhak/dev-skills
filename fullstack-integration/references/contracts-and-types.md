# Contracts and Generated Types

## Tooling by contract style
| Style | Contract | Client generation | Server verification | Breaking-change check |
|---|---|---|---|---|
| REST | OpenAPI 3.1 | openapi-typescript + openapi-fetch, orval, openapi-generator, Kiota, NSwag | response validation middleware, Schemathesis, Pact provider | oasdiff, openapi-diff |
| GraphQL | SDL schema | GraphQL Codegen (typed hooks/documents) | schema-first resolvers, persisted queries | GraphQL Inspector |
| tRPC / shared TS | router + Zod | inferred types | Zod parse at handler | type-check of consumers in monorepo |
| gRPC / Connect | `.proto` | buf generate | generated server stubs | `buf breaking` |

## Code-first vs schema-first
- Schema-first: write the spec, generate both sides. Best for multiple consumers and public APIs.
- Code-first: generate the spec from server annotations (FastAPI, NestJS Swagger, springdoc, Swashbuckle). Acceptable if the generated spec is committed, reviewed and diffed in CI.
Either way, the committed spec is the single source of truth the client is generated from.

## Breaking vs non-breaking
Non-breaking: add optional request field; add response field; add endpoint; add enum value **only if clients handle unknown values**.
Breaking: remove/rename field or endpoint; change type or format; make optional field required in request; remove enum value; change status codes or error format; tighten validation on existing inputs.

## Rollout order for a breaking need (expand/contract)
1. Server adds the new field/endpoint, keeps the old (expand).
2. Clients switch to the new one; deploy; wait for old clients (mobile!) to age out.
3. Monitor usage of the old field/endpoint (metrics/logs).
4. Remove old (contract) — in a later release.

## Sharing validation
- TS monorepo: one Zod schema → used by server handler, form resolver and inferred types.
- Different languages: JSON Schema from OpenAPI → client validator (Ajv/Zod via openapi-zod-client) and server validator. Server stays authoritative.
