function! ExtractMethod() range
    let extract_region = join( getline(a:firstline,a:lastline), "\n" )
    let method_name = input("Name of extracted method? ")
    if method_name == ""
        let method_name = 'extracted'
    endif

    let command = "editortools extractmethod -n " . method_name . " -s " . a:firstline . " -e " . a:lastline

    call Exec_command_and_replace_buffer( command )
endfunction

function! ConvertVarToAttribute()
    let newvar = input("Attribute name? ")

    let line = line('.')
    " should backtrack to $ or % or the like
    let col  = col('.')
    let filename = expand('%')

    let command = "editortools convertvartoattribute -c " . col . " -l " . line  . " -n " . newvar 

    call Exec_command_and_replace_buffer( command )
endfunction
