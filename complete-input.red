Red [
	Description: {Adjusted to work with multilne text}
]
red-complete-ctx/complete-input: func [
    str [string!] 
    console? [logic!] 
    /local 
    word ptr result sys-word delim? len insert? 
    start end delimiters d w change?
] bind [
    has-common-part?: no 
    result: make block! 4 
    delimiters: charset [#"^/" #"^-" #" " #"[" #"(" #":" #"'" #"{"] 
    delim?: no 
    insert?: not tail? str 
    len: (index? str) - 1 
    end: str 
    ptr: head str ;str:
    word: find/reverse/tail/part str delimiters len 
    if all [word (index? ptr) < (index? word)] [ptr: word]
    either head? ptr [start: head str] [start: ptr delim?: yes] 
    word: copy/part start end 
    unless empty? word [
        case [
            all [
                #"%" = word/1 
                1 < length? word
            ] [
                append result 'file 
                append result red-complete-file word console?
            ] 
            all [
                #"/" <> word/1 
                ptr: find word #"/" 
                #" " <> pick ptr -1
            ] [
                append result 'path 
                append result red-complete-path word console?
            ] 
            true [
                append result 'word 
                foreach w words-of system/words [
                    if value? w [
                        sys-word: mold w 
                        if find/match sys-word word [
                            append result sys-word
                        ]
                    ]
                ] 
                if ptr: find result word [swap next result ptr] 
                if console? [common-substr next result]
            ]
        ]
    ] 
    if console? [result: next result] 
    if all [console? any [has-common-part? 1 = length? result]] [
        if word = result/1 [
            unless has-common-part? [clear result]
        ] 
    ] 
    result
] red-complete-ctx
