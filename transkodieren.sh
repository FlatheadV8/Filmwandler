#!/bin/sh
#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Durch dieses Skript wird es möglich, mit einem einzigen Aufruf Filme in zwei
# Formate zu erzeugen: MP4 (das z.Z. kompatibelste) und MKV (ein freies).
#
# Das Skript erzeugt zwei neue Filme:
#  - MP4:     mp4    + H.264/AVC  + AAC
#  - MKV:     mkv    + VP9        + Vorbis
#  - WEBM:    webm   + VP9        + Opus (in Stereo) / ohne Untertitel
#    (AV1 ist noch viel zu langsam)
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
VERSION="v2022110300"		# -standard_ton 0 -standard_u 0


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


#------------------------------------------------------------------------------#
### Endung anpassen

# dieses Format immer zusätzlich, wenn mit Untertitel
ENDUNG_1="mp4"

# bevorzugtes freies Format, mit Untertitel
ENDUNG_2="mkv"

# bevorzugtes freies Format, ohne Untertitel
ENDUNG_3="webm"

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

FFPROBE_PROBESIZE="9223372036854"       # Maximalwert in MiB auf einem Intel(R) Core(TM) i5-10600T CPU @ 2.40GHz

UNTERTITELSPUREN="$(ffprobe -v error -probesize ${FFPROBE_PROBESIZE}M -analyzeduration ${FFPROBE_PROBESIZE}M -i "${FILMDATEI}" -show_streams | grep -F codec_type=subtitle | wc -l)"
echo "UNTERTITELSPUREN='${UNTERTITELSPUREN}'"

#exit
#==============================================================================#
# Die Frage lautet: "Sind Untertitel vorhanden?".

### das WEBM-Format verwenden wir hier nur dann, wenn als Video-Codec "VP9" zum Einsatz kommt!
if [ 0 -eq ${UNTERTITELSPUREN} ] ; then

  #----------------------------------------------------------------------------#
  # Wenn im Film kein Untertitel vorhanden ist, dann wird nur in das WEBM-Fotmat transkodiert.

  ### WEBM
  ### nur wenn im Film keine Untertitel vorhanden sind, weil WEBM nur Text-Formate beherscht, und die sind sehr selten
  echo "# 1,1: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -u =0"
  ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR} -u =0"

  ls -lha "${ZIELPFAD}"*

  #----------------------------------------------------------------------------#

else

  #----------------------------------------------------------------------------#
  # Wenn kein Untertitel angegeben wurde, dann werden alle vorhandenen genommen.
  # Wenn kein Untertitel vorhanden ist, dann das WEBM-Format ohne Untertitel + das MKV-Format mit Untertitel.
  # Das MP4-Format wird durch das WEBM-Format mit explizit abgeschalteten Untertiteln ersetzt.


  ### MP4
  ### HD ready
  ### Mindestanvorderungen des "HD ready"-Standards umsetzen
  ### Das bedeutet in diesem Fall:
  ###   - Auflösung begrenzt auf:
  ###     -  4/3:  1024×768 → XGA  (EVGA)
  ###     - 16/9:  1280×720 → WXGA (HDTV)
  ###   - nur eine Tonspur
  ###   - keine Untertitelspur
  #echo "# 0,1: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -minihd -standard_ton 0 -u =0"
  #${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -minihd -standard_ton 0 -u =0

  ### MKV
  echo "# 0,2: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -standard_ton 0 -standard_u 0"
  ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -standard_ton 0 -standard_u 0

  ### WEBM
  echo "# 0,1: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -standard_ton 0 -u =0"
  ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -standard_ton 0 -u =0

  ls -lha "${ZIELPFAD}"*

fi

#==============================================================================#

