@echo off
chcp 437 >nul
cd /d "%~dp0"
setlocal enabledelayedexpansion
echo.

REM MANUALLY: set "sites=google.com microsoft.com yahoo.com"
set "sites="  


set "output_dir=%~dp0Net_Protocols_Test"
if not exist "!output_dir!" (
    mkdir "!output_dir!"
    if errorlevel 1 (
        echo Failed to create output directory: "!output_dir!"
        pause
        exit /b 11
    )
)
del "!output_dir!\*_debug_*.txt" >nul 2>&1

set protocols=ip4 ip6 tr4 tr6 tls htp dns



:: ______________________________________________________________________________ ::
::                                                                                ::
::                               ARGUMENTS HANDLING                               ::
:: ______________________________________________________________________________ ::

if /i "%~1"=="/?"       goto :help
if /i "%~1"=="-?"       goto :help
if /i "%~1"=="--?"      goto :help
if /i "%~1"=="/help"    goto :help
if /i "%~1"=="-help"    goto :help
if /i "%~1"=="--help"   goto :help

:parse_args
if "%~1"=="" goto :after_args
if /i "%~1"=="/site"    goto :handle_site
if /i "%~1"=="/only"    goto :handle_only
if /i "%~1"=="/exclude" goto :handle_exclude
if /i "%~1"=="/debug"   goto :handle_debug
if /i "%~1"=="/nopause" goto :handle_nopause

echo  Argument not recognized : "%~1" & pause & goto :help

:handle_site
shift
:collect_sites
if "%~1"=="" goto :parse_args
set "arg1=%~1"
if "!arg1:~0,1!"=="/" goto :parse_args
set "arg=%~1"
if defined resetedsites (set "sites=!sites!;!arg!") else (set "sites=!arg!")
set "resetedsites=1"
shift
goto :collect_sites

:handle_only
shift
:collect_onlys
if "%~1"=="" goto :parse_args
set "arg1=%~1"
if "!arg1:~0,1!"=="/" goto :parse_args
set "arg=%~1"
set "found_protocol="
for %%P in (%protocols%) do (
    if /i "!arg!"=="%%P" (
        set "global_only_%%P=true"
        set "global_only_active=true"
        set "found_protocol=1"
    )
)
if "!found_protocol!"=="" (
    echo.
    echo  Invalid protocol "!arg!" specified after /only
    echo  Valid values are : 
    echo    - ip4 = Ping IPv4 
    echo    - ip6 = Ping IPv6
    echo    - tr4 = Traceroute IPv4 
    echo    - tr6 = Traceroute IPv6
    echo    - htp = HTTPS 
    echo    - tls = TLS 1.2
    echo    - dns = DNS lookup
    echo. & echo  Press any key to see Help & pause >nul & goto :help
)
shift
goto :collect_onlys

:handle_exclude
shift
:collect_excludes
if "%~1"=="" goto :parse_args
set "arg1=%~1"
if "!arg1:~0,1!"=="/" goto :parse_args
set "arg=%~1"
set "found_protocol="
for %%P in (%protocols%) do (
    if /i "!arg!"=="%%P" (
        set "global_exclude_%%P=true"
        set "found_protocol=1"
    )
)
if "!found_protocol!"=="" (
    echo  Invalid protocol "!arg!" specified after /exclude
    echo  Valid values are : 
    echo    - ip4 = Ping IPv4 
    echo    - ip6 = Ping IPv6
    echo    - tr4 = Traceroute IPv4 
    echo    - tr6 = Traceroute IPv6
    echo    - htp = HTTPS 
    echo    - tls = TLS 1.2
    echo    - dns = DNS lookup
    echo. & echo  Press any key to see Help & pause >nul & goto :help
)
shift
goto :collect_excludes

:handle_debug
shift
if "%~1"=="" (
    set "debug=true"
) else (
    if /i "%~1"=="true"  set "debug=true"    & set "recognized_debug_arg=true"
    if /i "%~1"=="1"     set "debug=true"    & set "recognized_debug_arg=true"
    if /i "%~1"=="false" set "debug=false"   & set "recognized_debug_arg=true"
    if /i "%~1"=="0"     set "debug=false"   & set "recognized_debug_arg=true"
    if not defined recognized_debug_arg (
        echo  Argument not recognized "%~1" specified after /debug
        echo  Valid values are : true, false, 1, 0. 
        echo                     Nothing specified = true --^> debug will be shown at end.
        echo. & echo  Press any key to see Help & pause >nul & goto :help
    )
    shift
)
goto :parse_args

:handle_nopause
shift
if "%~1"=="" (
    set "nopause=true"
) else (
    if /i "%~1"=="true"  set "nopause=true"  & set "recognized_nopause_arg=true"
    if /i "%~1"=="1"     set "nopause=true"  & set "recognized_nopause_arg=true"
    if /i "%~1"=="false" set "nopause=false" & set "recognized_nopause_arg=true"
    if /i "%~1"=="0"     set "nopause=false" & set "recognized_nopause_arg=true"
    if not defined recognized_nopause_arg (
        echo  Argument not recognized "%~1" specified after /nopause
        echo  Valid values are : true, false, 1, 0. 
        echo                     Nothing specified = false --^> script will be paused at end.
        echo. & echo  Press any key to see Help & pause >nul & goto :help
    )
    shift
)
goto :parse_args

:after_args

if not defined sites (
    echo  Please provide one or more websites addresses to test
    echo  Be careful to provide simples addresses, not including special caracters like %%
    echo. & echo  Press any key to see Help & pause >nul & goto :help
)

if not defined debug    set "debug=true"
if "%debug%"=="false"   set "debug="
if defined nopause if "%nopause%"=="false" set "nopause="



:: ______________________________________________________________________________ ::
::                                                                                ::
::                                       MAIN                                     ::
:: ______________________________________________________________________________ ::

if defined global_only_active (
    for %%P in (%protocols%) do (
        if not defined global_only_%%P (
            set "global_exclude_%%P=true"
        ) else (
            set "global_exclude_%%P=false"
        )
    )
)

for %%S in (%sites%) do (
    set "site=%%S"
    call :rename_loop %%S
)


set "ESC="
set "COLOR_RESET=%ESC%[0m"                 REM Reset colors
set "COLOR_TEXT=%ESC%[30m"                 REM Black text
set "COLOR_BORDER=%ESC%[38;5;15m"          REM White
set "COLOR_HEADER_TEXT=%ESC%[38;5;11m"     REM Yellow
set "COLOR_OK=%ESC%[38;5;10m"              REM Green
set "COLOR_KO=%ESC%[38;5;9m"               REM Red
set "COLOR_DASH=%ESC%[38;5;15m"            REM White
set "COLOR_WORKING=%ESC%[93m"              REM Light Yellow
set "COLOR_PROGRESS=%ESC%[42m"             REM Green background
set "COLOR_REMAIN=%ESC%[47m"               REM White background

set "WEIGHT_ip4=3"
set "WEIGHT_ip6=3"
set "WEIGHT_tr4=25"
set "WEIGHT_tr6=25"
set "WEIGHT_tls=2"
set "WEIGHT_htp=1"
set "WEIGHT_dns=1"

set /a total_weighted_tests=0
for %%S in (%sites_clean%) do (
    set "site_clean=%%S"
    set /a site_weighted_tests=0
    for %%P in (%protocols%) do (
        call :ShouldRunTest %%P "!excludes_%%S!" "!includes_%%S!" !site_clean!
        if "!skip_test!"=="false" (
            set "test_weight=!WEIGHT_%%P!"
            set /a site_weighted_tests+=!test_weight!
        )
    )
    set /a total_weighted_tests+=site_weighted_tests
)

set /a tests_completed_weighted=0

for /F "tokens=1-4 delims=:.," %%H in ("%TIME%") do (
    set /A "startTime=%%H*3600+%%I*60+%%J"
)
set "DEBUG_FILES="
for %%S in (%sites_clean%) do (
    for %%P in (%protocols%) do (
        set "cell_%%P_%%S=- "
    )
)

set "total_lines_printed=0"
call :PrintTable



:: ________________________________ START TESTS _________________________________ 

for %%S in (%sites_clean%) do (
    set "site_clean=%%S"
    call :TestSite !site_clean! "!excludes_%%S!" "!includes_%%S!"
)




:: ______________________________________________________________________________ ::
::                                                                                ::
::                                     ENDING                                     ::
:: ______________________________________________________________________________ ::

chcp 65001 >nul

set "DEBUG_FILES="
for %%S in (%sites_clean%) do (
    for %%P in (%protocols%) do (
        if "!cell_%%P_%%S!"=="%COLOR_KO%KO%COLOR_RESET%" if exist "!output_dir!\%%P_debug_%%S.txt" set "DEBUG_FILES=!DEBUG_FILES! %%P_debug_%%S.txt"
    )
)

if defined debug if defined DEBUG_FILES (
    echo.
    echo  %COLOR_KO%+-------------------------------+%COLOR_RESET%
    echo  %COLOR_KO%^|         %COLOR_KO%DEBUG REPORT%COLOR_KO%          ^|%COLOR_RESET%
    echo  %COLOR_KO%+-------------------------------+%COLOR_RESET%
    for %%F in (!DEBUG_FILES!) do (
        echo.
        echo %COLOR_KO%-------- %COLOR_KO%File:%COLOR_RESET% %%F %COLOR_KO%--------%COLOR_RESET%
        type "!output_dir!\%%F"
        echo %COLOR_RESET%
    )
)

set "KO_Protocols="
for %%F in (!DEBUG_FILES!) do (
    for /f "tokens=1 delims=_" %%A in ("%%~nF") do (
        set "protocol=%%A"
        set "protocol_num="
        for %%P in ("ip4=3" "ip6=4" "tr4=5" "tr6=6" "tls=7" "htp=8" "dns=9") do (
            for /f "tokens=1,2 delims==" %%B in (%%P) do if /i "%%A"=="%%B" set "protocol_num=%%C"
        )
        call :AddProtocolNum "!protocol_num!" "!KO_Protocols!" KO_Protocols
    )
)
if defined KO_Protocols (
    echo.
    echo  %COLOR_KO%Some tests failed. Exiting with code: !KO_Protocols!%COLOR_RESET%
    echo.
    if not defined nopause (echo  Press any key to exit... & echo. & pause >nul)
    del "!output_dir!\*_output_*.txt" >nul 2>&1
    del "!output_dir!\*_temp*.txt" >nul 2>&1
    exit /b !KO_Protocols!
) else (
    echo.
    echo  %COLOR_OK%All tests passed successfully.%COLOR_RESET%
    echo.
    if not defined nopause (echo  Press any key to exit... & echo. & pause >nul)
    del "!output_dir!\*_output_*.txt" >nul 2>&1
    del "!output_dir!\*_temp*.txt" >nul 2>&1
    exit /b 0
)





:: ______________________________________________________________________________ ::
::                                                                                ::
::                                  TESTS FUNCTION                                ::
:: ______________________________________________________________________________ ::

:TestSite

set "site=%~1"
set "specific_exclusions=%~2"
set "specific_inclusions=%~3"

for %%S in (%protocols%) do (
    set "specific_exclude_%%S="
    set "specific_include_%%S="
)
for %%S in (%protocols%) do (
    for %%E in (%specific_exclusions%) do if /i "%%E"=="%%S" set "specific_exclude_%%S=true"
    for %%I in (%specific_inclusions%) do if /i "%%I"=="%%S" set "specific_include_%%S=true"
)
call :UpdateProgress
call :PrintTable



:: Test Ping IPv4
set "protocol=ip4"
call :verify_skip %site% %protocol%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
call :UpdateProgress
call :PrintTable
ping -n 4 -4 %site% > "!output_dir!\%protocol%_debug_%site%.txt" 2>&1
echo !errorlevel!> "!output_dir!\%protocol%_output_%site%.txt"
for /f "usebackq tokens=*" %%r in (`type "!output_dir!\%protocol%_output_%site%.txt"`) do set "%protocol%_results_%site%=%%r"
if "!%protocol%_results_%site%!"=="0" (
    set "cell_%protocol%_%site%=%COLOR_OK%OK%COLOR_RESET%"
    del "!output_dir!\%protocol%_debug_%site%.txt" >nul 2>&1
) else (
    set "cell_%protocol%_%site%=%COLOR_KO%KO%COLOR_RESET%"
)
set /a tests_completed_weighted+=!WEIGHT_%protocol%!
call :UpdateProgress
call :PrintTable
:skip_ip4



:: Test Ping IPv6
set "protocol=ip6"
call :verify_skip %site% %protocol%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
call :UpdateProgress
call :PrintTable
ping -n 4 -6 %site% > "!output_dir!\%protocol%_debug_%site%.txt" 2>&1
echo !errorlevel!> "!output_dir!\%protocol%_output_%site%.txt"
for /f "usebackq tokens=*" %%r in (`type "!output_dir!\%protocol%_output_%site%.txt"`) do set "%protocol%_results_%site%=%%r"
if "!%protocol%_results_%site%!"=="0" (
    set "cell_%protocol%_%site%=%COLOR_OK%OK%COLOR_RESET%"
    del "!output_dir!\%protocol%_debug_%site%.txt" >nul 2>&1
) else (
    set "cell_%protocol%_%site%=%COLOR_KO%KO%COLOR_RESET%"
)
set /a tests_completed_weighted+=!WEIGHT_%protocol%!
call :UpdateProgress
call :PrintTable
:skip_ip6



:: Test Tracert IPv4
set "protocol=tr4"
call :verify_skip %site% %protocol%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
call :UpdateProgress
call :PrintTable
tracert -h 5 -4 %site% > "!output_dir!\%protocol%_debug_%site%.txt" 2>&1
call :CountTracertHops "!output_dir!\%protocol%_debug_%site%.txt" %protocol% %site%
echo !count! > "!output_dir!\%protocol%_output_%site%.txt"
if !count! GEQ 2 (
    set "cell_%protocol%_%site%=%COLOR_OK%OK%COLOR_RESET%"
    del "!output_dir!\%protocol%_debug_%site%.txt" >nul 2>&1
) else (
    set "cell_%protocol%_%site%=%COLOR_KO%KO%COLOR_RESET%"
)
set /a tests_completed_weighted+=!WEIGHT_%protocol%!
call :UpdateProgress
call :PrintTable
:skip_tr4



:: Test Tracert IPv6
set "protocol=tr6"
call :verify_skip %site% %protocol%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
call :UpdateProgress
call :PrintTable
tracert -h 5 -6 %site% > "!output_dir!\%protocol%_debug_%site%.txt" 2>&1
call :CountTracertHops "!output_dir!\%protocol%_debug_%site%.txt" %protocol% %site%
echo !count! > "!output_dir!\%protocol%_output_%site%.txt"
if !count! GEQ 2 (
    set "cell_%protocol%_%site%=%COLOR_OK%OK%COLOR_RESET%"
    del "!output_dir!\%protocol%_debug_%site%.txt" >nul 2>&1
) else (
    set "cell_%protocol%_%site%=%COLOR_KO%KO%COLOR_RESET%"
)
set /a tests_completed_weighted+=!WEIGHT_%protocol%!
call :UpdateProgress
call :PrintTable
:skip_tr6



:: Test TLS Handshake
set "protocol=tls"
call :verify_skip %site% %protocol%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
call :UpdateProgress
call :PrintTable
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"try { ^
    if ('%site%' -match '^https?://') {$site = '%site%' -replace '^https?://', ''} ^
    else {$site = '%site%'}; ^
    $tcpClient = New-Object System.Net.Sockets.TcpClient; ^
    $tcpClient.Connect($site, 443); ^
    $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false); ^
    $sslStream.AuthenticateAsClient($site, $null, [System.Security.Authentication.SslProtocols]::Tls12, $false); ^
    if ($sslStream.IsAuthenticated) { '1' ^| Out-File -FilePath '!output_dir!\%protocol%_output_%site%.txt' } ^
} catch { ^
    $_ ^| Out-File -FilePath '!output_dir!\%protocol%_debug_%site%.txt'; ^
    '0' ^| Out-File -FilePath '!output_dir!\%protocol%_output_%site%.txt'; ^
} finally { ^
    if ($sslStream) { $sslStream.Dispose() }; ^
    if ($tcpClient) { $tcpClient.Dispose() }; ^
}"
for /f "usebackq tokens=*" %%r in (`type "!output_dir!\%protocol%_output_%site%.txt"`) do set "%protocol%_results_%site%=%%r"
if "!%protocol%_results_%site%!"=="1" (
    set "cell_%protocol%_%site%=%COLOR_OK%OK%COLOR_RESET%"
    del "!output_dir!\%protocol%_debug_%site%.txt" >nul 2>&1
) else (
    set "cell_%protocol%_%site%=%COLOR_KO%KO%COLOR_RESET%"
)
set /a tests_completed_weighted+=!WEIGHT_%protocol%!
call :UpdateProgress
call :PrintTable
:skip_tls



:: Test HTTPS
set "protocol=htp"
call :verify_skip %site% %protocol%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
call :UpdateProgress
call :PrintTable
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"try { ^
    if ('%site%' -notmatch '^https?://') {$site = 'https://%site%'} ^
    elseif ('%site%' -match '^http://') {$site = '%site%' -replace '^http://', 'https://'} ^
    else {$site = '%site%'}; ^
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ^
    $response = Invoke-WebRequest -Uri $site -UseBasicParsing -TimeoutSec 5; ^
    if ($response.StatusCode -eq 200) { '1' ^| Out-File -FilePath '!output_dir!\%protocol%_output_%site%.txt' } ^
    else { '0' ^| Out-File -FilePath '!output_dir!\%protocol%_output_%site%.txt' }; ^
} catch { ^
    $_ ^| Out-File -FilePath '!output_dir!\%protocol%_debug_%site%.txt'; ^
    '0' ^| Out-File -FilePath '!output_dir!\%protocol%_output_%site%.txt'; ^
}"
for /f "usebackq tokens=*" %%r in (`type "!output_dir!\%protocol%_output_%site%.txt"`) do set "%protocol%_results_%site%=%%r"
if "!%protocol%_results_%site%!"=="1" (
    set "cell_%protocol%_%site%=%COLOR_OK%OK%COLOR_RESET%"
    del "!output_dir!\%protocol%_debug_%site%.txt" >nul 2>&1
) else (
    set "cell_%protocol%_%site%=%COLOR_KO%KO%COLOR_RESET%"
)
set /a tests_completed_weighted+=!WEIGHT_%protocol%!
call :UpdateProgress
call :PrintTable
:skip_htp



:: Test DNS
set "protocol=dns"
call :verify_skip %site% %protocol%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
call :UpdateProgress
call :PrintTable
nslookup -type=AAAA %site% > "!output_dir!\%protocol%_debug_%site%.txt" 2>&1
set "firstLine=" & set "lastLine="
for /f "tokens=* delims=" %%L in (!output_dir!\%protocol%_debug_%site%.txt) do (
    if not defined firstLine (set "firstLine=%%L") else (set "lastLine=%%L")
)
echo %firstLine% %lastLine% | findstr /c:"Timed out" /c:"No response from server" /c:"No records" /c:"Non-existent domain" ^
    /c:"Connection refused" /c:"Network is unreachable" /c:"Server failure" /c:"Refused" /c:"Format error" >nul
if errorlevel 1 (
    echo 1 > "!output_dir!\%protocol%_output_%site%.txt"
    set "dns_results_%site%=1"
    set "cell_%protocol%_%site%=%COLOR_OK%OK%COLOR_RESET%"
    del "!output_dir!\%protocol%_debug_%site%.txt" >nul 2>&1
) else (
    echo 0 > "!output_dir!\%protocol%_output_%site%.txt"
    set "dns_results_%site%=0"
    set "cell_%protocol%_%site%=%COLOR_KO%KO%COLOR_RESET%"
)
set /a tests_completed_weighted+=!WEIGHT_%protocol%!
call :UpdateProgress
call :PrintTable
:skip_dns

goto :eof



:: ______________________________________________________________________________ ::
::                                                                                ::
::                                 OTHER FUNCTIONS                                ::
:: ______________________________________________________________________________ ::

:PrintTable
if defined total_lines_printed (
    for /L %%i in (1,1,!total_lines_printed!) do (
        <nul set /p "=%ESC%[1A%ESC%[2K"
    )
)
set "lines_printed=0"
echo !header_line!
set /a lines_printed+=1
echo %COLOR_BORDER% +----------------------------------------------------------------------------+%COLOR_RESET%
set /a lines_printed+=1
echo  ^|%COLOR_HEADER_TEXT% Site               ^| Ping4 ^| Ping6 ^| Trac4 ^| Trac6 ^| TLS   ^| HTTPS ^| DNS   %COLOR_RESET%^|
set /a lines_printed+=1
echo %COLOR_BORDER% +----------------------------------------------------------------------------+%COLOR_RESET%
set /a lines_printed+=1
for %%S in (%sites_clean%) do (
    set "site_name=%%S"
    if "!site_name:~18,1!" NEQ "" (
        set "site_display= !site_name:~0,15!... "
    ) else (
        set "site_display= !site_name! "
        set "len=0"
        for /L %%i in (0,1,18) do (
            if "!site_name:~%%i,1!" NEQ "" set /a "len+=1"
        )
        set /a "spaces_needed=18-len"
        for /L %%i in (1,1,!spaces_needed!) do (
            set "site_display=!site_display! "
        )
    )
    set "output= |%COLOR_RESET%!site_display!|"
    for %%P in (%protocols%) do (
        set "cell=!cell_%%P_%%S!"
        set "output=!output! !cell!    ^|"
    )
    echo !output!
    set /a lines_printed+=1
)
echo %COLOR_BORDER% +----------------------------------------------------------------------------+%COLOR_RESET%
set /a lines_printed+=1
set "total_lines_printed=!lines_printed!"
goto :eof



:verify_skip
set "site=%~1"
set "protocol=%~2"
set "skip_test=false"
if defined specific_include_%protocol% (
    set "skip_test=false"
) else (
    if defined global_only_%protocol% (
        set "skip_test=false"
    ) else (
        if defined specific_exclude_%protocol% (
            set "skip_test=true"
        ) else (
            if defined global_exclude_%protocol% (
                set "skip_test=true"
            )
        )
    )
)
goto :eof



:ShouldRunTest
set "test=%~1"
set "skip_test=false"
set "site=%~4"
set "specific_exclusions=%~2"
set "specific_inclusions=%~3"
for %%E in (%specific_exclusions%) do (
    if %%E==!test! set "!site!_exclude_!test!=true"
)
for %%I in (%specific_inclusions%) do (
    if %%I==!test! set "!site!_include_!test!=true"
)
if defined !site!_include_!test! (
    set "skip_test=false"
) else if defined global_only_!test! (
    set "skip_test=false"
) else (
    if defined !site!_exclude_!test! (
        set "skip_test=true"
    ) else if defined global_exclude_!test! (
        set "skip_test=true"
    )
)
goto :eof



:rename_loop
set "checkTripleDash=!site:~-6,3!"
set "foundmarker="
if "!checkTripleDash!"=="+++" set "foundmarker=+"
if "!checkTripleDash!"=="---" set "foundmarker=-"
if defined foundmarker (
    set "protocol=!site:~-3,3!"
    set "site=!site:~0,-6!"
    if "%foundmarker%"=="-" (
        if defined excludes_%~1 (
            set "excludes_%~1=!excludes_%~1!;!protocol!"
        ) else (
            set "excludes_%~1=!protocol!"
        )
    ) else if "%foundmarker%"=="+" (
        if defined includes_%~1 (
            set "includes_%~1=!includes_%~1!;!protocol!"
        ) else (
            set "includes_%~1=!protocol!"
        )
    )
    goto rename_loop
) else (
    set "site_clean=!site:*://=!"
    for /F "delims=/" %%A in ("!site_clean!") do set "site_clean=%%A"
    if defined sites_clean (
        set "sites_clean=!sites_clean!;!site_clean!"
    ) else (
        set "sites_clean=!site_clean!"
    )
    if defined excludes_%~1 set "excludes_!site_clean!=!excludes_%~1!"
    if defined includes_%~1 set "includes_!site_clean!=!includes_%~1!"
    
    goto :eof
)



:CountTracertHops
setlocal enabledelayedexpansion
set count=0
findstr /r /v "^$" "%~1" > "!output_dir!\%~2_%~3_temp1.txt"
more +2 "!output_dir!\%~2_%~3_temp1.txt" > "!output_dir!\%~2_%~3_temp2.txt"
findstr /v /c:"Trace complete." "!output_dir!\%~2_%~3_temp2.txt" > "!output_dir!\%~2_%~3_temp3.txt"
for /f "usebackq tokens=* delims=" %%a in ("!output_dir!\%~2_%~3_temp3.txt") do (
    set "line=%%a"
    for %%b in (!line!) do set "word=%%b"
    set "ip=!word:*[=!"
    set "ip=!ip:]=!"
    if "!ip!"=="!word!" (set "addr=!word!") else set "addr=!ip!"
    echo !addr! | findstr /r "[0-9]" >nul
    if not errorlevel 1 (
        call :CountChar "!addr!" "." dots
        call :CountChar "!addr!" ":" colons
        if !dots! geq 2 (set /a count+=1) else if !colons! geq 2 set /a count+=1
    )
)
endlocal & set "count=%count%"
goto :eof



:CountChar
setlocal
set "string=%~1"
set "char=%~2"
set "total=0"
set "index=0"
:countloop
if "!string:~%index%,1!"=="" goto endcount
if "!string:~%index%,1!"=="%char%" set /a total+=1
set /a index+=1
goto countloop
:endcount
endlocal & set "%3=%total%"
goto :eof



:UpdateProgress
setlocal enabledelayedexpansion
if %tests_completed_weighted% GTR 0 (
    set /a "percent=(tests_completed_weighted*100)/total_weighted_tests"
    if !percent! GTR 100 set "percent=100"
) else (
    set "percent=0"
)
set /a "progress_chars=(percent*76)/100"
for /F "tokens=1-4 delims=:.," %%H in ("%TIME%") do (
    set /A "currentTime=%%H*3600+%%I*60+%%J"
)
set /A "elapsedTime=currentTime - startTime"
if !elapsedTime! LSS 0 set /A elapsedTime+=86400
if !elapsedTime! LSS 1 set /A elapsedTime=1
if not defined initialEstimatedTotalTime (
    set "initialEstimatedTotalTime=%total_weighted_tests%"
)
if %tests_completed_weighted% GTR 0 (
    set /A "estimatedTotalTimeFromProgress = (elapsedTime * total_weighted_tests) / tests_completed_weighted"
    set /A "alpha = ((total_weighted_tests - tests_completed_weighted) * 100) / total_weighted_tests"
    if !alpha! LSS 0 set "alpha=0"
    if !alpha! GTR 100 set "alpha=100"
    set /A "estimatedTotalTime = (alpha * initialEstimatedTotalTime + (100 - alpha) * estimatedTotalTimeFromProgress) / 100"
    set /A "remainingTime = estimatedTotalTime - elapsedTime"
    if !remainingTime! LSS 0 set "remainingTime=0"
) else (
    set /A "remainingTime = initialEstimatedTotalTime - elapsedTime"
    if !remainingTime! LSS 0 set "remainingTime=0"
)
call :FormatTime !elapsedTime! elapsedTimeStr
call :FormatTime !remainingTime! remainingTimeStr
set "total_header_length=76"
set "text=INTERNET TEST by Freenitial"
set "text_length=27"
set /a "text_start_pos=(total_header_length - text_length)/2"
set /a "text_end_pos=text_start_pos + text_length -1"
set "elapsedTimeText=Elapsed: !elapsedTimeStr!"
set "remainingTimeText=Remain: !remainingTimeStr!"
set "elapsedTime_length=14"
set "remainingTime_length=13"
set /a "elapsedTime_start_pos=2"
set /a "elapsedTime_end_pos=elapsedTime_start_pos + elapsedTime_length -1"
set /a "remainingTime_start_pos=total_header_length - remainingTime_length"
set /a "remainingTime_end_pos=remainingTime_start_pos + remainingTime_length -1"
set "header_line="
for /L %%p in (1,1,%total_header_length%) do (
    if %%p LEQ !progress_chars! (
        set "char_color=!COLOR_TEXT!!COLOR_PROGRESS!"
    ) else (
        set "char_color=!COLOR_TEXT!!COLOR_REMAIN!"
    )
    set "char= "
    if %%p GEQ !elapsedTime_start_pos! if %%p LEQ !elapsedTime_end_pos! (
        set /a "char_pos=%%p - elapsedTime_start_pos"
        call :GetChar "!elapsedTimeText!" !char_pos! char
    ) else if %%p GEQ !text_start_pos! if %%p LEQ !text_end_pos! (
        set /a "char_pos=%%p - text_start_pos"
        call :GetChar "!text!" !char_pos! char
    ) else if %%p GEQ !remainingTime_start_pos! if %%p LEQ !remainingTime_end_pos! (
        set /a "char_pos=%%p - remainingTime_start_pos"
        call :GetChar "!remainingTimeText!" !char_pos! char
    )
    set "header_line=!header_line!!char_color!!char!"
)
set "header_line=%COLOR_RESET% [!header_line!%COLOR_RESET%]"
endlocal & set "header_line=%header_line%"
goto :eof



:GetChar
setlocal EnableDelayedExpansion
set "str=%~1"
set /a pos=%~2
set "char= "
if not "!str:~%pos%,1!"=="" (
    set "char=!str:~%pos%,1!"
)
endlocal & set "%~3=%char%"
goto :eof



:FormatTime
setlocal
set /A "minutes=%~1 / 60"
set /A "seconds=%~1 %% 60"
if %minutes% LSS 10 set "minutes=0%minutes%"
if %seconds% LSS 10 set "seconds=0%seconds%"
endlocal & set "%~2=%minutes%:%seconds%"
goto :eof



:AddProtocolNum
REM %1 = Protocol Number to Add
REM %2 = Current KO_Protocols
REM %3 = Variable to Set (KO_Protocols)
set "new_num=%~1"
set "current=%~2"
REM Check if the number is already in the current list
echo %current% | findstr /c:"%new_num%" >nul
if errorlevel 1 (
    if defined current (
        set "updated=%current%%new_num%"
    ) else (
        set "updated=%new_num%"
    )
) else (
    set "updated=%current%"
)
set "%~3=%updated%"
goto :eof




:help
echo.
echo.
echo    =============================================================================
echo                              Network Protocol Tester v1.0
echo                                        --- 
echo                        Test Multiple Network Protocols Easily
echo                                   ------------
echo                           Author : Freenitial on GitHub
echo    =============================================================================
echo.
echo.
echo    DESCRIPTION:
echo       -----------
echo       Tests multiple network protocols and services for given websites. Provides
echo       visual feedback and detailed results for connectivity testing.
echo.
echo       You need to specify 1+ website to test, at begin of the script, or by using arguments
echo       Be careful to provide simples addresses, not including special caracters like '%%'
echo.
echo.
echo    PROTOCOLS:
echo       -----------
echo       Every protocols supported
echo       -----------
echo       ip4          Ping IPv4
echo       ip6          Ping IPv6
echo       tr4          Traceroute IPv4 - Success = ^>=2 adresses found / 5 hops
echo       tr6          Traceroute IPv6 - Success = ^>=2 adresses found / 5 hops
echo       tls          TLS 1.2 handshake
echo       htp          HTTPS connectivity
echo       dns          DNS resolution by nslookup
echo.
echo.
echo    ARGUMENTS:
echo       -----------
echo       Notice that 'site' is required. You can pre-fill variable 'sites' at the top of this file.
echo       -----------
echo       /site        domain[+++/---protocol]            Specify target websites [optionnal filter]        
echo       /only        ip4/ip6/tr4/tr6/tls/htp/dns        Test only specified protocols    
echo       /exclude     ip4/ip6/tr4/tr6/tls/htp/dns        Exclude specified protocols      
echo       /debug       true/false - default true          Show infos for KO tests at end
echo       /nopause     true/false - default false         Do not pause script at end
echo.
echo.
echo    RETURN CODES:
echo       -----------
echo       Notice that failed test return codes will be combined. Fail IPv4 and TLS will result code 37
echo       -----------
echo       1            Unexpected error
echo       2            Argument not recognized
echo       3            ^>=1 site test Failed IPv4
echo       4            ^>=1 site test Failed IPv6
echo       5            ^>=1 site test Failed Traceroute IPv4 = ^<2 adresses found / 5 hops
echo       6            ^>=1 site test Failed Traceroute IPv6 = ^<2 adresses found / 5 hops
echo       7            ^>=1 site test Failed TLS
echo       8            ^>=1 site test Failed HTTPS
echo       9            ^>=1 site test Failed DNS
echo       11           Failed to create output directory: '!output_dir!'
echo.
echo.
echo    OUTPUT:
echo       -----------
echo       Description of table symbols
echo       -----------
echo       * /    : Test in progress
echo       * ^>    : Test skipped
echo       * OK   : Test passed successfully
echo       * KO   : Test failed
echo.   
echo                    ____________________________________________________
echo.
echo.   ~~~~~~~~~~~~~
echo      EXAMPLES:
echo.   ~~~~~~~~~~~~~
echo. 
echo       Basic usage:
echo       -----------
echo       %~n0.bat /site google.com microsoft.com yahoo.com
echo       - Tests all protocols for both sites
echo.   
echo. 
echo       Test Only specified protocols - Global :
echo       -----------
echo       %~n0.bat /site google.com /only ip4 ip6
echo       - Tests only IPv4 and IPv6 protocols
echo         Notice that '/only' and '/exclude' are exclusive arguments. Do not mix them.
echo.
echo. 
echo       Exclude specified protocols - Global :
echo       -----------
echo       %~n0.bat /site google.com /exclude ip4 ip6
echo      - Test everything except IPv4 and IPv6 protocols
echo        Notice that '/only' and '/exclude' are exclusive arguments. Do not mix them.
echo.   
echo. 
echo       Include specified protocols - Site Specific :
echo       -----------
echo       %~n0.bat /site google.com+++ip4+++ip6 microsoft.com yahoo.com /exclude ip4 ip6
echo       - Exclude IPv4 and IPv6 for microsoft.com and yahoo.com
echo         IPv4 and IPv6 still be tested for google because of '+++ip4+++ip6'
echo         Notice that specific rules have piority on global rules
echo         '+++' will NOT test ONLY specified protocols - different from '/only'. 
echo         '+++' is designed to override a global exclusion
echo.
echo. 
echo       Exclude specified protocols - Site Specific :
echo       -----------
echo       %~n0.bat /site google.com---ip4+++dns microsoft.com yahoo.com /only ip4 ip6
echo       - Test only IPv4 and IPv6 for microsoft.com and yahoo.com
echo         Test IPv6 and DNS for google.com because of '---ip4+++dns'
echo         Notice that specific rules have piority on global rules
echo         '---' work the same as global exclude, for a specified site
echo.
echo. 
echo       Disable debug showing at end, and disable pause at end :
echo       -----------
echo       %~n0.bat /site google.com /debug false /nopause true
echo.   
echo.   
echo    =============================================================================
echo.
pause & exit /b 2
