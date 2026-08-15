# ---------------------------------------------------------------------------
# Workarounds for upstream defects. Everything in this file exists only because
# a dependency is broken, and should be DELETED when it is fixed — see
# UPSTREAM.md, which names the fix and the condition for removal.
# ---------------------------------------------------------------------------

# UPSTREAM.md §1 — KaimonSlate 1.1.0 calls `_register_builtin_kinds!()` at module top
# level (`src/widgets.jl:503`) rather than from its `__init__`. That call populates
# `SlateExtensionsBase._KINDS`, a `const Dict` owned by a *different* module: top-level
# code runs at precompilation, the cross-module mutation is serialised into neither
# package's `.ji`, and nothing replays it on load. The kind registry is therefore empty
# in every ordinary process.
#
# The visible symptom is `@bind fkey Select(["sin(x)" => "sin x", …])` binding a bare
# `String` instead of the documented `Choice`, because `wrap_value` looks its `wrap` hook
# up by kind and finds nothing — so `fkey.value` raises `FieldError(String, :value)`.
# `coerce` and `reconcile` are equally inert, so no widget reconciles its value across a
# re-run either. This is not headless-only; a live Slate session is affected identically.
#
# GiacSlate is a natural place to repair it: every notebook here does `using GiacSlate`,
# and by then KaimonSlate is loaded (the notebook preamble imports it on line 1), so this
# runs before any `@bind` cell.

const _KAIMONSLATE = Base.PkgId(Base.UUID("f7b954f5-0334-4562-ac21-b005218ce1da"), "KaimonSlate")

"""
    _ensure_widget_kinds!() -> Bool

Re-run KaimonSlate's built-in widget-kind registration if precompilation dropped it
(UPSTREAM.md §1). Returns `true` when it actually registered something.

Deliberately conservative, because it reaches into another package's internals:

- it is a **no-op when the registry is already populated**, so it disappears by itself
  the day upstream moves the call into `__init__` — no version check to keep in sync;
- it does **not** load KaimonSlate. GiacSlate builds against the lean
  `SlateExtensionsBase` SDK and must not acquire a KaimonSlate dependency, so this only
  acts when KaimonSlate is *already* in the process, and returns `false` otherwise;
- every failure is swallowed to a `@debug`. A broken workaround for someone else's bug
  must never be the reason `using GiacSlate` fails.
"""
function _ensure_widget_kinds!()
    isempty(SlateExtensionsBase.widget_kinds()) || return false   # already registered
    Base.root_module_exists(_KAIMONSLATE) || return false          # not our business to load it
    try
        Base.root_module(_KAIMONSLATE).ReportEngine._register_builtin_kinds!()
    catch err
        # An upstream rename or refactor lands here. Silent by design: the notebooks then
        # behave exactly as they do today, no worse.
        @debug "GiacSlate: could not re-register KaimonSlate's widget kinds" exception = (err, catch_backtrace())
        return false
    end
    registered = !isempty(SlateExtensionsBase.widget_kinds())
    registered && @debug "GiacSlate: re-registered KaimonSlate's built-in widget kinds (UPSTREAM.md §1)"
    return registered
end
