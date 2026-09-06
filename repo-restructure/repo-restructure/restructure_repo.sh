#!/usr/bin/env bash
# Run this from the ROOT of your local clone of the Lewis-Gateway repo.
# It reorganizes the flat file layout into the structure described in the README.
# Uses `git mv` where possible so history is preserved; falls back to `mv` for
# anything not yet tracked by git.
set -e

gmv() {
  if git ls-files --error-unmatch "$1" >/dev/null 2>&1; then
    git mv "$1" "$2"
  elif [ -e "$1" ]; then
    mv "$1" "$2"
  fi
}

echo "Creating folders..."
mkdir -p Postman_Tests
mkdir -p SQL_Validation_Queries
mkdir -p cypress/e2e

echo "Moving Postman API test files (adjust the patterns below to match your actual filenames)..."
for f in API-PRC-*.yaml API-STK-*.yaml API-CRD-*.yaml; do
  [ -e "$f" ] && gmv "$f" "Postman_Tests/$f"
done

echo "Moving T-SQL scripts (adjust the pattern to match your actual filenames, e.g. .sql)..."
for f in SQL-REC-*.sql SQL-PRC-AUD-*.sql SQL-HYG-*.sql SQL-BI-*.sql; do
  [ -e "$f" ] && gmv "$f" "SQL_Validation_Queries/$f"
done

echo "Moving Cypress spec into cypress/e2e/..."
[ -e "lewis_happy_path2.cy.js" ] && gmv "lewis_happy_path2.cy.js" "cypress/e2e/lewis_happy_path2.cy.js"

echo "Done. Review with 'git status' before committing:"
echo "  git add -A"
echo "  git commit -m \"Reorganize repo into Postman_Tests / SQL_Validation_Queries / cypress structure\""
echo "  git push"
