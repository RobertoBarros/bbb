# AGENTS.md

## Project

- Rails 8.1 application running on Ruby 4.0.6.
- SQLite database with schema tracked in `db/schema.rb`.
- Hotwire, Stimulus, Importmap, and Tailwind CSS.
- Minitest for controller, model, integration, and system tests.
- GitHub Actions is defined in `.github/workflows/ci.yml`.
- Votes are accepted asynchronously: `VotesController` enqueues
  `RegisterVoteJob` in Redis/Sidekiq, which validates and persists the vote in
  SQLite. A `202 Accepted` response confirms only that the submission was
  queued; it does not confirm that the vote will be persisted.
- `Vote` is the source of truth; `Candidacy#votes_count` is a periodically
  refreshed read projection. Redis must be available to run the Sidekiq
  integration and configuration tests.

## Working principles

- State assumptions when requirements are ambiguous or when alternatives have materially different outcomes.
- Prefer the smallest change that completely solves the requested problem.
- Do not add speculative abstractions, configuration, error handling, or dependencies.
- Keep edits surgical. Do not reformat, refactor, rename, or clean up unrelated code.
- Preserve all existing user changes, including untracked files. Never discard or overwrite them without explicit approval.
- Match the conventions and style of the surrounding Rails code.
- Every changed line must trace directly to the request.
- Define a concrete success criterion and verify it before reporting completion.

## Rails conventions

- Follow standard Rails file placement and naming.
- Prefer RESTful routes and conventional controller actions.
- Change the database through migrations; regenerate and commit `db/schema.rb`.
- Keep controllers thin. Put domain behavior in the appropriate model or focused object only when needed.
- Use existing application helpers and partials before introducing new abstractions.
- Add or update the narrowest test that proves the requested behavior.
- Use `assert_response`, `assert_select`, and model assertions for observable behavior rather than implementation details.
- Keep `test/system/` tracked so the CI system-test job can run even when it contains no tests.

## Verification

Run the narrowest relevant check first, then broaden according to risk:

```sh
bin/rails test path/to/test_file.rb
bin/rails test
bin/rails test:system
bin/rubocop
```

For database-related changes, prepare the test database before testing:

```sh
RAILS_ENV=test bin/rails db:test:prepare
```

Use `bin/ci` for a full local CI pass when the change is broad or touches shared configuration. Security-specific changes may also require:

```sh
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
```

Report exactly which checks ran and any validation that could not be performed. Do not claim GitHub Actions passed until the remote run completes successfully.

## Git and external actions

- Inspect `git status --short` before editing and before handoff.
- Do not commit, push, open pull requests, modify secrets, or trigger deployments unless explicitly requested.
- Do not edit generated or vendored files unless the requested workflow requires it.
