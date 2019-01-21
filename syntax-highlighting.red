Red [
	Author: "Toomas Vooglaid"
	Date: 2019-01-14
	Last: 2019-01-21
	Purpose: {Study of syntax highlighting}
]
do %info.red
context [
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
	opp: "[][()({}{"
	rt: bs: br: s: s1: s2: i: i1: i2: in-brc: pos: str1: str2: blk: res: wheel-pos: opts: len: line-num: needle: none ;layer: 
	steps: clear []
	initial-size: 800x400
;	find-matching: func [str needle][
;		
;	]
	highlight: function [s1 s2 style] bind [keep as-pair i: index? s1 (index? s2) - i keep style] :collect
	skip-some: func [str chars][while [find/match str chars][str: next str] str]
	count-lines: function [pos][i: 0 parse head pos [any [s: if (s = pos) thru end | newline (i: i + 1) | skip]] i]
	prev-step: does [
		unless empty? steps [
			set [str1 str2] take/last/part steps 2
			i1: index? str1
			i2: index? str2
			clear pos
			repend rt/data [as-pair i1 i2 - i1 'backdrop sky]
			if (count-lines str1) < scr/position [
				scr/position: count-lines str1
				rt/offset: layer/offset: as-pair 0 2 + negate scr/position * rich-text/line-height? rt 1
			]
			show bs
		]
	]
	next-step: does [
		repend steps [str1 str2]
		str2: skip-some str2 cls2
		while [str2/1 = #";"][
			str2: arg-scope str2 none
			str2: skip-some str2 cls2
		]
		i1: index? str1: str2
		move-backdrop str2
	]
	move-backdrop: func [str][
		i2: index? str2: arg-scope str none
		clear pos
		repend rt/data [as-pair i1 i2 - i1 'backdrop sky]
		if (count-lines str2) > (scr/position + scr/page-size)[
			scr/position: count-lines str
			rt/offset: layer/offset: as-pair 0 2 + negate scr/position * rich-text/line-height? rt 1
		]
		show bs
	]
	br-scope: function [br][
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
	left-scope: func [str /local i][i: 0
		until [str: back str not find/match str ws]
		either #")" = str/1 [find/reverse str "("][find/reverse/tail str skp]
	]
	arg-scope: func [str type /left /right /local el el2 s0 s1 s2 i2 _][
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
					path! [if any-function? get/any first el [s1: scope str]]
				]
			]
		]
		s1
	]
	scope: func [str /local /color col fn fnc inf clr arg i1 i2 s1 s2][
		fn: load/next str 's1
		fnc: either word? fn [fn][first fn]
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
		if path? fn [
			foreach ref next fn [
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
	rule: [any [s:
		ws
	|	brc (s2: next s highlight s s2 rebolor)
	|	#";" [if (s2: find s newline) | (s2: tail s)] (highlight s s2 reduce ['italic beige - 50]) :s2
	|	(el: load/next s 's2)(
			case [
				string? el		[highlight s s2 gray]
				any-string? el	[highlight s s2 orange]
				refinement? el	[highlight s s2 papaya]
				word? el		[case [
					any-function? get/any el [highlight s s2 brick]; reduce ['bold blue]]
					immediate? get/any el [highlight s s2 leaf]
				]]
				path? el		[;TBD Treat different paths: maps, blocks objects...
					if any-function? either object? get/any el/1 [get/any el][get/any el/1] [highlight s s2: find s #"/" brick]
				] 
				any-word? el	[highlight s s2 navy]
				any-path? el	[highlight s s2 water]
				number? el		[highlight s s2 mint]
				scalar? el		[highlight s s2 teal]
				immediate? el	[highlight s s2 leaf]
			]
		) :s2
	]]
	filter: func [series _end][
		collect [foreach file series [if find/match skip tail file -4 _end [keep file]]]
	]
	box-rule: bind [
		any [p: 
			; func         brc
			[178.34.34 | 142.128.110](
				address: back p 
				keep reduce ['box caret-to-offset rt address/1/1 
					(caret-to-offset rt pos: address/1/1 + address/1/2) + as-pair 0 -2 + rich-text/line-height? rt pos
				]
			)
		| skip
		]
	] :collect
	scroll: func [pos][
		rt/offset: layer/offset: as-pair 0 pos - 1 * negate rich-text/line-height? rt 1
		show bs
	]
	reposition: func [line-num][
		if any [
			line-num < (scr/position + 1)
			line-num > (scr/position + scr/page-size - 1)
		][
			scr/position: max 1 line-num - (scr/page-size / 3) 
			rt/offset: layer/offset: as-pair 0 2 + negate scr/position * rich-text/line-height? rt 1
		]
	]
	ask-find: has [needle][
		view/flags [
			text "Find what" fnd: field 100 focus on-enter [needle: face/text unview]
			button "OK" [needle: fnd/text unview]
		][modal popup]
		needle
	]
	find-menu: ["Find" fnd "Show" shw "Prev" prv "Next" nxt]
	find-word: func [event /local _last][
		_last: []; act str1 i1 len
		switch event/picked [
			fnd [
				clear pos
				if needle: ask-find [
					either str1: find rt/text needle [
						i1: index? str1
						len: length? needle
						;clear pos
						repend rt/data [as-pair i1 len 'backdrop cyan]
						reposition count-lines str1
						repend clear _last ['find str1 i1 len]
					][];TBD "Not found" message
				]
			]
			shw [
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
				repend clear _last ['show str i0 len]
			]
			prv nxt [
				prv: event/picked = 'prv
				switch _last/1 [
					show [
						pos1: find rt/data [backdrop 0.200.0]
						pos1/2: 100.255.100
						pos1: skip pos1 pick [-2 4] prv
						either prv [
							unless pos1/1 = 100.255.100 [pos1: next find/last rt/data 'backdrop]
						][
							if empty? pos1 [pos1: next find rt/data 'backdrop]
						]
						pos1/1: 0.200.0
						reposition count-lines at rt/text pos1/-2/1
					]
					find [
						clear pos
						if str1: either prv [
							any [
								either head? _last/2 [
									find/reverse tail rt/text needle
								][
									find/reverse back _last/2 needle
								] 
								find/reverse tail rt/text needle
							]
						][
							any [find next _last/2 needle find rt/text needle]
						][
							_last/3: index? _last/2: str1
							repend rt/data [as-pair _last/3 _last/4 'backdrop cyan]
							reposition count-lines str1
						]
					]
				]
			]
		]
		show rt;event/face/parent
	]
	system/view/auto-sync?: off
	view/flags/options/tight [
		backdrop white
		panel 800x50 [
			origin 0x0 
			options: panel 740x50 [
				panel [
					origin 0x0 
					files: drop-list 200 with [data: read %.] 
					on-change [
						rt/offset: layer/offset: 0x0
						rt/text: read pick face/data face/selected
						show rt
						rt/size/y: layer/size/y: second size-text rt
						scr/max-size: rich-text/line-count? rt
						scr/position: 1
						scr/page: 1
						scr/page-size: bs/size/y / rich-text/line-height? rt 1
						clear steps
						clear rt/data
						collect/into [parse rt/text rule] rt/data
						clear at layer/draw 5
						collect/into [parse rt/data box-rule] layer/draw
						pos: tail rt/data
						show bs
						if step/data [step/actors/on-change step none]
					]
					button "Dir..." [
						files/data: filter read change-dir request-dir/dir normalize-dir %. ".red"
						clear rt/data clear rt/text
						show files
					] 
				]
				panel 150x30 [
					origin 0x0 
					tips: radio 45 "Tips" data yes 
					expr: radio 45 "Expr" 
					step: radio 45 "Step" [
						clear pos
						either face/data [
							either empty? steps [
								str1: head rt/text
								scr/position: 1
								rt/offset: layer/offset: 0x0
								i2: index? str2: arg-scope str1 none
								;pos: tail rt/data
								repend rt/data [as-pair 1 i2 - 1 'backdrop sky]
							][
								prev-step
							]
						][
							repend steps [str1 str2]
						]
						show bs
					]
				]
				panel [
					origin 0x0
					button "Prev" [prev-step]
					button "Eval" [do copy/part str1 str2 next-step]
					button "Next" [next-step]
					button "Into" [
						repend steps [str1 str2]
						either find/match opn str1/1 [
							i1: index? str1: next str1
							str1: skip-some str1 ws
						][
							i1: index? str1: find/tail str1 skp
						]
						move-backdrop str1
					]
				]
			]
		]
		space 0x0
		return pad 10x10 
		bs: base white with [
			size: initial-size ;- 15x0
			pane: layout/only [
				origin 0x0 
				rt: rich-text "" with [
					size: initial-size - 15x0
					data: []
					menu: find-menu
				]
				on-menu [find-word event]; show rt]
				;on-mid-down [wheel-pos: event/offset] ; TBD?
				;all-over on-over [
				;	if event/mid-down? [
				;		rt/offset: layer/offset: as-pair 0 
				;			max 
				;				min 0 rt/offset/y + (wheel-pos/y - event/offset/y) 
				;				negate rt/size/y - bs/size/y
				;		show bs
				;	]
				;]
				at 0x0 layer: box with [
					size: initial-size - 15x0
					menu: find-menu
				] 
				draw [pen off fill-pen 0.0.0.254]
				on-menu [find-word event]; show face]
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
							expr/data [
								clear back find rt/data 'backdrop
								show rt
							]
						]
					][
						str: find/reverse/tail br: at rt/text offset-to-caret rt event/offset skp
						case [
							br: any [find/match br brc find/match back str brc][
								in-brc: yes
								br-scope back br
								show bs
							]
							tips/data [
								attempt [
									wrd: to-word copy/part str find str skp2
									tip/text: help-string :wrd
									tip/size/y: 20 + second size-text tip
									tip/offset: min 
										max 0x0 event/offset + face/offset + as-pair 30 0 - (tip/size/y / 2)
										bs/size - tip/size
									tip/visible?: yes
									show tip
								]
							]
							expr/data [scope str]
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
		on-down [
			if step/data [
				clear pos
				repend steps [str1 str2]
				i1: index? str1: find/reverse/tail at rt/text offset-to-caret rt event/offset skp
				i2: index? str2: arg-scope str1 none
				repend rt/data [as-pair i1 i2 - i1 'backdrop sky]
				if (count-lines str2) > (scr/position + scr/page-size)[
					scr/position: count-lines str1
					rt/offset: layer/offset: as-pair 0 2 + negate scr/position * rich-text/line-height? rt 1
				]
				show bs
			]
		]
		on-key [probe event/key]
		at 0x0 tip: box "" 350x50 left linen hidden
		do [rt/parent: bs layer/parent: bs]
	] 'resize [
		offset: 300x50
		actors: object [
			max-x: max-y: 0
			cur-y: 10
			lim: func [:z face][face/offset/:z + face/size/:z]
			opts: options/pane
			on-resizing: func [face event /local _last diff][
				if any [
					0 > diff: face/size/x - options/size/x
					all [diff > 0 options/size/x < 740]
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
	]
]
