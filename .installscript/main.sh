#!/bin/bash

dry_run(){
    if [[ $DRYRUN == true ]]; then
	echo $@
	return 0
    else
	$@
	return $?
    fi
}

die(){
    echo $@
    exit
}

getStdInstalls(){
    path="distros/"
    echo "checking OS"
    os=$(grep -e "^ID=" /etc/os-release | cut -d '=' -f 2)
    os = ${$os//\"}
    dry_run curl -f -o $FILE https://raw.githubusercontent.com/billionai/dotfiles/master/.installscript/distros/$os.sh
}

#main function I guess
echo "starting"

#parsing arguments
if [[ $# -ge 1 ]]; then
    if [[ $1 == "-d" ]] || [[ $1 == "--dry-run" ]]; then
	DRYRUN=true
    else
	if [[ $1 == "-n" ]] || [[ $1 == "--new" ]]; then
	    NEWBRANCH=true
	    [[ $# -ge 2 ]] || die "no name for new branch"
	    BRANCH=$2
	elif [[ $2 == "-n" ]] || [[ $2 == "--new" ]]; then
	    NEWBRANCH=true
	    BRANCH=$1
	else
	    NEWBRANCH=false
	    BRANCH=$1
	fi
    fi
else
    NEWBRANCH=false
fi

#check for custom file
FILE="./package.sh"
if [ -f $FILE ]; then 
    echo "found custom file";
else
    echo "No custom file found, getting things from git";
    getStdInstalls
fi

dry_run source $FILE
if ! dry_run "$pkgMgr $pkgInstall ${allPKG[@]}"; then
    echo "error installing dependencies, using slow one-at-a-time method"
    for pkg in "${allPKG[@]}"; do
	#don't need to dry_run here, cause dry_run always returns 0
	$pkgMgr $pkgInstall $pkg
	if [[ $? == 0 ]] && [[ $pkg =~ zsh ]]; then
	    #install OhMyZsh
	    sh -c "$(curl -fsSl https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi
    done
elif [[ " ${allPKG[*]} " =~ zsh ]]; then
    #install OhMyZsh
    sh -c "$(curl -fsSl https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "git cloning the dotfile repo"
dry_run "git clone --bare git@github.com:billionai/dotfiles $HOME/.cfg"
alias config='git --git-dit=$HOME/.cfg --work-tree=$HOME'

#check if user wants to checkout
if [[ $NEWBRANCH == true ]]; then #wants to create a new branch
    dry_run config -b checkout $BRANCH
elif [[ -n $BRANCH ]]; then #wants to branch to an existing branch
    dry_run config checkout $BRANCH || echo "checkout failed, check spelling and checkout manually"
fi #otherwise, keep in master branch

echo "setting default configs"
if ! grep $USER /etc/passwd; then
    echo "you are not in passwd, cant set some configs"
elif [[ " ${allPKG[@]} " =~ zsh ]]; then
    NEWSHELL=$(cat /etc/shells | grep zsh)
    dry_run chsh -s $NEWSHELL
fi

dry_run rm $FILE $0

echo "done"
