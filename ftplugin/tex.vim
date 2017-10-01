let maplocalleader = '`'

function! s:InMathInline()
    let prefix = strpart(getline('.'), 0, col('.') - 1)
    return count(prefix, '$') % 2
endfunction

function! s:InMathBlock()
    let prior = strpart(getline('.'), 0, col('.') - 1)
    let blocks = '{\(equation\|eqnarray\|multline\|gather\|align\|flalign\|alignat\)\*\=}'
    let boundaries = '\\begin'.blocks.'\|\\end'.blocks.'\|\\\]\|\\\['

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

function! s:InsertShortcut(text, math)
    if s:InMathInline() || s:InMathBlock()
        return a:math
    else
        return g:maplocalleader . a:text
    endif
endfunction

function! s:EnableMathShortcuts()
    setlocal notimeout
    let maps = [
        \ [g:maplocalleader, g:maplocalleader],
        \ ['a', '\alpha'],
        \ ['b', '\beta'],
        \ ['/', '\frac{}{}<Esc>F}i'],
        \ ]

    for entry in maps
        " <expr>: https://vi.stackexchange.com/a/8817
        let cmd = 'inoremap <buffer> <expr> <LocalLeader>%s <SID>InsertShortcut(''%s'', ''%s'')'
        exe printf(cmd, entry[0], entry[0], entry[1])
    endfor
endfunction

call s:EnableMathShortcuts()
