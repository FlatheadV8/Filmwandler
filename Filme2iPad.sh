#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Mit diesem Skript kann man einen Film in einen "*.mp4"-Film umwandeln,
# der vom iPad, iPad2 und iPad mini abgespielt werden kann.
# Der hiermit erzeugte Film hat eine maximale Auflösung von 1024x576 Bildpunkten (Pixel).
#
#
# Es werden folgende Programme von diesem Skript verwendet:
#  - mediainfo
#  - avconv (libav-tools) oder ffmpeg (mit ffmpeg getestet)
#
#
### iPad2
# http://walter.bislins.ch/blog/index.asp?page=Videos+konvertieren+f%FCr+iPad#H_Empfohlenes_iPad_Format
#
#------------------------------------------------------------------------------#

VERSION="v2015092000"

#==============================================================================#

while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -q)
                        FILMDATEI="${2}"
                        shift
                        ;;
                -z)
                        MP4DATEI="${2}"
                        shift
                        ;;
                -ton)
                        TONSPUR=${2}     # "0:5" ist die 4. Tonspur also, weil 0 die erste ist (0, 1, 2, 3), muss hier "3" stehen
                        TSNAME="${2}"
                        shift
                        ;;
                -h)
                        echo "
                        HILFE:
                        # Video- und Audio-Spur in ein iPad-kompatibles Format transkodieren
                        ${0} [Option] -q [Filmname] -z [Neuer_Filmname.mp4]
                        ${0} [Option] -q [Filmname] -z [Neuer_Filmname.m4v]
                        ${0} -q Film.mkv -z Film.mp4
                        ${0} -ton 1 -q Film.mkv -z Film.m4v
                        ${0} -ton 2 -q Film.mkv -z Film.mp4
                        ${0} -ton 3 -q \"Film mit Leerzeichen.mkv\" -z Film.m4v

                        Es duerfen in den Dateinamen keine Leerzeichen, Sonderzeichen
                        oder Klammern enthalten sein!
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

#------------------------------------------------------------------------------#

if [ -z "${TONSPUR}" ] ; then
        TONSPUR="0"     # die erste Tonspur ist "0"
fi

case "${MP4DATEI}" in
        [a-zA-Z0-9\_\-\+][a-zA-Z0-9\_\-\+]*[.][Mm][Pp4][Vv4])
                ENDUNG="richtig"
                shift
                ;;
        *)
                ENDUNG="falsch"
                shift
                ;;
esac

if [ -z "${TSNAME}" ] ; then
        MP4DATEI="$(echo "${MP4DATEI} ${TSNAME}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"."$2}')"
else
        MP4DATEI="$(echo "${MP4DATEI} ${TSNAME}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"_-_Tonspur_"$3"."$2}')"
fi

#------------------------------------------------------------------------------#

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
VIDEOCODEC="libx264"

if [ "FreeBSD" = "$(uname -s)" ] ; then
        AUDIOCODEC="libfaac"    # "non-free"-Lizenz; funktioniert aber
        #AUDIOCODEC="aac"       # free-Lizenz; ist noch experimentell
        #AUDIOCODEC="aac -strict experimental"
elif [ "Linux" = "$(uname -s)" ] ; then
        #AUDIOCODEC="libfaac"   # "non-free"-Lizenz; funktioniert aber
        #AUDIOCODEC="aac"       # free-Lizenz; ist noch experimentell
        AUDIOCODEC="aac -strict experimental" # das geht ohne www.medibuntu.org
fi

if [ "${AUDIOCODEC}" != "copy" ] ; then
        AUDIOOPTION="-b:a 128k -ar 44100"
fi

#==============================================================================#

PROGRAMM="$(which avconv)"
if [ -z "${PROGRAMM}" ] ; then
        PROGRAMM="$(which ffmpeg)"
fi

if [ -z "${PROGRAMM}" ] ; then
        echo "Weder avconv noch ffmpeg konnten gefunden werden. Abbruch!"
        exit 1
fi

#==============================================================================#
### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt
SCAN_TYPE="$(mediainfo -f ${FILMDATEI} | grep -Fv pixels | awk -F':' '/Scan type[ ]+/{print $2}' | tr -s ' ' '\n' | egrep -v '^$' | head -n1)"
if [ "${SCAN_TYPE}" != "Progressive" ] ; then
        ### wenn der Film im Zeilensprungverfahren vorliegt
        ZEILENSPRUNG="yadif,"
fi

### universelle Variante
VIDEOOPTION="-vf ${ZEILENSPRUNG}pad='max(iw\\,ih*(16/9)):ow/(16/9):(ow-iw)/2:(oh-ih)/2',scale='1024:576',setsar='1/1'"

START_iPad="${PROGRAMM} -i ${FILMDATEI} ${OPTIONEN} -map 0:v -map 0:a:${TONSPUR} -c:v ${VIDEOCODEC} ${VIDEOOPTION} -c:a ${AUDIOCODEC} ${AUDIOOPTION} -y ${MP4DATEI}"

#==============================================================================#
echo "
${START_iPad}
"

${START_iPad}

echo "
${START_iPad}
"
#------------------------------------------------------------------------------#

exit
