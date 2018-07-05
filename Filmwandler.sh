
#==============================================================================#
#
# https://trac.ffmpeg.org/wiki/Encode/AAC
#
#==============================================================================#

### libfdk_aac
#
# laut Debian ist libfdk_aac "non-free"-Licenc
# laut FSF, Fedora, RedHat ist libfdk_aac "free"-Licenc
#
# http://wiki.hydrogenaud.io/index.php?title=Fraunhofer_FDK_AAC#Recommended_Sampling_Rate_and_Bitrate_Combinations
#
# libfdk_aac -> Note, the VBR setting is unsupported and only works with some parameter combinations.
#
# FDK AAC kann im Modus "VBR" keine beliebige Kombination von Tonkanäle, Bit-Rate und Saple-Rate verarbeiten!
# Will man "VBR" verwenden, dann muss man explizit alle drei Parameter in erlaubter Größe angeben.
#

#------------------------------------------------------------------------------#

# Mit CRF legt man die Bildqualität fest.
# Die Option "-crf 16" erzeugt eine sehr gute Blu Ray - Qualität.
# -crf 12-21 sind hinsichtlich Kodiergeschwindigkeit und Dateigröße "gut"
# -crf 16-21 ist ein praxistauglicher Bereich für sehr gute Qualität
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
#
# -tune film verbessert die Qualität (gibt z.Z folgende: psnr ssim grain zerolatency fastdecode)

#==============================================================================#
# Betriebssystemabhängigkeiten

#
# Die internen (nativen) Codecs funktionieren immer (die sind ja fest drin),
# die externen Bibliotheken sind oft besser,
# müssen aber extra installiert werden.
#
# Weil die GPL-Lizenz, unter der Linux steht, nicht kompatiebel mit den Lizenzen
# vieler Codec-Bibliotheken ist (z. B. solcher, die unter BSD-Lizenz stehen),
# ist es auf den meisten Linux-Distributionen schwierig, diese Codec-Bibliotheken 
# zu installieren.
# Deshalb werden hier nur interne Codecs zur Verwendung vorgesehen.
# (auch wenn sie schlechter oder sogar noch experimentell sind)
#

if [ "FreeBSD" = "$(uname -s)" ] ; then
	# Audio
	AUDIOCODEC="libfdk_aac"
	AUDIO_QUALITAET_0="-vbr 1"			# 1 bis 5, 4 empfohlen
	AUDIO_QUALITAET_1="-vbr 2"			# 1 bis 5, 4 empfohlen
	AUDIO_QUALITAET_2="-vbr 3"			# 1 bis 5, 4 empfohlen
	AUDIO_QUALITAET_3="-vbr 4"			# 1 bis 5, 4 empfohlen
	AUDIO_QUALITAET_4="-vbr 4"			# 1 bis 5, 4 empfohlen
	AUDIO_QUALITAET_5="-vbr 4"			# 1 bis 5, 4 empfohlen
	AUDIO_QUALITAET_6="-vbr 5"			# 1 bis 5, 4 empfohlen
	AUDIO_QUALITAET_7="-vbr 5"			# 1 bis 5, 4 empfohlen
	AUDIO_QUALITAET_8="-vbr 5"			# 1 bis 5, 4 empfohlen
	AUDIO_QUALITAET_9="-vbr 5"			# 1 bis 5, 4 empfohlen

	VIDEOCODEC="libx264"
else
	# Audio
	# https://slhck.info/video/2017/02/24/vbr-settings.html
	AUDIOCODEC="aac"
	AUDIO_QUALITAET_0="-q:a 0.10"			# undokumentiert (0.1-?) / 0.12 ~ 128k
	AUDIO_QUALITAET_1="-q:a 0.11"			# undokumentiert (0.1-?) / 0.12 ~ 128k
	AUDIO_QUALITAET_2="-q:a 0.12"			# undokumentiert (0.1-?) / 0.12 ~ 128k
	AUDIO_QUALITAET_3="-q:a 0.13"			# undokumentiert (0.1-?) / 0.12 ~ 128k
	AUDIO_QUALITAET_4="-q:a 0.14"			# undokumentiert (0.1-?) / 0.12 ~ 128k
	AUDIO_QUALITAET_5="-q:a 0.15"			# undokumentiert (0.1-?) / 0.12 ~ 128k
	AUDIO_QUALITAET_6="-q:a 0.16"			# undokumentiert (0.1-?) / 0.12 ~ 128k
	AUDIO_QUALITAET_7="-q:a 0.17"			# undokumentiert (0.1-?) / 0.12 ~ 128k
	AUDIO_QUALITAET_8="-q:a 0.18"			# undokumentiert (0.1-?) / 0.12 ~ 128k
	AUDIO_QUALITAET_9="-q:a 0.19"			# undokumentiert (0.1-?) / 0.12 ~ 128k

	VIDEOCODEC="h264"
fi


#==============================================================================#

# Format
ENDUNG="mp4"
FORMAT="mp4"

# Video
VIDEO_OPTION="-preset slow"
VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 25"	# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 24"	# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 23"	# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 22"	# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 21"	# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 20"	# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 19"	# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 18"	# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 17"	# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 16"	# von "0" (verlustfrei) bis "51"
IFRAME="-keyint_min 2-8"

#==============================================================================#
# Funktionen

FORMAT_BESCHREIBUNG="
********************************************************************************
* Name:			MP4                                                    *
* ENDUNG:		.mp4                                                   *
* Video-Kodierung:	H.264 (MPEG-4 Part 10 / AVC / Blu Ray / AVCHD)         *
* Audio-Kodierung:	AAC       (mehrkanalfähiger Nachfolger von MP3)        *
* Beschreibung:                                                                *
*	- HTML5-Unterstützung                                                  *
*	- hohe Kompatibilität mit Konsumerelektronik                           *
*	- auch abspielbar auf Android                                          *
********************************************************************************
"
