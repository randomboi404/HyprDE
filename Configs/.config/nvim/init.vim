" Set line numbers
set number
set relativenumber

" Enable syntax highlighting
syntax on
set termguicolors

" Set tabs and indentation
set tabstop=4
set shiftwidth=4
set expandtab

" Enable mouse support
set mouse=a

" Enable incremental search
set hlsearch
set incsearch

" Set a better scrolling experience
set scrolloff=8

" Use system clipboard
set clipboard=unnamedplus

" Key Mapping: Space as leader key
let mapleader=" "
nnoremap <leader>w :w<CR>  " Save with <Space>w
nnoremap <leader>q :q<CR>  " Quit with <Space>q

" Enable colorscheme
colorscheme darkblue
