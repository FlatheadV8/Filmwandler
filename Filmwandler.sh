#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Dieses Skript verändert NICHT die Bildwiederholrate!
#
# Das Ergebnis besteht immer aus folgendem Format:
#  - WebM:    webm   + AV1        + Opus    (ohne Untertitel)
#  - MKV:     mkv    + VP9        + Vorbis
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
#VERSION="v2020040800"			# jetzt wird beim X*Y-Format auch die Bild-Rotation berücksichtigt
#VERSION="v2020050300"			# jetzt gibt es auch eine Option, durch die man das Normalisieren auf 4:3 bzw. 16:9 verhindern kann
#VERSION="v2020060200"			# Dateinamen können jetzt auch Punkte enthalten
#VERSION="v2020061000"			# VIDEO_TAG wurde doppelt verwendet
#VERSION="v2020061100"			# in Zeile 1117 einen Work-Around für Bit-Rate bei Tonspuren eingesetzt
#VERSION="v2020070500"			# soll_xmaly wurde falsch behandelt
#VERSION="v2020072100"			# die erste Tonspur ist immer die "Default"-Tonspur: -disposition:a:0 default
#VERSION="v2020072600"			# Jetzt können auch Video-Dateien ohne Video-Spur erstellt werden
#VERSION="v2020072700"			# Fehler behoben
#VERSION="v2020092500"			# bestimmte Audio-Optionen können bei FFmpeg leider nur noch global, nicht mehr pro Kanal angegeben werden
#VERSION="v2020100100"			# Fehler behoben
#VERSION="v2020101600"			# Fehler in Interpretation von "field_order" behoben
#VERSION="v2020101800"			# bei inkompatiblen Untertitelformaten, wird jetzt ohne Untertiten weiter gemacht
#VERSION="v2020102300"			# kleinere Ergänzugen
#VERSION="v2020102400"			# die STANDARD-AUDIO-SPUR kann jetzt auch manuell gesetzt werden
#VERSION="v2020102500"			# die STANDARD-UNTERTITEL-SPUR kann jetzt auch manuell gesetzt werden
#VERSION="v2020102600"			# Jetzt werden auch die Titel richtig behandelt, so das Leerzeichen keine Probleme mehr bereiten
#VERSION="v2020102800"			# Fehler bei METADATEN behoben
#VERSION="v2020110400"			# Fehler bei PROTOKOLLDATEI-Namen behoben + VIDEO_DELAY eingebaut
#VERSION="v2020110900"			# etwas mehr Logausgaben
#VERSION="v2020111100"			# Fehler bei Video-Spurerkennung von Blurays behoben
#VERSION="v2020121700"			# Multiple -c, -codec, -acodec, -vcodec, -scodec or -dcodec options specified for stream 9, only the last option '-c:s copy' will be used. /  Multiple -q or -qscale options specified for stream 2, only the last option '-q:a 6.000000' will be used.
#VERSION="v2021032800"			# Fehler: es wurde nur eine Video-Spur transkodiert, wenn es die erste Spur im Container war + PAD nach hinten verschoben
#VERSION="v2021040400"			# PAD vor PIXELKORREKTUR verschoben / jetzt gibt es einen Hinweis, wenn die Zieldatei keine Endung hat
#VERSION="v2021050600"			# PAD vor BILD_SCALE verschoben + PIXELKORREKTUR verlagert
#VERSION="v2021050800"			# das PAD (padding) verbessert
#VERSION="v2021050801"			# das PAD (padding) verbessert - Verzerrungsproblem bei nicht quadratischen Bildpunkten endlich gelöst
#VERSION="v2021050802"			# Test-Modus verbessert
#VERSION="v2021080400"			# Option zum drehen des Videos hinzugefügt
VERSION="v2021080700"			# Untertitelabschaltung verbessert

VERSION_METADATEN="${VERSION}"

#
# e[cx][hi][ot]
#
#
# Bild mit Tonspur
# -shortest
# ffmpeg -framerate 1/1988 -i kein_Fachbuch_beantwortet_die_Frage_warum_Schwangere_Verrueckt_werden.png -i kein_Fachbuch_beantwortet_die_Frage_warum_Schwangere_Verrueckt_werden.mp4 -map 0:v:0 -c:v libx264 -preset veryslow -tune film -x264opts ref=4:b-pyramid=strict:bluray-compat=1:weightp=0:vbv-maxrate=12500:vbv-bufsize=12500:level=3:slices=4:b-adapt=2:direct=auto:colorprim=bt709:transfer=bt709:colormatrix=bt709:keyint=50:aud:subme=9:nal-hrd=vbr -crf 20 -vf yadif,scale=856x480,pad='max(iw\,ih*(16/9)):ow/(16/9):(ow-iw)/2:(oh-ih)/2',setdar='16/9',fps='25' -keyint_min 2-8 -map 1:a:0 -c:a aac -b:a 336k -ac 2 -disposition:a:0 default -ss 1 -to 79 -movflags faststart -f mp4 -y Maenner_haben_es_schwer.mp4
#
# https://techbeasts.com/fmpeg-commands/
# Video um 90° drehen: ffmpeg -i input.mp4 -filter:v 'transpose=1' ouput.mp4
# Video 2 mal um 90° drehen: ffmpeg -i input.mp4 -filter:v 'transpose=2' ouput.mp4
# Video um 180° drehen: ffmpeg -i input.mp4 -filter:v 'transpose=2,transpose=2' ouput.mp4
#   http://www.borniert.com/2016/03/rasch-mal-ein-video-drehen/
#   ffmpeg -i in.mp4 -c copy -metadata:s:v:0 rotate=90 out.mp4
# siehe: BILD_DREHUNG=...
#
# https://stackoverflow.com/questions/44351606/ffmpeg-set-the-language-of-an-audio-stream
# ISO 639-2: 3-Zeichen-Kode
# -metadata:s:a:0 language=ger


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
TEST="Nein"
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


#==============================================================================#

if [ "x${1}" = x ] ; then
        ${0} -h
	exit 30
fi

while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -q)
                        FILMDATEI="${2}"			# Name für die Quelldatei
                        shift
                        ;;
                -z)
                        ZIELPFAD="${2}"				# Name für die Zieldatei
                        shift
                        ;;
                -titel)
                        EIGENER_TITEL="${2}"			# Titel/Name des Filmes
                        shift
                        ;;
                -c|-crop)
                        CROP="${2}"				# zum entfernen der schwarzen Balken: -vf crop=width:height:x:y
                        shift
                        ;;
                -drehen)
                        BILD_DREHUNG="${2}"			# es geht nur 90 (-vf transpose=1), 270 (-vf transpose=2) und 180 (-vf hflip,vflip) Grad
                        shift
                        ;;
                -dar)
                        IST_DAR="${2}"				# Display-Format, wenn ein anderes gewünscht wird als automatisch erkannt wurde
                        shift
                        ;;
                -orig_dar)
			ORIGINAL_DAR="${2}"			# das originale Seitenverhältnis soll beibehalten werden
                        shift
                        ;;
                -fps|-soll_fps)
                        SOLL_FPS="${2}"				# FPS (Bilder pro Sekunde) für den neuen Film festlegen
                        shift
                        ;;
                -par)
                        IST_PAR="${2}"				# Pixel-Format
                        shift
                        ;;
                -in_xmaly|-ist_xmaly)
                        IST_XY="${2}"				# Bildauflösung/Rasterformat der Quelle
                        shift
                        ;;
                -out_xmaly|-soll_xmaly)
                        SOLL_XY="${2}"				# Bildauflösung/Rasterformat der Ausgabe
                        shift
                        ;;
                -aq|-soll_aq)
                        TONQUALIT="${2}"			# Audio-Qualität
                        shift
                        ;;
                -vq|-soll_vq)
                        BILDQUALIT="${2}"			# Video-Qualität
                        shift
                        ;;
                -vn)
                        VIDEO_NICHT_UEBERTRAGEN="0"		# Video nicht übertragen
                        shift
                        ;;
                -vd)
			# Wenn Audio- und Video-Spur nicht synchron sind,
			# dann muss das korrigiert werden.
			#
			# Wenn "-vd" und "-ad" zusammen im selben Kommando
			# verwendet werden, dann wird das erste vom zweiten überschrieben.
			#
			# Zeit in Sekunden,
			# um wieviel das Bild später (nach dem Ton) laufen soll
			#
			# Wenn der Ton 0,2 Sekunden zu spät kommt,
			# dann kann das Bild wie folgt um 0,2 Sekunden nach hinten
			# verschoben werden:
			# -vd 0.2
                        VIDEO_SPAETER="${2}"			# Video-Delay
                        shift
                        ;;
                -ad)
			# Wenn Audio- und Video-Spur nicht synchron sind,
			# dann muss das korrigiert werden.
			#
			# Wenn "-vd" und "-ad" zusammen im selben Kommando
			# verwendet werden, dann wird das erste vom zweiten überschrieben.
			#
			# Zeit in Sekunden,
			# um wieviel der Ton später (nach dem Bild) laufen soll
			#
			# Wenn das Bild 0,2 Sekunden zu spät kommt,
			# dann kann den Ton wie folgt um 0,2 Sekunden nach hinten
			# verschoben werden:
			# -ad 0.2
                        AUDIO_SPAETER="${2}"			# Video-Delay
                        shift
                        ;;
                -standard_ton)
                        # Wird diese Option nicht verwendet,
                        # dann wird die Einstellung aus dem Originalfilm übernommen
                        # "0" für die erste Tonspur
                        # "5" für die sechste Tonspur
                        SOLL_STANDARD_AUDIO_SPUR="${2}"		# -standard_ton 5
                        shift
                        ;;
                -standard_u)
                        # Wird diese Option nicht verwendet,
                        # dann wird die Einstellung aus dem Originalfilm übernommen
                        # "0" für die erste Untertitelspur
                        # "5" für die sechste Untertitelspur
                        SOLL_STANDARD_UNTERTITEL_SPUR="${2}"	# -standard_u 5
                        shift
                        ;;
                -ton)
                        # Wird diese Option nicht verwendet, dann werden ALLE Tonspuren eingebettet
                        # "0" für die erste Tonspur
                        # "1" für die zweite Tonspur
                        # "0,1" für die erste und die zweite Tonspur
                        TONSPUR="${2}"				# -ton 0,1,2,3,4
                        shift
                        ;;
                -stereo)
                        STEREO="Ja"
                        #STEREO="-ac 2"				# Stereo-Ausgabe erzwingen
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
                        TEST="Ja"		# um die richtigen CROP-Parameter zu ermitteln
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

	# Titel/Name des Filmes
	titel \"Titel oder Name des Filmes\"
	titel \"Battlestar Galactica\"

	# Wenn Audio- und Video-Spur nicht synchron sind,
	# dann muss das korrigiert werden.
	#
	# Wenn "-vd" und "-ad" zusammen im selben Kommando
	# verwendet werden, dann wird das erste vom zweiten überschrieben.
	#
	# Zeit in Sekunden,
	# um wieviel das Bild später (nach dem Ton) laufen soll
	#
	# Wenn der Ton 0,2 Sekunden zu spät kommt,
	# dann kann das Bild wie folgt um 0,2 Sekunden nach hinten
	# verschoben werden:
	-vd 0.2

	# Wenn Audio- und Video-Spur nicht synchron sind,
	# dann muss das korrigiert werden.
	#
	# Wenn "-vd" und "-ad" zusammen im selben Kommando
	# verwendet werden, dann wird das erste vom zweiten überschrieben.
	#
	# Zeit in Sekunden,
	# um wieviel der Ton später (nach dem Bild) laufen soll
	#
	# Wenn das Bild 0,2 Sekunden zu spät kommt,
	# dann kann den Ton wie folgt um 0,2 Sekunden nach hinten
	# verschoben werden:
	-ad 0.2

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

	# Wird diese Option nicht verwendet,
	# dann wird die Einstellung aus dem Originalfilm übernommen
	# Bei "0" wird die erste Tonspur automatisch gestartet
	# Bei "5" wird die sechste Tonspur automatisch gestartet
	-standard_ton 5

	# Wird diese Option nicht verwendet,
	# dann wird die Einstellung aus dem Originalfilm übernommen
	# Bei "0" wird die erste Untertitelspur automatisch gestartet
	# Bei "5" wird die sechste Untertitelspur automatisch gestartet
	-standard_u 5

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

        # die gewünschte Bildauflösung des neuen Filmes (Ausgabe)
        -soll_xmaly 720x576		# deutscher Parametername
        -out_xmaly 720x480		# englischer Parametername
        -soll_xmaly 965x543		# frei wählbares Bildformat kann angegeben werden
        -soll_xmaly VCD			# Name eines Bildformates kann angegeben werden

        # wenn diese Option einen beliebigen Wert (auch "nein") bekommt,
	# dann wird das originale Seitenverhältnis beibehalten
        -orig_dar ja

        # wenn das Bildformat des Originalfilmes nicht automatisch ermittelt
        # werden kann oder falsch ermittelt wurde,
        # dann muss es manuell als Parameter uebergeben werden;
        # es wird nur einer der beiden Parameter DAR oder PAR benoetigt
        -dar 16:9

        # wenn die Pixelgeometrie des Originalfilmes nicht automatisch ermittelt
        # werden kann oder falsch ermittelt wurde,
        # dann muss es manuell als Parameter uebergeben werden;
        # es wird nur einer der beiden Parameter DAR oder PAR benoetigt
        -par 64:45

        # will man eine andere Video-Qualitaet, dann sie manuell als Parameter
        # uebergeben werden
        -vq 5
        -soll_vq 5

        # will man eine andere Audio-Qualitaet, dann sie manuell als Parameter
        # uebergeben werden
        -aq 3
        -soll_aq 3

        # Video nicht übertragen
        # das Ergebnis soll keine Video-Spur enthalten
        -vn

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
	# -crop Ausschnittsbreite:Ausschnittshöhe:Abstand_von_links:Abstand_von_oben
        -crop 540:576:90:0

	# hat man mit dem SmartPhone ein Video aufgenommen, dann kann es sein,
	# dass es verdreht ist; mit dieser Option kann man das Video wieder
	# in die richtige Richtung drehen
        # es geht nur 90 (-vf transpose=1), 270 (-vf transpose=2) und 180 (-vf hflip,vflip) Grad
        -drehen 90
        -drehen 180
        -drehen 270

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

#==============================================================================#
# Das Video-Format wird nach der Dateiendung ermittelt
# deshalb muss ermittelt werden, welche Dateiendung der Name der Ziel-Datei hat
#
# Wenn der Name der Quell-Datei und der Name der Ziel-Datei gleich sind,
# dann wird dem Namen der Ziel-Datei ein "Nr2" vor der Endung angehängt
#

QUELL_BASIS_NAME="$(echo "${QUELL_DATEI}" | awk '{print tolower($0)}')"
ZIEL_BASIS_NAME="$(echo "${ZIELDATEI}" | awk '{print tolower($0)}')"

ZIELNAME="$(echo "${ZIELDATEI}" | awk '{sub("[.][^.]*$","");print $0}')"
ZIEL_FILM="${ZIELNAME}"
ENDUNG="$(echo "${ZIEL_BASIS_NAME}" | rev | sed 's/[a-zA-Z0-9\_\-\+/][a-zA-Z0-9\_\-\+/]*[.]/&"/;s/[.]".*//' | rev)"

if [ "${ZIEL_BASIS_NAME}" = "${ENDUNG}" ] ; then
	echo 'Die Zieldatei muß eine Endung haben!'
	ls ${AVERZ}/Filmwandler_Format_*.txt | sed 's/.*Filmwandler_Format_//;s/[.]txt//'
	exit 1
fi

if [ "${QUELL_BASIS_NAME}" = "${ZIEL_BASIS_NAME}" ] ; then
	ZIELNAME="${ZIELNAME}_Nr2"
fi

#------------------------------------------------------------------------------#
### ab hier kann in die Log-Datei geschrieben werden

PROTOKOLLDATEI="$(echo "${ZIELNAME}.${ENDUNG}" | sed 's/[ ][ ]*/_/g;')"

echo "# 30
$(date +'%F %T')
${0} ${Film2Standardformat_OPTIONEN}

QUELL_DATEI='${QUELL_DATEI}'
ZIELVERZ='${ZIELVERZ}'
ZIELDATEI='${ZIELDATEI}'

ZIELNAME='${ZIELNAME}'
ZIEL_FILM='${ZIEL_FILM}'
ENDUNG='${ENDUNG}'
" | tee "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 90

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

### für Tests
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

META_DATEN_STREAMS="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_streams)"
META_DATEN_ZEILENWEISE_STREAMS="$(echo "${META_DATEN_STREAMS}" | tr -s '\r' '\n' | tr -s '\n' ';' | sed 's/;\[STREAM\]/³[STREAM]/g' | tr -s '³' '\n')"	# durch Semikolin getrennte Schlüssel

# index=1
# codec_type=audio
# TAG:language=ger
# index=2
# codec_type=audio
# TAG:language=eng
# index=3
# codec_type=subtitle
# TAG:language=eng
#
#   1 audio ger 
#   2 audio eng 
#   3 subtitle eng 
META_DATEN_SPURSPRACHEN="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | egrep 'TAG:language=' | while read Z ; do echo "${Z}" | tr -s ';' '\n' | awk -F'=' '/^index=|^codec_type=|^TAG:language=/{print $2}' | tr -s '\n' ' ' ; echo ; done)"

# https://techbeasts.com/fmpeg-commands/
# Video um 90° drehen: ffmpeg -i input.mp4 -filter:v 'transpose=1' ouput.mp4
# Video 2 mal um 90° drehen: ffmpeg -i input.mp4 -filter:v 'transpose=2' ouput.mp4
# Video um 180° drehen: ffmpeg -i input.mp4 -filter:v 'transpose=2,transpose=2' ouput.mp4
#   http://www.borniert.com/2016/03/rasch-mal-ein-video-drehen/
#   ffmpeg -i in.mp4 -c copy -metadata:s:v:0 rotate=90 out.mp4
#  https://stackoverflow.com/questions/3937387/rotating-videos-with-ffmpeg
#  ffmpeg -vfilters "rotate=90" -i input.mp4 output.mp4
# https://stackoverflow.com/questions/3937387/rotating-videos-with-ffmpeg
# 0 = 90CounterCLockwise and Vertical Flip (default)
# 1 = 90Clockwise
# 2 = 90CounterClockwise
# 3 = 90Clockwise and Vertical Flip
# 180 Grad: -vf "transpose=2,transpose=2"
if [ "x${BILD_DREHUNG}" = x ] ; then
	BILD_DREHUNG="$(echo "${META_DATEN_STREAMS}" | sed -ne '/index=0/,/index=1/p' | awk -F'=' '/TAG:rotate=/{print $NF}' | head -n1)"	# TAG:rotate=180 -=> 180
fi

# TAG:rotate=180
# TAG:creation_time=2015-02-16T13:25:51.000000Z
# TAG:language=eng
# TAG:handler_name=VideoHandle
# [SIDE_DATA]
# side_data_type=Display Matrix
# displaymatrix=
# 00000000:       -65536           0           0
# 00000001:            0      -65536           0
# 00000002:            0           0  1073741824
#
# rotation=-180
# [/SIDE_DATA]
# [/STREAM]
# ffprobe -v error -i /home/privat/Video/Filme_ab_2014/2015/2015-02-16/20150216_142433.mp4 -show_streams | sed -ne '/index=0/,/index=1/p' | fgrep -i rotat
# TAG:rotate=180
# rotation=-180

#META_DATEN_STREAMS='${META_DATEN_STREAMS}'
echo "# 35
META_DATEN_SPURSPRACHEN='${META_DATEN_SPURSPRACHEN}'
BILD_DREHUNG='${BILD_DREHUNG}'
"                                             | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

exit
#------------------------------------------------------------------------------#

ORIGINAL_TITEL="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_entries format_tags=title -of compact=p=0:nk=1)"
KOMMENTAR="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_entries format_tags=comment -of compact=p=0:nk=1 | sed 's/[ ]/_/g')"
BESCHREIBUNG="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_entries format_tags=description -of compact=p=0:nk=1 | sed 's/[ ]/_/g')"
if [ "x${EIGENER_TITEL}" = x ] ; then
	EIGENER_TITEL="${ZIELNAME}"
fi
METADATEN_TITEL="-metadata title="

if [ "x${KOMMENTAR}" = x ] ; then
	if [ "x${BESCHREIBUNG}" = x ] ; then
		METADATEN_BESCHREIBUNG="-metadata description='https://github.com/FlatheadV8/Filmwandler:${VERSION_METADATEN}'"
	else
		METADATEN_BESCHREIBUNG="-metadata description='${BESCHREIBUNG}'"
	fi
else
	if [ "x${BESCHREIBUNG}" = x ] ; then
		METADATEN_BESCHREIBUNG="-metadata description='${KOMMENTAR}'"
	else
		METADATEN_BESCHREIBUNG="-metadata description='${KOMMENTAR} / ${BESCHREIBUNG}'"
	fi
fi

echo "# 40
ORIGINAL_TITEL='${ORIGINAL_TITEL}'

KOMMENTAR='${KOMMENTAR}'

BESCHREIBUNG='${BESCHREIBUNG}'

METADATEN_TITEL='${METADATEN_TITEL}'
EIGENER_TITEL='${EIGENER_TITEL}'
METADATEN_BESCHREIBUNG='${METADATEN_BESCHREIBUNG}'

SOLL_STANDARD_AUDIO_SPUR='${SOLL_STANDARD_AUDIO_SPUR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#------------------------------------------------------------------------------#
### STANDARD-AUDIO-SPUR

#AUDIO_SPUR_SPRACHE="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_entries stream=index:stream_tags=language -select_streams a -of compact=p=0:nk=1 | awk -F '|' '{print $1-1,$2}')"
AUDIO_SPUR_SPRACHE="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F codec_type=audio | tr -s ';' '\n' | fgrep 'TAG:language=' | awk -F'=' '{print $NF}' | nl | awk '{print $1-1,$2}')"

### Die Bezeichnungen (Sprache) für die Audiospuren werden automatisch übernommen.
if [ "x${SOLL_STANDARD_AUDIO_SPUR}" = x ] ; then
	### wenn nichts angegeben wurde, dann
	### Deutsch als Standard-Sprache voreinstellen
	AUDIO_STANDARD_SPUR="$(echo "${AUDIO_SPUR_SPRACHE}" | grep -Ei " deu| ger" | awk '{print $1}' | head -n1)"

	if [ "x${AUDIO_STANDARD_SPUR}" = x ] ; then
		### wenn nichts angegeben wurde
		### und es keine als deutsch gekennzeichnete Spur gibt, dann
		### STANDARD-AUDIO-SPUR vom Originalfilm übernehmen
		### DISPOSITION:default=1
		AUDIO_STANDARD_SPUR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep codec_type=audio | tr -s ';' '\n' | fgrep 'DISPOSITION:default=1' | grep -E 'default=[0-9]' | awk -F'=' '{print $2-1}')"
		if [ "x${AUDIO_STANDARD_SPUR}" = x ] ; then
			### wenn es keine STANDARD-AUDIO-SPUR im Originalfilm gibt, dann
			### alternativ einfach die erste Tonspur zur STANDARD-AUDIO-SPUR machen
			AUDIO_STANDARD_SPUR=0
		fi
	fi
else
	### STANDARD-AUDIO-SPUR manuell gesetzt
	AUDIO_STANDARD_SPUR="${SOLL_STANDARD_AUDIO_SPUR}"
fi

echo "# 50
AUDIO_SPUR_SPRACHE='${AUDIO_SPUR_SPRACHE}'
AUDIO_STANDARD_SPUR='${AUDIO_STANDARD_SPUR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 100

#--- VIDEO_SPUR ---------------------------------------------------------------#
#------------------------------------------------------------------------------#

VIDEO_SPUR="$(echo "${META_DATEN_STREAMS}" | fgrep -i codec_type=video | head -n1)"
if [ "${VIDEO_SPUR}" != codec_type=video ] ; then
	VIDEO_NICHT_UEBERTRAGEN=0
fi

echo "# 55
VIDEO_SPUR='${VIDEO_SPUR}'
VIDEO_NICHT_UEBERTRAGEN='${VIDEO_NICHT_UEBERTRAGEN}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 105

#------------------------------------------------------------------------------#
### hier wird eine Liste externer verfügbarer Codecs erstellt

FFMPEG_LIB="$((ffmpeg -formats >/dev/null) 2>&1 | tr -s ' ' '\n' | egrep '^[-][-]enable[-]' | sed 's/^[-]*enable[-]*//;s/[-]/_/g' | egrep '^lib')"
FFMPEG_FORMATS="$(ffmpeg -formats 2>/dev/null | awk '/^[ \t]*[ ][DE]+[ ]/{print $2}')"

#------------------------------------------------------------------------------#
### alternative Methode zur Ermittlung der FPS
R_FPS="$(echo "${META_DATEN_STREAMS}" | egrep '^codec_type=|^r_frame_rate=' | egrep -A1 '^codec_type=video' | awk -F'=' '/^r_frame_rate=/{print $2}' | sed 's|/| |')"
A_FPS="$(echo "${R_FPS}" | wc -w)"
if [ "${A_FPS}" -gt 1 ] ; then
	R_FPS="$(echo "${R_FPS}" | awk '{print $1 / $2}')"
fi
#------------------------------------------------------------------------------#
### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt

# tbn (FPS vom Container)            = the time base in AVStream that has come from the container
# tbc (FPS vom Codec)                = the time base in AVCodecContext for the codec used for a particular stream
# tbr (FPS vom Video-Stream geraten) = tbr is guessed from the video stream and is the value users want to see when they look for the video frame rate

### "field_order" gibt bei "interlaced" an in welcher Richtung (von oben nach unten oder von links nach rechts)
### "field_order" gibt nicht an, ob ein Film "progressive" ist
SCAN_TYPE="$(echo "${META_DATEN_STREAMS}" | awk -F'=' '/^field_order=/{print $2}' | grep -Ev '^$' | head -n1)"

echo "# 60
SCAN_TYPE='${SCAN_TYPE}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

if [ "${SCAN_TYPE}" != "progressive" ] ; then
    if [ "${SCAN_TYPE}" != "unknown" ] ; then
        ### wenn der Film im Zeilensprungverfahren vorliegt
        #ZEILENSPRUNG="yadif,"
	#
	# https://ffmpeg.org/ffmpeg-filters.html#yadif-1
	# https://ffmpeg.org/ffmpeg-filters.html#mcdeint
        #ZEILENSPRUNG="yadif=3:1,mcdeint=2:1,"
        ZEILENSPRUNG="yadif=1/3,mcdeint=mode=extra_slow,"
    fi
fi

# META_DATEN_STREAMS=" width=720 "
# META_DATEN_STREAMS=" height=576 "
IN_BREIT="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^width=/{print $2}' | grep -Fv 'N/A' | head -n1)"
IN_HOCH="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^height=/{print $2}' | grep -Fv 'N/A' | head -n1)"
IN_XY="${IN_BREIT}x${IN_HOCH}"
O_BREIT="${IN_BREIT}"
O_HOCH="${IN_HOCH}"

echo "# 70
1 IN_XY='${IN_XY}'
1 IN_BREIT='${IN_BREIT}'
1 IN_HOCH='${IN_HOCH}'
1 O_BREIT='${O_BREIT}'
1 O_HOCH='${O_HOCH}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 110

if [ "x${IN_XY}" = "x" ] ; then
	# META_DATEN_STREAMS=" coded_width=0 "
	# META_DATEN_STREAMS=" coded_height=0 "
	IN_BREIT="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^coded_width=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
	IN_HOCH="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^coded_height=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
	IN_XY="${IN_BREIT}x${IN_HOCH}"
	echo "# 90
	2 IN_XY='${IN_XY}'
	2 IN_BREIT='${IN_BREIT}'
	2 IN_HOCH='${IN_HOCH}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

	# http://www.borniert.com/2016/03/rasch-mal-ein-video-drehen/
	# ffmpeg -i in.mp4 -c copy -metadata:s:v:0 rotate=90 out.mp4
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

IN_PAR="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^sample_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "# 100
1 IN_PAR='${IN_PAR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
if [ "x${IN_PAR}" = "x" ] ; then
	IN_PAR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^sample_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
	echo "# 110
	2 IN_PAR='${IN_PAR}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
fi

IN_DAR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^display_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "# 120
1 IN_DAR='${IN_DAR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
if [ "x${IN_DAR}" = "x" ] ; then
	IN_DAR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^display_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
	echo "# 130
	2 IN_DAR='${IN_DAR}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
fi

# META_DATEN_STREAMS=" r_frame_rate=25/1 "
# META_DATEN_STREAMS=" avg_frame_rate=25/1 "
# META_DATEN_STREAMS=" codec_time_base=1/25 "
IN_FPS="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^r_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1}')"
echo "# 140
1 IN_FPS='${IN_FPS}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
if [ "x${IN_FPS}" = "x" ] ; then
	IN_FPS="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^avg_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1}')"
	echo "# 150
	2 IN_FPS='${IN_FPS}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	if [ "x${IN_FPS}" = "x" ] ; then
		IN_FPS="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^codec_time_base=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $2}')"
		echo "# 160
		3 IN_FPS='${IN_FPS}'
		" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	fi
fi

IN_FPS_RUND="$(echo "${IN_FPS}" | awk '{printf "%.0f\n", $1}')"			# für Vergleiche, "if" erwartet einen Integerwert

IN_BIT_RATE="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^bit_rate=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "# 180
1 IN_BIT_RATE='${IN_BIT_RATE}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
if [ "x${IN_BIT_RATE}" = "x" ] ; then
	IN_BIT_RATE="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^bit_rate=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
	echo "# 190
	2 IN_BIT_RATE='${IN_BIT_RATE}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
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

echo "# 210
IN_XY='${IN_XY}'
BILD_DREHUNG='${BILD_DREHUNG}'
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
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

unset IN_BIT_RATE
unset IN_BIT_EINH

#exit 120

#==============================================================================#
#==============================================================================#
# Audio

# ${META_DATEN_SPURSPRACHEN}
#   1 audio ger 
#   2 audio eng 
#   3 subtitle eng 
if [ "x${TONSPUR}" = "x" ] ; then
        TSNAME="$(echo "${META_DATEN_STREAMS}" | fgrep -i codec_type=audio | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
else
	TSNAME="${TONSPUR}"
fi

TS_LISTE="$(echo "${TSNAME}" | sed 's/,/ /g')"
TS_ANZAHL="$(echo "${TSNAME}" | sed 's/,/ /g' | wc -w | awk '{print $1}')"

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
	echo "# 220"
	echo "Es konnte die Video-Auflösung nicht ermittelt werden."
	echo "versuchen Sie es mit diesem Parameter nocheinmal:"
	echo "-in_xmaly"
	echo "z.B. (PAL)     : -in_xmaly 720x576"
	echo "z.B. (NTSC)    : -in_xmaly 720x486"
	echo "z.B. (NTSC-DVD): -in_xmaly 720x480"
	echo "z.B. (HDTV)    : -in_xmaly 1280x720"
	echo "z.B. (FullHD)  : -in_xmaly 1920x1080"
	echo "ABBRUCH!"
	exit 130
fi

echo "# 230
IST_XY='${IST_XY}'
IN_DAR='${IN_DAR}'
IN_PAR='${IST_PAR}'
IST_DAR='${IST_DAR}'
IST_PAR='${IST_PAR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 140

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

echo "# 240
IN_XY='${IN_XY}'
IN_DAR='${IN_DAR}'
IN_PAR='${IST_PAR}'
IST_DAR='${IST_DAR}'
IST_PAR='${IST_PAR}'
PAR='${PAR}'
PAR_KOMMA='${PAR_KOMMA}'
PAR_FAKTOR='${PAR_FAKTOR}'
VIDEO_SPUR='${VIDEO_SPUR}'
VIDEO_NICHT_UEBERTRAGEN='${VIDEO_NICHT_UEBERTRAGEN}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 150

#------------------------------------------------------------------------------#
### Kontrolle Seitenverhältnis des Bildes (DAR)

if [ "x${IN_DAR}" = "x" ] ; then
	IN_DAR="$(echo "${IN_BREIT} ${IN_HOCH} ${PAR_KOMMA}" | awk '{printf("%.16f\n",$3/($2/$1))}')"
fi

if [ "${VIDEO_NICHT_UEBERTRAGEN}" != "0" ] ; then
  if [ -z "${IN_DAR}" ] ; then
	echo "# 250"
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
	exit 160
  fi
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
if [ "x${CROP}" = "x" ] ; then
	IN_BREIT="$(echo "${IN_XY}" | awk -F'x' '{print $1}')"
	IN_HOCH="$(echo  "${IN_XY}" | awk -F'x' '{print $2}')"
else
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

if [ "${VIDEO_NICHT_UEBERTRAGEN}" != "0" ] ; then
  if [ -z "${DAR_FAKTOR}" ] ; then
	echo "# 260"
	echo "Es konnte das Display-Format nicht ermittelt werden."
	echo "versuchen Sie es mit diesem Parameter nocheinmal:"
	echo "-dar"
	echo "z.B.: -dar 16:9"
	echo "ABBRUCH!"
	exit 170
  fi


  #------------------------------------------------------------------------------#
  #------------------------------------------------------------------------------#
  #------------------------------------------------------------------------------#
  ### quadratische Bildpunkte sind der Standard

  # https://ffmpeg.org/ffmpeg-filters.html#setdar_002c-setsar
  FORMAT_ANPASSUNG="setsar='1/1',"


  #------------------------------------------------------------------------------#
  ### gewünschtes Rasterformat der Bildgröße (Auflösung)

  if [ "x${SOLL_XY}" = "x" ] ; then
	unset BILD_SCALE
	unset SOLL_XY

	### ob die Pixel bereits quadratisch sind
	if [ "${PAR_FAKTOR}" -ne "100000" ] ; then
		### Umrechnung in quadratische Pixel
		#
		### [swscaler @ 0x81520d000] Warning: data is not aligned! This can lead to a speed loss
		### laut Googel müssen die Pixel durch 16 teilbar sein, beseitigt aber leider dieses Problem nicht
		#
		### die Pixel sollten wenigstens durch 2 teilbar sein! besser aber durch 8                          
		TEILER="2"
		##TEILER="4"
		#TEILER="8"
		###TEILER="16"
		#
		TEIL_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${IN_DAR} ${TEILER}" | awk '{gsub(":"," ");printf "%.0f\n", sqrt($1 * $2 * $3 / $4) / $3 / $5}' | awk '{print $1 * 2}')"
		BILD_BREIT="$(echo "${TEIL_HOEHE} ${IN_DAR}" | awk '{gsub(":"," ");print $1 * $2}')"
		BILD_HOCH="$(echo "${TEIL_HOEHE} ${IN_DAR}" | awk '{gsub(":"," ");print $1 * $3}')"
		BILD_SCALE="scale=${BILD_BREIT}x${BILD_HOCH},"
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
			echo "Leider konnte die Datei '${AVERZ}/Filmwandler_grafik.txt' nicht gelesen werden."
			exit 180
		fi
	fi

	SOLL_BILD_SCALE="scale=${SOLL_XY},"
	BILD_BREIT="$(echo "${SOLL_BILD_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $1}')"
	BILD_HOCH="$(echo "${SOLL_BILD_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $2}')"
  fi

  #------------------------------------------------------------------------------#
  ### Wenn die Bildpunkte vom Quell-Film und vom Ziel-Film quadratisch sind,
  ### dann ist es ganz einfach.
  ### Aber wenn nicht, dann sind diese Berechnungen nötig.

  if [ "x${ORIGINAL_DAR}" != "x" ] ; then
	ORIG_DAR_BREITE="$(echo "${IN_DAR}" | awk -F':' '{print $1}')"
	ORIG_DAR_HOEHE="$(echo "${IN_DAR}" | awk -F':' '{print $2}')"
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
			echo "# 270
			# PIXELVERZERRUNG='${PIXELVERZERRUNG}'
			" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
			exit 190
		elif [ "${PIXELVERZERRUNG}" -eq 1 ] ; then
			echo "# 280
			# quadratische Pixel
			# PIXELVERZERRUNG = 1 : ${PIXELVERZERRUNG}
			" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
			BREITE="$(echo "${SOLL_DAR}" | awk '{gsub("/"," ");print $1}')"
			HOEHE="$(echo "${SOLL_DAR}" | awk '{gsub("/"," ");print $2}')"
			#
			unset PIXELKORREKTUR
		elif [ "${PIXELVERZERRUNG}" -le 1 ] ; then
			echo "# 290
			# lange Pixel: breit ziehen
			# 4CIF (Test 2)
			# PIXELVERZERRUNG < 1 : ${PIXELVERZERRUNG}
			" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
			BREITE="$(echo "${SOLL_DAR} ${INBREITE_DAR} ${INHOEHE_DAR} ${BILD_BREIT} ${BILD_HOCH}" | awk '{gsub("/"," ");print $2 * $2 * $5 / $1 / $6}')"
			HOEHE="$(echo "${SOLL_DAR}" | awk '{gsub("/"," ");print $2}')"
			#
			PIXELKORREKTUR="${BILD_SCALE}"
		elif [ "${PIXELVERZERRUNG}" -ge 1 ] ; then
			echo "# 300
			# breite Pixel: lang ziehen
			# 2CIF (Test 1)
			# PIXELVERZERRUNG > 1 : ${PIXELVERZERRUNG}
			" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
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

  echo "# 310
  BILD_BREIT		='${BILD_BREIT}'
  BILD_HOCH		='${BILD_HOCH}'
  BILD_SCALE		='${BILD_SCALE}'
  SOLL_BILD_SCALE 	='${SOLL_BILD_SCALE}'
  " | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

  #exit 200

  if [ "x${BILD_DREHUNG}" != x ] ; then
	if [ "${BILD_DREHUNG}" = 90 ] ; then
		BILD_DREHEN
		BILD_DREHUNG=",transpose=1"
	elif [ "${BILD_DREHUNG}" = 180 ] ; then
		BILD_DREHUNG=",hflip,vflip"
	elif [ "${BILD_DREHUNG}" = 270 ] ; then
		BILD_DREHEN
		BILD_DREHUNG=",transpose=2"
	else
		echo "nur diese beiden Gradzahlen werden von der Option '-drehen' unterstützt:"
		echo "90° nach links drehen:"
		echo "		${0} -drehen 90"
		echo "90° nach rechts drehen:"
		echo "		${0} -drehen 270"
		echo "komplett einmal umdrehen:"
		echo "		${0} -drehen 180"
		exit 1349
	fi
  fi

  #------------------------------------------------------------------------------#

  echo "# 320
  O_BREIT		='${O_BREIT}'
  O_HOCH		='${O_HOCH}'
  FORMAT_ANPASSUNG	='${FORMAT_ANPASSUNG}'
  PIXELVERZERRUNG	='${PIXELVERZERRUNG}'
  BREITE		='${BREITE}'
  HOEHE			='${HOEHE}'
  NAME_XY_DAR		='${NAME_XY_DAR}'
  IN_DAR		='${IN_DAR}'
  IN_BREIT		='${IN_BREIT}'
  IN_HOCH		='${IN_HOCH}'
  CROP			='${CROP}'
  SOLL_DAR		='${SOLL_DAR}'
  INBREITE_DAR		='${INBREITE_DAR}'
  INHOEHE_DAR		='${INHOEHE_DAR}'
  IN_XY			='${IN_XY}'
  Originalauflösung	='${IN_BREIT}x${IN_HOCH}'
  PIXELZAHL		='${PIXELZAHL}'
  SOLL_XY		='${SOLL_XY}'

  BILD_BREIT		='${BILD_BREIT}'
  BILD_HOCH		='${BILD_HOCH}'
  BILD_SCALE		='${BILD_SCALE}'
  #==============================================================================#
  " | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

  #exit 210

  #------------------------------------------------------------------------------#
  ### PAD
  # https://ffmpeg.org/ffmpeg-filters.html#pad-1
  # pad=640:480:0:40:violet
  # pad=width=640:height=480:x=0:y=40:color=violet
  #
  # max(iw\,ih*(16/9)) => https://ffmpeg.org/ffmpeg-filters.html#maskedmax
  #
  # pad=Bild vor dem padden:Bildecke oben links:Hintergrundfarbe
  # Bild vor dem padden           = iw:ih
  # Bildecke oben links           = (ow-iw)/2:(oh-ih)/2
  # Hintergrundfarbe (Bildfläche) = ow:oh
  #
  # iw = Bildbreite vor  dem padden
  # ih = Bildhöhe   vor  dem padden
  # ow = Bildbreite nach dem padden
  # oh = Bildhöhe   nach dem padden
  #  a = iw / ih
  #
  # DAR = Display Aspect Ratio
  # SAR = Sample  Aspect Ratio = PAR
  # PAR = Pixel   Aspect Ratio = SAR
  #
  # PAL-TV         (720x576) : DAR  4/3, SAR 16:15 = 1,066666666666666666
  # NTNC-TV        (720x486) : DAR  4/3, SAR  9:10 = 0,9
  # NTSC-DVD       (720x480) : DAR 16/9, SAR 32:27 = 1,185185185185185185
  # PAL-DVD / DVB  (720x576) : DAR 16/9, SAR 64:45 = 1,422222222222222222
  # BluRay        (1920x1080): DAR 16/9, SAR  1:1  = 1,0
  #
  BILD_DAR_BREITE="$(echo "${IN_DAR}" | awk -F':' '{print $1}')"
  BILD_DAR_HOEHE="$(echo "${IN_DAR}" | awk -F':' '{print $2}')"
  BASISWERTE="${O_BREIT} ${O_HOCH} ${BILD_DAR_BREITE} ${BILD_DAR_HOEHE} ${IN_BREIT} ${IN_HOCH}"
  BREIT_QUADRATISCH="$(echo "${IN_HOCH} ${BASISWERTE}" | awk '{printf "%.0f\n", $1*$3*$4*$6/$2/$5/$7/2}' | awk '{printf "%.0f\n", $1*2}')"
  HOCH_QUADRATISCH="$(echo "${IN_BREIT} ${BASISWERTE}" | awk '{printf "%.0f\n", ($1/($3*$4*$6/$2/$5/$7))/2}' | awk '{printf "%.0f\n", $1*2}')"
  if [ "${BREIT_QUADRATISCH}" -gt "${IN_BREIT}" ] ; then
	ZWISCHENFORMAT_QUADRATISCH="scale=${BREIT_QUADRATISCH}x${IN_HOCH},"
  elif [ "${HOCH_QUADRATISCH}" -gt "${IN_HOCH}" ] ; then
	ZWISCHENFORMAT_QUADRATISCH="scale=${IN_BREIT}x${HOCH_QUADRATISCH},"
  else
	ZWISCHENFORMAT_QUADRATISCH=""
  fi
  #
  ### hier wird die schwarze Hintergrundfläche definiert, auf der dann das Bild zentriert wird
  # pad='[hier wird "ow" gesetzt]:[hier wird "oh" gesetzt]:[hier wird der linke Abstand gesetzt]:[hier wird der obere Abstand gesetzt]:[hier wird die padding-Farbe gesetzt]'
  #  4/3 => PAD="pad='max(iw\,ih*(4/3)):ow/(4/3):(ow-iw)/2:(oh-ih)/2:black',"
  # 16/9 => PAD="pad='max(iw\,ih*(16/9)):ow/(16/9):(ow-iw)/2:(oh-ih)/2:black',"
  PAD="${ZWISCHENFORMAT_QUADRATISCH}pad='max(iw\\,ih*(${BREITE}/${HOEHE})):ow/(${BREITE}/${HOEHE}):(ow-iw)/2:(oh-ih)/2:black',"

  echo "# 325
  # O_BREIT='${O_BREIT}'
  # O_HOCH='${O_HOCH}'
  # IN_DAR='${IN_DAR}'
  # BILD_DAR_BREITE='${BILD_DAR_BREITE}'
  # BILD_DAR_HOEHE='${BILD_DAR_HOEHE}'
  # BREITE='${BREITE}'
  # HOEHE='${HOEHE}'
  # IN_BREIT='${IN_BREIT}'
  # IN_HOCH='${IN_HOCH}'
  # BILD_DAR='${BILD_DAR}'
  # BASISWERTE='${BASISWERTE}'
  # BREIT_QUADRATISCH='${BREIT_QUADRATISCH}'
  # HOCH_QUADRATISCH='${HOCH_QUADRATISCH}'
  # ZWISCHENFORMAT_QUADRATISCH='${ZWISCHENFORMAT_QUADRATISCH}'
  # PAD='${PAD}'
  " | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

  #exit 215

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
fi


if [ -r ${AVERZ}/Filmwandler_Format_${ENDUNG}.txt ] ; then
    
        OP_QUELLE="1"
        unset FFMPEG_TARGET
        
	echo "IN_FPS='${IN_FPS}'"
	#exit 220

	. ${AVERZ}/Filmwandler_Format_${ENDUNG}.txt

else
	echo "Datei konnte nicht gefunden werden:"
	echo "${AVERZ}/Filmwandler_Format_${ENDUNG}.txt"
	exit 230
fi

echo "# 330
IN_FPS='${IN_FPS}'
OP_QUELLE='${OP_QUELLE}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 240

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
# 510 TONQUALIT='${TONQUALIT}'
"

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
	AUDIO_KANAELE="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep codec_type=audio | tr -s ';' '\n' | grep -E '^channels=' | awk -F'=' '{print $2}' | sort -nr | head -n1)"
	#----------------------------------------------------------------------#

	F_AUDIO_QUALITAET >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt 2>&1

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


#exit 250

echo "# 340
TONQUALIT='${TONQUALIT}'
AUDIOCODEC='${AUDIOCODEC}'
AUDIOQUALITAET='${AUDIOQUALITAET}'
Sound_ST='${Sound_ST}'
Sound_51='${Sound_51}'
Sound_71='${Sound_71}'
TS_ANZAHL='${TS_ANZAHL}'
STEREO='${STEREO}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 260

if [ "${TS_ANZAHL}" -gt 0 ] ; then
	# soll Stereo-Ausgabe erzwungen werden?
	if [ "x${STEREO}" = "x" ] ; then
		_ST=""
	else
		# wurde die Ausgabe bereits durch die Codec-Optionen auf Stereo gesetzt?
		BEREITS_AK2="$(echo "${AUDIOCODEC} ${AUDIO_CODEC_OPTION} ${AUDIOQUALITAET}" | grep -E 'ac 2|stereo')"
		if [ "x${BEREITS_AK2}" = "x" ] ; then
			_ST="${STEREO}"
		else
			_ST=""
		fi
	fi


	#--------------------------------------------------------------#
	# AUDIO_CODEC_OPTION
	# FFmpeg will die Angabe über den Codec sowie ggf. die Option "-ac 2" nur ein einziges Mal für alle Kanäle bekommen
	#--------------------------------------------------------------#
	AUDIO_VERARBEITUNG_01="-c:a ${AUDIOCODEC} ${AUDIO_CODEC_OPTION} ${AUDIOQUALITAET} $(for DIE_TS in ${TS_LISTE}
	do

		#
		# Multiple -q or -qscale options specified for stream 2, only the last option '-q:a 6.000000' will be used.
		#

		if [ "x${STEREO}" = "x" ] ; then
			AKN="$(echo "${DIE_TS}" | awk '{print $1 + 1}')"
			AUDIO_KANAELE="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep codec_type=audio | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E '^channels=' | awk -F'=' '{print $2}')"
			echo "# 350 - ${DIE_TS}
			AUDIO_KANAELE='${AUDIO_KANAELE}'
			" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
			AKL51="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep codec_type=audio | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E 'channel_layout=5.1')"
			AKL71="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep codec_type=audio | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E 'channel_layout=7.1')"
			if [ "x${AKL51}" != "x" ] ; then
				if [ "x${AUDIO_KANAELE}" = x ] ; then
					AUDIO_KANAELE=6
				fi
				#echo -n " -map 0:a:${DIE_TS} -c:a ${AUDIOCODEC} ${Sound_51}"
				echo -n " -map 0:a:${DIE_TS} ${Sound_51}"
			elif [ "x${AKL71}" != "x" ] ; then
				if [ "x${AUDIO_KANAELE}" = x ] ; then
					AUDIO_KANAELE=8
				fi
				#echo -n " -map 0:a:${DIE_TS} -c:a ${AUDIOCODEC} ${Sound_71}"
				echo -n " -map 0:a:${DIE_TS} ${Sound_71}"
			else
				if [ "x${AUDIO_KANAELE}" = x ] ; then
					AUDIO_KANAELE=2
				fi
				#echo -n " -map 0:a:${DIE_TS} -c:a ${AUDIOCODEC} ${Sound_ST}"
				echo -n " -map 0:a:${DIE_TS} ${Sound_ST}"
			fi
		else
			AUDIO_KANAELE="2"
			echo "# 360
			AUDIO_KANAELE='${AUDIO_KANAELE}'
			" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
			echo -n " -map 0:a:${DIE_TS} -c:a ${AUDIOCODEC} -ac 2"
		fi
	done)"
	#----------------------------------------------------------------------#

	TS_KOPIE="$(seq 0 ${TS_ANZAHL} | head -n ${TS_ANZAHL})"
	AUDIO_VERARBEITUNG_02="$(for DIE_TS in ${TS_KOPIE}
	do
		TONSPUR_SPRACHE="$(echo "${AUDIO_SPUR_SPRACHE}" | grep -E "^${DIE_TS} " | awk '{print $NF}' | head -n1)"

		echo -n " -map 0:a:${DIE_TS} -c:a copy"
	done)"

else
	AUDIO_VERARBEITUNG_01="-an"
	AUDIO_VERARBEITUNG_02="-an"
fi

echo "" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
echo "# 370
BEREITS_AK2='${BEREITS_AK2}'
TS_KOPIE='${TS_KOPIE}'
AUDIO_VERARBEITUNG_01='${AUDIO_VERARBEITUNG_01}'
AUDIO_VERARBEITUNG_02='${AUDIO_VERARBEITUNG_02}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 270

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#==============================================================================#
### Untertitel
#
# Multiple -c, -codec, -acodec, -vcodec, -scodec or -dcodec options specified for stream 9, only the last option '-c:s copy' will be used.
#

# -map 0:s:0 -c:s copy -map 0:s:1 -c:s copy		# "0" für die erste Untertitelspur
# -map 0:s:${i} -scodec copy				# alt
# -map 0:s:${i} -c:s copy				# neu
# UNTERTITEL="0,1,2,3,4"

if [ "${UNTERTITEL}" = "=0" ] ; then
	U_TITEL_FF_01=""
	U_TITEL_FF_ALT=""
	U_TITEL_FF_02=""
	UNTERTITEL_STANDARD_SPUR=""
else
	#----------------------------------------------------------------------#
	### STANDARD-UNTERTITEL-SPUR

	UNTERTITEL_SPUR_SPRACHE="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F codec_type=subtitle | tr -s ';' '\n' | fgrep 'TAG:language=' | awk -F'=' '{print $NF}' | nl | awk '{print $1-1,$2}')"

	### Die Bezeichnungen (Sprache) für die Audiospuren werden automatisch übernommen.
	if [ "x${SOLL_STANDARD_UNTERTITEL_SPUR}" = x ] ; then
		### wenn nichts angegeben wurde, dann
		### Deutsch als Standard-Sprache voreinstellen
		UNTERTITEL_STANDARD_SPUR="$(echo "${UNTERTITEL_SPUR_SPRACHE}" | grep -Ei " deu| ger" | awk '{print $1}' | head -n1)"

		if [ "x${UNTERTITEL_STANDARD_SPUR}" = x ] ; then
			### wenn nichts angegeben wurde
			### und es keine als deutsch gekennzeichnete Spur gibt, dann
			### STANDARD-UNTERTITEL-SPUR vom Originalfilm übernehmen
			### DISPOSITION:default=1
			UNTERTITEL_STANDARD_SPUR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | fgrep codec_type=subtitle | tr -s ';' '\n' | fgrep 'DISPOSITION:default=1' | grep -E 'default=[0-9]' | awk -F'=' '{print $2-1}')"
			if [ "x${UNTERTITEL_STANDARD_SPUR}" = x ] ; then
				### wenn es keine STANDARD-UNTERTITEL-SPUR im Originalfilm gibt, dann
				### alternativ einfach die erste Tonspur zur STANDARD-UNTERTITEL-SPUR machen
				UNTERTITEL_STANDARD_SPUR=0
			fi
		fi
	else
		### STANDARD-UNTERTITEL-SPUR manuell gesetzt
		UNTERTITEL_STANDARD_SPUR="${SOLL_STANDARD_UNTERTITEL_SPUR}"
	fi

	echo "# 375
	UNTERTITEL_SPUR_SPRACHE='${UNTERTITEL_SPUR_SPRACHE}'
	UNTERTITEL_STANDARD_SPUR='${UNTERTITEL_STANDARD_SPUR}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

	#exit 275

	#----------------------------------------------------------------------#
	if [ "x${UNTERTITEL}" = "x" ] ; then
		UTNAME="$(echo "${META_DATEN_STREAMS}" | grep -Fi codec_type=subtitle | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
		UT_META_DATEN="$(echo "${META_DATEN_STREAMS}" | fgrep -i codec_type=subtitle)"
		if [ "x${UT_META_DATEN}" != "x" ] ; then
			UT_LISTE="$(echo "${UT_META_DATEN}" | nl | awk '{print $1 - 1}' | tr -s '\n' ' ')"
		fi
	else
		UT_LISTE="$(echo "${UNTERTITEL}" | sed 's/,/ /g')"
	fi

	U_TITEL_FF_01="-c:s copy $(for DER_UT in ${UT_LISTE}
	do
		echo -n " -map 0:s:${DER_UT}?"
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
			U_TITEL_FF_ALT="-c:s ${UT_FORMAT} $(for DER_UT in ${UT_LISTE}
			do
				echo -n " -map 0:s:${DER_UT}?"
			done)"
		fi
	fi

	UT_ANZAHL="$(echo "${UT_LISTE}" | wc -w | awk '{print $1}')"
	UT_KOPIE="$(seq 0 ${UT_ANZAHL} | head -n ${UT_ANZAHL})"
	U_TITEL_FF_02="$-c:s copy (for DER_UT in ${UT_KOPIE}
	do
		echo -n " -map 0:s:${DER_UT}?"
	done)"
fi

echo "# 380
TS_LISTE='${TS_LISTE}'

UT_META_DATEN='${UT_META_DATEN}'

UNTERTITEL='${UNTERTITEL}'
UT_LISTE='${UT_LISTE}'
U_TITEL_FF_01='${U_TITEL_FF_01}'
U_TITEL_FF_ALT='${U_TITEL_FF_ALT}'
U_TITEL_FF_02='${U_TITEL_FF_02}'

AUDIO_STANDARD_SPUR='${AUDIO_STANDARD_SPUR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 380

#==============================================================================#
### Meta-Daten aufbereiten
###

META_DATEN_DISPOSITIONEN=""

#------------------------------------------------------------------------------#
### Ton

for DIE_TS in ${TS_LISTE}
do
	#----------------------------------------------------------------------#
	### Die Werte für "Disposition" für die Tonspur werden nach dem eigenen Wunsch gesetzt.
	# -disposition:a:0 default
	# -disposition:a:1 0
	# -disposition:a:2 0

	if [ "x${AUDIO_STANDARD_SPUR}" != x ] ; then
		if [ "${DIE_TS}" = "${AUDIO_STANDARD_SPUR}" ] ; then
			META_DATEN_DISPOSITIONEN="${META_DATEN_DISPOSITIONEN} -disposition:a:${DIE_TS} default"
			echo "# 381
			META_DATEN_DISPOSITIONEN='${META_DATEN_DISPOSITIONEN}'
			" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
		else
			META_DATEN_DISPOSITIONEN="${META_DATEN_DISPOSITIONEN} -disposition:a:${DIE_TS} 0"
			echo "# 382
			META_DATEN_DISPOSITIONEN='${META_DATEN_DISPOSITIONEN}'
			" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
		fi
	fi
done

echo "# 385
SOLL_STANDARD_AUDIO_SPUR='${SOLL_STANDARD_AUDIO_SPUR}'
AUDIO_STANDARD_SPUR='${AUDIO_STANDARD_SPUR}'
META_DATEN_DISPOSITIONEN='${META_DATEN_DISPOSITIONEN}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 285

#------------------------------------------------------------------------------#
### Untertitel

for DIE_US in ${UT_LISTE}
do
	#----------------------------------------------------------------------#
	### Die Werte für "Disposition" für die Untertitelspur werden nach dem eigenen Wunsch gesetzt.
	# -disposition:s:0 default
	# -disposition:s:1 0
	# -disposition:s:2 0

	if [ "x${UNTERTITEL_STANDARD_SPUR}" != x ] ; then
		if [ "${DIE_US}" = "${UNTERTITEL_STANDARD_SPUR}" ] ; then
			META_DATEN_DISPOSITIONEN="${META_DATEN_DISPOSITIONEN} -disposition:s:${DIE_US} default"
		else
			META_DATEN_DISPOSITIONEN="${META_DATEN_DISPOSITIONEN} -disposition:s:${DIE_US} 0"
		fi
	fi
done

echo "# 390
SOLL_STANDARD_UNTERTITEL_SPUR='${SOLL_STANDARD_UNTERTITEL_SPUR}'
UNTERTITEL_STANDARD_SPUR='${UNTERTITEL_STANDARD_SPUR}'
META_DATEN_DISPOSITIONEN='${META_DATEN_DISPOSITIONEN}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 290

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
### Korrektureingriff

if [ "x${PIXELKORREKTUR}" != x ] ; then
	BILD_SCALE="${PIXELKORREKTUR}"
fi

#------------------------------------------------------------------------------#
# Transkodierung
#
# vor PAD muss eine Auflösung, die der Originalauflösung entspricht, die aber
# für quadratische Pixel ist;
# oder man muss die Seitenverhältnisse für FFmpeg um den gleichen Wert verzerren,
# wie die Bildpunkte im Quell-Film;
# hinter PAD muss dann die endgültig gewünschte Auflösung für quadratische Pixel
# stehen
#
if [ "${TEST}" = "Ja" ] ; then
	if [ "x${CROP}" = "x" ] ; then
		VIDEOOPTION="$(echo "${VIDEOQUALITAET}" | sed 's/[,]$//')"
	else
		VIDEOOPTION="$(echo "${VIDEOQUALITAET} -vf ${CROP}${BILD_DREHUNG}" | sed 's/[,]$//;s/[,][,]/,/g')"
	fi
else
	if [ "x${ZEILENSPRUNG}${CROP}${PAD}${BILD_SCALE}${h263_BILD_FORMAT}${FORMAT_ANPASSUNG}" = "x" ] ; then
		VIDEOOPTION="$(echo "${VIDEOQUALITAET}" | sed 's/[,]$//')"
	else
		VIDEOOPTION="$(echo "${VIDEOQUALITAET} -vf ${ZEILENSPRUNG}${CROP}${PAD}${BILD_SCALE}${h263_BILD_FORMAT}${FORMAT_ANPASSUNG}${BILD_DREHUNG}" | sed 's/[,]$//;s/[,][,]/,/g')"
	fi
fi

if [ "x${SOLL_FPS}" = "x" ] ; then
	unset FPS
else
	FPS="-r ${SOLL_FPS}"
fi

START_ZIEL_FORMAT="-f ${FORMAT}"

#------------------------------------------------------------------------------#

SCHNITT_ANZAHL="$(echo "${SCHNITTZEITEN}" | wc -w | awk '{print $1}')"

#------------------------------------------------------------------------------#

echo "# 400
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
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 300

#set -x

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
### Wenn Audio- und Video-Spur nicht synchron sind,
### dann muss das korrigiert werden.

if [ "x${VIDEO_SPAETER}" = "x" ] ; then
	unset VIDEO_DELAY
else
	VIDEO_DELAY="-itsoffset ${VIDEO_SPAETER}"
fi

if [ "x${AUDIO_SPAETER}" = "x" ] ; then
	unset VIDEO_DELAY
else
	VIDEO_DELAY="-itsoffset -${AUDIO_SPAETER}"
fi

#------------------------------------------------------------------------------#
#--- Video --------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
### Bei VCD und DVD
### werden die Codecs nicht direkt angegeben

CODEC_ODER_TARGET="$(echo "${VIDEOCODEC}" | fgrep -- '-target ')"
if [ "x${CODEC_ODER_TARGET}" = x ] ; then
	VIDEO_PARAMETER_TRANS="-map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME}"
else
	VIDEO_PARAMETER_TRANS="-map 0:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME}"
fi

VIDEO_PARAMETER_KOPIE="-map 0:v -c:v copy"

if [ "${VIDEO_NICHT_UEBERTRAGEN}" = "0" ] ; then
	VIDEO_PARAMETER_TRANS="-vn"
	VIDEO_PARAMETER_KOPIE="-vn"
	U_TITEL_FF_01=""
	U_TITEL_FF_ALT=""
	U_TITEL_FF_02=""
fi

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
### Funktionen

# Es wird nur ein einziges Stück transkodiert
transkodieren_1_1()
{
	### 1001
	echo "# 410
	${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${VON} ${BIS} ${FPS} ${SCHNELLSTART} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${START_ZIEL_FORMAT} -y \"${ZIELVERZ}\"/\"${ZIEL_FILM}\".${ENDUNG}" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	echo
        ${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${VON} ${BIS} ${FPS} ${SCHNELLSTART} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${START_ZIEL_FORMAT} -y "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG} 2>&1 && WEITER=OK || WEITER=ALT
	echo "# 420
	WEITER='${WEITER}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
}

#------------------------------------------------------------------------------#
# Es wird nur ein einziges Stück transkodiert
# aber der erste Versuch ist fehlgeschlagen
# deshalb wird jetzt mit alternativem Untertitelformat probiert
transkodieren_2_1()
{
	### 1002
	echo "# 430
	${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_ALT} ${VON} ${BIS} ${FPS} ${SCHNELLSTART} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${START_ZIEL_FORMAT} -y \"${ZIELVERZ}\"/\"${ZIEL_FILM}\".${ENDUNG}" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	echo
	${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_ALT} ${VON} ${BIS} ${FPS} ${SCHNELLSTART} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${START_ZIEL_FORMAT} -y "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG} 2>&1 && WEITER=OK || WEITER=OHNE
	echo "# 440
	WEITER='${WEITER}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
}

#------------------------------------------------------------------------------#
# Es wird nur ein einziges Stück transkodiert
# aber der zweite Versuch ist auch fehlgeschlagen
# darum wird jetzt zum letzten Mal ohne Untertitel probiert
transkodieren_3_1()
{
	### 1003
	echo "# 450
	${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${VON} ${BIS} ${FPS} ${SCHNELLSTART} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${START_ZIEL_FORMAT} -y \"${ZIELVERZ}\"/\"${ZIEL_FILM}\".${ENDUNG}" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	echo
	${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${VON} ${BIS} ${FPS} ${SCHNELLSTART} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${START_ZIEL_FORMAT} -y "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG} 2>&1 && WEITER=OK || WEITER=NEIN
	echo "# 460
	WEITER='${WEITER}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
}

#------------------------------------------------------------------------------#
# Es werden mehrere Teil aus dem Original transkodiert und am Ende zu einem Film zusammengesetzt
transkodieren_4_1()
{
	### 1004
	echo "# 470
	${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} -ss ${VON} -to ${BIS} ${FPS} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${START_ZIEL_FORMAT} -y ${ZUFALL}_${NUMMER}_${PROTOKOLLDATEI}.${ENDUNG}" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	echo
        ${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} -ss ${VON} -to ${BIS} ${FPS} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${START_ZIEL_FORMAT} -y ${ZUFALL}_${NUMMER}_${PROTOKOLLDATEI}.${ENDUNG} 2>&1 && WEITER=OK || WEITER=ALT
	echo "# 480
	WEITER='${WEITER}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
}

#------------------------------------------------------------------------------#
# Es werden mehrere Teil aus dem Original transkodiert und am Ende zu einem Film zusammengesetzt
# aber der erste Versuch ist fehlgeschlagen
# deshalb wird jetzt mit alternativem Untertitelformat probiert
transkodieren_5_1()
{
	### 1005
	echo "# 490
	${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_ALT} -ss ${VON} -to ${BIS} ${FPS} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${START_ZIEL_FORMAT} -y ${ZUFALL}_${NUMMER}_${PROTOKOLLDATEI}.${ENDUNG}" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	echo
	${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_ALT} -ss ${VON} -to ${BIS} ${FPS} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${START_ZIEL_FORMAT} -y ${ZUFALL}_${NUMMER}_${PROTOKOLLDATEI}.${ENDUNG} 2>&1 && WEITER=OK || WEITER=OHNE
	echo "# 500
	WEITER='${WEITER}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
}

#------------------------------------------------------------------------------#
# Es werden mehrere Teil aus dem Original transkodiert und am Ende zu einem Film zusammengesetzt
# aber der zweite Versuch ist auch fehlgeschlagen
# darum wird jetzt zum letzten Mal ohne Untertitel probiert
transkodieren_6_1()
{
	### 1006
	echo "# 510
	${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} -ss ${VON} -to ${BIS} ${FPS} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${START_ZIEL_FORMAT} -y ${ZUFALL}_${NUMMER}_${PROTOKOLLDATEI}.${ENDUNG}" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	echo
	${PROGRAMM} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}" ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} -ss ${VON} -to ${BIS} ${FPS} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${START_ZIEL_FORMAT} -y ${ZUFALL}_${NUMMER}_${PROTOKOLLDATEI}.${ENDUNG} 2>&1 && WEITER=OK || WEITER=NEIN
	echo "# 520
	WEITER='${WEITER}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
}

#------------------------------------------------------------------------------#
# Hiermit werden die transkodierten Teil zu einem Film zusammengesetzt
transkodieren_7_1()
{
	### 1007
	echo "# 530
	${PROGRAMM} -f concat -i "${ZIELVERZ}"/${ZUFALL}_${PROTOKOLLDATEI}_Filmliste.txt ${VIDEO_PARAMETER_KOPIE} ${AUDIO_VERARBEITUNG_02} ${U_TITEL_FF_02} ${SCHNELLSTART} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${START_ZIEL_FORMAT} -y "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG}
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	${PROGRAMM} -f concat -i "${ZIELVERZ}"/${ZUFALL}_${PROTOKOLLDATEI}_Filmliste.txt ${VIDEO_PARAMETER_KOPIE} ${AUDIO_VERARBEITUNG_02} ${U_TITEL_FF_02} ${SCHNELLSTART} ${META_DATEN_DISPOSITIONEN} ${METADATEN_BESCHREIBUNG} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${START_ZIEL_FORMAT} -y "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG}
	echo "# 540
	WEITER='${WEITER}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

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
	### 1001
	transkodieren_1_1

	if [ "${WEITER}" = ALT ] ; then
		echo
		### 1002
		transkodieren_2_1
	fi

	if [ "${WEITER}" = OHNE ] ; then
		rm -vf "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG} | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
		ZIEL_FILM="${ZIELNAME}_-_ohne_Untertitel"
		echo
		### 1003
		transkodieren_3_1
	fi

else

	#----------------------------------------------------------------------#
	ZUFALL="$(head -c 100 /dev/urandom | base64 | tr -d '\n' | tr -cd '[:alnum:]' | cut -b-12)"
	rm -f "${ZIELVERZ}"/${ZUFALL}_${PROTOKOLLDATEI}_Filmliste.txt
	NUMMER="0"
	for _SCHNITT in ${SCHNITTZEITEN}
	do
		echo "---------------------------------------------------------" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

		NUMMER="$(echo "${NUMMER}" | awk '{printf "%2.0f\n", $1+1}' | tr -s ' ' '0')"
		VON="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $1}')"
		BIS="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $2}')"

		###----------------------------------------------------------###
		### hier werden die Teile zwischen der Werbung transkodiert  ###
		###----------------------------------------------------------###
		echo
		### 1004
		transkodieren_4_1

		if [ "${WEITER}" = ALT ] ; then
			echo
			### 1005
			transkodieren_5_1
		fi

		if [ "${WEITER}" = OHNE ] ; then
			ZIEL_FILM="${ZIELNAME}_-_ohne_Untertitel"
			echo
			### 1006
			transkodieren_6_1
		fi

		ffprobe -v error -i ${ZUFALL}_${NUMMER}_${PROTOKOLLDATEI}.${ENDUNG} | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

                ### den Film in die Filmliste eintragen
                echo "echo \"file '${ZUFALL}_${NUMMER}_${PROTOKOLLDATEI}.${ENDUNG}'\" >> \"${ZIELVERZ}\"/${ZUFALL}_${PROTOKOLLDATEI}_Filmliste.txt" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
                echo "file '${ZUFALL}_${NUMMER}_${PROTOKOLLDATEI}.${ENDUNG}'" >> "${ZIELVERZ}"/${ZUFALL}_${PROTOKOLLDATEI}_Filmliste.txt

		echo "---------------------------------------------------------" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	done

	### 1007
	transkodieren_7_1

	rm -f "${ZIELVERZ}"/${ZUFALL}_*.txt

	ffprobe -v error -i "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG} | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

	#ls -lh ${ZUFALL}_*.${ENDUNG}
	rm -f ${ZUFALL}_*.${ENDUNG}

fi

#------------------------------------------------------------------------------#

ls -lh "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG} "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

LAUFZEIT="$(echo "${STARTZEITPUNKT} $(date +'%s')" | awk '{print $2 - $1}')"
echo "# 550
$(date +'%F %T') (${LAUFZEIT})" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 310
