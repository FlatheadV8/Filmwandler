#!/bin/sh
#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Durch dieses Skript wird es möglich, mit einem einzigen Aufruf Filme in zwei
# Formate zu erzeugen: MP4 (das z.Z. kompatibelste) und MKV (ein freies).
#
# Das Skript erzeugt zwei neue Filme:
#  - MP4:     mp4    + H.264/AVC  + AAC
#    und
#  - MKV:     mkv    + VP9        + Vorbis
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
VERSION="v2022072600"		# um die Kompatibilität der MP4 zu erhöhen, wurde der Parameter '-stereo' hinzugefügt, jetzt werden auch Filme mit großer Audio-Bit-Rate auf einfachen Media-Playern abgespielt


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

# bevorzugtes freies Format
ENDUNG_2="mkv"

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

### MP4
echo "# 0,1: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -stereo"
${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -stereo

### MKV
echo "# 0,2: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\""
${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}"

ls -lha "${ZIELPFAD}"*

#------------------------------------------------------------------------------#
