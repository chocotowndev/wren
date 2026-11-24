#!/bin/bash
# Wren Launcher

##
# Mandatory Variables
##
# done this way so these things can't be overdone by the config file if present
mandatory_vars () {
    PREFIX="[wren]"
    VERSION="3.0"

    E="\033[31m"
    W="\033[33m"
    R="\033[0m"
    S="\033[32m"
    B="\033[1m"
    J='\033[1;34m'
    G="\033[1;37m"
}

print_config () {
    echo -e "${W}$PREFIX${R}     WREN_USER='$(whoami)'"
    echo -e "${W}$PREFIX${R}     SERVER_DIR='$SERVER_DIR'"
}


##
# Config
##
CONFIG_FILE="$HOME/.config/wren/wren.conf"
SERVER_DIR="/srv"
WREN_USER="$(whoami)"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    mandatory_vars
else
    mandatory_vars
    echo -e "${PREFIX} Config file not found, using defaults which are:"
    print_config
fi


##
# Commands
##
if [[ ! -d "$SERVER_DIR" ]]; then
    echo -e "${E}${PREFIX}${R} Your server directory ($SERVER_DIR) does not exist"
    exit 1
fi

if [[ $1 == "help" ]]; then
    echo -e "${W}$PREFIX${R} ${J}Wren Launcher v${VERSION}${R}"
    echo -e "${W}$PREFIX${R} (c) 2023-2026"
    echo -e "${W}$PREFIX${R} ${J}Commands:${R}"
    echo -e "${W}$PREFIX${R}    help    ${G}             ${R}       Show this help menu"
    echo -e "${W}$PREFIX${R}    config  ${G}             ${R}       Show your configuration"
    echo -e "${W}$PREFIX${R}    list    ${G}             ${R}       Show all running containers"
    echo -e "${W}$PREFIX${R}    start   ${G}(server name)${R}       Run start script of server"
    echo -e "${W}$PREFIX${R}    restart ${G}(server name)${R}       Run restart script of server"
    echo -e "${W}$PREFIX${R}    stop    ${G}(server name)${R}       Run stop script of server"
    echo -e "${W}$PREFIX${R}    kill    ${G}(server name)${R}       Kill container of server"
    echo -e "${W}$PREFIX${R}    console ${G}(server name)${R}       Open to console of server"
    echo -e "${W}$PREFIX${R} ${J}Available servers:${R}"
    for server in ${servers[@]}; do
        echo -e "${W}$PREFIX${R}    $server"
    done

elif [[ $1 == "start" ]]; then
    echo -e "${W}$PREFIX${R} Starting $2..."
    sudo -u "$WREN_USER" tmux -S /tmp/tmux_$2 new-session -d -s "$2" -c "$GAME_DIR/$2" "sh start.sh"
    sudo chgrp admin /tmp/tmux_$2
    sudo chmod 770 /tmp/tmux_$2

elif [[ $1 == "stop" ]]; then
    echo -e "${W}$PREFIX${R} Stopping $2..."
    sudo -u "$WREN_USER" tmux -S /tmp/tmux_$2 send-keys -t "$2" "stop" C-m

elif [[ $1 == "restart" ]]; then
    echo -e "${W}$PREFIX${R} Restarting $2..."
    sudo -u "$WREN_USER" tmux -S /tmp/tmux_$2 send-keys -t "$2" "restart" C-m

elif [[ $1 == "kill" ]]; then
    read -r -p "$(echo -e "${W}${PREFIX}${R} You're about to ${E}${B}kill${R} a process ($2). ${E}${B}This could lead to data corruption${R}, would you like to continue? [y/N] ")" ans

    if [[ "${ans,,}" == "y" ]]; then
        echo -e "${W}${PREFIX}${R} Killing $2..."
        sudo -u "$WREN_USER" tmux -S /tmp/tmux_$2 kill-session -t "$2"
    elif [[ "${ans,,}" == "n" ]]; then
        echo -e "${W}${PREFIX}${R} Did not kill $2..."
    else 
        echo -e "${W}${PREFIX}${R} Something went wrong. Did not kill $2."
    fi

elif [[ $1 == "config" ]]; then
    echo -e "${W}$PREFIX${R} Here's your current configuration:"
    print_config

elif [[ $1 == "list" ]]; then
    echo -e "${W}$PREFIX${R} Here's all the containers:"

    for server in "${servers[@]}"; do
        socket="/tmp/tmux_$server"

        if [[ -S "$socket" ]]; then
            echo -e "${S}$PREFIX${R} $server is running:"
            sudo -u "$WREN_USER" tmux -S "$socket" list-sessions
        else
            echo -e "${W}$PREFIX${R} $server is not running."
        fi
    done

elif [[ $1 == "console" ]]; then
    echo -e "${W}$PREFIX${R} Opening console of $2..."
    echo -e "${W}$PREFIX${R} "
    echo -e "${E}$PREFIX${R} ${E}!! IMPORTANT !!"
    echo -e "${W}$PREFIX${R} Do not use ${H}ctrl + c${R}."
    echo -e "${W}$PREFIX${R} To exit a container use ${H}ctrl + b${R} then ${H}d${R}."
    echo -e "${W}$PREFIX${R} To copy to clipboard use ${H}ctrl + shift + c${R}."
    echo -e "${W}$PREFIX${R} "
    read -r -p "$(echo -e ${W}$PREFIX${R}" "${G}"Press enter to continue")"

    sudo -u "$WREN_USER" tmux -S /tmp/tmux_$2 attach -t "$2"

else
    echo -e "${W}$PREFIX${R} Unknown command. See ${S}$0 help${R} for more"
fi
