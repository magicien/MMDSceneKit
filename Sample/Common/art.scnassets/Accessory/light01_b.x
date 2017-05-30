xof 0302txt 0064
template Header {
 <3D82AB43-62DA-11cf-AB39-0020AF71E433>
 WORD major;
 WORD minor;
 DWORD flags;
}

template Vector {
 <3D82AB5E-62DA-11cf-AB39-0020AF71E433>
 FLOAT x;
 FLOAT y;
 FLOAT z;
}

template Coords2d {
 <F6F23F44-7686-11cf-8F52-0040333594A3>
 FLOAT u;
 FLOAT v;
}

template Matrix4x4 {
 <F6F23F45-7686-11cf-8F52-0040333594A3>
 array FLOAT matrix[16];
}

template ColorRGBA {
 <35FF44E0-6C7C-11cf-8F52-0040333594A3>
 FLOAT red;
 FLOAT green;
 FLOAT blue;
 FLOAT alpha;
}

template ColorRGB {
 <D3E16E81-7835-11cf-8F52-0040333594A3>
 FLOAT red;
 FLOAT green;
 FLOAT blue;
}

template IndexedColor {
 <1630B820-7842-11cf-8F52-0040333594A3>
 DWORD index;
 ColorRGBA indexColor;
}

template Boolean {
 <4885AE61-78E8-11cf-8F52-0040333594A3>
 WORD truefalse;
}

template Boolean2d {
 <4885AE63-78E8-11cf-8F52-0040333594A3>
 Boolean u;
 Boolean v;
}

template MaterialWrap {
 <4885AE60-78E8-11cf-8F52-0040333594A3>
 Boolean u;
 Boolean v;
}

template TextureFilename {
 <A42790E1-7810-11cf-8F52-0040333594A3>
 STRING filename;
}

template Material {
 <3D82AB4D-62DA-11cf-AB39-0020AF71E433>
 ColorRGBA faceColor;
 FLOAT power;
 ColorRGB specularColor;
 ColorRGB emissiveColor;
 [...]
}

template MeshFace {
 <3D82AB5F-62DA-11cf-AB39-0020AF71E433>
 DWORD nFaceVertexIndices;
 array DWORD faceVertexIndices[nFaceVertexIndices];
}

template MeshFaceWraps {
 <4885AE62-78E8-11cf-8F52-0040333594A3>
 DWORD nFaceWrapValues;
 Boolean2d faceWrapValues;
}

template MeshTextureCoords {
 <F6F23F40-7686-11cf-8F52-0040333594A3>
 DWORD nTextureCoords;
 array Coords2d textureCoords[nTextureCoords];
}

template MeshMaterialList {
 <F6F23F42-7686-11cf-8F52-0040333594A3>
 DWORD nMaterials;
 DWORD nFaceIndexes;
 array DWORD faceIndexes[nFaceIndexes];
 [Material]
}

template MeshNormals {
 <F6F23F43-7686-11cf-8F52-0040333594A3>
 DWORD nNormals;
 array Vector normals[nNormals];
 DWORD nFaceNormals;
 array MeshFace faceNormals[nFaceNormals];
}

template MeshVertexColors {
 <1630B821-7842-11cf-8F52-0040333594A3>
 DWORD nVertexColors;
 array IndexedColor vertexColors[nVertexColors];
}

template Mesh {
 <3D82AB44-62DA-11cf-AB39-0020AF71E433>
 DWORD nVertices;
 array Vector vertices[nVertices];
 DWORD nFaces;
 array MeshFace faces[nFaces];
 [...]
}

Header{
1;
0;
1;
}

Mesh {
 16;
 -0.00044;-0.01957;-0.02293;,
 -0.00044;3.04556;-0.20219;,
 -0.14377;3.04556;-0.14283;,
 -0.01702;-0.01957;-0.01607;,
 -0.20314;3.04555;0.00051;,
 -0.02388;-0.01957;0.00051;,
 -0.14377;3.04556;0.14383;,
 -0.01702;-0.01957;0.01708;,
 -0.00044;3.04556;0.20321;,
 -0.00044;-0.01957;0.02394;,
 0.14288;3.04556;0.14383;,
 0.01613;-0.01957;0.01708;,
 0.20226;3.04556;0.00051;,
 0.02299;-0.01957;0.00051;,
 0.14288;3.04556;-0.14283;,
 0.01613;-0.01957;-0.01607;;
 
 8;
 4;0,1,2,3;,
 4;3,2,4,5;,
 4;5,4,6,7;,
 4;7,6,8,9;,
 4;9,8,10,11;,
 4;11,10,12,13;,
 4;13,12,14,15;,
 4;15,14,1,0;;
 
 MeshMaterialList {
  1;
  8;
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0;;
  Material {
   0.412000;1.000000;1.000000;0.900000;;
   0.000000;
   0.000000;0.000000;0.000000;;
   0.412000;1.000000;1.000000;;
   TextureFilename {
    "light.tga";
   }
  }
 }
 MeshTextureCoords {
  16;
  0.500190;0.977930;
  0.500190;0.021420;
  0.146710;0.021420;
  0.419240;0.977930;
  0.000290;0.021420;
  0.385720;0.977930;
  0.146710;0.021420;
  0.419240;0.977930;
  0.500190;0.021420;
  0.500190;0.977930;
  0.853670;0.021420;
  0.581130;0.977930;
  1.000090;0.021420;
  0.614660;0.977930;
  0.853670;0.021420;
  0.581130;0.977930;;
 }
}
