@ECHO ON
SETLOCAL ENABLEDELAYEDEXPANSION

::_________________________ VARiABLES _________________________

SET MEDIAINFO="C:\LiberKey\MyApps\MediaInfo_CLI\MediaInfo.exe"
SET MKVEXTRACT="C:\LiberKey\MyApps\mkvtoolnix\mkvextract.exe"
SET ASS2SRT="C:\LiberKey\MyApps\ass2srt\ASS2SRT(WPF).exe"
SET MKVMERGE="C:\LiberKey\MyApps\mkvtoolnix\mkvmerge.exe"

SET LANG="French France"
set ATTR=%~a1
set DIRATTR=%ATTR:~0,1%

::___________________________ BEGiN ___________________________

:: Is the given argument a folder or a file ? (Source: https://ss64.com/nt/syntax-args.html)
IF /I "%DIRATTR%"=="d" (
	SET WORKING_DIR=%1
	CD !WORKING_DIR!

	:: For each mkv inside de given directory in argument
	FOR /F "usebackq delims=;" %%f IN (`dir /b *.mkv`) DO (

		REM Detect which track ID is the searched subtitle
		%MEDIAINFO% --Inform="Text;%%ID%%: %%Language/String%%\n" "%%f" | FINDSTR %LANG% > srt_track_id.tmp
		FOR /F "tokens=1 delims=:" %%t IN (srt_track_id.tmp) DO SET /a TRACK_ID=%%t-1

		REM Extract the french subtitle
		%MKVEXTRACT% "%%f" tracks !TRACK_ID!:%LANG%.ass

		REM Convert the ASS sub to SRT
		%ASS2SRT% /SOURCE=!WORKING_DIR:"=! /TARGET=!WORKING_DIR:"=!

		REM 5 seconds pause
		PING -n 5 127.0.0.1 >nul

		REM Merge the RAW + ASS + SRT in the right order and with the SRT as default sub
		%MKVMERGE% --ui-language en --output SUB.mkv --no-subtitles --language 0:jpn --track-name 0:Erai-Raws --default-track 0:yes --language 1:jpn --default-track 1:yes ^"^(^" ^"%%~f^" ^"^)^" --language 0:fre --track-name ^"0:Francais ^(SRT^)^" --default-track 0:yes ^"^(^" %LANG%.srt ^"^)^" --language 0:fre --track-name ^"0:Francais ^(ASS^)^" --default-track 0:no ^"^(^" %LANG%.ass ^"^)^" --track-order 0:0,0:1,1:0,2:0

		REM Delete temporary files
		DEL srt_track_id.tmp 2>nul
		DEL *.ass 2>nul
		DEL *.srt 2>nul
		MOVE SUB.mkv "SUBFRENCH_%%~nf.mkv"
	)
) ELSE IF /I "%DIRATTR%"=="-" (
	ECHO THIS IS A FILE

	REM Detect which track ID is the searched subtitle
	%MEDIAINFO% --Inform="Text;%%ID%%: %%Language/String%%\n" "%~1" | FINDSTR %LANG% > srt_track_id.tmp
	FOR /F "tokens=1 delims=:" %%t IN (srt_track_id.tmp) DO SET /a TRACK_ID=%%t-1
	ECHO !TRACK_ID!

	REM Extract the french subtitle
	%MKVEXTRACT% "%~1" tracks !TRACK_ID!:%LANG%.ass

	REM Convert the ASS sub to SRT
	%ASS2SRT% /SOURCE=%~dp1 /TARGET=%~dp1

	REM Pause
	PING -n 5 127.0.0.1 >nul

	REM Merge the RAW + ASS + SRT in the right order and with the SRT as default sub
	%MKVMERGE% --ui-language en --output SUB.mkv --no-subtitles --language 0:jpn --track-name 0:Erai-Raws --default-track 0:yes --language 1:jpn --default-track 1:yes ^"^(^" ^"%~1^" ^"^)^" --language 0:fre --track-name ^"0:Francais ^(SRT^)^" --default-track 0:yes ^"^(^" %LANG%.srt ^"^)^" --language 0:fre --track-name ^"0:Francais ^(ASS^)^" --default-track 0:no ^"^(^" %LANG%.ass ^"^)^" --track-order 0:0,0:1,1:0,2:0

	REM Delete temporary files
	DEL srt_track_id.tmp 2>nul
	DEL *.ass 2>nul
	DEL *.srt 2>nul
	MOVE SUB.mkv "SUBFRENCH_%~n1.mkv"
)
