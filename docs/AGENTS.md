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
