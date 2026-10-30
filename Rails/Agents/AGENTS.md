# AGENTS.md

Guidance for AI agents working in this repository.

## Stack

- **Ruby** 4.0.9 (`.ruby-version`), **Rails** 8.1 (`8-1-stable` branch from GitHub)
- **Database:** SQLite (`storage/*.sqlite3`). Production splits into `primary`, `cache`, `queue`, and `cable` databases.
- **Infrastructure:** Solid Queue (jobs), Solid Cache, Solid Cable — no Redis
- **Frontend:** Hotwire (Turbo + Stimulus) via importmap — no Node/npm build step
- **Styling:** Tailwind CSS via `tailwindcss-rails` (`app/assets/tailwind/application.css`)
- **Assets:** Propshaft
- **Tests:** Minitest with fixtures, Capybara + Selenium for system tests
- **Deploy:** Kamal (`config/deploy.yml`) + Thruster
- **Linting/security:** RuboCop (`rubocop-rails-omakase`), Brakeman, bundler-audit, importmap audit

Stick with what's here. Don't introduce new gems or tools (RSpec, FactoryBot, Fabrication, Devise, service-object frameworks, Node bundlers, Redis) without asking first.

## Commands

```sh
bin/setup            # install deps, prepare db
bin/dev              # run web server + Tailwind watcher (Procfile.dev)
bin/rails test       # unit/integration tests
bin/rails test test/models/foo_test.rb   # single file
bin/rails test:system                    # system tests
bin/rubocop -A path/to/file.rb           # lint + autocorrect
bin/brakeman --quiet --no-pager          # security scan
bin/ci               # full CI pipeline (config/ci.rb)
```

`bin/ci` runs setup, RuboCop, bundler-audit, importmap audit, Brakeman, the test suite, and a seed replant. It must pass before work is considered done.

## Code style

**Read `STYLE.md` before writing code.** It's the 37signals (Fizzy) style guide. Key points:

- Expanded conditionals over guard clauses (early `return` only at the top of a non-trivial method)
- Method order: class methods → public (`initialize` first) → private, then by invocation order
- `private` methods indented under the modifier, no blank line after it
- `!` only when a non-bang counterpart exists
- RuboCop omakase rules; don't edit `.rubocop.yml` to silence offenses

## Architecture

Vanilla Rails: thin controllers calling a rich domain model.

- **REST only.** When an action doesn't fit a CRUD verb, add a new resource (`resource :closure`) instead of a custom action (`post :close`).
- **No service layer by default.** Put behavior in models and model concerns (`app/models/<model>/<trait>.rb`, e.g. `Card::Closeable`). Plain Ruby objects are fine when justified, but don't treat them as a special layer.
- **Jobs stay shallow.** Jobs delegate to model methods. Use `_later` for methods that enqueue and `_now` for the synchronous version.
- **State as records** (`has_one :closure`) over boolean columns when who/when matters.
- **Validate on the server.** Models are the source of truth; re-render with Turbo instead of adding client-side validation.
- Use `Time.current` (not `Time.now`), eager-load to avoid N+1s, and put user-facing strings in I18n.

## Frontend

- Default to Turbo Drive; use Turbo Frames/Streams for partial updates.
- Stimulus controllers live in `app/javascript/controllers/` and auto-register via `pin_all_from`. After adding one, the Stimulus LSP may falsely report it as invalid until restart. Ignore that.
- Pin JS packages with `bin/importmap pin <pkg>`, not npm.
- Tailwind utilities only: no inline styles or arbitrary values. Include `dark:` variants and make layouts responsive.

## Testing

- Every new or changed model, controller, job, or mailer ships with tests in the matching `test/` path.
- Use **fixtures** (`test/fixtures/*.yml`). **Never modify existing fixtures** — add a new one when nothing fits, because changing shared fixtures breaks other tests.
- After fixture changes, run the full suite, not only the files you touched.
- Freeze time with `travel_to` in date-sensitive tests (the suite runs in parallel).

## Database

- SQLite: be careful with features like concurrent indexes or certain `ALTER TABLE` operations that other databases support.
- On tables with data, add NOT NULL or unique columns in steps: add nullable → backfill → add the constraint.
- Production uses multiple databases. Use the namespaced tasks there (`db:rollback:primary`).
- Restart the dev server after migrations that add columns (especially enum-backed ones).

## Git

- Work on a branch. Confirm the commit message with the user before committing.
- Never use `--no-verify`.

### General instructions

- Use imperative mood (command form) for all responses.
- Use a technical, professional tone appropriate for development teams.
- Keep all responses brief and to the point, maximum 1–2 sentences.

#### Commit messages

- Keep commit messages under 50 characters total; prioritize clarity over completeness.
- Write commit subjects in imperative mood (e.g., "Add", "Fix", "Update").
- Describe what was changed and why, not how it was implemented. Example: `fix: resolve login timeout to improve UX`

#### Explaining changes

- Explain both technical changes and business/user impact for each commit in simple terms.
- Format explanations as bullet points, one per major change or file modified.
- Always mention which components, modules, or areas of the codebase were affected.
- Explain technical concepts in simple terms that junior developers can understand.

#### Stash messages

- Start stash messages with action verbs: "Adding", "Fixing", "Updating", "Removing", "Refactoring".

#### Pull requests

- Include a "How to Test" section with specific steps to verify the changes.
- Include a "Breaking Changes" section if any exist, clearly explaining impact and migration steps.
- Include a "Review Focus" section highlighting specific areas or concerns for reviewers to examine.

#### Conflict resolution

- Always explain why you chose to keep, modify, or merge conflicting changes: "Kept incoming changes because...".
- Briefly describe what each conflicting branch was trying to accomplish before explaining the resolution.
- Use clear language: "Resolved by accepting our changes", "Resolved by accepting their changes", "Resolved by combining both approaches".

#### Composing commits

- Each commit should represent one logical change that could be reverted independently without breaking functionality.
- Never mix refactoring, formatting, or cleanup changes with new features or bug fixes in the same commit.
- Order commits logically so each builds on the previous one, making the history readable and bisect-friendly.

## Current state

The app is a fresh Rails 8.1 skeleton with no domain models, routes, or authentication yet (`bcrypt` is commented out in the Gemfile). When authentication is needed, use the Rails 8 generator (`bin/rails generate authentication`), not Devise.
