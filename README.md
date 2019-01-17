# syntax-highlighter
Red syntax/expressions highligting

## Current limitations / problems
1. Expressions highlighting works for predefined functions only. User-defined functions are TBD.
2. `op!` scope is correctly found when treated as argument. Arguments highlighting for `op!` itself is TBD.
3. Its's not editable. TBD
4. Not resizable. TBD
5. Layout is done according to W10. It can show with defects on other platforms/versions.
6. Hovering works for limited range. After ~1.5 pages hovering stops working. Reason is not yet clear. Can be a bug or something wrong with my code.
7. Using `bold` in syntax highlighting style definitions will cause bias in `caret-to-offset` calculations and misplacement of hover-reactive boxes on layer above rich-text. Bug?
