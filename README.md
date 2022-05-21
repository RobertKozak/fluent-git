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


### Installation 

You can install this custom prompt or theme in bash or zsh shell. 

## BASH
copy .prompt to $HOME and add to the end of .bashrc

```bash
cp .prompt $HOME/.prompt
echo "source .prompt" >> $HOME.bashrc
source $HOME/.bashrc
```

## ZSH
Requires oh-my-zsh to work properly in zsh shell https://ohmyz.sh/#install

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
 
* add fluent-git.theme to $ZSH/themes
* add ZSH_THEME="fluent-git" to .zshrc

```bash    
cp .prompt $ZSH/themes/fluent-git.theme
echo "ZSH_THEME="fluent-git"" >> $HOME/.zshrc
source $HOME/.zshrc
```

## Example Screenshots


#### Example of the new prompt displaying execution time for last command

![Prompt with timer](full.png?raw=true)

#### Example of the new prompt displaying error code

![Example with error](error.png?raw=true)


### NOTE:

You will need to set up your terminal to use a patched powerline font so the characters in the prompt will display correctly.

You can get pick a font from here: https://github.com/powerline/fonts


## Adding fluent-git prompt to remote machines (bash)

if you want this prompt to be available on machines you ssh into you will need to copy the .prompt file to the server.

1. create alias in .bash_aliases

```bash
# when using -P arg: copy .bashrc-ssh file and do ssh else just do ssh
__ssh(){
   [[ $@ == *'-P'* ]] && echo "Copying bash profile for Fluent-git Prompt" && scp -q -o LogLevel=QUIET $HOME/.prompt $1:/home/$USER/.bashrc
  
   /usr/bin/ssh $@
}

alias ssh="__ssh"
```

2. Restart shell or source .bash_aliases

```bash
source $HOME./bash_aliases
```

once those steps are done next time you ssh with -P arg it will copy over the .prompt to the remote server as your new .bashrc which contains the new prompt

example:

```bash
ssh bastion -P
```
