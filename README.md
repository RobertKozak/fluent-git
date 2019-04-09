# fluent-git

This is a custom prompt for zsh and bash

This prompt can displays, on a line, one or more of the following:

* Time taken to execute command if takes longer than 30 secs
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

#### Example of the new prompt diaplaying execution time for last command

![Prompt with timer](full.png?raw=true)

#### Example of the new prompt displaying error code

![Example with error](error.png?raw=true)


if you want this prompt to be available on mahines you ssh into you will need to copy the prompt.sh and .bashrc-ssh file to the server.

1. add the following to your local .bash_alias
    
    _ssh(){
      scp -q -o LogLevel=QUIET $HOME/.bashrc-ssh $1:/home/robert.kozak/.bashrc
      /usr/bin/ssh $@
    }
    alias ssh="_ssh"

2. copy .bashrc-ssh to your local $HOME

3. restart your shell or source $HOME/.bash_aliases

once those steps are done next time you ssh it will copy over the .bashrc-ssh file to the remote server as your new .bashrc which contains the new prompt

