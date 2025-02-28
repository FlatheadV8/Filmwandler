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
#VERSION="v2023010700"			# TAG:language
#VERSION="v2024070900"			# jetzt funktioniert auch ${0} title_t*.mkv
VERSION="v2025022500"			# jetzt auch mit codec_name

AVERZ="$(dirname ${0})"			# Arbeitsverzeichnis, hier liegen diese Dateien
#META_DATEN_STREAMS="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${1}" -show_streams)"
#echo "${META_DATEN_STREAMS}" | grep -Ei 'width|height|aspect_ratio|frame_rate|level'

#==============================================================================#

#FILM_DATEI="${1}"
echo "| DATEI-GROESSE | Filmlänge          | BreitxHoch | Ton-Spur-Name | Ton-Spur-Sprache | Untertitel-Spur-Name | Untertitel-Spur-Sprache | Codec-Name | Film-Datei-Name"
for FILM_DATEI in ${@}
do
	if [ -r "${FILM_DATEI}" ] ; then
		DATEI_GROESSE="$(du -sm "${FILM_DATEI}" | awk '{print $1}')"
		#KOMPLETT_DURCHSUCHEN="-probesize 9223372036G -analyzeduration 9223372036G"
		KOMPLETT_DURCHSUCHEN="-probesize 1G -analyzeduration 1G"

		FILM_SCANNEN()
		{
			FILMDATEI="${1}"

			META_DATEN_STREAMS="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_streams 2>&1)"
			echo "${META_DATEN_STREAMS}" > /tmp/Filmwandler_metadaten_anzeigen.txt
			META_DATEN_ZEILENWEISE_STREAMS="$(echo "${META_DATEN_STREAMS}" | tr -s '\r' '\n' | tr -s '\n' ';' | sed 's/;\[STREAM\]/³[STREAM]/g' | tr -s '³' '\n')"
			DURATION="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^TAG:DURATION/{print $2}' | grep -Fv 'N/A' | head -n1)"

			if [ "x${DURATION}" != x ] ; then
				CODEC_LONG_NAME="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^codec_long_name=/{print $2}' | grep -Fv 'N/A' | head -n1)"
				META_DATEN_SPURSPRACHEN="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -E 'TAG:language=' | while read Z ; do echo "${Z}" | tr -s ';' '\n' | awk -F'=' '/^index=|^codec_type=|^TAG:language=/{print $2}' | tr -s '\n' ' ' ; echo ; done)"

				TSNAME="$(echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=audio' | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
				TON_LANG="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | tr -s ';' '\n' | grep -F TAG:language | awk -F'=' '{print $2}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
				UTNAME="$(echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=subtitle' | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
				U_LANG="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=subtitle;' | tr -s ';' '\n' | grep -F TAG:language | awk -F'=' '{print $2}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
				CODEC_NAME="$(echo "${META_DATEN_STREAMS}" | grep -F 'codec_name=' | awk -F'=' '{print $2}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
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

		#----------------------------------------------------------------------------#

		unset TSNAME
		unset TON_LANG
		unset UTNAME
		unset U_LANG
		unset CODEC_NAME
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

		#----------------------------------------------------------------------------#

		#echo "# DATEI-GROESSE | Filmlänge | BreitxHoch | Ton-Spur-Name | Ton-Spur-Sprache | Untertitel-Spur-Name | Untertitel-Spur-Sprache | Film-Datei-Name"
		#echo "${DATEI_GROESSE} | ${DURATION} | ${IN_BREIT}x${IN_HOCH} | ${TSNAME} | ${TON_LANG} | ${UTNAME} | ${U_LANG} | ${FILM_DATEI}"
		#
		#echo -e "# DATEI-GROESSE\t| Filmlänge\t| BreitxHoch\t| Ton-Spur-Name\t| Ton-Spur-Sprache\t| Untertitel-Spur-Name\t| Untertitel-Spur-Sprache\t| Codec-Name\t| Film-Datei-Name"
		#echo -e "${DATEI_GROESSE}\t| ${DURATION}\t| ${IN_BREIT}x${IN_HOCH}\t| ${TSNAME}\t| ${TON_LANG}\t| ${UTNAME}\t| ${U_LANG}\t| ${CODEC_NAME}\t| ${FILM_DATEI}"

		C01="$(echo "${DATEI_GROESSE}" | awk '{printf ("%14s\n", $1)}')"	# 14
		C02="$(echo "${DURATION}" | awk '{printf ("%16s\n", $1)}')"		# 16
		C03="$(echo "${IN_BREIT}x${IN_HOCH}" | awk '{printf ("%10s\n", $1)}')"	# 10
		C04="$(echo "${TSNAME}" | awk '{printf ("%13s\n", $1)}')"		# 13
		C05="$(echo "${TON_LANG}" | awk '{printf ("%16s\n", $1)}')"		# 16
		C06="$(echo "${UTNAME}" | awk '{printf ("%20s\n", $1)}')"		# 20
		C07="$(echo "${U_LANG}" | awk '{printf ("%23s\n", $1)}')"		# 23
		C08="$(echo "${CODEC_NAME}" | awk '{printf ("%10s\n", $1)}')"		# 10
		C09="$(echo "${FILM_DATEI}" | awk '{printf ("%16s\n", $1)}')"		# 16

		echo " ${C01} | ${C02} | ${C03} | ${C04} | ${C05} | ${C06} | ${C07} | ${C08} | ${FILM_DATEI}"
	fi
done

