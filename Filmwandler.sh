#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Dieses Skript verändert NICHT die Bildwiederholrate!
#
# Das Ergebnis besteht aus folgenden Formaten:
#  - DivX10: mkv  + H.265/HEVC + AAC
#  - WebM:   webm + VP9        + Opus
#  - MP4:    mp4  + H.264/AVC  + AAC
#  - AVCHD:  mts  + H.264/AVC  + AC3
#  - AVI:    avi  + DivX5      + MP3
#  - FLV:    flv  + FLV        + MP3  (Sorenson Spark: H.263)
#  - 3GPP:   3gp  + H.263      + AAC  (128x96 176x144 352x288 704x576 1408x1152)
#  - OGG:    ogv  + Theora     + Vorbis
#  - MPEG:   mpeg + MPEG-2     + AC3
#  - MPG:    mpg  + MPEG-1     + MP2
#
# https://de.wikipedia.org/wiki/Containerformat
#
# Es werden folgende Programme von diesem Skript verwendet:
#  - ffmpeg
#  - ffprobe
#  - mediainfo
#  - mkvmerge (aus dem Paket mkvtoolnix)
#
#------------------------------------------------------------------------------#


BILDQUALIT="5"
TONQUALIT="5"


#VERSION="v2017102900"
VERSION="v2018070500"

#set -x
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"


#
# https://sites.google.com/site/linuxencoding/x264-ffmpeg-mapping
# -keyint <int>
#
# ffmpeg -h full 2>/dev/null | fgrep keyint
# -keyint_min        <int>        E..V.... minimum interval between IDR-frames (from INT_MIN to INT_MAX) (default 25)
IFRAME="-keyint_min 2-8"

LANG=C					# damit AWK richtig rechnet
Film2Standardformat_OPTIONEN="${@}"
ORIGINAL_PIXEL="Nein"

#==============================================================================#
### Funktionen

# einbinden der Namen von vielen Bildauflösungen
BILDAUFLOESUNGEN_NAMEN="$(dirname ${0})/Filmwandler_grafik.txt"
if [ -r "${BILDAUFLOESUNGEN_NAMEN}" ] ; then
. ${BILDAUFLOESUNGEN_NAMEN}
BILD_FORMATNAMEN_AUFLOESUNGEN="$(bildaufloesungen_namen)"
fi

AVERZ="$(dirname ${0})"		# Arbeitsverzeichnis, hier liegen diese Dateien


ausgabe_hilfe()
{
echo "
#==============================================================================#
#                                                                              #
# HILFE                                                                        #
#                                                                              #
# Geben sie bitte die richtige Dateiendung für den neuen Film an!              #
>>> ${ZIELDATEI} <<<
#                                                                              #
# Es werden die folgenden Formate unterstützt:                                 #
"
for INC in $(ls ${AVERZ}/Filmwandler_Format_*.txt)
do
	. ${INC}
	echo "${FORMAT_BESCHREIBUNG}"
done
echo "
#                                                                              #
#==============================================================================#
"
}


#==============================================================================#

if [ -z "$1" ] ; then
        ${0} -h
	exit 10
fi

while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -q)
                        FILMDATEI="${2}"	# Name für die Quelldatei
                        shift
                        ;;
                -z)
                        ZIELPFAD="${2}"		# Name für die Zieldatei
                        shift
                        ;;
                -c|-crop)
                        CROP="${2}"		# zum entfernen der schwarzen Balken: -vf crop=width:height:x:y
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
                        TONSPUR="${2}"		# "3" für die 4. Tonspur (0, 1, 2, 3)
                        TSNAME="${2}"
                        shift
                        ;;
                -schnitt)
                        SCHNITTZEITEN="${2}"	# zum Beispiel zum Werbung entfernen (in Sekunden, Dezimaltrennzeichen ist der Punkt): -schnitt "10-432 520-833 1050-1280"
                        shift
                        ;;
                -test|-t)
                        ORIGINAL_PIXEL="Ja"	# um die richtigen CROP-Parameter zu ermitteln
                        shift
                        ;;
                -u)
                        UNTERTITEL="-map 0:s:${2} -scodec copy"		# "0" für die erste Untertitelspur
                        shift
                        ;;
                -h)
			ausgabe_hilfe
                        echo "HILFE:
        # Video- und Audio-Spur in ein HTML5-kompatibles Format transkodieren

        # grundsaetzlich ist der Aufbau wie folgt,
        # die Reihenfolge der Optionen ist unwichtig
        ${0} [Option] -q [Filmname] -z [Neuer_Filmname.mp4]
        ${0} -q [Filmname] -z [Neuer_Filmname.mp4] [Option]

        # ein Beispiel mit minimaler Anzahl an Parametern
        ${0} -q Film.avi -z Film.mp4

        # ein Beispiel, bei dem auch die erste Untertitelspur (Zählweise beginnt mit '0'!) mit übernommen wird
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
        -schnitt '8.5-432 520-833.5 1050-1280'

        # will man z.B. von einem 4/3-Film, der als 16/9-Film (720x576)
        # mit schwarzen Balken an den Seiten, diese schwarzen Balken entfernen,
        # dann könnte das zum Beispiel so gemacht werden:
        -crop '540:576:90:0'

        # die gewünschte Bildauflösung des neuen Filmes
        -soll_xmaly 720x576		# deutscher Parametername
        -out_xmaly 720x480		# englischer Parametername
        -soll_xmaly 965x543		# frei wählbares Bildformat kann angegeben werden
	${BILD_FORMATNAMEN_AUFLOESUNGEN}
                        "
                        exit 12
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
        exit 13
fi

if [ -z "${TONSPUR}" ] ; then
        TONSPUR=0	# die erste Tonspur ist "0"
fi

#------------------------------------------------------------------------------#
# damit die Zieldatei mit Verzeichnis angegeben werden kann

ZIELVERZ="$(dirname ${ZIELPFAD})"
ZIELDATEI="$(basename ${ZIELPFAD})"

#------------------------------------------------------------------------------#
# damit keine Leerzeichen im Dateinamen enthalten sind

if [ -z "${TSNAME}" ] ; then
        ZIELDATEI="$(echo "${ZIELDATEI} ${TSNAME}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"."$2}')"
else
	# damit man erkennt welche Tonspur aus dem Original verwendet wurde
        ZIELDATEI="$(echo "${ZIELDATEI} ${TSNAME}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"_-_Tonspur_"$3"."$2}')"
fi

#==============================================================================#
### Programm

PROGRAMM="$(which ffmpeg)"
if [ -z "${PROGRAMM}" ] ; then
	PROGRAMM="$(which avconv)"
fi

if [ -z "${PROGRAMM}" ] ; then
	echo "Weder avconv noch ffmpeg konnten gefunden werden. Abbruch!"
	exit 14
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
		exit 15
	fi
fi

#==============================================================================#
#==============================================================================#
### Video

#------------------------------------------------------------------------------#
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


### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt
#echo "--------------------------------------------------------------------------------"
#probe "${FILMDATEI}" 2>&1 | fgrep Video:
#echo "--------------------------------------------------------------------------------"
MEDIAINFO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | sed 's/.* Video:/Video:/' | tr -s '[\[,\]]' '\n' | egrep '[0-9]x[0-9]|SAR |DAR | fps' | grep -Fv 'Stream #' | grep -Fv 'Video:' | tr -s '\n' ' ')"
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

# MEDIAINFO=' 720x576 SAR 64:45 DAR 16:9 25 fps '
# MEDIAINFO=" 852x480 SAR 1:1 DAR 71:40 25 fps "
IN_XY="$(echo "${MEDIAINFO}" | fgrep ' DAR ' | awk '{print $1}')"
IN_PAR="$(echo "${MEDIAINFO}" | fgrep ' DAR ' | awk '{print $3}')"
IN_DAR="$(echo "${MEDIAINFO}" | fgrep ' DAR ' | awk '{print $5}')"
#IN_FPS="$(echo "${MEDIAINFO}" | fgrep ' DAR ' | awk '{print $6}')"


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
###	IN_XY  = 720 x 576 (Rasterformat der Bildgröße)
###	IN_PAR =  15 / 16  (PAR / SAR)
###	IN_DAR =   4 / 3   (DAR)
###
#------------------------------------------------------------------------------#
### Hier wird versucht dort zu interpolieren, wo es erforderlich ist.
### Es kann jedoch von den vier Werten (Breite+Höhe+DAR+PAR) nur einer
### mit Hilfe der drei vorhandenen Werte interpoliert werden.

#------------------------------------------------------------------------------#
### Rasterformat der Bildgröße

if [ -n "${IST_XY}" ] ; then
	IN_XY="${IST_XY}"
fi


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
	exit 19
fi

IN_BREIT="$(echo "${IN_XY}" | awk -F'x' '{print $1}')"
IN_HOCH="$(echo "${IN_XY}" | awk -F'x' '{print $2}')"


#------------------------------------------------------------------------------#
### gewünschtes Rasterformat der Bildgröße (Auflösung)

if [ "${ORIGINAL_PIXEL}" = Ja ] ; then
	unset SOLL_SCALE
else
	if [ -n "${SOLL_XY}" ] ; then
		SOLL_SCALE="scale=${SOLL_XY},"
	fi
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
	exit 20
fi


#----------------------------------------------------------------------#
### Seitenverhältnis des Bildes - Arbeitswerte berechnen (DAR)

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


if [ -z "${DAR_FAKTOR}" ] ; then
	echo "Es konnte das Display-Format nicht ermittelt werden."
	echo "versuchen Sie es mit diesem Parameter nocheinmal:"
	echo "-dar"
	echo "z.B.: -dar 16:9"
	echo "ABBRUCH!"
	exit 21
fi


if [ "${PAR_FAKTOR}" -ne "100000" ] ; then

	### Umrechnung in quadratische Pixel - Version 1
	#QUADR_SCALE="scale=$(echo "${DAR_KOMMA} ${IN_BREIT} ${IN_HOCH}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$1/2}' | awk '{print $1*2"x"$2*2}'),"
	#QUADR_SCALE="scale=$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$3/2}' | awk '{print $1*2"x"$2*2}'),"

	### Umrechnung in quadratische Pixel - Version 2
	#HALBE_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{h=sqrt($1*$2/$3); printf "%.0f\n", h/2}')"
	#QUADR_SCALE="scale=$(echo "${HALBE_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk '{print $1*2"x"$2*2}'),"
	#
	### [swscaler @ 0x81520d000] Warning: data is not aligned! This can lead to a speed loss
	### laut Googel müssen die Pixel durch 16 teilbar sein, beseitigt aber leider das Problem hier nicht
	#TEILER="2"
	#TEILER="8"
	TEILER="16"
	#TEILER="32"
	TEIL_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA} ${TEILER}" | awk '{h=sqrt($1*$2/$3); printf "%.0f\n", h/$4}')"
	QUADR_SCALE="scale=$(echo "${TEIL_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk -v teiler="${TEILER}" '{print $1*teiler"x"$2*teiler}'),"

	QUADR_BREITE="$(echo "${QUADR_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $1}')"
	QUADR_HOCH="$(echo "${QUADR_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $2}')"
fi


#------------------------------------------------------------------------------#
### universelle Variante
# iPad : VIDEOOPTION="-vf ${ZEILENSPRUNG}pad='max(iw\\,ih*(16/9)):ow/(16/9):(ow-iw)/2:(oh-ih)/2',scale='1024:576',setsar='1/1'"
# iPad : VIDEOOPTION="-vf ${ZEILENSPRUNG}scale='1024:576',setsar='1/1'"
# HTML5: VIDEOOPTION="-vf ${ZEILENSPRUNG}setsar='1/1'"
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
if [ "${ORIGINAL_PIXEL}" = Ja ] ; then
	unset PAD
else
	PAD="pad='max(iw\\,ih*(${HOEHE}/${BREITE})):ow/(${HOEHE}/${BREITE}):(ow-iw)/2:(oh-ih)/2',"
fi

#------------------------------------------------------------------------------#
### Übersetzung von Bildauflösungsnamen zu Bildauflösungen
### tritt nur bei manueller Auswahl der Bildauflösung in Kraft

if [ "x${SOLL_XY}" != "x" ] ; then
	AUFLOESUNG_ODER_NAME="$(echo "${SOLL_XY}" | egrep '[0-9][0-9][0-9][x][0-9][0-9]')"
	if [ "x${AUFLOESUNG_ODER_NAME}" = "x" ] ; then
		### manuelle Auswahl der Bildauflösung per Namen
		if [ "x${BILD_FORMATNAMEN_AUFLOESUNGEN}" != "x" ] ; then
			SOLL_XY="$(bildaufloesungen_namen | egrep '[-]soll_xmaly ' | awk '{print $2,$4}' | egrep "^${SOLL_XY} " | awk '{print $2}')"
			SOLL_SCALE="scale=${SOLL_XY},"
		else
			echo "Die gewünschte Bildauflösung wurde als 'Name' angegeben: '${SOLL_XY}'"
			echo "Für die Übersetzung wird die Datei 'Filmwandler_grafik.txt' benötigt."
			echo "Leider konnte die Datei '$(dirname ${0})/Filmwandler_grafik.txt' nicht gelesen werden."
			exit 22
		fi
	fi
fi

#------------------------------------------------------------------------------#

if [ "x${SOLL_XY}" = "x" ] ; then
	PIXELZAHL="$(echo "${IN_BREIT} ${IN_HOCH}" | awk '{print $1 * $2}')"
else
	PIXELZAHL="$(echo "${SOLL_XY}" | awk -F'x' '{print $1 * $2}')"
fi

#------------------------------------------------------------------------------#

echo "
Originalauflösung   =${IN_BREIT}x${IN_HOCH}
erwünschte Auflösung=${SOLL_XY}
PIXELZAHL           =${PIXELZAHL}
"
#exit

#------------------------------------------------------------------------------#
### AVI und 3GPP können nicht zwingend quadratische Bildpunkte haben

FORMAT_ANPASSUNG="setsar='1/1'"


#==============================================================================#
#==============================================================================#
# Das Video-Format wird nach der Dateiendung ermittelt
#

ZIELNAME="$(echo "${ZIELDATEI}" | rev | sed 's/[ ][ ]*/_/g;s/[.]/ /' | rev | awk '{print $1}')"
ENDUNG="$(echo "${ZIELDATEI}" | sed 's/[a-zA-Z0-9\_\-\+/][a-zA-Z0-9\_\-\+/]*[.]/&"/;s/.*"//' | awk '{print tolower($0)}')"
. ${AVERZ}/Filmwandler_Format_${ENDUNG}.txt

#------------------------------------------------------------------------------#
### ab hier kann in die Log-Datei geschrieben werden

#rm -f ${ZIELVERZ}/${ZIELNAME}.txt
echo "# $(date +'%F %T')
${0} ${Film2Standardformat_OPTIONEN}" | tee ${ZIELVERZ}/${ZIELNAME}.txt

echo "
${FORMAT_BESCHREIBUNG}
" | tee -a ${ZIELVERZ}/${ZIELNAME}.txt

#------------------------------------------------------------------------------#

echo "
AUDIOCODEC=${AUDIOCODEC}
AUDIO_QUALITAET_0=${AUDIO_QUALITAET_0}
AUDIO_QUALITAET_5=${AUDIO_QUALITAET_5}
AUDIO_QUALITAET_9=${AUDIO_QUALITAET_9}

VIDEOCODEC=${VIDEOCODEC}
VIDEO_QUALITAET_0=${VIDEO_QUALITAET_0}
VIDEO_QUALITAET_5=${VIDEO_QUALITAET_5}
VIDEO_QUALITAET_9=${VIDEO_QUALITAET_9}
" | tee -a ${ZIELVERZ}/${ZIELNAME}.txt
#exit

#==============================================================================#
### Qualität
#
# Qualitäts-Parameter-Übersetzung
# https://slhck.info/video/2017/02/24/vbr-settings.html
#

#------------------------------------------------------------------------------#
### Audio

case "${TONQUALIT}" in
	0)
		AUDIOQUALITAET="${AUDIO_QUALITAET_0}"
		;;
	1)
		AUDIOQUALITAET="${AUDIO_QUALITAET_1}"
		;;
	2)
		AUDIOQUALITAET="${AUDIO_QUALITAET_2}"
		;;
	3)
		AUDIOQUALITAET="${AUDIO_QUALITAET_3}"
		;;
	4)
		AUDIOQUALITAET="${AUDIO_QUALITAET_4}"
		;;
	5)
		AUDIOQUALITAET="${AUDIO_QUALITAET_5}"
		;;
	6)
		AUDIOQUALITAET="${AUDIO_QUALITAET_6}"
		;;
	7)
		AUDIOQUALITAET="${AUDIO_QUALITAET_7}"
		;;
	8)
		AUDIOQUALITAET="${AUDIO_QUALITAET_8}"
		;;
	9)
		AUDIOQUALITAET="${AUDIO_QUALITAET_9}"
		;;
esac

#------------------------------------------------------------------------------#
### Video

case "${BILDQUALIT}" in
	0)
		VIDEOQUALITAET="${VIDEO_QUALITAET_0}"
		;;
	1)
		VIDEOQUALITAET="${VIDEO_QUALITAET_1}"
		;;
	2)
		VIDEOQUALITAET="${VIDEO_QUALITAET_2}"
		;;
	3)
		VIDEOQUALITAET="${VIDEO_QUALITAET_3}"
		;;
	4)
		VIDEOQUALITAET="${VIDEO_QUALITAET_4}"
		;;
	5)
		VIDEOQUALITAET="${VIDEO_QUALITAET_5}"
		;;
	6)
		VIDEOQUALITAET="${VIDEO_QUALITAET_6}"
		;;
	7)
		VIDEOQUALITAET="${VIDEO_QUALITAET_7}"
		;;
	8)
		VIDEOQUALITAET="${VIDEO_QUALITAET_8}"
		;;
	9)
		VIDEOQUALITAET="${VIDEO_QUALITAET_9}"
		;;
esac


#exit
#==============================================================================#
# Audio

STREAM_AUDIO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep ' Stream ' | fgrep Audio:)"
STREAMAUDIO="$(echo "${STREAM_AUDIO}" | wc -w | awk '{print $1}')"

if [ "${STREAMAUDIO}" -gt 0 ] ; then
	AUDIO_VERARBEITUNG_01="-map 0:a:${TONSPUR} -c:a ${AUDIOCODEC} ${AUDIOQUALITAET}"
	AUDIO_VERARBEITUNG_02="-c:a copy"
else
	AUDIO_VERARBEITUNG_01="-an"
	AUDIO_VERARBEITUNG_02="-an"
fi

#==============================================================================#
# Video

VIDEOOPTION="${VIDEOQUALITAET} -vf ${ZEILENSPRUNG}${CROP}${QUADR_SCALE}${PAD}${SOLL_SCALE}${FORMAT_ANPASSUNG}"

START_ZIEL_FORMAT="-f ${FORMAT}"

#==============================================================================#

echo "
STREAM_AUDIO=${STREAM_AUDIO}
STREAMAUDIO=${STREAMAUDIO}

AUDIO_VERARBEITUNG_01=${AUDIO_VERARBEITUNG_01}
AUDIO_VERARBEITUNG_02=${AUDIO_VERARBEITUNG_02}

VIDEOOPTION=${VIDEOOPTION}
START_ZIEL_FORMAT=${START_ZIEL_FORMAT}
" | tee -a ${ZIELVERZ}/${ZIELNAME}.txt
#exit


#------------------------------------------------------------------------------#
if [ -z "${SCHNITTZEITEN}" ] ; then

	echo
	echo "1: ${PROGRAMM} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}" | tee -a ${ZIELVERZ}/${ZIELNAME}.txt
	echo
#>
	${PROGRAMM} -i "${FILMDATEI}" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG} 2>&1

else

	#----------------------------------------------------------------------#
	ZUFALL="$(head -c 100 /dev/urandom | base64 | tr -d '\n' | tr -cd '[:alnum:]' | cut -b-12)"
	NUMMER="0"
	for _SCHNITT in ${SCHNITTZEITEN}
	do
		NUMMER="$(echo "${NUMMER}" | awk '{printf "%2.0f\n", $1+1}' | tr -s ' ' '0')"
		VON="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $1}')"
		BIS="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $2}')"

		echo
		echo "2: ${PROGRAMM} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} -ss ${VON} -to ${BIS} -f matroska -y ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.mkv" | tee -a ${ZIELVERZ}/${ZIELNAME}.txt
		echo
#>
		${PROGRAMM} -i "${FILMDATEI}" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} -ss ${VON} -to ${BIS} -f matroska -y ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.mkv 2>&1
		echo "---------------------------------------------------------"
	done

	FILM_TEILE="$(ls -1 ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv | tr -s '\n' '|' | sed 's/|/ + /g;s/ + $//')"
	echo "3: mkvmerge -o '${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv' '${FILM_TEILE}'"
#>
	mkvmerge -o ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv ${FILM_TEILE}

	# den vertigen Film aus dem MKV-Format in das MP$-Format umwandeln
	echo "4: ${PROGRAMM} -i ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv -c:v copy ${AUDIO_VERARBEITUNG_02} ${U_TITEL_MKV} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}"
#>
	${PROGRAMM} -i ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv -c:v copy ${AUDIO_VERARBEITUNG_02} ${U_TITEL_MKV} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}

	#ls -lh ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv
	#echo "rm -f ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv"
	rm -f ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv

fi
#------------------------------------------------------------------------------#

echo "
5: ${PROGRAMM} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} -map 0:a:${TONSPUR} -c:a ${AUDIOCODEC} ${UNTERTITEL} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}
"
#------------------------------------------------------------------------------#

ls -lh ${ZIELVERZ}/${ZIELNAME}.${ENDUNG} ${ZIELVERZ}/${ZIELNAME}.txt | tee -a ${ZIELVERZ}/${ZIELNAME}.txt
#exit
