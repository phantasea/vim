" Author: Chris Yang @ Dec 12th, 2014

if exists("g:loaded_linemark") 
   finish
endif
let g:loaded_linemark = 1

nnoremap  <silent> mm :call <SID>HighlightLine('index') \| nohls<CR>
nnoremap  <silent> mq :call <SID>HighlightClear()<CR>
nnoremap  <silent> 'n :call <SID>HighlightGoto('f')<CR>
nnoremap  <silent> 'p :call <SID>HighlightGoto('b')<CR>
nnoremap  <silent> m<space> :call <SID>HighlightShow("all")<CR>

let s:lcolor_bg_tui = ["Blue", "Green","Cyan", "Red",  "Yellow","Magenta","LightGray"]
let s:lcolor_fg_tui = ["White","White","White","White","White", "White",  "Black"]
let s:markLines = {}
let s:lcolor_grp = "LHiColor"
let s:lcolor_max = min([len(s:lcolor_bg_tui), len(s:lcolor_fg_tui)])

function! <SID>HighlightLine(cmode)
    let bnum = bufnr('%')
    let lnum = line(".")
    let colorgrp = s:lcolor_grp. '_'. bnum. '_'. lnum
    let linePattern = '.*\%'. lnum. 'l.*'

    if !has_key(s:markLines, bnum)
        call extend(s:markLines, {bnum : []})
    endif

    let idx = index(s:markLines[bnum], lnum)
    if idx >= 0
        exec 'syn clear '. colorgrp
        call remove(s:markLines[bnum], idx)
        return
    endif

    call add(s:markLines[bnum], lnum)

    if a:cmode ==? 'index'
        let idx = index(s:markLines[bnum], lnum)
        let bgColor_tui = s:lcolor_bg_tui[idx % s:lcolor_max]
        let fgColor_tui = s:lcolor_fg_tui[idx % s:lcolor_max]
    else
        " hili by line no.
        let bgColor_tui = s:lcolor_bg_tui[lnum % s:lcolor_max]
        let fgColor_tui = s:lcolor_fg_tui[lnum % s:lcolor_max]
    endif

    exec 'hi '. colorgrp. ' ctermfg='. fgColor_tui. ' ctermbg='. bgColor_tui
    exec 'syn match '. colorgrp. ' "'. linePattern. '" containedin=ALL'

    let chr = tolower(strpart(bgColor_tui, 0, 1))
    exec "normal m".chr
endfunction

func! <SID>HighlightClear()
    exec 'delmarks!'

    let bnum = bufnr('%')
    if !has_key(s:markLines, bnum)
        return
    endif

    for lnum in s:markLines[bnum]
        let colorgrp = s:lcolor_grp. '_'. bnum. '_'. lnum
        exec 'syn clear '. colorgrp
    endfor

    call remove(s:markLines, bnum)
endfunc

func! <SID>HighlightShow(mode)
    let l:bnum = bufnr('%')
    if !has_key(s:markLines, l:bnum)
        return
    endif

    let l:lines = copy(s:markLines[l:bnum])
    if len(l:lines) == 0
        return
    endif

    let l:list_map = map(l:lines, '{"bufnr" : l:bnum, "lnum" : v:val, "text" : getline(v:val)}')
    call setqflist(l:list_map)

    if a:mode == "all"
        for b in keys(s:markLines)
            if b == l:bnum
                continue
            endif

            let l:lines = copy(s:markLines[b])
            let l:list_map = map(l:lines, '{"bufnr" : b, "lnum" : v:val, "text" : getline(v:val)}')
            call setqflist(l:list_map, 'a')
        endfor
    endif

    copen
endfunc

func! s:IncSort(val1, val2)
    return a:val1 - a:val2
endfunc

func! <SID>HighlightGoto(mode)
    let bnum = bufnr('%')
    if !has_key(s:markLines, bnum)
        return
    endif

    let lines = copy(s:markLines[bnum])
    let size = len(lines)
    if size == 0
        return
    endif

    call sort(lines, "s:IncSort")
    if a:mode ==? 'b'
        call reverse(lines)
    endif
        
    let lnum = line('.')
    let idx = 0
    while idx < size
        let diff = s:IncSort(lines[idx], lnum)
        if a:mode ==? 'b'
            let diff = 0 - diff
        endif

        if diff > 0
            break
        endif

        let idx += 1
    endwhile
        
    if idx == size
        let next = lines[0]
    else
        let next = lines[idx]
    endif

    "echom "next=".next." idx=".idx." lines=".string(lines)
    call cursor(next, 0, 0)
endfunc
