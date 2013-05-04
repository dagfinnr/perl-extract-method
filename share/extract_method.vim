function! ExtractMethod() range
    let extract_region = join( getline(a:firstline,a:lastline), "\n" )
    let method_name = input("Name of extracted method? ")
    if method_name == ""
        let method_name = 'extracted'
    endif

    let call_cmd = "editortools extractmethod-call -n " . method_name
    let call_statement = system(call_cmd, extract_region )
    let call_statement_lines = split( call_statement, "\n" )
    execute a:firstline . ',' . a:lastline . 'delete'
    normal k
    call append('.', call_statement_lines)

    let body_cmd = "editortools extractmethod-body -n " . method_name
    let method_body = system(body_cmd, extract_region )
    let method_body_lines = split( method_body, "\n" )

    call search('sub \w.* {')
    normal k
    call append('.', method_body_lines)
endfunction


