Red [
	Author: "Toomas Vooglaid"
	Date: 2019-01-14
	Last: 2019-01-16
	Purpose: {Study of syntax highlighting}
]
#include %../utils/info.red
context [
	ws: charset " ^/^-"
	opn: charset "[("
	cls: charset ")]"
	brc: union opn cls
	brc2: union brc charset "{}"
	skp: union ws brc
	skp2: union skp charset "/"
	br: s: s2: none
	opp: "[][()({}{"
	initial-size: 800x800
	highlight: function [s1 s2 style] bind [keep as-pair i: index? s1 (index? s2) - i keep style] :collect
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
			color: either empty? stack [gray + 100][i2: index? next s 255.220.220]
			repend rt/data [as-pair i1 i2 - i1 'backdrop color]
		][
			
		]
	]
	arg-scope: func [str type /local el s1 s2 i2][
		el: load/next str 's2
		el2: load/next s2 's3
		either op? attempt [get/any el2][
			s2: arg-scope s3 none
		][
			switch type?/word el [
				set-word! [s2: scope s2]
				word! [if any-function? get/any el [s2: scope str]]
				path! [if any-function? get/any first el [s2: scope str]]
			]
		]
		s2
	]
	scope: func [str /local fn fnc inf color arg i1 i2 s1 s2][
		fn: load/next str 's1
		fnc: either word? fn [fn][first fn]
		inf: info :fnc
		color: yello;silver + 100 ;tanned + 30
		foreach arg inf/arg-names [
			i2: index? s2: arg-scope s1 inf/args/:arg
			while [find ws s1/1][s1: next s1]
			i1: index? s1
			repend rt/data [as-pair i1 i2 - i1 'backdrop color: color - 30]
			s1: :s2
		]
		if path? fn [
			foreach ref next fn [
				if 0 < length? refs: inf/refinements/:ref [
					foreach type values-of refs [
						i2: index? s2: arg-scope s1 type
						while [find ws s1/1][s1: next s1]
						i1: index? s1
						repend rt/data [as-pair i1 i2 - i1 'backdrop color: color - 30]
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
				string? el 		[highlight s s2 gray]
				any-string? el 	[highlight s s2 orange]
				refinement? el	[highlight s s2 papaya]
				word? el 		[case [
					any-function? get/any el [highlight s s2 brick]; reduce ['bold blue]]
					immediate? get/any el [highlight s s2 leaf]
				]]
				path? el 		[if any-function? get/any el/1 [highlight s s2: find s #"/" brick]];reduce ['bold blue]]]
				any-word? el 	[highlight s s2 navy]
				any-path? el 	[highlight s s2 water]
				number? el 		[highlight s s2 mint]
				scalar? el 		[highlight s s2 teal]
				immediate? el 	[highlight s s2 leaf]
			]
		) :s2
	]]
	filter: func [series _end][
		collect [foreach file series [if find/match skip tail file -4 _end [keep file]]]
	]
	box-rule: bind [
		any [p: 
			; func         brc
			[178.34.34 | 142.128.110](;'bold (
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
	]
	system/view/auto-sync?: off
	view/options [
		backdrop white
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
			clear rt/data
			collect/into [parse rt/text rule] rt/data
			clear at layer/draw 5
			collect/into [parse rt/data box-rule] layer/draw
			show bs
		]
		button "Dir..." [
			files/data: filter read change-dir request-dir/dir normalize-dir %. ".red"
			clear rt/data clear rt/text
		] 
		panel 200x30 white [origin 0x0 help: radio "Helpstring" data yes expr: radio "Expressions"]
		return bs: base white with [
			size: initial-size - 15x0
			pane: layout/only [
				origin 0x0 
				rt: rich-text "" with [
					size: initial-size - 15x0
					data: []
				]
				at 0x0 layer: box with [
					size: initial-size - 15x0
				] 
				draw [pen off fill-pen 0.0.0.254]
				on-over [
					either event/away? [
						case [
							in-brc [
								clear skip tail rt/data -3
								in-brc: no
								show bs
							]
							help/data [
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
							help/data [
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
					up left [scr/position - 1]
					page-up page-left [scr/position - scr/page-size]
					down right [scr/position + 1]
					page-down page-right [scr/position + scr/page-size]
				] scr/max-size
			]
			show face
		]
		at 0x0 tip: box "" 350x100 left linen hidden
		do [rt/parent: bs layer/parent: bs]
	][offset: 300x30]
]