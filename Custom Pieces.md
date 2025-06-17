# Custom Piece Format

### Board
The board, both for 2D and 3D, uses the new Playtak board skin format, which is a 1350x1620 (or multiple thereof)
image format containing all 6 board sizes. For examples look into the assets, or the board skin channel in the tak discord server


### 2D
Attak utilizes the standard playtak piece format for 2D pieces, making it (somewhat) compatible with playtak styles. The image is expected to be square, and a power of 2 (such as 256x256 or 512x512). Make sure the background of the image transparent, or it will show up too. 

any image format that godot supports should function
(as of writing this, those are: .bmp .dds .ktx .exr .hdr .jpg .png .tga .svg .webp)

### 3D
There are 2 formats for 3D:
##### playtak format:
Any image file will be interpreted this way, functions exactly like playtak's format

##### GLTF / GLB:
A .gltf or .glb file can be used to create fully custom models, the file must include 2 objects, named "cap" and "flat" (lowercase, no quotes). Note that any rotation, position, or scale data in the file will be discarded.

A square is one unit in size, the standard square flat is a 1x1x1 cube. (it is scaled afterwards in Attak to be less tall) So this is the rough size you should work at. Any size is allowed, though not recommended.
