SHADER version 1
@OpenGL2.Vertex
#version 400
#define MAX_BONES 256
//OpenGL 4.0 pg 371 MAX_UNIFORM_BLOCK_SIZE = 16384 / 64 = 256 bones

//Uniforms
uniform mat4 entitymatrix;
uniform vec4 materialcolordiffuse;
uniform mat4 projectioncameramatrix;
uniform mat4 camerainversematrix;
uniform bonematrices { mat4 matrix[MAX_BONES];} bone;
uniform vec4 clipplane0 = vec4(0.0);

//Attributes
in vec3 vertex_position;
in vec4 vertex_color;
in vec2 vertex_texcoords0;
in vec3 vertex_normal;
in vec3 vertex_binormal;
in vec3 vertex_tangent;
in vec4 vertex_boneweights;
in ivec4 vertex_boneindices;

//Outputs
out vec4 ex_color;
out vec2 ex_texcoords0;
out float ex_selectionstate;
out vec3 ex_VertexCameraPosition;
out vec3 ex_normal;
out vec3 ex_tangent;
out vec3 ex_binormal;
out float clipdistance0;

void main()
{
	mat4 entitymatrix_=entitymatrix;
	entitymatrix_[0][3]=0.0;
	entitymatrix_[1][3]=0.0;
	entitymatrix_[2][3]=0.0;
	entitymatrix_[3][3]=1.0;

	vec4 wt = vertex_boneweights;
	float m = wt[0]+wt[1]+wt[2]+wt[3];
	wt[0]/=m; wt[1]/=m; wt[2]/=m; wt[3]/=m;
	
	mat4 animmatrix = bone.matrix[vertex_boneindices[0]] * wt[0];
	animmatrix += bone.matrix[vertex_boneindices[1]] * wt[1];
	animmatrix += bone.matrix[vertex_boneindices[2]] * wt[2];
	animmatrix += bone.matrix[vertex_boneindices[3]] * wt[3];	
	
	animmatrix[0][3]=0.0;
	animmatrix[1][3]=0.0;
	animmatrix[2][3]=0.0;
	animmatrix[3][3]=1.0;
	
	entitymatrix_ *= animmatrix;
	
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
	
	//mat3 nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);//39
	mat3 nmat = mat3(entitymatrix_[0].xyz,entitymatrix_[1].xyz,entitymatrix_[2].xyz);//40
	ex_normal = normalize(nmat * vertex_normal);	
	ex_tangent = normalize(nmat * vertex_tangent);
	ex_binormal = normalize(nmat * vertex_binormal);
	
	ex_texcoords0 = vertex_texcoords0;
	
	ex_color = vec4(entitymatrix[0][3],entitymatrix[1][3],entitymatrix[2][3],entitymatrix[3][3]);
	
	//ex_color = vec4(vertex_boneindices[0]) * 60.0;
	//If an object is selected, 10 is subtracted from the alpha color.
	//This is a bit of a hack that packs a per-object boolean into the alpha value.
	ex_selectionstate = 0.0;
	if (ex_color.a<-5.0)
	{
		ex_color.a += 10.0;
		ex_selectionstate = 1.0;
	}
	ex_color *= vec4(1.0-vertex_color.r,1.0-vertex_color.g,1.0-vertex_color.b,vertex_color.a) * materialcolordiffuse;
}
@OpenGLES2.Vertex

@OpenGLES2.Fragment

@OpenGL4.Vertex
#version 400
#define MAX_BONES 256
//OpenGL 4.0 pg 371 MAX_UNIFORM_BLOCK_SIZE = 16384 / 64 = 256 bones

//Uniforms
uniform mat4 entitymatrix;
uniform vec4 materialcolordiffuse;
uniform mat4 projectioncameramatrix;
uniform mat4 camerainversematrix;
uniform bonematrices { mat4 matrix[MAX_BONES];} bone;
uniform vec4 clipplane0 = vec4(0.0);

//Attributes
in vec3 vertex_position;
in vec4 vertex_color;
in vec2 vertex_texcoords0;
in vec3 vertex_normal;
in vec3 vertex_binormal;
in vec3 vertex_tangent;
in vec4 vertex_boneweights;
in ivec4 vertex_boneindices;

//Outputs
out vec4 ex_color;
out vec2 ex_texcoords0;
out float ex_selectionstate;
out vec3 ex_VertexCameraPosition;
out vec3 ex_normal;
out vec3 ex_tangent;
out vec3 ex_binormal;
out float clipdistance0;

void main()
{
	mat4 entitymatrix_=entitymatrix;
	entitymatrix_[0][3]=0.0;
	entitymatrix_[1][3]=0.0;
	entitymatrix_[2][3]=0.0;
	entitymatrix_[3][3]=1.0;

	vec4 wt = vertex_boneweights;
	float m = wt[0]+wt[1]+wt[2]+wt[3];
	wt[0]/=m; wt[1]/=m; wt[2]/=m; wt[3]/=m;
	
	mat4 animmatrix = bone.matrix[vertex_boneindices[0]] * wt[0];
	animmatrix += bone.matrix[vertex_boneindices[1]] * wt[1];
	animmatrix += bone.matrix[vertex_boneindices[2]] * wt[2];
	animmatrix += bone.matrix[vertex_boneindices[3]] * wt[3];	
	
	animmatrix[0][3]=0.0;
	animmatrix[1][3]=0.0;
	animmatrix[2][3]=0.0;
	animmatrix[3][3]=1.0;
	
	entitymatrix_ *= animmatrix;
	
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
	
	//mat3 nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);//39
	mat3 nmat = mat3(entitymatrix_[0].xyz,entitymatrix_[1].xyz,entitymatrix_[2].xyz);//40
	ex_normal = normalize(nmat * vertex_normal);	
	ex_tangent = normalize(nmat * vertex_tangent);
	ex_binormal = normalize(nmat * vertex_binormal);
	
	ex_texcoords0 = vertex_texcoords0;
	
	ex_color = vec4(entitymatrix[0][3],entitymatrix[1][3],entitymatrix[2][3],entitymatrix[3][3]);
	
	//ex_color = vec4(vertex_boneindices[0]) * 60.0;
	//If an object is selected, 10 is subtracted from the alpha color.
	//This is a bit of a hack that packs a per-object boolean into the alpha value.
	ex_selectionstate = 0.0;
	if (ex_color.a<-5.0)
	{
		ex_color.a += 10.0;
		ex_selectionstate = 1.0;
	}
	ex_color *= vec4(1.0-vertex_color.r,1.0-vertex_color.g,1.0-vertex_color.b,vertex_color.a) * materialcolordiffuse;
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
	
	vec4 albedo 		= srgb_to_lin( texture(texture0,ex_texcoords0) * materialcolordiffuse, gamma);
	if (albedo.a < 0.9) { discard; }
	
	vec4 gloss 			= texture(texture3,ex_texcoords0);	
	vec4 metalness		= texture(texture4,ex_texcoords0);
	//vec4 specular 		= texture(texture2,ex_texcoords0);
	
	float fmetallic 	= (metalness.r + metalness.g + metalness.b) * 0.3333333;
	float fgloss 		= (gloss.r + gloss.g  + gloss.b) * 0.3333333;
	//float fspecular		= mix(0.001, 0.08, (metalness.r + metalness.g + metalness.b) * 0.3333333);
		
	fragData0 = albedo;
	fragData2 = vec4(1-fgloss, fmetallic, 0.04, 0.0);	
					
	
	vec3 normal = ex_normal;	
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
