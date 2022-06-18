set tabstop=4 softtabstop=2
set shiftwidth=4
set expandtab
set smartindent
set nowrap


" Custom executations for each project, if you open 'vim .' project this read .vimrc local dir
set exrc
" Disable fancy cursors
set guicursor=
" Make line numbers relative to current line
set relativenumber
" Set the line number in the relative current line
set number
" No highlighted search after searching
set nohlsearch
" Keeps any buffer you've been editing, you can navigate away from it without saving it
set hidden
" smartcase searches for capital with uppercase
set smartcase
" smartcase works with ignorecase, case-sensitive searching
set ignorecase

set noswapfile
set nobackup
set undodir=~/.vim/undodir

" scroll when you are 8 lines away from bottom
set scrolloff=8

" we set gruvbox instead
" set termguicolors
set noshowmode
set completeopt=menuone,noinsert,noselect

set colorcolumn=120
" for linting (disabled)
" set signcolumn=yes

call plug#begin('~/.vim/plugged')
    Plug 'vim-scripts/vim-plug'
    Plug 'junegunn/seoul256.vim'
    Plug 'junegunn/vim-easy-align'
    Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
    Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
    Plug 'gruvbox-community/gruvbox'
    Plug 'tpope/vim-fugitive'
"Neovim only?
"    Plug 'nvim-lua/telescope.nvim'
    " ...
call plug#end()

colorscheme gruvbox
" none isn't a color? maybe needs NeoVim?
" highlight Normal guibg=none

" Neovim only?
" mode lhs rhs
"nnoremap <leader>ps

" Remaps things into functions, start with a space on the ex: line?
let mapleader = " "

" actions time
" first a function we will call from our auto group auto commands to trim
" whitespace
fun! TrimWhiteSpace()
        let l:save = winsaveview()
        keeppatterns %s/\s\+$//e
        call winrestview(l:save)
endfun

"    auto group of commands
augroup ZOB
    " first we clear the listeners, so we don't duplicate and have tons of
    " fork madness, wat
    autocmd!
    autocmd BufWritePre * :call TrimWhiteSpace()
augroup END

set wcm=<C-Z>
cnoremap ss so $vim/sessions/*.vim<C-Z>
set wildignore=*.o,*~,*.pyc " Ignore compiled files
set cmdheight=2             " Height of the command bar
set incsearch               " Makes search act like search in modern browsers

" coding things
set showmatch               " show matching brackets when text indicator is over them

set nocompatible            " Do not care about old versions yo

set spelllang=en_us
set spell


