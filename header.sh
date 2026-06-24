#!/usr/bin/env sh

function declareUserPaths {
    if [[ -z ${declareUserPathsUsed+x} ]]; then
        readonly declareUserPathsUsed="Used already"
        
        readonly workDirName='Main'
        readonly userDirName="$(whoami)"
        readonly projectDirName='Projects'
        readonly downloadsDirName='Downloads'
        readonly musicDirName='Music'
        readonly appsDirName='Apps'
        readonly scriptsDirName='Scripts'
        
        readonly userHomeDir="/home/$userDirName"

        readonly wmDir="$userHomeDir/.windowManager"
        readonly projectDir="$userHomeDir/$projectDirName"
        readonly mainWorkDir="$userHomeDir/$workDirName"
        readonly downloadsDir="$userHomeDir/$downloadsDirName"
        readonly appsDir="$userHomeDir/$appsDirName"
        readonly musicDir="$userHomeDir/$musicDirName"
        readonly scriptsDir="$mainWorkDir/$scriptsDirName"
    fi
}
function failCond {
    local condition="$1"; local msg="$2"
    eval "$condition" "&& condpass=1"
    if [[ $condpass -eq 1 ]]; then
        printf "Error: $msg Exitting...\n" >&2
        exit 1
    fi
}
function askEvalDialogue {
    local message="$1"; local evalCodeOnYes="$2"
    printf "$message(y/n)\n"
    read ans
    while :
    do
        if [[ $ans == "y" ]]; then
            eval "$evalCodeOnYes"
            break
        elif [[ $ans == "n" ]] ; then
            break
        else
            echo "Please enter a valid option! (y/n)"
            read ans
        fi
    done
}
function printAndLog {
    local message="$1"; local dumpFilePath="$2"; local overwriteFlag="$3"
    if [[ "$overwriteFlag" == "-o" ]] && [[ "$overwriteFlag" == "--overwrite" ]]; then
        echo "$message"
        echo "$message" > "$dumpFilePath"
    else
        echo "$message"
        echo "$message" >> "$dumpFilePath"
    fi
}
function printLongAssLine {
    printf "\n____________________________________________________________\n"
}
function mkdirSilently {
    local path="$1"
    if [ ! -d "$path" ]; then
        mkdir "$path"
    fi
}
function rmSilently {
    local path="$1"
    if [ -f "$path" ]; then
        rm "$path"
    fi
}
function rmdirSilently {
    local path="$1"
    if [ -d "$path" ]; then
        rmdir "$path"
    fi
}
function checkInstallPackage {
    for arg in "$@"; do
        if ! dpkg -s "$arg" &>/dev/null; then
            sudo apt update 
            sudo apt upgrade
            sudo apt install "$arg"
            #If statement is useless since the installation is catching the internet off anyway
            if ! dpkg -s "$1" &>/dev/null; then
                echo "Failed to install the package: $arg. Exitting..."
                sleep 10
                exit 1;
            fi
        fi  
    done
}
function checkEmptyFolder {
    local path="$1"
    if [ -z "$( ls -A "$path" )" ]; then
        echo "Empty"
    else
        echo "Not empty"
    fi
}
function integerCheck {
    local integer=$1
    if [[ $integer =~ ^[0-9]+$ ]]; then
        echo 1;
    else
        echo 0; 
    fi
}
function getNewestFile {
    local dirPath="$1"
    local temp=$(find "$dirPath" -type f -print0 | xargs -0 stat -c "%n %Y" | sort -nrk2 | head -n 1)
    temp=${temp:0:-11}
    echo $temp
}
function getOldestFile {
    local dirPath="$1"
    local temp=$(find "$dirPath" -type f -print0 | xargs -0 stat -c "%n %Y" | sort -nk2 | head -n 1)
    temp=${temp:0:-11}
    echo $temp
}
