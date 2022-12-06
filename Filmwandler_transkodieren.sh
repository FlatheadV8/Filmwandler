#!/bin/sh
#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Durch dieses Skript wird es möglich, mit einem einzigen Aufruf Filme in zwei
# Formate zu erzeugen: MP4 (das z.Z. kompatibelste) und MKV (ein freies).
#
# Das Skript erzeugt zwei neue Filme:
#  - MP4:     mp4    + H.264/AVC  + AAC / nur kompatible Untertitel
#  - MKV:     mkv    + VP9        + Vorbis / alle Untertitel
#  - WebM:    webm   + VP9        + Vorbis / ohne Untertitel
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
VERSION="v2022120600"		# + HLS-Kompatibilitäts-Option


ALLE_OPTIONEN="${@}"

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

STOP="Nein"

AVERZ="$(dirname ${0})"				# Arbeitsverzeichnis, hier liegen diese Dateien

#------------------------------------------------------------------------------#
### Endung anpassen

# dieses Format immer zusätzlich, wenn mit Untertitel
ENDUNG_1="mp4"

# bevorzugtes freies Format, mit Untertitel
ENDUNG_2="mkv"

# bevorzugtes freies Format, ohne Untertitel
ENDUNG_3="webm"

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

UNTERTITELSPUREN="$(ffprobe -v error -probesize ${FFPROBE_PROBESIZE}M -analyzeduration ${FFPROBE_PROBESIZE}M -i "${FILMDATEI}" -show_streams | grep -F codec_type=subtitle | wc -l)"
echo "UNTERTITELSPUREN='${UNTERTITELSPUREN}'"

#exit
#==============================================================================#
# Die Frage lautet: "Sind Untertitel vorhanden?".

### das WEBM-Format verwenden wir hier nur dann, wenn keine Untertitel im Film sind und als Video-Codec "VP9" zum Einsatz kommt!
if [ 0 -eq ${UNTERTITELSPUREN} ] ; then

  #----------------------------------------------------------------------------#
  # Wenn im Film kein Untertitel vorhanden ist, dann wird nur in ein sehr kompatibles Fotmat (HD ready, HTML5 oder HLS) transkodiert.

  ### MP4 (AVC + AAC) => für DLNA- und HLS-Kompatibilität
  #echo "# 0,1: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -standard_ton 0 -u =0"
  #${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -standard_ton 0 -u =0

  ### WEBM (VP9 + Vorbis) => HTML5-kompatibel
  ### WEBM (AV1 + Opus) => HTML5-kompatibel, transkodiert viel zu langsam
  ### der Kontainer "WebM" schränkt zu stark ein, weil er nur seltene Untertitelformate unterstützt
  echo "# 0,2: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -standard_ton 0 -u =0"
  ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -standard_ton 0 -u =0

  ls -lha "${ZIELPFAD}"*

  #----------------------------------------------------------------------------#

else

  #----------------------------------------------------------------------------#

  ### MP4 (AVC + AAC) => HD ready (preiswerte DVD- und BD-Player unterstützen nur diesen Standard
  ###
  ### der Kompatibilitäts-Standard "HD ready" schränkt zu stark ein, weil er die Auflösung und die Bit-Rate begrenzt
  ### Mindestanvorderungen des "HD ready"-Standards umsetzen
  ### Das bedeutet in diesem Fall:
  ###   - Auflösung begrenzt auf:
  ###     -  4/3:  1024×768 → XGA  (EVGA)
  ###     - 16/9:  1280×720 → WXGA (HDTV)
  ###   - nur eine Tonspur (wegen Bit-Raten-Begrenzung)
  ###   - keine Untertitelspur (wegen Bit-Raten-Begrenzung)
  #echo "# 1,1: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -standard_ton 0 -u =0 -minihd"
  #${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -standard_ton 0 -u =0 -minihd

  ### MP4 (AVC + AAC) => für DLNA- und HLS-Kompatibilität
  #echo "# 1,2: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -standard_ton 0 -standard_u 0"
  #${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -standard_ton 0 -standard_u 0

  ### MKV (VP9 + Vorbis) => kann alle Audio-Kanäle und alle Untertitelformate
  #   Wird nur benötigt, wenn die vorhandenen Untertiten nicht in den MP4-Film übernommen werden konnten.
  echo "# 1,3: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -standard_ton 0 -standard_u 0"
  ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -standard_ton 0 -standard_u 0

  ### WEBM (VP9 + Vorbis) => HTML5-kompatibel
  ### WEBM (AV1 + Opus) => HTML5-kompatibel
  ### der Kontainer "WebM" schränkt zu stark ein, weil er nur seltene Untertitelformate unterstützt
  #echo "# 1,4: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${FILMDATEI}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3}\" ${SCHNITT_OPTION} -titel \"${TITEL}\" -k \"${KOMMENTAR}\" -standard_ton 0 -u =0"
  #${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${FILMDATEI}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_3}" ${SCHNITT_OPTION} -titel "${TITEL}" -k "${KOMMENTAR}" -standard_ton 0 -u =0

  #----------------------------------------------------------------------------#

  ### Um eine "HD ready"-Kompatibilität (max. 720p + keine Untertitel) zu erreichen, wird das MKV-Video noch einmal transkodiert.
  ### Kompatibilität: "HD ready", HTML5, HLS, MPEG-DASH
  echo "# 1,5: ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}\" -z \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}\" =0 -minihd -hls"
  ${AVERZ}/Filmwandler.sh ${SONSTIGE_OPTIONEN} -q "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}" -z "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_1}" -u =0 -minihd -hls

  ### konvertiert den MKV-Film in einen WebM-Konterner und entfernt dabei die Untertitel
  ### Kompatibilität: teilweise HTML5, teilweise HLS, teilweise MPEG-DASH
  #echo "# 1,6: ${AVERZ}/Filmwandler_zu_WebM-Kontainer.sh -q \"${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}\""
  #${AVERZ}/Filmwandler_zu_WebM-Kontainer.sh -q "${ZIELVERZ}/${ZIELNAME}.${ENDUNG_2}"

  #----------------------------------------------------------------------------#

  ls -lha "${ZIELPFAD}"*

fi

#==============================================================================#

