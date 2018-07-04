# Filmwandler
Mit diesem Skript kann man einen beliebigen Film in eines von 10 sehr verbreiteten Formaten umwandeln.

Das Skript besitzt viele weitere nützliche Optionen, siehe:

    ~/bin/Filmwandler.sh -h

mit den beiden folgenden Kommandos können Filme erzeugt werden, die auch auf dem "iPad", "iPad2" und "iPad mini"
abspielbar sind:

    ~/bin/Filmwandler.sh -q Aufnahme.mpeg -z meinFilm.mp4 -soll_xmaly 1024x576
    ~/bin/Filmwandler.sh -q Aufnahme.mpeg -z meinFilm.mp4 -soll_xmaly iPad

Zur Zeit können mit diesem Skript die folgenden Film-Formate erzeugt werden:

    ********************************************************************************
    * Name:             AVCHD                                                      *
    * ENDUNG:           .mp4                                                       *
    * Video-Kodierung:  H.264 (MPEG-4 Part 10 / AVC / Blu Ray)                     *
    * Audio-Kodierung:  AAC   (mehrkanalfähiger Nachfolger von MP3)                *
    * Beschreibung:                                                                *
    *   - höchste Kompatibilität mit Konsumerelektronik                            *
    *   - HTML5-Unterstützung                                                      *
    *   - abspielbar auf Android                                                   *
    ********************************************************************************


    ********************************************************************************
    * Name:             DivX10                                                     *
    * ENDUNG:           .mkv                                                       *
    * Video-Kodierung:  H.265/HEVC (entwickelt für 4K)                             *
    * Audio-Kodierung:  AAC        (mehrkanalfähiger Nachfolger von MP3)           *
    * Beschreibung:                                                                *
    *   - (noch) keine HTML5-Unterstützung                                         *
    *   - abspielbar auf Android                                                   *
    ********************************************************************************


    ********************************************************************************
    * Name:             OGG                                                        *
    * ENDUNG:           .ogv                                                       *
    * Video-Kodierung:  Theora (freie Alternative zu DivX5)                        *
    * Audio-Kodierung:  Vorbis (freie Alternative zu MP3)                          *
    * Beschreibung:                                                                *
    *   - 'Royalty free' (komplett frei von patentierten Technologien)             *
    *   - mit HTML5-Unterstützung                                                  *
    *   - der ogv-Container ist uneingeschränkt streaming-fähig                    *
    *   - abspielbar auf Android                                                   *
    *   - kodiert sehr schnell                                                     *
    *   - nicht so gut wie 'AVCHD'                                                 *
    ********************************************************************************


    ********************************************************************************
    * Name:             WebM                                                       *
    * ENDUNG:           .webm                                                      *
    * Video-Kodierung:  VP9  (freie Alternative zu H.265 für 4K)                   *
    * Audio-Kodierung:  Opus (freie Alternative zu AAC)                            *
    * Beschreibung:                                                                *
    *   - 'Royalty free' (komplett frei von patentierten Technologien)             *
    *   - mit HTML5-Unterstützung                                                  *
    *   - abspielbar auf Android                                                   *
    *   - Unterstützung ab Android 5 'Lollipop'                                    *
    *   - beste Qualität                                                           *
    *   - kodiert 5-10 mal langsamer als AVCHD                                     *
    ********************************************************************************


    ********************************************************************************
    * Name:             DivX5                                                      *
    * ENDUNG:           .avi                                                       *
    * Video-Kodierung:  H.263+                                                     *
    * Audio-Kodierung:  MP3                                                        *
    * Beschreibung:                                                                *
    *   - abspielbar auf vielen größeren Konsumergeräten                           *
    *   - Advanced Simple Profile (ASP)                                            *
    *   - ASP-Codec mit der größten Verbreitung, bevor AVC ihn verdrengt hat       *
    *   - FourCC DIVX (Hack of AVI)                                                *
    *   - FourCC DX50 (DivX Version 5 / MPEG-4 Visual)                             *
    *   - MP3 -> MPEG-1 Layer 3                                                    *
    ********************************************************************************


    ********************************************************************************
    * Name:             3GPP                                                       *
    * ENDUNG:           .3gp                                                       *
    * Video-Kodierung:  H.263                                                      *
    * Audio-Kodierung:  AAC                                                        *
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

---

Dieses Skript ist optimiert für FreeBSD, funktioniert aber auch auf Linux.

Da es Probleme zwischen der GPL und den Lizenzen vieler Codec-Bibliotheken gibt, ist es häufig problematisch diese Codec-Bibliotheken auf vielen Linux-Distributionen zu betreiben.

Aus diesem Grund werden nur auf FreeBSD die externen Codec-Bibliotheken (per Voreinstellung) verwendet.
Alle anderen Betriebssysteme, auf denen dieses Skript läuft, werden die nativen (internen) Codecs von FFmpeg verwenden.

Leider sind einige von den nativen (internen) Codecs noch im Stadium "experimentell" (aber alle im Skript konfigurierten Codecs funktionieren). In den meisten Fällen erbringen die externen Codec-Bibliotheken bessere Ergebnisse.
