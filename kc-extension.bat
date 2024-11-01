@echo off
setlocal

echo WARNING: The .bat script is not tested and Windows integration neither yet

REM Check if there's at least one argument
if "%~1"=="" (
    echo Usage: %~nx0 ^<command^> [arguments...]
    echo Type "%~nx0 help" for available commands.
    exit /b 1
)

REM Store the first argument as the command
set "command=%~1"
shift /1

REM Check subcommands
if /i "%command%"=="add" (
    REM Check if additional arguments were provided
    if "%~1"=="" (
        echo Error: No extensions name provided.
        exit /b 1
    )

    REM Store all provided strings into a variable
    set "extensions=%*"

    REM Run the add-extension command with the provided extensions
    call mvnw -f runtime\pom.xml quarkus:add-extension -Dextensions="%extensions%"

    echo -------------------------------------------------------------------------------------------------------------------------------------------------------------
    echo WARNING: Do not forget to add the same extension present in runtime\pom.xml to the deployment\pom.xml with the suffix "-deployment" in artifactId (if exists)
    echo -------------------------------------------------------------------------------------------------------------------------------------------------------------
    exit /b 0
)

if /i "%command%"=="list" (
    REM List all available extensions
    call mvnw -f runtime\pom.xml quarkus:list-extensions
    exit /b 0
)

if /i "%command%"=="help" (
    echo Add Quarkus/Quarkiverse extensions to your Keycloak deployment
    echo.
    echo Usage: %~nx0 ^<command^> [arguments...]
    echo.
    echo Available commands:
    echo   add ^<extension(s)^>   Adds one or more Quarkus/Quarkiverse extensions.
    echo   list                   Displays all available extensions.
    echo   help                   Displays this help message.
    exit /b 0
)

REM If command is unknown
echo Unknown command: %command%
echo Type "%~nx0 help" for available commands.
exit /b 1
