#!/bin/bash
#
# Bitshares node manager
# Released under GNU AGPL by Someguy123
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_DIR="$DIR/dkr"
DATADIR="$DIR/data"
DOCKER_NAME="bitshares"

BOLD="$(tput bold)"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
MAGENTA="$(tput setaf 5)"
CYAN="$(tput setaf 6)"
WHITE="$(tput setaf 7)"
RESET="$(tput sgr0)"

# default. override in .env
PORTS="7777"

if [[ -f .env ]]; then
    source .env
fi

if [[ ! -f data/witness_node_data_dir/config.ini ]]; then
    echo "config.ini not found. copying example (seed)";
    cp data/witness_node_data_dir/config.ini.example data/witness_node_data_dir/config.ini
fi

IFS=","
DPORTS=()
for i in $PORTS; do
    if [[ $i != "" ]]; then
            DPORTS+=("-p0.0.0.0:$i:$i")
    fi
done

help() {
    echo "Usage: $0 COMMAND [DATA]"
    echo
    echo "Commands: "
    echo "    start - starts bitshares container"
    echo "    replay - starts bitshares container (in replay mode)"
    echo "    shm_size - resizes /dev/shm to size given, e.g. ./run.sh shm_size 10G "
    echo "    stop - stops bitshares container"
    echo "    status - show status of bitshares container"
    echo "    restart - restarts bitshares container"
    echo "    install - pulls latest docker image from server (no compiling)"
    echo "    rebuild - builds bitshares container (from docker file), and then restarts it"
    echo "    build - only builds bitshares container (from docker file)"
    echo "    logs - show all logs inc. docker logs, and bitshares logs"
    echo "    wallet - open cli_wallet in the container"
    echo "    enter - enter a bash session in the container"
    echo
    exit
}


build() {
    echo $GREEN"Building docker container"$RESET
    cd $DOCKER_DIR
    docker build -t bitshares .
}

install() {
    # step 1, get rid of old bitshares
    echo "Stopping and removing any existing bitshares containers"
    docker stop bitshares
    echo "Loading image from someguy123/bitshares"
    docker pull someguy123/bitshares
    echo "Tagging as bitshares"
    docker tag someguy123/bitshares bitshares
    echo "Installation completed. You may now configure or run the server"
}

seed_exists() {
    seedcount=$(docker ps -a -f name="^/"$DOCKER_NAME"$" | wc -l)
    if [[ $seedcount -eq 2 ]]; then
        return 0
    else
        return -1
    fi
}

seed_running() {
    seedcount=$(docker ps -f 'status=running' -f name=$DOCKER_NAME | wc -l)
    if [[ $seedcount -eq 2 ]]; then
        return 0
    else
        return -1
    fi
}

start() {
    echo $GREEN"Starting container..."$RESET
    seed_exists
    if [[ $? == 0 ]]; then
        docker start $DOCKER_NAME
    else
        docker run ${DPORTS[@]} -v /dev/shm:/shm -v "$DATADIR":/bitshares -d --name $DOCKER_NAME -t bitshares
    fi
}

install_docker() {
    sudo apt update
    sudo apt install curl git
    curl https://get.docker.com | sh
    if [ "$EUID" -ne 0 ]; then
        echo "Adding user $(whoami) to docker group"
        sudo usermod -aG docker $(whoami)
        echo "IMPORTANT: Please re-login (or close and re-connect SSH) for docker to function correctly"
    fi
}

replay() {
    echo "Removing old container"
    docker rm $DOCKER_NAME
    echo "Running bitshares with replay..."
    docker run ${DPORTS[@]} -v /dev/shm:/shm -v "$DATADIR":/bitshares -d --name $DOCKER_NAME -t bitshares witness_node --replay
    echo "Started."
}

shm_size() {
    echo "Setting SHM to $1"
    mount -o remount,size=$1 /dev/shm
}

stop() {
    echo $RED"Stopping container..."$RESET
    docker kill -s SIGINT $DOCKER_NAME
    docker stop -t 200 $DOCKER_NAME
    docker rm $DOCKER_NAME
}

enter() {
    docker exec -it $DOCKER_NAME bash
}

wallet() {
    docker exec -it $DOCKER_NAME cli_wallet
}

logs() {
    echo $BLUE"DOCKER LOGS: "$RESET
    docker logs --tail=30 $DOCKER_NAME
    #echo $RED"INFO AND DEBUG LOGS: "$RESET
    #tail -n 30 $DATADIR/{info.log,debug.log}
}

status() {
    
    seed_exists
    if [[ $? == 0 ]]; then
        echo "Container exists?: "$GREEN"YES"$RESET
    else
        echo "Container exists?: "$RED"NO (!)"$RESET 
        echo "Container doesn't exist, thus it is NOT running. Run $0 build && $0 start"$RESET
        return
    fi

    seed_running
    if [[ $? == 0 ]]; then
        echo "Container running?: "$GREEN"YES"$RESET
    else
        echo "Container running?: "$RED"NO (!)"$RESET
        echo "Container isn't running. Start it with $0 start"$RESET
        return
    fi

}

if [ "$#" -lt 1 ]; then
    help
fi

case $1 in
    build)
        echo "You may want to use '$0 install' for a binary image instead, it's faster."
        build
        ;;
    install)
        install
        ;;
    start)
        start
        ;;
    replay)
        replay
        ;;
    shm_size)
        shm_size $2
        ;;
    stop)
        stop
        ;;
    install_docker)
        install_docker 
        ;;
    restart)
        stop
        sleep 5
        start
        ;;
    rebuild)
        stop
        sleep 5
        build
        start
        ;;
    optimize)
        echo "Applying recommended dirty write settings..."
        optimize
        ;;
    status)
        status
        ;;
    wallet)
        wallet
        ;;
    enter)
        enter
        ;;
    logs)
        logs
        ;;
    *)
        echo "Invalid cmd"
        help
        ;;
esac
