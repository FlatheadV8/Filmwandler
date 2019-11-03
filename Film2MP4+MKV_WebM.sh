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
#  - WebM:    webm   + VP9        + Opus
#    oder (wenn WebM fehlschlägt)
#  - MKV:     mkv    + VP9        + Opus
#
# Weil WebM leider nur das eine Untertitelformat "WebVTT" (Text) unterstützt.
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
VERSION="v2019110100"


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


#------------------------------------------------------------------------------#
### Endung anpassen

# dieses Format immer
ENDUNG_1="mp4"

# bevorzugtes freies Format, leider nur ohne Untertitel möglich
ENDUNG_2="webm"

# Alternative, wenn ENDUNG_2 fehlschlägt
ENDUNG_3="mkv"

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

### immer einen in MP4
echo "# 0,1: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}\" ${SCHNITT_OPTION}"
#${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}" ${SCHNITT_OPTION}

### in MKV nur, wenn WebM fehlschlägt, sonst nicht
echo "# 0,2: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}\" ${SCHNITT_OPTION}"
${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}" ${SCHNITT_OPTION}

if [ -s "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}" ] ; then
	echo "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2} hat scheinbar funktioniert, ${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3} wird nicht erzeugt"
else
	rm ${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2} ${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}.txt

	echo "# 0,3: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3}\" ${SCHNITT_OPTION}"
	${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3}" ${SCHNITT_OPTION}
fi

ls -lha "${ZIELPFAD}"*

#------------------------------------------------------------------------------#
