# GiacSlate.jl — entry points. Run `just` with no arguments to list them.

default:
    @just --list

# Open a notebook in Kaimon Slate: `just slate giac_intro`.
slate name:
    slate notebooks/{{name}}.jl

# Instantiate the notebook environment (what `slate` and the docs build both use).
instantiate:
    julia --project=notebooks -e 'using Pkg; Pkg.instantiate()'

# Render the notebooks (executes them, fills docs/slate_cache), then build the site
# (executes nothing, consumes only that cache) — the same two steps the CI workflow runs
# as separate jobs, in sequence for a local build. `deploydocs` no-ops outside CI, so
# this never publishes.
docs:
    julia --project=docs docs/render.jl
    julia --project=docs docs/make.jl

# Re-render the notebooks only. Useful after editing a notebook: `just docs` afterwards
# will then be a pure cache hit.
render:
    julia --project=docs docs/render.jl

# Serve the built site locally.
serve:
    julia -e 'using LiveServer; serve(dir="docs/build")'
