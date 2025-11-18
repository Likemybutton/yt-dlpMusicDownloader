#!/usr/bin/env sh

userDirName=$(whoami)
downloadsDir="/home/$userDirName/Downloads"
downloadsDestDirPath="$downloadsDir/yt-dlp"

ytdlpExtractAudioLineStart="[ExtractAudio] Destination: $downloadsDestDirPath/"
ytdlpExtractAudioLineStartLength=${#ytdlpExtractAudioLineStart}

ytdlpPrintOutputFilePath="$downloadsDir/yt-dlpOutput.txt"
ytdlpDownloadNamesFilePath="$downloadsDir/yt-dlpDownloadNames.txt"
ytdlpDownloadTempRenamesFilePath="$downloadsDir/yt-dlpDownloadRenames.txt"
ytdlpSongNamesFilePath="$downloadsDir/yt-dlpSongNames.txt"


authorName=""
albumName=""
releaseYear=""

if [ $# -eq 1 ]; then
    arg="$1"
    youtubePlaylistLinkStart="https://www.youtube.com/playlist"
    userYoutubeLinkStart=${arg:0:${#youtubePlaylistLinkStart}}
    if [ $userYoutubeLinkStart == $youtubePlaylistLinkStart ]; then

        for file in "$downloadsDestDirPath/"*; do
            rm "$file"
        done
        printf "" > "$ytdlpPrintOutputFilePath"
        printf "" > "$ytdlpDownloadNamesFilePath"
        printf "" > "$ytdlpSongNamesFilePath"

        yt-dlp -t mp3 "$arg" -P "$downloadsDestDirPath" | tee "$ytdlpPrintOutputFilePath"
        while read -r line; do
            echo "${line:$ytdlpExtractAudioLineStartLength}" >> "$ytdlpDownloadNamesFilePath"
        done < <(grep "\[ExtractAudio\]" "$ytdlpPrintOutputFilePath")
        cp "$ytdlpDownloadNamesFilePath" "$ytdlpSongNamesFilePath"

    elif [ "$1" == "--edit" ]; then

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
        
        printf "" > "$ytdlpDownloadTempRenamesFilePath"
        i=1
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
        
    fi
fi
