" Author: Alejandro "HiPhish" Sanchez
" License:  The MIT License (MIT) {{{
"    Copyright (c) 2019 HiPhish
"
"    Permission is hereby granted, free of charge, to any person obtaining a
"    copy of this software and associated documentation files (the
"    "Software"), to deal in the Software without restriction, including
"    without limitation the rights to use, copy, modify, merge, publish,
"    distribute, sublicense, and/or sell copies of the Software, and to permit
"    persons to whom the Software is furnished to do so, subject to the
"    following conditions:
"
"    The above copyright notice and this permission notice shall be included
"    in all copies or substantial portions of the Software.
"
"    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
"    NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
"    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
"    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
"    USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}

" This function is called when NCM2 initiates completion. Its responsibility
" is to call Vlime's completion function and set up an appropriate callback.
function! ncm2#vlime#on_complete(context)
	let l:connection = vlime#connection#Get(v:true)
	if type(l:connection) == type(v:null)
		return
	endif
	" Both functions are asynchronous, they do not return any value. Instead
	" we supply a callback function as the second argument, the callback takes
	" to arguments: the connection that as used and the actual result.
	if s:use_fuzzy(l:connection)
		call l:connection.FuzzyCompletions(a:context.base, {c,r->ncm2#vlime#complete_fuzzy(a:context, r)})
	else
		call l:connection.SimpleCompletions(a:context.base, {c,r->ncm2#vlime#complete_simple(a:context, r)})
	endif
endfunction


" ---[ Completion functions ]--------------------------------------------------
" These are the callbacks which will be called after Vlime has finished
" getting the completion items. They are responsible for actually submitting
" the completion to NCM2.

function! ncm2#vlime#complete_simple(context, result)
	let l:matches = a:result[0]
	let l:startccol = a:context.startccol
	call ncm2#complete(a:context, l:startccol, l:matches)
endfunction

function! ncm2#vlime#complete_fuzzy(context, result)
	" The result is a pair, the first element is a list of tuples. We only
	" want the first item of each tuple. I don't know what the remainder of
	" the tuple is supposed to be.
	let l:matches = map(copy(a:result[0]), {i,v->v[0]})
	let l:startccol = a:context.startccol
	call ncm2#complete(a:context, l:startccol, l:matches)
endfunction


" ---[ Helper functions ]------------------------------------------------------

" Determine whether to use fuzzy or simple completion. If nothing is specified
" take an educated guess. The code is taken from Vlime itself and uses
" undocumented features, it might break in the future.
function! s:use_fuzzy(connection)
	if exists('b:ncm2_vlime_fuzzy') | return b:ncm2_vlime_fuzzy | endif
	if exists('t:ncm2_vlime_fuzzy') | return t:ncm2_vlime_fuzzy | endif
	if exists('g:ncm2_vlime_fuzzy') | return g:ncm2_vlime_fuzzy | endif
	return has_key(a:connection.cb_data, 'contribs') && index(a:connection.cb_data['contribs'], 'FUZZY') >= 0
endfunction
