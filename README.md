# fluent-git

This is a custom prompt for zsh and bash

This prompt can display, on a line, one or more of the following:

* Time taken to execute command (if takes longer than 30 secs)
* error code
* hostname
* username
* local git status
* remote git status
* kubernetes cluster and namespace
* path
* ssh client connection


## BASH
add to the end of .bashrc

```bash
cp ./prompt.sh $HOME
source $HOME/propmt.sh
```

## ZSH
add fluent-git.theme to $ZSH/themes

```bash    
cp fluent-git.theme $ZSH/themes
```

## Example Screenshots


#### Example of the new prompt displaying execution time for last command

![Prompt with timer](full.png?raw=true)

#### Example of the new prompt displaying error code

![Example with error](error.png?raw=true)



## Adding fluent-git prompt to remote machines

if you want this prompt to be available on machines you ssh into you will need to copy the prompt.sh and .bashrc-ssh file to the server.

1. create alias in .bash_aliases

```bash
# when using -P arg: copy .bashrc-ssh file and do ssh else just do ssh
__ssh(){
   [[ $@ == *'-P'* ]] && echo "Copying bash profile for Fluent-git Prompt" && scp -q -o LogLevel=QUIET $HOME/.bashrc-ssh $1:/home/$USER/.bashrc
  
   /usr/bin/ssh $@
}

alias ssh="__ssh"
```

2. copy .bashrc-ssh to $HOME

```bash
cp .bashrc-ssh $HOME
```

3. Restart shell or source .bash_aliases

```bash
source $HOME./bash_aliases
```

once those steps are done next time you ssh it will copy over the .bashrc-ssh file to the remote server as your new .bashrc which contains the new prompt

