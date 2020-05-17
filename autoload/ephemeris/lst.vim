" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=80
" Filename: autoload/lst.vim
" Description: everything concerning lists and checkboxes
" Home: https://github.com/HP4k1h5/ephemeris/


""
" @public 
" Copy TODOs from last set of TODOs going back up to 10 years. Your
" @setting(g:calendar_diary) directory must  be organized in a
" `.../YYYY/MM/DD.md` hierarchy, in order for this function to know which set of
" TODOs are _most recent_. TODOs are defined by the string set in
" @setting(g:ephemeris_todos). Default is 'TODOs'. **Everything** below that
" marker is copied to the current day's diary entry. It will open today's diary
" entry in a split. This function can be called from anywhere.
function! ephemeris#lst#copy_todos()
  " create today's path and .md entry file if necessary
  let l:today = expand(g:calendar_diary).'/'.strftime('%Y/%m/%d') 
  if !filereadable(l:today.'.md')
    echom "creating today's diary entry" 
    call mkdir(expand(g:calendar_diary).'/'.strftime('%Y/%m'), 'p')
    execute 'badd '.l:today.'.md'
  endif

  " get/set ephemeris_todos
  call ephemeris#lst#get_set_g_todos()

  " look back through a year's worth of potential diary entries
  let l:dp = 1
  while l:dp < 365 * 10
    let l:prev = substitute(system('date -v -'.l:dp."d '+%Y/%m/%d'"), '\n', '', 'g')
    let l:fn = expand(g:calendar_diary).'/'.l:prev.'.md'
    if filereadable(l:fn)
      " if file contains a todo, extract list and dump in today's entry
      " TODO: currently TODO lists need to end the file, a smarter function
      "     : will only grab `-` etc lines up to a natural end, 
      "     : e.g. 3 consecutive newlines
      let l:todostart = system('grep -n "'.g:ephemeris_todos.'" '.l:fn)
      if len(l:todostart)
        let l:todostart = split(l:todostart, ':')[0]
        " add buff, dump todo list, open latest entry, exit loop
        execute 'badd '.l:fn
        execute 'silent! '.bufnr(l:fn).' bufdo! '.l:todostart.',$ w! >> '.l:today.'.md'
        execute 'silent! b '.l:today.'.md'
        break
      endif
    endif
    let l:dp+=1
  endwhile
endfunction

""
" @public 
" Filter out completed tasks and their associated blocks in the current buffer. i.e., if you have a set of tasks like,
" >
"   - [ ] ephemeris docs
"     -[x] `.md`
"       - more list items but not tasks
"         and a nested block of text
"         with a few lines
"     -[ ] `txt`
"   - [x] export autocommands
" <
" and you run `:EphemerisFilterTasks` in the command-line mode, you will be left with
" >
"   - [ ] ephemeris docs
"     -[ ] `txt`
" <
function! ephemeris#lst#filter_tasks()
  " get/set ephemeris_todos
  call ephemeris#lst#get_set_g_todos()
  let l:i = 1
  let l:skip = 0
  for line in getbufline('%', 1, '$')
    " skip deleted nested items
    if l:skip > 0
      let l:skip -= 1
      continue
    endif

    " delete completed items
    if stridx(line, '- [x]') > -1
      call cursor(l:i, 1)
      execute l:i.'d'
      " delete nested items underneath completed blocks
      " stop on any task item, g:ephemeris_todos, 2 blank lines
      while l:i <= line('$') 
            \ && stridx(getline(l:i), '- [') == -1 
            \ && stridx(getline(l:i), g:ephemeris_todos) == -1
            \ && join(getline(l:i, l:i+1), '') !~ '^$' 
        execute l:i.'d'
        let l:skip += 1
      endwhile
    else
      let l:i += 1
    endif
  endfor
endfunction

" TODO: move to BACKLOG somewhere
" multiline pcre for similar `\- \[.].|[\s]+(?=(\- \[.]|\Z))` 

""
" @public
" Toggle state of task on the line under the cursor between
" >
"   - [ ] incomplete, and
"   - [x] complete
" <
function! ephemeris#lst#toggle_task()
  let l:n = line('.')
  let l:l = getline('.')
  let l:c = '- [x]'
  let l:u = '- [ ]'
  if stridx(l:l, l:u) > -1
    call setline(l:n, substitute(l:l, escape(l:u, '['), l:c, ''))
  elseif stridx(l:l, l:c) > -1 
    call setline(l:n, substitute(l:l, escape(l:c, '['), l:u, ''))
  endif
endfunction
