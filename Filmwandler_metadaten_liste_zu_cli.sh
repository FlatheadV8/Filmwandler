#!/bin/sh

#VERSION="v2023010700"
VERSION="v2023010800"		# Sprachbezeichnungen

#------------------------------------------------------------------------------#

AVERZ="$(dirname ${0})"			# Arbeitsverzeichnis, hier liegen diese Dateien

#------------------------------------------------------------------------------#

if [ "x${1}" = x ] ; then
	echo "Es muss diesem Skript eine Liste übergeben werden."
	echo ""
	echo "${AVERZ}/Filmwandler_metadaten_anzeigen.sh > Liste.txt"
	echo "${0} Liste.txt"
	exit 11
else
	if [ ! -r "${1}" ] ; then
		echo "Die Liste '${1}' konnte nicht gelesen werden"
		echo ""
		echo "${AVERZ}/Filmwandler_metadaten_anzeigen.sh > Liste.txt"
		echo "${0} Liste.txt"
		exit 12
	fi
fi

#------------------------------------------------------------------------------#

# 34497 | 03:01:44.727166666 | 1920x1080 | 0,1,2,3 | 0,1,2,3,4 | Vikings_-_S4_Vol_1_Disc_2/Vikings – Season 4 Volume 1 – Disc 2_t04.mkv
cat "${1}" | grep -F '|' | while read A
do
	DATANSATZ="$(echo "${A}" | sed 's/|/\n/g' | sed 's/^[ ]*//;s/[ ]*$//')"
	GR="$(echo "${DATANSATZ}" | head -n1 | tail -n1)"
	DAUER="$(echo "${DATANSATZ}" | head -n2 | tail -n1)"
	AUFL="$(echo "${DATANSATZ}" | head -n3 | tail -n1)"
	TONSPUREN="$(echo "${DATANSATZ}" | head -n4 | tail -n1)"
	TON_LANG="$(echo "${DATANSATZ}" | head -n5 | tail -n1)"
	UNTERTITELSP="$(echo "${DATANSATZ}" | head -n6 | tail -n1)"
	U_LANG="$(echo "${DATANSATZ}" | head -n7 | tail -n1)"
	DATEINAME="$(echo "${DATANSATZ}" | head -n8 | tail -n1)"

	#echo "'${GR}' / '${DAUER}' / '${AUFL}' / '${TONSPUREN}' / '${UNTERTITELSP}' / '${DATEINAME}'"

	if [ "x${TONSPUREN}" = x ] ; then
		TON_TON_SPUREN=""
	else
		TON_TON_SPUREN="-ton ${TONSPUREN}"
	fi

	if [ "x${UNTERTITELSP}" = x ] ; then
		U_UNTERTITEL_SP=""
	else
		U_UNTERTITEL_SP="-u ${UNTERTITELSP}"
	fi

	echo "${AVERZ}/Filmwandler_transkodieren.sh -q \"${DATEINAME}\" -z \"${DATEINAME}\" ${TON_TON_SPUREN} ${U_UNTERTITEL_SP} # ${TON_LANG} / ${U_LANG}"
done

