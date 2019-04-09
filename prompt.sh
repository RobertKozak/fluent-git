#!/bin/bash

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

# $1 text
# $FG = foreground color
# $BG = background color
segment () {
  eval fg="$FG\$$FG_COLOR"
  eval bg="$BG\$$BG_COLOR"
  printf "\e[%s;%s;%sm%s" $bold $fg $bg "$1"
}

# Colors
black=0
gray=0
red=1
green=2
yellow=3
blue=4
purple=5
cyan=6
white=7
none=8

# foreground
standard_fg=3
gray_fg=9
none_fg=9

# background colors
standard_bg=4
gray_bg=10
none_bg=10

FG=$standard_fg
BG=$standard_bg

bold=0
new_prompt="» "
reset="\[\033[00m\]"

get_current_action() {
    info="$(git rev-parse --git-dir 2>/dev/null)"
    if [ -n "$info" ]; then
        local action
        if [ -f "$info/rebase-merge/interactive" ]
        then
            action=${is_rebasing_interactively:-"rebase -i"}
        elif [ -d "$info/rebase-merge" ]
        then
            action=${is_rebasing_merge:-"rebase -m"}
        else
            if [ -d "$info/rebase-apply" ]
            then
                if [ -f "$info/rebase-apply/rebasing" ]
                then
                    action=${is_rebasing:-"rebase"}
                elif [ -f "$info/rebase-apply/applying" ]
                then
                    action=${is_applying_mailbox_patches:-"am"}
                else
                    action=${is_rebasing_mailbox_patches:-"am/rebase"}
                fi
            elif [ -f "$info/MERGE_HEAD" ]
            then
                action=${is_merging:-"merge"}
            elif [ -f "$info/CHERRY_PICK_HEAD" ]
            then
                action=${is_cherry_picking:-"cherry-pick"}
            elif [ -f "$info/BISECT_LOG" ]
            then
                action=${is_bisecting:-"bisect"}
            fi
        fi

        if [[ -n $action ]]; then printf "%s" "${1-}$action${2-}"; fi
    fi
}

build_git_prompt() {
    precmd
    prompt=""

    # Git info
    current_commit_hash=$(git rev-parse HEAD 2> /dev/null)
    is_a_git_repo=false
    [[ -n $current_commit_hash ]] && is_a_git_repo=true
    if [[ $is_a_git_repo ]]; then
        current_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
        if [[ $current_branch == 'HEAD' ]]; then detached=true; fi

        number_of_logs="$(git log --pretty=oneline -n1 2> /dev/null | wc -l)"
        if [[ $number_of_logs -eq 0 ]]; then
            just_init=true
        else
            upstream=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
            if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then has_upstream=true; fi

            git_status="$(git status --porcelain 2> /dev/null)"
            action="$(get_current_action)"
            if [[ $git_status =~ ($'\n'|^).M ]]; then has_modifications=true; fi
            if [[ $git_status =~ ($'\n'|^)M ]]; then has_modifications_cached=true; fi
            if [[ $git_status =~ ($'\n'|^)A ]]; then has_adds=true; fi
            if [[ $git_status =~ ($'\n'|^).D ]]; then has_deletions=true; fi
            if [[ $git_status =~ ($'\n'|^)D ]]; then has_deletions_cached=true; fi
            if [[ $git_status =~ ($'\n'|^)[MAD] && ! $git_status =~ ($'\n'|^).[MAD\?] ]]; then ready_to_commit=true; fi
            if [[ $git_status =~ ($'\n'|^)R ]]; then has_renamed_files=true; fi

            number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
            if [[ $number_of_untracked_files -gt 0 ]]; then has_untracked_files=true; fi

            tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
            if [[ -n $tag_at_current_commit ]]; then is_on_a_tag=true; fi

            if [[ $has_upstream == true ]]; then
                commits_diff="$(git log --pretty=oneline --topo-order --left-right ${current_commit_hash}...${upstream} 2> /dev/null)"
                commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
                commits_behind=$(\grep -c "^>" <<< "$commits_diff")
            fi

            if [[ $commits_ahead -gt 0 && $commits_behind -gt 0 ]]; then has_diverged=true; fi
            if [[ $has_diverged == false && $commits_ahead -gt 0 ]]; then should_push=true; fi

            will_rebase=$(git config --get branch.${current_branch}.rebase 2> /dev/null)

            number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
            if [[ $number_of_stashes -gt 0 ]]; then has_stashes=true; fi
        fi
   else
     firstprompt=""
     prompt=""
   fi

    printf -v git_prompt "%s" "$(custom_build_prompt ${enabled:-true} ${current_commit_hash:-""} ${is_a_git_repo:-false} ${current_branch:-""} ${detached:-false} ${just_init:-false} ${has_upstream:-false} ${has_modifications:-false} ${has_modifications_cached:-false} ${has_adds:-false} ${has_deletions:-false} ${has_deletions_cached:-false} ${has_untracked_files:-false} ${has_renamed_files:-false} ${ready_to_commit:-false} ${tag_at_current_commit:-""} ${is_on_a_tag:-false} ${commits_ahead:-false} ${commits_behind:-false} ${has_diverged:-false} ${should_push:-false} ${will_rebase:-false} ${has_stashes:-false} ${action})"

  }

  : ${git_has_untracked_files_symbol:='[untracked] '}
  : ${git_has_renamed_files_symbol:='[renamed] '}

  : ${git_has_adds_symbol:='[added] '}
  : ${git_has_deletions_symbol:='[deleted] '}
  : ${git_has_cached_deletions_symbol:='[staged deletions] '}
  : ${git_has_modifications_symbol:='[modified] '}
  : ${git_has_cached_modifications_symbol:='[staged modifications] '}
  : ${git_ready_to_commit_symbol:='[ready to commit] '}
  : ${git_is_on_a_tag_symbol:='[tag] '}
  : ${git_needs_to_merge_symbol:='[needs merge] '}
  : ${git_detached_symbol:='[detatched] '}
  : ${git_can_fast_forward_symbol:='[can FF »] '}
  : ${git_has_diverged_symbol:='[diverged] '}
  : ${git_not_tracked_branch_symbol:='[not tracked] '}
  : ${git_rebase_tracking_branch_symbol:='[rebase] '}
  : ${git_merge_tracking_branch_symbol:='[merge] '}
  : ${git_should_push_symbol:='[should push] '}
  : ${git_has_stashes_symbol:='[has stashes] '}

  function prompt_append {
     flag=$1
     symbol=$2
     if [[ $flag == false ]]; then symbol=''; fi

     echo -n "${symbol}"
  }

  function custom_build_prompt {
      enabled=${1}
      current_commit_hash=${2}
      is_a_git_repo=${3}
      current_branch=$4
      detached=${5}
      just_init=${6}
      has_upstream=${7}
      has_modifications=${8}
      has_modifications_cached=${9}
      has_adds=${10}
      has_deletions=${11}
      has_deletions_cached=${12}
      has_untracked_files=${13}
      has_renamed_files=${14}
      ready_to_commit=${15}
      tag_at_current_commit=${16}
      is_on_a_tag=${17}
      commits_ahead=${18}
      commits_behind=${19}
      has_diverged=${20}
      should_push=${21}
      will_rebase=${22}
      has_stashes=${23}

      prompt=""

      if [[ $is_a_git_repo == true ]]; then
          # on filesystem
          prompt=" "
          prompt+=$(prompt_append $has_stashes $git_has_stashes_symbol)
          prompt+=$(prompt_append $has_renamed_files $git_has_renamed_files_symbol)

          prompt+=$(prompt_append $has_untracked_files $git_has_untracked_files_symbol)
          prompt+=$(prompt_append $has_modifications $git_has_modifications_symbol)
          prompt+=$(prompt_append $has_deletions $git_has_deletions_symbol)

          # ready
          prompt+=$(prompt_append $has_adds $git_has_adds_symbol)
          prompt+=$(prompt_append $has_modifications_cached $git_has_cached_modifications_symbol)
          prompt+=$(prompt_append $has_deletions_cached $git_has_cached_deletions_symbol)

          # next operation
          prompt+=$(prompt_append $ready_to_commit $git_ready_to_commit_symbol)

          # where
          firstprompt="${prompt} ${current_branch} "
          prompt=' '

          if [[ $detached == true ]]; then
              prompt+=$(prompt_append $detached $git_detached_symbol)
              prompt+=$(prompt_append $detached "(${current_commit_hash:0:7}) ")
          else
              if [[ $has_upstream == false ]]; then
                  prompt+=$(prompt_append true "${git_not_tracked_branch_symbol} ")
              else
                  if [[ $will_rebase == true ]]; then
                      type_of_upstream=$git_rebase_tracking_branch_symbol
                  elif [[ $has_untracked_files == true || $has_modifications == true || $has_deletions == true || $has_adds == true || $has_modifications_cached == true || $has_deletions_cached == true || $ready_to_commit == true ]] ; then
                      type_of_upstream=$git_merge_tracking_branch_symbol
                  else
                      type_of_upstream=''
                  fi

                  if [[ $has_diverged == true ]]; then
                      prompt+=$(prompt_append true "[-${commits_behind} behind] ${git_has_diverged_symbol} [+${commits_ahead} ahead] ")
                  else
                      if [[ $commits_behind -gt 0 ]]; then
                          prompt+=$(prompt_append true "[-${commits_behind} behind] ${git_can_fast_forward_symbol} ")
                      fi
                      if [[ $commits_ahead -gt 0 ]]; then
                          prompt+=$(prompt_append true "${git_should_push_symbol}[+${commits_ahead} ahead] ")
                      fi
                  fi
                  prompt+=$(prompt_append true "${type_of_upstream}${upstream//\/$current_branch/} ")
              fi
          fi
          prompt+=$(prompt_append ${is_on_a_tag} "${git_is_on_a_tag_symbol}${tag_at_current_commit}")
      fi

      BG=$gray_bg
      FG=$gray_fg
      FG_COLOR=white
      BG_COLOR=blue
      segment "${firstprompt}"

      BG=$standard_bg
      FG_COLOR=blue
      BG_COLOR=blue
      segment ""

      FG=$standard_fg
      FG_COLOR=white
      BG_COLOR=blue
      segment "${prompt}"

      FG_COLOR=blue
      BG_COLOR=white
      segment ""
  }


_ssh_client(){
  if [[ -n "$SSH_CLIENT" ]]; then
    echo $SSH_CLIENT | awk {'print $1 " "'}
  fi
}

_kubernetes_env(){
  if [[ `command -v kubectl` ]]; then
    namespace=$(kubectl config get-contexts | grep $(kubectl config current-context) | awk {'print $5'})
    [[ -n $namespace ]] && namespace="| $namespace "
    echo -n " "`kubectl config current-context | xargs`" "$namespace
  else
    echo -n ""
  fi
}

function preexec() {
  timer=${timer:-$SECONDS}
}

function precmd() {
  TIMER_PROMPT=''
  ERROR_SEPARATOR=''

  # if environment var MIN_TIMER_DISPLAY is set use it otherwise use default of 30 seconds
  # Dont show time command took unless greater than the minimum
  if [[ "$MIN_TIMER_DISPLAY" == "" ]]; then
    MIN_TIMER=30
  else
    MIN_TIMER=${MIN_TIMER_DISPLAY}
  fi

  if [ $timer ]; then
    timer_show=$(($SECONDS - $timer))
    if [ $timer_show -gt $MIN_TIMER ]; then
      T=$timer_show
      H=$(printf "%02d:" $((T/60/60%24)))
      M=$(printf "%02d:" $((T/60%60)))
      S=$(printf "%02d" $((T%60)))
      if [[ "$H" == "00:" ]]; then H=''; fi
      TIMER_PROMPT=" ${H}${M}${S} "
    fi
    unset timer
  fi
}

_get_error_code() {
  error_code=$?
  error_segment=""
  ERROR_SEPARATOR=""

  FG_COLOR=white
  BG_COLOR=green
  if [[ "$error_code" != "0" ]]; then
    error_segment=" $error_code "
    if [ -n "$TIMER_PROMPT" ]; then
      ERROR_SEPARATOR="|"
    fi
    BG_COLOR=red
    error_code=0
  fi

  timer_segment=${TIMER_PROMPT}

  segment "$error_segment${ERROR_SEPARATOR}$timer_segment"

  FG_COLOR=$BG_COLOR
  BG_COLOR=white
  segment ""
}

segment1() {
  segment " \$(_get_error_code) "
}

segment_hostname () {
  FG_COLOR=black
  BG_COLOR=white

  segment ' $HOSTNAME '
  FG_COLOR=white
  BG_COLOR=blue
  segment ""
}

segment_username () {
  FG_COLOR=white
  BG_COLOR=blue

  segment ' $USER '
  BG=$gray_bg
  FG_COLOR=blue
  segment ""
}

segment_git () {
  echo -n -e `build_git_prompt`
}

segment_kubernetes_info () {
  FG_COLOR=black
  BG_COLOR=white
  segment '$(_kubernetes_env)'

  FG_COLOR=white
  BG_COLOR=gray
  BG=$gray_bg
  segment ""
}

segment_path () {
  FG_COLOR=white
  BG_COLOR=gray
  FG=$none_fg
  BG=$none_bg
  segment ' \w '
  FG_COLOR=gray
  BG_COLOR=none
  segment ""
  FG_COLOR=black

  echo -e -n ${reset}
  echo -e "\[\e[0K\]"
}

segment_sshclient () {
  FG_COLOR=cyan
  BG=$none_bg
  BG_COLOR=none
  segment '$(_ssh_client)'
  echo -e -n ${reset}
}

segment_prompt () {
  FG_COLOR=yellow
  BG_COLOR=none
  BG=$none_bg
  FG=$none_fg
  segment '$new_prompt '
}

preexec_invoke_exec () {
    [ -n "$COMP_LINE" ] && return  # do nothing if completing
    [ "$BASH_COMMAND" = "$PROMPT_COMMAND" ] && return # don't cause a preexec for $PROMPT_COMMAND
    local this_command=`HISTTIMEFORMAT= history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//"`;
    preexec "$this_command"
}
trap 'preexec_invoke_exec' DEBUG

PROMPT_COMMAND=`a=`build_git_prompt``
_prompt=$(echo -n $(segment1) && echo -n $(segment_hostname) && echo -n $(segment_username) && echo -n "\$git_prompt" && echo -n $(segment_kubernetes_info) && echo $(segment_path) && echo -n $(segment_sshclient) && echo -n $(segment_prompt) && echo ${reset})

PS1=$_prompt
