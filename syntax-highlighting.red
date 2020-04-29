Red [
	Needs: 'View
	Author: "Toomas Vooglaid"
	Date: 2019-01-14
	Last: 2019-02-15
	Purpose: {Study of syntax highlighting}
	Licence: "Public domain"
]
starting-pos: length? words-of system/words
if all [value? 'syntax-ctx attempt [object? syntax-ctx]][
	syntax-ctx/new-words-in-default-context: clear []
	syntax-ctx/overloaded-predefined-words: clear []
	;syntax-ctx/overloaded-undefined-words: clear []
]
#include %info.red
#include %../../red-latest/red-master/environment/console/help.red
#include %complete-input.red
syntax-ctx: context [
	sys-words: clear []
	collect/into [
		foreach word words-of system/words [
			if not unset? get/any word [keep word]
		]
	] sys-words
	word-idx: 0
	sp: charset " ^-"
	ws: charset " ^/^-"
	opn: charset "[("
	cls: charset ")]"
	cls2: union ws cls
	brc: union opn cls
	brc2: union brc charset "{}"
	skp: union ws brc
	skp2: union skp charset "/"
	skp3: union skp2 charset ":"
	skp4: union skp3 charset "'"
	com-check: charset {^/;}
	skip-chars: charset "#$&"
	opn-brc: charset "{[(^"" ;"
	opp: "[][()({}{^"^""
	delim: charset [#"^/" #"^-" #" " #"[" #"(" #":" #"'" #"{"]
	rt: layer: bs: refine: lns: r-expr: r-def: r-val: none
	br: scr: s: s1: s2: i: i1: i2: in-brc: pos: bx-pos: str1: str2: blk: res: wheel-pos: len: line-num: needle: none
	_i1: _i2: _str1: _str2: el: caret: found: found-del: dont-move: ctrl?: deleted: none
	text-start: text-end: address: fnt: opts: edit: step: btns: tip: tips: args: ret: none
	
	new-words: none 
	new-words-in-default-context: clear []
	overloaded-predefined-words: clear []
	;overloaded-undefined-words: clear []
	
	save-bd: clear []
	curpos: anchor: 1
	crt-start: crt-end: 1 
	crt-diff: 0
	dbl: no
	cnt: 0
	steps: clear []
	last-find: []; act str1 i1 len
	coef: 1

	open-new: does [
		if not lay/extra/saved [ask-save] 
		lay/extra/file: none
		rt/text: copy "Red []^/"
		lay/text: "New file"
		set-caret length? rt/text
		renew-view
	]
	open: func [/local file [file!]][
		if all [lay/extra/file not lay/extra/saved][ask-save]
		file: request-file/title/filter "Open file" ["Red" "*.red" "All" "*"]
		if file [
			file: second lay/extra/file: split-path file
			rt/text: read file
			lay/text: mold file
			renew-view
			lay/extra/saved: yes
		]
	]
	save: func [/as /copy /local file [file! none!] curdir [file! none!]][
		case [
			copy [
				curdir: none
				if lay/extra/file [curdir: lay/extra/file/1]
				if attempt [file: request-file/save/title "Save copy as"][
					write file rt/text
					if all [curdir what-dir <> curdir] [set-current-dir curdir]
				]
			]
			any [as not lay/extra/file] [
				if attempt [file: request-file/save/title "Save file as"][
					lay/text: mold second lay/extra/file: split-path file
					show lay 
					write file rt/text
					lay/extra/saved: yes
				]
			]
			true [
				write lay/extra/file/2 rt/text
				lay/extra/saved: yes
			]
		]
	]
	ask-save: does [
		view/flags [
			text "Save file?" return
			button "Yes" [save unview]
			button "No" [unview]
		] [modal popup]
	]
	quit: does [
		if not lay/extra/saved [ask-save] 
		unview lay
	]
	copy-selection: does [
		if rt/data/1/y > 0 [write-clipboard copy/part at rt/text rt/data/1/x rt/data/1/y dont-move: true]
	]
	cut-selection: does [
		if rt/data/1/y > 0 [
			write-clipboard copy/part pos1: at rt/text rt/data/1/x len: rt/data/1/y 
			remove/part pos1 len
			lay/extra/saved: no
			recolor
			renumber
			set-caret rt/data/1/x 
			adjust-scroller
		]
	]
	paste-selection: does [
		parse txt: read-clipboard [any [change crlf lf | skip]]
		len: (length? txt) - rt/data/1/y
		either rt/data/1/y > 0 [
			change/part at rt/text curpos: rt/data/1/x txt rt/data/1/y 
		][
			insert at rt/text curpos txt
		]
		lay/extra/saved: no
		adjust-markers/length pos1 len
		;show-rt
		;recolor
		renumber
		set-caret curpos + length? txt
		adjust-scroller
	]
	del: func [key][
		case [
			rt/data/1/y > 0 [
				remove/part pos1: at rt/text curpos: rt/data/1/x rt/data/1/y
				recolor	set-caret curpos
			]
			not empty? last-find [
				remove/part pos1: at rt/text curpos: last-find/3 last-find/4
				found-del: find rt/data reduce [as-pair last-find/3 last-find/4 'backdrop]
				found-del: remove/part found-del 3
				adjust-markers/length/only at rt/text curpos + 1 negate last-find/4
				if last-find/1 = 'show [deleted: yes]
			]
			'else [
				case [
					all [key = 'delete curpos <= length? rt/text] [
						remove pos1: at rt/text curpos
						recolor
					]
					all [key = #"^H" curpos > 1] [
						remove pos1: at rt/text curpos: curpos - 1
						recolor	set-caret curpos
					]
				]
				adjust-markers/length pos1 -1
			]
		]
		lay/extra/saved: no
		renumber
	]
	set-coef: has [sz][
		sz: (rich-text/line-count? rt) * (rich-text/line-height? rt 1) 
		coef: rt/size/y * 1.0 / sz	
	]
	renew-view: does [
		lns/offset: 0x0
		rt/offset: 60x0 
		rt/data/4/2: 1 + length? rt/text
		show rt
		lns/size/y: rt/size/y: second size-text rt
		set-coef
		scr/max-size: rich-text/line-count? rt
		scr/position: 1
		scr/page: 1
		scr/page-size: (bs/size/y / rich-text/line-height? rt 1) + 1
		
		clear steps
		recolor
		renumber
		lns/data/1/2: 1 + length? lns/text
		show lns
		anchor: curpos: 1 
		rt/draw: compose [
			pen black caret: line 
				(as-pair 0 y: second caret-to-offset rt 1) 
				(as-pair 0 y + rich-text/line-height? rt 1)
		]
		rt/rate: 3
		if step/data [step/actors/on-change step none]
		set-focus bs
		show lay
	]
	highlight: function [s1 [string!] s2 [string!] style [tuple! block!]] bind [
		keep as-pair i: index? s1 (index? s2) - i 
		keep style
	] :collect
	skip-some: func [str [string!] chars [bitset!]][
		while [find/match str chars][str: next str] 
		str
	]
	count-lines: function [cnt-pos [string!]][
		i: 1 
		parse head cnt-pos [any [s: if (s = cnt-pos) thru end | newline (i: i + 1) | skip]] 
		i
	]
	prev-step: does [
		unless empty? steps [
			set [_str1 _str2] take/last/part steps 2
			curpos: _i1: index? _str1
			_i2: index? _str2
			clear pos
			repend rt/data [as-pair _i1 _i2 - _i1 'backdrop sky]
			reposition count-lines _str1
		]
	]
	next-step: does [
		unless tail? _str2 [
			repend steps [_str1 _str2]
			_str2: skip-some _str2 cls2
		]
		unless tail? _str2 [
			while [_str2/1 = #";"][
				_str2: arg-scope _str2 none
				_str2: skip-some _str2 cls2
			]
			_i1: index? _str1: _str2
			move-backdrop _str2
		]
	]
	into-step: does [
		repend steps [_str1 _str2]
		_i1: index? _str1: either find/match opn _str1/1 [
			skip-some next _str1 ws
		][
			find/tail _str1 skp
		]
		move-backdrop _str1
	]
	do-step: does [
		do copy/part either s1: find/match/tail _str1 "#include " [s1][_str1] _str2
		next-step
		set-focus bs
		show lay
	]
	;construct-step: does [
	;	if find [object context] el: load/next _str1 '_str2 [
	;		tmp-obj: construct load/next _tmp '_str2
	;		loop 2 [into-step]
	;	]
	;]
	move-backdrop: func [str [string!]][
		_i2: index? _str2: arg-scope str none
		clear pos
		repend rt/data [as-pair curpos: _i1 _i2 - _i1 'backdrop sky]
		if (count-lines _str2) > (scr/position + scr/page-size - 1) [
			reposition/start/force count-lines str
		]
	]
	get-function: function [path [path!]][
		path: copy path 
		while [
			not any [
				tail? path 
				any-function? attempt [get/any either 1 = length? path [path/1][path]]
			]
		][
			clear back tail path
		] 
		either empty? path [none][path]
	]
	br-scope: function [br [string!]][
		stack: append clear [] br/1
		mstack: clear []
		either find opn br/1 [
			i1: index? br
			parse next br [some [s:
					newline (comm: no)
				|	[
						if (not any [comm instr inmstr]) [
							if (s/1 = select opp stack/1) (remove stack)
							[if (empty? stack) (i2: index? next s) thru end | skip]
						|	if (find brc s/1) (insert stack s/1) skip
						|	{"} (instr: yes) 
						|	#"{" (inmstr: yes insert mstack s/1)
						|	#";" (comm: yes)
						]
					| 	if (not comm) [
							if (not instr) [
								#"{"  (insert mstack s/1) 
							|	#"}" [if (mstack/1 = #"{")(remove mstack if empty? mstack [inmstr: no]) | ]
							]
						|	if (not inmstr) {"} [if (instr)(instr: no) | ]
						]
					]
				| 	skip
			]]
			color: either empty? stack [gray + 100][i2: index? s 255.220.220]
			repend rt/data [as-pair i1 i2 - i1 'backdrop color]
		][
			i2: 1 + index? br
			found: br
			until [any [
				all [
					found: find/reverse found select opp stack/1
					not find/part find/reverse/tail found lf #";" found
					load/next found 's
					s = next br
				]
				not found
			]]
			color: either found [gray + 100][255.220.220]
			i1: either found [index? found][1]
			repend rt/data [as-pair i1 i2 - i1 'backdrop color]
		]
	]
	left-scope: func [str [string!] /local i [integer!]][i: 0
		until [str: back str not find/match str ws]
		either #")" = str/1 [find/reverse str "("][find/reverse/tail str skp]
	]
	arg-scope: func [str [string!] type [none! block! datatype! typeset!] /left /right /local el el2 s0 s1 s2 i2 _][
		either left [
			s1: left-scope str
			s0: left-scope s1
			el: load/next s0 '_
			if op? attempt [get/any el][s1: arg-scope/left s0 none]
		][
			el: load/next str 's1
			el2: either right [none][load/next s1 's2]
			either all [word? el2 op? attempt/safer [get/any el2]][
				s1: arg-scope s2 none
			][
				either find/match str "#include " [
					s1: arg-scope s1 none
				][
					switch type?/word el [
						set-word! set-path! [s1: arg-scope s1 none]
						word! [if any-function? get/any el [s1: scope str]]
						path! [
							case [
								any-function? get/any first el [s1: scope str]
								get-function el [s1: scope str]
							]
						]
					]
				]
			]
		]
		s1
	]
	scope: func [str [string!] /color col /local fn fnc inf clr arg i1 i2 s1 s2][
		fn: load/next str 's1
		case [
			all [word? fn any-function? get/any :fn] [fnc: fn]
			all [path? fn fn1: get-function fn 1 = length? fn1] [fnc: fn/1]
			all [path? fn fn1] [fnc: fn1]
			'else [fnc: none]
		]
		if fnc [
			inf: info :fnc
			clr: any [col yello] 
			either op! = inf/type [
				s0: arg-scope/left str none
				i1: index? s0
				i2: -1 + index? str
				repend rt/data [as-pair i1 i2 - i1 'backdrop clr: clr - 30]
				i2: index? s2: arg-scope/right s1 none
				while [find ws s1/1][s1: next s1]
				i1: index? s1
				repend rt/data [as-pair i1 i2 - i1 'backdrop clr: clr - 30]
			][
				foreach arg inf/arg-names [
					i2: index? s2: arg-scope s1 inf/args/:arg
					while [find ws s1/1][s1: next s1]
					i1: index? s1
					repend rt/data [as-pair i1 i2 - i1 'backdrop clr: clr - 30]
					s1: :s2
				]
			]
			if all [path? fn any [word? fnc (length? fn) > (length? fnc)]][
				foreach ref either word? fnc [next fn][skip fn length? fnc] [
					if 0 < length? refs: inf/refinements/:ref [
						foreach type values-of refs [
							i2: index? s2: arg-scope s1 type
							while [find ws s1/1][s1: next s1]
							i1: index? s1
							repend rt/data [as-pair i1 i2 - i1 'backdrop clr: clr - 30]
							s1: :s2
						]
					]
				]
			]
			show rt
			s1
		]
	]
	rule: [any [s: [if ((index? text-end) <= index? s) (return true) |]
		ws
	|	brc (s2: next s highlight s s2 rebolor)
	|	#";" [if (s2: find s newline) | (s2: tail s)] (highlight s s2 reduce ['italic beige - 50]) :s2
	|	[if (all [attempt [el: load/next s 's2] s <> s2])(
			case [
				string? el		[highlight s s2 gray]
				any-string? el	[highlight s s2 orange]
				refinement? el	[highlight s s2 papaya]
				word? el		[
					case [
						function? get/any el [highlight s s2 brick]; reduce ['bold blue]]
						op? get/any el [highlight s s2 brick]
						any-function? get/any el [highlight s s2 crimson]
						;immediate? get/any el [highlight s s2 leaf]
						'else [highlight s s2 violet]
					]
				]
				path? el		[
					case [
						function? get/any el/1 [highlight s s2: find s #"/" brick]
						op? get/any el/1 [highlight s s2: find s #"/" brick]
						any-function? get/any el/1 [highlight s s2: find s #"/" crimson]
						fn: get-function :el [
							highlight s s2: find/tail s form fn brick
							highlight s find s #"/" violet
						] 
						'else [highlight s s2: find s #"/" violet]
					]
				] 
				set-word? el 	[
					either all [
						(index? to-word :el) < index? 'starting-pos 
						find sys-words to-word :el
					][
						append overloaded-predefined-words to-word :el
						highlight s s2 red
					][
						if unset? to-word :el [
							append new-words-in-default-context to-word :el
						]
						highlight s s2 navy
					]
				]
				any-word? el	[highlight s s2 navy]
				any-path? el	[highlight s s2 water]
				number? el		[highlight s s2 mint]
				scalar? el		[highlight s s2 teal]
				immediate? el	[highlight s s2 leaf]
			]
		) | [if (s2: find s ws) | (s2: tail s)] (highlight s s2 red)] :s2
	]]
	;               brc       func op   any-func   word
	boxes: reduce [rebolor '| brick '| crimson '| violet]
	box-rule: bind [
		any [p: 
			boxes (
				address: back p 
				keep reduce [
					'box (caret-to-offset rt address/1/1) + rt/offset + -60x2
						 (caret-to-offset rt bx-pos: address/1/1 + address/1/2) + 
							(as-pair 0 rich-text/line-height? rt bx-pos) + rt/offset - 60x2
				]
			)
		| skip
		]
	] :collect
	scroll: func [sc-pos [integer!]][
		lns/offset/y: rt/offset/y: to-integer negate (sc-pos - 1) * (rich-text/line-height? rt 1) * coef
		recolor
		show bs
	]
	adjust-scroller: does [
		lns/size/y: rt/size/y: second size-text rt 
		set-coef
		scr/max-size: rich-text/line-count? rt
		scr/page-size: (bs/size/y / rich-text/line-height? rt 1) + 1
	]
	reposition: func [line-num [integer!] /start /force][
		if any [
			force
			line-num < scr/position
			line-num > (scr/position + scr/page-size - 1)		
		][
			scr/position: max 1 line-num - either start [0][scr/page-size / 3]
			scr/page: scr/position - 1 / scr/page-size + 1
			scroll scr/position
		]
		set-focus bs
		show lay
	]
	ask-find: has [needle [string!]][
		view/flags [
			text "Find what" fnd: field 100 focus on-enter [needle: face/text unview]
			button "OK" [needle: fnd/text unview]
		][modal popup]
		needle
	]
	find-again: func [prev [logic!]][
		switch last-find/1 [
			show [
				either deleted [
					pos1: skip found-del pick [-1 2] prev 
					deleted: no
				][
					pos1: find pos [backdrop 0.200.0]
					pos1/2: 100.255.100
					pos1: skip pos1 pick [-2 4] prev
				]
				either prev [
					unless pos1/1 = 100.255.100 [pos1: next find/last pos 'backdrop]
				][
					if empty? pos1 [pos1: next find pos 'backdrop]
				]
				pos1/1: 0.200.0 
				reposition count-lines at rt/text last-find/3: curpos: pos1/-2/1
			]
			find [
				clear pos
				if str1: either prev [
					any [
						either head? last-find/2 [
							find/reverse tail rt/text needle
						][
							find/reverse back last-find/2 needle
						] 
						find/reverse tail rt/text needle
					]
				][
					any [find next last-find/2 needle find rt/text needle]
				][
					curpos: last-find/3: index? last-find/2: str1
					repend rt/data [as-pair last-find/3 last-find/4 'backdrop cyan]
					reposition count-lines str1
				]
			]
		]
	]
	find-menu: ["Find" find "Show" show "Prev" prev "Next" next]; "Inspect" insp]
	find-word: func [event [event!]][
		switch event/picked [
			find [
				clear pos
				if needle: ask-find [
					either str1: find rt/text needle [
						curpos: i1: index? str1
						len: length? needle
						repend rt/data [as-pair i1 len 'backdrop cyan]
						reposition count-lines str1
						repend clear last-find ['find str1 i1 len]
					][];TBD "Not found" message
				]
			]
			show [
				clear pos
				i0: index? str: find/reverse/tail at rt/text offset-to-caret rt offset event skp4 
				str2: find str skp3
				elem: copy/part str str2
				str1: rt/text
				len: length? elem
				while [
					str1: find/tail str1 elem
				][
					if all [
						any [attempt [find skp4 first skip str1 -1 - len] head? skip str1 0 - len]
						any [attempt [find skp3 first str1] tail? str1]
					][
						i1: index? str1
						repend rt/data [as-pair i: i1 - len len 'backdrop either i = i0 [0.200.0][100.255.100]]
					]
				]
				curpos: i0
				repend clear last-find ['show str i0 len]
				show rt
			]
			prev next [find-again event/picked = 'prev]
			insp [
				
			]
		]
	]
	renumber: has [n][
		append clear lns/text #"1"
		n: 1 found: rt/text
		while [found: find/tail found lf] [append lns/text rejoin [lf n: n + 1]]
		lns/data/1/2: 1 + length? lns/text
	]
	recolor: has [ofs][
		text-start: at rt/text offset-to-caret rt ofs: negate rt/offset - layer/offset ;as-pair 60 0 - rt/offset/y
		text-end: at rt/text offset-to-caret rt ofs + bs/size
		if pos [move/part pos save-bd length? pos]
		clear at rt/data 7
		collect/into [parse text-start rule] rt/data
		clear at layer/draw 5
		collect/into [parse rt/data box-rule] layer/draw
		pos: tail rt/data
		if not empty? save-bd [move/part save-bd pos length? save-bd]
		system/view/platform/redraw layer ; ??
	]
	change-font: func [what [integer! string!] /type /local n][
		n: pick [6 5] type
		rt/data/:n: what
		lns/data/(n - 3): what
		lns/size/y: rt/size/y: second size-text rt
		recolor
		show [lns rt] 
		adjust-scroller 
		set-caret curpos 
	]	
	adjust-markers: func [pos1 [string!] /length len /only /local i1 pos3][
		len: any [len 1]
		i1: either found: find/reverse/tail pos1 skp2 [index? found][1]
		pos3: rt/data
		rt/data/4/2: 1 + length? rt/text
		lns/data/1/2: 1 + length? lns/text
		forall pos3 [
			if pair? pos3/1 [
				case [
					all [negative? len curpos < pos3/1/1] [pos3/1/1: pos3/1/1 + len]
					all [negative? len curpos > pos3/1/1 curpos < (pos3/1/1 + pos3/1/2 + len)][pos3/1/2: pos3/1/2 + len]
					all [positive? len curpos <= pos3/1/1] [pos3/1/1: pos3/1/1 + len]
					all [positive? len curpos > pos3/1/1 curpos <= (pos3/1/1 + pos3/1/2 + len)][pos3/1/2: pos3/1/2 + len]
				]
			]
		]
		show rt
		unless only [recolor]
	]
	complete: func [e /local found word new-word][
		unless found: find/reverse/tail at rt/text curpos delim [found: head rt/text]
		word: copy/part found at rt/text curpos
		if #"%" = word/1 [word: next word]
		new-word: pick e/face/data e/face/selected
		unview
		found: find/tail new-word word
		len: length? new-word
		if found [len: len - (length? word)]
		insert at rt/text curpos either found [found][new-word]
	]
	set-caret: func [e [event! none! integer!] /dont-move /only /local found posM pos1M pos2M tmppos line-start brc_][
		case [
			event? e [ 
				switch e/type [
					down [
						either e/shift? [
							curpos: offset-to-caret rt offset e 
							rt/data/1: as-pair min anchor curpos absolute anchor - curpos
						][
							anchor: curpos: offset-to-caret rt offset e 
							rt/data/1/2: 0
						]
					]
					key [
						switch/default e/key [
							right [
								curpos: either e/ctrl? [
									index? find at rt/text curpos + 1 skp2
								][
									either all [0 < rt/data/1/2 not e/shift?] [
										rt/data/1/1 + rt/data/1/2
									][
										min 1 + length? rt/text curpos + 1																				
									]
								]
							]
							left [
								curpos: either e/ctrl? [
									either found: find/reverse/tail at rt/text curpos - 1 skp2 [index? found][1]
								][
									either all [0 < rt/data/1/2 not e/shift?] [
										rt/data/1/1
									][
										max 1 curpos - 1
									]
								]
							]
							down [
								curpos: min 1 + length? rt/text    offset-to-caret rt 
									((caret-to-offset rt curpos) + as-pair 0 rich-text/line-height? rt 1)
							]
							up [curpos: max 1 offset-to-caret rt (caret-to-offset rt curpos) - 0x3]
							page-down [
								curpos: min 1 + length? rt/text offset-to-caret rt (
									(caret-to-offset rt curpos) + as-pair 0 scr/page-size + 1 * rich-text/line-height? rt 1 
								)
							]
							page-up [
								curpos: max 1 offset-to-caret rt (
									(caret-to-offset rt curpos) - as-pair 0 scr/page-size + 1 * rich-text/line-height? rt 1 
								)
							]
							end [
								curpos: either e/ctrl? [
									1 + length? rt/text
								][
									either found: find at rt/text curpos lf [index?  found][1 + length? rt/text]
								]
							]
							home [
								curpos: either e/ctrl? [1][
									either found: find/reverse/tail at rt/text curpos lf [index? found][1]
								]
							]
							#"^A" [anchor: 1 curpos: 1 + length? rt/text] ;Select all
							#"^C" [copy-selection]
							#"^X" [cut-selection]
							#"^V" [paste-selection]
							delete #"^H" [del e/key] ;Delete and backspace
							#"^[" [clear pos clear last-find] ;Escape
							#"^M" [
								pos1M: any [find/reverse/tail at rt/text curpos newline head rt/text]
								pos2M: skip-some pos1M sp
								tmppos: index? pos1: insert at rt/text curpos reduce [newline line-start: copy/part pos1M pos2M]
								either brc_: find/match back at rt/text curpos opn [
									brc_: back brc_
									skip-some brc_ sp
									tmppos: index? pos1: insert pos1 tab
									either pos1/1 = opp/(brc_/1) [
										posM: insert at rt/text tmppos reduce [newline line-start]
										len: 2 * (length? line-start) + 4
									][
										posM: pos1
										len: 2 + length? line-start
									]
								][
									posM: pos1 
									len: 1 + length? line-start
								]
								curpos: tmppos 
								show rt
								replace/all rt/text crlf lf ; Needed?
								lay/extra/saved: no
								adjust-markers/length posM len
								renumber 
							]
							#"^S" [save]
							#"^O" [open]
							#"^N" [open-new]
							#"^Q" [quit]
						][
							curpos: index? pos1: either rt/data/1/y > 0 [
								len: negate rt/data/1/y - 1
								change/part at rt/text rt/data/1/x e/key rt/data/1/y 
							] [
								either all [e/key = 'F1][
									suggestions: red-complete-ctx/complete-input at rt/text curpos yes
									view/flags/options/tight compose/only [
										text-list data (suggestions) focus select 1 
										on-key-down [case [
											find [#"^M" #"^-"] event/key [ret: complete event] 
											event/key = #"^[" [unview len: 0 ret: at rt/text curpos]
										]]
										on-dbl-click [ret: complete event]
									][modal no-border][offset: (caret-to-offset rt curpos) + rt/offset + lay/offset + bs/offset + 0x20]
									ret
								][
									len: 1
									insert at rt/text curpos e/key
								]
							]
							if attempt [find opn-brc e/key] [insert pos1 opp/(e/key) len: 2]
							lay/extra/saved: no
							adjust-markers/length pos1 len
						]
						adjust-scroller 
					]
				]
				either any [find [#"^A" #"^C"] e/key all [e/shift? any [e/type = 'down find [left right down up end home] e/key]]] [
					rt/data/1: as-pair min anchor curpos absolute anchor - curpos
				][
					anchor: curpos rt/data/1/2: 0
				]
			]
			integer? e [curpos: e rt/data/1/2: 0 unless only [anchor: curpos]]
		]
		caret/2: caret-to-offset rt curpos
		caret/3: as-pair caret/2/1 caret/2/2 + rich-text/line-height? rt 1
		unless dont-move [reposition count-lines at rt/text curpos]
	]
	offset: func [e [event!]][either e/face = rt [e/offset][e/offset - rt/offset + layer/offset]]
	tip-text: rtd-layout reduce [white ""] tip-text/size: 580x30
	make-ctx-path: func [face [object!] addr [pair!] /local s s2 e b][
		face/extra/addr: addr
		clear at face/extra/path 2
		append face/extra/path parse at rt/text addr/1 [
			collect any [s:
				["make object!" | "object" | "context"] b:
				any ws b: #"["
				(load/next b 'e)
				if (addr/1 < index? e) (
					s: find/reverse/tail e: find/reverse s ws ws
				) keep (to-word copy/part s e)
				(s: back s) :s
			|	if (head? s) break
			|	(s: back s) :s
			]
		]
	]
	save-code-back: func [face [object!]][
		if step/data [
			change/part at rt/text face/extra/addr/1 face/text face/extra/addr/2
			lay/extra/saved: no
			set-caret curpos: _i1: face/extra/addr/1
			move-backdrop at rt/text _i1
			recolor
			renumber
			set-focus bs show bs 
			face/extra/addr/2: length? face/text
			adjust-scroller
			reposition curpos
		]
	]
	show-refine: has [sz1 sz2 diff s b e _path_] [
		ctrl?: no
		refine/offset: as-pair lay/size/x / 3 * 2 + 5 bs/offset/y
		refine/size: as-pair lay/size/x / 3 - 15 bs/size/y
		bs/size/x: refine/offset/x - 5
		rt/size/x: layer/size/x: bs/size/x - 78
		r-expr/size/x: r-def/size/x: r-val/size/x: refine/size/x - 20
		step-expr: first back find pos [backdrop 164.200.255]
		make-ctx-path r-expr step-expr
		r-expr/text: copy/part at rt/text step-expr/1 step-expr/2
		sz1: r-expr/size/y
		r-expr/size/y: min 400 max 50 second size-text r-expr
		r-expr/selected: 1x0 ; ? Doesn't work?
		show r-expr
		sz2: r-expr/size/y
		diff: sz2 - sz1
		foreach-face/with refine [face/offset/y: face/offset/y + diff] [face/offset/y > r-expr/offset/y]
		refine/visible?: yes
		show [bs refine]
	]
	do-refine-code: func [face [object!] /local res code ctx][
		code: bind load/all face/text get to-path face/extra/path
		r-val/text: either string? res: do code [res][mold :res]
		r-val/size/y: second size-text r-val
		show r-val
	]
	__explore-ctx__: none
	construct-code: has [loaded s e rule __current-ctx__ stack][
		__explore-ctx__: construct skip loaded: load rt/text 2
		__current-ctx__: __explore-ctx__
		stack: clear []
		parse loaded rule: [
			some [
				'Red block!
			|	set-word! s: [
					change ['object | 'context | 'make 'object!] construct
					(
						;if set-path? s/-1 [s/-1: load replace/all form s/-1 #"/" #"_"] ; what if there is context with path, eg system/view/VID | or anonymous?
						__current-ctx__/(to-word s/-1): do/next s 'e
						repend stack [__current-ctx__ e]
						__current-ctx__: __current-ctx__/(to-word s/-1)
					)
					s: (bind s/1 __current-ctx__) into rule 
					(set [__current-ctx__ e] take/last/part stack 2) :e
				| 	if (__current-ctx__/(to-word s/-1): attempt/safer [do/next s 'e]) :e ; attempt - to avoid routines
				]
			| 	skip
			]
		]
	]

	system/view/auto-sync?: off
	view/flags/no-wait lay: layout/options/tight [
		title "New file"
		backdrop white
		panel 800x50 [
			origin 0x0 
			options: panel 800x50 [
				panel 210x30 [
					origin 0x0 
					edit: radio 45 "Edit" data yes [clear pos set-focus bs attempt [show lay]]
					tips: radio 45 "Tips" [set-focus bs cnt: 0 attempt [show lay]]
					args: radio 45 "Args" [set-focus bs cnt: 0 attempt [show lay]]
					step: radio 45 "Step" [
						if 1 = cnt: cnt + 1 [
							clear pos
							clear last-find
							either face/data [
								cnt: 0
								either empty? steps [
									_str1: head rt/text
									_i2: index? _str2: arg-scope _str1 none
									repend rt/data [as-pair 1 _i2 - 1 'backdrop sky]
								][
									prev-step
								]
							][
								repend steps [_str1 _str2] 
							] 
							set-focus bs
							show lay
							'stop
						]
					]
				]
				btns: panel [
					origin 0x0
					button "Prev" [either all [step/data empty? last-find] [prev-step][find-again true]]
					button "Into" [either all [step/data empty? last-find] [into-step][find-again false]]
					button "Next" [either all [step/data empty? last-find] [next-step][find-again false]]
					button "Eval" [if all [step/data empty? last-find] [do-step]]
					button "Exec" [do rt/text]
					;button "Construct" [if all [step/data empty? last-find] [construct-step]]
					button "Construct" [construct-code]
					button "Recolor" [recolor set-focus bs attempt [show lay]]
					font-size: drop-list 40 data ["9" "10" "11" "12" "13" "14"] select 4 on-change [
						change-font to-integer pick face/data face/selected
					]
					drop-list with [
						data: collect [foreach fnt exclude words-of fonts: system/view/fonts [size] [keep fonts/:fnt]]
						selected: index? find data system/view/fonts/system
					] on-change [
						change-font/type pick face/data face/selected
					]
				]
			]
		]
		space 0x0
		return pad 10x10 
		bs: base white with [
			size: system/view/screens/1/size - 12x150 
			pane: layout/only [
				origin 0x0 across
				lns: rich-text top right "" white with [
					size: as-pair 50 system/view/screens/1/size/y
					data: reduce [1x0 to-integer pick font-size/data font-size/selected system/view/fonts/system silver]
				]
				rt: rich-text "Red []^/" with [
					size: system/view/screens/1/size - 90x0 
					data: reduce [1x0 'backdrop silver 1x0 to-integer pick font-size/data font-size/selected system/view/fonts/system]
					menu: find-menu
				]
				cursor I-beam 
				on-time [face/draw/2: pick [glass black] face/draw/2 = 'black show face]
				on-menu [find-word event]
				;all-over on-over [ ; NB! Works on first page only
				;	if event/down? [
				;		curpos: i2: offset-to-caret rt event/offset
				;		set-caret/dont-move/only curpos
				;		rt/data/1: as-pair min anchor curpos absolute anchor - curpos
				;		show rt
				;	]
				;]

				at 60x0 layer: box with [
					size: system/view/screens/1/size - 30x160
					menu: find-menu
				] 
				draw [pen off fill-pen 0.0.0.254]
				on-menu [find-word event]
				on-over [
					either event/away? [
						case [
							in-brc [
								clear skip tail rt/data -3
								in-brc: no
								show bs
							]
							tips/data [
								tip/visible?: no
								show tip
							]
							any [args/data all [edit/data ctrl?]] [
								clear pos 
								show rt
							]
						]
					][
						str: find/reverse/tail br: at rt/text offset-to-caret rt event/offset - rt/offset + layer/offset skp
						case [
							any [find brc br/1 all [any [find ws br/1 not find [word! path!] type? load/next br '_] find brc br/-1 br: back br]][
								in-brc: yes
								br-scope br
								show bs
							]
							tips/data [
								parse layer/draw [
									some [
										'box bx: pair! 
										if (within? event/offset bx/1 - 1x1 bx/2 - bx/1 + 2x2) (in-box: bx)
									| 	skip
									]
								]
								wrd: load copy/part 
									at rt/text offset-to-caret rt in-box/1 + 0x3 - rt/offset + layer/offset
									at rt/text offset-to-caret rt in-box/2 - 0x3 - rt/offset + layer/offset
								either event/ctrl? [
									tip-text/text: rejoin [type? fn: get :wrd "!^/"]
									append tip-text/text either any-function? :fn [mold spec-of :fn][help-string :wrd] ; or :fn for non-func? (with scrollers)
									case [
										any [function? :fn op? :fn] [append tip-text/text mold body-of :fn]
										bitset? :fn [
											append tip-text/text "Chars: "
											append tip-text/text mold rejoin collect [repeat i length? :fn [if pick :fn i [keep to-char i]]]
										]
									]
									
								][
									tip-text/text: help-string :wrd
								]
								tip-text/data/1/2: 1 + length? tip-text/text
								tip/size/y: 20 + tip-text/size/y: second size-text tip-text
								tip/draw/5/y: tip/size/y - 1
								case [
									(event/offset/y - face/offset/y) > (tip/size/y + 20) [
										tip/offset: min bs/size - tip/size
											max 0x40 event/offset + face/offset - as-pair 30 tip/size/y
									]
									(event/offset/x - face/offset/x) > tip/size/x [
										tip/offset: min 
											max 0x40 event/offset + face/offset + as-pair 0 - tip/size/x - 30 0 - (tip/size/y / 2)
											bs/size - tip/size
									]
									(face/size/y - event/offset/y) > (tip/size/y + 40) [
										tip/offset: min bs/size - tip/size
											max 0x40 event/offset + face/offset + -30x80
									]
									true [
										tip/offset: min 
											max 0x40 event/offset + face/offset + as-pair 30 0 - (tip/size/y / 2)
											bs/size - tip/size
									]
								]
								tip/visible?: yes
								show tip
								'stop
							]
							any [args/data all [edit/data ctrl?]] [if all [str not empty? str] [scope str]]
						]
					]
				]
				;at 60x0 layer2: box 0.0.0.254 with [size: system/view/screens/1/size - 30x160]
				;all-over on-over [
				;	if event/down? [
				;		curpos: i2: offset-to-caret rt offset event
				;		set-caret/dont-move/only curpos
				;		rt/data/1: as-pair min anchor curpos absolute anchor - curpos
				;		show rt
				;	]
				;]
			]
			flags: 'scrollable
		]
		on-created [
			put get-scroller face 'horizontal 'visible? no
			scr: get-scroller face 'vertical
		]
		on-scroll [
			unless event/key = 'end [
				scroll scr/position: min scr/max-size max 1 switch event/key [
					track [event/picked]
					up [scr/position - 1]
					page-up [scr/position - scr/page-size]
					down [scr/position + 1]
					page-down [scr/position + scr/page-size]
				] 
				clear at layer/draw 5
				collect/into [parse rt/data box-rule] layer/draw
				pos: tail rt/data
				show bs
			]
		]
		on-wheel [if bs/size/y < second size-text rt [scroll scr/position: min max 1 scr/position - (3 * event/picked) scr/max-size - scr/page-size]]
		on-key [
			switch/default event/key [
				left up [case [
					all [event/key = 'up ctrl?] [scroll scr/position: min max 1 scr/position - 1 scr/max-size]
					all [step/data empty? last-find] [prev-step]
					all [find [show find] last-find/1][find-again true] 
					edit/data [set-caret event]
				]]
				right [case [
					all [step/data empty? last-find] [next-step]
					all [find [show find] last-find/1] [find-again false] 
					edit/data [set-caret event]
				]]
				down [case [
					ctrl? [scroll scr/position: min max 1 scr/position + 1 scr/max-size]
					all [step/data empty? last-find] [into-step]
					all [find [show find] last-find/1] [find-again false] 
					edit/data [set-caret event]
				]]
				#"^M" [either all [step/data empty? last-find] [do-step][set-caret event]]
			][
				set-caret event
			]
		]
		on-key-down [
			switch event/key [
				left-control right-control [ctrl?: yes]
			]
		]
		on-key-up [
			switch event/key [
				left-control right-control [
					ctrl?: no 
					if all [edit/data empty? last-find] [clear pos show rt]
				]
			]
		]
		on-down [
			unless lay/selected = bs [set-focus bs show bs]
			either step/data [
				either any [ctrl? event/ctrl?] [
					show-refine
				][
					clear pos
					repend steps [_str1 _str2]
					_i1: index? _str1: find/reverse/tail at rt/text offset-to-caret rt offset event skp
					_i2: index? _str2: arg-scope _str1 none
					repend rt/data [as-pair _i1 _i2 - _i1 'backdrop sky] ;sky - selected expr in step mode
					if (count-lines _str2) > (scr/position + scr/page-size - 1) [
						reposition/start/force count-lines _str1
					]
					show bs
				]
			][set-caret event]
			;'stop
		]
		on-dbl-click [
			i1: index? str1: find/reverse/tail at rt/text offset-to-caret rt offset event skp2
			i2: index? str2: find str1 skp2
			set-caret/dont-move curpos: i2
			anchor: i1
			rt/data/1: as-pair min anchor curpos absolute anchor - curpos
			show rt
		]
		at 0x0 refine: panel hidden [
			r-expr: area wrap extra [addr 0x0 path [__explore-ctx__]]
			with [menu: ["Show def" show-def]]
			on-menu [
				switch event/picked [
					show-def [
						str: find rt/text append copy/part at r-expr/text 
							r-expr/selected/1 - (count-lines at r-expr/text r-expr/selected/1) + 1
							r-expr/selected/2 - r-expr/selected/1 + 1 #":"
						sz1: r-def/size/y
						r-def/text: copy/part str arg-scope str none
						make-ctx-path r-def as-pair i1: index? str length? r-def/text
						r-def/size/y: second min 400 max 50 size-text r-def
						show r-def
						sz2: r-def/size/y
						diff: sz2 - sz1
						foreach-face/with refine [face/offset/y: face/offset/y + diff] [face/offset/y > r-def/offset/y]
						show refine
					]
				]
			]
			return
			button "Do" [do-refine-code r-expr]
			button "Save" [save-code-back r-expr] return
			r-def: area wrap extra [addr 0x0 path [__explore-ctx__]] return
			button "Do" [do-refine-code r-def]
			button "Save" [save-code-back r-def] 
			return
			r-val: text wrap white
		]
		at 0x0 tip: rich-text 600x50 hidden with [
			draw: compose [
				fill-pen 0.0.128 
				box 0x0 (size - 1) 
				;fill-pen 254.254.254.1
				text 10x10 (tip-text)
			] 
		]

		do [lns/parent: bs rt/parent: bs layer/parent: bs]
	] [
		offset: -7x0
		extra: reduce ['file none 'saved false]
		menu: [
			"File" [
				"New		(^^N)"  new 
				"Open...	(^^O)"  open 
				"Save		(^^S)"  save 
				"Save as..." 		save-as 
				"Save copy..." 		save-copy 
				"Quit		(^^Q)"  quit
			]
			"Edit" [
				"Copy		(^^C)"  copy 
				"Cut		(^^X)"  cut 
				"Paste		(^^V)"  paste 
				"Delete		(del)"  del
			]
		]
		actors: object [
			max-x: max-y: 0
			cur-y: 10
			lim: func [:z face][face/offset/:z + face/size/:z]
			opts: options/pane
			on-menu: func [face [object!] event [event!]][
				switch event/picked [
					;---File---
					new [open-new]
					open [open]
					save [save]
					save-as [save/as]
					save-copy [save/copy]
					quit [quit]
					;---Edit---
					copy [copy-selection]
					cut [cut-selection]
					paste [paste-selection]
					del [del 'delete]
				]
			]
			resize: func [face [object!] event [event!] /local _last diff][
				if any [
					0 > diff: face/size/x - options/size/x
					all [diff > 0 options/size/x < 900]
				][
					max-y: 0
					max-x: 0 
					cur-y: 10
					options/size/x: face/size/x
					forall opts [
						if 1 < length? opts [
							max-x: max max-x lim x opts/1
							max-y: max max-y lim y opts/1
							opts/2/offset: either options/size/x - opts/2/size/x - 20 < lim x opts/1 [
								max-x: 0
								as-pair 10 cur-y: max-y + 10
							][
								as-pair max-x + 10 cur-y 
							]
						]
					] 
					options/parent/size/y: options/size/y: 10 + lim y last opts
				]
				options/parent/size/x: face/size/x
				bs/offset/y: options/offset/y + options/size/y + 10
				bs/size/x: face/size/x - 12
				bs/size/y: face/size/y - bs/offset/y - 10
				rt/size/x: layer/size/x: bs/size/x - 78
				show bs
				adjust-scroller
				reposition count-lines at rt/text curpos
			]
			on-resizing: func [face event][resize face event]
			on-resize: func [face event][resize face event]
		]
	] 'resize
	renew-view
	ending-pos: length? words-of system/words
	do-events
]
