" myfav.vim - Favorite file and directory explorer
" Author: Chris Yang
" Last Change: 2015 Aug 10
" Version: 1.0
"
"Command Summary:
" The fundamental mode of operation is via commands. Customizable key mappings
" are provided as alternative means of issuing the commands. The default key
" mappings use <Leader>, which is \ by default.
" Command		Key mapping	Action ~
" :FExplore		<Leader>fe	Open favlist in current window
"					or move to existing favlist window
" :FSplit		<Leader>fs	Open favlist in new window
"					or move to existing favlist window
" :FFile		<Leader>ff	Add current file to favlist
" :FDirectory		<Leader>fd	Add directory of current file to favlist

" Unless you have other user-defined commands with similar names, the first
" two letters (both uppercase) are enough to activate the commands.

" Only one favlist window can be open. Duplicates are not stored in the
" favlist.

if exists('loaded_myfav') || version < 600 || &cp
  finish
endif
let loaded_myfav=1

" FavAdd: add entry to favlist if it is not already there {{{
fun! s:FavAdd(action)
  if !exists("s:favlist")
    call s:FavList()
  endif
  " file if action==1 and directory if action==2
  if a:action == 1
    let name=expand("%:p:~")
  elseif a:action == 2
    let name=expand("%:p:~:h")
  endif
  " Move to existing myfav window or open one
  let test=bufwinnr('favlist')
  if test != -1
    exe test.'wincmd w'
  else
    exe 'silent! botright'.s:win_height.'sp '.s:favlist
  endif
  " Duplicate check
  if a:action == 1
    let dhead=search('^" Files',"w")
  elseif a:action == 2
    let dhead=search('^" Directories',"w")
  endif
  if dhead == 0
    echohl WarningMsg | echo "corrupt favlist" | echohl None
    return
  endif
  let temp=search(escape(name,'~\'),"W")
  " Add entry
  if temp == 0
    setlocal modifiable
    exe dhead.'put=name'
    silent! w
    setlocal nomodifiable
  endif
  " Close myfav window unless it was already open
  if test == -1
    silent! close
  endif
  unlet! temp name dhead
endfun
"}}}

" FavRemove: delete entry from favlist {{{
fun! s:FavRemove()
  if getline(".") =~? '^" [DF]'
    return
  endif
  setlocal modifiable
  .d
  silent! w
  setlocal nomodifiable
endfun
"}}}

" FavExplore: go to new or existing myfav window {{{
fun! s:FavExplore(newwin)
  if !exists("s:favlist")
    call s:FavList()
  endif
  let test=bufwinnr('favlist')
  if test != -1
    exe test.'wincmd w'
  else
    if a:newwin == 1
      exe 'silent! botright'.s:win_height.'sp '.s:favlist
    else
      exe "silent! e ".s:favlist
    endif
  endif
  if line("$") == 9
    echohl WarningMsg | echo "favlist is empty" | echohl None
  endif
  9
  "setlocal noswapfile nowrap nobuflisted nomodifiable fdm=manual
  if has('syntax')
    syn match Separator '^".*'
    hi def link Separator Comment
  endif
  " Maps to open a favorite
  com! -buffer -nargs=1 FOpen call s:FavOpen(<args>)
  " Open in previous window
  nnoremap <silent> <buffer> go :FOpen(1)<cr>
  nnoremap <silent> <buffer> <2-LeftMouse> :FOpen(1)<cr>
  " Open in new window
  nnoremap <silent> <buffer> gO :FOpen(2)<cr>
  " Open in myfav window
  nnoremap <silent> <buffer> <cr> :FOpen(0)<cr>
  " Map to delete myfav entry
  com! -buffer FRemove call s:FavRemove()
  nnoremap <silent> <buffer> <Del> :FRemove<cr>
endfun
"}}}

" FavOpen: edit file or explore directory {{{
fun! s:FavOpen(newwin)
  " in myfav window (a:newwin=0)
  " in previous window (a:newwin=1)
  " in new window (a:newwin=2)
  let thisline=getline(".")
  if thisline =~ '^"' || thisline =~ '^\s*$'
    return
  endif
  let dn=search('^" Directories',"w")
  if line(".") > dn
    let cmd=s:favex_explore_cmd
  else
    let cmd="edit"
  endif
  if a:newwin == 1
    wincmd p
  elseif a:newwin == 2
    split
  endif
  exe cmd." ".thisline
endfun
"}}}

" FavList: find favlist file; create it if necessary {{{
fun! s:FavList()
  silent! 1sp
  let upath=&path
  if has('win32')
    let temp=substitute(&rtp,'"','','g')
    let &path=substitute(temp,' ','\\\ ','g')
  else
    let &path=&rtp
  endif
  let v:errmsg=""
  silent! find favlist
  if v:errmsg != ""
    silent! find plugin/myfav.vim
    let s:favlist=substitute(expand('%:p:h'),"plugin$", 'favlist', '')
    exe "silent! e ".s:favlist
    1put='\"! <Enter> : open file(dir) in this window'
    2put='\"! o : open file(dir) in new window'
    3put='\"! O : open file(dir) in previous window'
    4put='\"! d : delete entry'
    5put='\"! q : close myfav window'
    6put='\"! :he myfav for detailed help'
    7put='\" Files (do not delete this line)'
    8put='\" Directories (do not delete this line)'
    echo "Created ".s:favlist
    silent! g/^$/d
    silent! w
  else
    let s:favlist=expand("%:p")
  endif
  let &path=upath
  unlet! upath temp
  silent! close
endfun
"}}}

" FavInit: initialize variables and maps {{{
fun! s:FavInit()
  " set favex_explore_cmd
  if exists('g:favex_explore_cmd')
    let s:favex_explore_cmd=g:favex_explore_cmd
  else
    let s:favex_explore_cmd='Explore'
  endif
  " set favex_win_height
  if exists('g:favex_win_height')
    let s:win_height=g:favex_win_height
  else
    let s:win_height=10
  endif
  " Map to start myfav in current window
  com FExplore call s:FavExplore(0)
  if !exists('g:favex_fe')
    let g:favex_fe='<Leader>fe'
  endif
  exe 'nnoremap <silent> '. g:favex_fe .' :FExplore<cr>'
  " Map to start myfav in new window
  com FSplit call s:FavExplore(1)
  if !exists('g:favex_fs')
    let g:favex_fs='<Leader>fs'
  endif
  exe 'nnoremap <silent> '. g:favex_fs .' :FSplit<cr>'
  " Map to add favorite file
  com FFile call s:FavAdd(1)
  if !exists('g:favex_ff')
    let g:favex_ff='<Leader>ff'
  endif
  exe 'nnoremap <silent> '. g:favex_ff .' :FFile<cr>'
  " Map to add favorite directory
  com FDirectory call s:FavAdd(2)
  if !exists('g:favex_fd')
    let g:favex_fd='<Leader>fd'
  endif
  exe 'nnoremap <silent> '. g:favex_fd .' :FDirectory<cr>'
endfun
"}}}

call s:FavInit()

" vim: fdm=marker:
