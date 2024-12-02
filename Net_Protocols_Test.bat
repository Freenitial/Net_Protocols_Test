@echo off
chcp 65001 >nul
cd /d "%~dp0"
setlocal enabledelayedexpansion
set "dp0=%~dp0" & set "n0=%~n0"

::  Do not modify this list
set protocols=ip4 ip6 tr4 tr6 tls htp dns
::  Ping IPv4, Ping IPv6, Traceroute IPv4, Traceroute IPv6, TLS 1.2, HTTPS, DNS lookup

:: ______________________________________________________________________________ ::
::                                                                                ::
::                                 MANUAL SETTINGS                                ::
::                                                                                ::
::                  Use "Net_Protocols_Test.bat /help" to see tutorial            ::
:: ______________________________________________________________________________ ::


REM Use "Net_Protocols_Test.bat /help" to see tutorial
REM Calling this script with arguments will override corresponding settings

set "sites="
::  "sites=google.com microsoft.com yahoo.com"
::   Net_Protocols_Test.bat /site google.com microsoft.com yahoo.com

set "test_only_protocols="
::  "test_only_protocols=ip4 ip6"
::   Net_Protocols_Test.bat /only ip4 ip6 /site google.com

set "test_exclude_protocols="
::  "test_exclude_protocols=tr4 tr6"
::   Net_Protocols_Test.bat /exclude tr4 tr6 /site google.com

set "nodebug=false"
::   Do not show logs for KO results at end
::   Net_Protocols_Test.bat /nodebug /site google.com

set "nopause=false"
::   Do not pause at end
::   Net_Protocols_Test.bat /nopause /site google.com

set "output_dir="
::   Default : Path\To\Script\Net_Protocols_Test


:: ______________________________________________________________________________ ::
::                                                                                ::
::                               ARGUMENTS HANDLING                               ::
:: ______________________________________________________________________________ ::

if "%nopause%"=="false"   set "nopause="
if "%nopause%"=="0"       set "nopause="

set "global_only_active="
if defined test_only_protocols (
    for %%O in (%test_only_protocols%) do (
        set "global_only_%%O=true"
        set "global_only_active=true"
    )
)
if defined test_exclude_protocols (
    for %%E in (%test_exclude_protocols%) do (
        set "global_exclude_%%E=true"
    )
)

if /i "%~1"=="/?"       goto :help
if /i "%~1"=="-?"       goto :help
if /i "%~1"=="--?"      goto :help
if /i "%~1"=="/help"    goto :help
if /i "%~1"=="-help"    goto :help
if /i "%~1"=="--help"   goto :help

call :check_nopause %*
if "%ARGS%"=="" goto :after_args
call :parse_args %ARGS%
if defined error_arg (
    if defined arg_not_recognized (
        echo  Argument not recognized : "%arg_not_recognized%"
    )
    if defined protocol_error (
        if defined only_arg_error    echo  Invalid protocol "!arg!" specified after /only
        if defined exclude_arg_error echo  Invalid protocol "!arg!" specified after /exclude
        echo  Valid values are : 
        echo    - ip4 = Ping IPv4 
        echo    - ip6 = Ping IPv6
        echo    - tr4 = Traceroute IPv4 
        echo    - tr6 = Traceroute IPv6
        echo    - htp = HTTPS 
        echo    - tls = TLS 1.2
        echo    - dns = DNS lookup
    )
    if defined nodebug_error (
        echo  Argument not recognized "%arg_not_recognized%" specified after /nodebug
        echo  Valid values are : true, false, 1, 0. 
        echo                     Nothing specified = true --^> debug will not be shown at end.
    )
    if not defined nopause (echo  Press a key to see Help & pause >nul & goto :help) else (exit /b 2)
)
goto :after_args

:check_nopause
set "all_args=%*"
set "extract_next="
for %%A in (%all_args%) do (
    set "current_arg=%%A"
    if "%%A"=="/nopause" (
        set "nopause=true"
        set "extract_next=true"
    ) else (
        if  defined extract_next (
            if      "%%A"=="true"             (set "nopause=true") ^
            else if "%%A"=="false"            (set "nopause="    ) ^
            else if "%%A"=="1"                (set "nopause=true") ^
            else if "%%A"=="0"                (set "nopause="    ) ^
            else if "!current_arg:~0,1!"=="/" (set "nopause=true" & set "args_remaining=!args_remaining! %%A") ^
            else                              (set "nopause=true")
            set "extract_next=" & set "extracted=true"
        )
        if not defined extracted set "args_remaining=!args_remaining! %%A"
        set "extracted="
    )
)
if defined args_remaining set "ARGS=!args_remaining:~1!"
goto :eof

:parse_args
if defined error_arg    goto :eof
if    "%~1"==""         goto :eof
if /i "%~1"=="/site"    goto :handle_site
if /i "%~1"=="/only"    goto :handle_only
if /i "%~1"=="/exclude" goto :handle_exclude
if /i "%~1"=="/nodebug" goto :handle_nodebug
if /i "%~1"=="/output"  goto :handle_output
set "error_arg=true"
set "arg_not_recognized=%~1" & goto :eof

:handle_output
shift
if  "%~1"==""          (set "error_arg=true" & set "output_missing_error=true" & goto :eof)
set "arg1=%~1"
if  "!arg1:~0,1!"=="/" (set "error_arg=true" & set "output_invalid_error=true" & goto :eof)
set "output_dir=%~1"
shift
goto :parse_args

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
for %%P in (%protocols%) do set "global_only_%%P="
set "global_only_active="
:collect_test_only_protocols
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
if "!found_protocol!"=="" (set "error_arg=true" & set "protocol_error=true" & set "only_arg_error=true" & goto :eof)
shift
goto :collect_test_only_protocols

:handle_exclude
shift
for %%P in (%protocols%) do set "global_exclude_%%P="
:collect_test_exclude_protocols
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
if "!found_protocol!"=="" (set "error_arg=true" & set "protocol_error=true" & set "exclude_arg_error=true" & goto :eof)
shift
goto :collect_test_exclude_protocols

:handle_nodebug
shift
set "nodebug=true"
set "arg1=%~1"
if not defined arg1 goto :parse_args
if "!arg1:~0,1!"=="/" goto :parse_args
set "arg=%~1"
if /i "%~1"=="true"  set "nodebug=true"    & set "recognized_nodebug_arg=true"
if /i "%~1"=="1"     set "nodebug=true"    & set "recognized_nodebug_arg=true"
if /i "%~1"=="false" set "nodebug=false"   & set "recognized_nodebug_arg=true"
if /i "%~1"=="0"     set "nodebug=false"   & set "recognized_nodebug_arg=true"
if not defined recognized_nodebug_arg (set "error_arg=true" & set "nodebug_error=true" & goto :eof)
shift
goto :parse_args

goto :eof


:after_args

if not defined sites (
    echo  Please provide one or more websites addresses to test
    echo  Be careful to provide simples addresses, not including special caracters like %%
    echo.
    if not defined nopause (echo  Press a key to see Help & pause>nul & goto :help) else (exit /b 2)
)

if not defined nodebug    set "nodebug=false"
if "%nodebug%"=="false"   set "nodebug="
if "%nodebug%"=="0"       set "nodebug="
if "%nopause%"=="false"   set "nopause="
if "%nopause%"=="0"       set "nopause="

if not defined output_dir (set "output_dir=!dp0!Net_Protocols_Test") else set "output_dir=!output_dir!\Net_Protocols_Test"
mkdir "!output_dir!" 2>nul
set "tempfile=!output_dir!\test_write.tmp"
echo Write Test > "!tempfile!" 2>nul
if exist "!tempfile!" (
    del /f "!tempfile!" >nul 2>&1
) else (
    echo  Failed to create output directory: "!output_dir!"
    echo  Verify your permissions
    echo.
    if not defined nopause (echo  Press a key to see Help & pause>nul & call :help & exit /b 11) else (exit /b 11)
)


:: ______________________________________________________________________________ ::
::                                                                                ::
::                                       MAIN                                     ::
:: ______________________________________________________________________________ ::

del "!output_dir!\*_debug_*.txt" >nul 2>&1

if defined global_only_active (
    for %%P in (%protocols%) do (
        if not defined global_only_%%P (set "global_exclude_%%P=true") ^
        else (set "global_exclude_%%P=false")
    )
)

for %%S in (%sites%) do (
    set "site=%%S"
    call :clean_domain %%S
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
        call :ShouldRunTest %%P "!test_exclude_protocols_%%S!" "!test_only_protocols_%%S!" !site_clean!
        if "!skip_test!"=="false" (
            set "test_weight=!WEIGHT_%%P!"
            set /a site_weighted_tests+=!test_weight!
        )
    )
    set /a total_weighted_tests+=site_weighted_tests
)

set /a tests_completed_weighted=0

set "clean_time=%TIME: =%"
for /F "tokens=1-4 delims=:.," %%H in ("%clean_time%") do (
    set "hh=%%H" & set "mm=%%I" & set "ss=%%J"
    if "!hh:~0,1!"==" " set "hh=!hh:~1!"
    if "!hh!"=="" set "hh=0"
    if "!mm!"=="" set "mm=0"
    if "!ss!"=="" set "ss=0"
    set /A "startTime=(1!hh!-100)*3600 + (1!mm!-100)*60 + (1!ss!-100)"
)

set "DEBUG_FILES="
for %%S in (%sites_clean%) do (
    for %%P in (%protocols%) do (
        set "cell_%%P_%%S=- "
    )
)

set "total_lines_printed=0"
echo.
call :UpdateProgress
call :PrintTable



:: ________________________________ START TESTS _________________________________ 

for %%S in (%sites_clean%) do (
    set "site_clean=%%S"
    call :TestSite !site_clean! "!test_exclude_protocols_%%S!" "!test_only_protocols_%%S!"
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

if not defined nodebug if defined DEBUG_FILES (
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
    set "error_msg="
    for %%P in ("3=ipv4" "4=ip6" "5=tr4" "6=tr6" "7=tls" "8=htp" "9=dns") do (
        for /f "tokens=1,2 delims==" %%B in (%%P) do (
            echo !KO_Protocols! | findstr /c:"%%B" >nul && (
                if defined error_msg (set "error_msg=!error_msg!, ") 
                set "error_msg=!error_msg!%%B=%%C"
            )
        )
    )
    echo  %COLOR_KO%Some tests failed. Exiting with code: !KO_Protocols! ^(!error_msg!^)%COLOR_RESET%
    echo.
    if not defined nopause (echo  Press any key to exit... & pause >nul)
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

call :UpdateProgress
call :PrintTable


:: Test Ping IPv4
set "protocol=ip4"
call :ShouldRunTest %protocol% "%specific_exclusions%" "%specific_inclusions%" %site%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
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
:skip_ip4
call :UpdateProgress
call :PrintTable



:: Test Ping IPv6
set "protocol=ip6"
call :ShouldRunTest %protocol% "%specific_exclusions%" "%specific_inclusions%" %site%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
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
:skip_ip6
call :UpdateProgress
call :PrintTable



:: Test Tracert IPv4
set "protocol=tr4"
call :ShouldRunTest %protocol% "%specific_exclusions%" "%specific_inclusions%" %site%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
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
:skip_tr4
call :UpdateProgress
call :PrintTable



:: Test Tracert IPv6
set "protocol=tr6"
call :ShouldRunTest %protocol% "%specific_exclusions%" "%specific_inclusions%" %site%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
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
:skip_tr6
call :UpdateProgress
call :PrintTable



:: Test TLS Handshake
set "protocol=tls"
call :ShouldRunTest %protocol% "%specific_exclusions%" "%specific_inclusions%" %site%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
call :PrintTable
chcp 437 >nul
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
chcp 65001 >nul
for /f "usebackq tokens=*" %%r in (`type "!output_dir!\%protocol%_output_%site%.txt"`) do set "%protocol%_results_%site%=%%r"
if "!%protocol%_results_%site%!"=="1" (
    set "cell_%protocol%_%site%=%COLOR_OK%OK%COLOR_RESET%"
    del "!output_dir!\%protocol%_debug_%site%.txt" >nul 2>&1
) else (
    set "cell_%protocol%_%site%=%COLOR_KO%KO%COLOR_RESET%"
)
set /a tests_completed_weighted+=!WEIGHT_%protocol%!
:skip_tls
call :UpdateProgress
call :PrintTable



:: Test HTTPS
set "protocol=htp"
call :ShouldRunTest %protocol% "%specific_exclusions%" "%specific_inclusions%" %site%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
call :PrintTable
chcp 437 >nul
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
chcp 65001 >nul
for /f "usebackq tokens=*" %%r in (`type "!output_dir!\%protocol%_output_%site%.txt"`) do set "%protocol%_results_%site%=%%r"
if "!%protocol%_results_%site%!"=="1" (
    set "cell_%protocol%_%site%=%COLOR_OK%OK%COLOR_RESET%"
    del "!output_dir!\%protocol%_debug_%site%.txt" >nul 2>&1
) else (
    set "cell_%protocol%_%site%=%COLOR_KO%KO%COLOR_RESET%"
)
set /a tests_completed_weighted+=!WEIGHT_%protocol%!
:skip_htp
call :UpdateProgress
call :PrintTable



:: Test DNS
set "protocol=dns"
call :ShouldRunTest %protocol% "%specific_exclusions%" "%specific_inclusions%" %site%
if "!skip_test!"=="true" (
    set "cell_%protocol%_%site%=%COLOR_DASH%> " 
    goto :skip_%protocol%
)
set "cell_%protocol%_%site%=%COLOR_WORKING%/ %COLOR_RESET%"
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
:skip_dns
call :UpdateProgress
call :PrintTable


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



:ShouldRunTest
set "skip_test=false"
set "protocol=%~1" & set "site=%~4"
set "specific_exclusions=%~2" & set "specific_inclusions=%~3"
for %%E in (%specific_exclusions%) do (if %%E==%protocol% set "%site%_exclude_%protocol%=true")
for %%I in (%specific_inclusions%) do (if %%I==%protocol% set "%site%_include_%protocol%=true")
if      defined %site%_include_%protocol% (set "skip_test=false") ^
else if defined %site%_exclude_%protocol% (set "skip_test=true" ) ^
else if defined global_only_%protocol%    (set "skip_test=false") ^
else if defined global_exclude_%protocol% (set "skip_test=true" )
goto :eof



:clean_domain
set "checkTripleDash=!site:~-6,3!" & set "foundmarker="
if "!checkTripleDash!"=="+++" set "foundmarker=+"
if "!checkTripleDash!"=="---" set "foundmarker=-"
if defined foundmarker (
    set "protocol=!site:~-3,3!"
    set "site=!site:~0,-6!"
    if "%foundmarker%"=="-" (
        if defined test_exclude_protocols_%~1 (set "test_exclude_protocols_%~1=!test_exclude_protocols_%~1!;!protocol!") ^
        else (set "test_exclude_protocols_%~1=!protocol!")
    ) else if "%foundmarker%"=="+" (
        if defined test_only_protocols_%~1 (set "test_only_protocols_%~1=!test_only_protocols_%~1!;!protocol!") ^
        else (set "test_only_protocols_%~1=!protocol!")
    )
    goto :clean_domain
) else (
    set "site_clean=!site:*://=!"
    for /F "delims=/" %%A in ("!site_clean!") do set "site_clean=%%A"
    if defined sites_clean (set "sites_clean=!sites_clean!;!site_clean!") ^
    else (set "sites_clean=!site_clean!")
    if defined test_exclude_protocols_%~1 set "test_exclude_protocols_!site_clean!=!test_exclude_protocols_%~1!"
    if defined test_only_protocols_%~1 set "test_only_protocols_!site_clean!=!test_only_protocols_%~1!"
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
    set /a "percent=tests_completed_weighted*100/total_weighted_tests"
    if !percent! GTR 100 set "percent=100"
) else set "percent=0"
set /a "progress_chars=percent*76/100"
set "clean_time=%TIME: =%"
for /F "tokens=1-4 delims=:.," %%H in ("%clean_time%") do (
    set "hh=%%H" & set "mm=%%I" & set "ss=%%J"
    if "!hh:~0,1!"==" " set "hh=!hh:~1!"
    if "!hh!"=="" set "hh=0"
    if "!mm!"=="" set "mm=0" 
    if "!ss!"=="" set "ss=0"
    set /A "currentTime=(1!hh!-100)*3600 + (1!mm!-100)*60 + (1!ss!-100)"
)
set /A "elapsedTime=currentTime-startTime"
if !elapsedTime! LSS 0 set /A "elapsedTime+=86400"
if !elapsedTime! LSS 1 (
    set /A "elapsedTime=currentTime-startTime"
)
if not defined initialEstimatedTotalTime set "initialEstimatedTotalTime=%total_weighted_tests%"
if %tests_completed_weighted% GTR 0 (
    set /A "estimatedTotalTimeFromProgress=elapsedTime*total_weighted_tests/tests_completed_weighted"
    set /A "alpha=(total_weighted_tests-tests_completed_weighted)*100/total_weighted_tests"
    if !alpha! LSS 0 set "alpha=0"
    if !alpha! GTR 100 set "alpha=100"
    set /A "estimatedTotalTime=(alpha*initialEstimatedTotalTime+(100-alpha)*estimatedTotalTimeFromProgress)/100"
    set /A "remainingTime=estimatedTotalTime-elapsedTime"
    if !remainingTime! LSS 0 set "remainingTime=0"
) else (
    set /A "remainingTime=initialEstimatedTotalTime-elapsedTime"
    if !remainingTime! LSS 0 set "remainingTime=0"
)
call :FormatTime !elapsedTime! elapsedTimeStr
call :FormatTime !remainingTime! remainingTimeStr
set "text=INTERNET TEST by Freenitial" & set "text_length=27"
set /a "text_start_pos=(76-text_length)/2,text_end_pos=text_start_pos+text_length-1"
set "elapsedTimeText=Elapsed: !elapsedTimeStr!" & set "remainingTimeText=Remain: !remainingTimeStr!"
set /a "elapsedTime_start_pos=2,elapsedTime_end_pos=15,remainingTime_start_pos=63,remainingTime_end_pos=75"
set "header_line="
for /L %%p in (1,1,76) do (
    set "char_color=!COLOR_TEXT!!COLOR_REMAIN!"
    if %%p LEQ !progress_chars! set "char_color=!COLOR_TEXT!!COLOR_PROGRESS!"
    set "char= "
    if %%p GEQ !elapsedTime_start_pos! if %%p LEQ !elapsedTime_end_pos! (
        set /a "char_pos=%%p-elapsedTime_start_pos"
        call :GetChar "!elapsedTimeText!" !char_pos! char
    ) else if %%p GEQ !text_start_pos! if %%p LEQ !text_end_pos! (
        set /a "char_pos=%%p-text_start_pos"
        call :GetChar "!text!" !char_pos! char
    ) else if %%p GEQ !remainingTime_start_pos! if %%p LEQ !remainingTime_end_pos! (
        set /a "char_pos=%%p-remainingTime_start_pos"
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
echo                              Net Protocols Test v1.5
echo                                        --- 
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
echo       Be careful to provide simples addresses, not including special caracters like '%%' or '()'
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
echo       /nodebug     true/false - default false         True = Hide infos for KO tests at end
echo       /nopause     true/false - default false         True = Do not pause script at end
echo       /ouput       'C:\Path\to\logs\directory'        Default = 'current_script_path\Net_Protocols_Test'
echo.
echo.
echo    RETURN CODES:
echo       -----------
echo       Notice that failed test return codes will be combined. Fail IPv4 and TLS will result code 37
echo       -----------
echo       1            Unexpected error
echo       2            Argument not recognized
echo       3            At least 1 site test Failed IPv4
echo       4            At least 1 site test Failed IPv6
echo       5            At least 1 site test Failed Traceroute IPv4 = ^<2 adresses found / 5 hops
echo       6            At least 1 site test Failed Traceroute IPv6 = ^<2 adresses found / 5 hops
echo       7            At least 1 site test Failed TLS
echo       8            At least 1 site test Failed HTTPS
echo       9            At least 1 site test Failed DNS
echo       11           Failed to create output directory -permissions?-
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
echo       !n0!.bat /site google.com microsoft.com yahoo.com
echo       -----------
echo       - Tests all protocols for both sites
echo.   
echo. 
echo       Test Only specified protocols - Global :
echo       -----------
echo       !n0!.bat /site google.com /only ip4 ip6
echo       -----------
echo       - Tests only IPv4 and IPv6 protocols
echo         Notice that '/only' and '/exclude' are exclusive arguments. Do not mix them.
echo.
echo. 
echo       Exclude specified protocols - Global :
echo       -----------
echo       !n0!.bat /site google.com /exclude ip4 ip6
echo       -----------
echo      - Test everything except IPv4 and IPv6 protocols
echo        Notice that '/only' and '/exclude' are exclusive arguments. Do not mix them.
echo.   
echo. 
echo       Include specified protocols - Site Specific :
echo       -----------
echo       !n0!.bat /site google.com+++ip4+++ip6 microsoft.com yahoo.com /exclude ip4 ip6
echo       -----------
echo       - Exclude IPv4 and IPv6 for microsoft.com and yahoo.com
echo         IPv4 and IPv6 still be tested for google because of '+++ip4+++ip6'
echo         Notice that specific rules have piority on global rules
echo         '+++' will NOT test ONLY specified protocols - different from '/only'. 
echo         '+++' is designed to override a global exclusion
echo.
echo. 
echo       Exclude specified protocols - Site Specific :
echo       -----------
echo       !n0!.bat /site google.com---ip4+++dns microsoft.com yahoo.com /only ip4 ip6
echo       -----------
echo       - Test only IPv4 and IPv6 for microsoft.com and yahoo.com
echo         Test IPv6 and DNS for google.com because of '---ip4+++dns'
echo         Notice that specific rules have piority on global rules
echo         '---' work the same as global exclude, for a specified site
echo         '---' can override a global inclusion of /only
echo.
echo. 
echo       Disable debug showing at end, and disable pause at end :
echo       -----------
echo       !n0!.bat /site google.com /nodebug true /nopause true
echo       -----------
echo.   
echo.   
echo    =============================================================================
echo.
pause & exit /b 2
