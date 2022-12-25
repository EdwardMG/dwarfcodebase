if exists("b:current_syntax") | finish | endif

syntax keyword Empty X
syntax keyword Connector -
syntax match You /[a-z]/
syntax match Marked /[A-WYZ]/

highlight Empty ctermfg=grey
highlight You ctermfg=cyan cterm=bold
highlight Marked ctermfg=red cterm=bold
highlight Connector ctermfg=yellow cterm=bold

" referenced in the popup function
hi DwarfPopup ctermbg=black

let b:current_syntax = "dwarfcodebase"

