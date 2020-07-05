#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Dieses Skript verändert NICHT die Bildwiederholrate!
#
# Das Ergebnis besteht immer aus folgendem Format:
#  - MKV:     mkv    + VP9        + Opus (mit Untertitel)
#  - WebM:    webm   + VP9        + Opus (ohne Untertitel)
#  - MP4:     mp4    + H.264/AVC  + AAC
#  - AVCHD:   m2ts   + H.264/AVC  + AC3
#  - AVI:     avi    + DivX5      + MP3
#  - FLV:     flv    + FLV        + MP3     (Sorenson Spark: H.263)
#  - 3GPP:    3gp    + H.263      + AAC     (128x96 176x144 352x288 704x576 1408x1152)
#  - 3GPP2:   3g2    + H.263      + AAC
#  - OGG:     ogg    + Theora     + Vorbis
#  - MPEG:    mpg/ts + MPEG-1/2   + MP2/AC3 (bei kleinen Bitraten ist MPEG-1 besser)
#
# WebM kann leider nur das eine Untertitelformat "WebVTT"
#
# https://de.wikipedia.org/wiki/Containerformat
#
# Es werden folgende Programme von diesem Skript verwendet:
#  - ffmpeg
#  - ffprobe
#
#------------------------------------------------------------------------------#


#VERSION="v2017102900"			# 4. Generation gestartet
#VERSION="v2019082800"			# Entwicklung an der 4. Generation eingestellt
#VERSION="v2019092100"			# 5. Generation gestartet
#VERSION="v2019092300"			# erstmals funktioniert jetzt die Formatumrechnung mit nicht quadratischen Bildpunkten
#VERSION="v2019092500"			# Dateinamen mit Leerzeichen (eine Unsitte) werden jetzt richtig behandelt
#VERSION="v2019102900"
#VERSION="v2019121900"			# Fehler ab Zeile 821 behoben
#VERSION="v2020031300"			# Hilfe erweitert
#VERSION="v2020040800"			# jetzt wird beim X*Y-Format auch die Rotation berücksichtigt
#VERSION="v2020050300"			# jetzt gibt es auch eine Option, durch die man das Normalisieren auf 4:3 bzw. 16:9 verhindern kann
#VERSION="v2020060200"			# Dateinamen können jetzt auch Punkte enthalten
#VERSION="v2020061000"			# VIDEO_TAG wurde doppelt verwendet
#VERSION="v2020061100"			# in Zeile 1117 einen Work-Around für Bit-Rate bei Tonspuren eingesetzt
VERSION="v2020070500"			# soll_xmaly wurde alsch behandelt


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
IFRAME="-keyint_min 2-8"		# --keyint in Frames
#IFRAME="-g 1"				# -g in Sekunden

LANG=C					# damit AWK richtig rechnet
Film2Standardformat_OPTIONEN="${@}"
ORIGINAL_PIXEL="Nein"
STOP="Nein"

AVERZ="$(dirname ${0})"			# Arbeitsverzeichnis, hier liegen diese Dateien

#==============================================================================#
### Funktionen

# einbinden der Namen von vielen Bildauflösungen
BILDAUFLOESUNGEN_NAMEN="${AVERZ}/Filmwandler_grafik.txt"
if [ -r "${BILDAUFLOESUNGEN_NAMEN}" ] ; then
	. ${BILDAUFLOESUNGEN_NAMEN}
	BILD_FORMATNAMEN_AUFLOESUNGEN="$(bildaufloesungen_namen)"
fi


ausgabe_hilfe()
{
echo "# 10
#==============================================================================#
"
egrep -h '^[*][* ]' ${AVERZ}/Filmwandler_Format_*.txt
echo "# 20
#==============================================================================#
"
}


#==============================================================================#

if [ "x${1}" = x ] ; then
        ${0} -h
	exit 30
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
                -orig_dar)
			ORIGINAL_DAR="${2}"	# das originale Seitenverhältnis soll beibehalten werden
                        shift
                        ;;
                -fps|-soll_fps)
                        SOLL_FPS="${2}"		# FPS (Bilder pro Sekunde) für den neuen Film festlegen
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
                        # Wirddiese Option nicht verwendet, dann werden ALLE Tonspuren eingebettet
                        # "0" für die erste Tonspur
                        # "1" für die zweite Tonspur
                        # "0,1" für die erste und die zweite Tonspur
                        TONSPUR="${2}"		# -ton 0,1,2,3,4
                        shift
                        ;;
                -stereo)
                        STEREO="Ja"
                        #STEREO="-ac 2"		# Stereo-Ausgabe erzwingen
			# Stereo-Ausgabe erzwingen 
                        # 5.1 mischen auf algorithmus von Dave_750 
                        # hier werden die tiefbass spur (LFE) mit abgemischt
                        # das trifft bei -ac 2 nicht zu (ATSC standards)
                        # -ac 2 als filter:
                        # -af "pan=stereo|FL < 1.0*FL + 0.707*FC + 0.707*BL|FR < 1.0*FR + 0.707*FC + 0.707*BR"
                        # Quelle: https://superuser.com/questions/852400/properly-downmix-5-1-to-stereo-using-ffmpeg/1410620#1410620
                        #STEREO="-filter_complex pan='stereo|FL=0.5*FC+0.707*FL+0.707*BL+0.5*LFE|FR=0.5*FC+0.707*FR+0.707*BR+0.5*LFE',volume='1.562500'"
                        # NighMode 
                        # The Nightmode Dialogue formula, created by Robert Collier on the Doom9 forum and sourced by Shane Harrelson in his answer, 
                        # results in a far better downmix than the ac -2 switch - instead of overly quiet dialogues, it brings them back to levels that are much closer to the source.
                        #STEREO="-filter_complex pan='stereo|FL=FC+0.30*FL+0.30*BL|FR=FC+0.30*FR+0.30*BR'"
                        shift
                        ;;
                -schnitt)
			SCHNITTZEITEN="$(echo "${2}" | sed 's/,/ /g')"	# zum Beispiel zum Werbung entfernen (in Sekunden, Dezimaltrennzeichen ist der Punkt): -schnitt 10-432,520-833,1050-1280
                        shift
                        ;;
                -test|-t)
                        ORIGINAL_PIXEL="Ja"	# um die richtigen CROP-Parameter zu ermitteln
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
                        ;;
                -g)
			echo "${BILD_FORMATNAMEN_AUFLOESUNGEN}"
                        exit 40
                        ;;
                -h)
			#ausgabe_hilfe
                        echo "HILFE:
        # Video- und Audio-Spur in ein HTML5-kompatibles Format transkodieren

        # grundsaetzlich ist der Aufbau wie folgt,
        # die Reihenfolge der Optionen ist unwichtig
        ${0} [Option] -q [Filmname] -z [Neuer_Filmname.mp4]
        ${0} -q [Filmname] -z [Neuer_Filmname.mp4] [Option]

        # ein Beispiel mit minimaler Anzahl an Parametern
        ${0} -q Film.avi -z Film.mp4

        # ein Beispiel, bei dem die erste Untertitelspur (Zählweise beginnt mit '0'!) übernommen wird
        ${0} -q Film.avi -u 0 -z Film.mp4
        # ein Beispiel, bei dem die zweite Untertitelspur übernommen wird
        ${0} -q Film.avi -u 1 -z Film.mp4
        # ein Beispiel, bei dem die erste und die zweite Untertitelspur übernommen werden
        ${0} -q Film.avi -u 0,1 -z Film.mp4

        # Es duerfen in den Dateinamen keine Leerzeichen, Sonderzeichen
        # oder Klammern enthalten sein!
        # Leerzeichen kann aber innerhalb von Klammer trotzdem verwenden
        ${0} -q \"Filmname mit Leerzeichen.avi\" -z Film.mp4

        # wenn der Film mehrer Tonspuren besitzt
        # und nicht die erste verwendet werden soll,
        # dann wird so die 2. Tonspur angegeben (die Zaehlweise beginnt mit 0)
        -ton 1

        # so wird die 1. Tonspur angegeben (die Zaehlweise beginnt mit 0)
        -ton 0

        # so wird so die 3. und 4. Untertitelspur angegeben (die Zaehlweise beginnt mit 0)
        -u 2,3

        # so wird Untertitel komplett abgeschaltet
        -u =0

        # so wird so die 3. und 4. Untertitelspur angegeben (die Zaehlweise beginnt mit 0)
        -u 2,3

	# Stereo-Ausgabe erzwingen
	# egal wieviele Audio-Kanäle der Originalfilm hat, der neue Film wird Stereo haben
	-stereo

        # Bildwiederholrate für den neuen Film festlegen,
        # manche Geräte können nur eine begrenzte Zahl an Bildern pro Sekunde (FPS)
        -soll_fps 15
        -fps 20

        # wenn die Bildaufloesung des Originalfilmes nicht automatisch ermittelt
        # werden kann, dann muss sie manuell als Parameter uebergeben werden
        -ist_xmaly 480x270
        -in_xmaly 480x270

        # wenn das Bildformat des Originalfilmes nicht automatisch ermittelt
        # werden kann, dann muss es manuell als Parameter uebergeben werden
        -dar 16:9
        -ist_dar 16:9

        # wenn diese Option einen beliebigen Wert (auch "nein") bekommt,
	# dann wird das originale Seitenverhältnis beibehalten
        -orig_dar ja

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
        -schnitt 8.5-432,520-833.5,1050-1280

        # will man z.B. von einem 4/3-Film, der als 16/9-Film (720x576)
        # mit schwarzen Balken an den Seiten, diese schwarzen Balken entfernen,
        # dann könnte das zum Beispiel so gemacht werden:
        -crop 540:576:90:0

        # die gewünschte Bildauflösung des neuen Filmes
        -soll_xmaly 720x576		# deutscher Parametername
        -out_xmaly 720x480		# englischer Parametername
        -soll_xmaly 965x543		# frei wählbares Bildformat kann angegeben werden
        -soll_xmaly VCD			# Name eines Bildformates kann angegeben werden

	mögliche Namen von Grafikauflösungen anzeigen
	=> ${0} -g
                        "
                        exit 50
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
if [ "x${PROGRAMM}" = "x" ] ; then
	PROGRAMM="$(which avconv)"
fi

if [ "x${PROGRAMM}" = "x" ] ; then
	echo "Weder avconv noch ffmpeg konnten gefunden werden. Abbruch!"
	exit 60
fi

#==============================================================================#
### Trivialitäts-Check

if [ "${STOP}" = "Ja" ] ; then
        echo "Bitte korrigieren sie die falschen Parameter. Abbruch!"
        exit 70
fi

#------------------------------------------------------------------------------#

if [ "${BILDQUALIT}" = "auto" ] ; then
        BILDQUALIT="5"
fi

if [ "${TONQUALIT}" = "auto" ] ; then
        TONQUALIT="5"
fi

#------------------------------------------------------------------------------#

if [ ! -r "${FILMDATEI}" ] ; then
        echo "Der Film '${FILMDATEI}' konnte nicht gefunden werden. Abbruch!"
        exit 80
fi

#------------------------------------------------------------------------------#
# damit die Zieldatei mit Verzeichnis angegeben werden kann

QUELL_DATEI="$(basename "${FILMDATEI}")"
ZIELVERZ="$(dirname "${ZIELPFAD}")"
ZIELDATEI="$(basename "${ZIELPFAD}")"

#------------------------------------------------------------------------------#
# damit keine Leerzeichen im Dateinamen enthalten sind

ZIELDATEI="$(echo "${ZIELDATEI}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"."$2}')"

#==============================================================================#
# Das Video-Format wird nach der Dateiendung ermittelt
# deshalb muss ermittelt werden, welche Dateiendung der Name der Ziel-Datei hat
#
# Wenn der Name der Quell-Datei und der Name der Ziel-Datei gleich sind,
# dann wird dem Namen der Ziel-Datei ein "Nr2" vor der Endung angehängt
#

QUELL_BASIS_NAME="$(echo "${QUELL_DATEI}" | awk '{print tolower($0)}')"
ZIEL_BASIS_NAME="$(echo "${ZIELDATEI}" | awk '{print tolower($0)}')"

ZIELNAME="$(echo "${ZIELDATEI}" | rev | sed 's/[ ][ ]*/_/g;s/[.]/ /' | rev | sed 's/ .*//')"
ENDUNG="$(echo "${ZIEL_BASIS_NAME}" | rev | sed 's/[a-zA-Z0-9\_\-\+/][a-zA-Z0-9\_\-\+/]*[.]/&"/;s/[.]".*//' | rev)"


if [ "${QUELL_BASIS_NAME}" = "${ZIEL_BASIS_NAME}" ] ; then
	ZIELNAME="${ZIELNAME}_Nr2"
fi

#------------------------------------------------------------------------------#
### ab hier kann in die Log-Datei geschrieben werden

PROTOKOLLDATEI="${ZIELVERZ}/${ZIELNAME}.${ENDUNG}"

echo "# $(date +'%F %T')
${0} ${Film2Standardformat_OPTIONEN}" | tee ${PROTOKOLLDATEI}.txt

#------------------------------------------------------------------------------#
### diese Optionen sind für ffprobe und ffmpeg notwendeig,
### damit auch die Spuren gefunden werden, die später als 5 Sekunden nach
### Filmbeginn einsetzen

## -probesize 18446744070G		# I64_MAX
## -analyzeduration 18446744070G	# I64_MAX
#KOMPLETT_DURCHSUCHEN="-probesize 18446744070G -analyzeduration 18446744070G"

## Value 19807040624582983680.000000 for parameter 'analyzeduration' out of range [0 - 9.22337e+18]
## Value 19807040624582983680.000000 for parameter 'analyzeduration' out of range [0 - 9.22337e+18]
## -probesize 9223370Ki
## -analyzeduration 9223370Ki
KOMPLETT_DURCHSUCHEN="-probesize 9223372036G -analyzeduration 9223372036G"

#KOMPLETT_DURCHSUCHEN="-probesize 100M -analyzeduration 100M"

#------------------------------------------------------------------------------#
### Parameter zum reparieren defekter Container

REPARATUR_PARAMETER="-fflags +genpts"

#==============================================================================#
#==============================================================================#
### Video
#
# IN-Daten (META-Daten) aus der Filmdatei lesen
#

#------------------------------------------------------------------------------#
### FFmpeg verwendet drei verschiedene Zeitangaben:
#
# http://ffmpeg-users.933282.n4.nabble.com/What-does-the-output-of-ffmpeg-mean-tbr-tbn-tbc-etc-td941538.html
# http://stackoverflow.com/questions/3199489/meaning-of-ffmpeg-output-tbc-tbn-tbr
# tbn = the time base in AVStream that has come from the container
# tbc = the time base in AVCodecContext for the codec used for a particular stream
# tbr = tbr is guessed from the video stream and is the value users want to see when they look for the video frame rate
#
#------------------------------------------------------------------------------#
### Meta-Daten auslesen

META_DATEN_KOMPLETT="$(ffprobe ${KOMPLETT_DURCHSUCHEN} -show_data -show_streams -i "${FILMDATEI}" 2>&1)"
META_DATEN_INFO="$(echo   "${META_DATEN_KOMPLETT}" | sed -ne '/^Input /,/STREAM/p')"
META_DATEN_STREAM="$(echo "${META_DATEN_KOMPLETT}" | sed -e  '1,/STREAM/d')"
BILD_DREHUNG="$(echo "${META_DATEN_INFO}" | sed -ne '/Video: /,/Audio: / p' | awk '/ rotate /{print $NF}' | head -n1)"

echo "${META_DATEN_INFO}"                                             | tee -a ${PROTOKOLLDATEI}.txt
echo "${META_DATEN_STREAM}" | grep -E '^codec_(name|long_name|type)=' | tee -a ${PROTOKOLLDATEI}.txt

#------------------------------------------------------------------------------#
### hier wird eine Liste externer verfügbarer Codecs erstellt

FFMPEG_LIB="$((ffmpeg -formats >/dev/null) 2>&1 | tr -s ' ' '\n' | egrep '^[-][-]enable[-]' | sed 's/^[-]*enable[-]*//;s/[-]/_/g' | egrep '^lib')"
FFMPEG_FORMATS="$(ffmpeg -formats 2>/dev/null | awk '/^[ \t]*[ ][DE]+[ ]/{print $2}')"

#------------------------------------------------------------------------------#
### alternative Methode zur Ermittlung der FPS
R_FPS="$(echo "${META_DATEN_STREAM}" | egrep '^codec_type=|^r_frame_rate=' | egrep -A1 '^codec_type=video' | awk -F'=' '/^r_frame_rate=/{print $2}' | sed 's|/| |')"
A_FPS="$(echo "${R_FPS}" | wc -w)"
if [ "${A_FPS}" -gt 1 ] ; then
	R_FPS="$(echo "${R_FPS}" | awk '{print $1 / $2}')"
fi
#------------------------------------------------------------------------------#
### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt

# tbn (FPS vom Container)            = the time base in AVStream that has come from the container
# tbc (FPS vom Codec)                = the time base in AVCodecContext for the codec used for a particular stream
# tbr (FPS vom Video-Stream geraten) = tbr is guessed from the video stream and is the value users want to see when they look for the video frame rate

SCAN_TYPE="$(echo "${META_DATEN_STREAM}" | awk '/^field_order=/{print $2}' | grep -Ev '^$' | head -n1)"
echo "SCAN_TYPE='${SCAN_TYPE}'"
if [ "${SCAN_TYPE}" != "progressive" ] ; then
        ### wenn der Film im Zeilensprungverfahren vorliegt
        ZEILENSPRUNG="yadif,"
fi

#exit 90

# META_DATEN_STREAM=" width=720 "
# META_DATEN_STREAM=" height=576 "
IN_BREIT="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^width=/{print $2}' | grep -Fv 'N/A' | head -n1)"
IN_HOCH="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^height=/{print $2}' | grep -Fv 'N/A' | head -n1)"
IN_XY="${IN_BREIT}x${IN_HOCH}"
echo "# 100
1 IN_XY='${IN_XY}'
1 IN_BREIT='${IN_BREIT}'
1 IN_HOCH='${IN_HOCH}'
" | tee -a ${PROTOKOLLDATEI}.txt
if [ "${IN_XY}" = "x" ] ; then
	# META_DATEN_INFO=' 720x576 SAR 64:45 DAR 16:9 25 fps '
	# META_DATEN_INFO=" 852x480 SAR 1:1 DAR 71:40 25 fps "
	# META_DATEN_INFO=' 1920x800 SAR 1:1 DAR 12:5 23.98 fps '
	IN_XY="$(echo "${META_DATEN_INFO}" | fgrep 'Video: ' | tr -s ',' '\n' | fgrep ' DAR ' | awk '{print $1}' | head -n1)"
	echo "# 110
	2 IN_XY='${IN_XY}'
	2 IN_BREIT='${IN_BREIT}'
	2 IN_HOCH='${IN_HOCH}'
	" | tee -a ${PROTOKOLLDATEI}.txt
	if [ "x${IN_XY}" = "x" ] ; then
		# META_DATEN_STREAM=" coded_width=0 "
		# META_DATEN_STREAM=" coded_height=0 "
		IN_BREIT="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^coded_width=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
		IN_HOCH="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^coded_height=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
		IN_XY="${IN_BREIT}x${IN_HOCH}"
		echo "# 120
		3 IN_XY='${IN_XY}'
		3 IN_BREIT='${IN_BREIT}'
		3 IN_HOCH='${IN_HOCH}'
		" | tee -a ${PROTOKOLLDATEI}.txt
	fi
	if [ "x${BILD_DREHUNG}" != x ] ; then
		if [ "${BILD_DREHUNG}" = 90 ] ; then
			IN_XY="$(echo "${IN_XY}" | awk -F'x' '{print $2"x"$1}')"
		elif [ "${BILD_DREHUNG}" = 270 ] ; then
			IN_XY="$(echo "${IN_XY}" | awk -F'x' '{print $2"x"$1}')"
		fi
	fi
	IN_BREIT="$(echo "${IN_XY}" | awk -F'x' '{print $1}')"
	IN_HOCH="$(echo  "${IN_XY}" | awk -F'x' '{print $2}')"
fi

IN_PAR="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^sample_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "# 130
1 IN_PAR='${IN_PAR}'
" | tee -a ${PROTOKOLLDATEI}.txt
if [ "x${IN_PAR}" = "x" ] ; then
	IN_PAR="$(echo "${META_DATEN_INFO}" | fgrep 'Video: ' | tr -s ',' '\n' | fgrep ' DAR ' | tr -s '[\[\]]' ' ' | awk '{print $3}')"
	echo "# 140
	2 IN_PAR='${IN_PAR}'
	" | tee -a ${PROTOKOLLDATEI}.txt
fi

IN_DAR="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^display_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "# 150
1 IN_DAR='${IN_DAR}'
" | tee -a ${PROTOKOLLDATEI}.txt
if [ "x${IN_DAR}" = "x" ] ; then
	IN_DAR="$(echo "${META_DATEN_INFO}" | fgrep 'Video: ' | tr -s ',' '\n' | fgrep ' DAR ' | tr -s '[\[\]]' ' ' | awk '{print $5}')"
	echo "# 160
	2 IN_DAR='${IN_DAR}'
	" | tee -a ${PROTOKOLLDATEI}.txt
fi

# META_DATEN_STREAM=" r_frame_rate=25/1 "
# META_DATEN_STREAM=" avg_frame_rate=25/1 "
# META_DATEN_STREAM=" codec_time_base=1/25 "
IN_FPS="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^r_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1}')"
echo "# 170
1 IN_FPS='${IN_FPS}'
" | tee -a ${PROTOKOLLDATEI}.txt
if [ "x${IN_FPS}" = "x" ] ; then
	IN_FPS="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^avg_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1}')"
	echo "# 180
	2 IN_FPS='${IN_FPS}'
	" | tee -a ${PROTOKOLLDATEI}.txt
	if [ "x${IN_FPS}" = "x" ] ; then
		IN_FPS="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^codec_time_base=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $2}')"
		echo "# 190
		3 IN_FPS='${IN_FPS}'
		" | tee -a ${PROTOKOLLDATEI}.txt
		if [ "x${IN_FPS}" = "x" ] ; then
			IN_FPS="$(echo "${META_DATEN_INFO}" | fgrep 'Video: ' | tr -s ',' '\n' | fgrep ' fps' | awk '{print $1}')"			# wird benötigt um den Farbraum für BluRay zu ermitteln
			echo "# 200
			4 IN_FPS='${IN_FPS}'
			" | tee -a ${PROTOKOLLDATEI}.txt
		fi
	fi
fi

IN_FPS_RUND="$(echo "${IN_FPS}" | awk '{printf "%.0f\n", $1}')"			# für Vergleiche, "if" erwartet einen Integerwert

IN_BIT_RATE="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^bit_rate=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "# 210
1 IN_BIT_RATE='${IN_BIT_RATE}'
" | tee -a ${PROTOKOLLDATEI}.txt
if [ "x${IN_BIT_RATE}" = "x" ] ; then
	IN_BIT_RATE="$(echo "${META_DATEN_INFO}" | grep -F 'Video: ' | tr -s ',' '\n' | awk -F':' '/bitrate: /{print $2}' | tail -n1)"
	echo "# 220
	2 IN_BIT_RATE='${IN_BIT_RATE}'
	" | tee -a ${PROTOKOLLDATEI}.txt
	if [ "x${IN_BIT_RATE}" = "x" ] ; then
		IN_BIT_RATE="$(echo "${META_DATEN_INFO}" | grep -F 'Duration: ' | tr -s ',' '\n' | awk -F':' '/bitrate: /{print $2}' | tail -n1)"
		echo "# 230
		3 IN_BIT_RATE='${IN_BIT_RATE}'
		" | tee -a ${PROTOKOLLDATEI}.txt
	fi
fi

IN_BIT_EINH="$(echo "${IN_BIT_RATE}" | awk '{print $2}')"
case "${IN_BIT_EINH}" in
        [Kk]b[p/]s|[Kk]b[/]s)
                        IN_BITRATE_KB="$(echo "${IN_BIT_RATE}" | awk '{print $1}')"
                        ;;
        [Mm]b[p/]s|[Mm]b[/]s)
                        IN_BITRATE_KB="$(echo "${IN_BIT_RATE}" | awk '{print $1 * 1024}')"
                        ;;
esac

echo "# 240
IN_XY='${IN_XY}'
IN_BREIT='${IN_BREIT}'
IN_HOCH='${IN_HOCH}'
IN_PAR='${IN_PAR}'
IN_DAR='${IN_DAR}'
IN_FPS='${IN_FPS}'
IN_FPS_RUND='${IN_FPS_RUND}'
IN_BIT_RATE='${IN_BIT_RATE}'
IN_BIT_EINH='${IN_BIT_EINH}'
IN_BITRATE_KB='${IN_BITRATE_KB}'
BILDQUALIT='${BILDQUALIT}'
TONQUALIT='${TONQUALIT}'
" | tee -a ${PROTOKOLLDATEI}.txt

unset IN_BIT_RATE
unset IN_BIT_EINH

#exit 250

#==============================================================================#
#==============================================================================#
# Audio

if [ "x${TONSPUR}" = "x" ] ; then
        TSNAME="$(echo "${META_DATEN_STREAM}" | fgrep -i codec_type=audio | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
else
	TSNAME="${TONSPUR}"
fi

TS_LISTE="$(echo "${TSNAME}" | sed 's/,/ /g')"
TS_ANZAHL="$(echo "${TSNAME}" | sed 's/,/ /g' | wc -w | awk '{print $1}')"

AUDIO_KANAL_INFOS="$(echo "${META_DATEN_STREAM}" | tr -s '\n' ';' | sed 's/\[STREAM\]/§/g' | tr -s '§' '\n' | grep -E 'codec_type=audio|channel_layout=' | sed 's/^;//;s/;$//')"


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
	echo "# 260"
	echo "Es konnte die Video-Auflösung nicht ermittelt werden."
	echo "versuchen Sie es mit diesem Parameter nocheinmal:"
	echo "-in_xmaly"
	echo "z.B. (PAL)     : -in_xmaly 720x576"
	echo "z.B. (NTSC)    : -in_xmaly 720x486"
	echo "z.B. (NTSC-DVD): -in_xmaly 720x480"
	echo "z.B. (HDTV)    : -in_xmaly 1280x720"
	echo "z.B. (FullHD)  : -in_xmaly 1920x1080"
	echo "ABBRUCH!"
	exit 270
fi

echo "# 280
IST_XY='${IST_XY}'
IN_DAR='${IN_DAR}'
IN_PAR='${IST_PAR}'
IST_DAR='${IST_DAR}'
IST_PAR='${IST_PAR}'
" | tee -a ${PROTOKOLLDATEI}.txt

#exit 290

#------------------------------------------------------------------------------#
### Seitenverhältnis des Bildes (DAR)

if [ -n "${IST_DAR}" ] ; then
	IN_DAR="${IST_DAR}"
fi


#----------------------------------------------------------------------#
### Seitenverhältnis der Bildpunkte (PAR / SAR)

if [ "x${IST_PAR}" = "x" ] ; then
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

echo "# 300
IN_XY='${IN_XY}'
IN_PAR='${IST_PAR}'
IST_DAR='${IST_DAR}'
IST_PAR='${IST_PAR}'
PAR='${PAR}'
PAR_KOMMA='${PAR_KOMMA}'
PAR_FAKTOR='${PAR_FAKTOR}'
" | tee -a ${PROTOKOLLDATEI}.txt

#exit 310

#------------------------------------------------------------------------------#
### Kontrolle Seitenverhältnis des Bildes (DAR)

if [ "x${IN_DAR}" = "x" ] ; then
	IN_DAR="$(echo "${IN_BREIT} ${IN_HOCH} ${PAR_KOMMA}" | awk '{printf("%.16f\n",$3/($2/$1))}')"
fi


if [ -z "${IN_DAR}" ] ; then
	echo "# 320"
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
	exit 340
fi


#----------------------------------------------------------------------#
### Seitenverhältnis des Bildes - Arbeitswerte berechnen (DAR)

DAR="$(echo "${IN_DAR}" | egrep '[:/]')"
if [ "x${DAR}" = "x" ] ; then
	DAR="$(echo "${IN_DAR}" | fgrep '.')"
	DAR_KOMMA="${DAR}"
	DAR_FAKTOR="$(echo "${DAR}" | fgrep '.' | awk '{printf "%u\n", $1*100000}')"
else
	DAR_KOMMA="$(echo "${DAR}" | egrep '[:/]' | awk -F'[:/]' '{print $1/$2}')"
	DAR_FAKTOR="$(echo "${DAR}" | egrep '[:/]' | awk -F'[:/]' '{printf "%u\n", ($1*100000)/$2}')"
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


#------------------------------------------------------------------------------#
### Seitenverhältnis des Bildes (DAR) muss hier bekannt sein!

if [ -z "${DAR_FAKTOR}" ] ; then
	echo "# 350"
	echo "Es konnte das Display-Format nicht ermittelt werden."
	echo "versuchen Sie es mit diesem Parameter nocheinmal:"
	echo "-dar"
	echo "z.B.: -dar 16:9"
	echo "ABBRUCH!"
	exit 360
fi


#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
### quadratische Bildpunkte sind der Standard

# https://ffmpeg.org/ffmpeg-filters.html#setdar_002c-setsar
FORMAT_ANPASSUNG="setsar='1/1',"


#------------------------------------------------------------------------------#
### gewünschtes Rasterformat der Bildgröße (Auflösung)

if [ "${ORIGINAL_PIXEL}" != Ja ] ; then
	if [ "x${SOLL_XY}" = "x" ] ; then
		unset BILD_SCALE
		unset SOLL_XY

		### ob die Pixel bereits quadratisch sind
		if [ "${PAR_FAKTOR}" -ne "100000" ] ; then
			### Umrechnung in quadratische Pixel - Version 1
			#BILD_SCALE="scale=$(echo "${DAR_KOMMA} ${IN_BREIT} ${IN_HOCH}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$1/2}' | awk '{print $1*2"x"$2*2}'),"
			#BILD_SCALE="scale=$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$3/2}' | awk '{print $1*2"x"$2*2}'),"

			### Umrechnung in quadratische Pixel - Version 2
			#HALBE_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{h=sqrt($1*$2/$3); printf "%.0f\n", h/2}')"
			#BILD_SCALE="scale=$(echo "${HALBE_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk '{print $1*2"x"$2*2}'),"
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
			BILD_SCALE="scale=$(echo "${TEIL_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk -v teiler="${TEILER}" '{print $1*teiler"x"$2*teiler}'),"

			BILD_BREIT="$(echo "${BILD_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $1}')"
			BILD_HOCH="$(echo "${BILD_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $2}')"
		else
			### wenn die Pixel bereits quadratisch sind
			BILD_BREIT="${IN_BREIT}"
			BILD_HOCH="${IN_HOCH}"
		fi
	else
		### Übersetzung von Bildauflösungsnamen zu Bildauflösungen
		### tritt nur bei manueller Auswahl der Bildauflösung in Kraft
		AUFLOESUNG_ODER_NAME="$(echo "${SOLL_XY}" | egrep '[0-9][0-9][0-9][x][0-9][0-9]')"
		if [ "x${AUFLOESUNG_ODER_NAME}" = "x" ] ; then
			### manuelle Auswahl der Bildauflösung per Namen
			if [ "x${BILD_FORMATNAMEN_AUFLOESUNGEN}" != "x" ] ; then
				NAME_XY_DAR="$(echo "${BILD_FORMATNAMEN_AUFLOESUNGEN}" | egrep '[-]soll_xmaly ' | awk '{print $2,$4,$5}' | egrep -i "^${SOLL_XY} ")"
				SOLL_XY="$(echo "${NAME_XY_DAR}" | awk '{print $2}')"
				SOLL_DAR="$(echo "${NAME_XY_DAR}" | awk '{print $3}')"

				# https://ffmpeg.org/ffmpeg-filters.html#setdar_002c-setsar
				FORMAT_ANPASSUNG="setdar='${SOLL_DAR}',"
			else
				echo "Die gewünschte Bildauflösung wurde als 'Name' angegeben: '${SOLL_XY}'"
				echo "Für die Übersetzung wird die Datei 'Filmwandler_grafik.txt' benötigt."
				echo "Leider konnte die Datei '$(dirname ${0})/Filmwandler_grafik.txt' nicht gelesen werden."
				exit 370
			fi
		fi

		SOLL_BILD_SCALE="scale=${SOLL_XY},"
		BILD_BREIT="$(echo "${SOLL_BILD_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $1}')"
		BILD_HOCH="$(echo "${SOLL_BILD_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $2}')"
	fi
fi

#------------------------------------------------------------------------------#
### Wenn die Bildpunkte vom Quell-Film und vom Ziel-Film quadratisch sind,
### dann ist es ganz einfach.
### Aber wenn nicht, dann sind diese Berechnungen nötig.

if [ "x${ORIGINAL_DAR}" != "x" ] ; then
	ORIG_DAR="$(echo "${META_DATEN_INFO}" | fgrep 'Video: ' | tr -s ',' '\n' | fgrep ' DAR ' | sed 's/.*DAR /DAR /;s/]//g' | awk '{print $2}' | head -n1)"
	ORIG_DAR_BREITE="$(echo "${ORIG_DAR}" | awk -F':' '{print $1}')"
	ORIG_DAR_HOEHE="$(echo "${ORIG_DAR}" | awk -F':' '{print $2}')"
	BREITE="${ORIG_DAR_BREITE}"
	HOEHE="${ORIG_DAR_HOEHE}"
	FORMAT_ANPASSUNG="setdar='${BREITE}/${HOEHE}',"
else
	if [ "x${SOLL_DAR}" != "x" ] ; then
		# hier sind Modifikationen nötig, weil viele der auswählbaren Bildformate
		# keine quadratischen Pixel vorsehen
		INBREITE_DAR="$(echo "${IN_DAR}" | awk -F'[/:]' '{print $1}')"
		INHOEHE_DAR="$(echo "${IN_DAR}" | awk -F'[/:]' '{print $2}')"
		PIXELVERZERRUNG="$(echo "${SOLL_DAR} ${INBREITE_DAR} ${INHOEHE_DAR} ${BILD_BREIT} ${BILD_HOCH}" | awk '{gsub("[:/]"," ") ; pfmt=$1*$6/$2/$5 ; AUSGABE=1 ; if (pfmt < 1) AUSGABE=0 ; if (pfmt > 1) AUSGABE=2 ; print AUSGABE}')"
		#
		unset PIXELKORREKTUR

		if [ "x${PIXELVERZERRUNG}" = x ] ; then
			echo "# 380
			# PIXELVERZERRUNG='${PIXELVERZERRUNG}'
			" | tee -a ${PROTOKOLLDATEI}.txt
			exit 390
		elif [ "${PIXELVERZERRUNG}" -eq 1 ] ; then
			echo "# 400
			# quadratische Pixel
			# PIXELVERZERRUNG = 1 : ${PIXELVERZERRUNG}
			" | tee -a ${PROTOKOLLDATEI}.txt
			BREITE="$(echo "${SOLL_DAR}" | awk '{gsub("/"," ");print $1}')"
			HOEHE="$(echo "${SOLL_DAR}" | awk '{gsub("/"," ");print $2}')"
			#
			unset PIXELKORREKTUR
		elif [ "${PIXELVERZERRUNG}" -le 1 ] ; then
			echo "# 410
			# lange Pixel: breit ziehen
			# 4CIF (Test 2)
			# PIXELVERZERRUNG < 1 : ${PIXELVERZERRUNG}
			" | tee -a ${PROTOKOLLDATEI}.txt
			BREITE="$(echo "${SOLL_DAR} ${INBREITE_DAR} ${INHOEHE_DAR} ${BILD_BREIT} ${BILD_HOCH}" | awk '{gsub("/"," ");print $2 * $2 * $5 / $1 / $6}')"
			HOEHE="$(echo "${SOLL_DAR}" | awk '{gsub("/"," ");print $2}')"
			#
			PIXELKORREKTUR="${BILD_SCALE}"
		elif [ "${PIXELVERZERRUNG}" -ge 1 ] ; then
			echo "# 420
			# breite Pixel: lang ziehen
			# 2CIF (Test 1)
			# PIXELVERZERRUNG > 1 : ${PIXELVERZERRUNG}
			" | tee -a ${PROTOKOLLDATEI}.txt
			BREITE="$(echo "${SOLL_DAR}" | awk '{gsub("/"," ");print $1}')"
			HOEHE="$(echo "${SOLL_DAR} ${INBREITE_DAR} ${INHOEHE_DAR} ${BILD_BREIT} ${BILD_HOCH}" | awk '{gsub("/"," ");print $1 * $1 * $6 / $2 / $5}')"
			#
			PIXELKORREKTUR="${BILD_SCALE}"
		fi
	else
		if [ "${DAR_FAKTOR}" -lt "149333" ] ; then
			BREITE="4"
			HOEHE="3"
		else
			BREITE="16"
			HOEHE="9"
		fi
		FORMAT_ANPASSUNG="setdar='${BREITE}/${HOEHE}',"
	fi
fi

#------------------------------------------------------------------------------#
### wenn ein bestimmtes Format gewünscht ist, dann muss es am Ende auch rauskommen

if [ "x${SOLL_XY}" != x ] ; then
	PIXELKORREKTUR="${SOLL_BILD_SCALE}"
fi

#------------------------------------------------------------------------------#
### wenn das Bild hochkannt steht, dann müssen die Seiten-Höhen-Parameter vertauscht werden
### Breite, Höhe, PAD, SCALE

echo "# 429
BILD_BREIT		='${BILD_BREIT}'
BILD_HOCH		='${BILD_HOCH}'
BILD_SCALE		='${BILD_SCALE}'
SOLL_BILD_SCALE		='${SOLL_BILD_SCALE}'
" | tee -a ${PROTOKOLLDATEI}.txt

BILD_DREHEN()
{
	if [ "x${IN_XY}" != x ] ; then
		IN_XY="$(echo "${IN_XY}" | awk -F'x' '{print $2"x"$1}')"
	fi

	unset ZWISCHENSPEICHER
	ZWISCHENSPEICHER="${BREITE}"
	BREITE="${HOEHE}"
	HOEHE="${ZWISCHENSPEICHER}"
	unset ZWISCHENSPEICHER

	if [ "x${BILD_SCALE}" = x ] ; then
		unset ZWISCHENSPEICHER
		ZWISCHENSPEICHER="${BILD_BREIT}"
		BILD_BREIT="${BILD_HOCH}"
		BILD_HOCH="${ZWISCHENSPEICHER}"
		unset ZWISCHENSPEICHER
	else
		BILD_BREIT="$(echo "${BILD_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $2}')"
		BILD_HOCH="$(echo "${BILD_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $1}')"
	fi
	BILD_SCALE="scale=${BILD_BREIT}x${BILD_HOCH},"

	if [ "x${SOLL_DAR}" = "x" ] ; then
		FORMAT_ANPASSUNG="setdar='${BREITE}/${HOEHE}',"
	fi
}

if [ "x${BILD_DREHUNG}" != x ] ; then
	if [ "${BILD_DREHUNG}" = 90 ] ; then
		BILD_DREHEN
	elif [ "${BILD_DREHUNG}" = 270 ] ; then
		BILD_DREHEN
	fi
fi
IN_BREIT="$(echo "${IN_XY}" | awk -F'x' '{print $1}')"
IN_HOCH="$(echo  "${IN_XY}" | awk -F'x' '{print $2}')"

#------------------------------------------------------------------------------#

echo "# 430
FORMAT_ANPASSUNG    ='${FORMAT_ANPASSUNG}'
PIXELVERZERRUNG     ='${PIXELVERZERRUNG}'
BREITE              ='${BREITE}'
HOEHE               ='${HOEHE}'
NAME_XY_DAR         ='${NAME_XY_DAR}'
IN_DAR              ='${IN_DAR}'
SOLL_DAR            ='${SOLL_DAR}'
INBREITE_DAR        ='${INBREITE_DAR}'
INHOEHE_DAR         ='${INHOEHE_DAR}'
IN_XY               ='${IN_XY}'
Originalauflösung   ='${IN_BREIT}x${IN_HOCH}'
PIXELZAHL           ='${PIXELZAHL}'
SOLL_XY             ='${SOLL_XY}'

BILD_BREIT          ='${BILD_BREIT}'
BILD_HOCH           ='${BILD_HOCH}'
BILD_SCALE          ='${BILD_SCALE}'
#==============================================================================#
" | tee -a ${PROTOKOLLDATEI}.txt

#exit 440

#------------------------------------------------------------------------------#
### PAD
# https://ffmpeg.org/ffmpeg-filters.html#pad-1
# pad=640:480:0:40:violet
# pad=width=640:height=480:x=0:y=40:color=violet
#
# SCHWARZ="$(echo "${HOEHE} ${BREITE} ${BILD_BREIT} ${BILD_HOCH}" | awk '{sw="oben"; if (($1/$2) < ($3/$4)) sw="oben"; print sw}')"
# SCHWARZ="$(echo "${HOEHE} ${BREITE} ${BILD_BREIT} ${BILD_HOCH}" | awk '{sw="oben"; if (($1/$2) > ($3/$4)) sw="links"; print sw}')"
#
if [ "${ORIGINAL_PIXEL}" = Ja ] ; then
	unset PAD
else
	PAD="pad='max(iw\\,ih*(${BREITE}/${HOEHE})):ow/(${BREITE}/${HOEHE}):(ow-iw)/2:(oh-ih)/2',"
fi


#------------------------------------------------------------------------------#
### hier wird ausgerechnen wieviele Pixel der neue Film pro Bild haben wird
### und die gewünschte Breite und Höhe wird festgelegt, damit in anderen
### Funktionen weitere Berechningen für Modus, Bitrate u.a. errechnet werden
### kann

if [ "x${SOLL_XY}" = "x" ] ; then
	PIXELZAHL="$(echo "${IN_BREIT} ${IN_HOCH}" | awk '{print $1 * $2}')"
	VERGLEICH_BREIT="${IN_BREIT}"
	VERGLEICH_HOCH="${IN_HOCH}"
else
	P_BREIT="$(echo "${SOLL_XY}" | awk -F'x' '{print $1}')"
	P_HOCH="$(echo "${SOLL_XY}" | awk -F'x' '{print $2}')"
	PIXELZAHL="$(echo "${P_BREIT} ${P_HOCH}" | awk '{print $1 * $2}')"
	VERGLEICH_BREIT="${P_BREIT}"
	VERGLEICH_HOCH="${P_HOCH}"
fi


if [ -r ${AVERZ}/Filmwandler_Format_${ENDUNG}.txt ] ; then
    
        OP_QUELLE="1"
        unset FFMPEG_TARGET
        
	echo "IN_FPS='${IN_FPS}'"
	#exit 450

	. ${AVERZ}/Filmwandler_Format_${ENDUNG}.txt

else
	echo "Datei konnte nicht gefunden werden:"
	echo "${AVERZ}/Filmwandler_Format_${ENDUNG}.txt"
	exit 460
fi

echo "# 460
IN_FPS='${IN_FPS}'
OP_QUELLE='${OP_QUELLE}'
" | tee -a ${PROTOKOLLDATEI}.txt

#exit 470

#==============================================================================#
### Qualität
#
# Qualitäts-Parameter-Übersetzung
# https://slhck.info/video/2017/02/24/vbr-settings.html
#

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
### Audio-Qualität

echo "
# 1012 TONQUALIT='${TONQUALIT}'
"

F_TON_QUALIT()
{
	#----------------------------------------------------------------------#
	# Work-Around
	#
	# Leider wird bei dieser Parameterangabe
	# "-map 0:a:0 -c:a libfdk_aac  -afterburner 1 -b:a 336k  -map 0:a:1 -c:a libfdk_aac  -afterburner 1 -b:a 112k"
	# für ALLE Tonspuren die Bit-Rate von "112k" verwendet!
	# Aus diesem Grund werden hier die Kanalinfos überschrieben,
	# damit für alle Tonspuren die max. Anzahl an Kanälen
	# bzw. die max. Bit-Rate verwendet wird.
	# Somit sollten beispielsweise diese Parameter nach diesem Work-Around so aussehen:
	# "-map 0:a:0 -c:a libfdk_aac  -afterburner 1 -b:a 336k  -map 0:a:1 -c:a libfdk_aac  -afterburner 1 -b:a 336k"
	#
	AUDIO_KANAELE="$(echo "${AUDIO_KANAL_INFOS}" | tr -s ';' '\n' | egrep '^channels=' | awk -F'=' '{print $2}' | sort -nr | head -n1)"
	#----------------------------------------------------------------------#

	F_AUDIO_QUALITAET >> ${PROTOKOLLDATEI}.txt 2>&1

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
}

#exit 475

echo "# 480
TONQUALIT='${TONQUALIT}'
AUDIOCODEC='${AUDIOCODEC}'
AUDIOQUALITAET='${AUDIOQUALITAET}'
AUDIO_KANAL_INFOS='${AUDIO_KANAL_INFOS}'
Sound_ST='${Sound_ST}'
Sound_51='${Sound_51}'
Sound_71='${Sound_71}'
TS_ANZAHL='${TS_ANZAHL}'
STEREO='${STEREO}'
" | tee -a ${PROTOKOLLDATEI}.txt

#exit 490

if [ "${TS_ANZAHL}" -gt 0 ] ; then
	# soll Stereo-Ausgabe erzwungen werden?
	if [ "x${STEREO}" = "x" ] ; then
		_ST=""
	else
		# wurde die Ausgabe bereits durch die Codec-Optionen auf Stereo gesetzt?
		BEREITS_AK2="$(echo "${AUDIOCODEC} ${AUDIOQUALITAET}" | grep -E 'ac 2|stereo')"
		if [ "x${BEREITS_AK2}" = "x" ] ; then
			_ST="${STEREO}"
		else
			_ST=""
		fi
	fi

	AUDIO_VERARBEITUNG_01="$(for DIE_TS in ${TS_LISTE}
	do
		if [ "x${STEREO}" = "x" ] ; then
			AKN="$(echo "${DIE_TS}" | awk '{print $1 + 1}')"
			AUDIO_KANAELE="$(echo "${AUDIO_KANAL_INFOS}" | head -n${AKN} | tail -n1 | tr -s ';' '\n' | egrep '^channels=' | awk -F'=' '{print $2}')"
			echo "# 483
			AUDIO_KANAELE='${AUDIO_KANAELE}'
			" >> ${PROTOKOLLDATEI}.txt
			AKL51="$(echo "${AUDIO_KANAL_INFOS}" | head -n${AKN} | tail -n1 | tr -s ';' '\n' | fgrep 'channel_layout=5.1')"
			AKL71="$(echo "${AUDIO_KANAL_INFOS}" | head -n${AKN} | tail -n1 | tr -s ';' '\n' | fgrep 'channel_layout=7.1')"
			if [ "x${AKL51}" != "x" ] ; then
				if [ "x${AUDIO_KANAELE}" = x ] ; then
					AUDIO_KANAELE=6
				fi
				F_TON_QUALIT
				echo -n "  -map 0:a:${DIE_TS} -c:a ${AUDIOCODEC} ${Sound_51} ${AUDIOQUALITAET}"
			elif [ "x${AKL71}" != "x" ] ; then
				if [ "x${AUDIO_KANAELE}" = x ] ; then
					AUDIO_KANAELE=8
				fi
				F_TON_QUALIT
				echo -n "  -map 0:a:${DIE_TS} -c:a ${AUDIOCODEC} ${Sound_71} ${AUDIOQUALITAET}"
			else
				if [ "x${AUDIO_KANAELE}" = x ] ; then
					AUDIO_KANAELE=2
				fi
				F_TON_QUALIT
				echo -n "  -map 0:a:${DIE_TS} -c:a ${AUDIOCODEC} ${Sound_ST} ${AUDIOQUALITAET}"
			fi
		else
			AUDIO_KANAELE="2"
			echo "# 487
			AUDIO_KANAELE='${AUDIO_KANAELE}'
			" >> ${PROTOKOLLDATEI}.txt
			F_TON_QUALIT
			echo -n " -map 0:a:${DIE_TS} -c:a ${AUDIOCODEC} ${AUDIOQUALITAET} -ac 2"
		fi
	done)"

	TS_KOPIE="$(seq 0 ${TS_ANZAHL} | head -n ${TS_ANZAHL})"
	AUDIO_VERARBEITUNG_02="$(for DIE_TS in ${TS_KOPIE}
	do
		echo -n " -map 0:a:${DIE_TS} -c:a copy"
	done)"

else
	AUDIO_VERARBEITUNG_01="-an"
	AUDIO_VERARBEITUNG_02="-an"
fi

echo "" | tee -a ${PROTOKOLLDATEI}.txt
echo "# 500
BEREITS_AK2='${BEREITS_AK2}'
TS_KOPIE='${TS_KOPIE}'
AUDIO_VERARBEITUNG_01='${AUDIO_VERARBEITUNG_01}'
AUDIO_VERARBEITUNG_02='${AUDIO_VERARBEITUNG_02}'
" | tee -a ${PROTOKOLLDATEI}.txt

#exit 510

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#==============================================================================#
### Untertitel

# -map 0:s:0 -c:s copy -map 0:s:1 -c:s copy		# "0" für die erste Untertitelspur
# UNTERTITEL="-map 0:s:${i} -scodec copy"		# alt
# UNTERTITEL="-map 0:s:${i} -c:s copy"			# neu

UNTERTITEL_AN="-c:s copy"				# für das zusammensetzen der Filmteile
if [ "${UNTERTITEL}" = "=0" ] ; then
	U_TITEL_FF_01=""
	U_TITEL_FF_ALT=""
	U_TITEL_FF_02=""
	UNTERTITEL_AN=""				# für das zusammensetzen der Filmteile
else
	if [ "x${UNTERTITEL}" = "x" ] ; then
		UT_META_DATEN="$(echo "${META_DATEN_STREAM}" | fgrep -i codec_type=subtitle)"
		if [ "x${UT_META_DATEN}" != "x" ] ; then
			UT_LISTE="$(echo "${UT_META_DATEN}" | nl | awk '{print $1 - 1}' | tr -s '\n' ' ')"
		fi
	else
		UT_LISTE="$(echo "${UNTERTITEL}" | sed 's/,/ /g')"
	fi

	U_TITEL_FF_01="$(for DER_UT in ${UT_LISTE}
	do
		echo -n " -map 0:s:${DER_UT}? -c:s copy"
	done)"

	### Wenn der Untertitel in einem Text-Format vorliegt, dann muss er ggf. auch transkodiert werden.
	if [ "${ENDUNG}" = mp4 ] ; then
		UT_FORMAT="mov_text"
	elif [ "${ENDUNG}" = webm ] ; then
		UT_FORMAT="webvtt"
	else
		unset UT_FORMAT
	fi

	### wenn kein alternatives Untertitelformat vorgesehen ist, dann weiter ohne Untertitel als "Alternative bei Fehlschlag"
	if [ "x${ENDUNG}" = x ] ; then
		unset U_TITEL_FF_ALT
	else
		if [ "x${UT_FORMAT}" != x ] ; then
			U_TITEL_FF_ALT="$(for DER_UT in ${UT_LISTE}
			do
				echo -n " -map 0:s:${DER_UT}? -c:s ${UT_FORMAT}"
			done)"
		fi
	fi

	UT_ANZAHL="$(echo "${UT_LISTE}" | wc -w | awk '{print $1}')"
	UT_KOPIE="$(seq 0 ${UT_ANZAHL} | head -n ${UT_ANZAHL})"
	U_TITEL_FF_02="$(for DER_UT in ${UT_KOPIE}
	do
		echo -n " -map 0:s:${DER_UT}? -c:s copy"
	done)"
fi

echo "# 520
UT_META_DATEN='${UT_META_DATEN}'

UNTERTITEL='${UNTERTITEL}'
UT_LISTE='${UT_LISTE}'
U_TITEL_FF_01='${U_TITEL_FF_01}'
U_TITEL_FF_ALT='${U_TITEL_FF_ALT}'
U_TITEL_FF_02='${U_TITEL_FF_02}'
" | tee -a ${PROTOKOLLDATEI}.txt

#exit 530

#==============================================================================#
### Video-Qualität

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
# Transkodierung
#
# vor PAD muss eine Auflösung, die der Originalauflösung entspricht, die aber
# für quadratische Pixel ist;
# oder man muss die Seitenverhältnisse für FFmpeg um den gleichen Wert verzerren,
# wie die Bildpunkte im Quell-Film;
# hinter PAD muss dann die endgültig gewünschte Auflösung für quadratische Pixel
#
#VIDEOOPTION="$(echo "${VIDEOQUALITAET} -vf ${ZEILENSPRUNG}${CROP}${BILD_SCALE}${PAD}${FORMAT_ANPASSUNG}" | sed 's/[,]$//')"			# für Testzwecke
VIDEOOPTION="$(echo "${VIDEOQUALITAET} -vf ${ZEILENSPRUNG}${CROP}${BILD_SCALE}${PAD}${PIXELKORREKTUR}${FORMAT_ANPASSUNG}" | sed 's/[,]$//')"

if [ "x${SOLL_FPS}" = "x" ] ; then
	unset FPS
else
	FPS="-r ${SOLL_FPS}"
fi

START_ZIEL_FORMAT="-f ${FORMAT}"

#------------------------------------------------------------------------------#

SCHNITT_ANZAHL="$(echo "${SCHNITTZEITEN}" | wc -w | awk '{print $1}')"

echo "# 530
SCHNITTZEITEN='${SCHNITTZEITEN}'
SCHNITT_ANZAHL='${SCHNITT_ANZAHL}'

TS_LISTE='${TS_LISTE}'
TS_ANZAHL='${TS_ANZAHL}'

BILDQUALIT='${BILDQUALIT}'
VIDEOCODEC='${VIDEOCODEC}'
VIDEOQUALITAET='${VIDEOQUALITAET}'

AUDIO_VERARBEITUNG_01='${AUDIO_VERARBEITUNG_01}'
AUDIO_VERARBEITUNG_02='${AUDIO_VERARBEITUNG_02}'

VIDEOOPTION='${VIDEOOPTION}'
START_ZIEL_FORMAT='${START_ZIEL_FORMAT}'
" | tee -a ${PROTOKOLLDATEI}.txt

#exit 540

#set -x

#------------------------------------------------------------------------------#
if [ ${SCHNITT_ANZAHL} -le 1 ] ; then
	if [ ${SCHNITT_ANZAHL} -eq 1 ] ; then
		VON="-ss $(echo "${SCHNITTZEITEN}" | tr -d '"' | awk -F'-' '{print $1}')"
		BIS="-to $(echo "${SCHNITTZEITEN}" | tr -d '"' | awk -F'-' '{print $2}')"
	fi

	###------------------------------------------------------------------###
	### hier der Film transkodiert                                       ###
	###------------------------------------------------------------------###
	echo
	echo "1,1: ${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${VON} ${BIS} ${FPS} ${SCHNELLSTART} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}" | tee -a ${PROTOKOLLDATEI}.txt
	echo
	         ${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${VON} ${BIS} ${FPS} ${SCHNELLSTART} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG} 2>&1 && WEITER=OK || WEITER=ALT

	if [ "${WEITER}" = ALT ] ; then
		echo
		echo "1,2: ${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_ALT} ${VON} ${BIS} ${FPS} ${SCHNELLSTART} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}" | tee -a ${PROTOKOLLDATEI}.txt
		echo
		${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_ALT} ${VON} ${BIS} ${FPS} ${SCHNELLSTART} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG} 2>&1
	fi

else

	#----------------------------------------------------------------------#
	ZUFALL="$(head -c 100 /dev/urandom | base64 | tr -d '\n' | tr -cd '[:alnum:]' | cut -b-12)"
	rm -f ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}_Filmliste.txt
	NUMMER="0"
	for _SCHNITT in ${SCHNITTZEITEN}
	do
		echo "---------------------------------------------------------" | tee -a ${PROTOKOLLDATEI}.txt

		NUMMER="$(echo "${NUMMER}" | awk '{printf "%2.0f\n", $1+1}' | tr -s ' ' '0')"
		VON="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $1}')"
		BIS="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $2}')"

		###----------------------------------------------------------###
		### hier werden die Teile zwischen der Werbung transkodiert  ###
		###----------------------------------------------------------###
		echo
		echo "2,1: ${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} -ss ${VON} -to ${BIS} ${FPS} ${START_ZIEL_FORMAT} -y ${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG}" | tee -a ${PROTOKOLLDATEI}.txt
		echo
		         ${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} -ss ${VON} -to ${BIS} ${FPS} ${START_ZIEL_FORMAT} -y ${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG} 2>&1 && WEITER=OK || WEITER=ALT

		if [ "${WEITER}" = ALT ] ; then
			echo
			echo "2,2: ${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_ALT} -ss ${VON} -to ${BIS} ${FPS} ${START_ZIEL_FORMAT} -y ${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG}" | tee -a ${PROTOKOLLDATEI}.txt
			echo
			${PROGRAMM} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_ALT} -ss ${VON} -to ${BIS} ${FPS} ${START_ZIEL_FORMAT} -y ${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG} 2>&1
		fi

		ffprobe -i ${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG} 2>&1 | tee -a ${PROTOKOLLDATEI}.txt

                ### den Film in die Filmliste eintragen
                echo "echo \"file '${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG}'\" >> ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}_Filmliste.txt" | tee -a ${PROTOKOLLDATEI}.txt
                echo "file '${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG}'" >> ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}_Filmliste.txt

		echo "---------------------------------------------------------" | tee -a ${PROTOKOLLDATEI}.txt
	done

	echo "# 550
	${PROGRAMM} -f concat -i ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}_Filmliste.txt -map 0:v -c:v copy ${AUDIO_VERARBEITUNG_02} ${U_TITEL_FF_02} ${SCHNELLSTART} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}
	" | tee -a ${PROTOKOLLDATEI}.txt
	${PROGRAMM} -f concat -i ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}_Filmliste.txt -map 0:v -c:v copy ${AUDIO_VERARBEITUNG_02} ${U_TITEL_FF_02} ${SCHNELLSTART} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}

	rm -f ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}_Filmliste.txt

	ffprobe -i ${ZIELVERZ}/${ZIELNAME}.${ENDUNG} 2>&1 | tee -a ${PROTOKOLLDATEI}.txt

	#ls -lh ${ZUFALL}_*_${ZIELNAME}.${ENDUNG} ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.${ENDUNG} ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.${ENDUNG}
	rm -f ${ZUFALL}_*_${ZIELNAME}.${ENDUNG} ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.${ENDUNG} ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.${ENDUNG}

fi

#------------------------------------------------------------------------------#

ls -lh ${ZIELVERZ}/${ZIELNAME}.${ENDUNG} ${PROTOKOLLDATEI}.txt | tee -a ${PROTOKOLLDATEI}.txt

LAUFZEIT="$(echo "${STARTZEITPUNKT} $(date +'%s')" | awk '{print $2 - $1}')"
echo "# 400
$(date +'%F %T') (${LAUFZEIT})" | tee -a ${PROTOKOLLDATEI}.txt

#exit 560
