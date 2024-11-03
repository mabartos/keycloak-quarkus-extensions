@echo off
REM Note: This script provides basic support for Windows environments.
REM It is recommended to test thoroughly, as it may not cover all scenarios.

setlocal

:show_help
echo Add Quarkus/Quarkiverse extensions to your Keycloak deployment
echo.
echo Usage: %~n0 [OPTIONS] <command>
echo.
echo Options:
echo   -h, --help                Displays this help message.
echo.
echo Commands:
echo   add <extension(s)>        Adds one or more Quarkus/Quarkiverse extensions.
echo   build                     Rebuild the Keycloak distribution with custom extensions.
echo   list                      Displays all available extensions.
echo   start-dev                 Executes the generated Keycloak distribution in development mode.
exit /b

:show_help_build
echo Build Keycloak distribution with provided Quarkus/Quarkiverse extensions
echo.
echo Usage: %~n0 build [OPTIONS]
echo.
echo Options:
echo   --keycloak-version <version>    Specifies the Keycloak version. Defaults to version from 'pom.xml' if not provided.
echo   --quarkus-version <version>     Specifies the Quarkus version. Defaults to version from 'pom.xml' if not provided.
echo   --distPath <path>               Specifies the distribution path.
echo   -h, --help                      Displays this help message.
exit /b

:get_keycloak_version_from_pom
for /f %%a in ('call ./mvnw help:evaluate -Dexpression=keycloak.version -q -DforceStdout') do (
    set "version=%%a"
)
if "%version%"=="" (
    echo Error: No keycloak.version found in pom.xml.
    exit /b 1
)
exit /b

:get_quarkus_version_from_pom
for /f %%a in ('call ./mvnw help:evaluate -Dexpression=quarkus.version -q -DforceStdout') do (
    set "version=%%a"
)
if "%version%"=="" (
    echo Error: No quarkus.version found in pom.xml.
    exit /b 1
)
exit /b

REM Store the command
set "command=%~1"
shift

REM Handle different commands
if "%command%"=="" (
    set "command=help"
)

if "%command%"=="help" (
    call :show_help
)

if "%command%"=="add" (
    if "%~1"=="" (
        echo Error: No extensions name provided.
        exit /b 1
    )

    set "extensions=%*"
    call ./mvnw -f runtime/pom.xml quarkus:add-extension -Dextensions="%extensions%"

    echo -------------------------------------------------------------------------------------------------------------------------------------------------------------
    echo WARNING: Do not forget to add the same extension present in runtime/pom.xml to the deployment/pom.xml with the suffix '-deployment' in artifactId (if exists)
    echo -------------------------------------------------------------------------------------------------------------------------------------------------------------
    exit /b
)

if "%command%"=="build" (
    set "keycloak_version="
    set "quarkus_version="
    set "distPath="

    REM Process parameters for `build`
    :process_params
    if "%~1"=="" goto :end_params
    if "%~1"=="--keycloak-version" (
        set "keycloak_version=%~2"
        if "%keycloak_version%"=="" (
            echo Error: Missing value for --keycloak-version.
            exit /b 1
        )
        echo Keycloak version set to: %keycloak_version%
        shift
    ) else if "%~1"=="--quarkus-version" (
        set "quarkus_version=%~2"
        if "%quarkus_version%"=="" (
            echo Error: Missing value for --quarkus-version.
            exit /b 1
        )
        echo Quarkus version set to: %quarkus_version%
        shift
    ) else if "%~1"=="--distPath" (
        set "distPath=%~2"
        if "%distPath%"=="" (
            echo Error: Missing value for --distPath.
            exit /b 1
        )
        echo Distribution path set to: %distPath%
        shift
    ) else if "%~1"=="-h" (
        call :show_help_build
    ) else (
        echo Unknown build option: %~1
        echo Type '%~n0 build --help' for available build options.
        exit /b 1
    )
    shift
    goto process_params
    :end_params

    REM Get Keycloak version from pom.xml only if not set
    if "%keycloak_version%"=="" (
        call :get_keycloak_version_from_pom
        echo Using keycloak version from pom.xml: %version%
        set "keycloak_version=%version%"
    )

    REM Get Quarkus version from pom.xml only if not set
    if "%quarkus_version%"=="" (
        call :get_quarkus_version_from_pom
        echo Using quarkus version from pom.xml: %version%
        set "quarkus_version=%version%"
    )

    echo Executing build with '--keycloak-version': %keycloak_version%, '--quarkus-version': %quarkus_version%, and '--distPath': %distPath%
    call ./mvnw clean install -DskipTests -Dkeycloak.version="%keycloak_version%" -Dquarkus.version="%quarkus_version%"
    exit /b
)

if "%command%"=="list" (
    call ./mvnw -f runtime/pom.xml quarkus:list-extensions
    exit /b
)

if "%command%"=="start-dev" (
    REM Check if target directory is empty
    if not exist "target" (
        echo Error: No generated Keycloak distribution found. Please run 'build' command first.
        exit /b 1
    )

    REM Find the Keycloak distribution zip file in the target directory
    for /f %%i in ('dir /b /s target\keycloak*.zip') do (
        set "keycloak_zip=%%i"
    )

    if "%keycloak_zip%"=="" (
        echo Error: No Keycloak distribution zip file found in target directory.
        exit /b 1
    )

    REM Unzip the distribution
    echo Unzipping Keycloak distribution from: %keycloak_zip%
    powershell -command "Expand-Archive -Path '%keycloak_zip%' -DestinationPath target -Force"

    REM Change to the directory of the unzipped distribution
    set "keycloak_dir=%keycloak_zip:~0,-4%"
    pushd "target\%keycloak_dir%"

    REM Start Keycloak in development mode
    echo Starting Keycloak in development mode...
    call ./bin/kc.bat start-dev
    exit /b
)

echo Unknown command: %command%
echo Type '%~n0 --help' for available commands.
exit /b 1
