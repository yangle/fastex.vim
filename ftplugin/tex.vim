let maplocalleader = '`'
let b:actualleader = '∮'

let s:leader_shortcuts = {
    \ 'a': '\alpha',
    \ 'b': '\beta',
    \ '/': '\frac{}{}<Esc>F}i',
    \ }

let s:insert_shortcuts = {
    \ 'b': '<Left>\mathbf{<Right>}',
    \ }

" =========================================================================

function! s:InMathInline()
    let prefix = strpart(getline('.'), 0, col('.') - 1)
    return count(prefix, '$') % 2
endfunction

function! s:InMathBlock()
    let prior = strpart(getline('.'), 0, col('.') - 1)
    let blocks = '{\(equation\|eqnarray\|multline\|gather\|align\|flalign\|alignat\)\*\=}'
    let boundaries = '\\begin'.blocks.'\|\\end'.blocks.'\|\\\]\|\\\['

    " Note: $$...$$ is not supported!

    " find the nearest prior of boundaries
    if prior !~# boundaries
        let lnum = line('.') - 1
        while lnum >= 0 && getline(lnum) !~# boundaries
            let lnum -= 1
        endwhile

        if lnum < 0
            return 0
        else
            let prior = getline(lnum)
        endif
    endif

    if prior =~# '\\\[\(.*\\\]\)\@!'
        return 1
    endif
    return prior =~# '\\begin\('.blocks.'\)\(.\{-}\\end\1\)\@!'
endfunction

function! s:InMath()
    return s:InMathInline() || s:InMathBlock()
endfunction

" smart tabbing inside TeX expressions
" adapted from https://github.com/vim-scripts/auctex.vim
function! s:Tabbing()
    let in_math_inline = s:InMathInline()
    let in_math_block = s:InMathBlock()

    if in_math_inline || in_math_block
        let suffix = strpart(getline('.'), col('.') - 1)

        if suffix[0] =~ ')\|]\||'
            return "\<Right>"
        elseif suffix =~ '^\\}\|\\|'
            return "\<Right>\<Right>"
        elseif suffix =~# '^\\right\\'
            return "\<Esc>8la"
        elseif suffix =~# '^\\right'
            return "\<Esc>7la"
        elseif suffix =~ '^}\(\^\|_\|\){'
            return "\<Esc>f{a"
        elseif suffix[0] == '}'
            return "\<Right>"
        else
            if in_math_inline
                return "\<Esc>f$a"
            else
                return "\<Tab>"
            endif
        endif
    endif

    return "\<Tab>"
endfunction

" convert triple dots into \ldots or \cdots
function! s:Dots()
    if s:InMath()
        let line = getline('.')
        let column = col('.') - 1
        if column >= 2 && line[column - 1] == '.' && line[column - 2] == '.'
            if column >= 3 && line[column - 3] == ','
                return "\<BS>\<BS>\\ldots"
            else
                return "\<BS>\<BS>\\cdots"
            endif
        endif
    endif

    return '.'
endfunction

" convert __ to _{} and ^^ to ^{}
function! s:BracedScript(key)
    if s:InMath()
        let column = col('.') - 1
        if column >= 1 && getline('.')[column - 1] == a:key
            return "{}\<Left>"
        endif
    endif

    return a:key
endfunction

" insert () [] {} \{\} in pairs
function! s:Pair(l, r)
    if s:InMath()
        let line = getline('.')
        let column = col('.') - 1

        if column >= 1 && strpart(line, column - 1, 2) == a:l . a:r
            return "\<Del>"
        elseif a:l == '{' && column >= 2 && strpart(line, column - 2, 4) == '\{\}'
            return "\<Del>\<Del>"
        elseif a:l == '{' && column >= 1 && line[column - 1] == '\'
            return '{\}'."\<Left>\<Left>"
        else
            return a:l.a:r."\<Left>"
        endif
    endif

    return a:l
endfunction

" enable shortcuts prefixed by <Insert>
function! s:EnableInsertShortcuts()
    imap <buffer><expr> <Insert> <SID>InMath() ? '<Plug>I' : '<Insert>'

    let mapping = s:insert_shortcuts
    for key in keys(mapping)
        let cmd = 'inoremap <buffer> <Plug>I%s %s'
        exe printf(cmd, key, mapping[key])
    endfor

endfunction

" enable shortcuts prefixed by <LocalLeader>
function! s:EnableLeaderShortcuts()
    setlocal notimeout
    imap <buffer><expr> <LocalLeader> <SID>InMath() ? b:actualleader : g:maplocalleader

    let mapping = {
        \ '<Space>': g:maplocalleader."<Space>",
        \ '\|': g:maplocalleader.'\|',
        \ }

    " skip 0x7C, i.e. '|', which requires extra escaping
    " (Note that range(b, e) gives [b .. e] in vim...)
    let visible = range(0x21, 0x7B) + range(0x7D, 0x7E)
    for nr in visible
        let char = nr2char(nr)
        let mapping[char] = g:maplocalleader.char
    endfor

    call extend(mapping, s:leader_shortcuts)

    for key in keys(mapping)
        " <expr>: https://vi.stackexchange.com/a/8817
        let cmd = 'inoremap <buffer><expr> %s%s ''%s'''
        exe printf(cmd, b:actualleader, key, mapping[key])
    endfor
endfunction

" =========================================================================

" common math environments
inoremap <buffer><silent> <F1>
    \ \begin{equation}<CR>\end{equation}<Esc>k0
inoremap <buffer><silent> <F2>
    \ \begin{equation}<CR>\begin{aligned}<CR>\end{aligned}<CR>\end{equation}<Esc>2k0
inoremap <buffer><silent> <F3>
    \ \begin{align}<CR>\end{align}<Esc>k0

inoremap <buffer><silent> <Tab> <C-R>=<SID>Tabbing()<CR>

inoremap <buffer><silent> . <C-R>=<SID>Dots()<CR>
inoremap <buffer><silent> _ <C-R>=<SID>BracedScript('_')<CR>
inoremap <buffer><silent> ^ <C-R>=<SID>BracedScript('^')<CR>
inoremap <buffer><silent> ( <C-R>=<SID>Pair('(',')')<CR>
inoremap <buffer><silent> [ <C-R>=<SID>Pair('[',']')<CR>
inoremap <buffer><silent> { <C-R>=<SID>Pair('{','}')<CR>

"inoremap <buffer> <Insert>b <Left>\mathbf{<Right>}
"inoremap <buffer> <Insert>B <Left>\mathbb{<Right>}
"inoremap <buffer> <Insert>r <Left>\mathrm{<Right>}
"inoremap <buffer> <Insert>s <Left>\mathsf{<Right>}
"inoremap <buffer> <Insert>f <Left>\mathfrak{<Right>}
"inoremap <buffer> <Insert>c <Left>\mathcal{<Right>}

call s:EnableLeaderShortcuts()
call s:EnableInsertShortcuts()
