#!/bin/sh

#------------------------------------------------------------------------------#
#
# https://ffmpeg.org/ffprobe.html#Main-options
#
#------------------------------------------------------------------------------#
# ffprobe -v error -select_streams v:0 -show_entries stream=width,height,duration,bit_rate -of default=noprint_wrappers=1 input.mp4
# siehe auch Filmwandler_ffprobe-show_streams.sh
#------------------------------------------------------------------------------#

#VERSION="v2022072800"			# Version 1
#VERSION="v2022122600"			# Version 2
#VERSION="v2023010200"			# Version 3, weil die Version 2 rekursiver Aufrufe erzeugte, wenn das Ziel nicht gefunden wurde
#VERSION="v2023010500"			# leider braucht der jedesmal ein weiteres ENTER und ggf. auch noch einen 2. Aufruf
#VERSION="v2023010700"			# Ungenauigkeit bei TAG:DURATION behoben
VERSION="v2023010700"			# TAG:language

AVERZ="$(dirname ${0})"			# Arbeitsverzeichnis, hier liegen diese Dateien
#META_DATEN_STREAMS="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${1}" -show_streams)"
#echo "${META_DATEN_STREAMS}" | grep -Ei 'width|height|aspect_ratio|frame_rate|level'

#==============================================================================#
### Version 1

#TITEL="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries format_tags=title -of compact=p=0:nk=1)"
#KOMMENTAR="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries format_tags=comment -of compact=p=0:nk=1)"
#BESCHREIBUNG="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries format_tags=description -of compact=p=0:nk=1)"
##TITEL_KOMMENTAR="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries format_tags=title,comment -of compact=p=0:nk=1)"
#ID_SPRACHE_AUDIO_SPUREN="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries stream=index:stream_tags=language -select_streams a -of compact=p=0:nk=1)"
#ID_SPRACHE_UNTERTITEL_SPUREN="$(ffprobe -v error -probesize 9223372036G -analyzeduration 9223372036G -i "${1}" -show_entries stream=index:stream_tags=language -select_streams s -of compact=p=0:nk=1)"

#echo "
# TITEL='${TITEL}'
#
# KOMMENTAR='${KOMMENTAR}'
#
# BESCHREIBUNG='${BESCHREIBUNG}'
#
# ID_SPRACHE_AUDIO_SPUREN='${ID_SPRACHE_AUDIO_SPUREN}'
#
# ID_SPRACHE_UNTERTITEL_SPUREN='${ID_SPRACHE_UNTERTITEL_SPUREN}'
#"

#==============================================================================#
### Version 2
### Version 3

FILM_DATEI="${1}"
if [ -r "${FILM_DATEI}" ] ; then
  DATEI_GROESSE="$(du -sm "${FILM_DATEI}" | awk '{print $1}')"
  #KOMPLETT_DURCHSUCHEN="-probesize 9223372036G -analyzeduration 9223372036G"
  KOMPLETT_DURCHSUCHEN="-probesize 1G -analyzeduration 1G"

  FILM_SCANNEN()
  {
    FILMDATEI="${1}"

    META_DATEN_STREAMS="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_streams 2>&1)"
    META_DATEN_ZEILENWEISE_STREAMS="$(echo "${META_DATEN_STREAMS}" | tr -s '\r' '\n' | tr -s '\n' ';' | sed 's/;\[STREAM\]/³[STREAM]/g' | tr -s '³' '\n')"
    DURATION="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^TAG:DURATION/{print $2}' | grep -Fv 'N/A' | head -n1)"

    if [ "x${DURATION}" != x ] ; then
	CODEC_LONG_NAME="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^codec_long_name=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	META_DATEN_SPURSPRACHEN="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -E 'TAG:language=' | while read Z ; do echo "${Z}" | tr -s ';' '\n' | awk -F'=' '/^index=|^codec_type=|^TAG:language=/{print $2}' | tr -s '\n' ' ' ; echo ; done)"
	#TSNAME="$(echo "${META_DATEN_STREAMS}" | grep -F codec_type=audio | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
	#TON_LANG="$(echo "${META_DATEN_STREAMS}" | grep -F codec_type=audio | grep -F TAG:language | awk -F'=' '{print $2}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
	#UTNAME="$(echo "${META_DATEN_STREAMS}" | grep -F codec_type=subtitle | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
	#U_LANG="$(echo "${META_DATEN_STREAMS}" | grep -F codec_type=subtitle | grep -F TAG:language | awk -F'=' '{print $2}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
	#BILD_DREHUNG="$(echo "${META_DATEN_STREAMS}" | sed -ne '/index=0/,/index=1/p' | awk -F'=' '/TAG:rotate=/{print $NF}' | head -n1)"	# TAG:rotate=180 -=> 180
	#FPS_TEILE="$(echo "${META_DATEN_STREAMS}" | grep -E '^codec_type=|^r_frame_rate=' | grep -E -A1 '^codec_type=video' | awk -F'=' '/^r_frame_rate=/{print $2}' | sed 's|/| |')"
	#IN_FPS="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^avg_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1}')"
	#SCAN_TYPE="$(echo "${META_DATEN_STREAMS}" | awk -F'=' '/^field_order=/{print $2}' | grep -Ev '^$' | head -n1)"
	#LEVEL="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^level=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	#IN_BREIT="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^width=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	#IN_HOCH="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^height=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	#IN_BREIT_CODED="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^coded_width=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	#IN_HOCH_CODED="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^coded_height=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	#IN_PAR="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^sample_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	#IN_DAR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^display_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"

	TSNAME="$(echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=audio' | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
	TON_LANG="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | tr -s ';' '\n' | grep -F TAG:language | awk -F'=' '{print $2}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
	UTNAME="$(echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=subtitle' | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
	U_LANG="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=subtitle;' | tr -s ';' '\n' | grep -F TAG:language | awk -F'=' '{print $2}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
	BILD_DREHUNG="$(echo "${META_DATEN_STREAMS}" | sed -ne '/index=0/,/index=1/p' | awk -F'=' '/TAG:rotate=/{print $NF}' | head -n1)"	# TAG:rotate=180 -=> 180
	FPS_TEILE="$(echo "${META_DATEN_STREAMS}" | grep -E '^codec_type=|^r_frame_rate=' | grep -E -A1 '^codec_type=video' | awk -F'=' '/^r_frame_rate=/{print $2}' | sed 's|/| |')"
	IN_FPS="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^avg_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1}')"
	SCAN_TYPE="$(echo "${META_DATEN_STREAMS}" | awk -F'=' '/^field_order=/{print $2}' | grep -Ev '^$' | head -n1)"
	LEVEL="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^level=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	IN_BREIT="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^width=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	IN_HOCH="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^height=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	IN_BREIT_CODED="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^coded_width=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	IN_HOCH_CODED="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^coded_height=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	IN_PAR="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^sample_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
	IN_DAR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^display_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
    fi
  }

  echo "# 1
  # FILM_DATEI='${FILM_DATEI}'
  "

  #----------------------------------------------------------------------------#

  unset TSNAME
  unset TON_LANG
  unset UTNAME
  unset U_LANG
  unset BILD_DREHUNG
  unset FPS_TEILE
  unset IN_FPS
  unset SCAN_TYPE
  unset LEVEL
  unset IN_BREIT
  unset IN_HOCH
  unset IN_BREIT_CODED
  unset IN_HOCH_CODED
  unset IN_PAR
  unset IN_DAR

  FILM_SCANNEN "${FILM_DATEI}"
  if [ "x${DURATION}" = x ] ; then
	${AVERZ}/Filmwandler_zu_MKV-Kontainer.sh -q "${FILM_DATEI}" -z MKV-Testdatei.mkv >/dev/null 2>/dev/null
	FILM_SCANNEN MKV-Testdatei.mkv
	rm -f MKV-Testdatei.mkv MKV-Testdatei.mkv.txt
  fi

  #echo "# 2
  # FILMDATEI='${FILMDATEI}'
  #
  # FILM_DATEI='${FILM_DATEI}'
  #
  # TITEL='${TITEL}'
  #
  # KOMMENTAR='${KOMMENTAR}'
  #
  # BESCHREIBUNG='${BESCHREIBUNG}'
  #
  # ID_SPRACHE_AUDIO_SPUREN='${ID_SPRACHE_AUDIO_SPUREN}'
  #
  # ID_SPRACHE_UNTERTITEL_SPUREN='${ID_SPRACHE_UNTERTITEL_SPUREN}'
  #"

  #----------------------------------------------------------------------------#

  echo "# DATEI-GROESSE | Filmlänge | BreitxHoch | Ton-Spur-Name | Ton-Spur-Sprache | Untertitel-Spur-Name | Untertitel-Spur-Sprache | Film-Datei-Name"
  echo "${DATEI_GROESSE} | ${DURATION} | ${IN_BREIT}x${IN_HOCH} | ${TSNAME} | ${TON_LANG} | ${UTNAME} | ${U_LANG} | ${FILM_DATEI}"

  echo "# 3
  # DATEI_GROESSE='${DATEI_GROESSE}'
  # CODEC_LONG_NAME='${CODEC_LONG_NAME}'
  # IN_XY='${IN_BREIT}x${IN_HOCH}'
  # IN_XY_CODED='${IN_BREIT_CODED}x${IN_HOCH_CODED}'
  # TSNAME='${TSNAME}'
  # UTNAME='${UTNAME}'
  # META_DATEN_SPURSPRACHEN='${META_DATEN_SPURSPRACHEN}'
  # BILD_DREHUNG='${BILD_DREHUNG}'
  # FPS_TEILE='${FPS_TEILE}'
  # IN_FPS='${IN_FPS}'
  # SCAN_TYPE='${SCAN_TYPE}'
  # LEVEL='${LEVEL}'
  # IN_PAR='${IN_PAR}'
  # IN_DAR='${IN_DAR}'
  # DURATION='${DURATION}'
  "
#else
#  echo "Der Film '${FILM_DATEI}' konnte nicht gelesen werden."
fi

