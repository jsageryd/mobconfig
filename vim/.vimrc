"Vim is the future
set nocompatible

"Pathogen
execute pathogen#infect()
filetype plugin indent on

"Set leader to ,
let mapleader = ","

"Avoid modelines CVE-2007-2438
set modelines=0

"Use auto-indent
set ai

"Show line numbers
set nu

"Briefly show matching bracket
set showmatch

"Show file name in window header
set title

"Enable ruler (bottom right corner)
set ruler

"Enable syntax colouring
sy on

"Prevent line wrapping
set nowrap

"Prevent lines breaking in the middle of words
set lbr

"Size of a tab
set tabstop=2

"Size of the space inserted or removed with >> or <<
set shiftwidth=2

"Default file encodings
" - Allow BOM to be recognised in an UTF-8 file
" - Use plain UTF-8 if there is no BOM
" - Allow non-latin1 to be recognised before latin1
" - Try latin1 if the file is not any of the above
set fileencodings=ucs-bom,utf-8,default,latin1

"Search highlighting
set hlsearch

"Try to prevent syntax colouring from breaking
syntax sync fromstart

"Set spell checker language
set spelllang=en_gb

"No join space. Prevents double space after period when joining lines.
set nojs

"Set listchars
set listchars=tab:\ \ ,nbsp:␣,extends:»,precedes:«
set list

"Set command history
set history=500

"Highlight leading tabs
highlight TabCharacter ctermfg=233 ctermbg=0
call matchadd('TabCharacter', '^\t\+')

"Avoid q: typo that pops up the annoying command history box
map q: :q

"Automatically remove upon save: trailing whitespace, blank lines at beginning of file, blank lines at end of file
autocmd BufWritePre * :%s/\s\+$//e | :%s/\n\+\%$//e | :0s/^\n\+//e

"Fix backspace
set backspace=indent,eol,start

"Set text width for Subversion commit messages
autocmd FileType svn setlocal tw=72

"Set text width for Git commit messages
autocmd FileType gitcommit setlocal tw=72

"Get rid of 'Thanks for flying Vim'
let &titleold=''

"Toggle folds with space
nnoremap <silent> <Space> @=(foldlevel('.')?'za':"\<Space>")<CR>
vnoremap <Space> zf

"Indicate the 50th, 72nd, and 80th column
set colorcolumn=50,72,80
highlight ColorColumn ctermbg=233

"Enable mouse
set ttymouse=xterm2
set mouse=a

"Always show status line
set laststatus=2

"Use goimports instead of gofmt
let g:go_fmt_command = "goimports"

"Toggle GoCoverage with <Leader>c
nnoremap <Leader>c :GoCoverageToggle<CR>

"Enable fzf
set rtp+=/usr/local/opt/fzf

"Use C-p for fzf
nnoremap <C-p> :FZF<CR>

"Use <Leader>b for git blame
nnoremap <Leader>b :Gblame<CR>

"Avoid vim swap files and backups
set noswapfile
set nobackup
set nowritebackup

"Toggle NERD tree with <Leader>n
nnoremap <silent> <Leader>n :NERDTreeToggle<CR>
let NERDTreeShowHidden=1

"Use <tab> to cycle over windows
noremap <tab> <c-w>w
noremap <S-tab> <c-w>W

"Toggle last two buffers with <Leader><Leader>
nnoremap <Leader><Leader> <C-^>

"Reload unmodified buffer without asking, if underlying file changes
"(this does not poll automatically, run :checktime to check all buffers)
set autoread

"Prevent search from wrapping at EOF
set nowrapscan

"Set text width to 80 for markdown
autocmd FileType markdown setlocal tw=80
