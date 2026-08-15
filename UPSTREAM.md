# Upstream defects

Defects in dependencies that GiacSlate has to work around. Each entry says what breaks,
what the workaround is, and what should be deleted once the defect is fixed.

## 1. The built-in widget kinds are never registered at run time

**Where** — KaimonSlate 1.1.0, `src/widgets.jl:503`.

**What happens** — `_register_builtin_kinds!()` is called at **module top level**:

```julia
_register_builtin_kinds!()   # widgets.jl:503, outside any __init__
```

It populates `SlateExtensionsBase._KINDS`, a `const Dict` owned by a *different* module.
Top-level code runs during precompilation only, and a mutation to another package's
global is serialised into neither package's `.ji` cache. Nothing replays it on load, so
the registry comes up empty in every ordinary process:

```
$ julia --project=notebooks -e 'using KaimonSlate;
    println(KaimonSlate.ReportEngine.SlateExtensionsBase.widget_kinds())'
String[]

$ julia --compiled-modules=no --project=notebooks -e '...same...'
["button", "checkbox", "multicheck", "multiselect", "number", "playhead",
 "radio", "select", "slider", "tableselect", "toggle"]
```

The rest follows mechanically. `Select` built from `value => label` pairs correctly sets
`params["labeled"] = true`, and `_do_bind` correctly ends in `wrap_value(w, val)`
(`widgets.jl:533`) — but `wrap_value` looks the `wrap` hook up by kind, finds an empty
registry, and returns the value untouched. So `@bind fkey Select(…)` binds a bare
`String` where the contract says `Choice`, and `fkey.value` — which is what
`notebooks/giac_intro.jl` writes, correctly — raises `FieldError(String, :value)`.

Registering the kinds by hand restores the documented behaviour:

```julia
julia> KaimonSlate.ReportEngine._register_builtin_kinds!()
julia> Core.eval(m, :(@bind fkey Select(["sin(x)" => "sin x"]; label = "f")));
julia> Core.eval(m, :fkey)
Choice{String}("sin(x)", "sin x")     # and fkey.value == "sin(x)"
```

**This is not a headless-only defect.** The registry is empty in *any* process that
loads KaimonSlate from its precompile cache, so a live Slate session is affected
identically. It happens to surface here because the documentation build is the thing
that executes these cells in CI.

**Consequence here** — two cells of `notebooks/giac_intro.jl` (`taylor_explorer` and
`taylor_symbolic`) fail. The other three notebooks execute cleanly; 93 cells in total.

**Workaround** — `docs/slate_options.jl` sets `fail_on_error = false`, so the two cells
render with their error on the page instead of aborting the whole build.
`collect_build_statuses` still reports the failure in the CI job summary.

**Fix** — move `_register_builtin_kinds!()` into `KaimonSlate.__init__()`, which already
exists at `src/KaimonSlate.jl:130`. Cross-module global state has to be established at
load time, not at precompile time.

**Delete when** — that fix lands upstream. Then restore the strict
`fail_on_error = true`, which is DocumenterSlate's own default and the setting you want
for catching real breakage.

**Not a workaround** — changing `fkey.value` to `fkey` in the notebook. It would paper
over the symptom in both contexts today and then break again the moment the registry is
fixed and the bind starts returning a `Choice`, as documented.

## 2. Reproducible archives need GNU tar

**Where** — DocumenterSlate, `src/distribution.jl`.

**What happens** — the reproducible `.tar.gz` bundle is built with
`tar --sort=name --mtime=@0 --owner=0 --group=0 --mode=... --format=ustar`. macOS ships
bsdtar, which rejects `--sort`, `--mtime`, `--mode`, `--owner` and `--group`, so
`build_slates` fails on the first notebook with `Option --sort=name is not supported`.

**Consequence here** — `just docs` does not work out of the box on macOS.

**Workaround** — none committed. CI runs on `ubuntu-latest`, which has GNU tar, so the
published site is unaffected. To build locally on macOS, install GNU tar
(`brew install gnu-tar`) and put its `gnubin` directory ahead of `/usr/bin` on `PATH`.

**Delete when** — DocumenterSlate builds the archive with Julia's own `Tar` stdlib, or
detects bsdtar and passes its equivalent flags.
