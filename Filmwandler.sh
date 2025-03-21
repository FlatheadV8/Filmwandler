#!/bin/sh

#------------------------------------------------------------------------------#
#!/usr/bin/env bash
#
# Dieses Skript verändert NICHT die Bildwiederholrate!
#
# Das Ergebnis besteht immer aus folgendem Format:
#  - WebM:    webm   + AV1        + Opus    (kann nur das eine Untertitelformat WebVTT)
#  - MKV:     mkv    + AV1        + Vorbis  (das z.Z. beste Format, leider aber kein HTML5-Standard)
#  - MP4:     mp4    + H.264/AVC  + AAC     (das z.Z. mit Abstand kompatibelste Format)
#  - MP4:     mp4    + H.265/HEVC + AAC
#  - AVCHD:   m2ts   + H.264/AVC  + AC-3
#  - AVI:     avi    + DivX5      + MP3
#  - FLV:     flv    + FLV        + MP3     (Sorenson Spark: H.263)
#  - 3GPP:    3gp    + H.263      + AAC     (128x96 176x144 352x288 704x576 1408x1152)
#  - 3GPP2:   3g2    + H.263      + AAC     (128x96 176x144 352x288 704x576 1408x1152)
#  - OGG:     ogg    + Theora     + Vorbis
#  - MPEG:    mpg/ts + MPEG-1/2   + MP2/AC-3 (bei kleinen Bitraten ist MPEG-1 besser)
#
# https://de.wikipedia.org/wiki/Containerformat
#
#------------------------------------------------------------------------------#
#
# Es werden folgende Programme von diesem Skript verwendet:
#  - bash
#  - ffmpeg
#  - ffprobe
#  - ggf. noch externe Bibliotheken für ffmpeg
#  - und weitere Unix-Shell-Werkzeuge (z.B. du, sed und awk)
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
#VERSION="v2021080700"			# Untertitelabschaltung verbessert
#VERSION="v2021091500"			# Jetzt kann man auch manuell einen Kommentar einfügen
#VERSION="v2021091600"			# alternatives Untertitel-Format MKV->webvtt hinzugefügt
#VERSION="v2021100100"			# wenn PAR und DAR nicht ermittelt werden konnten, dann wird IN_PAR="1:1" gesetzt
#VERSION="v2021101200"			# es wurde die Anzahl der Pixel nicht richtig berechnet, dadurch wurde die Auflösung geringer als nötig berechnet
#VERSION="v2021102100"			# Fehler in Zeile 1511 ("BASISWERTE=") behoben
#VERSION="v2021102600"			# wenn kein Untertitel gewünscht wird, dann wird jetzt die Option "-sn" hinzugefügt
#VERSION="v2021110200"			# ffmpeg kommt mit Umlauten in der Zieldatei nicht klar, jetzt wird davor gewarnt
#VERSION="v2022012200"			# Fehler bei IN_DAR behoben, der nur bei sehr wenigen Videos auftritt
#VERSION="v2022072400"			# wenn auch das alternative Untertitel-Format nicht funktioniert, dann wird jetzt explizit "-sn" gesetzt
#VERSION="v2022072600"			# Fehler im Abschnitt für die Option "-stereo" (Zeile 1808) behoben
#VERSION="v2022073100"			# Abbrüche bei zu wenig RAM behoben
#VERSION="v2022073100"			# Schalter für den (minimalen) HDTV-Standard ("HD ready") eingerichtet
#VERSION="v2022080200"			# Schalter -ffprobe eingerichtet, um eigene Scan-Größen angeben zu können
#VERSION="v2022080300"			# Fehler bei der AVC-Profil-Level-Bestimmung behoben, es wurde die In-Auflösung und nicht die Out-Auflösung zur Berechnung verwendet
#VERSION="v2022080700"			# Tests haben ergeben, das manche Set-Top-Boxen nur eine Tonspur können, deshalb wird ab jetzt mit den Parametern -hdtvmin oder -minihd nur noch die erste Tonspur in den Film übernommen
#VERSION="v2022080800"			# jetzt werden die Filme, die mit dem Parameter -hdtvmin oder -minihd verkleinert werden den Namenszusatz HD-ready bekommen
#VERSION="v2022110300"			# Kommentar und Hilfe leicht angepasst
#VERSION="v2022120300"			# Sprachen nach ISO-639-2 für Ton- und Untertitelspuren können jetzt mit angegeben werden und überschreiben die Angaben aus der Quelle
#VERSION="v2022120500"			# Video-Format (Alternative zur Endung): -format
#VERSION="v2022120600"			# HLS-Kompatibilität (ersteinmal nur die Einschränkung auf die erlaubten Bildschirmauflösungen)
#VERSION="v2022120601"			# Selektion für die FLK-kompatibelen Bildauflösungen verbessert
#VERSION="v2022120602"			# bei HLS-Kompatibilität wird der Dateiname geändert, ähnlich wie bei "HD ready"
#VERSION="v2022120700"			# Zusammenspiel von HDTV und HLS verbessert
#VERSION="v2022120700"			# RegEx-Fehler in Zeile 1192 behoben
#VERSION="v2022121100"			# Mit der Option -format können die Vorgaben der Cdecs überschrieben werden.
#VERSION="v2022121900"			# es können jetzt alternative Video- und Audio-Codecs angegeben werden: -cv ... -ca ...
#VERSION="v2022122000"			# Die Optionen -cv ... -ca ... waren falsch platziert.
#VERSION="v2022122200"			# Fehler in der Untertitelbeschriftung behoben
#VERSION="v2023021100"			# Fehler im Container-Format bei Verwendung von -format behoben
#VERSION="v2023021200"			# letzter Fehler in der Untertitelbeschriftung behoben
#VERSION="v2023032100"			# Kommentare und Beschreibungen verbessert
#VERSION="v2023040900"			# HLS-Kommentare verbessert und die Kodek-Einschränkung aufgehoben, sowie Fehler in HLS-Bildauflösung repariert
#VERSION="v2023042200"			# Film-Titel wird jetzt vom Original übernommen, wenn er nicht angegeben wird
#VERSION="v2023042300"			# es können jetzt auch externe Untertitel in den Film mit eingebunden werden
#VERSION="v2023042400"			# Fehler behoben, der kam, wenn kein Untertitel vorhanden war
#VERSION="v2023042500"			# Hilfe hinzugefügt, wie Untertitel-Dateien übergeben werden
#VERSION="v2023050600"			# neue Option: zur Begrenzung für den "FireTV Gen. 2" + von "-tune film" auf "-tune ssim" umgestellt
#VERSION="v2023051100"			# Variable "CPU_KERNE" mit Anzahl der verfügbaren CPU-Kernen gefüllt
#VERSION="v2023051200"			# FireTV-Profil überarbeitet; hdtvmin -> hdready umbenannt; hls und hdready sind jetzt Profile wie firetv
#VERSION="v2023051300"			# ab jetzt ist das normalisieren von DAR auf einen der Standards (16/9 oder 4/3) nicht mehr die Voreinstellung
#VERSION="v2023051900"			# PATH-Variable angepasst + optimiert für /bin/sh
#VERSION="v2023052300"			# da es im neuen FFmpeg mcdeint nicht mehr gibt, wurde von yadif=1/3,mcdeint=mode=extra_slow auf yadif=1:-1:0 umgestellt + Fehler bei Abbruch von ffmpeg behoben
#VERSION="v2023052600"			# das Profil fullhd konnte nicht aufgerufen werden / ein neues universelles Profil ist dazu gekommen, bei dem eine Auflösung frei gewählt werden kann
#VERSION="v2023060300"			# 2-Pass aktivieren
#VERSION="v2023060700"			# 2-Pass Aktivierung als Option eingebaut
#VERSION="v2023060800"			# Fehler bei Untertitelbehandlung behoben
#VERSION="v2023061000"			# jetzt wird für jeden Audio-Kanal separat die Bit-Rate berechnet
#VERSION="v2023061400"			# von IFRAME="-g 1" auf IFRAME="-g 5" umgestellt
#VERSION="v2023061600"			# von IFRAME="-g 5" auf IFRAME="-g 300" umgestellt
#VERSION="v2023061600"			# ffmpeg -benchmark -report
#VERSION="v2023082900"			# AUDIO_SPUR_SPRACHE für den Fall repariert, dass die Sprache der Tonspur mit übergeben wird
#VERSION="v2023112100"			# Reihenfolge der Audio- und Untertiteloptionen geordnet
#VERSION="v2023112300"			# AUDIO_STANDARD_SPUR und UNTERTITEL_STANDARD_SPUR repariert
#VERSION="v2023121700"			# Fehler behoben: bei undefinierten Audio-Spuren wurden keine Audio-Optionen für FFmpeg generiert
#VERSION="v2024031000"			# Fehler im Profil HLS behoben
#VERSION="v2024031600"			# ab jetzt wird bei Fehlschlag bedingungslos abgebrochen und nicht mehr mit automatisch veränderten Untertiteleinstellungen weiter probiert
#VERSION="v2024031900"			# für die wichtigsten 4 Codecs gibt es jetzt eine Option zum verlusstfreien transkodieren
#VERSION="v2024041700"			# Fehler im 2-Pass-Bereich behoben
#VERSION="v2024041900"			# Fehler im Schnitt-Bereich behoben
#VERSION="v2024042700"			# Fehler im Transkodierkommando beim maskieren des Filmnamens behoben + Schutz vor unsicheren Dateinamen, das Leerzeichen erlaube ich aber
#VERSION="v2024050100"			# Chrom-Leisten poliert
#VERSION="v2024051500"			# mit "-soll_dar" kann jetzt das Display-Format, des zu erstellenden Videos angegeben werden
#VERSION="v2024051800"			# mit "-ton =0" kann man jetzt Filme ohne Tonspur erzeugen
#VERSION="v2024051801"			# mit "-kerne" (z.B.: -kerne 1) kann man jetzt angeben, wieviel Kerne benutzt werden sollen; z.B. wenn zuviel RAM belegt wird, kann man die Anzahl der zu nutzenden CPU-Kerne reduzieren, das reduziert, bei vielen Codecs, auch die RAM-Belegung
#VERSION="v2024062200"			# Fehler in der Verarbeitung ohne Video-Spur behoben
#VERSION="v2024091700"			# Deutsche Ton- und Untertitelspuren werden jetzt nach vorne sortiert
#VERSION="v2025012500"			# Fehler behoben: die erste Tonspur (DE) ist jetzt immer die "Default"-Tonspur: -disposition:a:0 default
VERSION="v2025031600"			# wenn ein zu großer Bereich von einer Datei übersprungen wird, dann muß dieser Wert erhöht werden: max_muxing_queue_size


VERSION_METADATEN="${VERSION}"

#
# e[cx][hi][ot]
#
#
# Bild mit Tonspur
# -shortest
# ffmpeg -framerate 1/1988 -i kein_Fachbuch_beantwortet_die_Frage_warum_Schwangere_Verrueckt_werden.png -i kein_Fachbuch_beantwortet_die_Frage_warum_Schwangere_Verrueckt_werden.mp4 -map 0:v:0 -c:v libx264 -preset veryslow -tune film -x264opts ref=4:b-pyramid=strict:bluray-compat=1:weightp=0:vbv-maxrate=12500:vbv-bufsize=12500:level=3:slices=4:b-adapt=2:direct=auto:colorprim=bt709:transfer=bt709:colormatrix=bt709:keyint=50:aud:subme=9:nal-hrd=vbr -crf 20 -vf yadif,scale=856x480,pad='max(iw\,ih*(16/9)):ow/(16/9):(ow-iw)/2:(oh-ih)/2',setdar='16/9',fps='25' -keyint_min 150 -map 1:a:0 -c:a aac -b:a 336k -ac 2 -disposition:a:0 default -ss 1 -to 79 -movflags faststart -f mp4 -y Maenner_haben_es_schwer.mp4
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
# -metadata:s:s:0 language=ger


#set -x
PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

#
# https://sites.google.com/site/linuxencoding/x264-ffmpeg-mapping
# -keyint <int>
#
# ffmpeg -h full 2>/dev/null | grep -F keyint
# -keyint_min        <int>        E..V.... minimum interval between IDR-frames (from INT_MIN to INT_MAX) (default 25)
#IFRAME="-keyint_min 2-8"		# --keyint in Frames
#IFRAME="-keyint_min 150"		# --keyint in Frames
IFRAME="-g 300"				# Keyframe interval: -g in Frames

LANG=C					# damit AWK richtig rechnet
#FFMPEG_OPTIONEN="-benchmark -report"
FFMPEG_OPTIONEN="-benchmark"
Film2Standardformat_OPTIONEN="${@}"
TEST="Nein"
STOP="Nein"
BILDQUALIT="auto"
TONQUALIT="auto"
ORIGINAL_DAR="Ja"
TWO_PASS="Nein"

MUXING_QUEUE_SIZE_FAKTOR="30"		# -max_muxing_queue_size $(-ss * FAKTOR) / Work-Around um einen Bug in FFmpeg
AVERZ="$(dirname ${0})"			# Arbeitsverzeichnis, hier liegen diese Dateien

### die Pixel sollten wenigstens durch 2 teilbar sein! besser aber durch 8                          
TEILER="2"
##TEILER="4"
#TEILER="8"
###TEILER="16"

ZUFALL="$(head -c 100 /dev/urandom | base64 | tr -d '\n' | tr -cd '[:alnum:]' | cut -b-12)"

#==============================================================================#
### Funktionen

#------------------------------------------------------------------------------#

# einbinden der Namen von vielen Bildauflösungen
BILDAUFLOESUNGEN_NAMEN="${AVERZ}/Filmwandler_grafik.txt"
if [ -r "${BILDAUFLOESUNGEN_NAMEN}" ] ; then
	. ${BILDAUFLOESUNGEN_NAMEN}
	BILD_FORMATNAMEN_AUFLOESUNGEN="$(bildaufloesungen_namen)"
fi

#------------------------------------------------------------------------------#

ausgabe_hilfe()
{
echo "# 10
#==============================================================================#
"
grep -E -h '^[*][* ]' ${AVERZ}/Filmwandler_Format_*.txt
echo "# 20
#==============================================================================#
"
}

#------------------------------------------------------------------------------#

meta_daten_streams()
{
	KOMPLETT_DURCHSUCHEN="-probesize ${FFPROBE_PROBESIZE}M -analyzeduration ${FFPROBE_PROBESIZE}M"
	echo "# 30 meta_daten_streams: ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i \"${FILMDATEI}\" -show_streams"
	META_DATEN_STREAMS="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_streams 2>> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt)"
	if [ x = "x${META_DATEN_STREAMS}" ] ; then
		### Killed
		echo "# 40:
		Leider hat der erste ffprobe-Lauf nicht funktioniert,
		das deutet auf zu wenig verfügbaren RAM hin.
		Der ffprobe-Lauf wird erneut gestartet, jedoch wird
		jetzt nicht der komplette Film durchsucht.
		Das bedeutet, dass z.B. Untertitel, die erst später im Film beginnen,
		nicht gefunden und nicht berücksichtigt werden können.

		starte die Funktion: meta_daten_streams"

		FFPROBE_PROBESIZE="$(echo "${FFPROBE_PROBESIZE}" | awk '{printf "%.0f\n", $1/2 + 1}')"
		echo "# 50 META_DATEN_STREAMS: probesize ${FFPROBE_PROBESIZE}M"
		meta_daten_streams
	fi
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

	if [ x = "x${BILD_SCALE}" ] ; then
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

	if [ x = "x${SOLL_DAR}" ] ; then
		FORMAT_ANPASSUNG="setdar='${BREITE}/${HOEHE}',"
	fi
}


video_format()
{
	if [ x = "x${VIDEO_FORMAT}" ] ; then
		VIDEO_FORMAT=${ENDUNG}
	else
		VIDEO_FORMAT="$(echo "${VIDEO_FORMAT}" | awk '{print tolower($1)}')"
	fi
}


suche_video_encoder()
{
	ffmpeg -encoders 2>/dev/null | awk '/^ V/{print $2}' | grep -Fv '=' | grep -E "${1}" | head -n1
}


suche_audio_encoder()
{
	ffmpeg -encoders 2>/dev/null | awk '/^ A/{print $2}' | grep -Fv '=' | grep -E "${1}" | head -n1
}


#==============================================================================#

if [ x = "x${1}" ] ; then
        ${0} -h
	exit 60
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
		-k)
			KOMMENTAR="${2}"			# Kommentar/Beschreibung des Filmes
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
		-soll_dar)
			SOLL_DAR="${2}"				# Display-Format, des zu erstellenden Videos
			shift
			;;
		-std_dar)
			ORIGINAL_DAR="Nein"			# das Seitenverhältnis wird automatisch entweder auf 16/9 oder 4/3 geändert
			shift
			;;
		-orig_dar)
			ORIGINAL_DAR="Ja"			# das originale Seitenverhältnis soll beibehalten werden
			shift
			;;
		-fps|-soll_fps)
			SOLL_FPS="${2}"				# FPS (Bilder pro Sekunde) für den neuen Film festlegen
			shift
			;;
      		-2pass)
			TWOPASS="Ja"				# 2-Pass aktivieren (funktioniert z.Z. nur bei VP9 und AOM-AV1)
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
			AUDIO_STANDARD_SPUR="${2}"		# -standard_ton 5
			shift
			;;
		-standard_u)
			# Wird diese Option nicht verwendet,
			# dann wird die Einstellung aus dem Originalfilm übernommen
			# "0" für die erste Untertitelspur
			# "5" für die sechste Untertitelspur
			UNTERTITEL_STANDARD_SPUR="${2}" 	# -standard_u 5
			shift
			;;
		-ton)
			# Wird diese Option nicht verwendet, dann werden ALLE Tonspuren eingebettet
			# "=0" keine Tonspur
			# "0" für die erste Tonspur
			# "1" für die zweite Tonspur
			# "0,1" für die erste und die zweite Tonspur
			#
			# der Film soll keine Tonspuren (in der gewünschten Reihenfolge) angeben
			# -ton =0
			#
			# die gewünschten Tonspuren (in der gewünschten Reihenfolge) angeben
			# -ton 0,1,2,3,4
			#
			# Sprachen nach ISO-639-2 für Tonspuren können jetzt mit angegeben werden und überschreiben die Angaben aus der Quelle.
			# für die angegebenen Tonspuren auch noch die entsprechende Sprache mit angeben
			# -ton 0:deu,1:eng,2:spa,3:fra,4:ita
			#
			TON_SPUR_SPRACHE="${2}"			# -ton 0,1,2,3,4 / -ton 0:deu,1:eng,2:spa,3:fra,4:ita
			shift
			;;
		-ffprobe)
			# Dieser Wert gibt an wie weit von beginn der Filmdatei an
			# ffprobe nach Tonspuren und Untertiteln suchen soll.
			# Ist der Wert zu klein, dann werden beispielsweise keine
			# Untertitel gefunden, die erst sehr spät beginnen.
			# Der Wert sollte so groß sein wie der zu transkodierende Film ist.
			# Die Voreinstellung ist "9223372036854" MiB
			# Das ist der praktisch ermittelte Maximalwert von einem
			# "Intel(R) Core(TM) i5-10600T CPU @ 2.40GHz"
			# auf einem "FreeBSD 13.0"-System mit 64 GiB RAM.
			# 
			# Hat der Film nur eine Tonspur, die ganz am Anfang des Films beginnt, und keine Untertitel,
			# dann kann der Wert sehr klein gehalten werden. Zum Beispiel: 10
			SOLL_PROBESIZE="${2}"		# ffprobe-Scan-Größe in MiB
			shift
			;;
		-profil)
			# folgenden Parameter werden begrenzt:
			# Auflösung
			PROFIL_NAME="${2}"				# hls, hdready, firetv
			shift
			;;
		-format)
			# Das Format ist normalerweise durch die Dateiendung der Ziel-Datei vorgegeben.
			# Diese Vorgabe kann mit dieser Option überschrieben werden.
			VIDEO_FORMAT="${2}"			# Video-Format: 3g2, 3gp, avi, flv, m2ts, mkv, mp4, mpg, ogg, ts, webm
			shift
			;;
		-cv)
			# Das Format (Video-Codec + Audio-Codec) ist normalerweise durch die Dateiendung der Ziel-Datei vorgegeben.
			# Mit dieser Option kann der Video-Codec überschrieben werden.
			ALT_CODEC_VIDEO="${2}"			# Video-Codec: 261, 262, 263, 264, 2640, 265, 2650, av1, av10, divx, ffv1, flv, snow, theora, vc2, vp8, vp9, vp90, xvid
			shift
			;;
		-ca)
			# Das Format (Video-Codec + Audio-Codec) ist normalerweise durch die Dateiendung der Ziel-Datei vorgegeben.
			# Mit dieser Option kann der Audio-Codec überschrieben werden.
			ALT_CODEC_AUDIO="${2}"			# Audio-Codec: aac, ac3, mp2, mp3, opus, vorbis
			shift
			;;
		-stereo)
			STEREO="Ja"
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
			# Wird diese Option nicht verwendet, dann werden ALLE Untertitelspuren eingebettet
			# "=0" für keinen Untertitel
			# "0" für die erste Untertitelspur
			# "1" für die zweite Untertitelspur
			# "0,1" für die erste und die zweite Untertitelspur
			#
			# der Film soll keine Untertitelspuren enthalten
			# -u =0
			#
			# die gewünschten Untertitelspuren (in der gewünschten Reihenfolge) angeben
			# -u 0,1,2,3,4
			#
			# Sprachen nach ISO-639-2 für Untertitelspuren können jetzt mit angegeben werden und überschreiben die Angaben aus der Quelle.
			# für die angegebenen Untertitelspuren auch noch die entsprechende Sprache mit angeben
			# -u 0:deu,1:eng,2:spa,3:fra,4:ita
			#
			# Es können jetzt auch externe Untertiteldateien mit eingebunden werden.
			# -u Deutsch.srt,English.srt
			# -u Deutsch.srt:deu,English.srt:eng
			# -u 0:deu,1:eng,Deutsch.srt:deu,English.srt:eng,2:spa,3:fra,4:ita
			#
			UNTERTITEL_SPUR_SPRACHE="${2}"	# -u 0,1,2,3,4 / -u 0:deu,1:eng,2:spa,3:fra,4:ita
			shift
			;;
		-kerne)
			SOLL_KERNE="${2}"		# mit "-kerne" (z.B.: -kerne 1) kann man jetzt angeben, wieviel Kerne benutzt werden sollen; z.B. wenn zuviel RAM belegt wird, dann kann man die Anzahl der zu nutzenden CPU-Kerne reduzieren, das reduziert, bei vielen Codecs, auch die RAM-Belegung
			shift
			;;
		-g)
			echo "${BILD_FORMATNAMEN_AUFLOESUNGEN}"
			exit 70
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
	-q Film.avi -z Film.mp4

	# ein Beispiel, bei dem die erste Untertitelspur (Zählweise beginnt mit '0'!) übernommen wird
	-q Film.avi -u 0 -z Film.mp4
	# ein Beispiel, bei dem die zweite Untertitelspur übernommen wird
	-q Film.avi -u 1 -z Film.mp4
	# ein Beispiel, bei dem die erste und die zweite Untertitelspur übernommen werden
	-q Film.avi -u 0,1 -z Film.mp4

	# Es duerfen in den Dateinamen keine Leerzeichen, Sonderzeichen
	# oder Klammern enthalten sein!
	# Leerzeichen kann aber innerhalb von Klammer trotzdem verwenden
	-q \"Filmname mit Leerzeichen.avi\" -z Film.mp4

	# Titel/Name des Filmes
	-titel \"Titel oder Name des Filmes\"
	-titel \"Battlestar Galactica\"

	# Kommentar zum Film / Beschreibung des Filmes
	-k 'Ein Kommentar zum Film.'

	# Wenn Audio- und Video-Spur nicht synchron sind,
	# dann muss das korrigiert werden.
	#
	# Wenn \"-vd\" und \"-ad\" zusammen im selben Kommando
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
	# Wenn \"-vd\" und \"-ad\" zusammen im selben Kommando
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

	# Audio nicht übertragen
	# das Ergebnis soll keine Audio-Spur enthalten
	-ton =0

	# so wird die 3. und 4. Untertitelspur angegeben (die Zaehlweise beginnt mit 0)
	-u 2,3

	# so wird Untertitel komplett abgeschaltet
	-u =0

	# so wird die 3. und 4. Untertitelspur angegeben (die Zaehlweise beginnt mit 0)
	-u 2,3

	# so wird den Untertitelspuren noch eine Sprache mit angegeben
	-u 0:deu,1:eng,2:spa,3:fra,4:ita

	# so werden noch externe Untertitel-Dateien mit angegeben
	-u 0,1,Deutsch.srt,English.srt,2,3,4

	# so wird den Untertitelspuren und -dateien noch eine Sprache mit angegeben
	-u 0:deu,1:eng,Deutsch.srt:deu,English.srt:eng,2:spa,3:fra,4:ita

	# so sieht das aus, wenn die Untertitel-Dateien in einem Unterverzeichnis (Sub) liegen
	-u 0:deu,1:eng,Sub/Deutsch.srt:deu,Sub/English.srt:eng,2:spa,3:fra,4:ita

	# Wird diese Option nicht verwendet,
	# dann wird die Einstellung aus dem Originalfilm übernommen
	# Bei \"0\" wird die erste Tonspur automatisch gestartet
	# Bei \"5\" wird die sechste Tonspur automatisch gestartet
	-standard_ton 5

	# Wird diese Option nicht verwendet,
	# dann wird die Einstellung aus dem Originalfilm übernommen
	# Bei \"0\" wird die erste Untertitelspur automatisch gestartet
	# Bei \"5\" wird die sechste Untertitelspur automatisch gestartet
	-standard_u 5

	# Stereo-Ausgabe erzwingen
	# egal wieviele Audio-Kanäle der Originalfilm hat, der neue Film wird Stereo haben
	-stereo

	# Dieser Wert gibt an wie weit von beginn der Filmdatei an
	# ffprobe nach Tonspuren und Untertiteln suchen soll.
	# Ist der Wert zu klein, dann werden beispielsweise keine
	# Untertitel gefunden, die erst sehr spät beginnen.
	# Der Wert sollte so groß sein wie der zu transkodierende Film ist.
	# Die Voreinstellung ist \"9223372036854\" MiB
	# Das ist der praktisch ermittelte Maximalwert von einem
	# \"Intel Core i5-10600T CPU @ 2.40GHz\"
	# auf einem \"FreeBSD 13.0\"-System mit 64 GiB RAM.
	# 
	# Hat der Film nur eine Tonspur, die ganz am Anfang des Films beginnt, und keine Untertitel,
	# dann kann der Wert sehr klein gehalten werden. Zum Beispiel: 50
	-ffprobe 9223372036854
	-ffprobe 100000000000
	-ffprobe 50

        # folgenden Parameter werden durch Profile begrenzt: Auflösung
        # zukünftig ggf. auch noch: Farbtiefe, Profil, Level
	#
        # HD ready
        # Damit der Film auch auf gewöhnlichen Set-Top-Boxen abgespielt werden kann
        # Mindestanvorderungen des "HD ready"-Standards umsetzen
        #  4/3: maximal 1024×768 → XGA  (EVGA)
        # 16/9: maximal 1280×720 → WXGA (HDTV)
	#
	# HTTP Live Streaming -> HLS
	# Dieses Skript berücksichtigt vom HLS-Standard nur das Bildformat (16/9) und die Bildauflösungen (416x234, 640x360, 768x432, 960x540, 1280x720, 1920x1080, 2560x1440, 3840x2160).
	#
        # Das Profil "firetv" begrenzt die Hardware-Anforderungen auf Werte, die der "FireTV Gen 2" von Amazon verarbeiten kann.
        -profil hls
        -profil fullhd
        -profil hdready
        -profil firetv

        # Es kann statt eines konkreten Profilnamens auch eine frei wählbare Auflösung angegeben werden, die bei der Ausgabe nicht überschritten werden soll.
        # zum Beispiel:
	-profil 320x240
	-profil 640x480
	-profil 800x600
	-profil 960x540
	-profil 768x576
	-profil 1024x576
	-profil 1280x720
	-profil 1920x1080

        # Das Format ist normalerweise durch die Dateiendung der Ziel-Datei vorgegeben.
	# Diese Vorgabe kann mit dieser Option überschrieben werden.
	# z.B.:
	#   Will man einen Film in das MKV-Format transkodieren, dann sind die
	#   vorgegebenen Codecs dafür VP9+Vorbis. Für das WebM-Format sind die
	#   vorgegebenen Codecs dafür AV1+Opus.
	#   Will man jetzt aber einen WebM-Film mit den Codes von einem MKV-Film
	#   erstellen, dann benötigt man diese Option:
	#   ... -z Film.webm -format mkv
        # Video-Format: 3g2, 3gp, avi, flv, m2ts, mkv, mp4, mpg, ogg, ts, webm
        -format mp4
        -format mkv
        -format webm

	# Das Format (Video-Codec + Audio-Codec) ist normalerweise durch die Dateiendung der Ziel-Datei vorgegeben.
	# Mit dieser Option kann der Video-Codec überschrieben werden.
        # Video-Codec: 261, 262, 263, 264, 2640, 265, 2650, av1, av10, divx, ffv1, flv, snow, theora, vc2, vp8, vp9, vp90, xvid
	-cv theora
	-cv 264
	-cv 2640    # verllustfrei
	-cv 265
	-cv 2650    # verllustfrei
	-cv vp9
	-cv vp90    # verllustfrei
	-cv av1
	-cv av10    # verllustfrei

	# Das Format (Video-Codec + Audio-Codec) ist normalerweise durch die Dateiendung der Ziel-Datei vorgegeben.
	# Mit dieser Option kann der Audio-Codec überschrieben werden.
	# Audio-Codec: aac, ac3, mp2, mp3, opus, vorbis
	-ca aac
	-ca ac3
	-ca opus
	-ca vorbis

	# 2-Pass aktivieren (funktioniert z.Z. nur bei VP9)
        -2pass

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

	# mit dieser Option wird das originale Seitenverhältnis beibehalten,
	# sonst wird automatisch auf 4:3 oder 16:9 umgerechnet
	-orig_dar

	# wenn die Pixelgeometrie des Originalfilmes nicht automatisch ermittelt
	# werden kann oder falsch ermittelt wurde,
	# dann muss es manuell als Parameter uebergeben werden;
	# es wird nur einer der beiden Parameter DAR oder PAR benoetigt
	-par 16:15		# PAL
	-par 9:10		# NTSC
	-par 8:9		# NTSC-DVD
	-par 64:45		# NTSC / DVD / DVB
	-par 1:1		# BluRay

	# wenn das Bildformat des Originalfilmes nicht automatisch ermittelt
	# werden kann oder falsch ermittelt wurde,
	# dann muss es manuell als Parameter uebergeben werden;
	# es wird nur einer der beiden Parameter DAR oder PAR benötigt
	-dar 4:3		# TV (Röhre)
	-dar 16:9		# TV (Flat)
	-dar 480:201		# BluRay

	# das Bildformat des zu erstellenden Videos wird hiermit angegeben
	-soll_dar 4:3		# TV (Röhre)
	-soll_dar 16:9		# TV (Flat)
	-soll_dar 480:201	# BluRay

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

	# mit "-kerne" (z.B.: -kerne 1) kann man jetzt angeben, wieviel Kerne benutzt werden sollen; z.B. wenn zuviel RAM belegt wird, dann kann man die Anzahl der zu nutzenden CPU-Kerne reduzieren, das reduziert, bei vielen Codecs, auch die RAM-Belegung
	# wird eine zu große Zahl eingegeben, dann werden trotzdem nur alle Kerne benutzt
	-kerne 1

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
                        exit 80
                        ;;
                *)
                        if [ "$(echo "${1}" | grep -E '^-')" ] ; then
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
if [ x = "x${PROGRAMM}" ] ; then
	PROGRAMM="$(which avconv)"
	if [ x = "x${PROGRAMM}" ] ; then
		echo "Weder avconv noch ffmpeg konnten gefunden werden. Abbruch!"
		exit 90
	fi
fi

#==============================================================================#
### Trivialitäts-Check

if [ "Ja" = "${STOP}" ] ; then
        echo "Bitte korrigieren sie die falschen Parameter. Abbruch!"
        exit 100
fi

#------------------------------------------------------------------------------#

if [ "auto" = "${BILDQUALIT}" ] ; then
        BILDQUALIT="5"
fi

if [ "auto" = "${TONQUALIT}" ] ; then
        TONQUALIT="5"
fi

#------------------------------------------------------------------------------#

if [ ! -r "${FILMDATEI}" ] ; then
        echo "Der Film '${FILMDATEI}' konnte nicht gefunden werden. Abbruch!"
        exit 110
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

### leider kommt (Stand 2021) ffmpeg mit Umlauten nicht richtig zurecht
### sie werden als Sonderzeichen identifiziert und somit gilt soein
### Dateiname als "unsicher"
#
# [concat @ 0x80664f000] Unsafe file name 'iWRoMVJd7uIg_01_Jesus_war_Vegetarier_und_die_Texte_über_die_Opfergaben_im_AT_sind_Fälschungen.mp4'
#
if [ x = "x$(echo "${ZIELDATEI}" | grep -Ei 'ä|ö|ü|ß')" ] ; then
	ZIELNAME="$(echo "${ZIELDATEI}" | awk '{sub("[.][^.]*$","");print $0}')"
	ZIEL_FILM="${ZIELNAME}"
	ENDUNG="$(echo "${ZIEL_BASIS_NAME}" | rev | sed 's/[a-zA-Z0-9\_\-\+/][a-zA-Z0-9\_\-\+/]*[.]/&"/;s/[.]".*//' | rev)"
else
	echo
	echo 'Der Dateiname'
	echo "'${ZIELDATEI}'"
	echo 'enthält Umlaute, damit kommt ffmpeg leider nicht immer klar!'
	exit 120
fi

#------------------------------------------------------------------------------#
### ggf das Format ändern

video_format

#------------------------------------------------------------------------------#

if [ x = "x${SOLL_FPS}" ] ; then
	unset FPS
else
	FPS="-r ${SOLL_FPS}"
fi

if [ x = "x${SOLL_FPS}" ] ; then
	SOLL_FPS_RUND="$(echo "${IN_FPS}" | awk '{printf "%.0f\n", $1}')"			# für Vergleiche, "if" erwartet einen Integerwert
else
	SOLL_FPS_RUND="$(echo "${SOLL_FPS}" | awk '{printf "%.0f\n", $1}')"			# für Vergleiche, "if" erwartet einen Integerwert
fi

if [ "${ZIEL_BASIS_NAME}" = "${VIDEO_FORMAT}" ] ; then
	echo 'Die Zieldatei muß eine Endung haben!'
	ls ${AVERZ}/Filmwandler_Format_*.txt | sed 's/.*Filmwandler_Format_//;s/[.]txt//'
	exit 130
fi

if [ "${QUELL_BASIS_NAME}" = "${ZIEL_BASIS_NAME}" ] ; then
	ZIELNAME="${ZIELNAME}_Nr2"
fi

#------------------------------------------------------------------------------#
### ab hier kann in die Log-Datei geschrieben werden

PROTOKOLLDATEI="$(echo "${ZIELNAME}.${ENDUNG}" | sed 's/[ ][ ]*/_/g;')"

echo "# 140
# $(date +'%F %T')
# ${0} ${Film2Standardformat_OPTIONEN}
#
# ZIEL_BASIS_NAME='${ZIEL_BASIS_NAME}'
# QUELL_DATEI='${QUELL_DATEI}'
# ZIELVERZ='${ZIELVERZ}'
# ZIELDATEI='${ZIELDATEI}'
#
# ZIELNAME='${ZIELNAME}'
# ZIEL_FILM='${ZIEL_FILM}'
#
# ENDUNG='${ENDUNG}'
# VIDEO_FORMAT='${VIDEO_FORMAT}'
" | tee "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 150

#------------------------------------------------------------------------------#
### Parameter zum reparieren defekter Container

#REPARATUR_PARAMETER="-fflags +genpts"
REPARATUR_PARAMETER="-fflags +genpts+igndts"

#==============================================================================#
### maximale Anzahl an CPU-Kernen im System ermitteln

BS=$(uname -s)
if [ "FreeBSD" = "${BS}" ] ; then
	CPU_KERNE="$(sysctl -n kern.smp.cores)"
	if [ "x" = "x${CPU_KERNE}" ] ; then
		CPU_KERNE="$(sysctl -n hw.ncpu)"
	fi
elif [ "Darwin" = "${BS}" ] ; then
	CPU_KERNE="$(sysctl -n hw.physicalcpu)"
	if [ "x" = "x${CPU_KERNE}" ] ; then
		CPU_KERNE="$(sysctl -n hw.logicalcpu)"
	fi
elif [ "Linux" = "${BS}" ] ; then
	CPU_KERNE="$(lscpu -p=CORE | grep -E '^[0-9]' | sort | uniq | wc -l)"
	if [ "x" = "x${CPU_KERNE}" ] ; then
		CPU_KERNE="$(awk '/^cpu cores/{print $NF}' /proc/cpuinfo | head -n1)"
		if [ "x" = "x${CPU_KERNE}" ] ; then
			CPU_KERNE="$(sed 's/.,//' /sys/devices/system/cpu/cpu0/topology/core_cpus_list)"
			if [ "x" = "x${CPU_KERNE}" ] ; then
				CPU_KERNE="$(grep -m 1 'cpu cores' /proc/cpuinfo | sed 's/.* //')"
				if [ "x" = "x${CPU_KERNE}" ] ; then
					CPU_KERNE="$(grep -m 1 'cpu cores' /proc/cpuinfo | awk '{print $NF}')"
					if [ "x" = "x${CPU_KERNE}" ] ; then
						CPU_KERNE="$(nproc --all)"
					fi
				fi
			fi
		fi
	fi
fi

echo "# 158
# CPU_KERNE='${CPU_KERNE}'
# SOLL_KERNE='${SOLL_KERNE}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

if [ "x" = "x${CPU_KERNE}" ] ; then
	echo "Es konnte nicht ermittelt werden, wieviele CPU-Kerne in diesem System stecken."
	echo "Es wird nun nur ein Kern benuzt."
	CPU_KERNE="1"
fi

echo "# 159
# CPU_KERNE='${CPU_KERNE}'
# SOLL_KERNE='${SOLL_KERNE}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

if [ "x" != "x${SOLL_KERNE}" ] ; then
	if [ 1 -gt "${SOLL_KERNE}" ] ; then
		echo "In diesem System wurden nur '${CPU_KERNE}' CPU-Kerne gefunden."
		CPU_KERNE="${CPU_KERNE}"
	elif [ "${SOLL_KERNE}" -gt "${CPU_KERNE}" ] ; then
		echo "In diesem System wurden nur '${CPU_KERNE}' CPU-Kerne gefunden."
		CPU_KERNE="${CPU_KERNE}"
	else
		CPU_KERNE="${SOLL_KERNE}"
	fi
fi

echo "# 160
# BS='${BS}'
# CPU_KERNE='${CPU_KERNE}'
# SOLL_KERNE='${SOLL_KERNE}'
# SOLL_PROBESIZE='${SOLL_PROBESIZE}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
#exit 161

#==============================================================================#
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

if [ x != "x${SOLL_PROBESIZE}" ] ; then
	FFPROBE_PROBESIZE="$(echo "${SOLL_PROBESIZE}" | awk '{print tolower($0)}' | sed 's/[a-zA-Z]*$/ &/' | while read FFPROBE_GR FFPROBE_EINHEIT
	do
		if [ k = "${FFPROBE_EINHEIT}" -o ki = "${FFPROBE_EINHEIT}" ] ; then
			echo "${FFPROBE_GR}" | awk '{printf "%.0f\n", $1 / 1000}'
		elif [ g = "${FFPROBE_EINHEIT}" -o gi = "${FFPROBE_EINHEIT}" ] ; then
			echo "${FFPROBE_GR}" | awk '{printf "%.0f\n", $1 * 1000}'
		elif [ t = "${FFPROBE_EINHEIT}" -o ti = "${FFPROBE_EINHEIT}" ] ; then
			echo "${FFPROBE_GR}" | awk '{printf "%.0f\n", $1 * 1000000}'
		else
			echo "${FFPROBE_GR}" | awk '{printf "%.0f\n", $1}'
		fi
	done)"
fi

if [ x = "x${FFPROBE_PROBESIZE}" ] ; then
	#FFPROBE_PROBESIZE="9223372036"		# Maximalwert in GiB auf einem Intel(R) Core(TM) i5-10600T CPU @ 2.40GHz
	FFPROBE_PROBESIZE="9223372036854"	# Maximalwert in MiB auf einem Intel(R) Core(TM) i5-10600T CPU @ 2.40GHz
fi

echo "# 167 META_DATEN_STREAMS:
# FFPROBE_PROBESIZE='${FFPROBE_PROBESIZE}'M
"
#exit 168

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

echo "# 169 META_DATEN_STREAMS:
# FFPROBE_PROBESIZE='${FFPROBE_PROBESIZE}'M
"

meta_daten_streams
echo "# 170 META_DATEN_STREAMS:
# FFPROBE_PROBESIZE='${FFPROBE_PROBESIZE}'M
${META_DATEN_STREAMS}
"

if [ x = "x${META_DATEN_STREAMS}" ] ; then
	### Killed
	echo "# 180:
	Leider hat der erste ffprobe-Lauf nicht funktioniert,
	das deutet auf zu wenig verfügbaren RAM hin.
	Der ffprobe-Lauf wird erneut gestartet.

	starte die Funktion: meta_daten_streams" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

	FFPROBE_PROBESIZE="$(du -sm "${FILMDATEI}" | awk '{print $1}')"
	meta_daten_streams
fi

echo "# 190
# FFPROBE_PROBESIZE='${FFPROBE_PROBESIZE}'M (letzter Versuch)
" | head -n 40 | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
#exit 209

if [ x = "x${META_DATEN_STREAMS}" ] ; then
	echo "# 200: Die probesize von '${FFPROBE_PROBESIZE}M' ist weiterhin zu groß, bitte Rechner rebooten."
	exit 210
fi

echo "# 220: META_DATEN_ZEILENWEISE_STREAMS"
### es werden durch Semikolin getrennte Schlüssel ausgegeben bzw. in der Variablen gespeichert
META_DATEN_ZEILENWEISE_STREAMS="$(echo "${META_DATEN_STREAMS}" | tr -s '\r' '\n' | tr -s '\n' ';' | sed 's/;\[STREAM\]/³[STREAM]/g' | tr -s '³' '\n')"
#echo "${META_DATEN_ZEILENWEISE_STREAMS}" > /tmp/META_DATEN_ZEILENWEISE_STREAMS.txt
#exit 221

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
#   0 video eng 
#   1 audio ger 
#   2 audio eng 
#   3 subtitle eng 
META_DATEN_SPURSPRACHEN_01="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -E 'TAG:language=' | while read Z ; do echo "${Z}" | tr -s ';' '\n' | awk -F'=' '/^index=|^codec_type=|^TAG:language=/{print $2}' | tr -s '\n' ' ' ; echo ; done)"
META_DATEN_SPURSPRACHEN="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F 'codec_type=' | nl | while read ZNR M_DATEN
do
	SP_DATEN="$(echo "${M_DATEN}" | grep -E 'TAG:language=' | tr -s ';' '\n' | awk -F'=' '/^index=|^codec_type=|^TAG:language=/{print $2}' | tr -s '\n' ' ')"
	if [ x = "x${SP_DATEN}" ] ; then
		SP_DATEN="$( (echo "${M_DATEN}" | tr -s ';' '\n' | awk -F'=' '/^index=|^codec_type=/{print $2}'; echo "und") | tr -s '\n' ' ')"
	fi
	echo "${SP_DATEN}"
done)"

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
if [ x = "x${BILD_DREHUNG}" ] ; then
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
# ffprobe -v error -i 20150216_142433.mp4 -show_streams | sed -ne '/index=0/,/index=1/p' | grep -F -i rotat
# TAG:rotate=180
# rotation=-180

echo "# 230
# META_DATEN_SPURSPRACHEN='${META_DATEN_SPURSPRACHEN}'
# BILD_DREHUNG='${BILD_DREHUNG}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 240

#------------------------------------------------------------------------------#

#FFPROBE_SHOW_DATA="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_data 2>&1)"
ORIGINAL_TITEL="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_entries format_tags=title -of compact=p=0:nk=1)"

METADATEN_TITEL="-metadata title="
if [ x = "x${EIGENER_TITEL}" ] ; then
	echo "# 250: EIGENER_TITEL"
	#EIGENER_TITEL="$(echo "${FFPROBE_SHOW_DATA}" | grep -E 'title[ ]*: ' | sed 's/[ ]*title[ ]*: //' | head -n1)"
	EIGENER_TITEL="${ORIGINAL_TITEL}"

	if [ x = "x${EIGENER_TITEL}" ] ; then
		echo "# 260:"
		EIGENER_TITEL="${ZIELNAME}"
	fi
fi

METADATEN_BESCHREIBUNG="-metadata description="
if [ x = "x${KOMMENTAR}" ] ; then
	echo "# 270: KOMMENTAR"
	COMMENT_DESCRIPTION="$(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_entries format_tags=comment -of compact=p=0:nk=1) $(ffprobe -v error ${KOMPLETT_DURCHSUCHEN} -i "${FILMDATEI}" -show_entries format_tags=description -of compact=p=0:nk=1)"
	KOMMENTAR="$(echo "${COMMENT_DESCRIPTION}" | sed 's/^[ \t]*//')"

	if [ x = "x${KOMMENTAR}" ] ; then
		echo "# 280: github.com"
		METADATEN_BESCHREIBUNG="-metadata description='https://github.com/FlatheadV8/Filmwandler:${VERSION_METADATEN}'"
	fi
fi

echo "# 290
ORIGINAL_TITEL='${ORIGINAL_TITEL}'
METADATEN_TITEL='${METADATEN_TITEL}'
EIGENER_TITEL='${EIGENER_TITEL}'

METADATEN_BESCHREIBUNG=${METADATEN_BESCHREIBUNG}
KOMMENTAR='${KOMMENTAR}'

AUDIO_STANDARD_SPUR='${AUDIO_STANDARD_SPUR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 291

STARTZEITPUNKT="$(date +'%s')"

#--- VIDEO_SPUR ---------------------------------------------------------------#
#------------------------------------------------------------------------------#

if [ 0 != "${VIDEO_NICHT_UEBERTRAGEN}" ] ; then

  VIDEO_SPUR="$(echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=video' | head -n1)"
  if [ "${VIDEO_SPUR}" != "codec_type=video" ] ; then
	VIDEO_NICHT_UEBERTRAGEN=0
  fi

  echo "# 300
  # VIDEO_SPUR='${VIDEO_SPUR}'
  # VIDEO_NICHT_UEBERTRAGEN='${VIDEO_NICHT_UEBERTRAGEN}'
  " | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

  #exit 310

  #------------------------------------------------------------------------------#
  ### hier wird eine Liste externer verfügbarer Codecs erstellt

  FFMPEG_LIB="$( (ffmpeg -formats >/dev/null) 2>&1 | tr -s ' ' '\n' | grep -E '^[-][-]enable[-]' | sed 's/^[-]*enable[-]*//;s/[-]/_/g' | grep -E '^lib')"
  FFMPEG_FORMATS="$(ffmpeg -formats 2>/dev/null | awk '/^[ \t]*[ ][DE]+[ ]/{print $2}')"

  #------------------------------------------------------------------------------#
  ### alternative Methode zur Ermittlung der FPS

  FPS_TEILE="$(echo "${META_DATEN_STREAMS}" | grep -E '^codec_type=|^r_frame_rate=' | grep -E -A1 '^codec_type=video' | awk -F'=' '/^r_frame_rate=/{print $2}' | sed 's|/| |')"
  TEIL_ZWEI="$(echo "${FPS_TEILE}" | awk '{print $2}')"
  if [ x = "x${TEIL_ZWEI}" ] ; then
	R_FPS="$(echo "${FPS_TEILE}" | awk '{print $1}')"
  else
	R_FPS="$(echo "${FPS_TEILE}" | awk '{print $1/$2}')"
  fi

#------------------------------------------------------------------------------#
### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt

# tbn (FPS vom Container)            = the time base in AVStream that has come from the container
# tbc (FPS vom Codec)                = the time base in AVCodecContext for the codec used for a particular stream
# tbr (FPS vom Video-Stream geraten) = tbr is guessed from the video stream and is the value users want to see when they look for the video frame rate

### "field_order" gibt bei "interlaced" an in welcher Richtung (von oben nach unten oder von links nach rechts)
### "field_order" gibt nicht an, ob ein Film "progressive" ist
SCAN_TYPE="$(echo "${META_DATEN_STREAMS}" | awk -F'=' '/^field_order=/{print $2}' | grep -Ev '^$' | head -n1)"

echo "# 320
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
        #ZEILENSPRUNG="yadif=1/3,mcdeint=mode=extra_slow,"
        #ZEILENSPRUNG="yadif=1:-1:0,"
        ZEILENSPRUNG="bwdif=mode=send_frame,"
    fi
fi

# META_DATEN_STREAMS=" width=720 "
# META_DATEN_STREAMS=" height=576 "
IN_BREIT="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^width=/{print $2}' | grep -Fv 'N/A' | head -n1)"
IN_HOCH="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^height=/{print $2}' | grep -Fv 'N/A' | head -n1)"
IN_XY="${IN_BREIT}x${IN_HOCH}"
O_BREIT="${IN_BREIT}"
O_HOCH="${IN_HOCH}"

echo "# 330
# 1 IN_XY='${IN_XY}'
# 1 IN_BREIT='${IN_BREIT}'
# 1 IN_HOCH='${IN_HOCH}'
# 1 O_BREIT='${O_BREIT}'
# 1 O_HOCH='${O_HOCH}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 340

if [ x = "x${IN_XY}" ] ; then
	# META_DATEN_STREAMS=" coded_width=0 "
	# META_DATEN_STREAMS=" coded_height=0 "
	IN_BREIT="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^coded_width=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
	IN_HOCH="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^coded_height=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
	IN_XY="${IN_BREIT}x${IN_HOCH}"
	echo "# 350
	2 IN_XY='${IN_XY}'
	2 IN_BREIT='${IN_BREIT}'
	2 IN_HOCH='${IN_HOCH}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

	# http://www.borniert.com/2016/03/rasch-mal-ein-video-drehen/
	# ffmpeg -i in.mp4 -c copy -metadata:s:v:0 rotate=90 out.mp4
	if [ "x${BILD_DREHUNG}" != x ] ; then
		if [ "90" = "${BILD_DREHUNG}" ] ; then
			IN_XY="$(echo "${IN_XY}" | awk -F'x' '{print $2"x"$1}')"
		elif [ "270" = "${BILD_DREHUNG}" ] ; then
			IN_XY="$(echo "${IN_XY}" | awk -F'x' '{print $2"x"$1}')"
		fi
	fi
	IN_BREIT="$(echo "${IN_XY}" | awk -F'x' '{print $1}')"
	IN_HOCH="$(echo  "${IN_XY}" | awk -F'x' '{print $2}')"
fi

#------------------------------------------------------------------------------#

IN_PAR="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^sample_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "# 360
1 IN_PAR='${IN_PAR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
if [ x = "x${IN_PAR}" ] ; then
	IN_PAR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^sample_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
	echo "# 370
	2 IN_PAR='${IN_PAR}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
fi

if [ x = "x${IN_PAR}" ] ; then
	IN_PAR="1:1"
	echo "# 380
	3 IN_PAR='${IN_PAR}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
fi

#------------------------------------------------------------------------------#

IN_DAR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^display_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "# 390
1 IN_DAR='${IN_DAR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
if [ x = "x${IN_DAR}" ] ; then
	IN_DAR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^display_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
	echo "# 400
	2 IN_DAR='${IN_DAR}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
fi

if [ x = "x${IN_DAR}" ] ; then
	IN_DAR="$(echo "${IN_XY} ${IN_PAR}" | awk '{gsub("[:/x]"," "); print ($1*$3)/($2*$4)}' | head -n1)"
	echo "# 410
	3 IN_DAR='${IN_DAR}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
fi

#------------------------------------------------------------------------------#

# META_DATEN_STREAMS=" r_frame_rate=25/1 "
# META_DATEN_STREAMS=" avg_frame_rate=25/1 "
# META_DATEN_STREAMS=" codec_time_base=1/25 "
FPS_TEILE="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^r_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1,$2}')"
TEIL_ZWEI="$(echo "${FPS_TEILE}" | awk '{print $2}')"
if [ x = "x${TEIL_ZWEI}" ] ; then
	IN_FPS="$(echo "${FPS_TEILE}" | awk '{print $1}')"
else
	IN_FPS="$(echo "${FPS_TEILE}" | awk '{print $1/$2}')"
fi
echo "# 420
1 IN_FPS='${IN_FPS}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

if [ x = "x${IN_FPS}" ] ; then
	IN_FPS="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^avg_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1}')"
	echo "# 430
	2 IN_FPS='${IN_FPS}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	if [ x = "x${IN_FPS}" ] ; then
		IN_FPS="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^codec_time_base=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $2}')"
		echo "# 440
		3 IN_FPS='${IN_FPS}'
		" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	fi
fi

### Dieser Wert wird für AVI und MPG benötigt
IN_FPS_RUND="$(echo "${IN_FPS}" | awk '{printf "%.0f\n", $1}')"			# für Vergleiche, "if" erwartet einen Integerwert

IN_BIT_RATE="$(echo "${META_DATEN_STREAMS}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^bit_rate=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "# 450
1 IN_BIT_RATE='${IN_BIT_RATE}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
if [ x = "x${IN_BIT_RATE}" ] ; then
	IN_BIT_RATE="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=video;' | tr -s ';' '\n' | awk -F'=' '/^bit_rate=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
	echo "# 460
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

echo "# 470
# IN_XY='${IN_XY}'
# BILD_DREHUNG='${BILD_DREHUNG}'
# IN_BREIT='${IN_BREIT}'
# IN_HOCH='${IN_HOCH}'
# IN_PAR='${IN_PAR}'
# IN_DAR='${IN_DAR}'
# IN_FPS='${IN_FPS}'
# IN_FPS_RUND='${IN_FPS_RUND}'
# IN_BIT_RATE='${IN_BIT_RATE}'
# IN_BIT_EINH='${IN_BIT_EINH}'
# IN_BITRATE_KB='${IN_BITRATE_KB}'
# BILDQUALIT='${BILDQUALIT}'
# TONQUALIT='${TONQUALIT}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

unset IN_BIT_RATE
unset IN_BIT_EINH

#exit 480

if [ x = "x${IN_DAR}" ] ; then
	echo "# 490
	Fehler!
	IN_DAR='${IN_DAR}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	exit 500
fi

INDAR="$(echo "${IN_DAR}" | grep -E '[0-9][:][0-9]' | head -n1)"
echo "# 510
IN_DAR='${IN_DAR}'
INDAR='${INDAR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

if [ x = "x${INDAR}" ] ; then
	IN_DAR="${IN_DAR}:1"
	echo "# 520
	IN_DAR='${IN_DAR}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
fi

echo "# 530
# ORIGINAL_DAR='${ORIGINAL_DAR}'
# IN_DAR='${IN_DAR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 540

#==============================================================================#
#==============================================================================#
### Video

### diese Informationen müssen bereits jetzt abrufbar sein
### und können nicht erst unten bei der Untertitelverarbeitung ausgelesen werden
UT_VORHANDEN="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F codec_type=subtitle)"
IST_UT_FORMAT="$(echo "${UT_VORHANDEN}" | tr -s ';' '\n' | awk -F'=' '/^codec_name=/{print $2}')"

echo "# 544
# UT_VORHANDEN='${UT_VORHANDEN}'
# IST_UT_FORMAT='${IST_UT_FORMAT}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#------------------------------------------------------------------------------#
### Seitenverhältnis des Bildes (DAR) muss hier bekannt sein!

. ${AVERZ}/Filmwandler_video.txt

#------------------------------------------------------------------------------#
### BILD_BREIT und BILD_HOCH prüfen

echo "# 560
# ORIGINAL_DAR='${ORIGINAL_DAR}'
# BREIT_DAR='${BREIT_DAR}'
# HOCH_DAR='${HOCH_DAR}'
# SOLL_DAR='${SOLL_DAR}'
# BILD_BREIT='${BILD_BREIT}'
# BILD_HOCH='${BILD_HOCH}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
#exit 561

#set -x
if [ x = "x${BILD_BREIT}" -o x = "x${BILD_HOCH}" ] ; then
	echo "# 570: ${BILD_BREIT}x${BILD_HOCH}"
	exit 575
fi

fi

#exit 580

#------------------------------------------------------------------------------#

echo "# 590
# ENDUNG=${ENDUNG}
# VIDEO_FORMAT=${VIDEO_FORMAT}
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

VIDEO_ENDUNG="$(echo "${ENDUNG}" | awk '{print tolower($1)}')"

#------------------------------------------------------------------------------#
### Variable FORMAT füllen

echo "# 600 CONSTANT_QUALITY
# CONSTANT_QUALITY='${CONSTANT_QUALITY}'
# VIDEOCODEC='${VIDEOCODEC}'
# AUDIOCODEC='${AUDIOCODEC}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 601

# laut Endung
if [ -r ${AVERZ}/Filmwandler_Format_${VIDEO_ENDUNG}.txt ] ; then
    
        OP_QUELLE="1"
        unset FFMPEG_TARGET
        
	echo "IN_FPS='${IN_FPS}'"
	#exit 610

	. ${AVERZ}/Filmwandler_Format_${VIDEO_ENDUNG}.txt
	CONTAINER_FORMAT="${FORMAT}"

else
	echo "Datei konnte nicht gefunden werden:"
	echo "${AVERZ}/Filmwandler_Format_${VIDEO_ENDUNG}.txt"
	exit 620
fi

echo "# 630 CONSTANT_QUALITY
# CONSTANT_QUALITY='${CONSTANT_QUALITY}'
# VIDEOCODEC='${VIDEOCODEC}'
# AUDIOCODEC='${AUDIOCODEC}'
# VIDEO_FORMAT='${VIDEO_FORMAT}'
#
# ALT_CODEC_VIDEO='${ALT_CODEC_VIDEO}'
# TWOPASS='${TWOPASS}'
# TWO_PASS='${TWO_PASS}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 631

# laut Wunsch-Kodecs
if [ -r ${AVERZ}/Filmwandler_Format_${VIDEO_FORMAT}.txt ] ; then
        OP_QUELLE="1"
        unset FFMPEG_TARGET
        
	echo "IN_FPS='${IN_FPS}'"
	#exit 640

	. ${AVERZ}/Filmwandler_Format_${VIDEO_FORMAT}.txt
else
	echo "Datei konnte nicht gefunden werden:"
	echo "${AVERZ}/Filmwandler_Format_${VIDEO_FORMAT}.txt"
	exit 650
fi

#------------------------------------------------------------------------------#
### Container-Format nach Wunsch setzen

if [ "${VIDEO_FORMAT}" != "${VIDEO_ENDUNG}" ] ; then
	FORMAT="${CONTAINER_FORMAT}"
fi

START_ZIEL_FORMAT="-f ${FORMAT}"

#------------------------------------------------------------------------------#

echo "# 660
# $(date +'%F %T')
#
# CONSTANT_QUALITY='${CONSTANT_QUALITY}'
# ENDUNG='${ENDUNG}'
# VIDEO_ENDUNG='${VIDEO_ENDUNG}'
# VIDEO_FORMAT='${VIDEO_FORMAT}'
# VIDEOCODEC='${VIDEOCODEC}'
# AUDIOCODEC='${AUDIOCODEC}'
# FORMAT='${FORMAT}'
# VIDEO_OPTION='${VIDEO_OPTION}'
# VIDEO_OPTION_BD='${VIDEO_OPTION_BD}'
# VIDEO_OPTION_00='${VIDEO_OPTION_00}'
# VIDEOOPTION='${VIDEOOPTION}'
#
# ALT_CODEC_VIDEO='${ALT_CODEC_VIDEO}'
# TWOPASS='${TWOPASS}'
# TWO_PASS='${TWO_PASS}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 670

#------------------------------------------------------------------------------#
### Video-Codec

if [ 0 != "${VIDEO_NICHT_UEBERTRAGEN}" ] ; then

if [ x != "x${ALT_CODEC_VIDEO}" ] ; then
	if [ -r ${AVERZ}/Filmwandler_Codec_Video_${ALT_CODEC_VIDEO}.txt ] ; then
		echo "# 672
		# VIDEO_OPTION='${VIDEO_OPTION}'
		# VIDEO_OPTION_BD='${VIDEO_OPTION_BD}'
		# VIDEO_OPTION_00='${VIDEO_OPTION_00}'
		# VIDEOOPTION='${VIDEOOPTION}'
		" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
		. ${AVERZ}/Filmwandler_Codec_Video_${ALT_CODEC_VIDEO}.txt
		echo "# 674
		# VIDEO_OPTION='${VIDEO_OPTION}'
		# VIDEO_OPTION_BD='${VIDEO_OPTION_BD}'
		# VIDEO_OPTION_00='${VIDEO_OPTION_00}'
		# VIDEOOPTION='${VIDEOOPTION}'
		" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	else
		# -cv 261
		# -cv 262
		# -cv 263
		# -cv 264
		# -cv 2640
		# -cv 265
		# -cv 2650
		# -cv av1
		# -cv av10
		# -cv divx
		# -cv ffv1
		# -cv flv
		# -cv snow
		# -cv theora
		# -cv vc2
		# -cv vp8
		# -cv vp9
		# -cv vp90
		# -cv xvid
		echo "Es sind zur Zeit die Möglichkeiten verfügbar:"
		ls ${AVERZ}/Filmwandler_Codec_Video_*.txt | awk -F'[_.]' '{print "-cv",$(NF-1)}'
		exit 680
	fi
fi

echo "# 690 CONSTANT_QUALITY
# ALT_CODEC_VIDEO='${ALT_CODEC_VIDEO}'
# VIDEOCODEC='${VIDEOCODEC}'
# AUDIOCODEC='${AUDIOCODEC}'
# CONSTANT_QUALITY='${CONSTANT_QUALITY}'
# VIDEOOPTION='${VIDEOOPTION}'
# VIDEO_OPTION_BD='${VIDEO_OPTION_BD}'
# VIDEO_OPTION_00='${VIDEO_OPTION_00}'
# VIDEOOPTION='${VIDEOOPTION}'
#
# TWO_PASS='${TWO_PASS}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

fi

#exit 692

#==============================================================================#
#==============================================================================#
# Audio

#------------------------------------------------------------------------------#

echo "# 700
TON_SPUR_SPRACHE='${TON_SPUR_SPRACHE}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#------------------------------------------------------------------------------#

if [ x = "x${TON_SPUR_SPRACHE}" ] ; then
	TSNAME="$(echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=audio' | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
else
	# 0:deu,1:eng,2:spa,3,4
	TSNAME="${TON_SPUR_SPRACHE}"
fi

# 0 1 2 3 4
TS_LISTE="$(echo "${TSNAME}" | sed 's/:[a-z]*/ /g;s/,/ /g')"
# 5
TS_ANZAHL="$(echo "${TSNAME}" | sed 's/,/ /g' | wc -w | awk '{print $1}')"

echo "# 710
TS_LISTE='${TS_LISTE}'
TS_ANZAHL='${TS_ANZAHL}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#------------------------------------------------------------------------------#
### FLV unterstützt nur eine einzige Tonspur
#   flv    + FLV        + MP3     (Sorenson Spark: H.263)

if [ "flv" = "${ENDUNG}" ] ; then
	if [ "1" -lt "${TS_ANZAHL}" ] ; then
		echo '# 720
		FLV unterstützt nur eine einzige Tonspur!
		' | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
		exit 730
	fi
fi

#==============================================================================#
### Sprachen der Spuren

echo "# 740
TON_SPUR_SPRACHE='${TON_SPUR_SPRACHE}'
AUDIO_SPUR_SPRACHE='${AUDIO_SPUR_SPRACHE}'
UNTERTITEL_SPUR_SPRACHE='${UNTERTITEL_SPUR_SPRACHE}'
IST_UT_FORMAT='${IST_UT_FORMAT}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

# -metadata:s:a:${A} language=${C}
if [ x = "x${TON_SPUR_SPRACHE}" ] ; then
	echo "# 750" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	AUDIO_SPUR_SPRACHE="$(echo "${META_DATEN_SPURSPRACHEN}" | grep -F ' audio ' | nl | awk '{print $1 - 1,$4}' | grep -E '^[0-9]')"

	### Deutsche Spuren werden nach vorne sortiert
	AUDIO_SPUR_NUR_DEUTSCH="$(echo "${AUDIO_SPUR_SPRACHE}" | grep -Ei " deu| ger")"
	AUDIO_SPUR_OHNE_DEUTSCH="$(echo "${AUDIO_SPUR_SPRACHE}" | grep -Eiv " deu| ger")"
	AUDIO_SPUR_SPRACHE="$( (echo "${AUDIO_SPUR_NUR_DEUTSCH}"; echo "${AUDIO_SPUR_OHNE_DEUTSCH}") | grep -Ev '^[ \t]*$')"
else
	echo "# 760" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	AUDIO_SPUR_SPRACHE="$(echo "${TON_SPUR_SPRACHE}" | grep -Ev '^$'  | tr -s ',' '\n' | sed 's/:/ /g;s/.*/& und/' | awk '{print $1,$2}' | grep -E '^[0-9]')"
fi

# -metadata:s:s:${A} language=${C}
if [ x = "x${UNTERTITEL_SPUR_SPRACHE}" ] ; then
	echo "# 770" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	NOTA_SPUR_SPRACHE="$(echo "${META_DATEN_SPURSPRACHEN}" | grep -F ' subtitle ' | nl | awk '{print $1 - 1,$4}' | grep -E '^[0-9]')"

	### Deutsche Spuren werden nach vorne sortiert
	NOTA_SPUR_NUR_DEUTSCH="$(echo "${NOTA_SPUR_SPRACHE}" | grep -Ei " deu| ger")"
	NOTA_SPUR_OHNE_DEUTSCH="$(echo "${NOTA_SPUR_SPRACHE}" | grep -Eiv " deu| ger")"
	NOTA_SPUR_SPRACHE="$( (echo "${NOTA_SPUR_NUR_DEUTSCH}"; echo "${NOTA_SPUR_OHNE_DEUTSCH}") | grep -Ev '^[ \t]*$')"
else
	echo "# 780" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	NOTA_SPUR_SPRACHE="$(echo "${UNTERTITEL_SPUR_SPRACHE}" | grep -Ev '^$'  | tr -s ',' '\n' | sed 's/:/ /g;s/.*/& und/' | awk '{print $1,$2}' | grep -E '^[0-9]')"
fi

echo "# 790
TON_SPUR_SPRACHE='${TON_SPUR_SPRACHE}'
AUDIO_SPUR_SPRACHE='${AUDIO_SPUR_SPRACHE}'
AUDIO_STANDARD_SPUR='${AUDIO_STANDARD_SPUR}'
UNTERTITEL_SPUR_SPRACHE='${UNTERTITEL_SPUR_SPRACHE}'
NOTA_SPUR_SPRACHE='${NOTA_SPUR_SPRACHE}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 800
#==============================================================================#
#------------------------------------------------------------------------------#
### STANDARD-AUDIO-SPUR

### Die Bezeichnungen (Sprache) für die Audiospuren werden automatisch übernommen.
if [ x = "x${AUDIO_STANDARD_SPUR}" ] ; then
	### wenn nichts angegeben wurde, dann
	### Deutsch als Standard-Sprache voreinstellen
	AUDIO_STANDARD_SPUR="$(echo "${AUDIO_SPUR_SPRACHE}" | nl | grep -Ei " deu| ger" | awk '{print $1 - 1}' | head -n1)"

	if [ x = "x${AUDIO_STANDARD_SPUR}" ] ; then
		### wenn nichts angegeben wurde
		### und es keine als deutsch gekennzeichnete Spur gibt, dann
		### STANDARD-AUDIO-SPUR vom Originalfilm übernehmen
		### DISPOSITION:default=1
		AUDIO_STANDARD_SPUR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | tr -s ';' '\n' | grep -F 'DISPOSITION:default=1' | grep -E 'default=[0-9]' | awk -F'=' '{print $2-1}')"
		if [ x = "x${AUDIO_STANDARD_SPUR}" ] ; then
			### wenn es keine STANDARD-AUDIO-SPUR im Originalfilm gibt, dann
			### alternativ einfach die erste Tonspur zur STANDARD-AUDIO-SPUR machen
			AUDIO_STANDARD_SPUR=0
		fi
	fi
fi

echo "# 810
# TS_LISTE='${TS_LISTE}'
# TON_SPUR_SPRACHE='${TON_SPUR_SPRACHE}'
# AUDIO_SPUR_SPRACHE='${AUDIO_SPUR_SPRACHE}'
# AUDIO_STANDARD_SPUR='${AUDIO_STANDARD_SPUR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 820

#------------------------------------------------------------------------------#
### Audio-Codec

if [ x != "x${ALT_CODEC_AUDIO}" ] ; then
	if [ -r ${AVERZ}/Filmwandler_Codec_Audio_${ALT_CODEC_AUDIO}.txt ] ; then
		. ${AVERZ}/Filmwandler_Codec_Audio_${ALT_CODEC_AUDIO}.txt
	else
		# -ca aac
		# -ca ac3
		# -ca mp2
		# -ca mp3
		# -ca opus
		# -ca vorbis
		echo "Es sind zur Zeit die Möglichkeiten verfügbar:"
		ls ${AVERZ}/Filmwandler_Codec_Audio_*.txt | awk -F'[_.]' '{print "-ca",$(NF-1)}'
		exit 830
	fi
fi

#------------------------------------------------------------------------------#

echo "# 840
# IN_FPS='${IN_FPS}'
# OP_QUELLE='${OP_QUELLE}'
# STEREO='${STEREO}'
#
# ENDUNG='${ENDUNG}'
# VIDEO_FORMAT='${VIDEO_FORMAT}'
# VIDEOCODEC='${VIDEOCODEC}'
# AUDIOCODEC='${AUDIOCODEC}'
# CONSTANT_QUALITY='${CONSTANT_QUALITY}'
#
# ALT_CODEC_VIDEO='${ALT_CODEC_VIDEO}'
# ALT_CODEC_AUDIO='${ALT_CODEC_AUDIO}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 850

#==============================================================================#
### Qualität
#
# Qualitäts-Parameter-Übersetzung
# https://slhck.info/video/2017/02/24/vbr-settings.html
#

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
### Audio-Qualität

#------------------------------------------------------------------------------#

if [ "=0" = "${TON_SPUR_SPRACHE}" ] ; then
	AUDIO_VERARBEITUNG_01="-an"
	AUDIO_VERARBEITUNG_02="-an"
else
	AUDIO_VON_OBEN="$(echo "${TONQUALIT}" | awk '{print $1 + 1}')"

	#exit 860

	echo "# 870
	# TONQUALIT='${TONQUALIT}'
	# AUDIO_OPTION_GLOBAL='${AUDIO_OPTION_GLOBAL}'
	# AUDIO_SPUR_SPRACHE='${AUDIO_SPUR_SPRACHE}'
	# AUDIOCODEC='${AUDIOCODEC}'
	# AUDIO_QUALITAET_5='${AUDIO_QUALITAET_5}'
	# TS_ANZAHL='${TS_ANZAHL}'
	# TS_LISTE='${TS_LISTE}'
	# STEREO='${STEREO}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

	#exit 880

	if [ 0 -lt "${TS_ANZAHL}" ] ; then
		echo "# 881: Es sind im Film Tonspuren vorhanden, die jetzt ausgewertet werden..." | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
		#----------------------------------------------------------------------#
		# AUDIO_SPUR_SPRACHE='0 de'
		AUDIO_VERARBEITUNG_01="${AUDIO_OPTION_GLOBAL} $(echo "${AUDIO_SPUR_SPRACHE}" | grep -Ev '^$' | nl | while read AKN TS_NR TS_SP
		do
			LFD_NR="$(echo "${AKN}" | awk '{print $1 - 1}')"
			AUDIO_KANAELE="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E '^channels=' | awk -F'=' '{print $2}')"
			echo "# 890 AUDIO_KANAELE='${AUDIO_KANAELE}'" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

			if [ x = "x${AUDIO_KANAELE}" ] ; then
				AKL10="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E 'channel_layout=mono')"
				AKL20="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E 'channel_layout=stereo')"
				AKL30="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E 'channel_layout=3.0')"
				AKL40="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E 'channel_layout=4.0')"
				AKL50="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E 'channel_layout=5.0')"
				AKL51="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E 'channel_layout=5.1')"
				AKL61="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E 'channel_layout=6.1')"
				AKL71="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=audio;' | head -n${AKN} | tail -n1 | tr -s ';' '\n' | grep -E 'channel_layout=7.1')"

				echo "
				# 900
				# AKL10='${AKL10}'
				# AKL20='${AKL20}'
				# AKL30='${AKL30}'
				# AKL40='${AKL40}'
				# AKL50='${AKL50}'
				# AKL51='${AKL51}'
				# AKL61='${AKL61}'
				# AKL71='${AKL71}'
				" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

				if [ x != "x${AKL10}" ] ; then
					AUDIO_KANAELE=1
				elif [ x != "x${AKL20}" ] ; then
					AUDIO_KANAELE=2
				elif [ x != "x${AKL30}" ] ; then
					AUDIO_KANAELE=3
				elif [ x != "x${AKL40}" ] ; then
					AUDIO_KANAELE=4
				elif [ x != "x${AKL50}" ] ; then
					AUDIO_KANAELE=5
				elif [ x != "x${AKL51}" ] ; then
					AUDIO_KANAELE=6
				elif [ x != "x${AKL61}" ] ; then
					AUDIO_KANAELE=7
				elif [ x != "x${AKL71}" ] ; then
					AUDIO_KANAELE=8
				fi
			fi

			echo "# 910 - ${LFD_NR}
			AUDIO_KANAELE='${AUDIO_KANAELE}'
			LFD_NR='${LFD_NR}'
			" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

			#--------------------------------------------------------------#

			AUDIO_OPTION_PRO_TONSPUR="$(F_AUDIO_QUALITAET ${LFD_NR})"

			#--------------------------------------------------------------#

			echo "# 920 - ${LFD_NR}
			AUDIO_OPTION_PRO_TONSPUR='${AUDIO_OPTION_PRO_TONSPUR}'
			AUDIO_SPUR_SPRACHE='${AUDIO_SPUR_SPRACHE}'
			" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

			if [ 0 -lt "${TS_ANZAHL}" ] ; then
				echo "# 930
				AUDIO_VERARBEITUNG_01:
				AUDIOQUALITAET='${AUDIOQUALITAET}'
				" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

				echo "-map 0:a:${TS_NR} -c:a:${LFD_NR} ${AUDIOCODEC} ${AUDIO_OPTION_PRO_TONSPUR} -metadata:s:a:${LFD_NR} language=${TS_SP}" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

				echo "# 940
				# AUDIO_SPUR_SPRACHE='${AUDIO_SPUR_SPRACHE}'
				# AUDIO_STANDARD_SPUR='${AUDIO_STANDARD_SPUR}'
				" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

				#------------------------------------------------------#

				if [ x != "x${AUDIO_STANDARD_SPUR}" ] ; then
					if [ "${LFD_NR}" = "${AUDIO_STANDARD_SPUR}" ] ; then
						echo "# 950" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
						echo "-disposition:a:${LFD_NR} default" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
					else
						echo "# 960" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
						echo "-disposition:a:${LFD_NR} 0" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
					fi
				fi
			else
				echo "# 970" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
				echo "-an" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
			fi
		done | tr -s '\n' ' ')"

		#----------------------------------------------------------------------#

		TS_KOPIE="$(seq 0 ${TS_ANZAHL} | head -n ${TS_ANZAHL})"
		AUDIO_VERARBEITUNG_02="$(for DIE_TS in ${TS_KOPIE}
		do
			#TONSPUR_SPRACHE="$(echo "${AUDIO_SPUR_SPRACHE}" | grep -E "^${DIE_TS} " | awk '{print $NF}' | head -n1)"

			echo "# 980
			# AUDIO_VERARBEITUNG_02=' -map 0:a:${DIE_TS} -c:a:${DIE_TS} copy'
			" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

			echo "-map 0:a:${DIE_TS} -c:a:${DIE_TS} copy"
		done | tr -s '\n' ' ')"
	else
		AUDIO_VERARBEITUNG_01="-an"
		AUDIO_VERARBEITUNG_02="-an"
	fi
fi

echo "" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
echo "# 990
# AUDIO_KANAELE='${AUDIO_KANAELE}'
# TONQUALIT='${TONQUALIT}'
# AUDIOQUALITAET='${AUDIOQUALITAET}'
# BEREITS_AK2='${BEREITS_AK2}'
# TS_LISTE='${TS_LISTE}'
# TS_KOPIE='${TS_KOPIE}'
# AUDIO_STANDARD_SPUR='${AUDIO_STANDARD_SPUR}'
# AUDIO_VERARBEITUNG_01='${AUDIO_VERARBEITUNG_01}'
# AUDIO_VERARBEITUNG_02='${AUDIO_VERARBEITUNG_02}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 1000

#==============================================================================#
### Untertitel
#
# Multiple -c, -codec, -acodec, -vcodec, -scodec or -dcodec options specified for stream 9, only the last option '-c:s copy' will be used.
#

# -map 0:s:0 -c:s:0 copy -map 0:s:1 -c:s:1 copy		# "0" für die erste Untertitelspur
# -map 0:s:${i} -scodec copy				# alt
# -map 0:s:${i} -c:s:${i} copy				# neu
# UNTERTITEL_SPUR_SPRACHE="0,1,2,3,4"
# UNTERTITEL_SPUR_SPRACHE="0:deu,1:eng,2:spa,3:fra,4:ita"
# UNTERTITEL_SPUR_SPRACHE="0:de,1:en,2:sp,3:fr,4:it"
# NOTA_SPUR_SPRACHE="0 de
# 1 en
# 2 sp
# 3 fr
# 4 it"

if [ x = "x${NOTA_SPUR_SPRACHE}" ] ; then
	IST_UT_ANZAHL="$(echo "${NOTA_SPUR_SPRACHE}" | grep -Ev '^$' | wc -l)"
	if [ 0 -eq ${IST_UT_ANZAHL} ] ; then
		UNTERTITEL_SPUR_SPRACHE="=0"
	fi
fi

echo "# 1005
# UT_HLS='${UT_HLS}'
"

if [ "kein Text" = "${UT_HLS}" ] ; then
	U_TITEL_FF_01="-sn"
	U_TITEL_FF_02="-sn"
	UNTERTITEL_STANDARD_SPUR=""
else
    if [ "=0" = "${UNTERTITEL_SPUR_SPRACHE}" ] ; then
	U_TITEL_FF_01="-sn"
	U_TITEL_FF_02="-sn"
	UNTERTITEL_STANDARD_SPUR=""
    else
	#======================================================================#
	### STANDARD-UNTERTITEL-SPUR

	### META-Daten der Untertitel-Spuren
	DN=0
	UNTERTITEL_VERARBEITUNG_01="$(echo "${NOTA_SPUR_SPRACHE}" | nl | awk '{print $1 - 1,$2,$3}' | while read UN UB US
	do
		if [ -r "${UB}" ] ; then
			DN="$(echo "0${DN}" | awk '{print $1 + 1}')";
			echo "${DN} ${UN} ${UB} ${US}";
		else
			echo     "0 ${UN} ${UB} ${US}";
		fi ;
	done | while read DN UN UB US REST
	do
		echo "-map ${DN}:s:${UB}"
		W_US="$(echo "${US}" | wc -w)"

		if [ 1 -gt ${W_US} ] ; then
			US="$(echo "${META_DATEN_SPURSPRACHEN}" | grep -F ' subtitle ' | nl | awk '{print $1 - 1,$4}' | grep -E "^${UB} " | awk '{print $2}')"
			if [ x = "x${US}" ] ; then
				US="und"
			fi
		fi
		echo "-metadata:s:s:${UN} language=${US}"

		#----------------------------------------------------------------------#
		### externe Untertiteldateien einbinden "-i"

		#      1  7_English.srt eng
		#      2  8_English.srt eng
		D_SUB="$(echo "${NOTA_SPUR_SPRACHE}" | nl | while read XUM XUD XUS; do if [ -r "${XUD}" ] ; then echo "${XUM} ${XUD} ${XUS}"; fi ; done | nl)"
		if [ x = "x${D_SUB}" ] ; then
			echo "# 1010: Es wurden keine externen Untertitel-Dateien übergeben." >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
		else
			I_SUB="$(echo "${D_SUB}" | while read XUN XUM XUD XUS REST; do echo "-i ${XUD}"; done | tr -s '\n' ' ')"
		fi

		#----------------------------------------------------------------------#

		### Die Bezeichnungen (Sprache) für die Audiospuren werden automatisch übernommen.
		if [ x = "x${UNTERTITEL_STANDARD_SPUR}" ] ; then
			### wenn nichts angegeben wurde, dann
			### Deutsch als Standard-Sprache voreinstellen
			UNTERTITEL_STANDARD_SPUR="$(echo "${NOTA_SPUR_SPRACHE}" | grep -Ei " de| ger" | awk '{print $1}' | head -n1)"

			if [ x = "x${UNTERTITEL_STANDARD_SPUR}" ] ; then
				### wenn nichts angegeben wurde
				### und es keine als deutsch gekennzeichnete Spur gibt, dann
				### STANDARD-UNTERTITEL-SPUR vom Originalfilm übernehmen
				### DISPOSITION:default=1
				UNTERTITEL_STANDARD_SPUR="$(echo "${META_DATEN_ZEILENWEISE_STREAMS}" | grep -F ';codec_type=subtitle;' | tr -s ';' '\n' | grep -F 'DISPOSITION:default=1' | grep -E 'default=[0-9]' | awk -F'=' '{print $2-1}')"
				if [ x = "x${UNTERTITEL_STANDARD_SPUR}" ] ; then
					### wenn es keine STANDARD-UNTERTITEL-SPUR im Originalfilm gibt, dann
					### alternativ einfach die erste Tonspur zur STANDARD-UNTERTITEL-SPUR machen
					UNTERTITEL_STANDARD_SPUR=0
				fi
			fi
		else
			#----------------------------------------------------------------------#
			### Die Werte für "Disposition" für die Untertitelspur werden nach dem eigenen Wunsch gesetzt.
			# -disposition:s:0 default
			# -disposition:s:1 0
			# -disposition:s:2 0

			if [ "${UN}" = "${UNTERTITEL_STANDARD_SPUR}" ] ; then
				echo "-disposition:s:${UN} default"
			else
				echo "-disposition:s:${UN} 0"
			fi
		fi
	done | tr -s '\n' ' ')"

	#----------------------------------------------------------------------#

	UT_KOPIE="$(echo "${NOTA_SPUR_SPRACHE}" | nl | awk '{print $1}')"
	UNTERTITEL_VERARBEITUNG_02="$(echo "${NOTA_SPUR_SPRACHE}" | nl | awk '{print $1 - 1,$2,$3}' | while read UN UB US
	do
		#UNTERTITEL_SPRACHE="$(echo "${NOTA_SPUR_SPRACHE}" | grep -E "^${UN} " | awk '{print $NF}' | head -n1)"

		echo "# 1020
		UNTERTITEL_VERARBEITUNG_02=' -map 0:s:${UN} -c:s:${UN} copy'
		" >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

		echo "-map 0:s:${UN} -c:s:${UN} copy"
	done | tr -s '\n' ' ')"

	#----------------------------------------------------------------------#

	if [ x = "x${NOTA_SPUR_SPRACHE}" ] ; then
		UTNAME="$(echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=subtitle' | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
		UT_META_DATEN="$(echo "${META_DATEN_STREAMS}" | grep -F 'codec_type=subtitle')"
		if [ "x${UT_META_DATEN}" != "x" ] ; then
			UT_LISTE="$(echo "${UT_META_DATEN}" | nl | awk '{print $1 - 1}' | tr -s '\n' ' ')"
		fi

		UT_LISTE="$(echo "${UTNAME}"      | sed 's/:[a-z]*/ /g;s/,/ /g')"
		UT_ANZAHL="$(echo "${UTNAME}"     | sed 's/,/ /g' | wc -w | awk '{print $1}')"
	else
		UT_LISTE="$(echo "${NOTA_SPUR_SPRACHE}"  | awk '{print $1}' | tr -s '\n' ' ')"
		UT_ANZAHL="$(echo "${NOTA_SPUR_SPRACHE}" | nl | tail -n1 | awk '{print $1}')"
	fi

	#----------------------------------------------------------------------#
	### Untertitel im Text-Format identifizieren

	if [ x = "x${UT_VORHANDEN}" ] ; then
		echo "# 1025
		# Es gibt in diesem Film keine Untertitel.
		" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
		unset UT_LISTE
		unset UT_ANZAHL
		unset UT_KOPIE
		unset UT_FORMAT
		unset U_TITEL_FF_01
		unset U_TITEL_FF_02
		U_TITEL_FF_01="-sn"
		U_TITEL_FF_02="-sn"
	else
		UNTERTITEL_TEXT_CODEC="$(echo "${IST_UT_FORMAT}" | grep -Ei 'SRT|VTT|SSA|ASS|SMIL|TTML|DFXP|SBV|irc|cap|SCC|itt|DFXP|mov_text')"
		if [ x = "x${UNTERTITEL_TEXT_CODEC}" ] ; then
			#------------------------------------------------------#
			### unveränderliches Untertitelformat kann nur kopiert
			### werden oder man muß ohne Untertitel weiter arbeiten
			echo "# 1030
			# Untertitel liegen im Bild-Format vor.
			# Diese können mit diesem Skript nicht verändert werden
			# und müssen entweder kopiert werden (ffmpeg ... -c:s copy)
			# oder können nicht in den neuen Film mit übertragen werden (${0} -u =0).
			" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

			### Film bzw. Filmteile transkodieren
			U_TITEL_FF_01="-c:s copy"
			#------------------------------------------------------#
		else
			#------------------------------------------------------#
			### Wenn der Untertitel in einem Text-Format vorliegt, dann muss er ggf. auch transkodiert werden.
			echo "# 1035
			# Untertitel liegen im Text-Format vor.
			" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

			if [ "mp4" = "${ENDUNG}" ] ; then
				UT_FORMAT="mov_text"
			else
				UT_FORMAT="webvtt"
			fi

			### Film bzw. Filmteile transkodieren
			U_TITEL_FF_01="-c:s ${UT_FORMAT}"
			#------------------------------------------------------#
		fi

		### ffmpeg -f concat
		U_TITEL_FF_02="-c:s copy"
	fi

	echo "# 1040
	# Untertitel im Text-Format identifizieren
	# UT_VORHANDEN='${UT_VORHANDEN}'
	# UNTERTITEL_TEXT_CODEC='${UNTERTITEL_TEXT_CODEC}'
	# UT_FORMAT='${UT_FORMAT}'
	" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
    fi
fi

echo "# 1050
# TS_LISTE='${TS_LISTE}'
#
# UT_META_DATEN='${UT_META_DATEN}'
#
# NOTA_SPUR_SPRACHE='${NOTA_SPUR_SPRACHE}'
# UT_LISTE='${UT_LISTE}'
# UT_FORMAT='${UT_FORMAT}'
# U_TITEL_FF_01='${U_TITEL_FF_01}'
# U_TITEL_FF_02='${U_TITEL_FF_02}'
# UNTERTITEL_VERARBEITUNG_01='${UNTERTITEL_VERARBEITUNG_01}'
# UNTERTITEL_VERARBEITUNG_02='${UNTERTITEL_VERARBEITUNG_02}'
#
# AUDIO_STANDARD_SPUR='${AUDIO_STANDARD_SPUR}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 1060

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
# stehen
#
if [ "Ja" = "${TEST}" ] ; then
	if [ x = "x${CROP}" ] ; then
		if [ x = "x${PROFIL_VF}" ] ; then
			VIDEOOPTION="$(echo "${PROFIL_OPTIONEN} ${VIDEOQUALITAET}" | sed 's/[,]$//')"
		else
			VIDEOOPTION="$(echo "${PROFIL_OPTIONEN} ${VIDEOQUALITAET} -vf ${PROFIL_VF}" | sed 's/[,]$//')"
		fi
	else
		VIDEOOPTION="$(echo "${PROFIL_OPTIONEN} ${VIDEOQUALITAET} -vf ${PROFIL_VF}${CROP}${BILD_DREHUNG}" | sed 's/[,]$//;s/[,][,]/,/g')"
	fi
else
	if [ x = "x${ZEILENSPRUNG}${CROP}${HLS_SCALE}${PAD}${BILD_SCALE}${h263_BILD_FORMAT}${FORMAT_ANPASSUNG}" ] ; then
		if [ x = "x${PROFIL_VF}" ] ; then
			VIDEOOPTION="$(echo "${PROFIL_OPTIONEN} ${VIDEOQUALITAET}" | sed 's/[,]$//')"
		else
			VIDEOOPTION="$(echo "${PROFIL_OPTIONEN} ${VIDEOQUALITAET} -vf ${PROFIL_VF}" | sed 's/[,]$//')"
		fi
	else
		VIDEOOPTION="$(echo "${PROFIL_OPTIONEN} ${VIDEOQUALITAET} -vf ${ZEILENSPRUNG}${PROFIL_VF}${CROP}${HLS_SCALE}${PAD}${BILD_SCALE}${h263_BILD_FORMAT}${FORMAT_ANPASSUNG}${BILD_DREHUNG}" | sed 's/[,]$//;s/[,][,]/,/g')"
	fi
fi

#------------------------------------------------------------------------------#

SCHNITT_ANZAHL="$(echo "${SCHNITTZEITEN}" | wc -w | awk '{print $1}')"

#------------------------------------------------------------------------------#

echo "# 1090
# SCHNITTZEITEN='${SCHNITTZEITEN}'
# SCHNITT_ANZAHL='${SCHNITT_ANZAHL}'
#
# TS_LISTE='${TS_LISTE}'
# TS_ANZAHL='${TS_ANZAHL}'
#
# BILDQUALIT='${BILDQUALIT}'
# VIDEOCODEC='${VIDEOCODEC}'
# VIDEOQUALITAET='${VIDEOQUALITAET}'
#
# AUDIO_VERARBEITUNG_01='${AUDIO_VERARBEITUNG_01}'
# AUDIO_VERARBEITUNG_02='${AUDIO_VERARBEITUNG_02}'
#
# VIDEOOPTION='${VIDEOOPTION}'
# FORMAT='${FORMAT}'
# START_ZIEL_FORMAT='${START_ZIEL_FORMAT}'
#
# TWO_PASS='${TWO_PASS}'
" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 1100

#set -x

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
### Wenn Audio- und Video-Spur nicht synchron sind,
### dann muss das korrigiert werden.

if [ x = "x${VIDEO_SPAETER}" ] ; then
	unset VIDEO_DELAY
else
	VIDEO_DELAY="-itsoffset ${VIDEO_SPAETER}"
fi

if [ x = "x${AUDIO_SPAETER}" ] ; then
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

CODEC_ODER_TARGET="$(echo "${VIDEOCODEC}" | grep -F -- '-target ')"
if [ x = "x${CODEC_ODER_TARGET}" ] ; then
	VIDEO_PARAMETER_PASS_1="-map 0:v:0 -c:v ${VIDEOCODEC} ${VIDEO_OPTION_PASS_1}"
	VIDEO_PARAMETER_TRANS="${IFRAME} -map 0:v:0 -c:v ${VIDEOCODEC} ${VIDEOOPTION}"
else
	VIDEO_PARAMETER_PASS_1="-map 0:v:0 ${VIDEOCODEC} ${VIDEO_OPTION_PASS_1}"
	VIDEO_PARAMETER_TRANS="${IFRAME} -map 0:v:0 ${VIDEOCODEC} ${VIDEOOPTION}"
fi

VIDEO_PARAMETER_KOPIE="-map 0:v:0 -c:v copy"

if [ "0" = "${VIDEO_NICHT_UEBERTRAGEN}" ] ; then
	VIDEO_PARAMETER_PASS_1=""
	VIDEO_PARAMETER_TRANS="-vn"
	VIDEO_PARAMETER_KOPIE="-vn"
	U_TITEL_FF_01="-sn"
	U_TITEL_FF_02="-sn"
fi

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
### Funktionen

#------------------------------------------------------------------------------#
# Es wird nur ein einziges Stück transkodiert
transkodieren_1_1()
{
	### 1001
	pwd
	echo "# 1110
	TWO_PASS='${TWO_PASS}'"

	if [ Ja = "${TWO_PASS}" ] ; then
		echo "# 1120 TWO_PASS='${TWO_PASS}'
		2-Pass: pass 1
		${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_PARAMETER_PASS_1} -pass 1 -passlogfile \"${ZIELVERZ}\"/\"${ZIEL_FILM}\".pass -an -sn ${FPS} -f null /dev/null"

		${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i "${FILMDATEI}" ${VIDEO_PARAMETER_PASS_1} -pass 1 -passlogfile "${ZIELVERZ}"/"${ZIEL_FILM}".pass -an -sn ${FPS} -f null /dev/null

		echo "# 1121 TWO_PASS='${TWO_PASS}'
		2-Pass: pass 2
		${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${I_SUB} ${VIDEO_PARAMETER_TRANS} -pass 2 -passlogfile \"${ZIELVERZ}\"/\"${ZIEL_FILM}\".pass ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${UNTERTITEL_VERARBEITUNG_01} ${FPS} ${SCHNELLSTART} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${METADATEN_BESCHREIBUNG}\"${KOMMENTAR}\" ${START_ZIEL_FORMAT} -y \"${ZIELVERZ}\"/\"${ZIEL_FILM}\".${ENDUNG}"

		ls -lha "${ZIELVERZ}"/"${ZIEL_FILM}".pass*
		${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i "${FILMDATEI}" ${I_SUB} ${VIDEO_PARAMETER_TRANS} -pass 2 -passlogfile "${ZIELVERZ}"/"${ZIEL_FILM}".pass ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${UNTERTITEL_VERARBEITUNG_01} ${FPS} ${SCHNELLSTART} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${METADATEN_BESCHREIBUNG}"${KOMMENTAR}" ${START_ZIEL_FORMAT} -y "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG} >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.out 2>&1 && WEITER=OK || WEITER=Fehler

		ls -lha "${ZIELVERZ}"/"${ZIEL_FILM}".pass*
		rm -fv "${ZIELVERZ}"/"${ZIEL_FILM}".pass*
	else
		echo "# 1130 TWO_PASS='${TWO_PASS}'
		${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${I_SUB} ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${UNTERTITEL_VERARBEITUNG_01} ${FPS} ${SCHNELLSTART} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${METADATEN_BESCHREIBUNG}'${KOMMENTAR}' ${START_ZIEL_FORMAT} -y \"${ZIELVERZ}\"/\"${ZIEL_FILM}\".${ENDUNG}"

		${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i "${FILMDATEI}" ${I_SUB} ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${UNTERTITEL_VERARBEITUNG_01} ${FPS} ${SCHNELLSTART} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${METADATEN_BESCHREIBUNG}"${KOMMENTAR}" ${START_ZIEL_FORMAT} -y "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG} >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.out 2>&1 && WEITER=OK || WEITER=Fehler
	fi
	echo "# 1140
	WEITER='${WEITER}'
	"
}

#------------------------------------------------------------------------------#
# Es werden mehrere Teile aus dem Original transkodiert und am Ende zu einem Film zusammengesetzt
transkodieren_4_1()
{
	### 1004
	pwd
	echo "# 1230
	TWO_PASS='${TWO_PASS}'"

	if [ Ja = "${TWO_PASS}" ] ; then
		echo "# 1240 TWO_PASS='${TWO_PASS}'
		2-Pass: pass 1 + Schnitt
       		${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_PARAMETER_PASS_1} -pass 1 -passlogfile \"${ZIELVERZ}\"/\"${ZIEL_FILM}\".pass -an -sn -ss ${VON} -to ${BIS} ${FPS} ${MMQS} -f null /dev/null"

       		${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i "${FILMDATEI}" ${VIDEO_PARAMETER_PASS_1} -pass 1 -passlogfile "${ZIELVERZ}"/"${ZIEL_FILM}".pass -an -sn -ss ${VON} -to ${BIS} ${FPS} ${MMQS} -f null /dev/null

		echo "# 1241 TWO_PASS='${TWO_PASS}'
		2-Pass: pass 2 + Schnitt
        	${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${I_SUB} ${VIDEO_PARAMETER_TRANS} -pass 2 -passlogfile \"${ZIELVERZ}\"/\"${ZIEL_FILM}\".pass ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${UNTERTITEL_VERARBEITUNG_01} -ss ${VON} -to ${BIS} ${FPS} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${METADATEN_BESCHREIBUNG}\"${KOMMENTAR}\" ${START_ZIEL_FORMAT} ${MMQS} -y \"${ZIELVERZ}\"/${ZUFALL}_${NUMMER}_\"${ZIEL_FILM}\".${ENDUNG}"

		ls -lha "${ZIELVERZ}"/"${ZIEL_FILM}".pass*
        	${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i "${FILMDATEI}" ${I_SUB} ${VIDEO_PARAMETER_TRANS} -pass 2 -passlogfile "${ZIELVERZ}"/"${ZIEL_FILM}".pass ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${UNTERTITEL_VERARBEITUNG_01} -ss ${VON} -to ${BIS} ${FPS} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${METADATEN_BESCHREIBUNG}"${KOMMENTAR}" ${START_ZIEL_FORMAT} ${MMQS} -y "${ZIELVERZ}"/${ZUFALL}_${NUMMER}_${ZIEL_FILM}.${ENDUNG} >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.out 2>&1 && WEITER=OK || WEITER=Fehler

		ls -lha "${ZIELVERZ}"/"${ZIEL_FILM}".pass*
		rm -fv "${ZIELVERZ}"/"${ZIEL_FILM}".pass*
	else
		echo "# 1250 TWO_PASS='${TWO_PASS}'
        	${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${I_SUB} ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${UNTERTITEL_VERARBEITUNG_01} -ss ${VON} -to ${BIS} ${FPS} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${METADATEN_BESCHREIBUNG}\"${KOMMENTAR}\" ${START_ZIEL_FORMAT} ${MMQS} -y \"${ZIELVERZ}\"/${ZUFALL}_${NUMMER}_\"${ZIEL_FILM}\".${ENDUNG}"

        	${PROGRAMM} ${FFMPEG_OPTIONEN} ${VIDEO_DELAY} ${KOMPLETT_DURCHSUCHEN} ${REPARATUR_PARAMETER} -i "${FILMDATEI}" ${I_SUB} ${VIDEO_PARAMETER_TRANS} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF_01} ${UNTERTITEL_VERARBEITUNG_01} -ss ${VON} -to ${BIS} ${FPS} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${METADATEN_BESCHREIBUNG}"${KOMMENTAR}" ${START_ZIEL_FORMAT} ${MMQS} -y "${ZIELVERZ}"/${ZUFALL}_${NUMMER}_"${ZIEL_FILM}".${ENDUNG} >> "${ZIELVERZ}"/${PROTOKOLLDATEI}.out 2>&1 && WEITER=OK || WEITER=Fehler
	fi
	echo "# 1260
	WEITER='${WEITER}'
	" | tee -a "${ZIELVERZ}"/${ZUFALL}_Status.txt
}

#------------------------------------------------------------------------------#
# Hiermit werden alle transkodierten Teile zu einem Film zusammengesetzt
transkodieren_7_1()
{
	### 1007
	# https://hatchjs.com/ffmpeg-unsafe-file-name/
	pwd
	echo "# 1350
	${PROGRAMM} ${FFMPEG_OPTIONEN} -f concat -safe 0 -i ${ZUFALL}_${PROTOKOLLDATEI}_Filmliste.txt ${I_SUB} ${VIDEO_PARAMETER_KOPIE} ${AUDIO_VERARBEITUNG_02} ${SCHNELLSTART} ${U_TITEL_FF_02} ${UNTERTITEL_VERARBEITUNG_02} ${METADATEN_TITEL}\"${EIGENER_TITEL}\" ${METADATEN_BESCHREIBUNG}'${KOMMENTAR}' ${START_ZIEL_FORMAT} -y \"${ZIEL_FILM}\".${ENDUNG}"

	${PROGRAMM} ${FFMPEG_OPTIONEN} -f concat -safe 0 -i ${ZUFALL}_${PROTOKOLLDATEI}_Filmliste.txt ${I_SUB} ${VIDEO_PARAMETER_KOPIE} ${AUDIO_VERARBEITUNG_02} ${SCHNELLSTART} ${U_TITEL_FF_02} ${UNTERTITEL_VERARBEITUNG_02} ${METADATEN_TITEL}"${EIGENER_TITEL}" ${METADATEN_BESCHREIBUNG}"${KOMMENTAR}" ${START_ZIEL_FORMAT} -y "${ZIEL_FILM}".${ENDUNG} >> ${PROTOKOLLDATEI}.out 2>&1 && WEITER=OK || WEITER=kaputt
	echo "# 1360
	WEITER='${WEITER}'
	" | tee -a "${ZIELVERZ}"/${ZUFALL}_Status.txt
}

#------------------------------------------------------------------------------#
# wenn ein zu großer Bereich von einer Datei übersprungen wird, dann muß dieser Wert erhöht werden: max_muxing_queue_size
max_muxing_queue_size()
{
	if [ x != "x${VON}" ] ; then
        	TEST_VON_IN="$(echo "${VON}" | awk '{printf "%.0f\n", $1}')"
        	if [ 100 -lt "${TEST_VON_IN}" ] ; then
                	MMQS="-max_muxing_queue_size $(echo "${VON} ${MUXING_QUEUE_SIZE_FAKTOR}" | awk '{printf "%.0f\n", $1 * $2}')"
        	fi
	fi
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#exit 1370
#------------------------------------------------------------------------------#
if [ ${SCHNITT_ANZAHL} -lt 1 ] ; then
	if [ ${SCHNITT_ANZAHL} -eq 1 ] ; then
		VON="-ss $(echo "${SCHNITTZEITEN}" | tr -d '"' | awk -F'-' '{print $1}')"
		BIS="-to $(echo "${SCHNITTZEITEN}" | tr -d '"' | awk -F'-' '{print $2}')"
		max_muxing_queue_size
	else
                unset MMQS
	fi

	###------------------------------------------------------------------###
	### hier der Film transkodiert                                       ###
	###------------------------------------------------------------------###
	echo
	### 1001
	transkodieren_1_1 | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

else

	echo '
	### 1002
	#----------------------------------------------------------------------#
	# Quelle: https://hatchjs.com/ffmpeg-unsafe-file-name/
	# unsichere Dateinamen sind Dateinamen, die folgende Eigenschaften aufweisen:
	# - Dateinamen enthalten Leerzeichen oder andere Sonderzeichen
	# - Dateinamen enthalten einen Punkt
	# - Dateinamen die mit einem "$" oder "!" enden
	# - Dateinamen die ".exe", ".bat", oder ".cmd" enthalten
	# - Dateinamen enthalten einen absoluten Pfad
	# [concat @ 0x2d36e484c000] Unsafe file name '/Test/tTt7OsNf5PJ5_01_Test.mp4'
	#----------------------------------------------------------------------#'
	# Leerzeichen will ich mal erlauben... :-)
	#echo "${ZIEL_FILM}" | grep -E '[ ]|[$]|[.]exe|[.]bat|[.]cmd' && exit 1
	echo "${ZIEL_FILM}" | grep -E '[$]|[.]exe|[.]bat|[.]cmd' && exit 1
	echo "${ZIEL_FILM}" | grep -F '!' && exit 1
	#----------------------------------------------------------------------#
	rm -f "${ZIELVERZ}"/${ZUFALL}_${PROTOKOLLDATEI}_Filmliste.txt
	NUMMER="0"
	for _SCHNITT in ${SCHNITTZEITEN}
	do
		echo "---------------------------------------------------------" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

                unset MMQS
		NUMMER="$(echo "${NUMMER}" | awk '{printf "%2.0f\n", $1+1}' | tr -s ' ' '0')"
		VON="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $1}')"
		BIS="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $2}')"
		max_muxing_queue_size

		###----------------------------------------------------------###
		### hier werden die Teile zwischen der Werbung transkodiert  ###
		###----------------------------------------------------------###
		echo
		### 1004
		transkodieren_4_1 | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

		ffprobe -v error -i "${ZIELVERZ}"/${ZUFALL}_${NUMMER}_"${ZIEL_FILM}".${ENDUNG} | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

                ### den Film in die Filmliste eintragen
		### CONCAT akzeptiert nur Dateinamen, keine Pfadnamen:
		### [concat @ 0x2d36e484c000] Unsafe file name '/daten/mm/oeffentlich/Video/Test/tTt7OsNf5PJ5_01_Test.mp4'
                echo "echo \"file '${ZUFALL}_${NUMMER}_${ZIEL_FILM}.${ENDUNG}'\" >> \"${ZIELVERZ}\"/${ZUFALL}_${PROTOKOLLDATEI}_Filmliste.txt" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
                echo "file '${ZUFALL}_${NUMMER}_${ZIEL_FILM}.${ENDUNG}'" >> "${ZIELVERZ}"/${ZUFALL}_${PROTOKOLLDATEI}_Filmliste.txt

		echo "---------------------------------------------------------" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	done

	### 1007
	echo "### 1007"
	(cd "${ZIELVERZ}"/ && transkodieren_7_1 | tee -a ${PROTOKOLLDATEI}.txt)
	echo "### 1008"

	rm -f "${ZIELVERZ}"/${ZUFALL}_*.txt

	ffprobe -v error -i "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG} | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

	#ls -lh ${ZUFALL}_*.${ENDUNG}
	rm -f "${ZIELVERZ}"/${ZUFALL}_*.${ENDUNG} ffmpeg2pass-0.log

fi

#------------------------------------------------------------------------------#

ls -lh "${ZIELVERZ}"/"${ZIEL_FILM}".${ENDUNG} "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
if [ -r "${ZIELVERZ}"/${ZUFALL}_Status.txt ] ; then
	cat "${ZIELVERZ}"/${ZUFALL}_Status.txt | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
	rm -f "${ZIELVERZ}"/${ZUFALL}_Status.txt
fi

LAUFZEIT="$(echo "${STARTZEITPUNKT} $(date +'%s')" | awk '{print $2 - $1}')"
echo "# 1380
$(date +'%F %T') (${LAUFZEIT})" | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt
if [ -r /var/log/messages ] ; then grep -F 'kernel:' /var/log/messages | grep -F 'killed:' | grep -F ffmpeg | tail -n1; fi | tee -a "${ZIELVERZ}"/${PROTOKOLLDATEI}.txt

#exit 1390

