# 🥑 guac
## git under a comma
### basically an alias manager and a bunch of mnemonics for git
#### guac works by calling a function with the same name as the symlink used to invoke it.

### goals:
    - save keystrokes
    - provide a porcelain-like tool that lives in the shell,
        rather than in the editor
    - be fun to work with and on

### non-goals:
    - replace your favorite git tool
    - do everything git can


### Installation
clone this repo and run
`./guac -i $TARGET_DIRECTORY_ON_YOUR_PATH` (i like ~/bin/guac)


### Uninstallation
use guac's option to cleanup the symlinks you installed to a clean directory (NOT /usr/bin):

`, -u`
 [leaves behind ~/.config/guac]

 [![asciicast](https://asciinema.org/a/Ye43HFJoUKvPrVpCZrAg3iBxi.svg)](https://asciinema.org/a/Ye43HFJoUKvPrVpCZrAg3iBxi)


     🥑      git under a comma
     |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     , -b    bind alias     e.g: , -b ",ls" "git status"
     , -e    edit alias     e.g: , -e ",ls"  [no arg: edit guac's source]
     , -h    display help
     , -i    install (dump symlinks to specified dir)
     , -l    show aliases
     , -u    uninstall
     ,       git $argv || git status
     ,,,     print LONGHELP
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
     ,, git status
     , git

     ,a                      git add
     ,a.                     ,a .
     ,au                     ,a --update
     ,auc                    ,au && , commit
     ,aucm                   ,auc -m

     ,b                      __branch_or_checkout_existing
     ,bd                     ,b -d

     ,c                      git commit
     ,cm                     ,c -m

     ,clf                    git clean -f

     ,d                      git diff
     ,ds                     ,d --staged

     ,guac                   ,auc
     ,guacm                  ,aucm

     ,l                      git log
     ,la                     ,l --abbrev
     ,ll                     ,l --oneline
     ,log                    ,l

     ,m                      git merge

     ,v                      git mv

     ,o                      git remote -v
     ,oa                     ,o add
     ,oao                    ,oa origin
     ,or                     ,o remove

     ,                       , pull
     ,push                   , push

     ,r                      , reset

     ,s                      , stash
     ,pop                    , stash pop
     ,put                    , stash push
