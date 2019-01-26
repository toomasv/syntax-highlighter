Red [
	Needs: 'View
	Author: "Toomas Vooglaid"
	Date: 2019-01-14
	Last: 2019-01-26
	Purpose: {Study of syntax highlighting}
]
do %info.red ;#include
ctx: context [
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
	rt: layer: bs: br: s: s1: s2: i: i1: i2: in-brc: pos: str1: str2: blk: res: wheel-pos: opts: len: line-num: needle: none
	_i1: _i2: _str1: _str2: btns: caret: found: dont-move: ctrl?: none
	save-bd: clear []
	curpos: anchor: 1
	crt-start: crt-end: 1 
	crt-diff: 0
	dbl: no
	cnt: 0
	steps: clear []
	last-find: []; act str1 i1 len
	initial-size: 820x400

	open-file: func [file][
		either file [
			rt/text: read file
			lay/text: mold file
		][
			rt/text: copy "Red []^/"
			lay/text: "New file"
		]
		renew-view
	]
	renew-view: does [
		rt/offset: 0x0 
		rt/data/4/2: length? rt/text
		show rt
		rt/size/y: max bs/size/y second size-text rt 
		scr/max-size: rich-text/line-count? rt
		scr/position: 1
		scr/page: 1
		scr/page-size: bs/size/y / rich-text/line-height? rt 1
		clear steps
		recolor
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
	highlight: function [s1 [string!] s2 [string!] style [tuple! block!]] bind [keep as-pair i: index? s1 (index? s2) - i keep style] :collect
	skip-some: func [str [string!] chars [bitset!]][while [find/match str chars][str: next str] str]
	count-lines: function [pos [string!]][i: 0 parse head pos [any [s: if (s = pos) thru end | newline (i: i + 1) | skip]] i]
	prev-step: does [
		unless empty? steps [
			set [_str1 _str2] take/last/part steps 2
			_i1: index? _str1
			_i2: index? _str2
			clear pos
			repend rt/data [as-pair _i1 _i2 - _i1 'backdrop sky]
			reposition count-lines _str1
		]
	]
	next-step: does [
		;unless tail? _str2 [
			repend steps [_str1 _str2]
			_str2: skip-some _str2 cls2
		;]
		;unless tail? _str2 [
			while [_str2/1 = #";"][
				_str2: arg-scope _str2 none
				_str2: skip-some _str2 cls2
			]
			_i1: index? _str1: _str2
			move-backdrop _str2
		;]
	]
	into-step: does [
		repend steps [_str1 _str2]
		either find/match opn _str1/1 [
			_i1: index? _str1: next _str1
			_str1: skip-some _str1 ws
		][
			_i1: index? _str1: find/tail _str1 skp
		]
		move-backdrop _str1
	]
	do-step: does [
		do copy/part _str1 _str2 next-step
		set-focus bs
		show lay
	]
	move-backdrop: func [str [string!]][
		_i2: index? _str2: arg-scope str none
		clear pos
		repend rt/data [as-pair _i1 _i2 - _i1 'backdrop sky]
		if (count-lines _str2) > (scr/position + scr/page-size)[
			reposition count-lines str
		]
	]
	get-function: function [path [path!]][
		path: copy path while [
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
		i1: index? br
		stack: append clear [] br/1
		mstack: clear []
		either find opn br/1 [
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
		s1
	]
	scope: func [str [string!] /color col /local fn fnc inf clr arg i1 i2 s1 s2][
		fn: load/next str 's1
		fnc: either word? fn [fn][fn1: get-function fn either 1 = length? fn1 [fn1/1][fn1]]
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
	filter: func [series [block!] _end [string!]][
		collect [foreach file series [if find/match skip tail file -4 _end [keep file]]]
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
				word? el		[case [
					any-function? get/any el [highlight s s2 brick]; reduce ['bold blue]]
					immediate? get/any el [highlight s s2 leaf]
				]]
				path? el		[
					case [
						any-function? get/any el/1 [highlight s s2: find s #"/" brick]
						fn: get-function :el [highlight s s2: find/tail s form fn brick] 
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
	box-rule: bind [
		any [p: 
			; func        brc
			[178.34.34 | 142.128.110](
				address: back p 
				keep reduce ['box (caret-to-offset rt address/1/1) + rt/offset + 0x2
					(caret-to-offset rt pos: address/1/1 + address/1/2) + (as-pair 0 -2 + rich-text/line-height? rt pos) + rt/offset
				]
			)
		| skip
		]
	] :collect
	scroll: func [pos [integer!]][
		rt/offset: as-pair 0 pos - 1 * negate rich-text/line-height? rt 1 
		recolor
		show bs
	]
	adjust-scroller: func [][
		rt/size/y: second size-text rt 
		scr/page-size: bs/size/y / rich-text/line-height? rt 1
	]
	reposition: func [line-num [integer!]][
		if any [
			line-num < (scr/position)
			line-num > (scr/position + scr/page-size - 1)
		][
			scr/position: max 0 line-num - (scr/page-size / 3) 
			rt/offset: as-pair 0 2 + negate scr/position * rich-text/line-height? rt 1 
			recolor
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
				pos1: find pos [backdrop 0.200.0]
				pos1/2: 100.255.100
				pos1: skip pos1 pick [-2 4] prev
				either prev [
					unless pos1/1 = 100.255.100 [pos1: next find/last pos 'backdrop]
				][
					if empty? pos1 [pos1: next find pos 'backdrop]
				]
				pos1/1: 0.200.0
				reposition count-lines at rt/text pos1/-2/1
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
					last-find/3: index? last-find/2: str1
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
						i1: index? str1
						len: length? needle
						;clear pos
						repend rt/data [as-pair i1 len 'backdrop cyan]
						reposition count-lines str1
						repend clear last-find ['find str1 i1 len]
					][];TBD "Not found" message
				]
			]
			show [
				clear pos
				i0: index? str: find/reverse/tail at rt/text offset-to-caret rt event/offset skp4
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
				repend clear last-find ['show str i0 len]
				show rt
			]
			prev next [find-again event/picked = 'prev]
			insp [
				
			]
		]
	]
	recolor: does [
		text-start: at rt/text offset-to-caret rt ofs: as-pair 0 0 - rt/offset/y
		text-end: at rt/text offset-to-caret rt ofs + bs/size
		if pos [move/part pos save-bd length? pos]
		clear at rt/data 6
		collect/into [parse text-start rule] rt/data
		clear at layer/draw 5
		collect/into [parse rt/data box-rule] layer/draw
		pos: tail rt/data
		if not empty? save-bd [move/part save-bd pos length? save-bd]
		system/view/platform/redraw layer
	]
	change-font-size: func [inc][
		rt/data/5: rt/data/5 + inc 
		show rt 
		set-caret none 
		adjust-scroller 
		reposition count-lines at rt/text curpos 
	]
	adjust-markers: func [pos1 [string!] /length len /only /local i1 pos3][
		len: any [len 1]
		i1: either found: find/reverse/tail pos1 skp2 [index? found][1]
		pos3: rt/data
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
	set-caret: func [e [event! none! integer!]][
		case [
			event? e [ 
				switch e/type [probe e/key
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
									min 1 + length? rt/text curpos + 1
								]
							]
							left [
								curpos: either e/ctrl? [
									either found: find/reverse/tail at rt/text curpos - 1 skp2 [index? found][1]
								][
									max 1 curpos - 1
								]
							]
							down [
								curpos: min 1 + length? rt/text offset-to-caret rt 
									((caret-to-offset rt curpos) + as-pair 0 3 + rich-text/line-height? rt 1)
							]
							up [curpos: max 1 offset-to-caret rt (caret-to-offset rt curpos) - 0x3]
							page-down [
								curpos: min 1 + length? rt/text offset-to-caret rt (
									(caret-to-offset rt curpos) + as-pair 0 bs/size/y
								)
							]
							page-up [
								curpos: max 1 offset-to-caret rt (
									(caret-to-offset rt curpos) - as-pair 0 bs/size/y
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
							#"^A" [anchor: 1 curpos: 1 + length? rt/text];Select all
							#"^C" [;Copy
								if rt/data/1/y > 0 [write-clipboard copy/part at rt/text rt/data/1/x rt/data/1/y dont-move: true]
							]
							#"^X" [;Cut
								if rt/data/1/y > 0 [
									write-clipboard copy/part pos1: at rt/text rt/data/1/x len: rt/data/1/y 
									remove/part pos1 len 
									recolor
									set-caret rt/data/1/x 
								]
							]
							#"^V" [;Paste
								parse txt: read-clipboard [any [change [cr lf] lf | skip]]
								either rt/data/1/y > 0 [
									change/part at rt/text curpos: rt/data/1/x txt rt/data/1/y
								][
									insert at rt/text curpos txt
								]
								recolor
								set-caret curpos + length? txt
							]
							delete [
								either rt/data/1/y > 0 [
									remove/part at rt/text curpos: rt/data/1/x rt/data/1/y
									show rt
									recolor
									set-caret curpos
								][
									if curpos <= length? rt/text [
										remove pos1: at rt/text curpos
										adjust-markers/length pos1 -1
									]
								]
							]
							#"^H" [;Backspace
								either rt/data/1/y > 0 [
									remove/part pos1: at rt/text curpos: rt/data/1/x rt/data/1/y
									recolor
									set-caret curpos
								][
									if curpos > 1 [
										remove pos1: at rt/text curpos: curpos - 1
										set-caret curpos
										adjust-markers/length pos1 -1
									]
								]
							]
							#"^[" [;Escape
								clear pos clear last-find show rt 
							]
						][
							curpos: index? pos1: insert at rt/text curpos e/key
							if find opn-brc e/key [insert pos1 opp/(e/key)]
							adjust-markers pos1
						]
					]
				]
				either any [find [#"^A" #"^C"] e/key all [e/shift? any [e/type = 'down find [left right down up end home] e/key]]] [
					rt/data/1: as-pair min anchor curpos absolute anchor - curpos
				][
					anchor: curpos rt/data/1/2: 0
				]
			]
			integer? e [anchor: curpos: e rt/data/1/2: 0]
		]
		caret/2: caret-to-offset rt curpos
		caret/3: as-pair caret/2/1 caret/2/2 + rich-text/line-height? rt 1
		unless dont-move [reposition count-lines at rt/text curpos]
	]
	offset: func [e][either e/face = rt [e/offset][e/offset - rt/offset]]
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
					tips: radio 45 "Tips" [set-focus bs cnt: 0 attempt [show lay]];remove `attempt` -> Stack overflow!
					expr: radio 45 "Expr" [set-focus bs cnt: 0 attempt [show lay]];Stack overflow!
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
					button "Eval" [if all [step/data empty? last-find] [do-step]]
					button "Next" [either all [step/data empty? last-find] [next-step][find-again false]]
					button "Into" [either all [step/data empty? last-find] [into-step][find-again false]]
					button "Recolor" [recolor set-focus bs attempt [show lay]]
					button "A+" 30 [change-font-size 1]
					button "A-" 30 [change-font-size -1]
				]
			]
		]
		space 0x0
		return pad 10x10 
		bs: base white with [
			size: initial-size ;- 15x0
			pane: layout/only [
				origin 0x0 
				rt: rich-text "Red []^/" with [
					size: initial-size - 15x0
					data: [1x0 backdrop silver 1x0 10]
					menu: find-menu
				]
				cursor I-beam 
				on-time [face/draw/2: pick [glass black] face/draw/2 = 'black show face]
				on-menu [find-word event]
				at 0x0 layer: box with [
					size: initial-size - 15x0
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
							any [expr/data all [edit/data ctrl?]] [
								clear pos ;back find pos 'backdrop
								show rt
							]
						]
					][
						str: find/reverse/tail br: at rt/text offset-to-caret rt event/offset - rt/offset skp
						case [
							br: any [find/match br brc find/match back str brc][
								in-brc: yes
								br-scope back br
								show bs
							]
							tips/data [
								attempt [wrd: to-word copy/part str find str skp2]
								either event/ctrl? [
									tip/text: rejoin [type? fn: get :wrd "!^/"]
									append tip/text mold spec-of :fn
									if function? :fn [append tip/text mold body-of :fn]
								][
									tip/text: help-string :wrd
								]
								tip/size/y: 20 + second size-text tip
								either (event/offset/x - face/offset/x) > tip/size/x [
									tip/offset: min 
										max 0x40 event/offset + face/offset + as-pair 0 - tip/size/x - 30 0 - (tip/size/y / 2)
										bs/size - tip/size
								][
									tip/offset: min 
										max 0x40 event/offset + face/offset + as-pair 30 0 - (tip/size/y / 2)
										bs/size - tip/size
								]
								tip/data/1/2: length? tip/text
								tip/visible?: yes
								show tip
							]
							any [expr/data all [edit/data ctrl?]] [scope str]
						]
					]
				]
			]
			flags: 'scrollable
		]
		on-created [
			put get-scroller face 'horizontal 'visible? no
			scr: get-scroller face 'vertical
		]
		on-scroll [
			;print [ event/type event/key event/picked event/flags ]
			;foreach attr exclude words-of scr [parent window][print [attr ":" get attr]]
			;foreach attr exclude system/catalog/accessors/event! [face parent window][print [attr ":" attempt [get/any event/:attr]]]
			unless event/key = 'end [
				scroll scr/position: min max 1 switch event/key [
					track [event/picked]
					up [scr/position - 1]
					page-up [scr/position - scr/page-size]
					down [scr/position + 1]
					page-down [scr/position + scr/page-size]
				] scr/max-size
				clear at layer/draw 5
				collect/into [parse rt/data box-rule] layer/draw
				pos: tail rt/data
				show bs
			]
		]
		on-wheel [scroll scr/position: min max 1 scr/position - (3 * event/picked) scr/max-size - scr/page-size + 1]
		on-key [
			switch/default event/key [
				left up [case [
					all [step/data empty? last-find] [prev-step]
					all [find [show find] last-find/1][find-again true] ;tips/data 
					edit/data [set-caret event]
				]]
				right [case [
					all [step/data empty? last-find] [next-step]
					all [find [show find] last-find/1] [find-again false] ;tips/data 
					edit/data [set-caret event]
				]]
				down [case [
					all [step/data empty? last-find] [into-step]
					all [find [show find] last-find/1] [find-again false] ;tips/data 
					edit/data [set-caret event]
				]]
				#"^M" [either all [step/data empty? last-find] [do-step][set-caret event]] ;enter
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
				left-control right-control [ctrl?: no clear pos show rt]
			]
		]
		on-down [
			either step/data [;any [step/data event/ctrl?] [
				;if not step/data [do-actor step none 'change show step]
				clear pos
				if step/data [repend steps [_str1 _str2]]
				_i1: index? _str1: find/reverse/tail at rt/text offset-to-caret rt offset event skp
				_i2: index? _str2: arg-scope _str1 none
				repend rt/data [as-pair _i1 _i2 - _i1 'backdrop sky]
				if (count-lines _str2) > (scr/position + scr/page-size)[
					scr/position: count-lines _str1
					rt/offset: as-pair 0 2 + negate scr/position * rich-text/line-height? rt 1 
				]
				show bs
			][set-caret event]
		]
		at 0x0 tip: rich-text "" 400x50 left navy hidden with [data: [1x0 255.255.255]]
		do [rt/parent: bs layer/parent: bs]
	] [
		offset: 300x50
		menu: ["File" ["New" new "Open..." open "Save" save "Save as..." save-as]]; "Save copy" save-copy]]
		actors: object [
			max-x: max-y: 0
			cur-y: 10
			lim: func [:z face][face/offset/:z + face/size/:z]
			opts: options/pane
			on-menu: func [face [object!] event [event!]][
				switch event/picked [
					new [open-file none face/extra: none]
					open [open-file second face/extra: split-path request-file/title/filter "Open file" ["Red" "*.red"]]
					save [write face/extra/2 rt/text]
					save-as [face/extra: split-path file: request-file/save/title "Save file" write file rt/text]
					save-copy []
				]
			]
			on-resizing: func [face [object!] event [event!] /local _last diff][
				if any [
					0 > diff: face/size/x - options/size/x
					all [diff > 0 options/size/x < 900]
				][
					max-y: 0
					max-x: 0 
					cur-y: 10
					options/size/x: face/size/x; - 20
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
				bs/size: face/size - 12x60
				rt/size/x: layer/size/x: bs/size/x - 18
				scr/max-size: rich-text/line-count? rt
				scr/page-size: bs/size/y / rich-text/line-height? rt 1
				show face
			]
		]
	] 'resize
	renew-view
	do-events
]
