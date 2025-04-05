@echo off
setlocal enabledelayedexpansion

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::                                                                                         ::
:: DESCRIPTION:                                                                            ::
::   This script allows you to view all listening ports on your Windows system             ::
::   and kill processes by port number. It provides a user-friendly interface              ::
::   with colored output and various command options.                                      ::
::                                                                                         ::
:: FUNCTIONS:                                                                              ::
::   display_header - Clears the screen and displays the ASCII art logo                    ::
::   display_help - Shows all available commands and usage instructions                    ::
::   check_ports - Lists all active listening ports with their processes                   ::
::   show_full_details - Shows detailed information about specified ports                  ::
::   kill_ports_new - Terminates processes running on specified ports                      ::
::   get_ports_list - Helper function to populate the ports array                          ::
::   get_port_at_index - Helper function to retrieve a port at a specific index            ::  
::   parse_command - Processes user input and executes the appropriate function            ::
::   exit_program - Performs cleanup and exits the script                                  ::
::   main - Main entry point that initializes the environment and starts the command loop  ::
::                                                                                         ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: Global variables for port list
set "ports="
set "port_count=0"

:: Function to display the header
:display_header
cls
echo %BLUE%
echo  ____            _      ____ _               _             
echo ^|  _ \ ___  _ __^| ^|_   / ___^| ^|__   ___  ___^| ^| _____ _ __ 
echo ^| ^|_) / _ \^| '__^| __^| ^| ^|   ^| '_ \ / _ \/ __^| ^|/ / _ \ '__^|
echo ^|  __/ (_) ^| ^|  ^| ^|_  ^| ^|___^| ^| ^| ^|  __/ (__^|   ^<  __/ ^|   
echo ^|_^|   \___/^|_^|   \__^|  \____^|_^| ^|_^|\___)\___)\_\\___)_^|   
echo                                                             
echo %NC%
goto :EOF

:: Function to display help information
:display_help
call :display_header

echo %BLUE%=============== HELP ===============%NC%
echo %YELLOW%Port Checker - Monitor and manage active network ports%NC%
echo %YELLOW%This tool allows you to view all listening ports and kill processes by port number.%NC%
echo %YELLOW%You can select individual ports, port ranges, or all ports with exceptions.%NC%
echo.

echo %YELLOW%Available commands:%NC%
echo   %GREEN%kill%NC% - Kill ports with options
echo     %BLUE%-p, --port%NC% PORT_SPEC - Specify ports to kill (required unless -a is used)
echo     %BLUE%-e, --except%NC% PORT_SPEC - Specify ports to exclude
echo     %BLUE%-a, --all%NC% - Kill all ports

echo   %GREEN%fd%NC% or %GREEN%full-detail%NC% - Show full details of ports
echo     %BLUE%-p, --port%NC% PORT_SPEC - Specify ports to show details (required unless -a is used)
echo     %BLUE%-e, --except%NC% PORT_SPEC - Specify ports to exclude
echo     %BLUE%-a, --all%NC% - Show all ports

echo   Examples:
echo     %GREEN%kill -p 1%NC% - Kill port number 1
echo     %GREEN%kill -p 1,5,7%NC% - Kill ports 1, 5, and 7
echo     %GREEN%kill -a%NC% - Kill all ports
echo     %GREEN%kill -p -a%NC% - Also kills all ports (same as kill -a)
echo     %GREEN%kill -p 1-5%NC% - Kill ports 1 through 5
echo     %GREEN%kill -p 1-10 -e 5,8,9%NC% - Kill ports 1-10 except 5,8,9
echo     %GREEN%kill -a -e 2-5%NC% - Kill all ports except 2 through 5
echo     %GREEN%fd -p 1%NC% - Show full details of port 1
echo     %GREEN%fd -a%NC% - Show full details of all ports
echo     %GREEN%full-detail -p 1-3%NC% - Show details for ports 1 through 3

echo.
echo   %GREEN%r%NC% or %GREEN%reface%NC% - Reload/refresh port list
echo   %GREEN%h%NC% or %GREEN%help%NC% - Display this help information
echo   %GREEN%exit%NC%, %GREEN%quit%NC%, %GREEN%q%NC%, or %GREEN%e%NC% - Exit program

echo.
echo help,h : show all available commands
goto :EOF

:: Function to check running ports
:check_ports
call :display_header
echo %BLUE%======= CHECKING ACTIVE PORTS =======%NC%

:: Clear previous ports list
set "ports="
set "port_count=0"

:: Get list of listening TCP ports using netstat
for /f "tokens=2 delims=:" %%p in ('netstat -ano ^| findstr /i "listening" ^| findstr /i "tcp" ^| findstr /r /c:"[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*:[0-9]*"') do (
    set /a port_count+=1
    set "port=%%p"
    set "port=!port: =!"
    set "ports=!ports!!port! "
    
    :: Get PID from netstat
    for /f "tokens=5" %%i in ('netstat -ano ^| findstr /i "listening" ^| findstr "!port!"') do (
        set "pid=%%i"
        
        :: Get process name from tasklist
        for /f "tokens=1" %%j in ('tasklist /fi "PID eq !pid!" ^| findstr /v "PID"') do (
            set "process=%%j"
            
            :: Display port info
            echo [!port_count!] port %GREEN%!port!%NC% : 127.0.0.1 : !process!
        )
    )
)

if %port_count% equ 0 (
    echo %YELLOW%No active ports found.%NC%
)

echo.
echo help,h : show all available commands

goto :EOF

:: Function to show full details of ports
:show_full_details
set "port_spec=%~1"
set "except_spec=%~2"

call :display_header
echo %BLUE%=============== FULL DETAILS ===============%NC%

:: Refresh the ports list
call :get_ports_list

if %port_count% equ 0 (
    echo %YELLOW%No active ports to show details.%NC%
    echo.
    echo help,h : show all available commands
    goto :EOF
)

echo %BLUE%Found %port_count% active ports.%NC%

:: Process port specification
set "indices_to_show="
set "indices_to_except="

if "%port_spec%" == "all" (
    echo %BLUE%Processing all ports for details...%NC%
    for /l %%i in (1,1,%port_count%) do set "indices_to_show=!indices_to_show!%%i "
) else (
    :: Check if port_spec contains commas (list)
    echo %port_spec% | findstr "," > nul
    if !errorlevel! equ 0 (
        :: Process comma-separated list
        for %%i in (%port_spec::=,%) do (
            if %%i leq %port_count% (
                if %%i gtr 0 set "indices_to_show=!indices_to_show!%%i "
            )
        )
    ) else (
        :: Check if port_spec contains hyphen (range)
        echo %port_spec% | findstr "-" > nul
        if !errorlevel! equ 0 (
            for /f "tokens=1,2 delims=-" %%a in ("%port_spec%") do (
                set "start=%%a"
                set "end=%%b"
                for /l %%i in (!start!,1,!end!) do (
                    if %%i leq %port_count% (
                        if %%i gtr 0 set "indices_to_show=!indices_to_show!%%i "
                    )
                )
            )
        ) else (
            :: Single port number
            if %port_spec% leq %port_count% (
                if %port_spec% gtr 0 set "indices_to_show=!indices_to_show!%port_spec% "
            )
        )
    )
)

:: Process exceptions if provided
if not "%except_spec%" == "" (
    :: Check if except_spec contains commas (list)
    echo %except_spec% | findstr "," > nul
    if !errorlevel! equ 0 (
        :: Process comma-separated list
        for %%i in (%except_spec::=,%) do (
            if %%i leq %port_count% (
                if %%i gtr 0 set "indices_to_except=!indices_to_except!%%i "
            )
        )
    ) else (
        :: Check if except_spec contains hyphen (range)
        echo %except_spec% | findstr "-" > nul
        if !errorlevel! equ 0 (
            for /f "tokens=1,2 delims=-" %%a in ("%except_spec%") do (
                set "start=%%a"
                set "end=%%b"
                for /l %%i in (!start!,1,!end!) do (
                    if %%i leq %port_count% (
                        if %%i gtr 0 set "indices_to_except=!indices_to_except!%%i "
                    )
                )
            )
        ) else (
            :: Single port number
            if %except_spec% leq %port_count% (
                if %except_spec% gtr 0 set "indices_to_except=!indices_to_except!%except_spec% "
            )
        )
    )
)

:: Apply exceptions
if not "%indices_to_except%" == "" (
    set "new_indices_to_show="
    for %%i in (%indices_to_show%) do (
        set "exclude=false"
        for %%j in (%indices_to_except%) do (
            if %%i equ %%j set "exclude=true"
        )
        if "!exclude!" == "false" set "new_indices_to_show=!new_indices_to_show!%%i "
    )
    set "indices_to_show=!new_indices_to_show!"
)

:: Check if any ports to show
if "%indices_to_show%" == "" (
    echo %RED%No valid ports selected for showing details.%NC%
    echo.
    echo help,h : show all available commands
    goto :EOF
)

:: Get and show details for each selected port
for %%i in (%indices_to_show%) do (
    set /a port_idx=%%i-1
    call :get_port_at_index !port_idx! port

    echo.
    echo %YELLOW%Details for port [%%i]: %GREEN%!port!%NC%
    echo %BLUE%-------------------------------------%NC%
    
    echo %GREEN%Process Information:%NC%
    netstat -ano | findstr /i "listening" | findstr "!port!"
    
    :: Get PID
    for /f "tokens=5" %%p in ('netstat -ano ^| findstr /i "listening" ^| findstr "!port!"') do (
        set "pid=%%p"
        
        if defined pid (
            echo.
            echo %GREEN%Process Details:%NC%
            tasklist /fi "PID eq !pid!" /v
            
            echo.
            echo %GREEN%Process Tree:%NC%
            wmic process where "ProcessId=!pid!" get Caption,CommandLine,ProcessId
            
            echo.
            echo %GREEN%Network Connections:%NC%
            netstat -ano | findstr "!pid!"
        ) else (
            echo.
            echo %RED%No active process found for this port%NC%
        )
    )
    echo %BLUE%-------------------------------------%NC%
)

echo.
echo help,h : show all available commands
goto :EOF

:: Helper function to get ports list
:get_ports_list
:: Clear previous ports list
set "ports="
set "port_count=0"

:: Get list of listening TCP ports using netstat
for /f "tokens=2 delims=:" %%p in ('netstat -ano ^| findstr /i "listening" ^| findstr /i "tcp" ^| findstr /r /c:"[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*:[0-9]*"') do (
    set /a port_count+=1
    set "port=%%p"
    set "port=!port: =!"
    set "ports=!ports!!port! "
)
goto :EOF

:: Helper function to get port at index
:get_port_at_index
set /a idx=%1
set count=0
for %%p in (%ports%) do (
    if !count! equ %idx% (
        set %2=%%p
        goto :EOF
    )
    set /a count+=1
)
goto :EOF

:: Function to kill ports
:kill_ports_new
set "port_spec=%~1"
set "except_spec=%~2"

call :display_header

:: Refresh the ports list
call :get_ports_list

if %port_count% equ 0 (
    echo %YELLOW%No active ports found to kill.%NC%
    echo.
    echo help,h : show all available commands
    goto :EOF
)

echo %BLUE%Found %port_count% active ports.%NC%

:: Process port specification
set "indices_to_kill="
set "indices_to_except="

if "%port_spec%" == "all" (
    echo %BLUE%Processing all ports for killing...%NC%
    for /l %%i in (1,1,%port_count%) do set "indices_to_kill=!indices_to_kill!%%i "
) else (
    :: Check if port_spec contains commas (list)
    echo %port_spec% | findstr "," > nul
    if !errorlevel! equ 0 (
        :: Process comma-separated list
        for %%i in (%port_spec::=,%) do (
            if %%i leq %port_count% (
                if %%i gtr 0 set "indices_to_kill=!indices_to_kill!%%i "
            )
        )
    ) else (
        :: Check if port_spec contains hyphen (range)
        echo %port_spec% | findstr "-" > nul
        if !errorlevel! equ 0 (
            for /f "tokens=1,2 delims=-" %%a in ("%port_spec%") do (
                set "start=%%a"
                set "end=%%b"
                for /l %%i in (!start!,1,!end!) do (
                    if %%i leq %port_count% (
                        if %%i gtr 0 set "indices_to_kill=!indices_to_kill!%%i "
                    )
                )
            )
        ) else (
            :: Single port number
            if %port_spec% leq %port_count% (
                if %port_spec% gtr 0 set "indices_to_kill=!indices_to_kill!%port_spec% "
            ) else (
                echo %RED%Invalid port specification: %port_spec%%NC%
                echo.
                echo help,h : show all available commands
                goto :EOF
            )
        )
    )
)

:: Process exceptions if provided
if not "%except_spec%" == "" (
    :: Check if except_spec contains commas (list)
    echo %except_spec% | findstr "," > nul
    if !errorlevel! equ 0 (
        :: Process comma-separated list
        for %%i in (%except_spec::=,%) do (
            if %%i leq %port_count% (
                if %%i gtr 0 set "indices_to_except=!indices_to_except!%%i "
            )
        )
    ) else (
        :: Check if except_spec contains hyphen (range)
        echo %except_spec% | findstr "-" > nul
        if !errorlevel! equ 0 (
            for /f "tokens=1,2 delims=-" %%a in ("%except_spec%") do (
                set "start=%%a"
                set "end=%%b"
                for /l %%i in (!start!,1,!end!) do (
                    if %%i leq %port_count% (
                        if %%i gtr 0 set "indices_to_except=!indices_to_except!%%i "
                    )
                )
            )
        ) else (
            :: Single port number
            if %except_spec% leq %port_count% (
                if %except_spec% gtr 0 set "indices_to_except=!indices_to_except!%except_spec% "
            ) else (
                echo %RED%Invalid exception specification: %except_spec%%NC%
                echo.
                echo help,h : show all available commands
                goto :EOF
            )
        )
    )
)

:: Apply exceptions
if not "%indices_to_except%" == "" (
    set "new_indices_to_kill="
    for %%i in (%indices_to_kill%) do (
        set "exclude=false"
        for %%j in (%indices_to_except%) do (
            if %%i equ %%j set "exclude=true"
        )
        if "!exclude!" == "false" set "new_indices_to_kill=!new_indices_to_kill!%%i "
    )
    set "indices_to_kill=!new_indices_to_kill!"
)

:: Check if any ports to kill
if "%indices_to_kill%" == "" (
    echo %RED%No valid ports selected for killing.%NC%
    echo.
    echo help,h : show all available commands
    goto :EOF
)

echo %YELLOW%Killing the following ports:%NC%
for %%i in (%indices_to_kill%) do (
    set /a port_idx=%%i-1
    call :get_port_at_index !port_idx! port
    
    echo   %RED%Port !port!%NC%
    
    :: Get PID from netstat for this port
    for /f "tokens=5" %%p in ('netstat -ano ^| findstr /i "listening" ^| findstr "!port!"') do (
        set "pid=%%p"
        
        if defined pid (
            :: Kill the process
            taskkill /F /PID !pid! > nul 2>&1
            
            if !errorlevel! equ 0 (
                echo   %GREEN%Successfully killed process !pid! running on port !port!%NC%
            ) else (
                echo   %RED%Failed to kill process !pid! on port !port!%NC%
            )
        ) else (
            echo   %RED%No process found on port !port!%NC%
        )
    )
)

:: After killing ports, reload the port list
echo %BLUE%Reloading port list after killing operations...%NC%
timeout /t 1 /nobreak > nul
call :check_ports
goto :EOF

:: Parse command function
:parse_command
set "input=%*"
set "command="
set "ports="
set "except="
set "all=false"

:: Get first word as command
for /f "tokens=1*" %%a in ("%input%") do (
    set "command=%%a"
    set "remaining=%%b"
)

:: Handle simple commands first
if "%command%" == "r" goto check_ports
if "%command%" == "reface" goto check_ports
if "%command%" == "h" goto display_help
if "%command%" == "help" goto display_help
if "%command%" == "exit" goto exit_program
if "%command%" == "quit" goto exit_program
if "%command%" == "q" goto exit_program
if "%command%" == "e" goto exit_program

:: Check for valid commands
if not "%command%" == "kill" (
    if not "%command%" == "fd" (
        if not "%command%" == "full-detail" (
            call :display_header
            echo %RED%Unknown command: %command%%NC%
            echo %YELLOW%Type 'help' or 'h' for available commands%NC%
            echo.
            echo help,h : show all available commands
            goto :EOF
        )
    )
)

set "pattern=%command% -p -a"
if "%input%" == "%pattern%" (
    echo %BLUE%Running %command% all command...%NC%
    
    if "%command%" == "kill" (
        call :kill_ports_new "all" ""
        goto :EOF
    )
    
    if "%command%" == "fd" (
        call :show_full_details "all" ""
        goto :EOF
    )
    
    if "%command%" == "full-detail" (
        call :show_full_details "all" ""
        goto :EOF
    )
)

:: Process command arguments
set "arg_pos=1"
set "skip_next=0"

:parse_loop
set /a arg_pos+=1
for /f "tokens=%arg_pos%" %%a in ("%input%") do (
    set "current_arg=%%a"
    
    if "!skip_next!" == "1" (
        set "skip_next=0"
        goto :continue_parse
    )
    
    if "!current_arg!" == "-p" (
        set /a next_pos=!arg_pos!+1
        for /f "tokens=!next_pos!" %%b in ("%input%") do (
            set "ports=%%b"
            set "skip_next=1"
        )
    ) else if "!current_arg!" == "--port" (
        set /a next_pos=!arg_pos!+1
        for /f "tokens=!next_pos!" %%b in ("%input%") do (
            set "ports=%%b"
            set "skip_next=1"
        )
    ) else if "!current_arg!" == "-e" (
        set /a next_pos=!arg_pos!+1
        for /f "tokens=!next_pos!" %%b in ("%input%") do (
            set "except=%%b"
            set "skip_next=1"
        )
    ) else if "!current_arg!" == "--except" (
        set /a next_pos=!arg_pos!+1
        for /f "tokens=!next_pos!" %%b in ("%input%") do (
            set "except=%%b"
            set "skip_next=1"
        )
    ) else if "!current_arg!" == "-a" (
        set "all=true"
    ) else if "!current_arg!" == "--all" (
        set "all=true"
    ) else (
        call :display_header
        echo %RED%Unknown option: !current_arg!%NC%
        echo.
        echo help,h : show all available commands
        goto :EOF
    )
    
    :continue_parse
)

:: Execute the appropriate command
if "%command%" == "kill" (
    if "%all%" == "true" (
        call :kill_ports_new "all" "%except%"
    ) else if not "%ports%" == "" (
        call :kill_ports_new "%ports%" "%except%"
    ) else (
        call :display_header
        echo %RED%Missing port specification. Use -p or -a option.%NC%
        echo.
        echo help,h : show all available commands
    )
) else if "%command%" == "fd" (
    if "%all%" == "true" (
        call :show_full_details "all" "%except%"
    ) else if not "%ports%" == "" (
        call :show_full_details "%ports%" "%except%"
    ) else (
        call :display_header
        echo %RED%Missing port specification. Use -p or -a option.%NC%
        echo.
        echo help,h : show all available commands
    )
) else if "%command%" == "full-detail" (
    if "%all%" == "true" (
        call :show_full_details "all" "%except%"
    ) else if not "%ports%" == "" (
        call :show_full_details "%ports%" "%except%"
    ) else (
        call :display_header
        echo %RED%Missing port specification. Use -p or -a option.%NC%
        echo.
        echo help,h : show all available commands
    )
)

goto :EOF

:exit_program
echo %BLUE%Exiting...%NC%
timeout /t 1 /nobreak > nul
cls
exit /b 0

:: Main function
:main
reg query HKCU\Console /v VirtualTerminalLevel > nul 2>&1
if %errorlevel% neq 0 (
    reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f > nul 2>&1
)

call :check_ports

:command_loop
set /p "input=-> $ "
call :parse_command %input%
goto :command_loop


:start
call :main