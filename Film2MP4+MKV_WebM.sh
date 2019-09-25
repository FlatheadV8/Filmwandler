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


VERSION="v2019092500"


ALLE_OPTIONEN="${@}"

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

STOP="Nein"

AVERZ="$(dirname ${0})"                 # Arbeitsverzeichnis, hier liegen diese Dateien

#==============================================================================#

while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -q)
                        FILMDATEI="${2}"        # Name für die Quelldatei
                        shift
                        ;;
                -z)
                        ZIELPFAD="${2}"         # Name für die Zieldatei
                        shift
                        ;;
                -schnitt)
                        SCHNITTZEITEN="${2}"    # zum Beispiel zum Werbung entfernen (in Sekunden, Dezimaltrennzeichen ist der Punkt): -schnitt "10-432 520-833 1050-1280"
                        shift
                        ;;
                -u)
                        # Wirddiese Option nicht verwendet, dann werden ALLE Untertitelspuren eingebettet
                        # "=0" für keinen Untertitel
                        # "0" für die erste Untertitelspur
                        # "1" für die zweite Untertitelspur
                        # "0,1" für die erste und die zweite Untertitelspur
                        UNTERTITEL="${2}"       # -u 0,1,2,3,4
                        shift
                        ;;
                *)
                        if [ "$(echo "${1}"|egrep '^-')" ] ; then
                                echo "Der Parameter '${1}' wird nicht unterstützt!"
                                export STOP="Ja"
                        fi
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

# bevorzugtes Format, leider nur ohne Untertitel möglich
ENDUNG_2="webm"

### Untertitel
if [ "x${SIND_UNTERTITEL_VORHANDEN}" != x ] ; then
        if [ "${UNTERTITEL}" != "=0" ] ; then
                # alternatives Format, wenn Untertitel vorhanden sind und nicht abgewählt wurden
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
        SCHNITT_OPTION="-schnitt '${SCHNITTZEITEN}'"
fi

#------------------------------------------------------------------------------#

#set -x
for _E in ${ENDUNG_1} ${ENDUNG_2}
do
        echo "${AVERZ}/Filmwandler.sh ${ALLE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${_E}\" ${SCHNITT_OPTION}"
        ${AVERZ}/Filmwandler.sh ${ALLE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${_E}" ${SCHNITT_OPTION}
done

#------------------------------------------------------------------------------#
