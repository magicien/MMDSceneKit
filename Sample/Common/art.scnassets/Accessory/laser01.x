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
 30;
 -0.00347;-0.02859;0.00736;,
 0.01123;-0.02804;-0.01656;,
 -0.42995;6.28116;-0.01656;,
 -0.44462;6.28013;0.00736;,
 -0.45929;6.27911;-0.01656;,
 -0.01818;-0.02913;-0.01656;,
 -0.02264;-0.02930;0.00736;,
 -0.00766;-0.02874;-0.01656;,
 0.98618;6.24610;-0.01656;,
 0.97166;6.24841;0.00736;,
 0.95713;6.25071;-0.01656;,
 -0.03761;-0.02986;-0.01656;,
 0.00238;-0.02837;0.00151;,
 0.01709;-0.02782;-0.02250;,
 0.01709;6.27930;-0.46354;,
 0.00238;6.28097;-0.43968;,
 -0.01232;6.27930;-0.46354;,
 -0.01232;-0.02891;-0.02243;,
 0.00238;-0.02837;-0.00067;,
 0.01709;-0.02782;-0.02460;,
 0.01709;6.28097;0.41655;,
 0.00238;6.27930;0.44041;,
 -0.01232;6.28097;0.41655;,
 -0.01232;-0.02891;-0.02468;,
 0.00564;-0.02825;0.00166;,
 0.02047;-0.02769;-0.02233;,
 -0.31129;6.26799;0.63938;,
 -0.32597;6.26473;0.66308;,
 -0.34066;6.26646;0.63922;,
 -0.00892;-0.02879;-0.02244;;
 
 15;
 4;0,1,2,3;,
 4;0,3,4,5;,
 4;1,5,4,2;,
 4;6,7,8,9;,
 4;6,9,10,11;,
 4;7,11,10,8;,
 4;12,13,14,15;,
 4;12,15,16,17;,
 4;13,17,16,14;,
 4;18,19,20,21;,
 4;18,21,22,23;,
 4;19,23,22,20;,
 4;24,25,26,27;,
 4;24,27,28,29;,
 4;25,29,28,26;;
 
 MeshMaterialList {
  1;
  15;
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0;;
  Material {
   0.101961;0.705882;0.074510;0.920000;;
   0.000000;
   0.000000;0.000000;0.000000;;
   0.101961;0.705882;0.074510;;
   TextureFilename {
    "light.tga";
   }
  }
 }
 MeshTextureCoords {
  30;
  0.498260;1.023740;
  0.505610;1.023650;
  0.285020;0.006820;
  0.277690;0.006990;
  0.270350;0.007150;
  0.490910;1.023830;
  0.488680;1.023850;
  0.496170;1.023760;
  0.993090;0.012470;
  0.985830;0.012100;
  0.978570;0.011730;
  0.481190;1.023940;
  0.501190;1.023700;
  0.508540;1.023620;
  0.508540;0.007120;
  0.501190;0.006850;
  0.493840;0.007120;
  0.493840;1.023790;
  0.501190;1.023700;
  0.508540;1.023620;
  0.508540;0.006850;
  0.501190;0.007120;
  0.493840;0.006850;
  0.493840;1.023790;
  0.502820;1.023680;
  0.510240;1.023600;
  0.344360;0.008940;
  0.337010;0.009470;
  0.329670;0.009190;
  0.495540;1.023770;;
 }
}
