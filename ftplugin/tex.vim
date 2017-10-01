let maplocalleader = '`'
let b:actualleader = '∮'

let s:shortcuts = {
    \ 'a': '\alpha',
    \ 'b': '\beta',
    \ '/': '\frac{}{}<Esc>F}i',
    \ }

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

" adapted from https://github.com/vim-scripts/auctex.vim
function! s:Tabbing()
    let column = col('.') - 1
    let suffix = strpart(getline('.'), col('.') - 1)

    let in_math_inline = s:InMathInline()
    let in_math_block = s:InMathBlock()

    if in_math_inline || in_math_block
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
    else
        if suffix[0] =~ ')\|]\|}'
            return "\<Right>"
        else
            return "\<Tab>"
        endif
    endif
endfunction

function! s:EnableMathShortcuts()
    setlocal notimeout
    imap <buffer> <expr> <LocalLeader> <SID>InMath() ? b:actualleader : g:maplocalleader

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

    call extend(mapping, s:shortcuts)

    for key in keys(mapping)
        " <expr>: https://vi.stackexchange.com/a/8817
        let cmd = 'inoremap <buffer> <expr> %s%s ''%s'''
        exe printf(cmd, b:actualleader, key, mapping[key])
    endfor
endfunction

" =========================================================================

inoremap <buffer><silent> <F1>
    \ \begin{equation}<CR>\end{equation}<Esc>k0
inoremap <buffer><silent> <F2>
    \ \begin{equation}<CR>\begin{aligned}<CR>\end{aligned}<CR>\end{equation}<Esc>2k0
inoremap <buffer><silent> <F3>
    \ \begin{align}<CR>\end{align}<Esc>k0

inoremap <buffer><silent> <Tab> <C-R>=<SID>Tabbing()<CR>

call s:EnableMathShortcuts()
