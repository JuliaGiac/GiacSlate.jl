module GiacSlate

# The lean Slate extension SDK — to_widget/auto_widget (the typed @bind seam), required_assets +
# __slate_frontend (lazy front-end delivery). GiacSlate depends only on this, never on KaimonSlate.
using SlateExtensionsBase

# Autograder framework: structs, combinators, and HTML score cards.
include("grader.jl")
# Lesson content + reference solutions; registers its sections at load time.
include("laplace_lesson.jl")
# MathLive `<math-field>` → GiacExpr bridge (math-keyboard input).
include("mathfield.jl")
# giac"…" macro, gmath/gdisplay for markdown, and the editor's conversion bridge.
include("inline_math.jl")
# Repairs for upstream defects — see UPSTREAM.md. Delete along with the defects.
include("workarounds.jl")

# Runs at load, which is the point: the state it repairs is cross-module global state that
# precompilation drops (UPSTREAM.md §1), so it cannot be established at precompile time —
# the very mistake being worked around.
function __init__()
    _ensure_widget_kinds!()
    return nothing
end

# The notebook only ever calls these. The front-end (the `Mathfield` renderer + the inline-math editor
# extension + its giac bridge handlers) wires itself up on `using GiacSlate` — no boot cell, no exports.
export grade, check, course_report, Mathfield, mathfield_to_giac,
       @giac_str, gmath, gdisplay, giac_src_to_tex, mathjson_to_giac_src

end # module GiacSlate
