#!/bin/bash
# (c)2016 Adriel Kloppenburg

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # get script dir of where the script is run from
FFMPG_BIN="${SCRIPT_DIR}/ffmpeg"

FILE_FORMATE='jpg'

# Directory input (no trailing slash needed)
INPUT_DIR=$1
# Quality of output (hd480,hd720,hd1080)
QUALITY=$2
FPS=$3

# Quality - set the height, e.g. 4k = 2160p, then auto select width for the image's aspect ratio
if [[ -z $QUALITY ]]; then
	QUALITY='hd1080'
fi
if [[ -z $FPS ]]; then
	FPS='48'
fi

# Not hugely random, but good enough for my purposes
RANDOM_NO=$(head -200 /dev/urandom | cksum | cut -c1-4)

# Temp dir (trailing slash inluded in $TMPDIR)
TL_TMP_DIR=$TMPDIR'timelapse_tmp'

# Delete the old timelapse folder if found
if [[ -d "$TL_TMP_DIR" ]]; then
	rm -r "$TL_TMP_DIR"
fi

if [[ -d "$INPUT_DIR" ]]; then

	# Create tmp dir with links
	mkdir "$TL_TMP_DIR"
	echo 'Temp dir: '$TL_TMP_DIR #debug

	if [[ -d "$TL_TMP_DIR" ]]; then

		# Search for jpg files ordered from oldest to newest (using a-z order sometimes fails due to incoret img numbering)
		IMAGES=$(find "$INPUT_DIR" -maxdepth 1  -iname "*.$FILE_FORMATE" -type f -print0 | xargs -0 ls -tr)
		# echo "$IMAGES"

		# Loop over images in correct order and create shortcuts in tmp folder
		while read -r FILE; do

			((COUNT++))
			COUNT_FILL=$(printf "%04d" $COUNT) # Change to auto detect how long the no. should be
			FILE_EXT=$(echo $FILE | grep -E '\.([^\.]+)$' -o)
			ln -s "$FILE" "${TL_TMP_DIR}/${COUNT_FILL}${FILE_EXT}"

		done <<< "$IMAGES"

		# Combine images into a video
		echo 'Combine .'$FILE_EXT' images'
		$FFMPG_BIN \
		-i "${TL_TMP_DIR}/%04d${FILE_EXT}" \
		-r $FPS \
		-c:v libx264 \
		-preset superfast \
		-crf 25 \
		-pix_fmt yuv420p \
		"${INPUT_DIR}/timelapse_${RANDOM_NO}.mp4"

		#
		# FFMPEG notes
		#
		# I can't seem to figure out how to make ffmpeg use 100% of my CPU when encoding to speed up the process, 
		# seems to stick around 30%... more info below
		#
		# Leave -s (size) out, and it should use the source's size
		# Preset, using 'superfast' results in using about 20% of the CPU,
		# whereas using 'fast' uses 98%, however the "speed" goes from 0.34x to 0.22x (superfast -> fast...)
		#
		# Rendered video is turning out slightly lighter then the photo (pix_fmt yuvj444p seems to output a sharper and same color as source)
		# However once it's up on youtube you can't tell the diff.
		#
		# CRF: The range of the quantizer scale is 0-51: where 0 is lossless, 23 is default, and 51 is worst possible
		# for a list of preset speeds: https://trac.ffmpeg.org/wiki/EncodingForStreamingSites

	else
		echo 'Temp dir could not be found'
	fi

else
	echo 'Folder not found.'
fi
