# Render job: executes the notebooks and populates the on-disk cache.
#
# This is the only script that runs notebook code. It must never see `DOCUMENTER_KEY` —
# the two-job split (render without secrets / deploy without execution) is the whole
# point of the DocumenterSlate build model, and `.github/workflows/docs.yml` is where it
# is enforced. Locally, `just docs` runs the two steps in sequence.

import Pkg
Pkg.instantiate()   # `[sources]` in docs/Project.toml resolves GiacSlate + both plugins

using DocumenterSlate

include("slate_options.jl")

# The notebook environment has to be materialised before the isolated worker activates
# it: `_isolated_worker` calls `Pkg.activate(project_dir)` and nothing else, so whatever
# `notebooks/Project.toml` + `Manifest.toml` name must already be in the depot.
#
# It also has to be a *sibling* Manifest, which is why one is committed. Without it,
# DocumenterSlate copies `notebooks/Project.toml` alone into a temp directory and
# resolves there — and `[sources] GiacSlate = {path = ".."}`, a path relative to
# `notebooks/`, would then point at the temp directory's parent and fail to resolve.
run(`$(Base.julia_cmd()) --project=$(joinpath(REPO, "notebooks")) -e "using Pkg; Pkg.instantiate()"`)

statuses = collect_build_statuses() do
    build_slates(slate_options(:auto))
end

summary_path = get(ENV, "GITHUB_STEP_SUMMARY", nothing)
if summary_path !== nothing
    open(summary_path, "a") do io
        write_github_step_summary(io, statuses)
    end
end
