#!/bin/sh

#------------------------------------------------------------------------------#
#
# Test-Skript!
# siehe auch Filmwandler_-_AVC_-_Profil-Level.sh
#
#------------------------------------------------------------------------------#

#VERSION="v2022072700"		# erstellt
#VERSION="v2022080100"		# MaxBR + MaxCPB angepasst
#VERSION="v2022080101"		# Farbraumunterscheidung für SD und HD wieder aktiviert
#VERSION="v2022080300"		# Funktion AVC_LEVEL neu geschrieben + Fehlerausgabe und Info verbessert
#VERSION="v2022080400"		# Fehler in Farbraum-Kodierung behoben
VERSION="v2022080401"		# mit --bluray-compat lassen sich ein paar Zusatzoptionen einsparen

if [ "x${2}" = "x" ] ; then
	echo "${0} [Bildbreite] [Bildhöhe] [Bildwiederholrate]"
	echo "${0} 1024x576  25"
	echo "${0} 1024x768  25"
	echo "${0} 1440x1080 50"
	echo "${0} 1280x720  25"
	echo "${0} 1920x1080 50"
	exit 1
fi

AUFL="${1}"			# 1280x720
IN_FPS="${2}"			# 25

BILD_BREIT="$(echo "${AUFL}" | sed 's/x.*$//')"
BILD_HOCH="$(echo "${AUFL}" | sed 's/^.*x//')"

#==============================================================================#
#------------------------------------------------------------------------------#
### Bluray-kompatibele Werte errechnen

#------------------------------------------------------------------------------#
BLURAY_PARAMETER()
{
        VERSION="v2014010500"
        PROFILE="high"

        FNKLEVEL="${1}"
        MBREITE="${2}"
        MHOEHE="${3}"
        MaxFS="${4}"

        #----------------------------------------------------------------------#
        ### Blu-ray-kompatible Parameter ermitteln

        # --bluray-compat

	BHVERH="$(echo "${MBREITE} ${MHOEHE} ${MaxFS}" | awk '{verhaeltnis="gut"; if ($1 > (sqrt($3 * 8))) verhaeltnis="schlecht" ; if ($2 > (sqrt($3 * 8))) verhaeltnis="schlecht" ; print verhaeltnis}')"

        #echo "# 420 BLURAY_PARAMETER_01:
	# FNKLEVEL='${FNKLEVEL}'
	# MBREITE='${MBREITE}'
	# MHOEHE='${MHOEHE}'
	# MaxFS='${MaxFS}'
        #"

	#exit

        if [ "${BHVERH}" != "gut" ] ; then
                echo "# 430 BLURAY_PARAMETER_02:
                Das Makroblock-Seitenverhaeltnis von ${MBREITE}/${MHOEHE} wird von AVC nicht unterstuetzt!
                ABBRUCH
                "
                exit 1
        fi

        BIAF420="$(echo "${BILD_BREIT} ${BILD_HOCH}" | awk '{print $1 * $2 * 1.5}')"

        #----------------------------------------------------------------------#

        #LEVEL="$(echo "${FNKLEVEL}" | sed 's/[0-9]$/.&/')"
        LEVEL="$(echo "${FNKLEVEL}" | awk '{print $1 / 10}')"

	#======================================================================#
        #   http://forum.doom9.org/showthread.php?t=101345
        #   http://forum.doom9.org/showthread.php?t=154533
        #   https://de.wikipedia.org/wiki/H.264#Level
	SLICES=1
        if [ "${FNKLEVEL}" = "10" -a "${PROFILE}" = "high" ] ; then
		MaxBR="80"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="80"			# vbv-bufsize
                MaxVmvR="-64,63.75"             # noch ungenutzt (max. Vertical MV component range)
                MinCR="2"			# noch ungenutzt (würde auch nur bei crf=0 von Bedeutung sein)
                CRF="25"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "11" -a "${PROFILE}" = "high" ] ; then
		MaxBR="240"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="240"			# vbv-bufsize
                CRF="25"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "12" -a "${PROFILE}" = "high" ] ; then
		MaxBR="480"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="480"			# vbv-bufsize
                CRF="25"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "13" -a "${PROFILE}" = "high" ] ; then
		MaxBR="960"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="960"			# vbv-bufsize
                CRF="25"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "20" -a "${PROFILE}" = "high" ] ; then
		MaxBR="2500"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="2500"			# vbv-bufsize
                MaxVmvR="-128,127.75"           # noch ungenutzt (max. Vertical MV component range)
                MinCR="2"			# noch ungenutzt (würde auch nur bei crf=0 von Bedeutung sein)
                CRF="24"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "21" -a "${PROFILE}" = "high" ] ; then
		MaxBR="5000"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="5000"			# vbv-bufsize
                MaxVmvR="-256,255.75"           # noch ungenutzt (max. Vertical MV component range)
                MinCR="2"			# noch ungenutzt (würde auch nur bei crf=0 von Bedeutung sein)
                CRF="24"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "22" -a "${PROFILE}" = "high" ] ; then
		MaxBR="5000"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="5000"			# vbv-bufsize
                CRF="24"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "30" -a "${PROFILE}" = "high" ] ; then
		#MaxBR="12500"			# https://de.wikipedia.org/wiki/H.264#Level
                #MaxCPB="12500"			# https://de.wikipedia.org/wiki/H.264#Level
		#MaxBR="12000"			# (BD) https://forum.doom9.org/showthread.php?t=154533
		#MaxCPB="12000"			# (BD) https://forum.doom9.org/showthread.php?t=154533
		MaxBR="12000"			# (DVD) https://forum.doom9.org/showthread.php?t=154533
		MaxCPB="12000"			# (DVD) https://forum.doom9.org/showthread.php?t=154533
                MaxVmvR="-256,255.75"           # noch ungenutzt (max. Vertical MV component range)
                MinCR="2"			# noch ungenutzt (würde auch nur bei crf=0 von Bedeutung sein)
                CRF="23"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "31" -a "${PROFILE}" = "high" ] ; then
		#MaxBR="17500"			# https://de.wikipedia.org/wiki/H.264#Level
                #MaxCPB="17500"			# https://de.wikipedia.org/wiki/H.264#Level
		#MaxBR="16800"			# (BD) https://forum.doom9.org/showthread.php?t=154533
		#MaxCPB="16800"			# (BD) https://forum.doom9.org/showthread.php?t=154533
		MaxBR="15000"			# (DVD) https://forum.doom9.org/showthread.php?t=154533
		MaxCPB="15000"			# (DVD) https://forum.doom9.org/showthread.php?t=154533
                MaxVmvR="-512,511.75"           # noch ungenutzt (max. Vertical MV component range)
                MinCR="4"			# noch ungenutzt (würde auch nur bei crf=0 von Bedeutung sein)
                CRF="23"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "32" -a "${PROFILE}" = "high" ] ; then
		#MaxBR="25000"			# https://de.wikipedia.org/wiki/H.264#Level
                #MaxCPB="25000"			# vbv-bufsize
		#MaxBR="24000"			# (BD) https://forum.doom9.org/showthread.php?t=154533
		#MaxCPB="24000"			# (BD) https://forum.doom9.org/showthread.php?t=154533
		MaxBR="15000"			# (DVD/HD) https://forum.doom9.org/showthread.php?t=154533
		#MaxBR="8000"			# (DVD/SD) https://forum.doom9.org/showthread.php?t=154533
		MaxCPB="15000"			# (DVD) https://forum.doom9.org/showthread.php?t=154533
                MaxVmvR="-512,511.75"           # noch ungenutzt (max. Vertical MV component range)
                MinCR="4"			# noch ungenutzt (würde auch nur bei crf=0 von Bedeutung sein)
                CRF="23"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "40" -a "${PROFILE}" = "high" ] ; then
		#MaxBR="25000"			# https://de.wikipedia.org/wiki/H.264#Level
                #MaxCPB="25000"			# https://de.wikipedia.org/wiki/H.264#Level
		#MaxBR="24000"			# (BD/SD) https://forum.doom9.org/showthread.php?t=154533
		#MaxCPB="24000"			# (BD/SD) https://forum.doom9.org/showthread.php?t=154533
		MaxBR="15000"			# (DVD) https://forum.doom9.org/showthread.php?t=154533
		MaxCPB="15000"			# (DVD) https://forum.doom9.org/showthread.php?t=154533
                CRF="23"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "41" -a "${PROFILE}" = "high" ] ; then
		#MaxBR="62500"			# https://de.wikipedia.org/wiki/H.264#Level
                #MaxCPB="62500"			# https://de.wikipedia.org/wiki/H.264#Level
		#MaxBR="40000"			# (BD) https://forum.doom9.org/showthread.php?t=154533
		#MaxCPB="30000"			# (BD) https://forum.doom9.org/showthread.php?t=154533
		MaxBR="15000"			# (DVD) https://forum.doom9.org/showthread.php?t=154533
		MaxCPB="15000"			# (DVD) https://forum.doom9.org/showthread.php?t=154533
		SLICES=4
                CRF="23"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "42" -a "${PROFILE}" = "high" ] ; then
		MaxBR="62500"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="62500"			# vbv-bufsize
                CRF="22"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "50" -a "${PROFILE}" = "high" ] ; then
		MaxBR="168750"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="168750"			# vbv-bufsize
                MaxVmvR="-512,511.75"           # noch ungenutzt (max. Vertical MV component range)
                MinCR="2"			# noch ungenutzt (würde auch nur bei crf=0 von Bedeutung sein)
                CRF="21"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "51" -a "${PROFILE}" = "high" ] ; then
		MaxBR="300000"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="300000"			# vbv-bufsize
                CRF="20"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        elif [ "${FNKLEVEL}" = "52" -a "${PROFILE}" = "high" ] ; then
		MaxBR="300000"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="300000"			# vbv-bufsize
                CRF="20"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        else
		MaxBR="300000"			# vbv-maxrate (darf nie kleiner als vbv-bufsize sein)
                MaxCPB="300000"			# vbv-bufsize
                MaxVmvR="-512,511.75"           # noch ungenutzt (max. Vertical MV component range)
                MinCR="2"			# noch ungenutzt (würde auch nur bei crf=0 von Bedeutung sein)
                CRF="20"			# Qualität bzw. Kompression: 16 (sehr gut) ... 25 (gut genug)
        fi

}

#==============================================================================#
#==============================================================================#
### ???

# if(pyramid)
#     MaxDPB >= (bytes in a frame) * min(16, ref + 2)
# else if(bframes)
#     MaxDPB >= (bytes in a frame) * min(16, ref + 1)
# else
#     MaxDPB >= (bytes in a frame) * ref

#------------------------------------------------------------------------------#
### NTSC-, PAL- oder Blu-ray-Farbraum

#if [ "${IN_FPS}" = "10" -o "${IN_FPS}" = "15" -o "${IN_FPS}" = "20" -o "${IN_FPS}" = "24" ] ; then
#	# HDTV-Standard
#	FARBCOD="bt470"
#elif [ "${IN_FPS}" = "25" -o "${IN_FPS}" = "50" ] ; then
#	# DVD (PAL): 4/3 - 720x576
#	FARBCOD="bt470bg"
#else
#	# DVD (NTSC): 4/3 - 720x480
#	FARBCOD="smpte170m"        # SD: bt.601
#fi

#------------------------------------------------------------------------------#
### Farbraum für SD oder HD

if   [ "${BILD_HOCH}" -le "480" ] ; then
	FARBCOD="smpte170m"		# 480 (SD): SMPTE 170M / BT.601
elif [ "${BILD_HOCH}" -le "576" ] ; then
	FARBCOD="bt470bg"		# 576 (SD): BT.470 BG
else
	FARBCOD="bt709"			# 720, 1080 (HD): BT.709-5
fi

#------------------------------------------------------------------------------#

#echo "# 440:
# BILD_BREIT='${BILD_BREIT}'
# BILD_HOCH='${BILD_HOCH}'
# IN_FPS='${IN_FPS}'
# MBREITE/MHOEHE='${MBREITE}/${MHOEHE}'
#"

KEYINT="$(echo "${IN_FPS}" | awk '{printf "%.0f\n", $1 * 2}')"	# alle 2 Sekunden ein Key-Frame
#==============================================================================#

#==============================================================================#
### Berechnung des AVC-Profil-Level

# echo "720 576 25" | awk '{printf "%f %.0f %f %.0f %.0f\n",$1/16,$1/16,$2/16,$2/16,$3}' | awk '{if ($1 > $2) $2 = $2+1 ; if ($3 > $4) $4 = $4+1 ; print "MBLOCK =",$2 * $4"\nRBLOCK =",$2 * $4 * $5}'
# MBLOCK = 1620  (Makroblöcke je Bild)
# RBLOCK = 40500 (Makroblöcke eines Bildes pro Sekunde)

QUADR_MAKROBLOECKE="$(echo "${BILD_BREIT} ${BILD_HOCH}" | awk '{printf "%f %.0f %f %.0f\n",$1/16,$1/16,$2/16,$2/16}' | awk '{if ($1 > $2) $2 = $2+1 ; if ($3 > $4) $4 = $4+1 ; print $2,$4}')"
MAKRO_BLK_im_BILD="$(echo "${QUADR_MAKROBLOECKE}" | awk '{print $1 * $2}')"
MAKRO_BLK_in_SEKUNDE="$(echo "${MAKRO_BLK_im_BILD} ${IN_FPS}" | awk '{printf "%f %.0f\n",$1*$2,$1*$2}' | awk '{if ($1 > $2) $2 = $2+1 ; print $2}')"

#------------------------------------------------------------------------------#
### AVC-Level + Makroblöcke pro Sekunde + Makroblockgröße

# http://blog.mediacoderhq.com/h264-profiles-and-levels/
# https://de.wikipedia.org/wiki/H.264#Level
AVCL_MBPS_MBPB="
10    99    1485
11   396    3000
12   396    6000
13   396   11880
20   396   11880
21   792   19800
22  1620   20250
30  1620   40500
31  3600  108000
32  5120  216000
40  8192  245760
41  8192  245760
42  8704  522240
50 22080  589824
51 36864  983040
52 36864 2073600
"

LEVEL="$(echo "${AVCL_MBPS_MBPB}" | grep -Ev '^[ \t]*$' | while read AVC_LEVEL MAKRO_BLK_pro_BILD MAKRO_BLK_pro_SEKUNDE
do
	#echo "level='${AVC_LEVEL}' ${MAKRO_BLK_pro_BILD} ${MAKRO_BLK_pro_SEKUNDE} ; ${BILD_BREIT}x${BILD_HOCH}_${IN_FPS} ; ${MAKRO_BLK_im_BILD} ${MAKRO_BLK_in_SEKUNDE}"

	if [ "${MAKRO_BLK_pro_BILD}" -ge "${MAKRO_BLK_im_BILD}" ] ; then
		if [ "${MAKRO_BLK_pro_SEKUNDE}" -ge "${MAKRO_BLK_in_SEKUNDE}" ] ; then
			echo "${AVC_LEVEL}"
		fi
	fi
done | head -n1)"
#==============================================================================#

#==============================================================================#
MaxFS="$(echo "${BILD_BREIT} ${BILD_HOCH}" | awk '{print $1 * $2}')"
BLURAY_PARAMETER ${LEVEL} ${QUADR_MAKROBLOECKE} ${MaxFS}

#==============================================================================#
### Qualität

# Mit CRF legt man die Bildqualität fest.
# Die Option "-crf 16" erzeugt eine sehr gute Blu Ray - Qualität.
# -crf 12-21 sind hinsichtlich Kodiergeschwindigkeit und Dateigröße "gut"
# -crf 16-21 ist ein praxistauglicher Bereich für sehr gute Qualität
# -crf 20-26 ist ein praxistauglicher Bereich für gute Qualität
# -crf 27-34 ist ein praxistauglicher Bereich für befriedigende Qualität
#
# Mit dem PRESET legt man die Dateigröße und die Kodiergeschwindigkeit fest.
# -preset ultrafast
# -preset superfast
# -preset veryfast
# -preset faster
# -preset fast
# -preset medium   (Standard)
# -preset slow     (bester Kompromiss)
# -preset slower   (nur unwesentlich besser als "slow" aber merklich langsamer)
# -preset veryslow (wenig besser aber sehr viel langsamer)

### https://encodingwissen.de/codecs/x264/referenz/#no-psy
### alle psychovisuellen Algorithmen werden abgeschaltet
### (auch interne, die keinen Schalter besitzen)
### mit diesem Parameter wird ca. 15% schneller kodiert
### und die kodierte Datei wird 10-36% kleiner sein
# --no-psy

### diese Option verbessert die Qualität
### und vergrößert die kodierte Datei um ca. 15-20%
# -tune zerolatency
# -tune fastdecode
# -tune film

#------------------------------------------------------------------------------#
### Die Option "-profile:v" hat nur dann Wirkung, wenn auch die Option "-level" angegeben wird!

if [ "x${MaxBR}" = "x" -o "x${MaxCPB}" = "x" ] ; then
	echo "# 460
	FEHLER:
	für BluDisk-Kompatibilität ist 'nal-hrd=vbr' zwingend notwendig
	und 'nal-hrd=vbr' braucht die VBV-Optionen
	vbv-maxrate='${MaxBR}'
	vbv-bufsize='${MaxCPB}'
	"
	exit 460
else
	### https://forum.doom9.org/showthread.php?t=154533
	### --bluray-compat: Enforce x264 to create BD compliant stream, that will reduce x264 settings to BD compatible: bframe<=3, ref<=4 for 1080, ref<=6 for 720/576/480, bpyramid<=strict, weightp<=1, aud=1, nalhrd=vbr
	#VIDEO_OPTION="-profile:v ${PROFILE} -preset veryslow -tune film -x264opts ref=4:b-pyramid=strict:bluray-compat=1:weightp=0:vbv-maxrate=${MaxBR}:vbv-bufsize=${MaxCPB}:level=${LEVEL}:slices=4:b-adapt=2:direct=auto:colorprim=${FARBCOD}:transfer=${FARBCOD}:colormatrix=${FARBCOD}:keyint=${KEYINT}:aud:subme=9:nal-hrd=vbr"
	VIDEO_OPTION="-profile:v ${PROFILE} -preset veryslow -tune film -x264opts bluray-compat=1:vbv-maxrate=${MaxBR}:vbv-bufsize=${MaxCPB}:level=${LEVEL}:slices=1:b-adapt=2:direct=auto:colorprim=${FARBCOD}:transfer=${FARBCOD}:colormatrix=${FARBCOD}:keyint=${KEYINT}:subme=9"
fi

VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 30"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_1="${VIDEO_OPTION} -crf 28"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_2="${VIDEO_OPTION} -crf 26"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_3="${VIDEO_OPTION} -crf 24"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_4="${VIDEO_OPTION} -crf 22"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_5="${VIDEO_OPTION} -crf 20"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_6="${VIDEO_OPTION} -crf 19"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_7="${VIDEO_OPTION} -crf 18"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_8="${VIDEO_OPTION} -crf 17"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_9="${VIDEO_OPTION} -crf 16"		# von "0" (verlustfrei) bis "51"

IFRAME="-keyint_min 2-8"

#echo "# 470:
# LEVEL='${LEVEL}'
#
# profile=${PROFILE}
# rate=${MaxBR}
# vbv-bufsize=${MaxCPB}
# level=${LEVEL}
# colormatrix='${FARBCOD}'
#"

#echo "'${BILD_BREIT}'x'${BILD_HOCH}'@'${IN_FPS}' Bildpunkte='${MaxFS}' level='${LEVEL}'"

M_R_BLOCK="$(echo "${BILD_BREIT} ${BILD_HOCH} ${IN_FPS}" | awk '{printf "%f %.0f %f %.0f %.0f\n",$1/16,$1/16,$2/16,$2/16,$3}' | awk '{if ($1 > $2) $2 = $2+1 ; if ($3 > $4) $4 = $4+1 ; print $2 * $4,$2 * $4 * $5}')"
#echo "level='${LEVEL}'  ${BILD_BREIT}x${BILD_HOCH}_${IN_FPS}  ${MaxFS}  ${M_R_BLOCK}" | awk '{print $1"\t"$2"  \t"$3"   \t"$4"  \t"$5}'
echo "level='${LEVEL}'  ${BILD_BREIT}x${BILD_HOCH}_${IN_FPS}  ${MaxFS}  ${M_R_BLOCK}" | awk '{print $3"   \t"$2"  \t"$4"      \t"$5"    \t"$1}'

#==============================================================================#

#exit
