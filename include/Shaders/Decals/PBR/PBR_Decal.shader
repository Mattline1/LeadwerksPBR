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
in vec3 vertex_normal;
in vec3 vertex_binormal;
in vec3 vertex_tangent;
in vec2 vertex_texcoords0;

//Outputs
out mat3 nmat;
out float ex_selectionstate;
out vec3 modelposition;
out vec4 vColor;
out float clipdistance0;
out vec2 vTexCoords0;
out mat4 inversemodelmatrix;

void main()
{
	mat4 entitymatrix = entity.matrix[gl_InstanceID];
	mat4 entitymatrix_=entitymatrix;
	entitymatrix_[0][3]=0.0; entitymatrix_[1][3]=0.0; entitymatrix_[2][3]=0.0; entitymatrix_[3][3]=1.0;
	
	inversemodelmatrix = inverse(entitymatrix_);
	modelposition = entitymatrix_[3].xyz;
	
	vColor = vec4(entitymatrix[0][3],entitymatrix[1][3],entitymatrix[2][3],entitymatrix[3][3]);
	
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
	
	gl_Position = projectioncameramatrix * modelvertexposition;
	
	//nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);
	//nmat = nmat * mat3(entitymatrix[0].xyz,entitymatrix[1].xyz,entitymatrix[2].xyz);
	nmat = mat3(entitymatrix);
	vTexCoords0 = vertex_texcoords0;
	
	//If an object is selected, 10 is subtracted from the alpha color.
	//This is a bit of a hack that packs a per-object boolean into the alpha value.
	ex_selectionstate = 0.0;
	if (vColor.a<-5.0)
	{
		vColor.a += 10.0;
		ex_selectionstate = 1.0;
	}
	vColor *= vec4(1.0-vertex_color.r,1.0-vertex_color.g,1.0-vertex_color.b,vertex_color.a) * materialcolordiffuse;
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
in vec3 vertex_normal;
in vec3 vertex_binormal;
in vec3 vertex_tangent;
in vec2 vertex_texcoords0;

//Outputs
out mat3 nmat;
out float ex_selectionstate;
out vec3 modelposition;
out vec4 vColor;
out float clipdistance0;
out vec2 vTexCoords0;
out mat4 inversemodelmatrix;

void main()
{
	mat4 entitymatrix = entity.matrix[gl_InstanceID];
	mat4 entitymatrix_=entitymatrix;
	entitymatrix_[0][3]=0.0; entitymatrix_[1][3]=0.0; entitymatrix_[2][3]=0.0; entitymatrix_[3][3]=1.0;
	
	inversemodelmatrix = inverse(entitymatrix_);
	modelposition = entitymatrix_[3].xyz;
	
	vColor = vec4(entitymatrix[0][3],entitymatrix[1][3],entitymatrix[2][3],entitymatrix[3][3]);
	
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
	
	gl_Position = projectioncameramatrix * modelvertexposition;
	
	//nmat = mat3(camerainversematrix[0].xyz,camerainversematrix[1].xyz,camerainversematrix[2].xyz);
	//nmat = nmat * mat3(entitymatrix[0].xyz,entitymatrix[1].xyz,entitymatrix[2].xyz);
	nmat = mat3(entitymatrix);
	vTexCoords0 = vertex_texcoords0;
	
	//If an object is selected, 10 is subtracted from the alpha color.
	//This is a bit of a hack that packs a per-object boolean into the alpha value.
	ex_selectionstate = 0.0;
	if (vColor.a<-5.0)
	{
		vColor.a += 10.0;
		ex_selectionstate = 1.0;
	}
	vColor *= vec4(1.0-vertex_color.r,1.0-vertex_color.g,1.0-vertex_color.b,vertex_color.a) * materialcolordiffuse;
}
@OpenGL4.Fragment
#version 400
#define BFN_ENABLED 1

//Uniforms	
uniform vec2 buffersize;
uniform vec4 materialcolorspecular;
uniform samplerCube texture15;

uniform sampler2D texture0;		//Albedo map
uniform sampler2D texture1;		//Normal map
uniform sampler2D texture2;		//Specular map
uniform sampler2D texture4;		//Metalness map
uniform sampler2D texture3;		//Roughness map

//MSAA textures
uniform sampler2DMS texture6;// depth
uniform sampler2DMS texture7;// normal

uniform bool isbackbuffer;
uniform mat4 projectioncameramatrix;
uniform vec3 cameraposition;
uniform vec4 materialcolordiffuse;
uniform int RenderMode;

//Inputs
in float ex_selectionstate;
in vec4 vColor;
in mat4 inversemodelmatrix;
in vec3 modelposition;
in mat3 nmat;

//Outputs
out vec4 fragData0;
out vec4 fragData1;
out vec4 fragData2;
out vec4 fragData3;

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

float depthToPosition(in float depth, in vec2 depthrange)
{
	return depthrange.x / (depthrange.y - depth * (depthrange.y - depthrange.x)) * depthrange.y;
}

vec4 ScreenPositionToWorldPosition(in vec2 texCoord)
{
        float x = (texCoord.s / buffersize.x - 0.5) * 2.0;
        float y = (texCoord.t / buffersize.y - 0.5) * 2.0;
		float z;
		z = texelFetch(texture6, ivec2(texCoord),gl_SampleID).r;
		z = z / 0.5 - 1.0;
        vec4 posProj = vec4(x,y,z,1.0);
        vec4 posView = inverse(projectioncameramatrix) * posProj;
        posView /= posView.w;
        return posView;
}

int getMajorAxis(in vec3 v)
{
	vec3 b = abs(v);
	if (b.x>b.y)
	{
		if (b.x>b.z)
		{
			return 0;
		}
		else
		{
			return 2;
		}
	}
	else
	{
		if (b.y>b.z)
		{
			return 1;
		}
		else
		{
			return 2;
		}
	}
}

void main(void)
{
	vec3 normal;
	vec4 normaldata;	
	float depth;
	vec3 screencoord;
	vec4 worldcoord;
	vec4 worldpos;
	vec2 tc;
	vec4 emission = vec4(0,0,0,0);
	vec3 ex_normal;
	vec3 ex_binormal;
	vec3 ex_tangent;
	vec3 blendednormal;
	vec3 screennormal;
	vec3 worldnormal;
	float blendedspecular;
	ivec2 icoord = ivec2(gl_FragCoord.xy);
	if (isbackbuffer) icoord.y = int(buffersize.y) - icoord.y;
	
	depth = texelFetch(texture6, icoord,gl_SampleID).r;
	worldcoord = vec4(gl_FragCoord.x/buffersize.x,-gl_FragCoord.y/buffersize.y,depth,gl_FragCoord.w);
	worldcoord = inverse(projectioncameramatrix)*worldcoord;
	screencoord=worldcoord.xyz;
	worldpos = ScreenPositionToWorldPosition(gl_FragCoord.xy);
	screencoord = (inversemodelmatrix * worldpos).xyz;
	
	if (screencoord.x<-0.5) discard;
	if (screencoord.x>0.5) discard;
	if (screencoord.y<-0.5) discard;
	if (screencoord.y>0.5) discard;
	if (screencoord.z<-0.5) discard;
	if (screencoord.z>0.5) discard;
	
	normaldata = texelFetch(texture7, icoord,gl_SampleID);
	
	int materialflags = int(normaldata.a * 255.0 + 0.5);

	//Filter
	bool draw = false;
	if ((1 & RenderMode)!=0)//Brushes
	{
		if ((4 & materialflags)!=0) draw=true;
	}
	if ((2 & RenderMode)!=0)//Models
	{
		if ((8 & materialflags)!=0) draw=true;
	}
	if ((4 & RenderMode)!=0)//Terrain
	{
		if ((16 & materialflags)!=0) draw=true;
	}	
	if (!draw) discard;
	
	screennormal = normalize(normaldata.xyz*2.0-1.0);
	worldnormal = inverse(nmat) * screennormal;
	
	switch (getMajorAxis(worldnormal))
	{
	case 0:
		tc=vec2(sign(worldnormal.x)*1.0,-1.0)*screencoord.zy-0.5;
		break;
	case 1:
		tc=vec2(sign(worldnormal.y)*1.0,-1.0)*screencoord.xz-0.5;
		break;
	default:
		tc=vec2(sign(worldnormal.z)*-1.0,-1.0)*screencoord.xy-0.5;
		break;			
	}
	
	tc = mod(tc,1.0);
	
	vec4 albedo 		= srgb_to_lin( texture(texture0,tc) * materialcolordiffuse, 2.2);
	vec4 gloss 			= texture(texture3,tc);	
	vec4 metalness		= texture(texture4,tc);
	//vec4 specular 		= vec4(0.04);
	
	float fmetallic 	= (metalness.r + metalness.g + metalness.b) * 0.3333333;
	float fgloss 		= (gloss.r + gloss.g  + gloss.b) * 0.3333333;
	//float fspecular		= mix(0.001, 0.08, (metalness.r + metalness.g + metalness.b) * 0.3333333);
		
	fragData0 = albedo * materialcolordiffuse * vColor;
	fragData2 = vec4(1-fgloss, fmetallic, 0.04, albedo.a);	
	
	if (ex_selectionstate>0.0)
	{
		fragData0.xyz = (fragData0.xyz + vec3(1,0,0)) * 0.5;
	}
	fragData1 = normaldata;
	fragData2 = vec4(emission.rgb,fragData0.a);
}
