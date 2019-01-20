# syntax-highlighter
Red syntax/expressions highligting

## Current limitations / problems
1. Expressions highlighting works for predefined functions only. User-defined functions are TBD
2. `op!` scope is correctly found when treated as argument. Arguments highlighting for `op!` itself is TBD
  * Partly done 17.01
3. If function is in beginning of block or parens, then block scope is shown on hovering, not expression scope. TBD
4. Highlighting does not adapt to dialects (e.g. parse, VID, RTD). TBD
5. Its's not editable. TBD
6. Not resizable. TBD
  * First version done 18.01
7. No error-handling. TBD
8. No comments :). TBD
9. No code execution. Also incremental execution TBD. 
  * First draft done 18.01. (In "Step" mode use "Eval" button to evaluate highlighted expression)
10. Navigation by scroller only. Wheeling and arrow-nav TBD. 
  * Simple wheeling done 18.01
  * Back-stepping added 19.01
  * Step-selection by mouse click 19.01
  * Simple search added 20.01. Use contextual menu in "Help" mode. Pointing on element, choose "Show". For navigation between highlighted elements, select "Next" or "Prev".
11. Layout is done according to W10. It can show with defects on other platforms/versions.
12. Hovering works for limited range. After ~1.5 pages hovering stops working. Reason is not yet clear. Can be a Red bug or something wrong with my code.
13. Using `bold` in syntax highlighting style definitions has no effect on `caret-to-offset` calculations, which causes misplacement of hover-reactive boxes on layer above rich-text. Red bug?
