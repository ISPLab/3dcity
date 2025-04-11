# 3DCityDB Deployment Scripts

This repository contains scripts to easily deploy the complete 3DCityDB ecosystem on your local machine.

## Components

The deployment scripts will set up the following components:

1. **3DCityDB Database** - PostgreSQL database with 3DCityDB extensions for storing 3D city models
2. **3DCityDB Tool** - Command-line interface for importing/exporting city models and managing the database
3. **3DCityDB Web Map Client** - Web-based viewer for 3D city models
4. **3DCityDB Documentation** - Local copy of the documentation

## Prerequisites

- **Docker** - Required for running containers (https://docs.docker.com/get-docker/)
- **Git** - Required for cloning repositories (https://git-scm.com/downloads)
- **Java 17+** - Optional, for building citydb-tool from source (https://adoptium.net/)
- **Python 3** - Optional, for running documentation locally (https://www.python.org/downloads/)
- **Node.js** - Optional, for running the web client locally (https://nodejs.org/)

## Usage

### For Linux/macOS Users

1. Make the script executable:
   ```
   chmod +x deploy_3dcitydb_all.sh
   ```

2. Run the script:
   ```
   ./deploy_3dcitydb_all.sh
   ```

### For Windows Users

1. Run the batch script:
   ```
   deploy_3dcitydb_all.bat
   ```

## What the Scripts Do

The scripts will:

1. Check for required dependencies (Docker, Git, Java, Python, Node.js)
2. Create a workspace directory structure
3. Clone the necessary repositories
4. Pull required Docker images
5. Start the 3DCityDB database in a Docker container
6. Deploy the 3DCityDB Web Map Client
7. Set up the documentation with MkDocs
8. Build the citydb-tool from source (if Java is available)
9. Display usage instructions for working with the deployed components

## Accessing the Components

After successful deployment:

- **Database**: Available at localhost:5432
  - Username: postgres
  - Password: specified in the script (default: changeMe)
  - Database: postgres

- **Web Map Client**: Access at http://localhost:8000/3dwebclient/index.html

- **Documentation**: Run the specified command to start the documentation server:
  ```
  cd 3dcitydb-workspace/3dcitydb-mkdocs && source venv/bin/activate && mkdocs serve
  ```
  Then access at http://localhost:8000

## Working with the 3DCityDB

The script output includes example commands for:
- Importing CityGML data
- Exporting CityGML data
- Getting help with the citydb-tool
- Managing the Docker containers

## Data Directory

A data directory is created in the workspace directory. Place your CityGML files in this directory to import them.

## Customization

You can modify the scripts to:
- Change default passwords
- Change port mappings
- Modify directory structure
- Add additional components

## Resources

- [3DCityDB Official Documentation](https://3dcitydb-docs.readthedocs.io/)
- [3DCityDB GitHub Organization](https://github.com/3dcitydb)
- [CityGML Standard](https://www.ogc.org/standards/citygml) 




Клиент поддерживает различные форматы данных для визуализации:
COLLADA/KML/glTF
CZML
GeoJSON
Cesium 3D Tiles
Indexed 3D Scene Layers (I3S)

Web Map Client может подключаться к базе данных 3DCityDB, но это подключение обычно происходит не напрямую, а через специальное API или сервисы-посредники.
Web Map Client визуализирует данные, которые:
Предварительно экспортируются из базы данных в форматы визуализации (KML/glTF, GeoJSON и др.) с помощью инструмента citydb-tool
Затем эти файлы визуализации размещаются на веб-сервере для доступа из клиента
Для тематических данных (атрибутов объектов) Web Map Client может подключаться к:
Google Spreadsheets (через Google Sheets API v4)
PostgreSQL (через промежуточный сервис PostgREST API)
OGC Feature API
Таким образом, для полноценной работы с 3DCityDB вам понадобится сначала импортировать данные в базу с помощью citydb-tool, затем экспортировать их в формате визуализации, а затем настроить Web Map Client для отображения этих данных с возможным подключением к тематическим данным через указанные сервисы.




Чтобы подключить 3DCityDB Web Map Client к базе данных для отображения тематических данных, выполните следующие шаги:
Предварительная подготовка данных:
Импортируйте CityGML данные в базу 3DCityDB с помощью citydb-tool:

docker run -i -t --rm --name citydb-tool \
  --network host \
  -v /path/to/data:/data \
  -e CITYDB_HOST=localhost \
  -e CITYDB_PORT=5432 \
  -e CITYDB_NAME=postgres \
  -e CITYDB_USERNAME=postgres \
  -e CITYDB_PASSWORD=changeMe \
3dcitydb/citydb-tool import citygml "/data/your-file.gml"

Экспортируйте модели в формат визуализации (например, KML/glTF):

docker run -i -t --rm --name citydb-tool \
  --network host \
  -v /path/to/data:/data \
  -e CITYDB_HOST=localhost \
  -e CITYDB_PORT=5432 \
  -e CITYDB_NAME=postgres \
  -e CITYDB_USERNAME=postgres \
  -e CITYDB_PASSWORD=changeMe \
3dcitydb/citydb-tool export kml -o "/data/export"
Настройка PostgREST для доступа к базе данных:
Установите и настройте PostgREST (API для PostgreSQL):

docker run -d --name postgrest \
  -p 3000:3000 \
  -e PGRST_DB_URI="postgres://postgres:changeMe@localhost:5432/postgres" \
  -e PGRST_DB_SCHEMA="citydb" \
  -e PGRST_DB_ANON_ROLE="postgres" \
  postgrest/postgrest


postgrest
Настройка Web Map Client:
Откройте Web Map Client: http://localhost:8000/3dwebclient/index.html
Добавьте слой с данными KML/glTF через интерфейс:
Нажмите "Toolbox" → "Add Layer"
Укажите URL к файлам визуализации (например, http://yourserver/path/to/exported/files)
Выберите тип данных: COLLADA/KML/glTF
Подключите тематические данные через PostgREST:
В настройках слоя укажите URL для тематических данных (поле Spreadsheet URL):
http://localhost:3000/your_citydb_table
Убедитесь, что ID объектов в визуализации совпадают с ID в базе данных
Дополнительные настройки:
Для настройки CORS, если Web Map Client и PostgREST находятся на разных серверах:
Apply to README.md
postgrest
После этих настроек Web Map Client будет отображать 3D модели из файлов визуализации, а при клике на объекты будет показывать их атрибуты, полученные напрямую из базы данных через PostgREST API.
Для более детальной настройки обратитесь к документации 3DCityDB (https://3dcitydb-docs.readthedocs.io/).






https://blogs.esri-cis.com/2022/07/08/3d-maps-based-on-citygml/# 3dcity
