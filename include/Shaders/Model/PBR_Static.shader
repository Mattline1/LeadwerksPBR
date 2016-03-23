SHADER version 1
@OpenGL2.Vertex
#version 400
#define MAX_INSTANCES 256

//Uniforms
uniform vec4 materialcolordiffuse;
uniform mat4 projectioncameramatrix;
uniform mat4 camerainversematrix;
uniform instancematrices { mat4 matrix[MAX_INSTANCES];} entity;
uniform vec4 clipplane0 = vec4(0.0);

//Attributes
in vec3 vertex_position;
in vec4 vertex_color;
in vec2 vertex_texcoords0;
in vec3 vertex_normal;
in vec3 vertex_binormal;
in vec3 vertex_tangent;
//in vec4 vertex_boneweights;
//in ivec4 vertex_boneindices;

//Outputs
out vec4 ex_color;
out vec2 ex_texcoords0;
out float ex_selectionstate;

out vec3 ex_VertexCameraPosition;
out vec3  ex_vertexPosition;

out vec3 ex_normal;
out vec3 ex_tangent;
out vec3 ex_binormal;
out float clipdistance0;

void main()
{
	mat4 entitymatrix = entity.matrix[gl_InstanceID];
	mat4 entitymatrix_=entitymatrix;
	entitymatrix_[0][3]=0.0;
	entitymatrix_[1][3]=0.0;
	entitymatrix_[2][3]=0.0;
	entitymatrix_[3][3]=1.0;
	
	vec4 modelvertexposition = entitymatrix_ * vec4(vertex_position,1.0);
	ex_vertexPosition = modelvertexposition.xyz;
	
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

	mat3 nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);//39
	nmat = nmat * mat3(entitymatrix[0].xyz,entitymatrix[1].xyz,entitymatrix[2].xyz);//40
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
#define MAX_INSTANCES 256

//Uniforms
uniform vec4 materialcolordiffuse;
uniform mat4 projectioncameramatrix;
uniform mat4 camerainversematrix;
uniform instancematrices { mat4 matrix[MAX_INSTANCES];} entity;
uniform vec4 clipplane0 = vec4(0.0);

//Attributes
in vec3 vertex_position;
in vec4 vertex_color;
in vec2 vertex_texcoords0;
in vec3 vertex_normal;
in vec3 vertex_binormal;
in vec3 vertex_tangent;
//in vec4 vertex_boneweights;
//in ivec4 vertex_boneindices;

//Outputs
out vec4 ex_color;
out vec2 ex_texcoords0;
out float ex_selectionstate;

out vec3 ex_VertexCameraPosition;
out vec3  ex_vertexPosition;

out vec3 ex_normal;
out vec3 ex_tangent;
out vec3 ex_binormal;
out float clipdistance0;

void main()
{
	mat4 entitymatrix = entity.matrix[gl_InstanceID];
	mat4 entitymatrix_=entitymatrix;
	entitymatrix_[0][3]=0.0;
	entitymatrix_[1][3]=0.0;
	entitymatrix_[2][3]=0.0;
	entitymatrix_[3][3]=1.0;
	
	vec4 modelvertexposition = entitymatrix_ * vec4(vertex_position,1.0);
	ex_vertexPosition = modelvertexposition.xyz;
	
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

	mat3 nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);//39
	nmat = nmat * mat3(entitymatrix[0].xyz,entitymatrix[1].xyz,entitymatrix[2].xyz);//40
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
uniform sampler2D texture0;//ALbedo map
uniform sampler2D texture1;//Normal map
uniform sampler2D texture2;//Roughness map
//uniform sampler2D texture3;//Height map
uniform sampler2D texture4;//Metalness map
uniform samplerCube texture7;//ENV map

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
uniform bool isReflection;

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

bool[4] FloatTo4BitGray(float val)
{
	val = clamp(val, 0.0, 1.0);
	int i = int(val * 16 + 0.01);
	//i = floatBitsToUint(val);
	
	bool[4] bitsout;
	int _bit = 0;	
	//8bit
	_bit = clamp(i - 8, 0, 1);	
	bitsout[3] = bool(_bit);
	i -= 8*_bit;	
	//4bit	 
	_bit = clamp(i - 4, 0, 1);
	bitsout[2] = bool(_bit);
	i -= 4*_bit;	
	//2bit	
	_bit = clamp(i - 2, 0, 1);
	bitsout[1] =  bool(_bit);
	i-= 2*_bit;	
	
	bitsout[0] = bool(clamp(i - 1, 0, 1));		
	return bitsout;
}

float Bit4GrayToFloat(bool[4] bits)
{
	int i = 0;
	
	i += int(int(bits[0]));	
	i += int(int(bits[1])*2);
	i += int(int(bits[2])*4); 
	i += int(int(bits[3])*8); 
		
	
	float f = float(i)/15.0;
	return f;	
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
	
	vec4 albedo = texture(texture0,ex_texcoords0); 
	float fmetallic;
	
	if (isReflection)
	{
		vec3 worldnormal = normalize(cameranormalmatrix * ex_normal);
		vec4 ambient = textureLod(texture7, worldnormal, 11);	
			
		fragData0 = albedo;	
		fragData2 = vec4(ambient.xyz, 0.0);	
	
		fragData1 = vec4(normalize(ex_normal)*0.5+0.5,fragData0.a);
	}
	else
	{
		vec4 gloss = texture(texture2,ex_texcoords0);	
		vec4 metalness= texture(texture4,ex_texcoords0);	
		
		albedo = srgb_to_lin(albedo * materialcolordiffuse, gamma);	
		fmetallic = metalness.r + metalness.g + metalness.b;
		fmetallic *= 0.3333333;
		float invmetallic = 1-fmetallic;
		float fgloss = gloss.r + gloss.g  + gloss.b;	
		fgloss *= 0.3333333;			
					
		//Normal map
		vec3 normal = ex_normal;
		normal = texture(texture1,ex_texcoords0).xyz * 2.0 - 1.0;
		float ao = normal.z;
		normal = ex_tangent*normal.x + ex_binormal*normal.y + ex_normal*normal.z;	
		normal=normalize(normal);
			
		//Calculate Ambient lighting
		// ambient_diffuse_out = albedo.xyz;	
		// ambient_specular_out = vec3(0.0);	
		//
		// specular 
		//
		// roughnessmip 
		//
		// specular_power //
		// - roughness of the surface
		//
		// specular_colour
		// self explanatory name, is a blend of the specular intensity & albedo based on metalness
		//
		// roughnessmip //		
		// this assumes 7 mipmap levels 128*128 
		// Mipmaps are generated at runtime, so blurring with exact values isn't possible
		// this calculation matches the generated mipmaps as closely as possible to the specular lobes
		vec3 ambient_diffuse_out = vec3(0.0);	
		vec3 ambient_specular_out = vec3(0.0);	
		
		float specular 			= 0.04;				
		float roughnessmip 		= 7 - (fgloss * 7);				
		float specular_power  	= exp2(10 * fgloss + 1); //from remember me implementation
		vec3  specular_colour 	= mix(albedo.xyz, vec3(specular), invmetallic);		
		
		vec3 eyeNormal 		= normalize( ex_vertexPosition - cameraposition );	
		vec3 worldnormal 	= normalize(cameranormalmatrix * normal);
		vec3 reflectvec 	= normalize(reflect(ex_VertexCameraPosition, normal));
		vec3 cubecoord 		= cameranormalmatrix * reflectvec;	
				
		ambient_diffuse_out = textureLod(texture7, worldnormal, 11).xyz;	
		ambient_diffuse_out *= invmetallic;
						
		ambient_specular_out = textureLod(texture7, cubecoord, roughnessmip).xyz;	
		float exponent = pow(1.0f - clamp(dot(normal, reflectvec), 0.0, 1.0), 5.0f);		
		vec3 fresnel_term = specular_colour + (1.0f - max(1.0 - vec3(fgloss*fgloss), specular_colour)) * exponent;
		
		//fresnel_term = clamp(fresnel_term, 0.0, 1.0);
		
		vec3 selectionColour = vec3(clamp(ex_selectionstate, 0.0, 1.0), 0.0, 0.0);
		ambient_specular_out =  ambient_specular_out * fresnel_term + selectionColour;
		
		ambient_diffuse_out *= albedo.xyz;
		ambient_diffuse_out += ambient_specular_out + selectionColour;
		
		fragData0 = albedo;	
		fragData2 = vec4(ambient_diffuse_out, fgloss);			
		
	#if BFN_ENABLED==1
		//Best-fit normals
		fragData1 = texture(texture15,normalize(vec3(normal.x,-normal.y,normal.z)));
	#else
		//Low-res normals
		fragData1 = vec4(normalize(normal)*0.5+0.5,fragData0.a);
	#endif	
	}
	
	//set material flags
	int materialflags=1;	
	//if (ex_selectionstate>0.0) materialflags += 2; <--selection colour is included in ambient light
	if (decalmode==1) materialflags += 2;//brush
	if (decalmode==2) materialflags += 4;//model	
	if (decalmode==4) materialflags += 8;//terrain
	
	// encode metalness into a 4 bit grayscale image
	bool[4] mBits = FloatTo4BitGray(fmetallic);
	
	//if (int(fmetallic + 0.5)) materialflags += 16;
	if (mBits[0]) materialflags += 16;
	if (mBits[1]) materialflags += 32;
	if (mBits[2]) materialflags += 64;
	if (mBits[3]) materialflags += 128;
	
	fragData1.a = materialflags/255.0;	
		
}
