let s:leader_shortcuts = {
    \ 'a': '\alpha',
    \ 'b': '\beta',
    \ 'B': '\boldsymbol{}<Left>',
    \ 'c': '\chi',
    \ 'd': '\delta',
    \ 'e': '\varepsilon',
    \ 'E': '\epsilon',
    \ 'f': '\phi',
    \ '4': '\varphi',
    \ 'g': '\gamma',
    \ 'h': '\eta',
    \ 'i': '\iota',
    \ 'k': '\kappa',
    \ 'l': '\lambda',
    \ 'm': '\mu',
    \ 'n': '\nu',
    \ 'o': '\omega',
    \ 'p': '\pi',
    \ 'P': '\Pi',
    \ 'q': '\theta',
    \ 'r': '\rho',
    \ 's': '\sigma',
    \ 't': '\tau',
    \ 'u': '\upsilon',
    \ 'v': '\vee',
    \ 'w': '\wedge',
    \ 'x': '\xi',
    \ 'y': '\psi',
    \ 'z': '\zeta',
    \ 'D': '\Delta',
    \ 'I': '\int_{}^{}<Esc>F}i',
    \ 'F': '\Phi',
    \ 'G': '\Gamma',
    \ 'L': '\Lambda',
    \ 'N': '\nabla',
    \ 'O': '\Omega',
    \ 'Q': '\Theta',
    \ 'R': '\varrho',
    \ 'S': '\Sigma',
    \ 'U': '\Upsilon',
    \ 'X': '\Xi',
    \ 'Y': '\Psi',
    \ '0': '\emptyset',
    \ '1': '\left',
    \ '2': '\right',
    \ '3': '\Big',
    \ '6': '\partial',
    \ '8': '\infty',
    \ '/': '\frac{}{}<Esc>F}i',
    \ '@': '\circ',
    \ '=': '\equiv',
    \ '\': '\setminus',
    \ '.': '\cdot',
    \ '*': '\times',
    \ '&': '\wedge',
    \ '_': '\bigcap',
    \ '+': '\dagger',
    \ '(': '\subset',
    \ ')': '\supset',
    \ '<': '\langle',
    \ '>': '\rangle',
    \ ',': '\nonumber',
    \ ':': '\dots',
    \ '~': '\widetilde{}<Left>',
    \ '^': '\hat{}<Left>',
    \ ';': '\dot{}<Left>',
    \ '-': '\overline{}<Left>',
    \ '<Up>': '\uparrow',
    \ '<Down>': '\downarrow',
    \ '<Left>': '\leftarrow',
    \ '<Right>': '\rightarrow',
    \ }

" =========================================================================

" backport count() to seach for a *single* character in a string
function! s:count(str, char)
    " str to list of chars: https://stackoverflow.com/a/17692652
    return count(split(a:str, '\zs'), a:char)
endfunction

" determine whether the cursor is inside $...$
function! s:InMathInline()
    let line = getline('.')
    let prefix = strpart(line, 0, col('.') - 1)
    let ct = s:count(prefix, '$')

    " assumptions:
    " 1. $...$ expands at most two lines
    " 2. double-line $...$ pairs are not line-wise adjacent / overlapping
    if s:count(line, '$') % 2 != 0
        let lnum = line('.')
        if lnum >= 1
            let ct += s:count(getline(lnum - 1), '$')
        endif
    endif
    return ct % 2
endfunction

" determine whether the cursor is inside a \begin{xyz}...\end{xyz} math block
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
    let suffix = strpart(getline('.'), col('.') - 1)

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
function! s:Pair(l, r, ...)
    let math_only = (a:0 >= 1) ? a:1 : 1

    if !math_only || s:InMath()
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

" insert $ in pairs -- not limited to math mode!
function! s:Dollar()
    let line = getline('.')
    let column = col('.') - 1
    if column >= 1 && strpart(line, column - 1, 2) == '$$'
        return "\<Del>\<Left>\\\<Right>"
    else
        return "$$\<Left>"
    endif
endfunction

" enable shortcuts prefixed by <LocalLeader>

function! s:EnableLeaderShortcuts()
    " b:plug is just like <Plug>, but only a single char if inserted verbatim
    " (note: we cannot use a s:* or local variable on the RHS of map-<expr>)
    let b:plug = '∮'
    imap <buffer><expr> <LocalLeader> <SID>InMath() ? b:plug : g:maplocalleader

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
        exe printf(cmd, b:plug, key, mapping[key])
    endfor
endfunction

" =========================================================================

setlocal notimeout

let maplocalleader = '`'

" common math environments
inoremap <buffer><silent> <F1>
    \ \begin{equation}<CR>\end{equation}<Esc>k0
inoremap <buffer><silent> <F2>
    \ \begin{equation}<CR>\begin{aligned}<CR>\end{aligned}<CR>\end{equation}<Esc>2k0
inoremap <buffer><silent> <F3>
    \ \begin{align}<CR>\end{align}<Esc>k0

inoremap <buffer><silent> . <C-R>=<SID>Dots()<CR>
inoremap <buffer><silent> _ <C-R>=<SID>BracedScript('_')<CR>
inoremap <buffer><silent> ^ <C-R>=<SID>BracedScript('^')<CR>
inoremap <buffer><silent> ( <C-R>=<SID>Pair('(', ')')<CR>
inoremap <buffer><silent> [ <C-R>=<SID>Pair('[', ']')<CR>
inoremap <buffer><silent> { <C-R>=<SID>Pair('{', '}')<CR>

call s:EnableLeaderShortcuts()

" the following mappings are not limited to math mode
inoremap <buffer><silent> <Tab> <C-R>=<SID>Tabbing()<CR>
inoremap <buffer><silent> $ <C-R>=<SID>Dollar()<CR>
inoremap <buffer><silent> { <C-R>=<SID>Pair('{', '}', 0)<CR>

inoremap <buffer> <Insert>b <Left>\mathbf{<Right>}
inoremap <buffer> <Insert>B <Left>\mathbb{<Right>}
inoremap <buffer> <Insert>r <Left>\mathrm{<Right>}
inoremap <buffer> <Insert>s <Left>\mathsf{<Right>}
inoremap <buffer> <Insert>f <Left>\mathfrak{<Right>}
inoremap <buffer> <Insert>c <Left>\mathcal{<Right>}
inoremap <buffer> <Insert>s \sqrt{}<Left>
inoremap <buffer> <Insert>t \text{}<Left>

" do not load default plugin or indent files for TeX
" see :help :filetype-overview
if &ft == 'tex'
    filetype plugin indent off
endif
