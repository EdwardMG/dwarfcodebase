let s:prg = $HOME."/bin/dwarfcodebase"
let s:title = "Dwarf Codebase"

let g:dwarfpopup = 0

fu! DrawDwarfPopup(content)
  if g:dwarfpopup | call popup_clear(g:dwarfpopup) | endif
  let g:dwarfpopup = popup_create(
        \ a:content,
        \ { 'padding':   [0,0,0,0]
        \ , 'line':      1
        \ , 'col':       &columns
        \ , 'pos':       'topright'
        \ , 'scrollbar': 1
        \ , 'hightlight': "DwarfPopup"
        \ }
        \)

  call setwinvar(g:dwarfpopup, '&wincolor', 'DwarfPopup')
  call setbufvar(
        \  winbufnr( g:dwarfpopup ),
        \  '&filetype', 'dwarfcodebase')
endfu

fu! DrawDwarfCodebase()
  let r = systemlist(s:prg)[0:-2]
  call DrawDwarfPopup(r)
endfu

fu! InitDwarfCodebase()
  call system(s:prg." p " . expand('%:p'))
  call DrawDwarfCodebase()
endfu

fu! MoveDwarfCodebase(a)
  let r = systemlist(s:prg . ' ' . a:a)
  call popup_clear()
  call DrawDwarfPopup(r[0:-2])
  if r[-1] != ""
    exe "edit ".r[-1]
  endif
endfu

fu! EraseLabelDwarfCodebase()
  let r = systemlist(s:prg . ' e')
  call popup_clear()
  call DrawDwarfPopup(r[0:-2])
endfu

fu! LabelDwarfCodebase(a)
  let r = systemlist(s:prg . ' x' . a:a . ' ' . shellescape(expand('%:p')))[0:-2]
  call popup_clear()
  call DrawDwarfPopup(r)
endfu

if !exists('g:DwarfMode') | let g:DwarfMode = 0 | endif

if !exists('g:dwarf_mode')
  let g:dwarf_mode = 0
  call add(g:nyao_modes, { -> g:dwarf_mode })
endif

fu! DwarfMode()
  call DeactivateOtherModes('DwarfMode')
  let g:dwarf_mode = !g:dwarf_mode
  if !exists('g:jor_old_mappings')
    let g:jor_old_mappings   = {}
  endif
  if !exists('g:jor_old_v_mappings')
    let g:jor_old_v_mappings = {}
  endif

  if g:dwarf_mode | let g:nyao_active_mode = 'DwarfMode' | endif

  let keys_to_map   = ['j', 'k', 'h', 'l', 'f', 'd', 'xo', 'e', '<Tab>']
  let v_keys_to_map = []

  for n in keys_to_map
    let g:jor_old_mappings[ n ] = mapcheck( n, 'n')
  endfor
  for n in v_keys_to_map
    let g:jor_old_v_mappings[ n ] = mapcheck( n, 'v')
  endfor

  if g:dwarf_mode

    call DrawDwarfCodebase()

    " this is not working? weird
    if &bg=="dark"
      hi StatusLine ctermbg=136 ctermfg=black
    else
      hi StatusLine ctermbg=white ctermfg=brown
    endif
    nno <silent> h :call MoveDwarfCodebase('h')<CR>
    nno <silent> j :call MoveDwarfCodebase('j')<CR>
    nno <silent> k :call MoveDwarfCodebase('k')<CR>
    nno <silent> l :call MoveDwarfCodebase('l')<CR>
    nno <nowait><silent> f :call MoveDwarfCodebase('f')<CR>
    nno <nowait><silent> d :call MoveDwarfCodebase('d')<CR>

    nno <silent> e :call EraseLabelDwarfCodebase()<CR>

    for letter in split('a b c d e f g h i j k l m n o p q r s t u v w y z') " no x
      exe "nno <silent> x".letter." :call LabelDwarfCodebase('".toupper(letter)."')<CR>"
    endfor

    nno <silent> <Tab> :call DwarfMode()<CR>

  else " exit dwarf mode
    let g:nyao_active_mode = ""
    for n in keys_to_map
      if (has_key( g:jor_old_mappings, n ) ) && g:jor_old_mappings[ n ]
        exe 'nno '.n.' '. g:jor_old_mappings[ n ]
        unlet g:jor_old_mappings[ n ]
      else
        exe 'nno '.n.' '.n
      endif
    endfor
    call ResetStatusColour()

    for n in v_keys_to_map
      if (has_key( g:jor_old_mappings, n ) ) && g:jor_old_v_mappings[ n ]
        exe 'vno '.n.' '. g:jor_old_v_mappings[ n ]
        unlet g:jor_old_v_mappings[ n ]
      else
        exe 'vno '.n.' '.n
      endif
    endfor
    call UnbindMode('DwarfMode') " Do I need this? probably
    for letter in split('a b c d e f g h i j k l m n o p q r s t u v w y z') " no x
      exe "nunmap x".letter
    endfor
  endif
endfu

nno <silent> cmd :call DwarfMode()<CR>
" still not both under homerow... maybe just dk and give up survey mode which
" I also don't use
nno <silent> dh :call DwarfMode()<CR>
command! Dwarf call DwarfMode()


augroup Dwarf
    autocmd!
    " When NOT in dwarf mode, we want the minimap to update as we move around,
    " in case we forget we already set a file or it's on a much deeper level
    " or whatever
    " also nicely puts us somewhere sensible when we startup
    " not working anymore for some reason
    au BufEnter * if (g:dwarf_mode == 0 && system(s:prg." p " . expand('%:p')) == "1") | call DrawDwarfCodebase() | endif
augroup END

