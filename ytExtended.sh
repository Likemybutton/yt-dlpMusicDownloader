#!/usr/bin/env sh

userDirName=$(whoami)
userHomeDir="/home/$userDirName"
downloadsDir="$userHomeDir/$downloadsDirName"

function checkInstallPackage() {
    if ! dpkg -s "$1" &>/dev/null; then
        bash "$mainWorkDir"/Scripts/systemUpdate.sh
        sudo apt install "$1"
        if ! dpkg -s "$1" &>/dev/null; then
            echo "Failed to install the package: $1. Exitting..."
            sleep 10
            exit 1;
        fi
    fi  
}
checkInstallPackage id3v2
checkInstallPackage p7zip-full

downloadsDestDirPath="$downloadsDir/yt-dlp"
ytdlpPrintOutputFilePath="$downloadsDir/yt-dlpOutput.txt"
ytdlpDownloadNamesFilePath="$downloadsDir/yt-dlpDownloadNames.txt"
ytdlpDownloadTempRenamesFilePath="$downloadsDir/yt-dlpDownloadRenames.txt"
ytdlpSongNamesFilePath="$downloadsDir/yt-dlpSongNames.txt"
ytdlpExtractAudioLineStart="[ExtractAudio] Destination: $downloadsDestDirPath/"
ytdlpExtractAudioLineStartLength=${#ytdlpExtractAudioLineStart}
authorName=""
albumName=""
releaseYear=""
function wronglyNamesSongsMessagePrint() {
    echo "Please edit the file $ytdlpSongNamesFilePath to the desired names."
    echo "After editing the file, launch the script with \"--edit\" option."
    echo "DO NOT CHANGE THE ORDER OF SONG NAMES! DO NOT CHANGE THE CONTENTS OF $downloadsDestDirPath DIRECTORY!"
    echo "Exitting..."
}
function tagUserInputDialogue() {
    echo "Please enter author's name:"
    read authorName
    echo "Please enter album name:"
    read albumName
    echo "Please enter year of release:"
    read releaseYear
    while :
    do
        if [[ $releaseYear =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Please enter a number:"
            read releaseYear
        fi
    done
}
function tagUserInputCheckPrint() {
    printLongAssLine
    printf "\nPrinting inputted information:\n"
    printf "Author: $authorName\n"
    printf "Album: $albumName\n"
    printf "Year: $releaseYear\n"
    printf "Is the information correct? (y/n)\n"
}
function assignTagsAndRenameDownloads() {
    printf "" > "$ytdlpDownloadTempRenamesFilePath"
    local i=1
    while read -r file; do
        id3v2 -D "$downloadsDestDirPath/$file"
        songName=$(sed "${i}q;d" "$ytdlpSongNamesFilePath")
        id3v2 -2 --TIT2 "$songName" "$downloadsDestDirPath/$file"
        id3v2 -2 --TPE1 "$authorName" "$downloadsDestDirPath/$file"
        id3v2 -2 --TRCK $i "$downloadsDestDirPath/$file"
        id3v2 -2 --TALB "$albumName" "$downloadsDestDirPath/$file"
        id3v2 -2 --TYER "$releaseYear" "$downloadsDestDirPath/$file"
        id3v2 -2 --TPE2 "$authorName" "$downloadsDestDirPath/$file"
        id3v2 -2 --COMM "Downloaded from youtube for personal non-commercial use" "$downloadsDestDirPath/$file"
        echo "$authorName - $albumName - $i - $songName.mp3" >> "$ytdlpDownloadTempRenamesFilePath"
        mv "$downloadsDestDirPath/$file" "$downloadsDestDirPath/$authorName - $albumName - $i - $songName.mp3"
        ((i++))
    done <"$ytdlpDownloadNamesFilePath"
    mv "$ytdlpDownloadTempRenamesFilePath" "$ytdlpDownloadNamesFilePath"
}
function archiveDownloads() {
    local archiveDate=$(date +"%s")
    for file in "$downloadsDestDirPath/"*; do
        7z a "$downloadsDir/$authorName - $albumName - $archiveDate.7z" "$file"
        printf "\n"
    done
}
function printTagsInDestDir() {
    for file in "$downloadsDestDirPath/"*; do
        id3v2 -l "$file"
        printf "\n"
    done
}
function printFileNamesInDestDir() {
    for file in "$downloadsDestDirPath/"*; do
        echo "$file"
    done
}
function taggingBusiness() {
    printf "\nAre songs named correctly? (y/n)\n"
    read ans
    while :
    do
        if [ $ans == "y" ]; then
            break
        elif [ $ans == "n" ]; then
            wronglyNamesSongsMessagePrint
            exit 0
        else
            echo "Please enter a valid option!"
            read ans
        fi
    done
    tagUserInputDialogue
    while :
    do
        tagUserInputCheckPrint
        read ans
        if [ $ans == "y" ]; then
            break
        elif [ $ans == "n" ]; then
            tagUserInputDialogue
        else
            printf ""
        fi
    done
    assignTagsAndRenameDownloads
    archiveDownloads
    printLongAssLine
}
function downloadYoutubeAlbumDestructor(){
    echo "Cleaning up temp files and folders."
    rm "$ytdlpPrintOutputFilePath"
    rm "$ytdlpDownloadNamesFilePath"
    rm "$ytdlpSongNamesFilePath"
    for file in "$downloadsDestDirPath/"*; do
        rm "$file"
    done
    rmdir "$downloadsDestDirPath"
}
function downloadYoutubeAlbumConstructor(){
    echo "Creating/Overriding empty temp files and folders: "
    mkdir "$downloadsDestDirPath"
    printf "" > "$ytdlpPrintOutputFilePath"
    printf "" > "$ytdlpDownloadNamesFilePath"
    printf "" > "$ytdlpSongNamesFilePath"
}
function printHelpMessage {
    printf "\nOptions:"
    printf "\n\t[Youtube Playlist Link] \t Downloads youtube playlist through yt-dlp in mp3 format, proceeds to rename downloads' ID3v2 tags on inputted metadata by the user, archives downloaded music into .7z file.\n"
    printf "\n\t--edit \t Renames ID3v2 tags for the files placed in $downloadsDestDirPath, archives output into .7z file.\n"
    printf "\n\t--clean \t Deletes all files produced by the script.\n"
    printf "\n\t--print \t Prints all ID3v2 tags of .mp3 files placed in $downloadsDestDirPath.\n"
    printf "\n\t--names \t Prints all file names of .mp3 files placed in $downloadsDestDirPath.\n"
    printf "\n\t--help \t Prints this message\n"
    printf "\n"
}
if [ $# -eq 1 ]; then
    arg="$1"
    youtubeLinkBegining=${arg:0:32}
    if [ $youtubeLinkBegining == "https://www.youtube.com/playlist" ]; then
        downloadYoutubeAlbumDestructor
        downloadYoutubeAlbumConstructor
        yt-dlp -t mp3 "$1" -P "$downloadsDestDirPath" | tee "$ytdlpPrintOutputFilePath"
        while read -r line; do
            echo "${line:$ytdlpExtractAudioLineStartLength}" >> "$ytdlpDownloadNamesFilePath"
        done < <(grep "\[ExtractAudio\]" "$ytdlpPrintOutputFilePath")
        printf "\nListing downloaded song names:\n"
        printLongAssLine
        while read -r line; do
            songName=$(echo "$line" | sed 's/[[][^]]*]//')
            songName=${songName:0:-5}
            echo $songName
            echo $songName >> "$ytdlpSongNamesFilePath"
        done <"$ytdlpDownloadNamesFilePath"
        taggingBusiness
    elif [ "$1" == "--edit" ]; then
        printf "\nListing downloaded song names:\n"
        printLongAssLine
        while read -r line; do
            echo $line
        done <"$ytdlpSongNamesFilePath"
        taggingBusiness
    elif [ "$1" == "--clean" ]; then
        downloadYoutubeAlbumDestructor
    elif [ "$1" == "--print" ]; then
        printTagsInDestDir
    elif [ "$1" == "--names" ]; then
        printFileNamesInDestDir
    elif [ "$1" == "--help" ]; then
        printHelpMessage
    else
        echo "Wrong arguments given. Exitting..."
    fi
else
    echo "Please add an argument. Exitting..."
fi
