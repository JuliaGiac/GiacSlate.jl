# Upstream defects

Defects in dependencies that GiacSlate has to work around. Each entry says what breaks,
what the workaround is, and what should be deleted once the defect is fixed.

## 1. A labeled `Select` binds a `Choice` live but a bare value headlessly

**Where** — KaimonSlate, `src/widgets.jl`.

**What happens** — `Select(options)` built from `value => label` pairs sets
`params["labeled"] = true`, whose documented meaning in the source is "bind a `Choice`
(value + label) rather than the bare value". So in a live session the bound variable is
a `Choice`, and `fkey.value` is the correct way to read it — which is what
`notebooks/giac_intro.jl` does.

But `Widget.default` is computed by `_opt_default`, which returns the bare value:

```julia
julia> mod = Module(:T); KaimonSlate.standalone!(mod; dir = pwd());
julia> Core.eval(mod, :(@bind fkey Select(["sin(x)" => "sin x"]; label = "f(x)")));
julia> typeof(Core.eval(mod, :fkey))
String
```

`KaimonSlate.standalone!` — the headless path DocumenterSlate executes notebooks
through — binds that default. So the same cell that works in the browser raises
`FieldError(String, :value)` when executed headlessly.

**Consequence here** — two cells of `notebooks/giac_intro.jl` (`taylor_explorer` and
`taylor_symbolic`) fail during the documentation build, and only there. The other three
notebooks execute cleanly, 93 cells in total.

**Workaround** — `docs/slate_options.jl` sets `fail_on_error = false`, so the two cells
render with their error on the page instead of aborting the whole build.
`collect_build_statuses` still reports the failure in the CI job summary.

**Delete when** — `standalone!` binds a `Choice` for a labeled `Select`, matching the
live path. Then restore the strict `fail_on_error = true`, which is DocumenterSlate's
own default and the setting you want for catching real breakage.

**Not a workaround** — changing `fkey.value` to `fkey` in the notebook. That would fix
the headless build and break the live notebook, which is the wrong trade: the notebook
exists to be used in Slate.

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
