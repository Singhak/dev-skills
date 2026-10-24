# Project Discovery — Finding Commands & Conventions

Always prefer the project's own scripts (Makefile, `package.json` scripts, `justfile`, `Taskfile`, CI workflow files) over generic commands. CI config (`.github/workflows`, `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml`) is the most reliable source of the true gate commands.

| Ecosystem | Signals | Typical commands |
|---|---|---|
| Node/TS | package.json, lockfile type | `npm ci` / `pnpm i --frozen-lockfile` / `yarn --immutable`; `npm run lint`, `npm run typecheck` (`tsc --noEmit`), `npm test` (Jest/Vitest), `npx playwright test` |
| Python | pyproject.toml, requirements*.txt, uv.lock, poetry.lock | `uv sync` / `poetry install` / `pip install -e .[dev]`; `ruff check`, `ruff format`, `mypy`/`pyright`, `pytest` |
| Java/Kotlin | pom.xml, build.gradle(.kts) | `./mvnw verify` / `./gradlew build`; unit via Surefire/`test`, integration via Failsafe/`integrationTest` |
| Go | go.mod | `go build ./...`, `go vet ./...`, `golangci-lint run`, `go test ./... -race` |
| Rust | Cargo.toml | `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test` |
| .NET | *.sln, *.csproj | `dotnet build`, `dotnet format --verify-no-changes`, `dotnet test` |
| Ruby | Gemfile | `bundle install`, `rubocop`, `bundle exec rspec` |
| PHP | composer.json | `composer install`, `phpstan`, `vendor/bin/phpunit` / `pest` |

Also check:
- `.editorconfig`, linter configs, `CONTRIBUTING.md`, `AGENTS.md`/`CLAUDE.md` for agent-specific rules
- `docker-compose.yml` for local dependencies needed by integration tests
- Existing test folder layout and naming (`*.test.ts`, `test_*.py`, `*_test.go`, `*Test.java`) — copy it
