# vim: set filetype=sh :
# My bashrc for non-login shells
# see /usr/share/doc/bash/examples/startup-files for examples
# Copyright © 2016 liloman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#

# If not running interactively return!
[[ -z $PS1 ]] && return

###################
#  Shell options  #
###################

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
# Prepend cd to directory names automatically (../var = cd ../var)
shopt -s autocd
# Fix cd spelling
shopt -s cdspell
# Correct dir spelling errors during tab-completion
shopt -s dirspell 
# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob
# Save multiline commands in one line
shopt -s cmdhist
# Dont delete history
shopt -s histappend
# Regexp in bash prompt
shopt -s extglob
#Disable report expansion errors (lot of problems...)
#like wget http://url or tab completition
shopt -u failglob
#Allow dot expansion by globbing
shopt -s dotglob
#Allow ** globbing ( cd **/jor will enter foo/bar/baz/jor) o_O
shopt -s globstar
#Don't execute history autocompletions but print it. Better than the magic-space
shopt -s histverify

#Disable <C-s>(stop) and <C-q>(start) on terminal. To use <C-s> on vim (to save file)
stty stop undef
stty start undef
#Disable control flow completely and press any key to start
stty -ixon -ixoff ixany


#Disable caps bloq  (needs work)
# setxkbmap -option ctrl:nocaps
#xmodmap -e 'clear Lock' -e 'keycode 0x42 = Escape'

#######################
# INTERNAL VARIABLES  #
#######################

KERNEL=$(uname -r)
TTY=$(tty)

# MUST come first...
PROMPT_COMMAND='lastExit=$?' 

#Unlimited History file (all sessions)
HISTFILESIZE=
#History lines (current session)
#be generous to be able to work with asyncBash (fc) when history > histsize
# "out of range" error
HISTSIZE=$HISTFILESIZE
#Maybe I should rework this to make it dinamic again...
HISTFILE=~/.bash_history
#Show history timestamp with current locale
HISTTIMEFORMAT="%c | "
#Don't insert into history exits,bg,clears and histories commands
HISTIGNORE="exit:clear:bg:history *:fc *"
#Don't put duplicate lines in the history.
#if change review set_cmd_number bash<->readline ipc
HISTCONTROL=ignoredups
# to work properly with shopt -s extglob  (ls -d .*)
GLOBIGNORE=.:..
#just show the last 2 dirs on PS1 \w dirs
PROMPT_DIRTRIM=2


############
#  COLORS  #
############

# A lot of script to for colors 
# https://github.com/pvinis/colortools
if tput setaf 1 &> /dev/null; then
    tput sgr0; # reset colors
    bold=$(tput bold);
    reset=$(tput sgr0);
    # Solarized colors, taken from http://git.io/solarized-colors.
    black=$(tput setaf 0);
    blue=$(tput setaf 33);
    cyan=$(tput setaf 37);
    green=$(tput setaf 64);
    orange=$(tput setaf 166);
    purple=$(tput setaf 125);
    red=$(tput setaf 124);
    violet=$(tput setaf 61);
    white=$(tput setaf 15);
    yellow=$(tput setaf 136);
else
    bold='';
    reset="\e[0m";
    black="\e[1;30m";
    blue="\e[1;34m";
    cyan="\e[1;36m";
    green="\e[1;32m";
    orange="\e[1;33m";
    purple="\e[1;35m";
    red="\e[1;31m";
    violet="\e[1;35m";
    white="\e[1;37m";
    yellow="\e[1;33m";
fi;


###################
#  Stderr in red  #
###################
# exec 9>&2
# exec 8> >(
# while IFS= read -r line || [[ -n $line ]]; do
#     echo -e "\[\e[00;31m\]${line}\[\e[00m\]"
# done
# )
#
# function undirect(){ exec 2>&9; }
# function redirect(){ exec 2>&8; }
# trap "redirect;" DEBUG
# PROMPT_COMMAND+='undirect;'

########################
#  EXPORTED VARIABLES  #
########################

needs(){ hash $1 2>/dev/null; return $?; }

#Default vagrant provider to virtualbox otherwise libvirt
export VAGRANT_DEFAULT_PROVIDER=virtualbox
#less options applied
export LESS=" -eIRMX " 
#less colored when possible... :S
#needs customs cases...
[[ -f /usr/bin/src-hilite-lesspipe.sh ]] && export LESSOPEN="| /usr/bin/src-hilite-lesspipe.sh %s"
#-e quit at 2 eof, -I case insensitive search
#-r raw control displayed (colors), -M long prompt
# -X dont send de/initialization strings to the terminal
# make less more friendly for non-text input files, see lesspipe(1)
[[ -x /usr/bin/lesspipe ]] && eval "$(lesspipe)"

#Default editor
needs vim && { 
export EDITOR=vim
export FCEDIT=$EDITOR
export GIT_EDITOR=$EDITOR
export VISUAL=$EDITOR
}

#Let's use most  (case sensitive search not working ¿? ). 
# TODO: map shift-space to page-up in ~/.mostrc
needs most && export PAGER="most" MOST_SWITCHES="-c"
# open  the manpages in a brower with man -H command :)
needs firefox && export BROWSER="firefox" 
# show file, line and func when set -x
export PS4='(${BASH_SOURCE}:${LINENO})(${FUNCNAME[0]}): '
export PS2="\[${yellow}\]ps2> \[${reset}\]";
#show messages in english with UTF-8 (powerline...)
export LANG=C.utf8
#Fix broken lxsession config dirs
export XDG_CONFIG_DIRS=$HOME/.config

export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig/"

[[ $TERM == xterm ]] && TERM=xterm-256color

#Realtime logs file
export RTLOG=/tmp/.output_logs.txt


#Sometimes the systemd user instance fails and this fix it... ¿?
export XDG_RUNTIME_DIR=/run/user/$(id -u)
#Export path to systemd user units 
systemctl --user set-environment PATH=$PATH

###########
#  Files  #
###########

# PATH modified in ~/.bash_profile

#source a filepath and declare variables
import(){
    #To work with file expansion
    if [[ -f $(echo $1) ]]; then
        . $1
        shift
        for arg; do
            eval $arg
        done
    else
        #Don't print anything before first prompt to not tamper asyncBash_consolerow
        #echo "Failed import:$1 not found"
        return 1
    fi
}



#Load asyncBash plugin 
import ~/Clones/mine/asyncBash/asyncBash.sh asyncBash_prompt_command_lines=2 
#load bash-surround keybindings AFTER asyncBash otherwise asyncBash doesn't work ¿?
bind -f ~/.inputrc-surround

#Load dirStack plugin
import  ~/Clones/mine/dirStack/dirStack.sh DIRSTACK_EXCLUDE+=":$HOME/dotfiles" DIRSTACK_HEADER=true || asyncBash_prompt_command_lines=0

#Z script to get the most common directories and so on
#  https://github.com/rupa/z 
import ~/Clones/third/z/z.sh _Z_DATA=$HOME/.zs/.z _Z_NO_PROMPT_COMMAND=true

# load definitions before aliases to work with custom aliases
import ~/.bash_functions

# Function definitions
import ~/Scripts/libnotify

# Alias definitions
import ~/.bash_aliases

#Enable Autocompletions 
. /usr/share/bash-completion/bash_completion 

#To work with git 
import /usr/share/doc/git-core-doc/contrib/completion/git-completion.bash 
#count with dirstack enabled
import /usr/share/doc/git-core-doc/contrib/completion/git-prompt.sh   || { DIRSTACK_HEADER=false; asyncBash_prompt_command_lines=2; }

# added by travis gem
import ~/.travis/travis.sh 

#tmuxinator
import /usr/share/gems/gems/tmuxinator*/completion/tmuxinator.bash

#set a colored ps1 with exit value,command number and vi mode
#not ; starting cause z has wrong prompt_command append
PROMPT_COMMAND+='set_ps1'

#delete import function
unset -f import needs


