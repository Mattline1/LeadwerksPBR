SHADER version 1
@OpenGL2.Vertex
#version 400
#define MAX_INSTANCES 4096
#define ANIMATION_AMPLITUDE 0.01

//Uniforms
uniform vec4 materialcolordiffuse;
uniform mat4 projectioncameramatrix;
uniform mat4 camerainversematrix;
//uniform instancematrices { int matrix[MAX_INSTANCES];} entity;
//uniform bonematrices { int matrix[MAX_INSTANCES];} bone;
uniform vec4 clipplane0 = vec4(0.0);
uniform sampler2D texture5;// matrix grid
uniform sampler2D texture6;// terrain heightmap
uniform vec2 InstanceOffset;
uniform float TerrainSize;
uniform float TerrainHeight;
uniform float TerrainResolution;
uniform float CellResolution;
uniform float Density;
uniform vec3 cameraposition;
//uniform usamplerBuffer texture4;// instance buffer
uniform vec2 scalerange;
uniform vec2 gridoffset;
uniform float variationmapresolution;
uniform vec2 colorrange;
uniform float currenttime;

//Attributes
in vec3 vertex_position;
in vec4 vertex_color;
in vec2 vertex_texcoords0;
in vec3 vertex_normal;
in vec3 vertex_binormal;
in vec3 vertex_tangent;
//in float vertex_texcoords1;
in uint vertex_texcoords1;

//Outputs
out vec4 ex_color;
out vec2 ex_texcoords0;
out vec3 ex_VertexCameraPosition;
out vec3 ex_normal;
out vec3 ex_tangent;
out vec3 ex_binormal;
out float clipdistance0;
out mat4 ex_entitymatrix;
out vec3 screendir;

float rand(vec2 co)
{
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

mat4 GetInstanceMatrix(in uint id)
{
	float x = floor(id/CellResolution);
	float z = id-x*CellResolution;
	x += gridoffset.x;
	z += gridoffset.y;
	
	mat4 mat;
	vec2 texcoord = vec2(0.5);
	
	mat[0][0]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 0.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[0][1]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 1.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[0][2]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 2.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[0][3]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 3.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	
	mat[1][0]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 4.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[1][1]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 5.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[1][2]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 6.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[1][3]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 7.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	
	mat[2][0]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 8.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[2][1]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 9.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[2][2]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 10.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[2][3]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 11.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	
	mat[3][0]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 12.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[3][1]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 13.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[3][2]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 14.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[3][3]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 15.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	
	mat[3][0] += x * Density;
	mat[3][2] += z * Density;
	
	vec2 texcoords = vec2((mat[3][0]+TerrainSize/2.0)/TerrainSize+(1.0/TerrainResolution/2.0),(mat[3][2]+TerrainSize/2.0)/TerrainSize+(1.0/TerrainResolution/2.0));
	mat[3][1] = texture(texture6,texcoords).r * TerrainHeight;
	
	//Adjust scale
	float scale = mat[3][3];
	scale = scalerange.x + scale * (scalerange.y - scalerange.x);
	mat[0].xyz = mat[0].xyz * scale;
	mat[1].xyz = mat[1].xyz * scale;
	mat[2].xyz = mat[2].xyz * scale;
	
	return mat;
}

void main()
{
	uint id = uint(vertex_texcoords1);//texelFetch(texture4,gl_InstanceID).r;
	//uint id = gl_InstanceID;
	mat4 entitymatrix_ = GetInstanceMatrix( id );
	ex_color = vec4(entitymatrix_[0][3]) * (colorrange.y - colorrange.x) + colorrange.x;
	ex_color.a = 1.0;
	entitymatrix_[0][3]=0.0; entitymatrix_[1][3]=0.0; entitymatrix_[2][3]=0.0; entitymatrix_[3][3]=1.0;
	ex_entitymatrix = entitymatrix_;
	
	vec4 modelvertexposition = entitymatrix_ * vec4(vertex_position,1.0);
	
	//Clip planes
	if (length(clipplane0.xyz)>0.0001)
	{
		clipdistance0 = modelvertexposition.x*clipplane0.x + modelvertexposition.y*clipplane0.y + modelvertexposition.z*clipplane0.z + clipplane0.w;
	}
	else
	{
		clipdistance0 = 0.0;
	}	
	
	ex_VertexCameraPosition = vec3(camerainversematrix * modelvertexposition);
	gl_Position = projectioncameramatrix * modelvertexposition;
	
	screendir = entitymatrix_[3].xyz - cameraposition;
	
	//mat3 nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);
	//nmat = nmat * mat3(entitymatrix_[0].xyz,entitymatrix_[1].xyz,entitymatrix_[2].xyz);
	mat3 nmat = mat3(entitymatrix_);
	ex_normal = normalize(nmat * vertex_normal);	
	ex_tangent = normalize(nmat * vertex_tangent);
	ex_binormal = normalize(nmat * vertex_binormal);	
	
	ex_texcoords0 = vertex_texcoords0;
}
@OpenGLES2.Vertex

@OpenGLES2.Fragment

@OpenGL4.Vertex
#version 400
#define MAX_INSTANCES 4096
#define ANIMATION_AMPLITUDE 0.01

//Uniforms
uniform vec4 materialcolordiffuse;
uniform mat4 projectioncameramatrix;
uniform mat4 camerainversematrix;
//uniform instancematrices { int matrix[MAX_INSTANCES];} entity;
//uniform bonematrices { int matrix[MAX_INSTANCES];} bone;
uniform vec4 clipplane0 = vec4(0.0);
uniform sampler2D texture5;// matrix grid
uniform sampler2D texture6;// terrain heightmap
uniform vec2 InstanceOffset;
uniform float TerrainSize;
uniform float TerrainHeight;
uniform float TerrainResolution;
uniform float CellResolution;
uniform float Density;
uniform vec3 cameraposition;
//uniform usamplerBuffer texture4;// instance buffer
uniform vec2 scalerange;
uniform vec2 gridoffset;
uniform float variationmapresolution;
uniform vec2 colorrange;
uniform float currenttime;

//Attributes
in vec3 vertex_position;
in vec4 vertex_color;
in vec2 vertex_texcoords0;
in vec3 vertex_normal;
in vec3 vertex_binormal;
in vec3 vertex_tangent;
//in float vertex_texcoords1;
in uint vertex_texcoords1;

//Outputs
out vec4 ex_color;
out vec2 ex_texcoords0;
out vec3 ex_VertexCameraPosition;
out vec3 ex_normal;
out vec3 ex_tangent;
out vec3 ex_binormal;
out float clipdistance0;
out mat4 ex_entitymatrix;
out vec3 screendir;

float rand(vec2 co)
{
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

mat4 GetInstanceMatrix(in uint id)
{
	float x = floor(id/CellResolution);
	float z = id-x*CellResolution;
	x += gridoffset.x;
	z += gridoffset.y;
	
	mat4 mat;
	vec2 texcoord = vec2(0.5);
	
	mat[0][0]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 0.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[0][1]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 1.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[0][2]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 2.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[0][3]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 3.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	
	mat[1][0]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 4.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[1][1]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 5.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[1][2]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 6.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[1][3]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 7.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	
	mat[2][0]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 8.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[2][1]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 9.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[2][2]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 10.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[2][3]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 11.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	
	mat[3][0]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 12.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[3][1]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 13.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[3][2]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 14.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	mat[3][3]=texture(texture5,vec2((float(x)*16.0 + texcoord.x + 15.0) / variationmapresolution / 16.0,texcoord.y + z / variationmapresolution)).r;
	
	mat[3][0] += x * Density;
	mat[3][2] += z * Density;
	
	vec2 texcoords = vec2((mat[3][0]+TerrainSize/2.0)/TerrainSize+(1.0/TerrainResolution/2.0),(mat[3][2]+TerrainSize/2.0)/TerrainSize+(1.0/TerrainResolution/2.0));
	mat[3][1] = texture(texture6,texcoords).r * TerrainHeight;
	
	//Adjust scale
	float scale = mat[3][3];
	scale = scalerange.x + scale * (scalerange.y - scalerange.x);
	mat[0].xyz = mat[0].xyz * scale;
	mat[1].xyz = mat[1].xyz * scale;
	mat[2].xyz = mat[2].xyz * scale;
	
	return mat;
}

void main()
{
	uint id = uint(vertex_texcoords1);//texelFetch(texture4,gl_InstanceID).r;
	//uint id = gl_InstanceID;
	mat4 entitymatrix_ = GetInstanceMatrix( id );
	ex_color = vec4(entitymatrix_[0][3]) * (colorrange.y - colorrange.x) + colorrange.x;
	ex_color.a = 1.0;
	entitymatrix_[0][3]=0.0; entitymatrix_[1][3]=0.0; entitymatrix_[2][3]=0.0; entitymatrix_[3][3]=1.0;
	ex_entitymatrix = entitymatrix_;
	
	vec4 modelvertexposition = entitymatrix_ * vec4(vertex_position,1.0);
	
	//Clip planes
	if (length(clipplane0.xyz)>0.0001)
	{
		clipdistance0 = modelvertexposition.x*clipplane0.x + modelvertexposition.y*clipplane0.y + modelvertexposition.z*clipplane0.z + clipplane0.w;
	}
	else
	{
		clipdistance0 = 0.0;
	}	
	
	ex_VertexCameraPosition = vec3(camerainversematrix * modelvertexposition);
	gl_Position = projectioncameramatrix * modelvertexposition;
	
	screendir = entitymatrix_[3].xyz - cameraposition;
	
	//mat3 nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);
	//nmat = nmat * mat3(entitymatrix_[0].xyz,entitymatrix_[1].xyz,entitymatrix_[2].xyz);
	mat3 nmat = mat3(entitymatrix_);
	ex_normal = normalize(nmat * vertex_normal);	
	ex_tangent = normalize(nmat * vertex_tangent);
	ex_binormal = normalize(nmat * vertex_binormal);	
	
	ex_texcoords0 = vertex_texcoords0;
}
@OpenGL4.Fragment
#version 400
#define BFN_ENABLED 1

// modified from Shaders/Model/Diffuse+Normal+Specular

//Uniforms
uniform sampler2D texture0;		//Albedo map
uniform sampler2D texture1;		//Normal map
uniform sampler2D texture2;		//Specular map
uniform sampler2D texture4;		//Metalness map
uniform sampler2D texture3;		//Roughness map

uniform vec4 lighting_ambient;
uniform vec4 materialcolordiffuse;
uniform vec4 materialcolorspecular;
uniform samplerCube texture15;//Bfn cube map
uniform vec2 camerarange;
uniform vec2 buffersize;
uniform float camerazoom;
uniform int decalmode;
uniform float gamma = 2.2;

uniform mat4 projectioncameramatrix;
uniform vec3 cameraposition;
uniform mat3 cameranormalmatrix;
uniform mat4 camerainversematrix;

uniform bool isbackbuffer;

//extra variables for vegetation
uniform vec2 faderange;// = vec2(10.0,15.0);
in vec3 screendir;

//Inputs
in vec2 ex_texcoords0;
in vec4 ex_color;
in float ex_selectionstate;
in vec3 ex_VertexCameraPosition;
in vec3 ex_vertexPosition;
in vec3 ex_normal;
in vec3 ex_tangent;
in vec3 ex_binormal;
in float clipdistance0;


//Outputs
out vec4 fragData0;
out vec4 fragData1;
out vec4 fragData2;
out vec4 fragData3;
out vec4 fragData4;
        
vec4 srgb_to_lin(vec4 val, float _gamma)
{
        float a = 0.055;
        vec4 n_val = (val + a) * (1.0 / (1 + a));
        return pow(n_val, vec4(_gamma));
}   

vec4 lin_to_srgb(vec4 val, float _gamma)
{
        float a = 0.055;
        return (1 + a) * pow(val, vec4(1.0/ _gamma)) - a;
} 

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 ScreenPositionToWorldPosition()
{
	vec2 icoord = vec2(gl_FragCoord.xy/buffersize);
	if (isbackbuffer) icoord.y = 1.0f - icoord.y;
	float x = icoord.s * 2.0f - 1.0f;
	float y = icoord.t * 2.0f - 1.0f;
	float z = gl_FragCoord.z;
	vec4 posProj = vec4(x,y,z,1.0);
	vec4 posView = inverse(projectioncameramatrix) * posProj;
	posView /= posView.w;
	posView.xyz+=cameraposition;
	return posView;
}

float DepthToZPosition(in float depth) {
	return camerarange.x / (camerarange.y - depth * (camerarange.y - camerarange.x)) * camerarange.y;
}

void main(void)
{
	//Clip plane discard
	if (clipdistance0>0.0) discard;
	
	vec3 screencoord = vec3(((gl_FragCoord.x/buffersize.x)-0.5) * 2.0 * (buffersize.x/buffersize.y),((-gl_FragCoord.y/buffersize.y)+0.5) * 2.0,DepthToZPosition( gl_FragCoord.z ));
	screencoord.x *= screencoord.z / camerazoom;
	screencoord.y *= -screencoord.z / camerazoom;   
	vec3 nscreencoord = normalize(screencoord);
	
	float z = length(screendir); //depthToPosition(gl_FragCoord.z,camerarange);
	if (z>faderange.x)
	{
		if (z>faderange.y) discard;
		vec2 tcoord = vec2(gl_FragCoord.xy/buffersize);
		float f = rand(gl_FragCoord.xy / buffersize * 1.0 + gl_SampleID*37.45128);
		if (f>1.0-(z-faderange.x)/(faderange.y-faderange.x)) discard;
	}
	
	vec4 albedo 		= srgb_to_lin( texture(texture0,ex_texcoords0) * materialcolordiffuse, gamma);
	if (albedo.a < 0.9) { discard; }
	
	vec4 gloss 			= texture(texture3,ex_texcoords0);	
	vec4 metalness		= texture(texture4,ex_texcoords0);
	vec4 specular 		= texture(texture2,ex_texcoords0);
	
	float fmetallic 	= (metalness.r + metalness.g + metalness.b) * 0.3333333;
	float fgloss 		= (gloss.r + gloss.g  + gloss.b) * 0.3333333;
	float fspecular		= mix(0.001, 0.08, (specular.r + specular.g + specular.b) * 0.3333333);
		
	fragData0 = albedo;
	fragData2 = vec4(1-fgloss, fmetallic, 0.04, 0.0);	
	
	//Normal map
	vec3 normal = ex_normal;
	//normal = texture(texture1,ex_texcoords0).xyz * 2.0 - 1.0;
	//float ao = normal.z;
	//normal = ex_tangent*normal.x + ex_binormal*normal.y + ex_normal*normal.z;
	normal=normalize(normal);	
	
#if BFN_ENABLED==1
	//Best-fit normals
	fragData1 = texture(texture15,normalize(vec3(normal.x,-normal.y,normal.z)));
	fragData1.a = fragData0.a;
#else
	//Low-res normals
	fragData1 = vec4(normalize(normal)*0.5+0.5,fragData0.a);
#endif	
		
	int materialflags=1;
	if (ex_selectionstate>0.0) materialflags += 2;
	if (decalmode==1) materialflags += 4;//brush
	if (decalmode==2) materialflags += 8;//model
	if (decalmode==4) materialflags += 16;//terrain	
	fragData1.a = materialflags/255.0;	
		
}
