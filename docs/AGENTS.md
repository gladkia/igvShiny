# AI Assistant Instructions for igvShiny

This is an R package for **Bioconductor**. All code changes must adhere
to Bioconductor standards.

## Workflow & Standards

1.  **Documentation (Roxygen2)**: Use `roxygen2` for all R
    documentation. When modifying `.R` files in the `R/` directory
    (adding/changing functions or docs), you must run
    [`devtools::document()`](https://devtools.r-lib.org/reference/document.html)
    to update the `man/` directory and `NAMESPACE` file. Do not edit
    `NAMESPACE` or `.Rd` files manually.
2.  **Testing**: This package uses the `testthat` framework for testing.
    Tests are located in `tests/testthat/`. Any new feature or bug fix
    must be accompanied by appropriate tests. Run tests via `make test`
    or
    [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
    to verify changes.
3.  **Continuous Integration / Checking**: The preferred method for
    running comprehensive checks (R CMD check, tests, linters, etc.) is
    via
    [`gDRstyle::checkPackage()`](https://gdrplatform.github.io/gDRstyle/reference/checkPackage.html).
    Ensure the package passes these checks before finalizing any
    commits.
4.  **Dependencies**: R dependencies are defined in the `DESCRIPTION`
    file. If a new package is required, add it to the appropriate
    section (`Imports:`, `Suggests:`, `Depends:`).
5.  **Front-end / JavaScript**: As an `htmlwidgets` package, the
    JavaScript code is typically located in `inst/htmlwidgets/` or a
    similarly configured directory. Ensure any JS modifications are
    properly synchronized with the R widget bindings.
6.  **General Make Targets**: The `makefile` provides useful targets:
    `make roxy` (document), `make test` (run testthat tests),
    `make demo` (run the shiny demo app), and `make all`.

## Automated review — what it does and does not catch

Pull requests are reviewed by **CodeRabbit** (`.coderabbit.yaml`,
profile `assertive`). Treat it as editorial review: style, obvious logic
slips, missing tests and docs. It reads the diff, so it cannot catch the
class of bug that has actually hurt this package — the semantics of the
bundled `igv.js`. Finding those means reading
`inst/htmlwidgets/lib/igv-*.js` directly, and that path is filtered out
of review on purpose (~8.7 MB of third-party code).

Two conventions exist for the bot’s benefit:

- PRs use `Related: #NNN`, not `Fixes #NNN` — see
  `.github/pull_request_template.md`. Auto-closing has hidden
  partly-finished work before (#36), but the reference still has to be
  there or CodeRabbit’s linked-issue checks silently skip.
- Broken external assets are checked deterministically, not by an AI
  reviewer: `.github/workflows/asset-url-check.yml` runs
  `.github/scripts/check-asset-urls.sh` weekly and files an issue when a
  genome, index or demo track URL stops resolving. Run the script by
  hand after touching any URL in `R/`, `inst/demos/` or
  `inst/htmlwidgets/igvShiny.js`.

If a `CLAUDE.md` file exists in the repository root, read it too. Some
contributors keep longer local notes there; it is untracked, so its
absence is normal and nothing depends on it.
