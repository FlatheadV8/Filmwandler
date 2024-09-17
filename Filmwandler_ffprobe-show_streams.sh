#!/bin/sh

#set -x
#------------------------------------------------------------------------------#
#
# https://ffmpeg.org/ffprobe.html#Main-options
#
#------------------------------------------------------------------------------#
# ffprobe -v error -select_streams v:0 -show_entries stream=width,height,duration,bit_rate -of default=noprint_wrappers=1 input.mp4
# siehe auch Filmwandler_metadaten_anzeigen.sh
#------------------------------------------------------------------------------#

VERSION="v2023051300"			# erstellt

AVERZ="$(dirname ${0})"			# Arbeitsverzeichnis, hier liegen diese Dateien

#==============================================================================#
hilfeausgabe()
{
	echo
	echo "alles ausgeben:"
	echo "${0} -d [Filmdatei]"
	echo "${0} -d Film.mkv"
	echo
	echo "nur die Video-Infos ausgeben:"
	echo "${0} -v -d [Filmdatei]"
	echo
	echo "nur die Audio-Infos ausgeben:"
	echo "${0} -a -d [Filmdatei]"
	echo
	echo "nur die Untertitel-Infos ausgeben:"
	echo "${0} -u -d [Filmdatei]"
	echo
	echo "nur die Meta-Daten ausgeben:"
	echo "${0} -m -d [Filmdatei]"
	echo
}
#==============================================================================#

ALLE_DATEN="Ja"
while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -d)
                        FILM_DATEI="${2}"				# nur die Video-Infos ausgeben
                        shift
                        ;;
                -v)
                        VIDEO_INFOS="video"				# nur die Video-Infos ausgeben
			ALLE_DATEN=""
                        shift
                        ;;
                -a)
                        AUDIO_INFOS="audio"				# nur die Audio-Infos ausgeben
			ALLE_DATEN=""
                        shift
                        ;;
                -u)
                        UNTERTITEL_INFOS="untertitel"			# nur die Untertitel-Infos ausgeben
			ALLE_DATEN=""
                        shift
                        ;;
                -m)
                        META_DATEN="metadaten"				# nur die Meta-Daten ausgeben
			ALLE_DATEN=""
                        shift
                        ;;
                *)
                        if [ "$(echo "${1}" | grep -E '^-')" ] ; then
                                echo "Der Parameter '${1}' wird nicht unterstützt!"
				hilfeausgabe
				exit 1
                        fi
                        shift
                        ;;
        esac
done

#------------------------------------------------------------------------------#
if [ -r "${FILM_DATEI}" ] ; then
	#KOMPLETT_DURCHSUCHEN="-probesize 9223372036G -analyzeduration 9223372036G"
	KOMPLETT_DURCHSUCHEN="-probesize 1G -analyzeduration 1G"

	META_DATEN_STREAMS="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILM_DATEI}" -show_streams 2>&1)"
	#echo "${META_DATEN_STREAMS}"

	#echo "${META_DATEN_STREAMS}" | grep -Ei 'width|height|aspect_ratio|frame_rate|level'

	META_DATEN_ZEILENWEISE_STREAMS="$(echo "${META_DATEN_STREAMS}" | tr -s '\r' '\n' | tr -s '\n' ';' | sed 's/;\[STREAM\]/³[STREAM]/g' | tr -s '³' '\n')"
	#echo "${META_DATEN_ZEILENWEISE_STREAMS}"
else
	hilfeausgabe
	exit 0
fi

#exit
#------------------------------------------------------------------------------#

(
if [ "video" = "${VIDEO_INFOS}" ] ; then
#	BILD_DREHUNG:
#		echo "${META_DATEN_STREAMS}" | sed -ne '/index=0/,/index=1/p' | awk -F'=' '/TAG:rotate=/{print $NF}' | head -n1
#	FPS_TEILE:
#		echo "${META_DATEN_STREAMS}" | grep -E '^codec_type=|^r_frame_rate=' | grep -E -A1 '^codec_type=video' | awk -F'=' '/^r_frame_rate=/{print $2}' | sed 's|/| |'
#	IN_FPS:
#		echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^avg_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1}'
#	SCAN_TYPE:
#		echo "${META_DATEN_STREAMS}" | awk -F'=' '/^field_order=/{print $2}' | grep -Ev '^$' | head -n1
#	LEVEL:
#		echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^level=/{print $2}' | grep -Fv 'N/A' | head -n1
#	IN_BREIT:
#		echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^width=/{print $2}' | grep -Fv 'N/A' | head -n1
#	IN_HOCH:
#		echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^height=/{print $2}' | grep -Fv 'N/A' | head -n1
#	IN_BREIT_CODED:
#		echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^coded_width=/{print $2}' | grep -Fv 'N/A' | head -n1
#	IN_HOCH_CODED:
#		echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^coded_height=/{print $2}' | grep -Fv 'N/A' | head -n1
#	IN_PAR:
#		echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^sample_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1
#	IN_DAR:
#		echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^display_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1

	echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n'
fi

if [ "audio" = "${AUDIO_INFOS}" ] ; then
#	TSNAME:
#		echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=audio' | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//'
#	TON_LANG
#		echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | tr -s ';' '\n' | grep -F TAG:language | awk -F'=' '{print $2}' | tr -s '\n' ',' | sed 's/^,//;s/,$//'

	echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | tr -s ';' '\n'
fi

if [ "untertitel" = "${UNTERTITEL_INFOS}" ] ; then
#	UTNAME:
#		echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=subtitle' | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//'
#	U_LANG:
#		echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=subtitle;' | tr -s ';' '\n' | grep -F TAG:language | awk -F'=' '{print $2}' | tr -s '\n' ',' | sed 's/^,//;s/,$//'

	echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=subtitle;' | tr -s ';' '\n'
fi

if [ "metadaten" = "${META_DATEN}" ] ; then
#	META:
#		echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=subtitle' | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//'

	echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -Ev ';codec_type=video;|;codec_type=audio;|;codec_type=subtitle;' | tr -s ';' '\n'
	ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_entries format_tags=title -of compact=p=0:nk=1
	ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_entries format_tags=comment -of compact=p=0:nk=1
	ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_entries format_tags=description -of compact=p=0:nk=1
fi

if [ "Ja" = "${ALLE_DATEN}" ] ; then
	echo "${META_DATEN_STREAMS}"
fi
) | sed 's/=/:\t/g;s/\[[/]*STREAM\]//'

#==============================================================================#

