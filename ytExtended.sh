#!/usr/bin/env sh

source header.sh; declareUserPaths
checkInstallPackage id3v2 p7zip-full

if ! (return 2>/dev/null); then
    function __init__ {
        readonly downloadsDestDirPath="$downloadsDir/yt-dlp"
        readonly ytdlpPrintOutputFilePath="$downloadsDir/yt-dlpOutput.txt"
        readonly ytdlpDownloadNamesFilePath="$downloadsDir/yt-dlpDownloadNames.txt"
        readonly ytdlpDownloadTempRenamesFilePath="$downloadsDir/yt-dlpDownloadRenames.txt"
        readonly ytdlpSongNamesFilePath="$downloadsDir/yt-dlpSongNames.txt"
        readonly ytdlpExtractAudioLineStart="[ExtractAudio] Destination: $downloadsDestDirPath/"
        readonly ytdlpExtractAudioLineStartGREP="\[ExtractAudio\] Destination:"
        readonly ytdlpExtractAudioLineStartLength=${#ytdlpExtractAudioLineStart}
        readonly ytdlpSplitChaptersLineStartTemplate="[SplitChapters] Chapter 000; Destination: $downloadsDestDirPath/"
        readonly ytdlpSplitChaptersLineStartTemplateGREP="\[SplitChapters\] Chapter (.*[0-9]); Destination:"
        readonly ytdlpSplitChaptersLineStartTemplateLength=${#ytdlpSplitChaptersLineStartTemplate}
        readonly playlistUrlBegining="https://www.youtube.com/playlist"
        readonly videoUrlBegining="https://www.youtube.com/watch"
        authorName=""
        albumName=""
        releaseYear=""
    }
    function __args__ {
        local i=1
        for ((; i<($#+1); i++)); do
            local arg="${!i}"
            if [[ "$arg" == "--edit" ]]; then
                checkNeededFilesAndDirs
                echo "$i --edit"
                return 0
            elif [[ "$arg" == "--clean" ]]; then
                echo "$i --clean"
                return 0
            elif [[ "$arg" == "--print" ]]; then
                checkNeededFilesAndDirs
                echo "$i --print"
                return 0
            elif [[ "$arg" == "--names" ]]; then
                checkNeededFilesAndDirs
                echo "$i --names"
                return 0
            elif [[ "$arg" == "--help" ]]; then
                echo "$i --help"
                return 0
            elif [[ "$arg" == "--cut" ]]; then
                local nextArgIndex=$(($i+1))
                local link="${!nextArgIndex}"
                local youtubeVideoLinkCheckVar=${link:0:${#videoUrlBegining}}
                failCond "[[ $youtubeVideoLinkCheckVar != $videoUrlBegining ]]" \
                         "Please provide correct link for a youtube video for a download under --cut option!"
                echo "$i --cut"
                return 0
            else
                local youtubePlaylistLinkCheckVar=${arg:0:${#playlistUrlBegining}}
                local youtubeVideoLinkCheckVar=${arg:0:${#videoUrlBegining}}
                if [ $youtubePlaylistLinkCheckVar == $playlistUrlBegining ] || \
                       [ $youtubeVideoLinkCheckVar == $videoUrlBegining ]; then
                    echo "$i __youtubeDownloadLink"
                    return 0
                fi
            fi
        done
        failCond "true" "Wrong arguments given."
    }
    function checkNeededFilesAndDirs {
        failCond "[[ ! -d $downloadsDestDirPath ]] \
|| [[ ! -f $ytdlpPrintOutputFilePath ]] \
|| [[ ! -f $ytdlpDownloadNamesFilePath ]] \
|| [[ ! -f $ytdlpSongNamesFilePath ]]" \
                 "Can not find needed files and the directory!"
    }
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
            local songName=$(sed "${i}q;d" "$ytdlpSongNamesFilePath")
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
        # TODO Add actual compression to the thing
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
            if [ "$ans" == "y" ]; then
                break
            elif [ "$ans" == "n" ]; then
                wronglyNamesSongsMessagePrint
                exit 0
            else
                echo "Please enter a valid option! (y/n)"
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
        #archiveDownloads
        printLongAssLine
    }
    function downloadYoutubeAlbumDestructor(){
        echo "Cleaning up temp files and folders."
        rmSilently "$ytdlpPrintOutputFilePath"
        rmSilently "$ytdlpDownloadNamesFilePath"
        rmSilently "$ytdlpSongNamesFilePath"
        for file in "$downloadsDestDirPath/"*; do
            rmSilently "$file"
        done
        rmdirSilently "$downloadsDestDirPath"
    }
    function downloadYoutubeAlbumConstructor(){
        echo "Creating/Overriding empty temp files and folders: "
        mkdirSilently "$downloadsDestDirPath"
        printf "" > "$ytdlpPrintOutputFilePath"
        printf "" > "$ytdlpDownloadNamesFilePath"
        printf "" > "$ytdlpSongNamesFilePath"
    }
    function printHelpMessage {
        printf "\nOptions:"
        printf "\n\t[Youtube Playlist Link] \tDownloads youtube playlist through \
yt-dlp in mp3 format, proceeds to rename downloads' ID3v2 tags on inputted \
metadata by the user, [DEPRICATED] archives downloaded music into .7z file.\n"
        printf "\n\t--edit \tRenames ID3v2 tags for the files placed in $downloadsDestDirPath, \
[DEPRICATED] archives output into .7z file.\n"
        printf "\n\t--clean \tDeletes all files produced by the script.\n"
        printf "\n\t--print \tPrints all ID3v2 tags of .mp3 files placed in $downloadsDestDirPath.\n"
        printf "\n\t--names \tPrints all file names of .mp3 files placed in $downloadsDestDirPath.\n"
        printf "\n\t--help  \tPrints this message\n"
        printf "\n"
    }
    function __main__ {
        __init__
        local argsAns=$(__args__ "$@")
        local optionArgIndex="$(echo "$argsAns" | grep -o '^[^ ]*' | tr -d ' ')"
        local optionArgName="$(echo "$argsAns" | grep -o ' .*' | tr -d ' ')"
        case "$optionArgName" in
            "__youtubeDownloadLink") 
                local link="${!optionArgIndex}"
                downloadYoutubeAlbumDestructor
                downloadYoutubeAlbumConstructor
                yt-dlp -t mp3 "$link" -P "$downloadsDestDirPath" | tee "$ytdlpPrintOutputFilePath"
                local line=""
                while read -r line; do
                    echo "${line:$ytdlpExtractAudioLineStartLength}" >> "$ytdlpDownloadNamesFilePath"
                done < <(grep -P "$ytdlpExtractAudioLineStartGREP" "$ytdlpPrintOutputFilePath")
                printf "\nListing downloaded song names:\n"
                printLongAssLine
                while read -r line; do
                    local songName=$(echo "$line" | sed 's/[[][^]]*]//')
                    local songName=${songName:0:-5}
                    echo $songName
                    echo $songName >> "$ytdlpSongNamesFilePath"
                done <"$ytdlpDownloadNamesFilePath"
                taggingBusiness
                ;;
            "--cut")
                local nextArgIndex=$(($optionArgIndex+1))
                local link="${!nextArgIndex}"
                downloadYoutubeAlbumDestructor
                downloadYoutubeAlbumConstructor
                yt-dlp --split-chapters -o "%(title).200B.%(ext)s" -o "chapter:%(section_title).200B.%(ext)s" \
                       -t mp3 "$link" -P "$downloadsDestDirPath" \
                    | tee "$ytdlpPrintOutputFilePath"
                local line=""
                while read -r line; do
                    echo "${line:$ytdlpSplitChaptersLineStartTemplateLength}" >> "$ytdlpDownloadNamesFilePath"
                done < <(grep -P "$ytdlpSplitChaptersLineStartTemplateGREP" "$ytdlpPrintOutputFilePath")
                printf "\nListing downloaded song names:\n"
                printLongAssLine
                while read -r line; do
                    local songName=$(echo "$line" | sed 's/[[][^]]*]//')
                    local songName=${songName:0:-5}
                    echo $songName
                    echo $songName >> "$ytdlpSongNamesFilePath"
                done <"$ytdlpDownloadNamesFilePath"
                taggingBusiness
                ;;
            "--edit")
                printf "\nListing downloaded song names:\n"
                printLongAssLine
                local line=""
                while read -r line; do
                    echo $line
                done <"$ytdlpSongNamesFilePath"
                taggingBusiness
                ;;
            "--clean")
                downloadYoutubeAlbumDestructor
                ;;
            "--print")
                printTagsInDestDir
                ;;
            "--names")
                printFileNamesInDestDir
                ;;
            "--help")
                printHelpMessage
                ;;
        esac
    }
    __main__ "$@"
fi
