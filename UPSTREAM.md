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

**Consequence** — before the workaround below, two cells of `notebooks/giac_intro.jl`
(`taylor_explorer` and `taylor_symbolic`) failed with `FieldError(String, :value)`. Less
visibly, `coerce` and `reconcile` were inert for all eleven kinds too, so no widget
reconciled its value across a re-run as documented.

**Workaround** — `GiacSlate._ensure_widget_kinds!` in `src/workarounds.jl`, called from
`GiacSlate.__init__`. Every notebook here does `using GiacSlate`, and KaimonSlate is
already loaded by then (the notebook preamble imports it on line 1), so the registry is
repaired before any `@bind` cell runs — headless and live alike. It is a no-op when the
registry is already populated, so it retires itself the day the upstream fix lands, with
no version check to keep in sync. With it in place, all four notebooks execute cleanly
under the strict `fail_on_error = true`.

**Fix** — move `_register_builtin_kinds!()` into `KaimonSlate.__init__()`, which already
exists at `src/KaimonSlate.jl:130`. Cross-module global state has to be established at
load time, not at precompile time.

**Delete when** — that fix lands upstream: delete `src/workarounds.jl`, its `include`,
and `GiacSlate.__init__`.

**Not a workaround** — changing `fkey.value` to `fkey` in the notebook. It would paper
over the symptom today and then break again the moment the registry is fixed and the
bind starts returning a `Choice`, as documented.

## 3. ECharts figures render as a raw `Dict` dump

**Where** — DocumenterSlate, `src/assets.jl`.

**What happens** — a cell whose value is a `KaimonSlate.ReportEngine.EChart` is written
into the page as its `text/plain` representation: the whole option `Dict`, data series
included. `_ASSET_MIME_EXTENSIONS` tracks only `image/png` and `image/svg+xml`, and
`EChart` is showable as neither — it is a live browser chart, and nothing renders it
server-side.

**Consequence here** — three cells (two in `giac_intro.jl`, one in `laplace_lesson.jl`)
emit tens of kilobytes of coordinate pairs where a figure belongs. It is why those two
pages need `size_threshold_ignore`. Pre-existing, not caused by defect 1's workaround —
though fixing that defect added the third instance, by making a cell that used to fail
succeed.

**Delete when** — either DocumenterSlate learns to skip or summarise a value it cannot
render, or something renders `EChart` to a static image. Neither is GiacSlate's to do.

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
