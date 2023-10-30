#!/bin/sh
#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Wenn im Film Untertitel keine Untertitel oder Untertitel in einem Textformat
# vorhanden sind, dann wird das WebM-Container-Format verwendet,
# sonst das MKV-Container-Format.
#
# Es werden folgende Programme bzw. Skripte verwendet:
#  - /${AVERZ}/Filmwandler*.sh
#  - ffmpeg
#  - ffprobe
#
#------------------------------------------------------------------------------#


#VERSION="v2019092500"
#VERSION="v2019101600"
#VERSION="v2019102900"
#VERSION="v2019110100"
#VERSION="v2020101800"
#VERSION="v2020102600"		# jetzt funktionieren auch Titel mit Leerzeichen
#VERSION="v2020091500"		# jetzt kann auch ein Kommentar mit übergeben werden
#VERSION="v2022072600"		# um die Kompatibilität der MP4 zu erhöhen, wurde der Parameter '-stereo' hinzugefügt, jetzt werden auch Filme mit großer Audio-Bit-Rate auf einfachen Media-Playern abgespielt
#VERSION="v2022080800"		# um die Kompatibilität der MP4 zu erhöhen, wurde der Parameter '-minihd' (das beinhaltet auch, dass nur die erste Tonspur im Film landet) hinzugefügt, jetzt sollten die MP4-Filme (fast) überall laufen :-) 
#VERSION="v2022081300"		# Kommentare erweitert
#VERSION="v2022100900"		# wenn keine Untertitel vorhanden sind, dann soll nur noch WEBM gebaut werden
#VERSION="v2022101500"		# wenn Untertitel vorhanden sind, dann soll WEBM mit abgeschalteten Untertiteln und MKV mit Untertitel gebaut werden
#VERSION="v2022110300"		# -standard_ton 0 -standard_u 0
#VERSION="v2022112900"		# meine MP4-Filme sind alle HLS-kompatibel, da das nun ausreichend ist, wurde der Parameter '-minihd' entfernt; der Kompatibilitäts-Standard "HD ready" schränkt zu stark ein, weil er die Auflösung und die Bit-Rate begrenzt
#VERSION="v2022120200"		# wenn keine Untertitel im Quell-Film enthalten sind, dann wird nur in ein sehr kompatibles Fotmat (HD ready, HTML5 oder HLS) transkodiert => von WebM auf MP4 umgestellt
#VERSION="v2022120400"		# MKV -> WebM - Konverter, der die Untertitel entfernt, damit der WebM-Film überall abgespielt werden kann
#VERSION="v2022120500"		# MKV + MP4 für HTML5- und HLS-Kompatibilität
#VERSION="v2022120600"		# + HLS-Kompatibilitäts-Option
#VERSION="v2022120700"		# den alternativen Zweig (für den Fall, dass keine UUntertitel vorhanden sind) abgeschaltet, weil dort WebM mit AV1 zum Einsatz kommt, was z.Z. noch viel zu langsam ist
#VERSION="v2022120700"		# Fehler in der MP4-Erstellung behoben
#VERSION="v2022122200"		# Fehler in der MP4-Erstellung behoben
#VERSION="v2023051900"		# optimiert für /bin/sh
#VERSION="v2023100900"		# WebM favorisieren und MKV als Alternative, wenn es im Quell-Film Untertitel im nicht-Text-Format gibt
VERSION="v2023103000"		# "mov_text" ist auch ein Untertitel-Format im Text-Format


ALLE_OPTIONEN="${@}"

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

STOP="Nein"

AVERZ="$(dirname ${0})"				# Arbeitsverzeichnis, hier liegen diese Dateien

#==============================================================================#
if [ x = "x${1}" ] ; then
	echo "${0} OPTIONEN"
	echo "siehe: ${AVERZ}/Filmwandler.sh -h"
	echo "${0} -q [Quelle] -z [Ziel]"
	echo "${0} -q Film.avi -z Film"
	exit 1
fi
#==============================================================================#

while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -q)
                        FILMDATEI="${2}"	# Name für die Quelldatei
                        shift
                        shift
                        ;;
                -z)
                        ZIELPFAD="${2}"		# Name für die Zieldatei
                        shift
                        shift
                        ;;
                -titel)
                        TITEL="${2}"		# Name für die Zieldatei
                        shift
                        shift
                        ;;
                -k)
                        KOMMENTAR="${2}"	# Kommentar zum Film
                        shift
                        shift
                        ;;
                *)
                        printf .
			SONSTIGE_OPTIONEN="${SONSTIGE_OPTIONEN} ${1}"
                        shift
                        ;;
        esac
done

#------------------------------------------------------------------------------#
# damit die Endung austauschbar wird

ZIELVERZ="$(dirname "${ZIELPFAD}")"
ZIELDATEI="$(basename "${ZIELPFAD}")"

ZIELNAME="$(echo "${ZIELDATEI}" | rev | sed 's/[ ][ ]*/_/g;s/.*[.]//' | rev)"

#echo "
#ZIELVERZ='${ZIELVERZ}'
#ZIELDATEI='${ZIELDATEI}'
#ZIELNAME='${ZIELNAME}'
#"

#------------------------------------------------------------------------------#
### Schnitt

if [ "x${SCHNITTZEITEN}" != x ] ; then
	SCHNITT_OPTION="-schnitt \"${SCHNITTZEITEN}\""
fi

echo "
ALLE_OPTIONEN='${ALLE_OPTIONEN}'
SONSTIGE_OPTIONEN='${SONSTIGE_OPTIONEN}'
SCHNITTZEITEN='${SCHNITTZEITEN}'
SCHNITT_OPTION='${SCHNITT_OPTION}'
"
#exit 

#------------------------------------------------------------------------------#

#set -x

#==============================================================================#
# hier wird geprüft, ob im Film kein Untertitel vorhanden sind

FFPROBE_PROBESIZE="9223372036854"       	# Maximalwert in MiB auf einem Intel(R) Core(TM) i5-10600T CPU @ 2.40GHz
KOMPLETT_DURCHSUCHEN="-probesize ${FFPROBE_PROBESIZE} -analyzeduration ${FFPROBE_PROBESIZE}"
FFPROBE_SHOW_DATA="$(ffprobe ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_data 2>&1)"

#exit
#==============================================================================#
# Die Frage lautet: "Sind Untertitel vorhanden?".

UNTERTITEL_SPUREN="$(echo "${FFPROBE_SHOW_DATA}" | grep -F 'Stream #' | grep -Fi ' Subtitle:' | wc -l | awk '{print $1}' | head -n1)"

ENDUNG="webm"
if [ 0 -lt "${UNTERTITEL_SPUREN}" ] ; then
	UNTER_CODEC="$(echo "${FFPROBE_SHOW_DATA}" | grep -Fi ' Subtitle: ' | sed 's/^.* Subtitle: //;s/,.*$//' | awk '{print $1}' | sort | uniq | head -n1)"

	# WebVTT ist eine Weiterentwicklung von SRT
	UNTERTITEL_TEXT_CODEC="$(echo "${UNTER_CODEC}" | grep -Ei 'SRT|VTT|SSA|ASS|SMIL|TTML|DFXP|SBV|irc|cap|SCC|itt|DFXP|mov_text')"
	if [ x = "x${UNTERTITEL_TEXT_CODEC}" ] ; then
		ENDUNG="mkv"
	fi

	echo "# 2: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -standard_ton 0 -standard_u 0"
	${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -standard_ton 0 -standard_u 0
else
	echo "# 1: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -standard_ton 0 -u =0"
	${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -standard_ton 0 -u =0
fi

#==============================================================================#

