@echo off
REM Comprehensive deployment script for 3DCityDB ecosystem
echo 3DCityDB Ecosystem Deployment Script
echo ===================================

REM Check if Docker is installed
docker --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Docker is not installed. Please install Docker Desktop first.
    echo Visit https://www.docker.com/products/docker-desktop/ for installation instructions.
    exit /b 1
)

REM Check if Git is installed
git --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Git is not installed. Please install Git first.
    echo Visit https://git-scm.com/downloads for installation instructions.
    exit /b 1
)

REM Check if Java is installed (for citydb-tool direct installation)
java -version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Java is not installed. Java 17+ is required for direct citydb-tool installation.
    echo We'll proceed with Docker-based deployment instead.
    set JAVA_AVAILABLE=false
) else (
    for /f "tokens=3" %%g in ('java -version 2^>^&1 ^| findstr /i "version"') do (
        set JAVA_VERSION=%%g
    )
    echo Java version detected: %JAVA_VERSION%
    set JAVA_AVAILABLE=true
)

REM Check if Node.js is installed (for web-map-client)
node --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Node.js is not installed. It's required for running web-map-client locally.
    echo We'll proceed with setup, but you'll need Node.js to run the web-map-client.
    set NODE_AVAILABLE=false
) else (
    for /f "tokens=1" %%n in ('node --version') do (
        set NODE_VERSION=%%n
    )
    echo Node.js version detected: %NODE_VERSION%
    set NODE_AVAILABLE=true
)

REM Set variables (can be customized)
set DB_PASSWORD=changeMe
set SRID=25832
set DB_PORT=5432
set DB_CONTAINER_NAME=citydb
set TOOL_CONTAINER_NAME=citydb-tool
set WEB_MAP_CONTAINER_NAME=citydb-web-map
set WEB_MAP_PORT=8000
set DOCS_PORT=8080
set WORKSPACE_DIR=%CD%\3dcitydb-workspace
set DATA_DIR=%WORKSPACE_DIR%\data
set CITYDB_TOOL_DIR=%WORKSPACE_DIR%\citydb-tool
set WEB_MAP_DIR=%WORKSPACE_DIR%\3dcitydb-web-map
set DOCS_DIR=%WORKSPACE_DIR%\3dcitydb-mkdocs

REM Create workspace and data directories
echo Setting up workspace directories...
if not exist "%WORKSPACE_DIR%" mkdir "%WORKSPACE_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%CITYDB_TOOL_DIR%" mkdir "%CITYDB_TOOL_DIR%"
if not exist "%WEB_MAP_DIR%" mkdir "%WEB_MAP_DIR%"
if not exist "%DOCS_DIR%" mkdir "%DOCS_DIR%"

REM Function to clone or pull a repository
call :clone_or_pull_repo "https://github.com/3dcitydb/citydb-tool.git" "%CITYDB_TOOL_DIR%"
call :clone_or_pull_repo "https://github.com/3dcitydb/3dcitydb-web-map.git" "%WEB_MAP_DIR%"
call :clone_or_pull_repo "https://github.com/3dcitydb/3dcitydb-mkdocs.git" "%DOCS_DIR%"

echo Pulling 3DCityDB Docker images...
docker pull 3dcitydb/3dcitydb-pg:5-alpine
docker pull 3dcitydb/citydb-tool
docker pull tumgis/3dcitydb-web-map:latest

echo.
echo ===================================
echo 1. Starting 3DCityDB database container...
echo ===================================
REM Check if the container is already running
docker ps -q -f name=%DB_CONTAINER_NAME% > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Database container is already running.
) else (
    REM Check if the container exists but is stopped
    docker ps -aq -f name=%DB_CONTAINER_NAME% > nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo Starting existing database container...
        docker start %DB_CONTAINER_NAME%
    ) else (
        echo Creating new database container...
        docker run -d -p %DB_PORT%:5432 --name %DB_CONTAINER_NAME% ^
            -e POSTGRES_PASSWORD=%DB_PASSWORD% ^
            -e SRID=%SRID% ^
            3dcitydb/3dcitydb-pg:5-alpine
    )
    
    REM Wait for database to be ready
    echo Waiting for database to initialize (this may take a minute)...
    timeout /t 20 /nobreak > nul
)

REM Check if database container is running
docker ps -q -f name=%DB_CONTAINER_NAME% > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ 3DCityDB database is running!
    echo Database connection details:
    echo   Host: localhost
    echo   Port: %DB_PORT%
    echo   Database: postgres
    echo   Username: postgres
    echo   Password: %DB_PASSWORD%
    echo   SRID: %SRID%
) else (
    echo ❌ Error: Failed to start 3DCityDB database container.
    exit /b 1
)

echo.
echo ===================================
echo 2. Setting up 3DCityDB Web Map Client...
echo ===================================
REM Check if the container is already running
docker ps -q -f name=%WEB_MAP_CONTAINER_NAME% > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Web Map container is already running.
) else (
    REM Check if the container exists but is stopped
    docker ps -aq -f name=%WEB_MAP_CONTAINER_NAME% > nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo Starting existing Web Map container...
        docker start %WEB_MAP_CONTAINER_NAME%
    ) else (
        echo Creating new Web Map container...
        docker run -d -p %WEB_MAP_PORT%:8000 --name %WEB_MAP_CONTAINER_NAME% tumgis/3dcitydb-web-map:latest
    )
)

REM Check if web map container is running
docker ps -q -f name=%WEB_MAP_CONTAINER_NAME% > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ 3DCityDB Web Map Client is running!
    echo Web Map Client is accessible at: http://localhost:%WEB_MAP_PORT%/3dwebclient/index.html
) else (
    echo ❌ Error: Failed to start 3DCityDB Web Map container.
)

echo.
echo ===================================
echo 3. Setting up Documentation...
echo ===================================
REM Setup Python environment for documentation
python --version > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Setting up documentation with MkDocs...
    cd "%DOCS_DIR%"
    
    REM Create virtual environment if it doesn't exist
    if not exist "venv" (
        python -m venv venv
    )
    
    REM Activate virtual environment and install dependencies
    call venv\Scripts\activate.bat
    pip install -r requirements.txt
    
    echo ✅ Documentation setup complete!
    echo To start the documentation server, run:
    echo cd "%DOCS_DIR%" ^&^& venv\Scripts\activate.bat ^&^& mkdocs serve
    echo Documentation will be available at: http://localhost:8000
    
    REM Deactivate virtual environment
    call venv\Scripts\deactivate.bat
    
    cd %~dp0
) else (
    echo ⚠️ Python not found. Skipping documentation setup.
    echo To set up documentation, install Python and run:
    echo cd "%DOCS_DIR%" ^&^& python -m venv venv ^&^& venv\Scripts\activate.bat ^&^& pip install -r requirements.txt
)

echo.
echo ===================================
echo 4. Citydb-tool Setup
echo ===================================
if "%JAVA_AVAILABLE%"=="true" (
    echo Building citydb-tool from source (this may take a few minutes)...
    cd "%CITYDB_TOOL_DIR%"
    call gradlew.bat installDist
    
    if %ERRORLEVEL% EQU 0 (
        echo ✅ citydb-tool built successfully!
        echo Tool is available at: %CITYDB_TOOL_DIR%\citydb-cli\build\install\citydb\bin\citydb.bat
    ) else (
        echo ❌ Error building citydb-tool. You can still use the Docker version.
    )
    
    cd %~dp0
) else (
    echo Java not available. Skipping direct build of citydb-tool.
    echo You can use the Docker version of citydb-tool instead.
)

echo.
echo ===================================
echo 3DCityDB Ecosystem Deployment Complete!
echo ===================================
echo.
echo Services deployed:
echo 1. 3DCityDB PostgreSQL Database: Running on port %DB_PORT%
echo 2. 3DCityDB Web Map Client: http://localhost:%WEB_MAP_PORT%/3dwebclient/index.html
echo 3. Documentation: Set up at %DOCS_DIR% (run mkdocs serve to start)
echo.
echo Working with your 3DCityDB:
echo.

REM Display command examples
echo 1. To import CityGML data:
echo docker run -i -t --rm --name %TOOL_CONTAINER_NAME% ^
echo   --network host ^
echo   -v "%DATA_DIR%:/data" ^
echo   -e CITYDB_HOST=localhost ^
echo   -e CITYDB_PORT=%DB_PORT% ^
echo   -e CITYDB_NAME=postgres ^
echo   -e CITYDB_USERNAME=postgres ^
echo   -e CITYDB_PASSWORD=%DB_PASSWORD% ^
echo 3dcitydb/citydb-tool import citygml "/data/your-file.gml"
echo.

echo 2. To export CityGML data:
echo docker run -i -t --rm --name %TOOL_CONTAINER_NAME% ^
echo   --network host ^
echo   -v "%DATA_DIR%:/data" ^
echo   -e CITYDB_HOST=localhost ^
echo   -e CITYDB_PORT=%DB_PORT% ^
echo   -e CITYDB_NAME=postgres ^
echo   -e CITYDB_USERNAME=postgres ^
echo   -e CITYDB_PASSWORD=%DB_PASSWORD% ^
echo 3dcitydb/citydb-tool export citygml -o "/data/export.gml"
echo.

echo 3. To view command help:
echo docker run -i -t --rm 3dcitydb/citydb-tool help
echo.

echo 4. To stop all containers:
echo docker stop %DB_CONTAINER_NAME% %WEB_MAP_CONTAINER_NAME%
echo.

echo 5. To remove all containers:
echo docker rm %DB_CONTAINER_NAME% %WEB_MAP_CONTAINER_NAME%
echo.

echo Workspace directory: %WORKSPACE_DIR%
echo Data directory: %DATA_DIR%
echo Place your CityGML files in the data directory to import them.

echo.
echo Press any key to exit...
pause > nul
exit /b 0

:clone_or_pull_repo
REM Function to clone or pull a repository
set repo_url=%~1
set target_dir=%~2
set repo_name=%repo_url:~-4%

if exist "%target_dir%\.git" (
    echo Updating %repo_name% repository...
    pushd "%target_dir%"
    git pull
    popd
) else (
    echo Cloning %repo_name% repository...
    git clone "%repo_url%" "%target_dir%"
)

exit /b 0 