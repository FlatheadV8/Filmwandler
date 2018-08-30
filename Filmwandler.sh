#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Dieses Skript verändert NICHT die Bildwiederholrate!
#
# Das Ergebnis besteht aus folgenden Formaten:
#  - MKV:    mkv  + VP8        + MP3
#  - WebM:   webm + VP9        + Opus
#  - MP4:    mp4  + H.264/AVC  + AAC
#  - AVCHD:  mts  + H.264/AVC  + AC3
#  - AVI:    avi  + DivX5      + MP3
#  - FLV:    flv  + FLV        + MP3  (Sorenson Spark: H.263)
#  - 3GPP:   3gp  + H.263      + AAC  (128x96 176x144 352x288 704x576 1408x1152)
#  - OGG:    ogg  + Theora     + Vorbis
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


#VERSION="v2017102900"
VERSION="v2018083000"


BILDQUALIT="auto"
TONQUALIT="auto"

#set -x
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

STARTZEITPUNKT="$(date +'%s')"

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
STOP="Nein"

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
# Es werden die folgenden Formate unterstützt:                                 #"
for INC in $(ls ${AVERZ}/Filmwandler_Format_*.txt)
do
	. ${INC}
	echo "${FORMAT_BESCHREIBUNG}"
done
echo "#                                                                              #
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
                        TONSPUR="${2}"		# Tonspur (1, 2, 3, 4)
                        shift
                        ;;
                -stereo)
                        STEREO="-ac 2"		# Stereo-Ausgabe erzwingen
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

	# Stereo-Ausgabe erzwingen
	# egal wieviele Audio-Kanäle der Originalfilm hat, der neue Film wird Stereo haben
	-stereo

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
				export STOP="Ja"
                        fi
                        shift
                        ;;
        esac
done


#==============================================================================#
### Trivialitäts-Check

if [ "${STOP}" = "Ja" ] ; then
        echo "Bitte korrigieren sie die falschen Parameter. Abbruch!"
        exit 13
fi

#------------------------------------------------------------------------------#

if [ ! -r "${FILMDATEI}" ] ; then
        echo "Der Film '${FILMDATEI}' konnte nicht gefunden werden. Abbruch!"
        exit 14
fi

if [ -z "${TONSPUR}" ] ; then
        TONSPUR=0	# die erste Tonspur ist "0"
else
	if [ "${TONSPUR}" -gt 0 ] ; then
		TSNAME="$(echo "${TONSPUR}" | awk '{print $1 - 1}')"
	else
		TSNAME="${TONSPUR}"
	fi
fi

#------------------------------------------------------------------------------#
# damit die Zieldatei mit Verzeichnis angegeben werden kann

QUELL_DATEI="$(basename ${FILMDATEI})"
ZIELVERZ="$(dirname ${ZIELPFAD})"
ZIELDATEI="$(basename ${ZIELPFAD})"

#------------------------------------------------------------------------------#
# damit keine Leerzeichen im Dateinamen enthalten sind

if [ -z "${TSNAME}" ] ; then
        ZIELDATEI="$(echo "${ZIELDATEI}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"."$2}')"
else
	# damit man erkennt welche Tonspur aus dem Original verwendet wurde
        ZIELDATEI="$(echo "${ZIELDATEI} ${TONSPUR}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"_-_Tonspur_"$3"."$2}')"
fi

#==============================================================================#
### Programm

PROGRAMM="$(which ffmpeg)"
if [ -z "${PROGRAMM}" ] ; then
	PROGRAMM="$(which avconv)"
fi

if [ -z "${PROGRAMM}" ] ; then
	echo "Weder avconv noch ffmpeg konnten gefunden werden. Abbruch!"
	exit 15
fi

REPARATUR_PARAMETER="-fflags +genpts"

#==============================================================================#
### Untertitel

unset U_TITEL_MKV
if [ -n "${UNTERTITEL}" ] ; then
	echo "${UNTERTITEL}" | egrep '0:s:[0-9]' >/dev/null || export U_TITEL=Fehler
	U_TITEL_MKV="-map 0:s:0 -scodec copy"
	if [ "${U_TITEL}" = "Fehler" ] ; then
		echo "Für die Untertitelspur muss eine Zahl angegeben werden. Abbruch!"
		echo "z.B.: ${0} -q Film.avi -u 0 -z Film.mp4"
		exit 16
	fi
fi

#==============================================================================#
#==============================================================================#
### Video

#------------------------------------------------------------------------------#
### FFmpeg verwendet drei verschiedene Zeitangaben:
# http://ffmpeg-users.933282.n4.nabble.com/What-does-the-output-of-ffmpeg-mean-tbr-tbn-tbc-etc-td941538.html
# http://stackoverflow.com/questions/3199489/meaning-of-ffmpeg-output-tbc-tbn-tbr
# tbn = the time base in AVStream that has come from the container
# tbc = the time base in AVCodecContext for the codec used for a particular stream
# tbr = tbr is guessed from the video stream and is the value users want to see when they look for the video frame rate
#------------------------------------------------------------------------------#

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
### hier wird ermittelt, wieviele Audio-Kanäle max. um Film enthalten sind

AUDIO_KANAELE="$(ffprobe -show_data -show_streams "${FILMDATEI}" 2>/dev/null | sed -e '1,/^codec_type=audio/ d' | awk -F'=' '/^channels=/{print $2}' | sort -nr | head -n1)"	# max. Anzahl der vorhandenen Audio-Kanäle
if [ "x${STEREO}" != "x" ] ; then
	AUDIO_KANAELE="2"
fi

#------------------------------------------------------------------------------#
### hier wird eine Liste externer verfügbarer Codecs erstellt

FFMPEG_LIB="$((ffmpeg -formats >/dev/null) 2>&1 | tr -s ' ' '\n' | egrep '^[-][-]enable[-]' | sed 's/^[-]*enable[-]*//;s/[-]/_/g' | egrep '^lib')"
FFMPEG_FORMATS="$(ffmpeg -formats 2>/dev/null | awk '/^[ \t]*[ ][DE]+[ ]/{print $2}')"

#------------------------------------------------------------------------------#
### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt

#echo "--------------------------------------------------------------------------------"
#probe "${FILMDATEI}" 2>&1 | fgrep Video:
#echo "--------------------------------------------------------------------------------"
FFPROBE="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | sed 's/.* Video:/Video:/' | tr -s '[\[,\]]' '\n' | egrep '[0-9]x[0-9]|SAR |DAR | fps' | grep -Fv 'Stream #' | grep -Fv 'Video:' | tr -s '\n' ' ')"
# tbn (FPS vom Container)= the time base in AVStream that has come from the container
# tbc (FPS vom Codec) = the time base in AVCodecContext for the codec used for a particular stream
# tbr (FPS vom Video-Stream geraten) = tbr is guessed from the video stream and is the value users want to see when they look for the video frame rate
echo "FFPROBE='${FFPROBE}'"
#------------------------------------------------------------------------------#
### alternative Methode zur Ermittlung der FPS
R_FPS="$(ffprobe -show_data -show_streams "${FILMDATEI}" 2>/dev/null | egrep '^codec_type=|^r_frame_rate=' | egrep -A1 '^codec_type=video' | awk -F'=' '/^r_frame_rate=/{print $2}' | sed 's|/| |')"
A_FPS="$(echo "${R_FPS}" | wc -w)"
if [ "${A_FPS}" -gt 1 ] ; then
	R_FPS="$(echo "${R_FPS}" | awk '{print $1 / $2}')"
fi
#------------------------------------------------------------------------------#
### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt
#
# leider kann das z.Z. nur mit "mediainfo" einfach und zuverlässig ermittelt werden
# mit "ffprobe" ist es etwas komplizierter...
#
MEDIAINFO="$(mediainfo --BOM -f "${FILMDATEI}" 2>/dev/null)"
#echo "MEDIAINFO='${MEDIAINFO}'"

SCAN_TYPE="$(echo "${MEDIAINFO}" | grep -Fv pixels | awk -F':' '/Scan type[ ]+/{print $2}' | tr -s ' ' '\n' | egrep -v '^$' | head -n1)"
echo "SCAN_TYPE='${SCAN_TYPE}'"
if [ "${SCAN_TYPE}" != "Progressive" ] ; then
        ### wenn der Film im Zeilensprungverfahren vorliegt
        ZEILENSPRUNG="yadif,"
fi

#exit 17

# FFPROBE=' 720x576 SAR 64:45 DAR 16:9 25 fps '
# FFPROBE=" 852x480 SAR 1:1 DAR 71:40 25 fps "
# FFPROBE=' 1920x800 SAR 1:1 DAR 12:5 23.98 fps '
IN_XY="$(echo "${FFPROBE}" | fgrep ' DAR ' | awk '{print $1}')"
IN_BREIT="$(echo "${IN_XY}" | awk -F'x' '{print $1}')"
IN_HOCH="$(echo  "${IN_XY}" | awk -F'x' '{print $2}')"
IN_PAR="$(echo "${FFPROBE}" | fgrep ' DAR ' | awk '{print $3}')"
IN_DAR="$(echo "${FFPROBE}" | fgrep ' DAR ' | awk '{print $5}')"
IN_FPS="$(echo "${FFPROBE}" | fgrep ' DAR ' | awk '{print $6}')"	# wird benötigt um den Farbraum für BluRay zu ermitteln
IN_FPS_RUND="$(echo "${IN_FPS}" | awk '{printf "%.0f\n", $1}')"			# für Vergleiche, "if" erwartet einen Integerwert
IN_BITRATE="$(echo "${MEDIAINFO}" | sed -ne '/^Video$/,/^$/ p' | egrep '^Bit rate' | awk -F':' '{print $2}' | sed 's/[ ]*//g;s/[a-zA-Z/][a-zA-Z/]*$/ &/' | tail -n1)"
IN_BIT_EINH="$(echo "${IN_BITRATE}" | awk '{print $2}')"

if [ "${IN_BIT_EINH}" = "kb/s" ] ; then
	IN_BIT_RATE="$(echo "${IN_BITRATE}" | awk '{print $1}')"
elif [ "${IN_BIT_EINH}" = "Mb/s" ] ; then
	IN_BIT_RATE="$(echo "${IN_BITRATE}" | awk '{print $1 * 1024}')"
else
	unset IN_BIT_RATE
	BILDQUALIT="5"
	TONQUALIT="5"
fi
unset IN_BITRATE
unset IN_BIT_EINH

M_INFOS="
IN_XY='${IN_XY}'
IN_BREIT='${IN_BREIT}'
IN_HOCH='${IN_HOCH}'
IN_PAR='${IN_PAR}'
IN_DAR='${IN_DAR}'
IN_FPS='${IN_FPS}'
IN_FPS_RUND='${IN_FPS_RUND}'
IN_BITRATE='${IN_BITRATE}'
IN_BIT_RATE='${IN_BIT_RATE}'
IN_BIT_EINH='${IN_BIT_EINH}'
BILDQUALIT='${BILDQUALIT}'
TONQUALIT='${TONQUALIT}'
"
echo "${M_INFOS}"


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


### wenn die Pixel bereits quadratisch sind
if [ "${PAR_FAKTOR}" -ne "100000" ] ; then

	### Umrechnung in quadratische Pixel - Version 1
	#QUADR_SCALE="scale=$(echo "${DAR_KOMMA} ${IN_BREIT} ${IN_HOCH}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$1/2}' | awk '{print $1*2"x"$2*2}'),"
	#QUADR_SCALE="scale=$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$3/2}' | awk '{print $1*2"x"$2*2}'),"

	### Umrechnung in quadratische Pixel - Version 2
	#HALBE_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{h=sqrt($1*$2/$3); printf "%.0f\n", h/2}')"
	#QUADR_SCALE="scale=$(echo "${HALBE_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk '{print $1*2"x"$2*2}'),"
	#
	### [swscaler @ 0x81520d000] Warning: data is not aligned! This can lead to a speed loss
	### laut Googel müssen die Pixel durch 16 teilbar sein, beseitigt aber leider dieses Problem nicht
	#
	### die Pixel sollten wenigstens durch 2 teilbar sein! besser aber durch 8                          
	#TEILER="2"
	#TEILER="4"
	TEILER="8"
	#TEILER="16"
	TEIL_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA} ${TEILER}" | awk '{h=sqrt($1*$2/$3); printf "%.0f\n", h/$4}')"
	QUADR_SCALE="scale=$(echo "${TEIL_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk -v teiler="${TEILER}" '{print $1*teiler"x"$2*teiler}'),"

	QUADR_BREIT="$(echo "${QUADR_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $1}')"
	QUADR_HOCH="$(echo "${QUADR_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $2}')"
else
	QUADR_BREIT="${IN_BREIT}"
	QUADR_HOCH="${IN_HOCH}"
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
# SCHWARZ="$(echo "${HOEHE} ${BREITE} ${QUADR_BREIT} ${QUADR_HOCH}" | awk '{sw="oben"; if (($1/$2) < ($3/$4)) sw="oben"; print sw}')"
# SCHWARZ="$(echo "${HOEHE} ${BREITE} ${QUADR_BREIT} ${QUADR_HOCH}" | awk '{sw="oben"; if (($1/$2) > ($3/$4)) sw="links"; print sw}')"
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
#exit 23

#------------------------------------------------------------------------------#
### quadratische Bildpunkte sind der Standard

FORMAT_ANPASSUNG="setsar='1/1'"


#==============================================================================#
#==============================================================================#
# Das Video-Format wird nach der Dateiendung ermittelt
# deshalb muss ermittelt werden, welche Dateiendung der Name der Ziel-Datei hat
#
# Wenn der Name der Quell-Datei und der Name der Ziel-Datei gleich sind,
# dann wird dem Namen der Ziel-Datei ein "Nr2" vor der Endung angehängt
#

QUELL_BASIS_NAME="$(echo "${QUELL_DATEI}" | awk '{print tolower($0)}')"
ZIEL_BASIS_NAME="$(echo "${ZIELDATEI}" | awk '{print tolower($0)}')"

ZIELNAME="$(echo "${ZIELDATEI}" | rev | sed 's/[ ][ ]*/_/g;s/.*[.]//' | rev)"
ENDUNG="$(echo "${ZIEL_BASIS_NAME}" | rev | sed 's/[a-zA-Z0-9\_\-\+/][a-zA-Z0-9\_\-\+/]*[.]/&"/;s/[.]".*//' | rev)"

if [ "${QUELL_BASIS_NAME}" = "${ZIEL_BASIS_NAME}" ] ; then
	ZIELNAME="${ZIELNAME}_Nr2"
fi

#------------------------------------------------------------------------------#
### ab hier kann in die Log-Datei geschrieben werden

#rm -f ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
echo "# $(date +'%F %T')
${0} ${Film2Standardformat_OPTIONEN}" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt

echo "
${FORMAT_BESCHREIBUNG}
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt

echo "${M_INFOS}
PAR_FAKTOR='${PAR_FAKTOR}'
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt

#------------------------------------------------------------------------------#

if [ -r ${AVERZ}/Filmwandler_Format_${ENDUNG}.txt ] ; then

	OP_QUELLE="1"

#echo "IN_FPS='${IN_FPS}'"
#exit 24
. ${AVERZ}/Filmwandler_Format_${ENDUNG}.txt

else
	OP_QUELLE="2"

	# wenn die gewünschte Formatdatei nicht gelesen werden kann, dann wird ein MP4 gebaut
	ENDUNG="mp4"
	FORMAT="mp4"


	# Audio
	AUDIOCODEC="$(ffmpeg -formats 2>&1 | tr -s ' ' '\n' | egrep -v '[A-Z]' | egrep '[-][-]enable[-]' | sed 's/^[-]*enable[-]*//' | fgrep aac | tr -s '-' '_' | head -n1)"
	if [ "x${AUDIOCODEC}" = "x" ] ; then
		AUDIOCODEC="aac"
	fi

	if [ "${AUDIOCODEC}" = "libfdk_aac" ] ; then
		### 2018-07-15: [libfdk_aac @ 0x813af3900] Note, the VBR setting is unsupported and only works with some parameter combinations
		### https://trac.ffmpeg.org/wiki/Encode/HighQualityAudio
		### http://wiki.hydrogenaud.io/index.php?title=Fraunhofer_FDK_AAC#Audio_Object_Types
		### http://wiki.hydrogenaud.io/index.php?title=Fraunhofer_FDK_AAC#Usage.2FExamples
		#AUDIO_OPTION="-profile:a aac_he"
		#AUDIO_OPTION="-profile:a aac_he_v2"
		AUDIO_QUALITAET_0="-vbr 1"					# 1 bis 5, 4 empfohlen / Constant (CBR): ~ 184 kb/s
		AUDIO_QUALITAET_1="-vbr 2"					# 1 bis 5, 4 empfohlen / Constant (CBR): ~ 201 kb/s
		AUDIO_QUALITAET_2="-vbr 3"					# 1 bis 5, 4 empfohlen / Constant (CBR): ~ 235 kb/s
		AUDIO_QUALITAET_3="-vbr 4"					# 1 bis 5, 4 empfohlen / Constant (CBR): ~ 288 kb/s
		AUDIO_QUALITAET_4="-vbr 4"					# 1 bis 5, 4 empfohlen / Constant (CBR): ~ 288 kb/s
		AUDIO_QUALITAET_5="-vbr 4"					# 1 bis 5, 4 empfohlen / Constant (CBR): ~ 288 kb/s
		AUDIO_QUALITAET_6="-vbr 5"					# 1 bis 5, 4 empfohlen / Constant (CBR): ~ 427 kb/s
		AUDIO_QUALITAET_7="-vbr 5"					# 1 bis 5, 4 empfohlen / Constant (CBR): ~ 427 kb/s
		AUDIO_QUALITAET_8="-vbr 5"					# 1 bis 5, 4 empfohlen / Constant (CBR): ~ 427 kb/s
		AUDIO_QUALITAET_9="-vbr 5"					# 1 bis 5, 4 empfohlen / Constant (CBR): ~ 427 kb/s
	else
		# https://slhck.info/video/2017/02/24/vbr-settings.html
		# undokumentiert (0.1-?) -> "-q:a 0.12" ~ 128k
		# August 2018: viel zu schlechte Qualität!
		# er bei "-q:a" nimmt immer: "Stream #0:1(und): Audio: aac (LC) (mp4a / 0x6134706D), 48000 Hz, 5.1, fltp, 341 kb/s (default)"
		if [ "${AUDIO_KANAELE}" -gt 2 ] ; then
			AUDIO_QUALITAET_0="-b:a 160k"
			AUDIO_QUALITAET_1="-b:a 184k"
			AUDIO_QUALITAET_2="-b:a 216k"
			AUDIO_QUALITAET_3="-b:a 256k"
			AUDIO_QUALITAET_4="-b:a 296k"
			AUDIO_QUALITAET_5="-b:a 344k"
			AUDIO_QUALITAET_6="-b:a 400k"
			AUDIO_QUALITAET_7="-b:a 472k"
			AUDIO_QUALITAET_8="-b:a 552k"
			AUDIO_QUALITAET_9="-b:a 640k"
		else
			AUDIO_QUALITAET_0="-b:a 64k"
			AUDIO_QUALITAET_1="-b:a 80k"
			AUDIO_QUALITAET_2="-b:a 88k"
			AUDIO_QUALITAET_3="-b:a 112k"
			AUDIO_QUALITAET_4="-b:a 128k"
			AUDIO_QUALITAET_5="-b:a 160k"
			AUDIO_QUALITAET_6="-b:a 184k"
			AUDIO_QUALITAET_7="-b:a 224k"
			AUDIO_QUALITAET_8="-b:a 264k"
			AUDIO_QUALITAET_9="-b:a 320k"
		fi
	fi


	# Video
	CODEC_PATTERN="x264"		# Beispiel: "h264|x264" (libopenh264, libx264)
	VIDEOCODEC="$(echo "${FFMPEG_LIB}" | fgrep "${CODEC_PATTERN}" | head -n1)"
	if [ "x${VIDEOCODEC}" = "x" ] ; then
		VIDEOCODEC="$(echo "${FFMPEG_FORMATS}" | fgrep "${CODEC_PATTERN}" | head -n1)"
		if [ "x${VIDEOCODEC}" = "x" ] ; then
			echo ""
			echo "${CODEC_PATTERN}"
			echo "Leider wird dieser Codec von der aktuell installierten Version"
			echo "von FFmpeg nicht unterstützt!"
			echo ""
			exit 1
		fi
	fi


	VIDEO_QUALITAET_0="-preset veryslow -crf 30 -tune film"		# von "0" (verlustfrei) bis "51"
	VIDEO_QUALITAET_1="-preset veryslow -crf 28 -tune film"		# von "0" (verlustfrei) bis "51"
	VIDEO_QUALITAET_2="-preset veryslow -crf 26 -tune film"		# von "0" (verlustfrei) bis "51"
	VIDEO_QUALITAET_3="-preset veryslow -crf 24 -tune film"		# von "0" (verlustfrei) bis "51"
	VIDEO_QUALITAET_4="-preset veryslow -crf 22 -tune film"		# von "0" (verlustfrei) bis "51"
	VIDEO_QUALITAET_5="-preset veryslow -crf 20 -tune film"		# von "0" (verlustfrei) bis "51"
	VIDEO_QUALITAET_6="-preset veryslow -crf 19 -tune film"		# von "0" (verlustfrei) bis "51"
	VIDEO_QUALITAET_7="-preset veryslow -crf 18 -tune film"		# von "0" (verlustfrei) bis "51"
	VIDEO_QUALITAET_8="-preset veryslow -crf 17 -tune film"		# von "0" (verlustfrei) bis "51"
	VIDEO_QUALITAET_9="-preset veryslow -crf 16 -tune film"		# von "0" (verlustfrei) bis "51"
	IFRAME="-keyint_min 2-8"

	### Bluray-kompatibele Werte errechnen
	. ${AVERZ}/Filmwandler_-_Blu-ray-Disc_-_AVC.txt


FORMAT_BESCHREIBUNG="
********************************************************************************
* Name:			MP4                                                    *
* ENDUNG:		.mp4                                                   *
* Video-Kodierung:	H.264 (MPEG-4 Part 10 / AVC)                           *
* Audio-Kodierung:	AAC       (mehrkanalfähiger Nachfolger von MP3)        *
* Beschreibung:                                                                *
*	- HTML5-Unterstützung                                                  *
*	- hohe Kompatibilität mit Konsumerelektronik                           *
*	- auch abspielbar auf Android                                          *
********************************************************************************
"
fi

echo "
OP_QUELLE='${OP_QUELLE}'
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
#exit 25

#==============================================================================#
### Qualität
#
# Qualitäts-Parameter-Übersetzung
# https://slhck.info/video/2017/02/24/vbr-settings.html
#

#------------------------------------------------------------------------------#
### Audio

if [ "${BILDQUALIT}" = "auto" ] ; then
        BILDQUALIT="5"
fi

if [ "${TONQUALIT}" = "auto" ] ; then
        TONQUALIT="5"
fi

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


#------------------------------------------------------------------------------#

echo "
AUDIOCODEC=${AUDIOCODEC}
AUDIOQUALITAET=${AUDIOQUALITAET}

VIDEOCODEC=${VIDEOCODEC}
VIDEOQUALITAET=${VIDEOQUALITAET}
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
#exit 26

#==============================================================================#
# Audio

STREAM_AUDIO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep ' Stream ' | fgrep Audio:)"
STREAMAUDIO="$(echo "${STREAM_AUDIO}" | wc -w | awk '{print $1}')"

if [ "${STREAMAUDIO}" -gt 0 ] ; then
	# soll Stereo-Ausgabe erzwungen werden?
	if [ "x${STEREO}" = x ] ; then
		AUDIO_VERARBEITUNG_01="-map 0:a:${TSNAME} -c:a ${AUDIOCODEC} ${AUDIOQUALITAET}"
	else
		# wurde die Ausgabe bereits durch die Codec-Optionen auf Stereo gesetzt?
		BEREITS_AC2="$(echo "${AUDIOCODEC} ${AUDIOQUALITAET}" | fgrep "ac 2")"
		if [ "x${BEREITS_AC2}" = x ] ; then
			AUDIO_VERARBEITUNG_01="-map 0:a:${TSNAME} -c:a ${AUDIOCODEC} ${AUDIOQUALITAET} ${STEREO}"
		else
			AUDIO_VERARBEITUNG_01="-map 0:a:${TSNAME} -c:a ${AUDIOCODEC} ${AUDIOQUALITAET}"
		fi
	fi
	AUDIO_VERARBEITUNG_02="-c:a copy"
else
	AUDIO_VERARBEITUNG_01="-an"
	AUDIO_VERARBEITUNG_02="-an"
fi

#==============================================================================#
# Video

# vor PAD muss eine Auflösung, die der Originalauflösung entspricht, die aber
# für quadratische Pixel ist (QUADR_SCALE);
# hinter PAD muss dann die endgültig gewünschte Auflösung für quadratische
# Pixel (SOLL_SCALE)
VIDEOOPTION="${VIDEOQUALITAET} -vf ${ZEILENSPRUNG}${CROP}${QUADR_SCALE}${PAD}${SOLL_SCALE}${FORMAT_ANPASSUNG}"
#VIDEOOPTION="${VIDEOQUALITAET} -vf ${ZEILENSPRUNG}${CROP}${PAD}${QUADR_SCALE}${SOLL_SCALE}${FORMAT_ANPASSUNG}"

START_ZIEL_FORMAT="-f ${FORMAT}"

#==============================================================================#

echo "
STREAM_AUDIO=${STREAM_AUDIO}
STREAMAUDIO=${STREAMAUDIO}

AUDIO_VERARBEITUNG_01=${AUDIO_VERARBEITUNG_01}
AUDIO_VERARBEITUNG_02=${AUDIO_VERARBEITUNG_02}

VIDEOOPTION=${VIDEOOPTION}
START_ZIEL_FORMAT=${START_ZIEL_FORMAT}
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
#exit 27


#------------------------------------------------------------------------------#
if [ -z "${SCHNITTZEITEN}" ] ; then

	echo
	echo "1: ${PROGRAMM} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_TAG} -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
	echo
#>
	         ${PROGRAMM} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}"  ${VIDEO_TAG} -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG} 2>&1

else

	#----------------------------------------------------------------------#
	ZUFALL="$(head -c 100 /dev/urandom | base64 | tr -d '\n' | tr -cd '[:alnum:]' | cut -b-12)"
	NUMMER="0"
	for _SCHNITT in ${SCHNITTZEITEN}
	do
		NUMMER="$(echo "${NUMMER}" | awk '{printf "%2.0f\n", $1+1}' | tr -s ' ' '0')"
		VON="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $1}')"
		BIS="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $2}')"

		#
		# Leider können hier die einzelnen Filmteile nicht direkt in das
		# Container-Format Matroska überführt werden.
		#
		# FFmpeg füllt 'Video Format profile' für AVI aus aber für Matroska nicht.
		#
		# Deshalb wird direkt in das Ziel-Container-Format (ggf. AVI) transkodiert
		# und zum zusammenbauen wird es zwischenzeitlich in das Container-Format
		# Matroska überführt.
		#

		echo
		echo "2: ${PROGRAMM} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_TAG} -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} -ss ${VON} -to ${BIS} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG}" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
		echo
#>
		         ${PROGRAMM} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}"  ${VIDEO_TAG} -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} -ss ${VON} -to ${BIS} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG} 2>&1

		ffmpeg -i ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG} -c:v copy -c:a copy ${U_TITEL_MKV} -f matroska -y ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.mkv && rm -f ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG}

		echo "---------------------------------------------------------"
	done

	FILM_TEILE="$(ls -1 ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv | tr -s '\n' '|' | sed 's/|/ + /g;s/ + $//')"
	echo "3: mkvmerge -o '${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv' '${FILM_TEILE}'"
#>
	mkvmerge -o ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv ${FILM_TEILE}

	# den vertigen Film aus dem MKV-Format in das MP$-Format umwandeln
	echo "4: ${PROGRAMM} ${REPARATUR_PARAMETER} -i ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv ${VIDEO_TAG} -c:v copy ${AUDIO_VERARBEITUNG_02} ${U_TITEL_MKV} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}"
#>
	         ${PROGRAMM} ${REPARATUR_PARAMETER} -i ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv ${VIDEO_TAG} -c:v copy ${AUDIO_VERARBEITUNG_02} ${U_TITEL_MKV} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}

	#ls -lh ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv
	#echo "rm -f ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv"
	rm -f ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv

fi
#------------------------------------------------------------------------------#

echo "
5: ${PROGRAMM} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_TAG} -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} -map 0:a:${TSNAME} -c:a ${AUDIOCODEC} ${AUDIOQUALITAET} ${STEREO} ${UNTERTITEL} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}
"
#------------------------------------------------------------------------------#

ls -lh ${ZIELVERZ}/${ZIELNAME}.${ENDUNG} ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
LAUFZEIT="$(echo "${STARTZEITPUNKT} $(date +'%s')" | awk '{print $2 - $1}')"
echo "# $(date +'%F %T') (${LAUFZEIT})" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
#exit 28
