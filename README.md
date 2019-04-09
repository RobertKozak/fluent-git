# fluent-git.zsh-theme

Custom prompt for zsh and bash

# Prompt that displays one or more of the following:
# Time taken to execute command - after 30 secs
# Error code
# hostname
# username
# local git status
# remote git status
# kubernetes cluster and namespace
# path
# ssh client connection


## BASH
add to the end of .bashrc

    source $HOME/propmt.sh

## ZSH
add fluent-git.theme to $ZSH/themes

![Prompt with timer](full.png?raw=true)

![Example with error](error.png?raw=true)
