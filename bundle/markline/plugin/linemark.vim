" Author: Chris Yang @ Dec 12th, 2014

if exists("g:loaded_linemark") 
   finish
endif
let g:loaded_linemark = 1

nnoremap  <silent> mm :call <SID>HighlightLine() \| nohls<CR>
nnoremap  <silent> mc :call <SID>HighlightClear()<CR>
nnoremap  <silent> 'n :call <SID>HighlightGoto('f')<CR>
nnoremap  <silent> 'p :call <SID>HighlightGoto('b')<CR>
nnoremap  <silent> m<space> :call <SID>HighlightShow("all")<CR>

let s:bg = ["Blue", "Green","Cyan", "Red",  "Yellow","Magenta","White"]
let s:fg = ["White","White","White","White","White", "White",  "Black"]
let s:buf = {}
let s:grp = "HILI"
let s:max = 7

func! <SID>HighlightLine()
    let bnum = bufnr('%')
    let lnum = line(".")
    let grp = s:grp. '_'. bnum. '_'. lnum

    if !has_key(s:buf, bnum)
        call extend(s:buf, {bnum : []})
    endif

    let idx = index(s:buf[bnum], lnum)
    if idx >= 0
        exec 'syn clear '.grp
        call remove(s:buf[bnum], idx)

        let bg = s:bg[idx % s:max]
        let ch = strpart(bg, 0, 1)
        exec "delmarks ".ch

        return
    endif

    call add(s:buf[bnum], lnum)

    let idx = index(s:buf[bnum], lnum)
    let bg  = s:bg[idx % s:max]
    let fg  = s:fg[idx % s:max]
    let pat = '/\%'. lnum. 'l.*/'

    exec 'hi '.grp.' ctermfg='.fg.' ctermbg='.bg
    exec 'syn match '.grp.' '.pat.' containedin=ALL'

    let ch = strpart(bg, 0, 1)
    exec "normal m".ch
endfunc

func! <SID>HighlightClear()
    let bnum = bufnr('%')
    if !has_key(s:buf, bnum)
        return
    endif

    let lines = s:buf[bnum]
    for idx in range(len(lines))
        let lnum = lines[idx]

        let grp = s:grp. '_'. bnum. '_'. lnum
        exec 'syn clear '. grp

        let bg = s:bg[idx % s:max]
        let ch = strpart(bg, 0, 1)
        exec 'delmarks '.ch
    endfor

    call remove(s:buf, bnum)
endfunc

func! <SID>HighlightShow(mode)
    let l:bnum = bufnr('%')
    if !has_key(s:buf, l:bnum)
        return
    endif

    let l:lines = copy(s:buf[l:bnum])
    if len(l:lines) == 0
        return
    endif

    let l:list_map = map(l:lines, '{"bufnr" : l:bnum, "lnum" : v:val, "text" : getline(v:val)}')
    call setqflist(l:list_map)

    if a:mode == "all"
        for b in keys(s:buf)
            if b == l:bnum
                continue
            endif

            let l:lines = copy(s:buf[b])
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
    if !has_key(s:buf, bnum)
        return
    endif

    let lines = copy(s:buf[bnum])
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
