Red []
info-ctx: context [
	get-function: function [path][
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

	set 'info func ['fn	/local intr ars refs locs ret arg ref typ irefs][
		intr: copy "" ars: make map! copy [] refs: make map! copy [] locs: copy [] ret: copy [] irefs: copy [] typ: ref-arg: ref-arg-type: none
		;if path? fn [irefs: copy next to-block fn fn: first fn]
		if path? fn [irefs: copy skip to-block fn length? fn: get-function fn if 1 = length? fn [fn: fn/1]]
		if lit-word? fn [fn: to-word fn]
		unless any-function? get fn [
			cause-error 'user 'message ["Only function types accepted!"]
		]
		out: make map! copy []
		specs: spec-of get fn 
		parse specs [
			opt [set intr string!]
			any [set arg [word! | lit-word! | get-word!] opt [set typ block!] opt string! (put ars arg either typ [typ][[any-type!]])]
			any [set ref refinement! [
				if (ref <> /local) (put refs to-lit-word ref make map! copy []) 
					opt string! 
					any [set ref-arg word! opt [set ref-arg-type block!] 
						(put refs/(to-word ref) to-lit-word ref-arg either ref-arg-type [ref-arg-type][[any-type!]])
					]
					opt string!
				|	any [set loc word! (append locs loc) opt string!] 
					opt [set-word! set ret block!]
			]]
		]
		
		make object!  [
			name: 		either path? fn [last fn][to-word fn];to-word fn 
			intro: 		intr 
			args: 		ars 
			refinements: refs 
			locals: 	locs 
			return: 	ret 
			spec: 		specs 
			type: 		type? get fn
			arg-num: 	length? args
			arg-names: 	copy keys-of args
			arg-types: 	copy values-of args
			ref-names: 	copy keys-of refinements
			ref-types: 	copy values-of refinements
			ref-num:	length? refinements
		]
	]
]
