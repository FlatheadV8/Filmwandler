# Filmwandler
Mit diesem Skript kann man einen beliebigen Film in verschiedene Formaten umwandeln (transkodieren), die sehr verbreiteten sind.

Am 10. Juli 2004 habe ich meine erste Digitalkamera (eine "KONICA MINOLTA DiMAGE Z1") bekommen, leider konnte ich die damit erzeugten Videos (AVI) nur am PC anschauen oder über die Kamera am Fernseher. Jedoch nicht mit unserem DVD-HDD-Recorder "Philips DVDR3460H", obwohl er "DivX 5"-Filme abspielen konnte.
Daraus resultierten Ende 2004 die ersten Versuche, Filme in ein Format zu transkodieren, mit dem es auf handelsüblicher Consumer-Elektronik am Fernseher abspielbar wird -> damit begann die 1. Generation von diesem Skript (das arbeitete noch mit MPlayer/MEncoder).
Ab 2005 begann ich mir über ein sinnvolles Ziel-Format Gedanken zu machen. Es sollte nicht nur auf diesem speziellen DVD-HDD-Recorder abspielbar sein, sondern auf allen Geräten, die einen bestimmten Standard unterstützen.
Zu diesem Zeitpunkt gab es praktisch nur 3 Formate, die von der Indutrie breit unterstützt wurden: VCD, DVD und BD.
Im Internet erfreute sich allerdings noch das "DivX 5"-Format großer Beliebtheit. Leider wurde das aber kaum von Consumer-Elektronik unterstützt. VCD hat eine viel zu schlechte Qualität, DVD hatte eine viel zu schlechte Kompression und BD konnte man erst seit April 2010 mit freier Software (x264) erstellen (also erst ca. 5 Jahre später). Also habe ich zuerst meine Filme in das "DivX 5"-Format transkodiert und ab Mitte 2010 habe ich mir dann über verschiedene Foren alle Informationen beschafft, um mit dem Encoder "x264" BD-kompatiblen Kode generieren zu können. Das hat bis 2012 gedauert. Danach ist das Skript dann mit den umfangreichen Berechnungen (die ich damals noch selbst im Skript ausführte), sehr unübersichtlich geworden. Später konnte ich einen Teil dieser Berechnungen, zur Umwandlung der Bildauflösung (damit die Kreise rund bleiben, also keine Verzerrungen auftreten, wenn das Format z.B. von 4/3 auf 16/9 geändert wird), von FFmpeg durchführen lassen.
Leider habe ich bei den ersten 3 Generationen immer unlösbare Probleme bekommen, bei der Fehlerbehebung, wenn der Umfang die 5000 Kodezeilen überschritten hatte. Mit der 4. Genaration habe ich es stark modularisiert und hatte damit sehr gute Erfahrungen gemacht. Dann hatte ich nicht mehr soviel Zeit und hatte deshalb die letzten Fehler aus der 4. Generation nie behoben.
Am 29. Oktober 2018 wurde die Entwicklung an der 4. Generation eingestellt.
Statt dessen habe ich aus der 4. Generation eine abgespeckte Version extrahiert, die nur MP4 im HTML-5-Standard erzeugen konnte (Film2MP4.sh). Diese wurde bis September 2019 soweit erweitert, dass ich mit dem "Funktionsmantel" von diesem Skript problemlos den "Funktionsmantel" der 4. Generation ersetzen konnte und so wurde am 22. September 2019 die 5. Generation geboren.

Download:

https://github.com/FlatheadV8/Filmwandler

https://github.com/FlatheadV8/Filmwandler/releases/

https://github.com/FlatheadV8/Filmwandler/releases/latest

Das Skript besitzt viele weitere nützliche Optionen, siehe:

    ~/bin/Filmwandler.sh -h

mit den beiden folgenden Kommandos können Filme erzeugt werden, die auch auf dem "iPad", "iPad2" und "iPad mini"
abspielbar sind:

    ~/bin/Filmwandler.sh -q Aufnahme.mpeg -z meinFilm.mp4 -soll_xmaly 1024x576
    ~/bin/Filmwandler.sh -q Aufnahme.mpeg -z meinFilm.mp4 -soll_xmaly iPad

Zur Zeit können mit diesem Skript die folgenden Film-Formate erzeugt werden:

    ********************************************************************************
    * Name:                 AVCHD                                                  *
    * ENDUNG:               .mp4                                                   *
    * Video-Kodierung:      H.264 (MPEG-4 Part 10 / AVC / Blu Ray)                 *
    * Audio-Kodierung:      AAC   (mehrkanalfähiger Nachfolger von MP3)            *
    * Beschreibung:                                                                *
    *       - hohe Kompatibilität mit Konsumerelektronik                           *
    *       - HTML5-Unterstützung                                                  *
    *       - abspielbar auf Android                                               *
    ********************************************************************************


    ********************************************************************************
    * Name:                 Matroska                                               *
    * ENDUNG:               .mkv                                                   *
    * Video-Kodierung:      AV1  (freie Alternative zu H.265 für 4K)               *
    * Audio-Kodierung:      Opus                                                   *
    * Beschreibung:                                                                *
    *       - freies Format mit sehr hoher Kompressionsrate                        *
    ********************************************************************************


    ********************************************************************************
    * Name:                 WebM                                                   *
    * ENDUNG:               .webm                                                  *
    * Video-Kodierung:      VP9  (freie Alternative zu H.265 für 4K)               *
    * Audio-Kodierung:      Opus (freie Alternative zu AAC)                        *
    * Beschreibung:                                                                *
    *       - mit HTML5-Unterstützung                                              *
    *       - WebM kann leider nur das eine Untertitelformat "WebVTT"              *
    *       - 'Royalty free' (komplett frei von patentierten Technologien)         *
    *       - WebM wird seit Android  2.3 'Gingerbread' unterstützt                *
    *       - VP9 wird seit Android 4.4 'KitKat' unterstützt                       *
    *       - Opus wird seit Android 5 'Lollipop' unterstützt                      *
    *       - kodiert 5-10 mal langsamer als AVCHD/MP4                             *
    ********************************************************************************


    ********************************************************************************
    * Name:                 OGG                                                    *
    * ENDUNG:               .ogg                                                   *
    * Video-Kodierung:      VP8    (freie Alternative zu H.264)                    *
    * Audio-Kodierung:      Vorbis (freie Alternative zu MP3)                      *
    * Beschreibung:                                                                *
    *       - mit HTML5-Unterstützung                                              *
    *       - auch abspielbar auf Android                                          *
    *       - 'Royalty free' (komplett frei von patentierten Technologien)         *
    *       - der ogg-Container ist uneingeschränkt streaming-fähig                *
    *       - kodiert sehr schnell                                                 *
    *       - nicht so gut wie 'AVCHD/MP4'                                         *
    ********************************************************************************


    ********************************************************************************
    * Name:                 DivX5                                                  *
    * ENDUNG:               .avi                                                   *
    * Video-Kodierung:      H.263+                                                 *
    * Audio-Kodierung:      MP3                                                    *
    * Beschreibung:                                                                *
    *   - abspielbar auf vielen größeren Konsumergeräten                           *
    *   - Advanced Simple Profile (ASP)                                            *
    *   - ASP-Codec mit der größten Verbreitung, bevor AVC ihn verdrengt hat       *
    *   - FourCC DIVX (Hack of AVI)                                                *
    *   - FourCC DX50 (DivX Version 5 / MPEG-4 Visual)                             *
    *   - MP3 -> MPEG-1 Layer 3                                                    *
    ********************************************************************************


    ********************************************************************************
    * Name:                 XviD                                                   *
    * ENDUNG:               .avi                                                   *
    * Video-Kodierung:      H.263++ (MPEG-4 Part 2 / ASP / DivX Version 5)         *
    * Audio-Kodierung:      MP3                                                    *
    * Beschreibung:                                                                *
    *       - hohe Kompatibilität mit Konsumerelektronik (DivX 5 / XviD)           *
    ********************************************************************************


    ********************************************************************************
    * Name:                 3GPP                                                   *
    * ENDUNG:               .3gp                                                   *
    * Video-Kodierung:      H.263                                                  *
    * Audio-Kodierung:      AAC                                                    *
    * Beschreibung:                                                                *
    *   - abspielbar auf vielen kleineren Konsumergeräten                          *
    *       * die meisten dieser Abspielgeräte können nur 15 FPS                   *
    *   - Advanced Simple Profile (ASP)                                            *
    *   - H.263 kann aber leider nur diese Formate beherbergen:                    *
    *       * 128x96                                                               *
    *       * 176x144                                                              *
    *       * 352x288                                                              *
    *       * 704x576                                                              *
    *       * 1408x1152                                                            *
    ********************************************************************************


    ********************************************************************************
    * Name:                 3GPP2                                                  *
    * ENDUNG:               .3g2                                                   *
    * Video-Kodierung:      H.263 (MPEG-4 Part 2 / ASP)                            *
    * Audio-Kodierung:      AAC                                                    *
    * Beschreibung:                                                                *
    *       - H.263 kann aber leider nur diese Formate beherbergen:                *
    *           * 128x96                                                           *
    *           * 176x144                                                          *
    *           * 352x288                                                          *
    *           * 704x576                                                          *
    *           * 1408x1152                                                        *
    ********************************************************************************


    ********************************************************************************
    * Name:                 VCD / DVD                                              *
    * ENDUNG:               .mpg                                                   *
    * Video-Kodierung:      MPEG-1 / MPEG-2                                        *
    * Audio-Kodierung:      MP2 / AC3                                              *
    * Beschreibung:                                                                *
    *       - hohe Kompatibilität mit Konsumerelektronik                           *
    *       - ähnlich dem VCD-/DVD-Format                                          *
    ********************************************************************************

---

Dieses Skript ist optimiert für FreeBSD, funktioniert aber auch auf Linux.

Da es Probleme zwischen der GPL und den Lizenzen vieler Codec-Bibliotheken gibt, ist es häufig problematisch diese Codec-Bibliotheken auf vielen Linux-Distributionen zu betreiben.

Aus diesem Grund werden nur auf FreeBSD die externen Codec-Bibliotheken (per Voreinstellung) verwendet.
Alle anderen Betriebssysteme, auf denen dieses Skript läuft, werden die nativen (internen) Codecs von FFmpeg verwenden.

Leider sind einige von den nativen (internen) Codecs noch im Stadium "experimentell" (aber alle im Skript konfigurierten Codecs funktionieren). In den meisten Fällen erbringen die externen Codec-Bibliotheken bessere Ergebnisse.
