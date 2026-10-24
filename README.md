# Security Review

A Ruby on Rails web app that replaces the department's Excel/Word security review process. Projects move through two security gates, testers record results against a baseline control library, and findings with evidence are captured in one place. Summaries and scores are computed, never typed in.

> **Status:** pre-implementation. The design is agreed (23 Oct 2026) and the build is sequenced into steps (see [Build plan](#build-plan)). Update this README as decisions change.

## Stack

- Ruby on Rails **8.1.4** (all code and references assume this version)
- PostgreSQL
- Rails 8 built-in authentication
- Active Storage for evidence uploads
- Rails conventions only ("the Rails way")

## How it works

### Project lifecycle

```
design -> design_review (gate 1) -> development -> security_testing (gate 2) -> live
```

- **Gate 1** outcome: forward to development, or return to the solutions architect.
- **Gate 2** outcome: go live, or return to the developers.
- Go-live is the end of what the app tracks.
- The same baseline checklist is used at both gates. Controls that cannot be tested at design are marked N/A.
- Each return and resubmission creates a new assessment (round + 1). Earlier rounds stay as read-only history.

### Rules

1. Every assessment gets a baseline checklist, created automatically from the control library when the assessment starts. All results begin as `pending`.
2. Every vulnerability needs an evidence pack: a control that is `failed` or `partial` needs at least one finding, and each finding needs at least one piece of evidence (a screenshot with a caption).
3. Forward is blocked while any control is `pending`, or any failed/partial control lacks a finding with evidence.
4. Open Critical failures should never go live, but the tester makes the decision. The department head may override with mandatory comments; the override records who approved it and when.
5. The summary is computed, never stored. Score = passed / (passed + failed + partial). N/A and pending are excluded from the score; pending still blocks a decision.
6. Domain status labels use admin-configurable thresholds. Starting values: >= 80% On Track, >= 50% In Progress, otherwise Attention.

### Roles

| Role | Responsibility |
|---|---|
| Solutions architect | Owns design; receives returned projects with findings and evidence |
| Developer | Owns development; receives returned projects with findings and evidence; resubmits |
| Security tester | The only role that records results, findings and outcomes |
| Department head | May approve the Critical override |
| Reviewer / auditor | Read-only access to summaries and evidence packs |

Open question: whether developers and auditors get their own logins (assumed yes).

## Data model (proposed)

| Model | Purpose |
|---|---|
| User | Login and role enum |
| Project | The application moving through the gates; stage enum; architect/developer assignments |
| Domain | Section of the control library; unique integer `number` |
| Control | Reusable baseline control; integer `sequence` unique within its domain; OWASP/CWE/NIST refs; default severity; `retired_at` |
| Assessment | One security check of a project; gate, round, tester, scope, outcome, dates |
| ControlResult | A control's result in an assessment; status, severity, comments, owner |
| Finding | A vulnerability in the evidence pack; belongs to a control result; category, test objective, observations |
| Evidence | Screenshot with caption (Active Storage) |
| Override | Department head's Critical exception: approver, comments, timestamp |

### Numbering

Controls are numbered hierarchically (domain 1 -> controls 1.1 ... 1.n). Numbers are stored as two integers and the reference (for example `1.10`) is derived for display, which avoids the spreadsheet corruption where "1.10" was read as 1.1. Numbers are permanent: new controls take the next free number, retired controls are hidden from new assessments and their numbers are never reused. Findings link to controls by database ID, never by the reference text.

### Design principles

- Statuses, severities, outcomes and roles are database enums.
- Scores and summaries are calculated on demand.
- Scope is one field on the assessment, not a per-control column.
- Evidence is uploaded files with captions.
- Gate rules are enforced in code as guarded stage transitions.
- Round history is preserved for reviewers and auditors.

## Sample data

The existing documents are sample data and rule validation only; the app is not constrained by the manual design.

| File | Role |
|---|---|
| API Baseline Security Report.csv | Seed for the control library (60 controls, 8 domains) |
| USSD Security Report Summary.csv | Reference for the computed domain summary |
| CRM_Security_Assessment_Evidence_Pack.docx | Model for the evidence pack (8 findings, different system) |

The demo assessment should reproduce the sample domain scores: Authentication 29%, Authorization 0%, Data Exposure 67%, Rate Limiting 33%, Secure Configuration 90%, Input Validation 88%, Auditing & Logging 0%, API Inventory 100%.

## Getting started

Prerequisites: Ruby (version matching Rails 8.1.4), PostgreSQL, Git.

```sh
rails _8.1.4_ new security_review --database=postgresql --skip-kamal
cd security_review
bin/rails db:create db:migrate
bin/rails server
```

> The app has not been scaffolded yet; these commands are Step 00 of the build plan. Once the repository exists, replace them with `git clone` and `bin/setup`.

### Checks

```sh
bin/rails test
bin/rubocop
bin/brakeman
```

All three must pass before a PR is merged.

## Build plan

The app is built in sequenced steps, each a normal Rails loop: branch -> migration -> model + tests -> console check -> route -> controller -> view -> integration test -> checks -> commit -> PR -> merge -> tag.

| Step | Content |
|---|---|
| 00 | Environment, repo, CI, PR template |
| 01 | Authentication and five roles |
| 02 | Control library: Domain and Control, permanent numbering, CRUD |
| 03 | Importer and seeds from the baseline CSV |
| 04 | Projects with stage and assignments |
| 05 | Assessments and control results |
| 06 | Testers record results |
| 07 | Findings and evidence (Active Storage) |
| 08 | Forward/return decisions, stage transitions, department head override |
| 09 | Computed summary, admin thresholds, demo assessment |
| 10 | Hardening checklist and backlog |

Each step has a guide in `docs/steps/NN-name.md` and an entry in `docs/DEVELOPMENT_LOG.md`.

## Git conventions

- `main` is always green.
- One branch per step: `step/NN-name`.
- Small commits (migration + schema, model + tests, routes + controller + views, integration tests).
- Merge commits, not squash; tag `step-NN` after merge.
- Commit `db/schema.rb` with its migration; never edit a merged migration.
- Never commit `config/master.key`.

## Backlog

Per-project permissions, user management screens, exports, notifications (tracked in step 10).

## Documentation

- `Security_Review_App_Design_Baseline.md`: rules, roles, data model, numbering
- `Build_Plan_and_Git_Workflow.md`: steps and git conventions