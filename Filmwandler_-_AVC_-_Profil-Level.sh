#!/bin/sh

#------------------------------------------------------------------------------#
#
# Test-Skript!
#
#------------------------------------------------------------------------------#
# HD ready (HDTVmin)
#  4/3: 1024x768
# 16/9: 1280x720
#------------------------------------------------------------------------------#

if [ "x${1}" = x ] ; then
	echo "${0} [Bildwiederholrate]"
	echo "${0} 25"
	echo "${0} 50"
	exit 1
fi

if [ "x${1}" = x ] ; then
	W="50"
else
	W="${1}"
fi

SKRIPT_VERZ="$(dirname ${0})"

#==============================================================================#
### 4/3
sd()
{
for F in $(seq 60 208)
do
	#echo "${F}" | awk '{printf "%.0f %.0f\n", ($1*8)/2,($1*6)/2}' | awk '{print $1*2,$2*2,($1*2)/($2*2)}'
	#BB="$(echo " 4 ${F}" | awk '{printf "%.0f\n", $1*$2}' | awk '{print $1*2}')"
	BB="$(echo " 4 ${F}" | awk '{print $1*$2*2}')"
	#BH="$(echo " 3 ${F}" | awk '{printf "%.0f\n", $1*$2}' | awk '{print $1*2}')"
	BH="$(echo " 3 ${F}" | awk '{print $1*$2*2}')"
	AUFL="$(echo "${BB} ${BH}" | awk '{print $1"x"$2}')"
	BILDPUNKTE="$(echo "${BB} ${BH}" | awk '{print $1*$2}')"
	SV="$(echo "${BB} ${BH}" | awk '{print $1/$2}')"
	#echo -e "${F}:\t${BB} x ${BH} = ${BILDPUNKTE}\t(${SV})\t- $(${SKRIPT_VERZ}/Filmwandler_-_Blu-ray-Disc_-_AVC.sh ${AUFL} ${W} | grep -E '^level=')\t${W}Hz"

	# Test
	INFO="$(echo "${BB} ${BH} 8" | awk '{print $1/$3,$2/$3}')"
	echo -e "${F}:\t${BB} x ${BH} = ${BILDPUNKTE}\t(${SV})\t- $(${SKRIPT_VERZ}/Filmwandler_-_Blu-ray-Disc_-_AVC.sh ${AUFL} ${W} | grep -E '^level=')\t${W}Hz\t| ${INFO}"
done
}

#------------------------------------------------------------------------------#
### 16/9
hd()
{
for F in $(seq 10 60)
do
	#echo "${F}" | awk '{printf "%.0f %.0f\n", ($1*32)/2,($1*18)/2}' | awk '{print $1*2,$2*2,($1*2)/($2*2)}'
	BB="$(echo "16 ${F}" | awk '{print $1*$2*2}')"
	BH="$(echo " 9 ${F}" | awk '{print $1*$2*2}')"
	AUFL="$(echo "${BB} ${BH}" | awk '{print $1"x"$2}')"
	BILDPUNKTE="$(echo "${BB} ${BH}" | awk '{print $1*$2}')"
	SV="$(echo "${BB} ${BH}" | awk '{print $1/$2}')"
	#echo -e "${F}:\t${BB} x ${BH} = ${BILDPUNKTE}\t(${SV})\t- $(${SKRIPT_VERZ}/Filmwandler_-_Blu-ray-Disc_-_AVC.sh ${AUFL} ${W} | grep -E '^level=')\t${W}Hz"

	# Test
	INFO="$(echo "${BB} ${BH} 8" | awk '{print $1/$3,$2/$3}')"
	echo -e "${F}:\t${BB} x ${BH} = ${BILDPUNKTE}\t(${SV})\t- $(${SKRIPT_VERZ}/Filmwandler_-_Blu-ray-Disc_-_AVC.sh ${AUFL} ${W} | grep -E '^level=')\t${W}Hz\t| ${INFO}"
done
}

#------------------------------------------------------------------------------#

echo "#==============================================================================#"
sd
echo "#==============================================================================#"
hd
echo "#==============================================================================#"

