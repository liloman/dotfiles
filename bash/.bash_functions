# vim: set filetype=sh :
# My bash functions
# Copyright © 2015 liloman
#
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, see <http://www.gnu.org/licenses/>.

######################
#  Dir stack prompt  #
######################

#Insert into dir stack checking repetitions
add_dir_stack() { 
    local dir="$(realpath -P "${2:-"."}" 2>/dev/null)"
    [[ -d $dir ]] || { echo "Dir $dir not found";return;}
    # If executed del_dir_stack and keep working in it...
    [[ $1 == false && $_DIR_STACK_LDIR == $dir ]] && return
    _DIR_STACK_LDIR="$dir"
    #Check exclusions
    IFS=":"; excl=($DIRSTACK_EXCLUDE); unset IFS
    for elem in "${excl[@]}"; do [[ $elem = $dir ]]&& return; done
    #Check duplicates
    readarray -t dup <<<"$(dirs -p -l 2>/dev/null)"
    #First entry (0) is always $PWD
    dup=${dup[@]:1}
    for elem in "${dup[@]}"; do [[ $elem = $dir ]]&& return; done
    #Check limit
    (( ${#dup[@]} > $DIRSTACK_LIMIT )) && del_dir_stack $DIRSTACK_LIMIT silent
    pushd -n "${dir}" >/dev/null; 
}


#Delete dir stack whithout changing dir
del_dir_stack () { 
    #Get dir 1 by default
    local num=${1:-1}
    (( $num == 0 )) && num=-1
    local dest="$(dirs -l +$num 2>/dev/null)"
    #Empty dir stack, out of range dir index or index=0
    [[ $dest ]] || { echo "Incorrect dir stack index or empty stack";return;}
    # check if you want to delete current dir actually (no args)
    [[ ! $1  &&  $PWD != $dest ]] && return
    popd -n +$num >/dev/null
    (( $? == 0 )) && [[ ! $2 ]] && echo Deleted "$dest" from dir stack
}

#Go to a dir stack number. 
go_dir_stack() { 
    #Get absolute path
    local dir="$(dirs -l +$1 2>/dev/null)"
    [[ $dir ]] || { echo "Incorrect dir stack index or empty stack";return;}
    cd "$dir" && echo Changed dir to "$dir"
}

#Show the dir stack below the bash prompt
list_dir_stack() {
    [[ ${DIRSTACK_ENABLED} != true ]] && return
    local Orange='\e[00;33m'
    local back='\e[00;44m'
    local Reset='\e[00m'
    local Green='\e[01;32m'
    #Copy & Paste from any unicode table... 
    local one=$(printf "%s" ✪)
    local two=$(printf "%s" ✪)
    local cwd="$(pwd -P)"
    local i=0 
    local com="dirs -p -l"

    echo -e "${Green}${one} $USER$(__git_ps1 "(%s)") on $TTY@$HOSTNAME($KERNEL)"
    echo -ne "${Orange}${two} "
    add_dir_stack false "$cwd"

    #Must use IFS= to not remove trailing whitespaces by process substitution
    while IFS= read -r dir; do 
        if (( $i > 0 )); then 
            if [[ $dir == $cwd ]]; then #Put background color
                echo -ne "[${back}$i:${dir/$HOME/\~}${Orange}]";
            else
                echo -ne "[$i:${dir/$HOME/\~}]";
            fi
        fi
        ((i++))
    done < <($com)
    (( $i == 1 )) && echo -ne "${two} ${Orange}Empty dir stack(a add,d delete,g go number,~num alias)";

    #Print newline so for PS1
    echo -e "${Reset}"
}


if [ "${DIRSTACK_ENABLED}" == true ]; then
    [ -v DIRSTACK_LIMIT ] || echo DIRSTACK_LIMIT must be a number
    [ -v DIRSTACK_EXCLUDE ] || echo DIRSTACK_EXCLUDE must be a string
    alias a="add_dir_stack true"
    alias d=del_dir_stack
    alias g=go_dir_stack
fi


###########
# General #
###########

show_ps1() {
    local lastExit=$? # Should come first...
    local Blue='\[\e[01;34m\]'
    local White='\[\e[01;37m\]'
    local Red='\[\e[01;31m\]'
    local Green='\[\e[01;32m\]'
    local Reset='\[\e[00m\]'
    #Copy & Paste from any unicode table... 
    local arrow=$(printf "%s" ➬)


    error="${White}$lastExit"
    (( $lastExit )) && error="${Red}$lastExit"

    #Print command history and error number
    PS1=" ${Blue}[${Reset}C:${White}\#${Reset}-E:${error}"

    # Reset the text color to the default at the end.
    PS1+="${Blue}:${Red}\w]${Green}${arrow}${Reset}"
}


#Show the size of something
#maybe rework with tree or alike
tam() { du -hs "$@" | sort -h; }

#Print octal symbol ready to be used in bash 
# or just use printf %s :D
#Copy & Paste from any unicode table... 
get_octal() {
    local dump=$(od -t o1 <<< '$1')
    read -r _ a b c _ <<< "$dump"
    echo -n "\\$a\\$b\\$c"
    echo -e " ($1)"
}


bak() {
 local arg="$1" ; shift
 [[ -e $arg ]] || { echo "file/dir:$arg must exist"; return 1; }
 arg=${arg%/}
 local bak="$arg.bak"
 if [[ ${arg: -4} != .bak ]]; then 
     \cp -r "$arg" "$bak" && \
     echo "Copied $arg to $bak"
 else 
     bak="${arg%.bak}" && \
     \rm -rf "$bak" && \
     \mv "$arg" "$bak" && \
     echo "Moved $arg to $bak"
 fi
}

#Add new executable symlink to ~/.local/bin dir
lbin() {
    local dest=~/.local/bin/
    for arg; do
        local file="$(realpath "$arg" 2>/dev/null)"
        [[ -n $file ]] || { echo "Must pass a valid file"; return; }
        [[ ! -d $dest ]] && mkdir -p $dest
        ln -sfv  $file $dest
    done
}

#############
#  Desktop  #
#############

#Notify of events transient
notify(){
    local title="${FUNCNAME[1]:-"Info message"}"
    local text="${1:-"Notification text"}"
    local icon="${2:-"user-info"}"
    local timeout=4
    # zenity --timeout $timeout --info --title "$title" --text "$text"
    notify-send -t $(($timeout*1000)) --hint=int:transient:1 --icon="$icon" "$title" "$text" 
}

notify-err(){
local title="${FUNCNAME[1]:-"Info message"}"
local text="${1:-"Error text"}"
local icon="${2:-"user-info"}"
local timeout=4
notify-send -t $(($timeout*1000)) --icon="$icon" "$title" "$text" 
}

#Show current song from a Spotify generated file from a Windows VirtualBox
currentSpotifySong() {
    local file=/tmp/.spotify/title.txt
    local title= artist= song=
    [[ -d ${file%/*} ]] || mkdir ${file%/*}
    [[ -e $file ]] || touch $file
    while true; do 
        if inotifywait -e modify $file; then
            #let's give chance to release the file to the batch (sync)
            sleep 2
            read -r title < $file
            title=${title//^\"/}
            #ctl-v + ctl-m  not ^M!
            title=${title///}
            [[ $title == Spotify ]] && { notify "PAUSED!" folder-music ; continue; }
            artist=${title%%-*}
            song=${title#*-}
            echo "title:$title artist:$artist song:$song"
            # covert art from http://www.last.fm/music/Joe+Farrell/_/Follow+Your+Heart
            notify "$title" folder-music
        fi
    done
}

#Alternate between running/saved/paused/power off states of a VMVB
alternateVBox() {
    local machine="${1? $0 Needs a machine name}"
    local pause="$2"
    #Not Greedy state
    local regex='(State:)([[:space:]]*)([-[:alnum:][:space:]]*)([[:space:]].*)'

    #Get the VM info
    readarray -t info <<< "$(VBoxManage showvminfo "$machine" 2>/dev/null)" 
    #Search regex onto full array
    [[ ${info[@]} =~ ${regex} ]] || { echo "$machine not found"; return; }

    local state="${BASH_REMATCH[3]}"
    echo $machine State was:"\"$state\""

    if [[ $state == "paused" ]]; then
        VBoxManage controlvm "$machine" resume && \ 
        notify  "$machine resumed!" virtualbox
    fi

    case $state in saved|"powered off") VBoxManage startvm "$machine" --type headless && \
        notify  "$machine started!" virtualbox ;;
    esac

    if [[ $state == "running" ]]; then
        if [[ $pause ]]; then
            VBoxManage controlvm "$machine" pause && \
                notify  "$machine paused!" virtualbox
        else # Save state to hard disk
            VBoxManage controlvm "$machine" savestate && \
                notify  "$machine was saved!" virtualbox
        fi
    fi
}


#Download a vid and play it in FS from bash or vimperator or whatever
descarga() {
    local latest=false
    local dest=$HOME/Descargas/videoFlash
    local url="$1"
    # local options=" $url --add-metadata  --verbose -o $dest -f best --no-part "
    # failing --add-metadata option
    local options=" $url --verbose -o $dest -f best --no-part "
    killall -q youtube-dl
    cd ~ # youtube-dl doesn't get DEST right ¿?
    \rm -f $dest
    > $dest
    #Failback for latest youtube-dl in case of errors on fedora's one
    if [[ $latest = true ]]; then
        if [[ ! -x "~/Scripts/youtube-dl" ]]; then 
            wget https://yt-dl.org/latest/youtube-dl -O ~/Scripts/youtube-dl
            chmod +x ~/Scripts/youtube-dl
        fi
        ~/Scripts/youtube-dl $options >/tmp/youtube.log &
    else
        youtube-dl $options >/tmp/youtube.log &
    fi
    local downloading=$!
    # echo  "pgrep: $(pgrep -aw youtube-dl) downloading pid:$downloading" 
    read tam _ <<< $(du -b $dest)
    # Wait for 1M file
    while (( $tam < 1000000 )); do 
        read tam _ <<< $(du -b $dest)
        sleep 0.5
    done
    #It needs nohup to work on bash cli also
    nohup mplayer -fs $dest >/dev/null & 
    #it'd be better get the metadata working on local file but it doesn't work already
    local title="$(youtube-dl -e "$url")"
    wait $downloading && notify "Video downloaded for $title!" smplayer
}


#Download and install the current extension pack for virtualbox 
virtualboxGetExtensionPack() {
    local version=$(VBoxManage --version)
    local ver=${version:0:6}
    local base="http://download.virtualbox.org/virtualbox"
    local pkg="Oracle_VM_VirtualBox_Extension_Pack-$ver-${version: -6}.vbox-extpack"
    local url="$base/$ver/$pkg"
    cd /tmp/
    wget "$url" || { echo "URL:$url not found"; return; }
    echo Downloaded /tmp/"$pkg" 
    VBoxManage extpack install /tmp/"$pkg"
    VBoxManage list extpacks
}

#Sync & set firefox profile between RAM and non-voltatile storage
firefox_sync() {
    hash rsync || { echo rsync must be installed!; return; }
    #Firefox home
    local firhome="$HOME/.mozilla/firefox"
    #Firefox default profile
    local profile=($firhome/*.default)
    #RAM directory 
    local volatile="/tmp/firefox-$USER"
    #My profile name
    local link=${profile##*/}
    local static=${link}.solid

    #Changed to firefox home dir
    cd "$firhome"

    #First run of the day
    [[ -d $volatile ]] || mkdir -m0700 "$volatile"
    [[ -e $link ]] || { echo $link must exist!. ; return; }

    #if not already soft linked
    if [[ $(readlink $link) != $volatile ]]; then
        files=($link/*)
        #Move and make backup if not empty dir
        if (( ${#files[@]} > 1 )); then
            mv $link $static
            local cache=${HOME}/.cache/mozilla/firefox/
            [[ -d $cache ]] || mkdir -p "$cache"
            tar zcfp ${cache}/firefox_profile_backup.tar.gz $static
        fi
        ln -s $volatile $link
    fi


    if [[ -f $link/.unpacked ]]; then
        rsync -a --delete --exclude .unpacked ./$link/ ./$static/
    else
        rsync -a ./$static/ ./$link/
        touch $link/.unpacked
    fi
}

#get the photo of today from nationalgeographic and use it as wallpaper
doWallpaper() {
    #wallpaper url and title, need to be got from $com
    local url= title= line=
    local regex='<img src="([^"]*)".*alt="([^"]*)" />'
    local wallpaper=$HOME/.wallpaper-of-the-day
    local web=http://photography.nationalgeographic.com/photography/photo-of-the-day/
    local com="wget $web --quiet -O-"

    while IFS= read -r line; do
        if [[ $line =~ $regex ]]; then
            url="http:${BASH_REMATCH[1]}"
            title="${BASH_REMATCH[2]}"
            break
        fi
    done < <($com)

    if [[ -z $url ]]; then
        notify-err "doWallpaper failed.Couldn't retrieve the url" preferences-desktop-wallpaper
        return
    fi

    wget $url --quiet -O $wallpaper 
    pcmanfm -w  $wallpaper && notify "Background changed to:\n $title!" preferences-desktop-wallpaper
}


#Clean firefox profiles
cleanFirefox() {
    local profile="$1"; shift
    local wdirs="storage/  minidumps/"
    local rdirs="crashes/ datareporting healthreport/ saved-telemetry-pings/"
    [[ -z $profile ]] && { echo "Needs a profile"; return ; }

    cd ~/.mozilla/firefox/*.$profile 2>/dev/null || { echo "Profile:$profile incorrect"; return ; }


    echo "Doing clean up in firefox $profile"

    echo "Wiping readonly dirs..."
    for dir in $rdirs; do
        [[ -d $dir ]] || continue
        echo "Doing $dir"
        chmod a+w $dir
        rm -rfv $dir/*
        chmod a-w $dir
    done

    echo "Wiping writable dirs..."

    for dir in $wdirs; do
        [[ -d $dir ]] || continue
        echo "Doing $dir"
        rm -rfv $dir/*
    done

    echo "Wiping cache for $profile..."
    rm -rf ~/.cache/mozilla/firefox/*.$profile

    echo "Done!"
}


#Listen to several radios
radios(){
    [ "$1" = "xfm" ] && mplayer http://mediasrv-sov.musicradio.com/XFMLondon
    [ "$1" = "virgin" ] && mplayer http://www.smgradio.com/core/audio/ogg/live.pls?service=vrbb
    [ "$1" = "capital" ] && mplayer http://mediasrv-the.musicradio.com/CapitalRadio
    [ "$1" = "bbcworld" ] && mplayer -playlist  http://bbc.co.uk/radio/worldservice/meta/tx/nb/live_infent_au_nb.asx
    [ "$1" = "bbc1" ] && mplayer -playlist  http://bbc.co.uk/radio/listen/live/r1.asx
    [ "$1" = "bbc1x" ] && mplayer -playlist  http://bbc.co.uk/radio/listen/live/r1x.asx
    [ "$1" = "bbc2" ] && mplayer -softvol -softvol-max 200 -playlist  http://bbc.co.uk/radio/listen/live/r2.asx
    [ "$1" = "bbc3" ] && mplayer -softvol -softvol-max 200 -playlist  http://bbc.co.uk/radio/listen/live/r3.asx
    [ "$1" = "bbc4" ] && mplayer -playlist  http://bbc.co.uk/radio/listen/live/r4.asx
    [ "$1" = "bbc5" ] && mplayer -playlist  http://bbc.co.uk/radio/listen/live/r5.asx
    [ "$1" = "bbc6" ] && mplayer -playlist  http://bbc.co.uk/radio/listen/live/r6.asx
    [ "$1" = "bbcman" ] && mplayer -playlist  http://bbc.co.uk/radio/listen/live/bbcmanchester.asx
    [ "$1" = "vaughan" ] && mplayer http://server01.streaming-pro.com:8012 
    [ "$1" = "radio3" ] && mplayer -cache 500 -playlist http://rtve.stream.flumotion.com/rtve/radio3.mp3.m3u
    [ "$1" = "folk-eu" ] && mplayer http://www.live365.com/play/wumb919fast
    [ "$1" = "folk" ] && mplayer -cache 500 -playlist http://public.wavepanel.net/3LACLKLS7UVKONE4/listen/m3u
    # alias folkradio_graba='mplayer -cache 500 http://www.live365.com/play/wumb919fast -ao pcm:file=radio.wav -vo null -vc null'
    #FRANCE
    [ "$1" = "nrj" ] && mplayer mms://vipnrj.yacast.fr/encodernrj
    [ "$1" = "rtl" ] && mplayer http://streaming.radio.rtl.fr/rtl-1-44-96
    [ "$1" = "rtl2" ] && mplayer http://streaming.radio.rtl.fr/rtl2-1-44-96
    [ "$1" = "europe2" ] && mplayer mms://vipmms9.yacast.fr/encodereurope2
    [ "$1" = "fip" ] && mplayer http://viphttp.yacast.net/V4/radiofrance/fip_hd.m3u
    [ "$1" = "franceculture" ] && mplayer http://viphttp.yacast.net/V4/radiofrance/franceculture_hd.m3u
    [ "$1" = "franceinter" ] && mplayer http://viphttp.yacast.net/V4/radiofrance/franceculture_hd.m3u
    [ "$1" = "lemouv" ] && mplayer http://viphttp.yacast.net/V4/radiofrance/lemouv_hd.m3u
    echo "Posibles opciones: xfm virgin capital bbcworld bbc1 bbc1x bbc2 bbc3 bbc4 bbc5 bbc6 vaughan radio3 folk-eu folk rtl rtl2 nostalgie europe2 (broken links galore) "
}


#Let's use vim to read manpages right!
# function man() { vim -c "Man $*" -c "silent! only";  }

