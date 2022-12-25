if exists("b:current_syntax") | finish | endif

syntax keyword Empty X
syntax keyword Connector -
syntax match You /[a-z]/
syntax match Marked /[A-WYZ]/


syntax keyword Zero 0
syntax keyword One 1
syntax keyword Two 2
syntax keyword Three 3
syntax keyword Four 4
syntax keyword Five 5
syntax keyword Six 6
syntax keyword Seven 7
syntax keyword Eight 8
syntax keyword Nine 9

highlight Zero  ctermfg=cyan
highlight One   ctermfg=78
highlight Two   ctermfg=45
highlight Three ctermfg=69
highlight Four  ctermfg=blue
highlight Five  ctermfg=184
highlight Six   ctermfg=red
highlight Seven ctermfg=165
highlight Eight ctermfg=130
highlight Nine  ctermfg=57

highlight Empty ctermfg=grey
highlight You ctermfg=cyan cterm=bold
highlight Marked ctermfg=red cterm=bold
highlight Connector ctermfg=yellow cterm=bold

" referenced in the popup function
hi DwarfPopup ctermbg=black

let b:current_syntax = "dwarfcodebase"

