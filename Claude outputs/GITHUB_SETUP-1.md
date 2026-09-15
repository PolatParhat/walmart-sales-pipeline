# Pushing the Walmart pipeline project to GitHub

Terraform is intentionally left out of this round - just `snowflake_sql/`,
`walmart_dbt/`, and the Tableau workbook for now. You can add `terraform/`
into the repo later the same way (drop the folder in, extend `.gitignore`
with the Terraform-specific lines, commit) whenever you're ready for it.

## 1. Get everything into one folder

You should end up with one project root (your existing `WalmartBIAnalysis`
folder) containing these pieces:

```
WalmartBIAnalysis/
  snowflake_sql/        # 01_database_and_schemas.sql through 08_monitoring_queries.sql
  walmart_dbt/          # the dbt project
  <your .twb/.twbx>     # the Tableau workbook, once you've saved it
```

If `snowflake_sql/` was downloaded separately earlier (as a zip, into your
Downloads folder or similar) and isn't already inside `WalmartBIAnalysis`,
move it in now so this is a single, self-contained project folder before
you turn it into a git repo.

## 2. Create a .gitignore BEFORE your first commit

This is the step that matters most - a few of the files this project
generates contain real account details, credentials, or just noisy build
output that doesn't belong in a shared repo. Create a file named
`.gitignore` at the root of `WalmartBIAnalysis` with this content:

```gitignore
# dbt build artifacts - regenerated on every run, not source
walmart_dbt/target/
walmart_dbt/logs/
walmart_dbt/dbt_packages/

# dbt connection profile - this should already live outside the project
# entirely (in ~/.dbt/profiles.yml per SETUP.md), but exclude it here too
# as a safety net in case a real copy ever ends up inside the project
profiles.yml

# Snowflake key-pair auth files - never commit private keys
*.p8
*.pem

# OS noise
.DS_Store
```

Notice what's **not** excluded: `profiles.yml.example`, and every
`.sql`/`.md` file with placeholders like `<your_snowflake_username>` -
those are exactly what makes the repo useful to someone reading it
(including future you), and they don't contain anything real.

When you're ready to add `terraform/` back in later, append these lines
to `.gitignore` before committing it (same reasoning as above - state and
cache files contain real resource IDs/ARNs and are machine-specific):

```gitignore
terraform/.terraform/
terraform/*.tfstate
terraform/*.tfstate.backup
terraform/terraform.tfvars
terraform/.terraform.lock.hcl
```

## 3. Double-check nothing sensitive is already sitting in the folder

Before the first commit, quickly look for anything that shouldn't be
there:

```bash
cd ~/WalmartBIAnalysis
find . -iname "*.p8" -o -iname "*.pem" -o -iname "profiles.yml"
```

If that command lists anything (other than files ending in
`.example`), either delete it from the project folder (if it's just a
stray copy) or confirm it's covered by `.gitignore` above before
proceeding.

## 4. Initialize git and make the first commit

```bash
cd ~/WalmartBIAnalysis
git init
git add .
git status   # review the list - confirm nothing from .gitignore shows up as "to be committed"
git commit -m "Initial commit: Walmart sales pipeline (S3 -> Snowflake -> dbt -> Tableau)"
```

If `git status` shows something you didn't expect (like `terraform.tfvars`
without the `.example`), stop and fix `.gitignore` before committing -
it's much easier to exclude a file before the first commit than to
scrub it out of git history afterward.

## 5. Create the GitHub repo

1. Go to [github.com/new](https://github.com/new) while signed in.
2. Repository name: something like `walmart-sales-pipeline`.
3. Leave "Initialize this repository with a README" **unchecked** -
   you already have local commits, and checking it creates a conflicting
   history you'd have to merge.
4. Choose **Public** or **Private** - public makes sense for a portfolio
   piece, as long as step 3 came back clean.
5. Click **Create repository**. GitHub shows you a page with commands
   for "...or push an existing repository from the command line" -
   that's the block you'll use next.

## 6. Connect and push

GitHub's page will show your exact URL, but it looks like:

```bash
git remote add origin https://github.com/<your_username>/walmart-sales-pipeline.git
git branch -M main
git push -u origin main
```

You'll be prompted to authenticate - GitHub no longer accepts your
account password for this; use a **Personal Access Token** instead
(GitHub will prompt you to create one, or generate it ahead of time at
Settings -> Developer settings -> Personal access tokens) or set up the
GitHub CLI (`brew install gh` -> `gh auth login`) and use `gh repo create`
instead of the manual steps above, which handles authentication for you.

## 7. Verify

Refresh the repo page on GitHub and confirm: `snowflake_sql/`,
`walmart_dbt/`, and your Tableau workbook are all there, and clicking
into any `.p8` file (if one somehow shows up in the file list) returns a
404 (because it was never committed) rather than showing real values.

## 8. Optional: a root-level README

Right now each sub-folder has its own README (`walmart_dbt/README.md`,
`snowflake_sql/README.md`), but there's no single top-level page
explaining the whole pipeline end to end. If you want, I can draft one
that ties Raw -> Silver -> Gold -> Tableau together with the
architecture decisions we made along the way (Snowpipe auto-ingest,
RBAC, incremental merge, SCD2 via snapshot) - useful for anyone (a
recruiter, a hiring manager) landing on the repo without this
conversation's context. Say the word and I'll write it.
