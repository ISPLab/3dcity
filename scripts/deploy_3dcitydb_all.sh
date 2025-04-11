#!/bin/bash

# Comprehensive deployment script for 3DCityDB ecosystem
echo "3DCityDB Ecosystem Deployment Script"
echo "==================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
    exit 1
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed. Please install Git first."
    echo "Visit https://git-scm.com/downloads for installation instructions."
    exit 1
fi

# Check if Java is installed (for citydb-tool direct installation)
if ! command -v java &> /dev/null; then
    echo "Warning: Java is not installed. Java 17+ is required for direct citydb-tool installation."
    echo "We'll proceed with Docker-based deployment instead."
    JAVA_AVAILABLE=false
else
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "Java version detected: $java_version"
    JAVA_AVAILABLE=true
fi

# Check if Node.js is installed (for web-map-client)
if ! command -v node &> /dev/null; then
    echo "Warning: Node.js is not installed. It's required for running web-map-client locally."
    echo "We'll proceed with setup, but you'll need Node.js to run the web-map-client."
    NODE_AVAILABLE=false
else
    node_version=$(node --version)
    echo "Node.js version detected: $node_version"
    NODE_AVAILABLE=true
fi

# Set variables (can be customized)
DB_PASSWORD="changeMe"
SRID="25832"  # EPSG code
DB_PORT="5432"
DB_CONTAINER_NAME="citydb"
TOOL_CONTAINER_NAME="citydb-tool"
WEB_MAP_CONTAINER_NAME="citydb-web-map"
WEB_MAP_PORT="8000"
DOCS_PORT="8080"
WORKSPACE_DIR="$PWD/3dcitydb-workspace"
DATA_DIR="$WORKSPACE_DIR/data"
CITYDB_TOOL_DIR="$WORKSPACE_DIR/citydb-tool"
WEB_MAP_DIR="$WORKSPACE_DIR/3dcitydb-web-map"
DOCS_DIR="$WORKSPACE_DIR/3dcitydb-mkdocs"

# Create workspace and data directories
echo "Setting up workspace directories..."
mkdir -p "$DATA_DIR"
mkdir -p "$CITYDB_TOOL_DIR"
mkdir -p "$WEB_MAP_DIR"
mkdir -p "$DOCS_DIR"

# Function to clone or pull a repository
clone_or_pull_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name=$(basename "$repo_url" .git)
    
    if [ -d "$target_dir/.git" ]; then
        echo "Updating $repo_name repository..."
        cd "$target_dir"
        git pull
        cd - > /dev/null
    else
        echo "Cloning $repo_name repository..."
        git clone "$repo_url" "$target_dir"
    fi
}

# Clone repositories
clone_or_pull_repo "https://github.com/3dcitydb/citydb-tool.git" "$CITYDB_TOOL_DIR"
clone_or_pull_repo "https://github.com/3dcitydb/3dcitydb-web-map.git" "$WEB_MAP_DIR"
clone_or_pull_repo "https://github.com/3dcitydb/3dcitydb-mkdocs.git" "$DOCS_DIR"

echo "Pulling 3DCityDB Docker images..."
docker pull 3dcitydb/3dcitydb-pg:5-alpine
docker pull 3dcitydb/citydb-tool
docker pull tumgis/3dcitydb-web-map:latest

echo ""
echo "==================================="
echo "1. Starting 3DCityDB database container..."
echo "==================================="
# Check if the container is already running
if [ "$(docker ps -q -f name=$DB_CONTAINER_NAME)" ]; then
    echo "Database container is already running."
else
    # Check if the container exists but is stopped
    if [ "$(docker ps -aq -f name=$DB_CONTAINER_NAME)" ]; then
        echo "Starting existing database container..."
        docker start $DB_CONTAINER_NAME
    else
        echo "Creating new database container..."
        docker run -d -p $DB_PORT:5432 --name $DB_CONTAINER_NAME \
            -e POSTGRES_PASSWORD=$DB_PASSWORD \
            -e SRID=$SRID \
            3dcitydb/3dcitydb-pg:5-alpine
    fi
    
    # Wait for database to be ready
    echo "Waiting for database to initialize (this may take a minute)..."
    sleep 20
fi

# Check if database container is running
if [ "$(docker ps -q -f name=$DB_CONTAINER_NAME)" ]; then
    echo "✅ 3DCityDB database is running!"
    echo "Database connection details:"
    echo "  Host: localhost"
    echo "  Port: $DB_PORT"
    echo "  Database: postgres"
    echo "  Username: postgres"
    echo "  Password: $DB_PASSWORD"
    echo "  SRID: $SRID"
else
    echo "❌ Error: Failed to start 3DCityDB database container."
    exit 1
fi

echo ""
echo "==================================="
echo "2. Setting up 3DCityDB Web Map Client..."
echo "==================================="
# Check if the container is already running
if [ "$(docker ps -q -f name=$WEB_MAP_CONTAINER_NAME)" ]; then
    echo "Web Map container is already running."
else
    # Check if the container exists but is stopped
    if [ "$(docker ps -aq -f name=$WEB_MAP_CONTAINER_NAME)" ]; then
        echo "Starting existing Web Map container..."
        docker start $WEB_MAP_CONTAINER_NAME
    else
        echo "Creating new Web Map container..."
        docker run -d -p $WEB_MAP_PORT:8000 --name $WEB_MAP_CONTAINER_NAME tumgis/3dcitydb-web-map:latest
    fi
fi

# Check if web map container is running
if [ "$(docker ps -q -f name=$WEB_MAP_CONTAINER_NAME)" ]; then
    echo "✅ 3DCityDB Web Map Client is running!"
    echo "Web Map Client is accessible at: http://localhost:$WEB_MAP_PORT/3dwebclient/index.html"
else
    echo "❌ Error: Failed to start 3DCityDB Web Map container."
fi

echo ""
echo "==================================="
echo "3. Setting up Documentation..."
echo "==================================="
# Setup Python environment for documentation
if command -v python3 &> /dev/null; then
    echo "Setting up documentation with MkDocs..."
    cd "$DOCS_DIR"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    # Activate virtual environment and install dependencies
    source venv/bin/activate
    pip install -r requirements.txt
    
    echo "✅ Documentation setup complete!"
    echo "To start the documentation server, run:"
    echo "cd $DOCS_DIR && source venv/bin/activate && mkdocs serve"
    echo "Documentation will be available at: http://localhost:8000"
    
    # Deactivate virtual environment
    deactivate
    
    cd - > /dev/null
else
    echo "⚠️ Python 3 not found. Skipping documentation setup."
    echo "To set up documentation, install Python 3 and run:"
    echo "cd $DOCS_DIR && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
fi

echo ""
echo "==================================="
echo "4. Citydb-tool Setup"
echo "==================================="
if [ "$JAVA_AVAILABLE" = true ]; then
    echo "Building citydb-tool from source (this may take a few minutes)..."
    cd "$CITYDB_TOOL_DIR"
    ./gradlew installDist
    
    if [ $? -eq 0 ]; then
        echo "✅ citydb-tool built successfully!"
        echo "Tool is available at: $CITYDB_TOOL_DIR/citydb-cli/build/install/citydb/bin/citydb"
    else
        echo "❌ Error building citydb-tool. You can still use the Docker version."
    fi
    
    cd - > /dev/null
else
    echo "Java not available. Skipping direct build of citydb-tool."
    echo "You can use the Docker version of citydb-tool instead."
fi

echo ""
echo "==================================="
echo "3DCityDB Ecosystem Deployment Complete!"
echo "==================================="
echo ""
echo "Services deployed:"
echo "1. 3DCityDB PostgreSQL Database: Running on port $DB_PORT"
echo "2. 3DCityDB Web Map Client: http://localhost:$WEB_MAP_PORT/3dwebclient/index.html"
echo "3. Documentation: Set up at $DOCS_DIR (run mkdocs serve to start)"
echo ""
echo "Working with your 3DCityDB:"
echo ""

# Display command examples
echo "1. To import CityGML data:"
echo "docker run -i -t --rm --name $TOOL_CONTAINER_NAME \\"
echo "  --network host \\"
echo "  -v $DATA_DIR:/data \\"
echo "  -e CITYDB_HOST=localhost \\"
echo "  -e CITYDB_PORT=$DB_PORT \\"
echo "  -e CITYDB_NAME=postgres \\"
echo "  -e CITYDB_USERNAME=postgres \\"
echo "  -e CITYDB_PASSWORD=$DB_PASSWORD \\"
echo "3dcitydb/citydb-tool import citygml \"/data/your-file.gml\""
echo ""

echo "2. To export CityGML data:"
echo "docker run -i -t --rm --name $TOOL_CONTAINER_NAME \\"
echo "  --network host \\"
echo "  -v $DATA_DIR:/data \\"
echo "  -e CITYDB_HOST=localhost \\"
echo "  -e CITYDB_PORT=$DB_PORT \\"
echo "  -e CITYDB_NAME=postgres \\"
echo "  -e CITYDB_USERNAME=postgres \\"
echo "  -e CITYDB_PASSWORD=$DB_PASSWORD \\"
echo "3dcitydb/citydb-tool export citygml -o \"/data/export.gml\""
echo ""

echo "3. To view command help:"
echo "docker run -i -t --rm 3dcitydb/citydb-tool help"
echo ""

echo "4. To stop all containers:"
echo "docker stop $DB_CONTAINER_NAME $WEB_MAP_CONTAINER_NAME"
echo ""

echo "5. To remove all containers:"
echo "docker rm $DB_CONTAINER_NAME $WEB_MAP_CONTAINER_NAME"
echo ""

echo "Workspace directory: $WORKSPACE_DIR"
echo "Data directory: $DATA_DIR"
echo "Place your CityGML files in the data directory to import them." 