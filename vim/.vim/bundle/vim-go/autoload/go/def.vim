let s:go_stack = []
let s:go_stack_level = 0

function! go#def#Jump(mode) abort
  let old_gopath = $GOPATH
  let $GOPATH = go#path#Detect()

  let fname = fnamemodify(expand("%"), ':p:gs?\\?/?')

  " so guru right now is slow for some people. previously we were using
  " godef which also has it's own quirks. But this issue come up so many
  " times I've decided to support both. By default we still use guru as it
  " covers all edge cases, but now anyone can switch to godef if they wish
  let bin_name = get(g:, 'go_def_mode', 'guru')
  if bin_name == 'godef'
    if &modified
      " Write current unsaved buffer to a temp file and use the modified content
      let l:tmpname = tempname()
      call writefile(getline(1, '$'), l:tmpname)
      let fname = l:tmpname
    endif

    let bin_path = go#path#CheckBinPath("godef")
    if empty(bin_path)
      let $GOPATH = old_gopath
      return
    endif
    let command = printf("%s -f=%s -o=%s -t", bin_path, fname, go#util#OffsetCursor())
    let out = go#util#System(command)
    if exists("l:tmpname")
      call delete(l:tmpname)
    endif
  elseif bin_name == 'guru'
    let bin_path = go#path#CheckBinPath("guru")
    if empty(bin_path)
      let $GOPATH = old_gopath
      return
    endif

    let cmd = [bin_path]
    let stdin_content = ""

    if &modified
      let sep = go#util#LineEnding()
      let content  = join(getline(1, '$'), sep)
      let stdin_content = fname . "\n" . strlen(content) . "\n" . content
      call add(cmd, "-modified")
    endif

    if exists('g:go_guru_tags')
      let tags = get(g:, 'go_guru_tags')
      call extend(cmd, ["-tags", tags])
    endif

    let fname = fname.':#'.go#util#OffsetCursor()
    call extend(cmd, ["definition", fname])

    if has('job')
      let l:spawn_args = {
            \ 'cmd': cmd,
            \ 'custom_cb': function('s:jump_to_declaration_cb', [a:mode, bin_name]),
            \ }

      if &modified
        let l:spawn_args.input = stdin_content
      endif

      call go#util#EchoProgress("searching declaration ...")

      call s:def_job(spawn_args)
      return
    endif

    let command = join(cmd, " ")
    if &modified
      let out = go#util#System(command, stdin_content)
    else
      let out = go#util#System(command)
    endif
  else
    call go#util#EchoError('go_def_mode value: '. bin_name .' is not valid. Valid values are: [godef, guru]')
    return
  endif

  if go#util#ShellError() != 0
    call go#util#EchoError(out)
    return
  endif

  call s:jump_to_declaration(out, a:mode, bin_name)
  let $GOPATH = old_gopath
endfunction

function! s:jump_to_declaration_cb(mode, bin_name, job, exit_status, data) abort
  if a:exit_status != 0
    return
  endif

  call s:jump_to_declaration(a:data[0], a:mode, a:bin_name)
endfunction

function! s:jump_to_declaration(out, mode, bin_name) abort
  let final_out = a:out
  if a:bin_name == "godef"
    " append the type information to the same line so our we can parse it.
    " This makes it compatible with guru output.
    let final_out = join(split(a:out, '\n'), ':')
  endif

  " strip line ending
  let out = split(final_out, go#util#LineEnding())[0]
  if go#util#IsWin()
    let parts = split(out, '\(^[a-zA-Z]\)\@<!:')
  else
    let parts = split(out, ':')
  endif

  let filename = parts[0]
  let line = parts[1]
  let col = parts[2]
  let ident = parts[3]

  " Remove anything newer than the current position, just like basic
  " vim tag support
  if s:go_stack_level == 0
    let s:go_stack = []
  else
    let s:go_stack = s:go_stack[0:s:go_stack_level-1]
  endif

  " increment the stack counter
  let s:go_stack_level += 1

  " push it on to the jumpstack
  let stack_entry = {'line': line("."), 'col': col("."), 'file': expand('%:p'), 'ident': ident}
  call add(s:go_stack, stack_entry)

  " needed for restoring back user setting this is because there are two
  " modes of switchbuf which we need based on the split mode
  let old_switchbuf = &switchbuf

  normal! m'
  if filename != fnamemodify(expand("%"), ':p:gs?\\?/?')
    " jump to existing buffer if, 1. we have enabled it, 2. the buffer is loaded
    " and 3. there is buffer window number we switch to
    if get(g:, 'go_def_reuse_buffer', 0) && bufloaded(filename) != 0 && bufwinnr(filename) != -1
      " jumpt to existing buffer if it exists
      execute bufwinnr(filename) . 'wincmd w'
    elseif a:mode == "tab"
      let &switchbuf = "usetab"
      if bufloaded(filename) == 0
        tab split
      endif
    elseif a:mode == "split"
      split
    elseif a:mode == "vsplit"
      vsplit
    endif

    " open the file and jump to line and column
    exec 'edit' filename
  endif
  call cursor(line, col)

  " also align the line to middle of the view
  normal! zz

  let &switchbuf = old_switchbuf
endfunction

function! go#def#SelectStackEntry() abort
  let target_window = go#ui#GetReturnWindow()
  if empty(target_window)
    let target_window = winnr()
  endif

  let highlighted_stack_entry = matchstr(getline("."), '^..\zs\(\d\+\)')
  if !empty(highlighted_stack_entry)
    execute target_window . "wincmd w"
    call go#def#Stack(str2nr(highlighted_stack_entry))
  endif

  call go#ui#CloseWindow()
endfunction

function! go#def#StackUI() abort
  if len(s:go_stack) == 0
    call go#util#EchoError("godef stack empty")
    return
  endif

  let stackOut = ['" <Up>,<Down>:navigate <Enter>:jump <Esc>,q:exit']

  let i = 0
  while i < len(s:go_stack)
    let entry = s:go_stack[i]
    let prefix = ""

    if i == s:go_stack_level
      let prefix = ">"
    else
      let prefix = " "
    endif

    call add(stackOut, printf("%s %d %s|%d col %d|%s", 
          \ prefix, i+1, entry["file"], entry["line"], entry["col"], entry["ident"]))
    let i += 1
  endwhile

  if s:go_stack_level == i
    call add(stackOut, "> ")
  endif

  call go#ui#OpenWindow("GoDef Stack", stackOut, "godefstack")

  noremap <buffer> <silent> <CR>  :<C-U>call go#def#SelectStackEntry()<CR>
  noremap <buffer> <silent> <Esc> :<C-U>call go#ui#CloseWindow()<CR>
  noremap <buffer> <silent> q     :<C-U>call go#ui#CloseWindow()<CR>
endfunction

function! go#def#StackClear(...) abort
  let s:go_stack = []
  let s:go_stack_level = 0
endfunction

function! go#def#StackPop(...) abort
  if len(s:go_stack) == 0
    call go#util#EchoError("godef stack empty")
    return
  endif

  if s:go_stack_level == 0
    call go#util#EchoError("at bottom of the godef stack")
    return
  endif

  if !len(a:000)
    let numPop = 1
  else
    let numPop = a:1
  endif

  let newLevel = str2nr(s:go_stack_level) - str2nr(numPop)
  call go#def#Stack(newLevel + 1)
endfunction

function! go#def#Stack(...) abort
  if len(s:go_stack) == 0
    call go#util#EchoError("godef stack empty")
    return
  endif

  if !len(a:000)
    " Display interactive stack
    call go#def#StackUI()
    return
  else
    let jumpTarget = a:1
  endif

  if jumpTarget !~ '^\d\+$'
    if jumpTarget !~ '^\s*$'
      call go#util#EchoError("location must be a number")
    endif
    return
  endif

  let jumpTarget = str2nr(jumpTarget) - 1

  if jumpTarget >= 0 && jumpTarget < len(s:go_stack)
    let s:go_stack_level = jumpTarget
    let target = s:go_stack[s:go_stack_level]

    " jump
    exec 'edit' target["file"]
    call cursor(target["line"], target["col"])
    normal! zz
  else
    call go#util#EchoError("invalid location. Try :GoDefStack to see the list of valid entries")
  endif
endfunction

function s:def_job(args) abort
  function! s:error_info_cb(job, exit_status, data) closure
    " do not print anything during async definition search&jump
  endfunction

  let a:args.error_info_cb = function('s:error_info_cb')
  let callbacks = go#job#Spawn(a:args)

  let start_options = {
        \ 'callback': callbacks.callback,
        \ 'close_cb': callbacks.close_cb,
        \ }

  if &modified
    let l:tmpname = tempname()
    call writefile(split(a:args.input, "\n"), l:tmpname, "b")
    let l:start_options.in_io = "file"
    let l:start_options.in_name = l:tmpname
  endif

  call job_start(a:args.cmd, start_options)
endfunction

" vim: sw=2 ts=2 et
