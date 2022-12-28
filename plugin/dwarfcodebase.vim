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
  let r = systemlist(s:prg . ' m' . a:a . ' ' . shellescape(expand('%:p')))
  if r[-1][0] == "/"
    let map = r[0:-2]
    call popup_clear()
    call DrawDwarfPopup(map)
  else
    echoerr r[-1]
  endif
endfu

if !exists('g:DwarfMode') | let g:DwarfMode = 0 | endif

if !exists('g:dwarf_mode')
  let g:dwarf_mode = 0
  if !exists('g:nyao_modes')
    call add(g:nyao_modes, { -> g:dwarf_mode })
  endif
endif

fu! DwarfMode()
  if !exists('g:nyao_modes')
    call DeactivateOtherModes('DwarfMode')
  endif
  let g:dwarf_mode = !g:dwarf_mode
  if !exists('g:dwarf_old_mappings')
    let g:dwarf_old_mappings   = {}
  endif
  if !exists('g:dwarf_old_v_mappings')
    let g:dwarf_old_v_mappings = {}
  endif

  if g:dwarf_mode | let g:nyao_active_mode = 'DwarfMode' | endif

  let keys_to_map   = ['j', 'k', 'h', 'l', 'f', 'd', 'xo', 'e', 'c', 'v', '<Tab>']
  for letter in split('a b c d e f g h i j k l m n o p q r s t u v w y z') " no x
    call add(keys_to_map, "m".letter)
  endfor

  let v_keys_to_map = []

  if g:dwarf_mode
    for n in keys_to_map
      " mapcheck looks for matches, maparg checks exact match
      let g:dwarf_old_mappings[ n ] = maparg( n, 'n')
    endfor
    for n in v_keys_to_map
      let g:dwarf_old_v_mappings[ n ] = maparg( n, 'v')
    endfor

    call DrawDwarfCodebase()

    if !exists('g:nyao_modes')
      if &bg=="dark"
        hi StatusLine ctermbg=171 ctermfg=black
      else
        hi StatusLine ctermbg=white ctermfg=brown
      endif
    endif
    nno <silent> h :call MoveDwarfCodebase('h')<CR>
    nno <silent> j :call MoveDwarfCodebase('j')<CR>
    nno <silent> k :call MoveDwarfCodebase('k')<CR>
    nno <silent> l :call MoveDwarfCodebase('l')<CR>
    nno <nowait><silent> f :call MoveDwarfCodebase('f')<CR>
    nno <nowait><silent> d :call MoveDwarfCodebase('d')<CR>
    nno <nowait><silent> c :call MoveDwarfCodebase('c')<CR>
    nno <nowait><silent> v :call MoveDwarfCodebase('v')<CR>

    nno <silent> e :call EraseLabelDwarfCodebase()<CR>

    for letter in split('a b c d e f g h i j k l m n o p q r s t u v w y z') " no x
      exe "nno <silent> m".letter." :call LabelDwarfCodebase('".toupper(letter)."')<CR>"
    endfor

    nno <silent> <Tab> :call DwarfMode()<CR>

  else " exit dwarf mode
    call system(s:prg." p " . expand('%:p'))
    call DrawDwarfCodebase()
    let g:nyao_active_mode = ""
    for n in keys_to_map
      if has_key( g:dwarf_old_mappings, n )
            \ && type(g:dwarf_old_mappings[ n ]) == 1
            \ && len(g:dwarf_old_mappings[ n ]) > 0
        exe 'nno '.n.' '. g:dwarf_old_mappings[ n ]
      else
        exe 'nno '.n.' '.n
      endif
      unlet g:dwarf_old_mappings[ n ]
    endfor

    if !exists('g:nyao_modes')
      call ResetStatusColour()
    endif

    for n in v_keys_to_map
      if has_key( g:dwarf_old_mappings, n )
            \ && type(g:dwarf_old_mappings[ n ]) == 1
            \ && len(g:dwarf_old_mappings[ n ]) > 0
        exe 'vno '.n.' '. g:dwarf_old_v_mappings[ n ]
      else
        exe 'vno '.n.' '.n
      endif
      unlet g:dwarf_old_v_mappings[ n ]
    endfor
    if !exists('g:nyao_modes')
      call UnbindMode('DwarfMode')
    endif
  endif
endfu

nno <silent> cmd :call DwarfMode()<CR>
nno <silent> dh :call DwarfMode()<CR>
command! Dwarf call DwarfMode()


augroup Dwarf
    autocmd!
    " When NOT in dwarf mode, we want the minimap to update as we move around,
    " in case we forget we already set a file or it's on a much deeper level
    " or whatever
    " also nicely puts us somewhere sensible when we startup
    "
    " One disadvantage is that when dwarf mode is active, occasionally we
    " would like the map to update (sc hotkeys for example) The case for this
    " is mainly we're NOT on an X spot, so we don't intend to add a new
    " mapping AND the label already exists. The case when we don't want the
    " map to update is when we DONT have the mapping and we ARE on an X spot
    "
    " Q: Does it really matter if we're on an X spot? eg if the mapping
    " exists, should we always just move to it? Or is it important that we
    " sometimes have the convenience of not updating the map? The problem
    " we don't want to encounter is looking at another file and being forced
    " back to the one in the map. And when we're still loaded on a file in the
    " map, we DONT want to move back to there when we're trying to mark a new
    " label on an x spot, hence when dwarf mode is on, we're also kind of in
    " label / explore mode, when dwarf mode is off, we want the map to show
    " where we are. So maybe all that's needed is on exiting dwarf mode,
    " please redraw the map
    au BufEnter * if (g:dwarf_mode == 0 && system(s:prg." p " . expand('%:p')) == "1") | call DrawDwarfCodebase() | endif
augroup END

