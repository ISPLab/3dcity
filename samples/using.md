// Start of Selection
# Using 3ds Max (.max) Models in a 3DCityDB Project

To use models created in 3ds Max (.max files) with 3DCityDB, you need to go through several conversion steps since 3DCityDB works with the CityGML format. Below is a step-by-step guide.

## Step 1: Export from 3ds Max to an Intermediate Format
1. Open your .max models in 3ds Max.  
2. Export them to one of the following formats:
   - Collada (.dae) – a good choice for preserving geometry and textures.  
   - OBJ (.obj) – a widely supported format.  
   - FBX (.fbx) – retains model details.  
   - glTF (.gltf/.glb) – a modern 3D format for the web.

To export:  
1. In 3ds Max, go to File → Export → Export.  
2. Select the desired format from the dropdown list.  
3. Configure export settings (texture preservation, scale, etc.).  
4. Save the file.

## Step 2: Adding Georeferencing to Models
It is essential for your models to have correct coordinates:
- Before exporting from 3ds Max, ensure the model is positioned correctly.  
- Alternatively, use specialized software (e.g., FME, QGIS) for georeferencing.  
- The model should be in the same coordinate system as 3DCityDB (by default, the EPSG code specified during setup).

## Step 3: Converting to CityGML
You have several options for converting your models to CityGML:

### Option A: Using FME (the most flexible)
1. Install FME Desktop.  
2. Create a workflow to transform your format (DAE/OBJ/FBX) into CityGML.  
3. Configure CityGML parameters (LOD, attributes, etc.).  
4. Run the transformation.

### Option B: Using SketchUp with the CityGML Plugin
1. Import the exported file into SketchUp.  
2. Install the CityGML plugin for SketchUp.  
3. Export your model to CityGML.

### Option C: Direct Use with the Web Map Client
If a complete CityGML conversion process is too cumbersome, you can use your models directly:
1. Export from 3ds Max as glTF or Collada (.dae).  
2. Host these files on a web server.  
3. Use the 3DCityDB Web Map Client for direct visualization of those formats.

## Step 4: Visualization Without Database Import
The 3DCityDB Web Map Client can display various formats directly:
1. Host the exported files (especially glTF) on a web server.  
2. Open the Web Map Client at:  
   http://localhost:8000/3dwebclient/index.html  
3. Click “Toolbox” → “Add Layer.”  
4. Choose the data type “COLLADA/KML/glTF.”  
5. Provide the URL to your files.  
https://media.githubusercontent.com/media/ISPLab/3dcity/refs/heads/master/samples/sample_buildings.glb
6. Configure other visualization settings as needed.




## Step 5: Full Integration (Optional)
For complete integration with 3DCityDB:
1. Import the converted CityGML files into the database.  
2. Export as described in previous tutorials.  
3. Set up thematic data with attributes.

## Additional Tips
- **Textures**: Make sure that all textures export with your model.  
- **Optimization**: Simplify models before export for better web client performance.  
- **Size**: Split large models into logical parts (e.g., blocks or individual buildings).  
- **LOD**: Create multiple Levels of Detail for optimal visualization.

Using 3ds Max models requires a few extra conversion steps, but gives you the ability to integrate detailed architectural models into a geospatial environment powered by 3DCityDB.