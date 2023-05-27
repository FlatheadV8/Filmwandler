#!/bin/sh
#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Dieses Skript verändert nur den Kontainer.
#
# Es wurde entworfen, um die vorhandenen AVI-Filme mit defektem Index,
# schnell anschauen zu können.
#
# Aus Kompatibilitäts-Gründen wäre die Unterstützung von AC-3 sehr hilfreich.
# Aber leider unterstützt der MP4-Kontainer keinen AC-3 (a52) - Codec,
# deshalb wird der MKV-Kontainer verwendet.
#
#------------------------------------------------------------------------------#
#
# Matroska: https://de.wikipedia.org/wiki/Containerformat
#
# Es werden folgende Programme von diesem Skript verwendet:
#  - ffmpeg
#
#------------------------------------------------------------------------------#


#VERSION="v2022072100"		# erstellt, um die vorhandenen AVI-Filme mit defektem Index, schnell anschauen zu können
#VERSION="v2022120400"		# jetzt wird der Titel und Kommentar nicht mehr zwangsläufig überschrieben
#VERSION="v2022120500"		# einen Schönheitskorrekturen vorgenommen
#VERSION="v2022120800"		# jetzt werden auch alle Tonspuren mit kopiert
#VERSION="v2022122600"		# jetzt werden auch alle Untertitel mit kopiert + kleine Fehler behoben
#VERSION="v2023010500"		# kleine Fehler behoben
VERSION="v2023021900"		# jetzt wird das Ziel ungefragt überschrieben


#set -x
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

STARTZEITPUNKT="$(date +'%s')"
AVERZ="$(dirname ${0})"		# Arbeitsverzeichnis, hier liegen diese Dateien

#------------------------------------------------------------------------------#

# Format
ENDUNG="mkv"
FORMAT="matroska"

#==============================================================================#
################################################################################
### 
#------------------------------------------------------------------------------#

if [ -z "${1}" ] ; then
        ${0} -h
	exit 10
fi

while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -q)
                        FILMDATEI="${2}"			# Name für die Quelldatei
                        shift
                        ;;
                -titel)
                        EIGENER_TITEL="${2}"			# Titel/Name des Filmes
                        shift
                        ;;
                -k)
                        KOMMENTAR="${2}"			# Kommentar/Beschreibung des Filmes
                        shift
                        ;;
                -z)
                        ZIELDATEI="${2}"			# Name für die Zieldatei
                        shift
                        ;;
                -h)
                        echo
                        echo "HILFE:

        # ein Beispiel mit minimaler Anzahl an Parametern
        ${0} -q Film.avi

        # ein komplettes Beispiel
        ${0} -q Film.avi -titel \"Der Filmname\" -k \"Ein Kommentar zum Film / FSK 12\"
                        "
                        exit 30
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
### Programm

PROGRAMM="$(which ffmpeg)"
if [ "x${PROGRAMM}" == "x" ] ; then
	PROGRAMM="$(which avconv)"
fi

if [ "x${PROGRAMM}" == "x" ] ; then
	echo "Weder avconv noch ffmpeg konnten gefunden werden. Abbruch!"
	exit 40
fi

#==============================================================================#
### Trivialitäts-Check

if [ -r "${FILMDATEI}" ] ; then
        FILM_NAME="${FILMDATEI}"
else
        echo "Der Film '${FILMDATEI}' konnte nicht gefunden werden. Abbruch!"
        exit 60
fi

if [ x == "x${ZIELDATEI}" ] ; then
	ZIEL_DATEI="${FILM_NAME}.${ENDUNG}"
else
	MKV="$(echo "${ZIELDATEI}" | grep -E '[.]mkv$')"
	if [ x == "x${MKV}" ] ; then
		ZIEL_DATEI="${ZIELDATEI}.${ENDUNG}"
	else
		ZIEL_DATEI="${ZIELDATEI}"
	fi
fi

#------------------------------------------------------------------------------#

## -probesize 18446744070G		# I64_MAX
## -analyzeduration 18446744070G	# I64_MAX
#KOMPLETT_DURCHSUCHEN="-probesize 18446744070G -analyzeduration 18446744070G"

## Value 19807040624582983680.000000 for parameter 'analyzeduration' out of range [0 - 9.22337e+18]
## Value 19807040624582983680.000000 for parameter 'analyzeduration' out of range [0 - 9.22337e+18]
## -probesize 9223370Ki
## -analyzeduration 9223370Ki
KOMPLETT_DURCHSUCHEN="-probesize 9223372036G -analyzeduration 9223372036G"

#------------------------------------------------------------------------------#
### Parameter zum reparieren defekter Container

#REPARATUR_PARAMETER="-fflags +genpts"
REPARATUR_PARAMETER="-fflags +genpts+igndts"

#==============================================================================#
transkodieren()
{
	echo
	echo "1:
	${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" -c:v copy -c:a copy -c:s copy -dn -map 0 -f ${FORMAT} -y \"${ZIEL_DATEI}\"
	" | tee -a "${ZIEL_DATEI}".txt

	echo
	${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i "${FILMDATEI}" -c:v copy -c:a copy -c:s copy -dn -map 0 -f ${FORMAT} -y "${ZIEL_DATEI}"
}
#------------------------------------------------------------------------------#
transkodieren_titel()
{
	echo
	echo "2:
	${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" -c:v copy -c:a copy -c:s copy -c:d copy -map 0 -metadata title=\"${EIGENER_TITEL}\" -f ${FORMAT} -y \"${ZIEL_DATEI}\"
	" | tee -a "${ZIEL_DATEI}".txt

	echo
	${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i "${FILMDATEI}" -c:v copy -c:a copy -c:s copy -c:d copy -map 0 -metadata title="${EIGENER_TITEL}" -f ${FORMAT} -y "${ZIEL_DATEI}"
}
#------------------------------------------------------------------------------#
transkodieren_kommentar()
{
	echo
	echo "3:
	${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" -c:v copy -c:a copy -c:s copy -c:d copy -map 0 -metadata description=\"${KOMMENTAR}\" -f ${FORMAT} -y \"${ZIEL_DATEI}\"
	" | tee -a "${ZIEL_DATEI}".txt

	echo
	${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i "${FILMDATEI}" -c:v copy -c:a copy -c:s copy -c:d copy -map 0 -metadata description="${KOMMENTAR}" -f ${FORMAT} -y "${ZIEL_DATEI}"
}
#------------------------------------------------------------------------------#
transkodieren_titel_kommentar()
{
	echo
	echo "4:
	${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" -c:v copy -c:a copy -c:s copy -c:d copy -map 0 -metadata title=\"${EIGENER_TITEL}\" -metadata description=\"${KOMMENTAR}\" -f ${FORMAT} -y \"${ZIEL_DATEI}\"
	" | tee -a "${ZIEL_DATEI}".txt

	echo
	${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i "${FILMDATEI}" -c:v copy -c:a copy -c:s copy -c:d copy -map 0 -metadata title="${EIGENER_TITEL}" -metadata description="${KOMMENTAR}" -f ${FORMAT} -y "${ZIEL_DATEI}"
}
#==============================================================================#

if [ "x${EIGENER_TITEL}" = x ] ; then
	if [ "x${KOMMENTAR}" = x ] ; then
		transkodieren
	else
		transkodieren_kommentar
	fi
else
	if [ "x${KOMMENTAR}" = x ] ; then
		transkodieren_titel
	else
		transkodieren_titel_kommentar
	fi
fi

