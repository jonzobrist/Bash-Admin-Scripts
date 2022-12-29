set nocompatible            " Do not care about old versions yo
set tabstop=4 softtabstop=2
set shiftwidth=4
set expandtab
set smartindent
set nowrap

" neeed this first - curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" enable syntax and plugins (for netrw)
syntax enable
filetype plugin on

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
    Plug 'vim-python/python-syntax'                    " Python highlighting
    Plug 'ap/vim-css-color'                            " Color previews for CSS
    Plug 'powerline/powerline'
    Plug 'vim-airline/vim-airline'                      " https://github.com/vim-airline/vim-airline
    Plug 'vim-airline/vim-airline-themes'
    Plug 'bling/vim-bufferline'                         " https://github.com/bling/vim-bufferline
    Plug 'vifm/vifm.vim'                               " Vifm

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


" https://github.com/vim-airline/vim-airline
" AirlineTheme solarized
" let g:airline_solarized_bg='dark'
" let g:airline_theme='solarized'
let g:airline_theme='badwolf'
" let g:airline_theme='solarized'
" let g:airline_solarized_bg='dark'

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


set spelllang=en_us
set spell


" From YouTube https://www.youtube.com/watch?v=XA2WjJbmmoM
" https://github.com/changemewtf/no_plugins
" FINDING FILES:
" Search down into subfolders
" Provides tab-completion for all file-related tasks
set path+=**
" Display all matching files when we tab complete
set wildmenu
" NOW WE CAN:
" - Hit tab to :find by partial match
" - Use * to make it fuzzy
" THINGS TO CONSIDER:
" - :b lets you autocomplete any open buffer
" TAG JUMPING:
" Create the `tags` file (may need to install ctags first)
command! MakeTags !ctags -R .
" NOW WE CAN:
" - Use ^] to jump to tag under cursor
" - Use g^] for ambiguous tags
" - Use ^t to jump back up the tag stack
" THINGS TO CONSIDER:
" - This doesn't help if you want a visual list of tags
" AUTOCOMPLETE:
" The good stuff is documented in |ins-completion|
" HIGHLIGHTS:
" - ^x^n for JUST this file
" - ^x^f for filenames (works with our path trick!)
" - ^x^] for tags only
" - ^n for anything specified by the 'complete' option
" NOW WE CAN:
" - Use ^n and ^p to go back and forth in the suggestion list


" FILE BROWSING:
" Tweaks for browsing
let g:netrw_banner=0        " disable annoying banner
let g:netrw_browse_split=4  " open in prior window
let g:netrw_altv=1          " open splits to the right
let g:netrw_liststyle=3     " tree view
let g:netrw_list_hide=netrw_gitignore#Hide()
let g:netrw_list_hide.=',\(^\|\s\s\)\zs\.\S\+'
" NOW WE CAN:
" - :edit a folder to open a file browser
" - <CR>/v/t to open in an h-split/v-split/tab
" - check |netrw-browse-maps| for more mappings


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Merging in some changes from DistroTube https://www.youtube.com/DistroTube
" per https://www.youtube.com/watch?v=Zir28KFCSQw
" https://gitlab.com/dwt1/dotfiles/-/blob/master/.vimrc

" => NERDTree
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Uncomment to autostart the NERDTree
" autocmd vimenter * NERDTree
map <C-n> :NERDTreeToggle<CR>
let g:NERDTreeDirArrowExpandable = '►'
let g:NERDTreeDirArrowCollapsible = '▼'
let NERDTreeShowLineNumbers=1
let NERDTreeShowHidden=1
let NERDTreeMinimalUI = 1
let g:NERDTreeWinSize=38

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Vifm - file manager, kinda meh, should disable
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <Leader>vv :Vifm<CR>
map <Leader>vs :VsplitVifm<CR>
map <Leader>sp :SplitVifm<CR>
map <Leader>dv :DiffVifm<CR>
map <Leader>tv :TabVifm<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Splits and Tabbed Files
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set splitbelow splitright

" Remap splits navigation to just CTRL + hjkl
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Make adjusing split sizes a bit more friendly
noremap <silent> <C-Left> :vertical resize +3<CR>
noremap <silent> <C-Right> :vertical resize -3<CR>
noremap <silent> <C-Up> :resize +3<CR>
noremap <silent> <C-Down> :resize -3<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Open terminal inside Vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" map <Leader>tt :vnew term://zsh<CR>
" map <Leader>tt :vnew term://zsh<CR>
" let &shell='/bin/zsh -i'
autocmd vimenter * let &shell='/bin/zsh -i'

" Change 2 split windows from vert to horiz or horiz to vert
map <Leader>th <C-w>t<C-w>H
map <Leader>tk <C-w>t<C-w>K

" Removes pipes | that act as seperators on splits
set fillchars+=vert:\



" set t_Co=256                    " Set if term supports 256 colors.
" Always show statusline
" set laststatus=2
" Uncomment to prevent non-normal modes showing in powerline and below powerline.
" set noshowmode


""" powerline but no worky https://linuxconfig.org/introduction-to-powerline-the-statusline-plugin-for-vim
"python3 from powerline.vim import setup as powerline_setup
"python3 powerline_setup()
"python3 del powerline_setup


