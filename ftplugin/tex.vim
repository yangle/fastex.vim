let maplocalleader = '`'
let b:actualleader = '∮'

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

function! s:EnableMathShortcuts()
    setlocal notimeout
    imap <buffer> <expr> <LocalLeader> <SID>InMathBlock() ? b:actualleader : g:maplocalleader

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

    let shortcuts = {
        \ 'a': '\alpha',
        \ 'b': '\beta',
        \ '/': '\frac{}{}<Esc>F}i',
        \ }
    call extend(mapping, shortcuts)

    for key in keys(mapping)
        " <expr>: https://vi.stackexchange.com/a/8817
        let cmd = 'inoremap <buffer> <expr> %s%s ''%s'''
        exe printf(cmd, b:actualleader, key, mapping[key])
    endfor
endfunction

call s:EnableMathShortcuts()
