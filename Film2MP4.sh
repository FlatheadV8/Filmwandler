#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Mit diesem Skript kann man einen Film in einen HTML5-kompatiblen "*.mp4"-Film
# umwandeln, der z.B. vom FireFox ab "Version 35" inline abgespielt werden kann.
#
# Es werden folgende Programme von diesem Skript verwendet:
#  - ffmpeg
#  - ffprobe
#  - mediainfo
#  - mkvmerge (aus dem Paket mkvtoolnix)
#
#------------------------------------------------------------------------------#

VERSION="v2017102900"

#set -x
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

#TONQUALIT="3"
TONQUALIT="5"
AUDIO_SAMPLERATE="-ar 44100"

BILDQUALIT="5"
VIDEOCODEC="libx264"

#
# https://sites.google.com/site/linuxencoding/x264-ffmpeg-mapping
# -keyint <int>
#
# ffmpeg -h full 2>/dev/null | fgrep keyint
# -keyint_min        <int>        E..V.... minimum interval between IDR-frames (from INT_MIN to INT_MAX) (default 25)
IFRAME="-keyint_min 2-8"

LANG=C		# damit AWK richtig rechnet

#==============================================================================#

if [ -z "$1" ] ; then
        ${0} -h
	exit 1
fi

while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -q)
                        FILMDATEI="${2}"	# Name für die Quelldatei
                        shift
                        ;;
                -z)
                        MP4PFAD="${2}"		# Name für die Zieldatei
                        shift
                        ;;
                -c)
                        CROP="${2}"		# -vf crop=width:height:x:y
                        shift
                        ;;
                -dar|-ist_dar)
                        IST_DAR="${2}"		# Display-Format
                        shift
                        ;;
                -par|-ist_par)
                        IST_PAR="${2}"		# Pixel-Format
                        shift
                        ;;
                -in_xmaly|-ist_xmaly)
                        IST_XY="${2}"		# Bildauflösung/Rasterformat der Quelle
                        shift
                        ;;
                -out_xmaly|-soll_xmaly)
                        SOLL_XY="${2}"		# Bildauflösung/Rasterformat der Ausgabe
                        shift
                        ;;
                -aq|-soll_aq)
                        TONQUALIT="${2}"	# Audio-Qualität
                        shift
                        ;;
                -vq|-soll_vq)
                        BILDQUALIT="${2}"	# Video-Qualität
                        shift
                        ;;
                -ton)
                        TONSPUR=${2}		# "0:3" ist die 4. Tonspur; also, weil 0 die erste ist (0, 1, 2, 3), muss hier "3" stehen
                        TSNAME="${2}"
                        shift
                        ;;
                -schnitt)
                        SCHNITTZEITEN="${2}"	# zum Beispiel zum Werbung entfernen (in Sekunden, Dezimaltrennzeichen ist der Punkt): -schnitt "10-432 520-833 1050-1280"
                        shift
                        ;;
                -crop)
                        CROP="${2}"		# zum Beispiel zum entfernen der schwarzen Balken
                        shift
                        ;;
                -u)
                        UNTERTITEL="-map 0:s:${2} -scodec copy"		# "0" für die erste Untertitelspur
                        shift
                        ;;
                -h)
                        echo "HILFE:
        # Video- und Audio-Spur in ein HTML5-kompatibles Format transkodieren

        # grundsaetzlich ist der Aufbau wie folgt,
        # die Reihenfolge der Optionen ist unwichtig
        ${0} [Option] -q [Filmname] -z [Neuer_Filmname.mp4]
        ${0} -q [Filmname] -z [Neuer_Filmname.mp4] [Option]

        # ein Beispiel mit minimaler Anzahl an Parametern
        ${0} -q Film.avi -z Film.mp4

        # ein Beispiel, bei dem auch die erste Untertitelspur (Zählweise beginnt mit "0"!) mit übernommen wird
        ${0} -q Film.avi -u 0 -z Film.mp4

        # Es duerfen in den Dateinamen keine Leerzeichen, Sonderzeichen
        # oder Klammern enthalten sein!
        # Leerzeichen kann aber innerhalb von Klammer trotzdem verwenden
        ${0} -q \"Filmname mit Leerzeichen.avi\" -z Film.mp4

        # wenn der Film mehrer Tonspuren besitzt
        # und nicht die erste verwendet werden soll,
        # dann wird so die 2. Tonspur angegeben (die Zaehlweise beginnt mit 0)
        -ton 1

        # wenn der Film mehrer Tonspuren besitzt
        # und nicht die erste verwendet werden soll,
        # dann wird so die 3. Tonspur angegeben (die Zaehlweise beginnt mit 0)
        -ton 2

        # die gewünschte Bildaufloesung des neuen Filmes
        -soll_xmaly 720x576
        -out_xmaly 720x576

        # wenn die Bildaufloesung des Originalfilmes nicht automatisch ermittelt
        # werden kann, dann muss sie manuell als Parameter uebergeben werden
        -ist_xmaly 480x270
        -in_xmaly 480x270

        # wenn das Bildformat des Originalfilmes nicht automatisch ermittelt
        # werden kann, dann muss es manuell als Parameter uebergeben werden
        -dar 16:9
        -ist_dar 16:9

        # wenn die Pixelgeometrie des Originalfilmes nicht automatisch ermittelt
        # werden kann, dann muss sie manuell als Parameter uebergeben werden
        -par 64:45
        -ist_par 64:45

        # will man eine andere Video-Qualitaet, dann sie manuell als Parameter
        # uebergeben werden
        -vq 5
        -soll_vq 5

        # will man eine andere Audio-Qualitaet, dann sie manuell als Parameter
        # uebergeben werden
        -aq 3
        -soll_aq 3

        # Man kann aus dem Film einige Teile entfernen, zum Beispiel Werbung.
        # Angaben muessen in Sekunden erfolgen,
        # Dezimaltrennzeichen ist der Punkt.
        # Die Zeit-Angaben beschreiben die Laufzeit des Filmes,
        # so wie der CLI-Video-Player 'MPlayer' sie
        # in der untersten Zeile anzeigt.
        # Hier werden zwei Teile (432-520 und 833.5-1050) aus dem vorliegenden
        # Film entfernt bzw. drei Teile (8.5-432 und 520-833.5 und 1050-1280)
        # aus dem vorliegenden Film zu einem neuen Film zusammengesetzt.
        -schnitt \"8.5-432 520-833.5 1050-1280\"

        # will man z.B. von einem 4/3-Film, der als 16/9-Film (720x576)
        # mit schwarzen Balken an den Seiten, diese schwarzen Balken entfernen,
        # dann könnte das zum Beispiel so gemacht werden:
        -crop "540:576:90:0"
                        "
                        exit 1
                        ;;
                *)
                        if [ "$(echo "${1}"|egrep '^-')" ] ; then
                                echo "Der Parameter '${1}' wird nicht unterstützt!"
                        fi
                        shift
                        ;;
        esac
done

#==============================================================================#
### Trivialitäts-Check

#------------------------------------------------------------------------------#

if [ ! -r "${FILMDATEI}" ] ; then
        echo "Der Film '${FILMDATEI}' konnte nicht gefunden werden. Abbruch!"
        exit 1
fi

if [ -z "${TONSPUR}" ] ; then
        TONSPUR=0	# die erste Tonspur ist "0"
fi

#------------------------------------------------------------------------------#
# damit die Zieldatei mit Verzeichnis angegeben werden kann

MP4VERZ="$(dirname ${MP4PFAD})"
MP4DATEI="$(basename ${MP4PFAD})"

#------------------------------------------------------------------------------#
# damit man erkennt welche Tonspur aus dem Original verwendet wurde

if [ -z "${TSNAME}" ] ; then
        MP4DATEI="$(echo "${MP4DATEI} ${TSNAME}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"."$2}')"
else
        MP4DATEI="$(echo "${MP4DATEI} ${TSNAME}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"_-_Tonspur_"$3"."$2}')"
fi

#------------------------------------------------------------------------------#
# damit keine Leerzeichen im Dateinamen enthalten sind

case "${MP4DATEI}" in
        [a-zA-Z0-9\_\-\+/][a-zA-Z0-9\_\-\+/]*[.][Mm][Pp][4])
		MP4NAME="$(echo "${MP4DATEI}" | rev | sed 's/[ ][ ]*/_/g;s/[.]/ /' | rev | awk '{print $1}')"
                ENDUNG="mp4"
                FORMAT="mp4"
                shift
                ;;
        *)
                echo "Die Zieldatei darf nur die Endung '.mp4' tragen!"
                exit 1
                shift
                ;;
esac

#------------------------------------------------------------------------------#
# Test

#echo "
#MP4VERZ='${MP4VERZ}'
#MP4DATEI='${MP4DATEI}'
#MP4NAME='${MP4NAME}'
#"
#exit

#------------------------------------------------------------------------------#
### Audio-Unterstützung pro Betriebssystem

if [ "FreeBSD" = "$(uname -s)" ] ; then
        #AUDIOCODEC="libmp3lame"
        AUDIOCODEC="libfdk_aac"    # "non-free"-Lizenz; funktioniert aber
        #AUDIOCODEC="libfaac"    # "non-free"-Lizenz; funktioniert aber
        #AUDIOCODEC="aac -strict experimental"
        #AUDIOCODEC="aac"       # free-Lizenz; seit 05. Dez. 2015 nicht mehr experimentell
elif [ "Linux" = "$(uname -s)" ] ; then
        #AUDIOCODEC="libmp3lame"
        #AUDIOCODEC="libfaac"   # "non-free"-Lizenz; funktioniert aber (nur mit www.medibuntu.org)
        #AUDIOCODEC="aac -strict experimental"   # das funktioniert ohne www.medibuntu.org
        AUDIOCODEC="aac"        # free-Lizenz; seit 05. Dez. 2015 nicht mehr experimentell
fi

#==============================================================================#
### Programm

PROGRAMM="$(which avconv)"
if [ -z "${PROGRAMM}" ] ; then
        PROGRAMM="$(which ffmpeg)"
fi

if [ -z "${PROGRAMM}" ] ; then
        echo "Weder avconv noch ffmpeg konnten gefunden werden. Abbruch!"
        exit 1
fi

#==============================================================================#
### Untertitel

unset U_TITEL_MKV
if [ -n "${UNTERTITEL}" ] ; then
        echo "${UNTERTITEL}" | egrep '0:s:[0-9]' >/dev/null || export U_TITEL=Fehler
        U_TITEL_MKV="-map 0:s:0 -scodec copy"
	if [ "${U_TITEL}" = "Fehler" ] ; then
        	echo "Für die Untertitelspur muss eine Zahl angegeben werden. Abbruch!"
        	echo "z.B.: ${0} -q Film.avi -u 0 -z Film.mp4"
        	exit 1
	fi
fi

#==============================================================================#
### Qualitäts-Parameter-Übersetzung

#------------------------------------------------------------------------------#
### Audio

### Tonqualitaet entsprechend dem Audio-Encoder setzen
#
# https://trac.ffmpeg.org/wiki/Encode/AAC
# -> libfaac
# erlaubte VBR-Bitraten (FAAC_VBR): -q:a 10-500 (~27k bis ~264k)
# erlaubte ABR-Bitraten (FAAC_ABR): -b:a bis 152k
#
# -> aac
# erlaubte VBR-Bitraten (AAC_VBR): -q:a 0.1 bis 2
# erlaubte ABR-Bitraten (AAC_ABR): -b:a bis 152k
#
## -> libmp3lame
## MP3 wir in Browsern schlechter unterstützt als AAC
## https://trac.ffmpeg.org/wiki/Encode/MP3
## erlaubte VBR-Bitraten (MP3_VBR): -q:a 9-0 (45-85k bis 220-260k)
## erlaubte CBR-Bitraten (MP3_CBR): -b:a 8k-320k
#
case "${TONQUALIT}" in
        0)
                MP3_VBR="-q:a 9 -ac 2"
                MP3_CBR="-b:a 8k -ac 2"
                FAAC_VBR="-q:a 10"
                FAAC_ABR="-b:a 26k"
                AAC_VBR="-q:a 0.1"
                AAC_ABR="-b:a 26k"
                ;;
        1)
                MP3_VBR="-q:a 8 -ac 2"
                MP3_CBR="-b:a 40k -ac 2"
                FAAC_VBR="-q:a 64"
                FAAC_ABR="-b:a 40k"
                AAC_VBR="-q:a 0.3"
                AAC_ABR="-b:a 40k"
                ;;
        2)
                MP3_VBR="-q:a 7 -ac 2"
                MP3_CBR="-b:a 72k -ac 2"
                FAAC_VBR="-q:a 120"
                FAAC_ABR="-b:a 54k"
                AAC_VBR="-q:a 0.5"
                AAC_ABR="-b:a 54k"
                ;;
        3)
                MP3_VBR="-q:a 6 -ac 2"
                MP3_CBR="-b:a 106k -ac 2"
                FAAC_VBR="-q:a 174"
                FAAC_ABR="-b:a 68k"
                AAC_VBR="-q:a 0.7"
                AAC_ABR="-b:a 68k"
                ;;
        4)
                MP3_VBR="-q:a 5 -ac 2"
                MP3_CBR="-b:a 138k -ac 2"
                FAAC_VBR="-q:a 228"
                FAAC_ABR="-b:a 82k"
                AAC_VBR="-q:a 1.0"
                AAC_ABR="-b:a 82k"
                ;;
        5)
                MP3_VBR="-q:a 4 -ac 2"
                MP3_CBR="-b:a 170k -ac 2"
                FAAC_VBR="-q:a 282"
                FAAC_ABR="-b:a 96k"
                AAC_VBR="-q:a 1.2"
                AAC_ABR="-b:a 96k"
                ;;
        6)
                MP3_VBR="-q:a 3 -ac 2"
                MP3_CBR="-b:a 202k -ac 2"
                FAAC_VBR="-q:a 336"
                FAAC_ABR="-b:a 110k"
                AAC_VBR="-q:a 1.4"
                AAC_ABR="-b:a 110k"
                ;;
        7)
                MP3_VBR="-q:a 2 -ac 2"
                MP3_CBR="-b:a 236k -ac 2"
                FAAC_VBR="-q:a 392"
                FAAC_ABR="-b:a 124k"
                AAC_VBR="-q:a 1.6"
                AAC_ABR="-b:a 124k"
                ;;
        8)
                MP3_VBR="-q:a 1 -ac 2"
                MP3_CBR="-b:a 268k -ac 2"
                FAAC_VBR="-q:a 446"
                FAAC_ABR="-b:a 138k"
                AAC_VBR="-q:a 1.8"
                AAC_ABR="-b:a 138k"
                ;;
        9)
                MP3_VBR="-q:a 0 -ac 2"
                MP3_CBR="-b:a 320k -ac 2"
                FAAC_VBR="-q:a 500"
                FAAC_ABR="-b:a 152k"
                AAC_VBR="-q:a 2"
                AAC_ABR="-b:a 152k"
                ;;
esac


if [ "${AUDIOCODEC}" = "libmp3lame" ] ; then
                AUDIOOPTION="${MP3_VBR} ${AUDIO_SAMPLERATE}"
                #AUDIOOPTION="${MP3_CBR} ${AUDIO_SAMPLERATE}"
elif [ "${AUDIOCODEC}" = "libfaac" ] ; then
                AUDIOOPTION="${FAAC_VBR} ${AUDIO_SAMPLERATE}"
                #AUDIOOPTION="${FAAC_ABR} ${AUDIO_SAMPLERATE}"
elif [ "${AUDIOCODEC}" = "aac" ] ; then
                AUDIOOPTION="${AAC_VBR} ${AUDIO_SAMPLERATE}"
                #AUDIOOPTION="${AAC_ABR} ${AUDIO_SAMPLERATE}"
fi

#------------------------------------------------------------------------------#
# Bildqualität entsprechend dem Video-Encoder setzen

case "${BILDQUALIT}" in
        0)
                AVC_CRF="34"
                ;;
        1)
                AVC_CRF="32"
                ;;
        2)
                AVC_CRF="30"
                ;;
        3)
                AVC_CRF="28"
                ;;
        4)
                AVC_CRF="26"
                ;;
        5)
                AVC_CRF="24"
                ;;
        6)
                AVC_CRF="22"
                ;;
        7)
                AVC_CRF="20"
                ;;
        8)
                AVC_CRF="18"
                ;;
        9)
                AVC_CRF="16"
                ;;
esac

#==============================================================================#
### IN-Daten (META-Daten) aus der Filmdatei lesen

#------------------------------------------------------------------------------#
# Input #0, mov,mp4,m4a,3gp,3g2,mj2, from '79613_Fluch_der_Karibik_13.09.14_20-15_orf1_130_TVOON_DE.mpg.HQ.cut.mp4':
#     Stream #0:0(und): Video: h264 (High) (avc1 / 0x31637661), yuv420p(tv, bt470bg), 720x576 [SAR 64:45 DAR 16:9], 816 kb/s, 25 fps, 25 tbr, 100 tbn, 50 tbc (default)
#------------------------------------------------------------------------------#
# Input #0, matroska,webm, from 'Fluch_der_Karibik_1_Der_Fluch_der_Black_Pearl_-_Pirates_of_the_Caribbean_The_Curse_of_the_Black_Pearl/Fluch_der_Karibik_1.mkv':
#     Stream #0:0(eng): Video: h264 (High), yuv420p, 1920x816, SAR 1:1 DAR 40:17, 23.98 fps, 23.98 tbr, 1k tbn, 47.95 tbc (default)
#------------------------------------------------------------------------------#
# ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | tr -s '[\[,\]]' '\n' | egrep -B1 'SAR |DAR ' | tr -s '\n' ' ' ; echo ; done
#  720x576 SAR 64:45 DAR 16:9
#  1920x816 SAR 1:1 DAR 40:17
#------------------------------------------------------------------------------#
### Video

### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt
#echo "--------------------------------------------------------------------------------"
#probe "${FILMDATEI}" 2>&1 | fgrep Video:
#echo "--------------------------------------------------------------------------------"
#MEDIAINFO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | tr -s '[]' ' ' | tr -s ',' '\n')"
#MEDIAINFO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | tr -s '[\[,\]]' '\n' | egrep -B1 'SAR |DAR ' | tr -s '\n' ' ')"
#MEDIAINFO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | sed 's/.* Video:/Video:/' | tr -s '[\[,\]]' '\n' | egrep '[0-9]x[0-9]|SAR |DAR ' | fgrep -v 'Stream #' | tr -s '\n' ' ')"
MEDIAINFO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | sed 's/.* Video:/Video:/' | tr -s '[\[,\]]' '\n' | egrep '[0-9]x[0-9]|SAR |DAR ' | grep -Fv 'Stream #' | grep -Fv 'Video:' | tr -s '\n' ' ')"
# tbn (FPS vom Container)= the time base in AVStream that has come from the container
# tbc (FPS vom Codec) = the time base in AVCodecContext for the codec used for a particular stream
# tbr (FPS vom Video-Stream geraten) = tbr is guessed from the video stream and is the value users want to see when they look for the video frame rate

### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt
#
# leider kann das z.Z. nur mit "mediainfo" einfach und zuverlässig ermittelt werden
# mit "ffprobe" ist es etwas komplizierter...
#
SCAN_TYPE="$(mediainfo --BOM -f "${FILMDATEI}" 2>/dev/null | grep -Fv pixels | awk -F':' '/Scan type[ ]+/{print $2}' | tr -s ' ' '\n' | egrep -v '^$' | head -n1)"
if [ "${SCAN_TYPE}" != "Progressive" ] ; then
        ### wenn der Film im Zeilensprungverfahren vorliegt
        ZEILENSPRUNG="yadif,"
fi

# MEDIAINFO=' 720x576 SAR 64:45 DAR 16:9 '
IN_XY="$(echo "${MEDIAINFO}" | fgrep ' DAR ' | awk '{print $1}')"
IN_PAR="$(echo "${MEDIAINFO}" | fgrep ' DAR ' | awk '{print $3}')"
IN_DAR="$(echo "${MEDIAINFO}" | fgrep ' DAR ' | awk '{print $5}')"

#echo "
#MEDIAINFO='${MEDIAINFO}'
##----
#IN_XY='${IN_XY}'
#IN_PAR='${IN_PAR}'
#IN_DAR='${IN_DAR}'
#ZEILENSPRUNG='${ZEILENSPRUNG}'
#"
#exit


#==============================================================================#
### Korrektur: gelesene IN-Daten mit übergebenen IST-Daten überschreiben
###
### Es wird unbedingt das Rasterformat der Bildgröße (Breite x Höhe) benötigt!
###
### Weiterhin wird das Seitenverhältnis des Bildes (DAR) benötigt,
### dieser Wert kann aber auch aus dem Seitenverhältnis der Bildpunkte (PAR/SAR)
### errechnet werden.
###
### Sollte die Bildgröße bzw. DAR+PAR/SAR fehlen, bricht die Bearbeitung ab!
###
### zum Beispiel:
###                     IN_XY  = 720 x 576 (Rasterformat der Bildgröße)
###                     IN_PAR =  15 / 16  (PAR / SAR)
###                     IN_DAR =   4 / 3   (DAR)
###
#------------------------------------------------------------------------------#
### Hier wird versucht dort zu interpolieren, wo es erforderlich ist.
### Es kann jedoch von den vier Werten (Breite+Höhe+DAR+PAR) nur einer
### mit Hilfe der drei vorhandenen Werte interpoliert werden.

#------------------------------------------------------------------------------#
### Rasterformat der Bildgröße

#echo "
#IST_XY='${IST_XY}'
#IN_XY='${IN_XY}'
#"

if [ -n "${IST_XY}" ] ; then
	IN_XY="${IST_XY}"
fi

#echo "
#IST_XY='${IST_XY}'
#IN_XY='${IN_XY}'
#"
#exit


if [ -z "${IN_XY}" ] ; then
	echo "Es konnte die Video-Auflösung nicht ermittelt werden."
	echo "versuchen Sie es mit diesem Parameter nocheinmal:"
	echo "-in_xmaly"
	echo "z.B. (PAL)     : -in_xmaly 720x576"
	echo "z.B. (NTSC)    : -in_xmaly 720x486"
	echo "z.B. (NTSC-DVD): -in_xmaly 720x480"
	echo "z.B. (HDTV)    : -in_xmaly 1280x720"
	echo "z.B. (FullHD)  : -in_xmaly 1920x1080"
	echo "ABBRUCH!"
	exit 1
fi

IN_BREIT="$(echo "${IN_XY}" | awk -F'x' '{print $1}')"
IN_HOCH="$(echo "${IN_XY}" | awk -F'x' '{print $2}')"


#------------------------------------------------------------------------------#
### gewünschtes Rasterformat der Bildgröße (Auflösung)

if [ -n "${SOLL_XY}" ] ; then
	SOLL_SCALE="scale=${SOLL_XY},"
fi


#------------------------------------------------------------------------------#
### Seitenverhältnis des Bildes (DAR)

if [ -n "${IST_DAR}" ] ; then
	IN_DAR="${IST_DAR}"
fi


#----------------------------------------------------------------------#
### Seitenverhältnis der Bildpunkte (PAR / SAR)

if [ -n "${IST_PAR}" ] ; then
	IN_PAR="${IST_PAR}"
fi


#----------------------------------------------------------------------#
### Seitenverhältnis der Bildpunkte - Arbeitswerte berechnen (PAR / SAR)

ARBEITSWERTE_PAR()
{
if [ -n "${IN_PAR}" ] ; then
	PAR="$(echo "${IN_PAR}" | egrep '[:/]')"
	if [ -n "${PAR}" ] ; then
		PAR_KOMMA="$(echo "${PAR}" | egrep '[:/]' | awk -F'[:/]' '{print $1/$2}')"
		PAR_FAKTOR="$(echo "${PAR}" | egrep '[:/]' | awk -F'[:/]' '{printf "%u\n", ($1*100000)/$2}')"
	else
		PAR="$(echo "${IN_PAR}" | fgrep '.')"
		PAR_KOMMA="${PAR}"
		PAR_FAKTOR="$(echo "${PAR}" | fgrep '.' | awk '{printf "%u\n", $1*100000}')"
	fi
fi
}

ARBEITSWERTE_PAR


#------------------------------------------------------------------------------#
### Kontrolle Seitenverhältnis des Bildes (DAR)

if [ -z "${IN_DAR}" ] ; then
	IN_DAR="$(echo "${IN_BREIT} ${IN_HOCH} ${PAR_KOMMA}" | awk '{printf("%.16f\n",$3/($2/$1))}')"
fi


if [ -z "${IN_DAR}" ] ; then
	echo "Es konnte das Seitenverhältnis des Bildes nicht ermittelt werden."
	echo "versuchen Sie es mit einem dieser beiden Parameter nocheinmal:"
	echo "-in_dar"
	echo "z.B. (Röhre)   : -in_dar 4:3"
	echo "z.B. (Flat)    : -in_dar 16:9"
	echo "-in_par"
	echo "z.B. (PAL)     : -in_par 16:15"
	echo "z.B. (NTSC)    : -in_par  9:10"
	echo "z.B. (NTSC-DVD): -in_par  8:9"
	echo "z.B. (DVB/DVD) : -in_par 64:45"
	echo "z.B. (BluRay)  : -in_par  1:1"
	echo "ABBRUCH!"
	exit 1
fi


#----------------------------------------------------------------------#
### Seitenverhältnis der Bildes - Arbeitswerte berechnen (DAR)

DAR="$(echo "${IN_DAR}" | egrep '[:/]')"
if [ -n "${DAR}" ] ; then
	DAR_KOMMA="$(echo "${DAR}" | egrep '[:/]' | awk -F'[:/]' '{print $1/$2}')"
	DAR_FAKTOR="$(echo "${DAR}" | egrep '[:/]' | awk -F'[:/]' '{printf "%u\n", ($1*100000)/$2}')"
else
	DAR="$(echo "${IN_DAR}" | fgrep '.')"
	DAR_KOMMA="${DAR}"
	DAR_FAKTOR="$(echo "${DAR}" | fgrep '.' | awk '{printf "%u\n", $1*100000}')"
fi


#----------------------------------------------------------------------#
### Kontrolle Seitenverhältnis der Bildpunkte (PAR / SAR)

if [ -z "${IN_PAR}" ] ; then
	IN_PAR="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{printf "%.16f\n", ($2*$3)/$1}')"
fi


ARBEITSWERTE_PAR


#echo "
#IN_XY='${IN_XY}'
#SOLL_XY='${SOLL_XY}'
#IN_BREIT='${IN_BREIT}'
#IN_HOCH='${IN_HOCH}'
#IST_XY='${IST_XY}'
#IST_DAR='${IST_DAR}'
#IST_PAR='${IST_PAR}'
#IN_DAR='${IN_DAR}'
#DAR='${DAR}'
#DAR_KOMMA='${DAR_KOMMA}'
#DAR_FAKTOR='${DAR_FAKTOR}'
#PAR='${PAR}'
#PAR_KOMMA='${PAR_KOMMA}'
#PAR_FAKTOR='${PAR_FAKTOR}'
#"
#exit


#==============================================================================#
### Bildausschnitt

### CROPing
#
# oben und unten die schwarzen Balken entfernen
# crop=720:432:0:72
#
# von den Seiten die schwarzen Balken entfernen
# crop=540:576:90:0
#
if [ -n "${CROP}" ] ; then
	### CROP-Seiten-Format
	# -vf crop=width:height:x:y
	# -vf crop=in_w-100:in_h-100:100:100
	IN_BREIT="$(echo "${CROP}" | awk -F'[:/]' '{print $1}')"
	IN_HOCH="$(echo "${CROP}" | awk -F'[:/]' '{print $2}')"
	#X="$(echo "${CROP}" | awk -F'[:/]' '{print $3}')"
	#Y="$(echo "${CROP}" | awk -F'[:/]' '{print $4}')"

	### Display-Seiten-Format
	DAR_FAKTOR="$(echo "${PAR_FAKTOR} ${IN_BREIT} ${IN_HOCH}" | awk '{printf "%u\n", ($1*$2)/$3}')"
	DAR_KOMMA="$(echo "${DAR_FAKTOR}" | awk '{print $1/100000}')"

	CROP="crop=${CROP},"
fi


#
# echo "breit hoch DAR" | awk '{a=$1*$2; b=sqrt(a/$3); h=a/b; printf "%.0f %.0f %.0f %.0f\n", b/2, h/2}' | awk '{print $1*2, $2*2}'
# echo "720 576 1.3333" | awk '{a=$1*$2; b=sqrt(a/$3); h=a/b; printf "%.0f %.0f %.0f %.0f\n", $1, $2, b/2, h/2}' | awk '{b=$3*2; h=$4*2; print b"x"h, b/h, b*h, $1*$2}'
# echo "720 576 1.7778" | awk '{a=$1*$2; b=sqrt(a/$3); h=a/b; printf "%.0f %.0f %.0f %.0f\n", $1, $2, b/2, h/2}' | awk '{b=$3*2; h=$4*2; print b"x"h, b/h, b*h, $1*$2}'
# QUADR_AUFLOESUNG="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{a=$1*$2; h=sqrt(a/$3); b=a/h; printf "%.0f %.0f\n", b/2, h/2}' | awk '{print $1*2"x"$2*2}')"
#

#echo "
#IST_XY='${IST_XY}'
#SOLL_XY='${SOLL_XY}'
#IST_DAR='${IST_DAR}'
#DAR_FAKTOR='${DAR_FAKTOR}'
#DAR_KOMMA='${DAR_KOMMA}'
#PAR_KOMMA='${PAR_KOMMA}'
#IN_BREIT='${IN_BREIT}'
#IN_HOCH='${IN_HOCH}'
#"
#exit


if [ -z "${DAR_FAKTOR}" ] ; then
	echo "Es konnte das Display-Format nicht ermittelt werden."
	echo "versuchen Sie es mit diesem Parameter nocheinmal:"
	echo "-dar"
	echo "z.B.: -dar 16:9"
	echo "ABBRUCH!"
	exit 1
fi


if [ "${PAR_FAKTOR}" -ne "100000" ] ; then

	# Umrechnung in quadratische Pixel - Version 1
	#QUADR_SCALE="scale=$(echo "${DAR_KOMMA} ${IN_BREIT} ${IN_HOCH}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$1/2}' | awk '{print $1*2"x"$2*2}'),"
	#QUADR_SCALE="scale=$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$3/2}' | awk '{print $1*2"x"$2*2}'),"

	# Umrechnung in quadratische Pixel - Version 2
	HALBE_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{h=sqrt($1*$2/$3); printf "%.0f\n", h/2}')"
	QUADR_SCALE="scale=$(echo "${HALBE_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk '{print $1*2"x"$2*2}'),"


	QUADR_BREITE="$(echo "${QUADR_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $1}')"
	QUADR_HOCH="$(echo "${QUADR_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $2}')"
fi


#echo "
#DAR_KOMMA='${DAR_KOMMA}'
#PAR_KOMMA='${PAR_KOMMA}'
#IN_BREIT='${IN_BREIT}'
#IN_HOCH='${IN_HOCH}'
#QUADR_SCALE='${QUADR_SCALE}'
#QUADR_BREITE='${QUADR_BREITE}'
#QUADR_HOCH='${QUADR_HOCH}'
#SOLL_SCALE='${SOLL_SCALE}'
#-------------------------------
#"
#exit


### universelle Variante
# iPad : VIDEOOPTION="-crf ${AVC_CRF} -vf ${ZEILENSPRUNG}pad='max(iw\\,ih*(16/9)):ow/(16/9):(ow-iw)/2:(oh-ih)/2',scale='1024:576',setsar='1/1'"
# iPad : VIDEOOPTION="-crf ${AVC_CRF} -vf ${ZEILENSPRUNG}scale='1024:576',setsar='1/1'"
# HTML5: VIDEOOPTION="-crf ${AVC_CRF} -vf ${ZEILENSPRUNG}setsar='1/1'"
#
if [ "${DAR_FAKTOR}" -lt "149333" ] ; then
	HOEHE="4"
	BREITE="3"
else
	HOEHE="16"
	BREITE="9"
fi


### PAD
# https://ffmpeg.org/ffmpeg-filters.html#pad-1
# pad=640:480:0:40:violet
# pad=width=640:height=480:x=0:y=40:color=violet
#
# SCHWARZ="$(echo "${HOEHE} ${BREITE} ${QUADR_BREITE} ${QUADR_HOCH}" | awk '{sw="oben"; if (($1/$2) < ($3/$4)) sw="oben"; print sw}')"
# SCHWARZ="$(echo "${HOEHE} ${BREITE} ${QUADR_BREITE} ${QUADR_HOCH}" | awk '{sw="oben"; if (($1/$2) > ($3/$4)) sw="links"; print sw}')"
#
PAD="pad='max(iw\\,ih*(${HOEHE}/${BREITE})):ow/(${HOEHE}/${BREITE}):(ow-iw)/2:(oh-ih)/2',"

VIDEOOPTION="-crf ${AVC_CRF} -vf ${ZEILENSPRUNG}${CROP}${QUADR_SCALE}${PAD}${SOLL_SCALE}setsar='1/1'"

START_MP4_FORMAT="-f ${FORMAT}"


echo "
${VIDEOOPTION}
"


#echo "
#SOLL_XY='${SOLL_XY}'
#DAR_KOMMA='${DAR_KOMMA}'
#DAR_FAKTOR='${DAR_FAKTOR}'
#PAR_KOMMA='${PAR_KOMMA}'
#PAR_FAKTOR='${PAR_FAKTOR}'
#SCHWARZ='${SCHWARZ}'
#IN_BREIT='${IN_BREIT}'
#IN_HOCH='${IN_HOCH}'
#QUADR_SCALE='${QUADR_SCALE}'
#HOEHE='${HOEHE}'
#BREITE='${BREITE}'
#${PROGRAMM}
#-i \"${FILMDATEI}\"
#-map 0:v
#-c:v ${VIDEOCODEC}
#${VIDEOOPTION}
#${IFRAME}
#-map 0:a:${TONSPUR}
#-c:a ${AUDIOCODEC}
#${AUDIOOPTION}
#${START_MP4_FORMAT}
#-y ${MP4VERZ}/${MP4NAME}.${ENDUNG}
#"
#exit


#==============================================================================#

STREAM_AUDIO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep ' Stream ' | fgrep Audio:)"
STREAMAUDIO="$(echo "${STREAM_AUDIO}" | wc -w | awk '{print $1}')"

if [ "${STREAMAUDIO}" -gt 0 ] ; then
	AUDIO_VERARBEITUNG_01="-map 0:a:${TONSPUR} -c:a ${AUDIOCODEC} ${AUDIOOPTION}"
	AUDIO_VERARBEITUNG_02="-c:a copy"
else
	AUDIO_VERARBEITUNG_01="-an"
	AUDIO_VERARBEITUNG_02="-an"
fi

#echo "
#STREAM_AUDIO='${STREAM_AUDIO}'
#STREAMAUDIO='${STREAMAUDIO}'
#AUDIO_VERARBEITUNG_01='${AUDIO_VERARBEITUNG_01}'
#AUDIO_VERARBEITUNG_02='${AUDIO_VERARBEITUNG_02}'
#"
#exit

#==============================================================================#

rm -f ${MP4VERZ}/${MP4NAME}.txt
echo "${0} $@" > ${MP4VERZ}/${MP4NAME}.txt

if [ -z "${SCHNITTZEITEN}" ] ; then
	echo
	echo "${PROGRAMM} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${START_MP4_FORMAT} -y ${MP4VERZ}/${MP4NAME}.${ENDUNG}" | tee -a ${MP4VERZ}/${MP4NAME}.txt
	echo
	${PROGRAMM} -i "${FILMDATEI}" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} ${START_MP4_FORMAT} -y ${MP4VERZ}/${MP4NAME}.${ENDUNG} 2>&1
else
	#echo "SCHNITTZEITEN=${SCHNITTZEITEN}"
	#exit

	ZUFALL="$(head -c 100 /dev/urandom | base64 | tr -d '\n' | tr -cd '[:alnum:]' | cut -b-12)"
	NUMMER="0"
	for _SCHNITT in ${SCHNITTZEITEN}
	do
		NUMMER="$(echo "${NUMMER}" | awk '{printf "%2.0f\n", $1+1}' | tr -s ' ' '0')"
		VON="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $1}')"
		DAUER="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $2 - $1}')"

		echo
		echo "${PROGRAMM} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} -ss ${VON} -t ${DAUER} -f matroska -y ${MP4VERZ}/${ZUFALL}_${NUMMER}_${MP4NAME}.mkv" | tee -a ${MP4VERZ}/${MP4NAME}.txt
		echo
		${PROGRAMM} -i "${FILMDATEI}" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} -ss ${VON} -t ${DAUER} -f matroska -y ${MP4VERZ}/${ZUFALL}_${NUMMER}_${MP4NAME}.mkv 2>&1
		echo "---------------------------------------------------------"
	done

	FILM_TEILE="$(ls -1 ${MP4VERZ}/${ZUFALL}_*_${MP4NAME}.mkv | tr -s '\n' '|' | sed 's/|/ + /g;s/ + $//')"
	echo "# mkvmerge -o '${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv' '${FILM_TEILE}'"
	mkvmerge -o ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv ${FILM_TEILE}

	# den vertigen Film aus dem MKV-Format in das MP$-Format umwandeln
	echo "${PROGRAMM} -i ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv -c:v copy ${AUDIO_VERARBEITUNG_02} ${START_MP4_FORMAT} -y ${MP4VERZ}/${MP4NAME}.${ENDUNG}"
	${PROGRAMM} -i ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv -c:v copy ${AUDIO_VERARBEITUNG_02} ${U_TITEL_MKV} ${START_MP4_FORMAT} -y ${MP4VERZ}/${MP4NAME}.${ENDUNG}

	#ls -lh ${MP4VERZ}/${ZUFALL}_*_${MP4NAME}.mkv ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv
	#echo "rm -f ${MP4VERZ}/${ZUFALL}_*_${MP4NAME}.mkv ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv"
	rm -f ${MP4VERZ}/${ZUFALL}_*_${MP4NAME}.mkv ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv
fi

#echo "
#${PROGRAMM} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} -map 0:a:${TONSPUR} -c:a ${AUDIOCODEC} ${AUDIOOPTION} ${UNTERTITEL} ${START_MP4_FORMAT} -y ${MP4VERZ}/${MP4NAME}.${ENDUNG}
#"
#------------------------------------------------------------------------------#

ls -lh ${MP4VERZ}/${MP4NAME}.${ENDUNG} ${MP4VERZ}/${MP4NAME}.txt
exit
