@echo off
setlocal

REM Get the script directory
set "SCRIPT_DIR=%~dp0"

REM Show main help message
:show_help
echo Add Quarkus/Quarkiverse extensions to your Keycloak deployment
echo.
echo Usage: %~nx0 [OPTIONS] ^<command^>
echo.
echo Options:
echo   -h, --help                Displays this help message.
echo.
echo Commands:
echo   add ^<extension(s)^>      Adds one or more Quarkus/Quarkiverse extensions.
echo   build                     Rebuild the Keycloak distribution with custom extensions.
echo   list                      Displays all available extensions.
echo   start-dev                 Executes the generated Keycloak distribution in development mode.
exit /b

REM Function to get keycloak.version from pom.xml
:get_keycloak_version_from_pom
for /f %%a in ('"%SCRIPT_DIR%mvnw" -f "%SCRIPT_DIR%pom.xml" help:evaluate -Dexpression=keycloak.version -q -DforceStdout') do (
    set "keycloak_version=%%a"
)
if "%keycloak_version%"=="" (
    echo Error: No keycloak.version found in pom.xml.
    exit /b 1
)
exit /b

REM Function to get quarkus.version from pom.xml
:get_quarkus_version_from_pom
for /f %%a in ('"%SCRIPT_DIR%mvnw" -f "%SCRIPT_DIR%pom.xml" help:evaluate -Dexpression=quarkus.version -q -DforceStdout') do (
    set "quarkus_version=%%a"
)
if "%quarkus_version%"=="" (
    echo Error: No quarkus.version found in pom.xml.
    exit /b 1
)
exit /b

REM Parse command and parameters
set "command=%1"
set "command=%command:"=%"  REM Remove surrounding quotes if any
shift

if /i "%command%"=="add" goto :add
if /i "%command%"=="build" goto :build
if /i "%command%"=="list" goto :list
if /i "%command%"=="start-dev" goto :start_dev
if /i "%command%"=="-h" goto :show_help
if /i "%command%"=="--help" goto :show_help

echo Unknown command: %command%
echo Type '%~nx0 --help' for available commands.
exit /b 1

:add
REM Add extensions
if "%~1"=="" (
    echo Error: No extensions name provided.
    exit /b 1
)

set "extensions="
:loop_add
if "%~1"=="" goto :done_add
set "extensions=%extensions% %1"
shift
goto :loop_add

:done_add
"%SCRIPT_DIR%mvnw" -f "%SCRIPT_DIR%runtime/pom.xml" quarkus:add-extension -Dextensions="%extensions%"
echo -------------------------------------------------------------------------------------------------------------
echo WARNING: Do not forget to add the same extension present in runtime/pom.xml to the deployment/pom.xml with the suffix '-deployment' in artifactId (if exists)
echo -------------------------------------------------------------------------------------------------------------
exit /b

:build
REM Build command
set "keycloak_version="
set "quarkus_version="
set "distPath="

:parse_build_params
if "%~1"=="" goto :process_build
if /i "%~1"=="--keycloak-version" (
    set "keycloak_version=%~2"
    shift
) else if /i "%~1"=="--quarkus-version" (
    set "quarkus_version=%~2"
    shift
) else if /i "%~1"=="--distPath" (
    set "distPath=%~2"
    shift
) else if /i "%~1"=="-h" (
    call :show_help_build
    exit /b 0
) else (
    echo Unknown build option: %1
    echo Type '%~nx0 build --help' for available build options.
    exit /b 1
)
shift
goto :parse_build_params

:process_build
if "%keycloak_version%"=="" call :get_keycloak_version_from_pom
if "%quarkus_version%"=="" call :get_quarkus_version_from_pom

echo Executing build with '--keycloak-version': %keycloak_version%, '--quarkus-version': %quarkus_version%, and '--distPath': %distPath%
"%SCRIPT_DIR%mvnw" clean install -f "%SCRIPT_DIR%pom.xml" -DskipTests -Dkeycloak.version=%keycloak_version% -Dquarkus.version=%quarkus_version%
exit /b

:list
REM List available extensions
"%SCRIPT_DIR%mvnw" -f "%SCRIPT_DIR%runtime/pom.xml" quarkus:list-extensions
exit /b

:start_dev
REM Start development mode
if not exist "%SCRIPT_DIR%target" (
    echo Error: No generated Keycloak distribution found. Please run 'build' command first.
    exit /b 1
)

for %%f in ("%SCRIPT_DIR%target\keycloak*.zip") do (
    set "keycloak_zip=%%f"
    goto :found_zip
)

echo Error: No Keycloak distribution zip file found in target directory.
exit /b 1

:found_zip
echo Unzipping Keycloak distribution from: %keycloak_zip%
"%SCRIPT_DIR%\unzip.exe" -q "%keycloak_zip%" -d "%SCRIPT_DIR%target\"

set "keycloak_dir="
for %%d in ("%SCRIPT_DIR%target\keycloak*") do (
    set "keycloak_dir=%%~nd"
)

cd /d "%SCRIPT_DIR%target\%keycloak_dir%"
echo Starting Keycloak in development mode...
call bin\kc.sh start-dev
exit /b

REM Show build help message
:show_help_build
echo Build Keycloak distribution with provided Quarkus/Quarkiverse extensions
echo.
echo Usage: %~nx0 build [OPTIONS]
echo.
echo Options:
echo   --keycloak-version ^<version^>    Specifies the Keycloak version. Defaults to version from 'pom.xml' if not provided.
echo   --quarkus-version ^<version^>     Specifies the Quarkus version. Defaults to version from 'pom.xml' if not provided.
echo   --distPath ^<path^>               Specifies the distribution path.
echo   -h, --help                        Displays this help message.
exit /b
