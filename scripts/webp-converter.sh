#!/bin/bash

# example run: ./$(pwd)/server-base-setup/scripts/webp-converter.sh /home/user/server-base-setup/files/subdomain/wp-content/uploads 80 none > $HOME/logs/webp-converter-subdomain.log 2>&1 &
DIRECTORY="$1"
QUALITY="$2"
METADATA="$3"

# check if any argument is empty
if [ -z "$DIRECTORY" ] || [ -z "$QUALITY" ] || [ -z "$METADATA" ]; then
    echo "Error: Missing arguments. Please provide values for DIRECTORY, QUALITY, and METADATA."
    exit 1
fi

inotifywait -m -r -e create --format "%w%f" "$DIRECTORY" |
while read -r FILE
do
    FILETYPE=$(/usr/bin/file -b --mime-type "$FILE")

    if [[ $FILETYPE =~ ^image/(png|jpeg|jpg) || $FILETYPE =~ ^"inode/x-empty" ]]; then
        if [[ $FILETYPE =~ ^"inode/x-empty" ]]; then
            sleep 5
        fi

        PATH="${FILE//\/uploads\//\/uploads-webp\/}"

        /usr/bin/cwebp -q "$QUALITY" -metadata "$METADATA" "$FILE" -o "$PATH.webp"

        echo "converted $FILE to WebP"
    fi
done
