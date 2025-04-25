# BipartiteFactorGraphs.jl Documentation

This directory contains the documentation for BipartiteFactorGraphs.jl, built with [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).

## Structure

- `make.jl`: Script that builds the documentation
- `src/`: Source files for the documentation
  - `index.md`: Home page
  - `api.md`: API reference
  - `usage.md`: Usage guide with examples
  - `benchmarks.md`: Performance benchmarks information

## Building Documentation Locally

To build the documentation locally:

```bash
make docs
```

To serve the documentation for development:

```bash
make docs-serve
```

The documentation will be served at http://localhost:5678.

## Documentation Dependencies

To install documentation dependencies:

```bash
make deps-docs
```

## Clean Documentation Build

To clean the documentation build:

```bash
make docs-clean
``` 