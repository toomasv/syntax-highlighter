# syntax-highlighter
Red syntax/expressions highligting

## Usage and limitations
1. Expressions highlighting works by default for predefined functions only. If UDF is evaluated in step mode, highlighting will work on these too (They are evaluated in default context; in-object evaluation TBD)
2. `op!` scope is correctly found when treated as argument. Arguments highlighting for `op!` itself (in "Expr" mode) is TBD
  - Partly done 17.01 (Left nested parens TBD)
3. Highlighting does not adapt to dialects (e.g. parse, VID, RTD). TBD
4. Editing:
  - First version 24.01
  - Font size and type changeable
  - Selection with keys, double-click, shift-click
  - Selection by dragging TBD
5. Resizing:
  - First version done 18.01
6. No error-handling. TBD
7. No comments :). TBD
8. Code evaluation: 
  - First draft done 18.01: In "Step" mode use "Eval" button to evaluate highlighted expression
  - Refining 7.02: Click "Construct". Then in step mode select expression and ctrl-click it to open refining panel... Works only for programs not in anonymous or path-named contexts.
9. Navigation:
  - By scroller (from start)
  - Simple wheeling done 18.01
  - Back-stepping added 19.01
  - Step-selection by mouse click 19.01
  - Simple search added 20.01. Pointing on element, choose "Show" from contextual menu. For navigation between highlighted elements, select "Next" or "Prev", use contextual menu or arrow-keys.
  - "Find" added to contextual menu 21.01. Next/prev find with buttons, contextual menu or arrow-keys.
  - Move "Step"-highlighted elements: buttons, menu and keys (down-arrow-key = "into" while stepping, enter = evaluate) 
10. Layout is done according to W10. It may show with defects on other platforms/versions.
11. Hovering worked initially for ~1.5 page only.
  - Now works throughout longer files too 25.01
12. Using `bold` in syntax highlighting style definitions has no effect on `caret-to-offset` calculations, which causes misplacement of hover-reactive boxes on layer above rich-text. Red bug?
