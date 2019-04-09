# fluent-git.zsh-theme

Custom prompt for zsh and bash

* Prompt that displays one or more of the following:
* Time taken to execute command - after 30 secs
* Error code
* hostname
* username
* local git status
* remote git status
* kubernetes cluster and namespace
* path
* ssh client connection


## BASH
add to the end of .bashrc

    source $HOME/propmt.sh

## ZSH
add fluent-git.theme to $ZSH/themes

# Example of the new prompt diaplaying execution time for last command

![Prompt with timer](full.png?raw=true)

# Example of the new prompt displaying error code

![Example with error](error.png?raw=true)
