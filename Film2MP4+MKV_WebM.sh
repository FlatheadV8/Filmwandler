#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Durch dieses Skript wird es möglich, mit einem einzigen Aufruf Filme in zwei
# Formate zu erzeugen: MP4 (das z.Z. kompatibelste) und eines von WebM oder MKV,
# WebM wenn das Ziel keine Untertitel beinhalten wird oder
# MKV wenn das Ziel Untertitel beinhalten wird.
#
# Das Skript erzeugt zwei neue Filme:
#  - MP4:     mp4    + H.264/AVC  + AAC
#    und
#  - WebM:    webm   + VP9        + Opus (ohne Untertitel)
#    oder
#  - MKV:     mkv    + VP9        + Opus (mit Untertitel)
#
# Weil WebM leider nur das eine Untertitelformat "WebVTT" unterstützt.
#
# Es werden folgende Programme bzw. Skripte verwendet:
#  - /${AVERZ}/Filmwandler*.sh
#  - ffmpeg
#  - ffprobe
#
#------------------------------------------------------------------------------#


#VERSION="v2019092500"
VERSION="v2019101200"


ALLE_OPTIONEN="${@}"

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

STOP="Nein"

AVERZ="$(dirname ${0})"			# Arbeitsverzeichnis, hier liegen diese Dateien

#==============================================================================#
if [ "x${1}" == x ] ; then
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
                -schnitt)
                        SCHNITTZEITEN="$(echo "${2}" | sed 's/"//g' | sed "s/'//g")"	# zum Beispiel zum Werbung entfernen (in Sekunden, Dezimaltrennzeichen ist der Punkt): -schnitt "10-432 520-833 1050-1280"
                        shift
                        shift
                        ;;
                -u)
                        # Wirddiese Option nicht verwendet, dann werden ALLE Untertitelspuren eingebettet
                        # "=0" für keinen Untertitel
                        # "0" für die erste Untertitelspur
                        # "1" für die zweite Untertitelspur
                        # "0,1" für die erste und die zweite Untertitelspur
                        UNTERTITEL="${2}"	# -u 0,1,2,3,4
                        shift
                        shift
                        ;;
                *)
                        echo -n .
			SONSTIGE_OPTIONEN="${SONSTIGE_OPTIONEN} ${1}"
                        shift
                        ;;
        esac
done


#==============================================================================#
# Wenn kein Untertitel angegeben wurde, dann werden alle vorhandenen genommen.
# Die Frage lautet: "Sind Untertitel vorhanden?".

SIND_UNTERTITEL_VORHANDEN="$(ffprobe -probesize 9223372036G -analyzeduration 9223372036G -i "${FILMDATEI}" 2>&1 | sed -ne '/^Input /,/STREAM/p' | fgrep ' Subtitle: ')"

#------------------------------------------------------------------------------#
### Endung anpassen

# dieses Format immer
ENDUNG_1="mp4"

# bevorzugtes freies Format, leider nur ohne Untertitel möglich
ENDUNG_2="webm"

### Untertitel
if [ "x${SIND_UNTERTITEL_VORHANDEN}" != x ] ; then
	if [ "${UNTERTITEL}" != "=0" ] ; then
		# alternatives freies Format, wenn Untertitel vorhanden sind und nicht abgewählt wurden
		ENDUNG_2="mkv"
	fi
fi


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
for _E in ${ENDUNG_1} ${ENDUNG_2}
do
	echo "${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${_E}\" ${SCHNITT_OPTION}"
	${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${_E}" ${SCHNITT_OPTION}
done

#------------------------------------------------------------------------------#
