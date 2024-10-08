" Command definitions for generating permalinks
command! -range=% GetCommitLink <line1>,<line2>call s:get_commit_link("file", <line1>, <line2>)
command! -range=% GetCurrentBranchLink <line1>,<line2>call s:get_commit_link("branch", <line1>, <line2>)
command! -range=% GetCurrentCommitLink <line1>,<line2>call s:get_commit_link("head", <line1>, <line2>)

function! s:get_commit_link(which_ref, line1, line2) range
    " Save the current directory to restore it later
    let s:currentdir = getcwd()
    " Get the repository root directory
    let s:root = system('git rev-parse --show-toplevel')
    " Remove any trailing control characters and whitespace
    let s:root = substitute(s:root, '[\x00-\x1F\x7F[:space:]]*$', '', '')
    if s:root == ''
        echoerr "Unable to determine repository root"
        return
    endif
    " Change directory to the repository root
    execute 'lcd' fnameescape(s:root)
    " Determine the git reference based on the command
    if a:which_ref == "branch"
        let s:ref = system("git rev-parse --abbrev-ref HEAD")
    elseif a:which_ref == "head"
        let s:ref = system("git rev-parse HEAD")
    elseif a:which_ref == "file"
        let s:ref = system("git rev-list -1 HEAD -- " . shellescape(expand('%:p')))
    else
        echoerr "Unknown ref type '" . a:which_ref . "'"
        execute 'lcd' . fnameescape(s:currentdir)
        return
    endif
    " Remove any trailing control characters and whitespace from the ref
    let s:ref = substitute(s:ref, '[\x00-\x1F\x7F[:space:]]*$', '', '')
    " Call the function to generate the link with the specified ref and line range
    call s:execute_with_ref(s:ref, a:line1, a:line2, s:root)
    " Restore the original directory
    execute 'lcd' . fnameescape(s:currentdir)
endfunction

function! s:execute_with_ref(ref, startline, endline, root)
    " Get the remote URL
    let s:remote_name = 'origin'
    let s:remote = system('git ls-remote --get-url ' . s:remote_name)
    " Remove any trailing control characters and whitespace
    let s:remote = substitute(s:remote, '[\x00-\x1F\x7F[:space:]]*$', '', '')
    if v:shell_error != 0 || s:remote ==# ''
        echoerr "Unable to get remote URL"
        return
    endif

    let s:repo = ''
    if s:remote =~? '^git@'
        let s:repo = s:get_repo_url_from_git_protocol(s:remote)
    elseif s:remote =~? '^ssh://'
        let s:repo = s:get_repo_url_from_ssh_protocol(s:remote)
    elseif s:remote =~? '^https://'
        let s:repo = s:get_repo_url_from_https_protocol(s:remote)
    else
        echoerr "Remote doesn't match any known protocol"
        return
    endif

    if s:repo == ''
        echoerr "Failed to parse repository URL"
        return
    endif

    " Get the absolute path of the current file
    let s:file_absolute_path = expand('%:p')
    " Compute the path of the file relative to the repository root
    let s:path_from_root = fnamemodify(s:file_absolute_path, ':' . a:root)
    if s:path_from_root ==# s:file_absolute_path
        " If fnamemodify didn't work, manually remove the root path
        let s:path_from_root = substitute(s:file_absolute_path, '^' . a:root . '/\?', '', '')
    endif

    " URL-encode the path segments
    let s:path_from_root = s:url_encode_path_segments(s:path_from_root)
    " Build the base link to the file at the specified ref
    let s:link = s:repo . "/blob/" . s:ref . "/" . s:path_from_root

    " Check for documentation file extensions and add the 'plain' query parameter for GitHub
    if s:link =~? '\v.*\.(md|rst|markdown|mdown|mkdn|textile|rdoc|org|creole|mediawiki|wiki|rst|asciidoc|adoc|asc|pod)$'
        let s:link = s:link . "?plain=1"
    endif

    " Append the line numbers to the link
    if a:startline == a:endline
        let s:link = s:link . "#L" . a:startline
    else
        let s:link = s:link . "#L" . a:startline . "-L" . a:endline
    endif

    " Remove any control characters and whitespace from the link
    let s:link = substitute(s:link, '[\x00-\x1F\x7F[:space:]]', '', 'g')
    " Copy the link to the clipboard
    let @+ = s:link
    echo 'Copied link: ' . s:link
endfunction

" Remaining functions remain unchanged

function! s:get_repo_url_from_git_protocol(uri)
    let s:matches = matchlist(a:uri, '^git@\(.*\):\(.*\)$')
    if len(s:matches) < 3
        return ''
    endif
    " Always assume the hostname is github.com
    let s:resolved_host = 'github.com'
    return "https://" . s:resolved_host . '/' . s:trim_git_suffix(s:matches[2])
endfunction

function! s:get_repo_url_from_ssh_protocol(uri)
    let s:matches = matchlist(a:uri, '^ssh:\/\/git@\([^\/]*\)\/\(.*\)$')
    if len(s:matches) < 3
        return ''
    endif
    " Always assume the hostname is github.com
    let s:resolved_host = 'github.com'
    return "https://" . s:resolved_host . '/' . s:trim_git_suffix(s:matches[2])
endfunction

function! s:get_repo_url_from_https_protocol(uri)
    let s:matches = matchlist(a:uri, '^https:\/\/\(.*@\)\?\(.*\)$')
    if len(s:matches) < 3
        return ''
    endif
    return "https://" . s:trim_git_suffix(s:matches[2])
endfunction

function! s:trim_git_suffix(str)
    " Strip control characters and whitespace
    let s:nospace = substitute(a:str, '[\x00-\x1F\x7F[:space:]]', '', 'g')
    return substitute(s:nospace, '\.git$', '', '')
endfunction

" URL-encode a string
function! s:url_encode(str) abort
    return substitute(a:str, '[^A-Za-z0-9_.~-]', '\=printf("%%%02X", char2nr(submatch(0)))', 'g')
endfunction

" URL-encode each segment of a file path
function! s:url_encode_path_segments(path) abort
    let s:segments = split(a:path, '/')
    let s:encoded_segments = map(s:segments, 's:url_encode(v:val)')
    return join(s:encoded_segments, '/')
endfunction
