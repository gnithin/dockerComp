#!/bin/bash

# define your server hostname here; default name defined below..
SERVER_HOSTNAME=$(echo  $HOSTNAME  | awk -F'.' '{print $1}')
# SERVER_HOSTNAME=""

# To be used for checking dependencies
# Consider the deps to be not present
DOCKER_INSTALLED=0
PIP_INSTALLED=0
FLASK_INSTALLED=0
GIT_INSTALLED=0

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    echo -e "Cleaning Up and terminating..."
    sudo rm -rf src/
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

setup_env(){
    check_env=$(grep SERVER_D ~/.bashrc)
    if [[ -z $check_env ]]
    then
	echo "export SERVER_D='"$SERVER_HOSTNAME"'" >> ~/.bashrc
    else
	sed -i "s/.*SERVER_D=.*/export SERVER_D='$SERVER_HOSTNAME'/g" ~/.bashrc
    fi
    export SERVER_D=$SERVER_HOSTNAME
}

check_docker(){

    docker_op=`docker --version`

    if [[ $docker_op != *"command not found"* ]]
    then
	DOCKER_INSTALLED=1 # Docker is installed
	echo "Docker is already installed"
    fi
}

check_pip(){
    pip_op=`pip -V`
    if [[ $pip_op != *"command not found"* ]]
    then
	PIP_INSTALLED=1 # pip is installed
	echo "pip is already installed"
    fi
}

check_flask(){
    flask_op=`ls -l /usr/local/lib/python2.7/site-packages | grep flask`
    if [[ "X"$flask_op == "X" ]]
    then
	FLASK_INSTALLED=1 # flask is installed
	echo "flask is already installed"
    fi
}

check_git(){
    git_op=`git --version`

    if [[ $git_op != *"command not found"* ]]
    then
	GIT_INSTALLED=1 # git is installed
	echo "Git is already installed"
    fi
}

check_deps(){
    check_docker
    check_pip
    check_flask
    check_git
}

setup_deps(){
    check_deps
    if [ $GIT_INSTALLED -eq 1 ] && [ $DOCKER_INSTALLED -eq 1 ] && [ $PIP_INSTALLED -eq 1 ] && [ $FLASK_INSTALLED -eq 1 ]; then
	echo "All dependencies are statisfied."
	sudo usermod -a -G docker $USER
	return
    fi

    echo "What's your package manager?"
    echo "1. APT"
    echo "2. YUM"
    read opt

    if [ $opt -eq 1 ]; then
	command="sudo apt-get install -y" # deb based
    elif [ $opt -eq 2 ]; then
	command="sudo yum -y install"  # rpm based
    else
	echo "Wrong choice! Program Terminated!"
	echo "Error: Unable to continue for this very reason!"
	exit
    fi

    if [ $GIT_INSTALLED -eq 0 ]; then # install git
	git_install=$command" git"
	eval $git_install
    fi

    if [ $PIP_INSTALLED -eq 0 ]; then # install pip
	pip_install=$command" python-pip"
	eval $pip_install
    fi

    if [ $FLASK_INSTALLED -eq 0 ]; then # install flask
	sudo pip install flask
    fi


    if [ $DOCKER_INSTALLED -eq 0 ]; then # install docker
	if [ $opt -eq 1 ]; then # deb based
	    docker_install=$command" docker.io"
	    eval $docker_install
	    sudo ln -sf /usr/bin/docker.io /usr/local/bin/docker
	    sudo sed -i '$acomplete -F _docker docker' /etc/bash_completion.d/docker.io
	    source /etc/bash_completion.d/docker.io
	fi

	if [ $opt -eq 2 ]; then # rpm based
	    docker_install=$command" docker-io"
	    eval $docker_install
	    sudo systemctl start docker
	    sudo systemctl enable docker
	fi
    fi

    sudo usermod -a -G docker $USER
    #sudo newgrp docker
}

setup_app(){
    cd ~
    git clone https://github.com/arcolife/dockerComp.git
    cd dockerComp/
    # remove server side code, useless for normal users
    git config core.sparseCheckout true
    echo client-side/ > .git/info/sparse-checkout
    git checkout master
    cd client-side/
    sudo ./launch.sh $SERVER_D
    sudo ./test.sh $SERVER_D
}

setup_env
setup_deps
setup_app
