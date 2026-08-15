# Build options shared by `render.jl` and `make.jl`.
#
# This file exists because the two scripts MUST agree. DocumenterSlate's cache
# fingerprint is computed from the notebook bytes, the resolved environment, the Julia /
# KaimonSlate / DocumenterSlate versions, and a hash of the render-affecting options —
# which includes `fail_on_error` and `worker_environment`. If `make.jl` passed even one
# of them differently from `render.jl`, the fingerprint would differ, the cache lookup
# would miss, and `execution = :never` would abort the deploy job with a "cache miss"
# error that says nothing about the actual cause. Defining them once removes the
# opportunity to drift.
#
# `execution` is the one legitimate difference, so it is the argument: `:auto` for the
# render job (execute on a cache miss), `:never` for the deploy job (a cache miss is an
# error). It is not part of the fingerprint.

const REPO = dirname(@__DIR__)

function slate_options(execution::Symbol)
    return SlateBuildOptions(;
        # The notebooks live at the repository root, not under docs/: they are the very
        # files you open with `slate notebooks/giac_intro.jl`. The docs build reads them;
        # it does not keep a copy that would drift.
        source = joinpath(REPO, "notebooks"),
        output = joinpath(@__DIR__, "src", "notebooks"),
        cache_dir = joinpath(@__DIR__, "slate_cache"),
        slate_toml = joinpath(@__DIR__, "slate.toml"),
        execution = execution,
        # Not the strict default, because of one upstream defect (see UPSTREAM.md §1):
        # KaimonSlate registers its built-in widget kinds at module top level rather than
        # in `__init__`, so precompilation discards the registration and the kind
        # registry is empty at run time. A labeled `Select` then binds a bare `String`
        # instead of the documented `Choice`, and the two cells of `giac_intro.jl` that
        # read `fkey.value` raise `FieldError(String, :value)`. With `false`, the failure
        # is rendered on the page instead of aborting the whole build, and
        # `collect_build_statuses` still reports it in the CI job summary. Restore the
        # default `true` once the registration moves into `__init__` upstream.
        fail_on_error = false,
        # The parent process environment is not inherited; this is the explicit
        # allowlist. The notebooks print ζ, ωₙ and ✓ — without a UTF-8 locale the
        # captured output would come back mangled.
        worker_environment = Dict(
            "LANG" => "C.UTF-8",
            "LC_ALL" => "C.UTF-8",
        ),
    )
end
