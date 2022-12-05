#!/bin/sh

#------------------------------------------------------------------------------#
#
# https://ffmpeg.org/ffprobe.html#Main-options
#
#------------------------------------------------------------------------------#
# ffprobe -v error -select_streams v:0 -show_entries stream=width,height,duration,bit_rate -of default=noprint_wrappers=1 input.mp4
#------------------------------------------------------------------------------#

META_DATEN_STREAMS="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${1}" -show_streams)"
echo "${META_DATEN_STREAMS}" | grep -Ei 'width|height|aspect_ratio|frame_rate|level'

#------------------------------------------------------------------------------#

TITEL="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries format_tags=title -of compact=p=0:nk=1)"

KOMMENTAR="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries format_tags=comment -of compact=p=0:nk=1)"

BESCHREIBUNG="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries format_tags=description -of compact=p=0:nk=1)"

#TITEL_KOMMENTAR="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries format_tags=title,comment -of compact=p=0:nk=1)"

ID_SPRACHE_AUDIO_SPUREN="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries stream=index:stream_tags=language -select_streams a -of compact=p=0:nk=1)"

echo "
TITEL='${TITEL}'

KOMMENTAR='${KOMMENTAR}'

BESCHREIBUNG='${BESCHREIBUNG}'

ID_SPRACHE_AUDIO_SPUREN='${ID_SPRACHE_AUDIO_SPUREN}'
"

