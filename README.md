vim-github-link
---

Copy github/gitlab link for current line(s) to clipboard.

Links have the format:

- GitHub - `https://GITHUB_REMOTE_DOMAIN/OWNER/REPO/blob/$REF/PATH/TO/FILE#L1-L10`.
- GitLab - `https://GITLAB_REMOTE_DOMAIN/OWNER/REPO/blob/$REF/PATH/TO/FILE#L1-10`.

The plugin defines the following functions which returns different `$REF` references:

- `GetCommitLink`: commit which most recently modified the current file (permalink)
- `GetCurrentBranchLink`: active branch name
- `GetCurrentCommitLink`: most recent commit - URL will 404 if you haven't pushed it to the remote

# Usage
In normal mode

```
:1,3GetCurrentBranchLink
```
then link is copied to your clipboard.

In visual mode, same command after selected.

# Install
## dein.vim
add below line into .vimrc

```
call dein#add('renato-osec/vim-github-link')
```

or add to toml file

```
[[plugins]]
repo = 'renato-osec/vim-github-link'
```

## vim-plug

```
Plug 'renato-osec/vim-github-link'
```
