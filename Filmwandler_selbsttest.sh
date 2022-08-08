#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Selbsttest
#
#------------------------------------------------------------------------------#

#VERSION="v2020100100"		# erste Version, noch ohne erweiterte Parameter
VERSION="v2020100200"		# Schönheitsverbesserungen

#==============================================================================#

if [ "x${1}" = x ] ; then
        ${0} -h
	exit 11
fi

while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -q)
                        FILMDATEI="${2}"	# Name für die Quelldatei
                        shift
                        ;;
                -h)
			#ausgabe_hilfe
                        echo "HILFE:
	# Vom Testfilm werden die ersten 10 Sekunden übersprungen und die
	# darauffolgenden 60 Sekunden verwendet.
	# Als Testfilm kann man jedes beliebige Video-Material nutzen,
	# welches FFmpeg lesen kann.

	# Beisliel:
        ${0} -q testfilm

	# Es wird daraus ein Basisfilm erstellt, dabei werden ausschließlich nur
	# interne Codecs und Formate verwendet, damit niemals der Fall eintritt,
	# bei dem bereits der Basisfilm schon nicht generiert werden kann.

	# Zur Zeit wird der Video-Codec FFv1 genutz, weil er sehr leistungsfähig
	# ist. Als Audio-Codec wird a52/ac3 genutzt, weil es der einzige interne
	# mehrkanalfähige Codec ist. Und als Container-Format wird AVI genutzt,
	# weil es das am besten unterstützte interne Container-Format ist.
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

AVERZ="$(dirname ${0})"			# Arbeitsverzeichnis, hier liegen diese Dateien
ZUFALL="$(head -c 100 /dev/urandom | base64 | tr -d '\n' | tr -cd '[:alnum:]' | cut -b-12)"

### Basismaterial zum testen erstellen
ffmpeg -i ${FILMDATEI} -map 0:v:0 -c:v ffv1 -b:v 3600k -vf scale=640x480 -map 0:a:0 -c:a ac3 -b:a 640k -ss 10 -to 70 -f avi -y ${ZUFALL}_Basisfilm.avi

### Testumfang festlegen
ENDUNGEN="$(ls ${AVERZ}/Filmwandler_Format_*.txt | awk '{gsub("[_.]"," "); print $(NF-1)}')"
echo "${ENDUNGEN}" > ${ZUFALL}_ENDUNGEN.txt

### Test
for TEST in ${ENDUNGEN}
do
	echo "${AVERZ}/Filmwandler.sh -q ${ZUFALL}_Basisfilm.avi -z ${ZUFALL}_Testfilm.${TEST}"
	${AVERZ}/Filmwandler.sh -q ${ZUFALL}_Basisfilm.avi -z ${ZUFALL}_Testfilm.${TEST} 2>&1 | tee ${ZUFALL}_Testfilm.${TEST}.log
done

ls -rtlha ${ZUFALL}_*
