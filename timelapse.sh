#!/bin/bash

FFMPG_BIN='/Users/adriel/Downloads/TimeLapse-Creater-master/ffmpeg'

# Directory input (no trailing slash needed)
INPUT_DIR=$1

# Quality of output (hd480,hd720,hd1080)
QUALITY=$2
FPS=$3

if [[ -z $QUALITY ]]; then
	QUALITY='hd720'
fi
if [[ -z $FPS ]]; then
	FPS='25'
fi
# Temp dir (trailing slash inluded in $TMPDIR)
TMP_DIR=$TMPDIR'timelapse_tmp'
# Need to delete the old timelapse folder from another combine
rm -r $TMP_DIR

if [[ -d "$INPUT_DIR" ]]; then

	# Create tmp dir with links
	mkdir "$TMP_DIR"
	echo 'Temp dir: '$TMP_DIR
	if [[ -d "$TMP_DIR" ]]; then
		IMAGES=$(find "$INPUT_DIR" -maxdepth 1  -iname "*.jpg" -type f -exec echo {} \;)
		# IMAGES=$(find "$INPUT_DIR" -maxdepth 1  -iname "*.jpg" -type f -exec echo {} \;)
		# find "$INPUT_DIR" -maxdepth 1 -iname "*.jpg" -type f -exec FNAME=$(basename {}) \; -exec ln -s {} "$TMP_DIR/$FNAME" \;
		# find "$INPUT_DIR" -maxdepth 1 -iname "*.jpg" -type f -exec FNAME=$(basename {}) \; -exec ln -s {} "$TMP_DIR/$FNAME" \;
		# echo $IMAGES
		# find -iname "*.$fileFormate" | grep -v -i "sample" | sort | while read file; do echo 'hi'; done
		while read -r FILE; do
		    # echo "... $line ..."
			((COUNT++))
			COUNT_FILL=$(printf "%04d" $COUNT) # Change to auto detect how long the no. should be
			FILE_EXT=$(echo $FILE | grep -E '\.([^\.]+)$' -o)
			# echo $COUNT_FILL
			# FNAME=$(basename "$FILE")
			ln -s "$FILE" "$TMP_DIR/${COUNT_FILL}${FILE_EXT}"
		done <<< "$IMAGES"

		echo 'Combine imgs '$FILE_EXT
		# Create video
		$FFMPG_BIN -i "$TMP_DIR/%04d$FILE_EXT" -r $FPS -s $QUALITY -vcodec libx264  -pix_fmt yuv420p -threads 0 "$INPUT_DIR"/timelapse1.mp4

	else
		echo 'Temp dir could not be found'
	fi

else
	echo 'Folder not found.'
fi
