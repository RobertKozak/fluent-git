# foreground
local blue="%{$FG[020]%}"
local darkblue="%{$FG[019]%}"
local white="%{$fg[white]%}"
local black="%{$fg[black]%}"
local green="%{$fg[green]%}"
local red="%{$fg[red]%}"
local gray="%{$FG[245]%}"
local cyan="%{$fg[cyan]%}"
local yellow="%{$fg[yellow]%}"

#background
local background_darkblue="%{$BG[019]%}"
local background_blue="%{$BG[020]%}"
local background_white="%{$bg[white]%}"
local background_red="%{$bg[red]%}"
local background_yellow="%{$bg[yellow]%}"
local background_gray="%{$BG[245]%}"
local background_green="%{$bg[green]%}"
local reset=%{$reset_color%}

local white_on_blue="${white}${background_blue}"
local white_on_darkblue="${white}${background_darkblue}"
local white_on_red="${white}${background_red}"
local white_on_green="${white}${background_green}"
local white_on_gray="${white}${background_gray}"
local blue_on_darkblue="${blue}${background_darkblue}"
local darkblue_on_gray="${darkblue}${background_gray}"
local darkblue_on_blue="${darkblue}${background_blue}"
local red_on_white="${red}${background_white}"
local green_on_white="${green}${background_white}"
local black_on_white="${black}${background_white}"

function get_current_action () {
    local info="$(git rev-parse --git-dir 2>/dev/null)"
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

function build_git_prompt {
    local enabled=`git config --local --get oh-my-git.enabled`
    if [[ ${enabled} == false ]]; then
        echo "${PSORG}"
        exit;
    fi

    local prompt=""

    # Git info
    local current_commit_hash=$(git rev-parse HEAD 2> /dev/null)
    if [[ -n $current_commit_hash ]]; then local is_a_git_repo=true; fi

    if [[ $is_a_git_repo == true ]]; then
        local current_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
        if [[ $current_branch == 'HEAD' ]]; then local detached=true; fi

        local number_of_logs="$(git log --pretty=oneline -n1 2> /dev/null | wc -l)"
        if [[ $number_of_logs -eq 0 ]]; then
            local just_init=true
        else
            local upstream=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
            if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then local has_upstream=true; fi

            local git_status="$(git status --porcelain 2> /dev/null)"
            local action="$(get_current_action)"

            if [[ $git_status =~ ($'\n'|^).M ]]; then local has_modifications=true; fi
            if [[ $git_status =~ ($'\n'|^)M ]]; then local has_modifications_cached=true; fi
            if [[ $git_status =~ ($'\n'|^)A ]]; then local has_adds=true; fi
            if [[ $git_status =~ ($'\n'|^).D ]]; then local has_deletions=true; fi
            if [[ $git_status =~ ($'\n'|^)D ]]; then local has_deletions_cached=true; fi
            if [[ $git_status =~ ($'\n'|^)[MAD] && ! $git_status =~ ($'\n'|^).[MAD\?] ]]; then local ready_to_commit=true; fi
            if [[ $git_status =~ ($'\n'|^)R ]]; then local has_renamed_files=true; fi

            local number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
            if [[ $number_of_untracked_files -gt 0 ]]; then local has_untracked_files=true; fi

            local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
            if [[ -n $tag_at_current_commit ]]; then local is_on_a_tag=true; fi

            if [[ $has_upstream == true ]]; then
                local commits_diff="$(git log --pretty=oneline --topo-order --left-right ${current_commit_hash}...${upstream} 2> /dev/null)"
                local commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
                local commits_behind=$(\grep -c "^>" <<< "$commits_diff")
            fi

            if [[ $commits_ahead -gt 0 && $commits_behind -gt 0 ]]; then local has_diverged=true; fi
            if [[ $has_diverged == false && $commits_ahead -gt 0 ]]; then local should_push=true; fi

            local will_rebase=$(git config --get branch.${current_branch}.rebase 2> /dev/null)

            local number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
            if [[ $number_of_stashes -gt 0 ]]; then local has_stashes=true; fi
        fi
    fi

    echo "$(custom_build_prompt ${enabled:-true} ${current_commit_hash:-""} ${is_a_git_repo:-false} ${current_branch:-""} ${detached:-false} ${just_init:-false} ${has_upstream:-false} ${has_modifications:-false} ${has_modifications_cached:-false} ${has_adds:-false} ${has_deletions:-false} ${has_deletions_cached:-false} ${has_untracked_files:-false} ${has_renamed_files:-false} ${ready_to_commit:-false} ${tag_at_current_commit:-""} ${is_on_a_tag:-false} ${commits_ahead:-false} ${commits_behind:-false} ${has_diverged:-false} ${should_push:-false} ${will_rebase:-false} ${has_stashes:-false} ${action})"

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
      local flag=$1
      local symbol=$2
      if [[ $flag == false ]]; then symbol=''; fi

      echo -n "${symbol}"
  }

  function custom_build_prompt {
      local enabled=${1}
      local current_commit_hash=${2}
      local is_a_git_repo=${3}
      local current_branch=$4
      local detached=${5}
      local just_init=${6}
      local has_upstream=${7}
      local has_modifications=${8}
      local has_modifications_cached=${9}
      local has_adds=${10}
      local has_deletions=${11}
      local has_deletions_cached=${12}
      local has_untracked_files=${13}
      local has_renamed_files=${14}
      local ready_to_commit=${15}
      local tag_at_current_commit=${16}
      local is_on_a_tag=${17}
      local commits_ahead=${18}
      local commits_behind=${19}
      local has_diverged=${20}
      local should_push=${21}
      local will_rebase=${22}
      local has_stashes=${23}

      local prompt=""

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
          firstprompt="${prompt}${current_branch} "
          prompt=' '

          if [[ $detached == true ]]; then
              prompt+=$(prompt_append $detached $git_detached_symbol)
              prompt+=$(prompt_append $detached "(${current_commit_hash:0:7}) ")
          else
              if [[ $has_upstream == false ]]; then
                  prompt+=$(prompt_append true "${git_not_tracked_branch_symbol} ")
              else
                  if [[ $will_rebase == true ]]; then
                      local type_of_upstream=$git_rebase_tracking_branch_symbol
                  elif [[ $has_untracked_files == true || $has_modifications == true || $has_deletions == true || $has_adds == true || $has_modifications_cached == true || $has_deletions_cached == true || $ready_to_commit == true ]] ; then
                      local type_of_upstream=$git_merge_tracking_branch_symbol
                  else
                      local type_of_upstream=''
                  fi

                  if [[ $has_diverged == true ]]; then
                      prompt+=$(prompt_append true "[-${commits_behind} behind] ${git_has_diverged_symbol} [+${commits_ahead} ahead] ")
                  else
                      if [[ $commits_behind -gt 0 ]]; then
                          prompt+=$(prompt_append true "[-${commits_behind} behind] ${white_on_darkblue}${git_can_fast_forward_symbol}${white_on_darkblue} ")
                      fi
                      if [[ $commits_ahead -gt 0 ]]; then
                          prompt+=$(prompt_append true "${white_on_darkblue}${git_should_push_symbol}${white_on_darkblue}[+${commits_ahead} ahead] ")
                      fi
                  fi
                  prompt+=$(prompt_append true "${type_of_upstream}${upstream//\/$current_branch/} ")
              fi
          fi
          prompt+=$(prompt_append ${is_on_a_tag} "${git_is_on_a_tag_symbol}${tag_at_current_commit}")
          prompt+="${reset}"
      fi

      echo "${firstprompt}${blue_on_darkblue}${white_on_darkblue}${prompt}"
  }


_zsh_terminal_set_256color() {
  if [[ "$TERM" =~ "-256color$" ]] ; then
    [[ -n "${ZSH_256COLOR_DEBUG}" ]] && echo "zsh-256color: 256 color terminal already set." >&2
    return
  fi

  local TERM256="${TERM}-256color"

  # Use (n-)curses binaries, if installed.
  if [[ -x "$( which toe )" ]] ; then
    if toe -a | egrep -q "^$TERM256" ; then
      _zsh_256color_debug "Found $TERM256 from (n-)curses binaries."
      export TERM="$TERM256"
      return
    fi
  fi

  # Search through termcap descriptions, if binaries are not installed.
  for termcaps in $TERMCAP "$HOME/.termcap" "/etc/termcap" "/etc/termcap.small" ; do
    if [[ -e "$termcaps" ]] && egrep -q "(^$TERM256|\|$TERM256)\|" "$termcaps" ; then
      _zsh_256color_debug "Found $TERM256 from $termcaps."
      export TERM="$TERM256"
      return
    fi
  done

  # Search through terminfo descriptions, if binaries are not installed.
  for terminfos in $TERMINFO "$HOME/.terminfo" "/etc/terminfo" "/lib/terminfo" "/usr/share/terminfo" ; do
    if [[ -e "$terminfos"/$TERM[1]/"$TERM256" || \
        -e "$terminfos"/"$TERM256" ]] ; then
      _zsh_256color_debug "Found $TERM256 from $terminfos."
      export TERM="$TERM256"
      return
    fi
  done
}

_colorize(){
  _zsh_terminal_set_256color
  unset -f _zsh_terminal_set_256color
}

_is_git(){
  if [[ $(git branch 2>/dev/null) != "" ]]; then echo 1 ; else echo 0 ; fi
}

_git_info(){
  if [[ $(_is_git) == 1 ]]; then
    build_git_prompt;
  else
    echo "${blue_on_darkblue}";
  fi
}

__ssh_client(){
  if [[ -n "$SSH_CLIENT" ]]; then
    echo $SSH_CLIENT | awk {'print $1 " "'};
  fi
}

# ⮞
# »
__prompt() {
  echo "»"
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
    local MIN_TIMER=30
  else
    local MIN_TIMER=${MIN_TIMER_DISPLAY}
  fi

  if [ $timer ]; then
    timer_show=$(($SECONDS - $timer))
    if [ $timer_show -gt $MIN_TIMER ]; then
      local T=$timer_show
      local H=$(printf "%02d:" $((T/60/60%24)))
      local M=$(printf "%02d:" $((T/60%60)))
      local S=$(printf "%02d" $((T%60)))
      if [[ "$H" == "00:" ]]; then H=''; fi
      TIMER_PROMPT=" ${H}${M}${S} "
      if [ "$TIMER_PROMPT" != "  " ]; then
        ERROR_SEPARATOR="|"
      fi
    fi
    unset timer
  fi
}

fluent_git(){
  setopt promptsubst

  RPROMPT=''
  PROMPT='
%(?.${white_on_green}${TIMER_PROMPT}${green_on_white}.${white_on_red} $(echo $?) ${ERROR_SEPARATOR}${TIMER_PROMPT}${red_on_white})${black_on_white} %m ${white_on_darkblue} $B%n$b ${darkblue_on_blue}${white_on_blue}`_git_info`${darkblue_on_gray}${white_on_gray} %3~ ${reset}${gray}${reset}
${cyan}$(__ssh_client)${reset}${yellow}$(__prompt)${reset} '
}

fluent_git_prompt(){
  fluent_git
}

_colorize()
autoload -U add-zsh-hook
fluent_git_prompt
