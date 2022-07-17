@echo off

:: Necessary for some loop and branching operations
setlocal enabledelayedexpansion
:: Max 4chan file size for webm's, slightly reduced because ffmpeg averages the bitrate and it can become slightly bigger than the max size, even with perfect calculation
set max_file_size=2900
:: Defaults to no audio
set audiorate=-an

:: Check if script was started with a proper parameter
if "%~1" == "" (
	echo This script needs to be run by dragging and dropping a video file on it.
	echo It cannot do anything by itself.
	pause
	goto :EOF
)

:: Hello user ::
echo 4chan VP9 webm maker
echo by Anon
echo Note: This will take a long time to encode in comparison to VP8
echo.

:: Time for some setup ::
cd /d "%~dp0"

::Ask user which board they are making the webm for
echo Which board are you making the webm for? (Default 3)
set /p board="1 - /gif/ 2 - /wsg/ 3 - other: " %=%
echo.

if /I "!board!" EQU "1" (
	set max_file_size=3400
) ELSE (
	if /I "!board!" EQU "2" (
		set max_file_size=5300
	) ELSE (
			goto :skippedaudio
		)
)

:: Ask user if they want audio if creating webm for /gif/ or /wsg/
set /p audq="Would you like audio (y/N): " %=%
echo.

:skippedaudio

:: Ask user how big the webm should be 
echo Please enter webm render resolution. 
echo Example: 720 for 720p.
echo Default: Source video resolution.
set /p resolution="Enter: " %=%
if not "!resolution!" == "" (
	set resolutionset=-vf scale=-1:!resolution!
)
echo.

:: Ask user where to start webm rendering in source video
echo Please enter webm rendering offset in SECONDS.
echo Example: 31
echo Default: Start of source video.
set /p start="Enter: " %=%
if not "!start!" == "" (
	set startset=-ss !start!
)
echo.

:: Ask user for length of rendering ::
echo Please enter webm rendering length in SECONDS.
echo Example: 15
echo Default: Entire source video.
set /p length="Enter: " %=%
if not "%length%" == "" (
	set lengthset=-t %length%
) else (
	ffmpeg.exe -i %1 2> webm.tmp
	for /f "tokens=1,2,3,4,5,6 delims=:., " %%i in (webm.tmp) do (
		if "%%i"=="Duration" call :calculatelength %%j %%k %%l %%m
	)
	del webm.tmp
	echo Using source video length: !length! seconds
)
echo.

:: Find bitrate that maxes out max filesize on 4chan, defined above
set /a bitrate=8*!max_file_size!/!length!

:: 24k Audio is ok from my testing
if /I "!audq!" EQU "Y" (
	set audiorate=-c:a libopus -b:a 24K
	set /a "!bitrate!-=24"
)
echo Target bitrate: !bitrate!
del ffmpeg2pass-0.log
:: Two pass encoding because reasons
ffmpeg.exe -i "%~1" -c:v libvpx-vp9 -b:v !bitrate!K -deadline best !resolutionset! !startset! !lengthset! !audiorate! -sn -cpu-used 0 -g 128 -row-mt 1 -aq-mode 1 -pix_fmt yuv420p10le -f webm -pass 1 -y NUL
ffmpeg.exe -i "%~1" -c:v libvpx-vp9 -b:v !bitrate!K -deadline best !resolutionset! !startset! !lengthset! !audiorate! -sn -cpu-used 0 -g 128 -row-mt 1 -aq-mode 1 -pix_fmt yuv420p10le -f webm -pass 2 -y "%~n1-VP9.webm"
del ffmpeg2pass-0.log
goto :EOF

:: Helper function to calculate length of video
:calculatelength
for /f "tokens=* delims=0" %%a in ("%3") do set /a s=%%a
for /f "tokens=* delims=0" %%a in ("%2") do set /a s=s+%%a*60
for /f "tokens=* delims=0" %%a in ("%1") do set /a s=s+%%a*60*60
set /a length=s