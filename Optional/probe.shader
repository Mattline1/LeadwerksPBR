SHADER version 1
@OpenGL2.Vertex
#version 400

uniform mat4 projectioncameramatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec3 lightglobalposition;
uniform vec2 lightrange;
uniform mat4 entitymatrix;
uniform mat4 camerainversematrix;

in vec3 vertex_position;

out vec3 ex_aabbmin;
out vec3 ex_aabbmax;
out vec3 ex_localaabbmin;
out vec3 ex_localaabbmax;
out vec3 ex_VertexCameraPosition;

uniform float aabbpadding;

void main(void)
{
	const float padding = 0.1;
	
	vec3 scaleoffset;
	vec3 scale;
	scale.x = length(entitymatrix[0].xyz);
	scale.y = length(entitymatrix[1].xyz);
	scale.z = length(entitymatrix[2].xyz);
	
	scale.x = 1.0 + aabbpadding / scale.x * 2.0;
	scale.y = 1.0 + aabbpadding / scale.y * 2.0;
	scale.z = 1.0 + aabbpadding / scale.z * 2.0;
		
	gl_Position = projectioncameramatrix * entitymatrix * vec4(vertex_position * scale,1.0);
	ex_VertexCameraPosition = vec3(camerainversematrix * gl_Position);


	ex_aabbmin = (entitymatrix * vec4(-0.5,-0.5,-0.5,1.0)).xyz;
	ex_aabbmax = (entitymatrix * vec4(0.5,0.5,0.5,1.0)).xyz;
	ex_localaabbmin = (projectioncameramatrix * vec4(ex_aabbmin,1.0)).xyz;
	ex_localaabbmax = (projectioncameramatrix * vec4(ex_aabbmax,1.0)).xyz;
	//gl_Position = projectioncameramatrix * vec4(lightglobalposition + vertex_position * lightrange.y * 2.0,1.0);
}
@OpenGLES2.Vertex

@OpenGLES2.Fragment

@OpenGL4.Vertex
#version 400

uniform mat4 projectioncameramatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec3 lightglobalposition;
uniform vec2 lightrange;
uniform mat4 entitymatrix;
uniform mat4 camerainversematrix;

in vec3 vertex_position;

out vec3 ex_aabbmin;
out vec3 ex_aabbmax;
out vec3 ex_localaabbmin;
out vec3 ex_localaabbmax;
out vec3 ex_VertexCameraPosition;

uniform float aabbpadding;

void main(void)
{
	const float padding = 0.1;
	
	vec3 scaleoffset;
	vec3 scale;
	scale.x = length(entitymatrix[0].xyz);
	scale.y = length(entitymatrix[1].xyz);
	scale.z = length(entitymatrix[2].xyz);
	
	scale.x = 1.0 + aabbpadding / scale.x * 2.0;
	scale.y = 1.0 + aabbpadding / scale.y * 2.0;
	scale.z = 1.0 + aabbpadding / scale.z * 2.0;
		
	gl_Position = projectioncameramatrix * entitymatrix * vec4(vertex_position * scale,1.0);
	ex_VertexCameraPosition = vec3(camerainversematrix * gl_Position);


	ex_aabbmin = (entitymatrix * vec4(-0.5,-0.5,-0.5,1.0)).xyz;
	ex_aabbmax = (entitymatrix * vec4(0.5,0.5,0.5,1.0)).xyz;
	ex_localaabbmin = (projectioncameramatrix * vec4(ex_aabbmin,1.0)).xyz;
	ex_localaabbmax = (projectioncameramatrix * vec4(ex_aabbmax,1.0)).xyz;
	//gl_Position = projectioncameramatrix * vec4(lightglobalposition + vertex_position * lightrange.y * 2.0,1.0);
}
@OpenGL4.Fragment
#version 400
#ifndef SAMPLES
	#define SAMPLES 1
#endif
#define LOWERLIGHTTHRESHHOLD 0.001
#define PI 3.14159265359
#define HALFPI PI/2.0
#ifndef KERNEL
	#define KERNEL 3
#endif
#define KERNELF float(KERNEL)
#define GLOSS 10.0

#define PARALLAX_CUBEMAP 0

#define AMBIENT_ROUGHNESS 7.0
#define SPECULAR_ROUGHNESS 0

uniform vec4 lighting_ambient;

#if SAMPLES==0
	uniform sampler2D texture0;
	uniform sampler2D texture1;
	uniform sampler2D texture2;
	uniform sampler2D texture3;
	uniform sampler2D texture4;	
#else
	uniform sampler2DMS texture0;
	uniform sampler2DMS texture1;
	uniform sampler2DMS texture2;
	uniform sampler2DMS texture3;
	uniform sampler2DMS texture4;
#endif

uniform mat3 cameranormalmatrix;
uniform mat3 camerainversenormalmatrix;
uniform vec3 cameraposition;
uniform samplerCube texture5;//shadowmap
uniform vec4 ambientlight;
uniform vec2 buffersize;
uniform vec3 lightposition;
uniform vec4 lightcolor;
uniform vec4 lightspecular;
uniform vec2 lightrange;
uniform vec3 lightglobalposition;
uniform vec2 camerarange;
uniform float camerazoom;
uniform mat4 lightprojectionmatrix;
uniform mat4 lightprojectioninversematrix;
uniform mat4 projectioncameramatrix;
uniform mat4 cameramatrix;
uniform mat4 camerainversematrix;
uniform mat4 projectionmatrix;
uniform vec2 lightshadowmapoffset;
uniform mat3 lightnormalmatrix;
uniform float shadowmapsize;
uniform bool isbackbuffer;
//uniform float aabbpadding;

in vec3 ex_VertexCameraPosition;

in vec3 ex_aabbmin;
in vec3 ex_aabbmax;
in vec3 ex_localaabbmin;
in vec3 ex_localaabbmax;

out vec4 fragData0;

float depth;
vec4 diffuse;
vec3 normal;
vec4 materialdata;
float specularity;
float ao;
bool uselighting;
vec4 emission;	
vec4 sampleoutput;
vec4 stagecolor;
vec3 screencoord;
vec3 screennormal;
float attenuation;	
vec3 lightreflection;
float fade;
vec3 shadowcoord;
float dist;
vec3 offset;
vec2 sampleoffset;
vec3 lp;
vec4 normaldata;
int materialflags;

vec4 albedo;		
vec4 surfacedata;		
float specular;
float metalness;
float gloss;
float roughnessmip;
float specular_power;	
float roughness;
vec4 speccolor;
	
vec4 sample_out;	

float depthToPosition(in float depth, in vec2 depthrange)
{
	return depthrange.x / (depthrange.y - depth * (depthrange.y - depthrange.x)) * depthrange.y;
}

float positionToDepth(in float z, in vec2 depthrange) {
	return (depthrange.x / (z / depthrange.y) - depthrange.y) / -(depthrange.y - depthrange.x);
}

//function to parallax correct reflection
vec3 getBoxIntersection( vec3 pos, vec3 reflectionVector, vec3 cubeSize, vec3 cubePos )
{
        vec3 rbmax = ((cubePos-cubeSize *.5) + cubeSize - pos ) / reflectionVector;
        vec3 rbmin = ((cubePos-cubeSize *.5) - pos ) / reflectionVector;   
        
        vec3 rbminmax = vec3(
                ( reflectionVector.x > 0.0f ) ? rbmax.x : rbmin.x,
                ( reflectionVector.y > 0.0f ) ? rbmax.y : rbmin.y,
                ( reflectionVector.z > 0.0f ) ? rbmax.z : rbmin.z );
        
        float correction = min( min( rbminmax.x, rbminmax.y ), rbminmax.z );
        return ( pos + reflectionVector * abs( correction ) );
}

//Correct cubemaps
vec3 LocalCorrect(vec3 origVec, vec3 bboxMin, vec3 bboxMax, vec3 vertexPos, vec3 cubemapPos, float offset)
{
    // Find the ray intersection with box plane
    vec3 invOrigVec = vec3(1.0)/origVec;
    vec3 intersecAtMaxPlane = (bboxMax - vertexPos) * invOrigVec;
    vec3 intersecAtMinPlane = (bboxMin - vertexPos) * invOrigVec;
    // Get the largest intersection values
    // (we are not intersted in negative values)
    vec3 largestIntersec = max(intersecAtMaxPlane, intersecAtMinPlane);
    // Get the closest of all solutions
    float Distance = min(min(largestIntersec.x, largestIntersec.y),
                         largestIntersec.z);
    // Get the intersection position
    vec3 IntersectPositionWS = vertexPos + origVec * (Distance + offset);// * (length(cubemapPos-cameraposition)));
    // Get corrected vector
    vec3 localCorrectedVec = IntersectPositionWS - cubemapPos;
    return localCorrectedVec;
}

bool AABBIntersectsPoint(in vec3 aabbmin, in vec3 aabbmax, in vec3 p)
{
	if (p.x<aabbmin.x) return false;
	if (p.y<aabbmin.y) return false;
	if (p.z<aabbmin.z) return false;
	if (p.x>aabbmax.x) return false;
	if (p.y>aabbmax.y) return false;
	if (p.z>aabbmax.z) return false;		
	return true;
}

float blendaabb(float limit, float vpos, float centre, float blend)
{
	float pos 	= mix(limit, centre, blend);
	float dif 	= vpos - pos;
	float range = limit - pos;
				
	return ( 1.0 - (dif / range) );		
}

vec4 F_Schlick(vec4 f0, float fd90, float u ) 
{
	return f0 + ( fd90 - f0 ) * pow (1.0f - u , 5.0f);
}

vec4 F_Schlick_Roughness(vec4 f0, float fd90, float alpha, float u ) 
{
	vec4 f90 = max(vec4(1-alpha), f0); 
	
	//return f0 + ( f90 - f0 ) * pow (1.0f - u , 5.0f);
	
	return f0 + ( f90 - f0 ) * pow (1.0f - u , 5.0f);
}

float V_SmithsGGX(float alpha, float n_dot_l, float n_dot_v)
{
	float k = 2.f/alpha;
	float G_l = (n_dot_l * (1.0f - k) + k);
	float G_v = (n_dot_v * (1.0f - k) + k);
	
	return 1.0f / G_l*G_v;
}

float D_GGX(float alpha, float n_dot_h)
{
	float alphaSqr = alpha*alpha;
	float denom = n_dot_h * n_dot_h *(alphaSqr-1.0) + 1.0f;
	return alphaSqr/(PI * denom * denom);
}

vec4 Fd_DisneyDiffuse(vec4 f0, float n_dot_l, float n_dot_v, float l_dot_h, float gloss)
{
	float Bias = mix(0.0f , 0.5f , gloss);
	float Factor = mix(1.0f , 1.0f / 1.51f , gloss);
	float fd90 = Bias + 2.0f * l_dot_h * l_dot_h * gloss;
				
	vec4 Fl = 	F_Schlick(f0, fd90, n_dot_l);
	vec4 Fv = 	F_Schlick(f0, fd90, n_dot_v);						
	return Fl * Fv * Factor;

}

void main(void)
{
	vec3 flipcoord = vec3(1.0);	
	vec2 coord = gl_FragCoord.xy / buffersize;
	ivec2 icoord = ivec2(gl_FragCoord.xy);	
	
	if (!isbackbuffer) 
	{ 
		flipcoord.y = -1.0; 
	}
	else 
	{
		coord.y = 1.0 - coord.y;
		icoord.y = int(buffersize.y) - icoord.y;
	}

	float aabbpadding = length(lightspecular);
	//AABB
	float aabbf=lightrange.y;
	vec3 aabbmin=lightglobalposition+vec3(-aabbf,-aabbf,-aabbf);
	vec3 aabbmax=lightglobalposition+vec3(aabbf,aabbf,aabbf);

	for (int i=0; i<max(1,SAMPLES); i++)
	{
		//----------------------------------------------------------------------
		//Retrieve data from gbuffer
		//----------------------------------------------------------------------
#if SAMPLES==0
		depth = 		texture(texture0,coord).x;
		albedo = 		texture(texture1,coord);
		normaldata =	texture(texture2,coord);
		surfacedata = 	texture(texture3,coord);
#else
		depth = 		texelFetch(texture0,icoord,i).x;
		albedo = 		texelFetch(texture1,icoord,i);
		normaldata =	texelFetch(texture2,icoord,i);
		surfacedata = 	texelFetch(texture3,icoord,i);		
#endif
		materialflags = int(normaldata.a * 255.0 + 0.5);
		sample_out = 	albedo;
		
		screencoord = vec3(((gl_FragCoord.x/buffersize.x)-0.5) * 2.0 * (buffersize.x/buffersize.y),((-gl_FragCoord.y/buffersize.y)+0.5) * 2.0,depthToPosition(depth,camerarange));
		screencoord.x *= screencoord.z / camerazoom;
		screencoord.y *= -screencoord.z / camerazoom;		
		screennormal = normalize(screencoord) * flipcoord;		
		screencoord *= flipcoord;

		if ((1 & materialflags)!=0)
		{		
			//get vertex positions for local correction
			vec3 vpos = (cameramatrix * vec4(screencoord,1)).xyz;
			
			if (AABBIntersectsPoint(ex_aabbmin,ex_aabbmax,vpos))
			{
				specular 	= surfacedata.b;				
				gloss 		= surfacedata.r;
				metalness 	= 1 - surfacedata.g;				
				speccolor 	= mix(albedo, vec4(specular), metalness) * lightcolor;
				
				float alpha = max(0.001, 1-pow(gloss, 4));	
				int mip 	= int(mix(0.0, AMBIENT_ROUGHNESS, alpha));
				
				/////				
				
				//Distance attenuation
				float aabbblend = mix(0.6, 1.0, length(lightspecular)/16);
												
				float attenuation = blendaabb(ex_aabbmax.z, vpos.z, lightglobalposition.z, aabbblend);	
				attenuation *= blendaabb(ex_aabbmax.y, vpos.y, lightglobalposition.y, aabbblend);
				attenuation *= blendaabb(ex_aabbmax.x, vpos.x, lightglobalposition.x, aabbblend);
				attenuation *= blendaabb(ex_aabbmin.z, vpos.z, lightglobalposition.z, aabbblend);
				attenuation *= blendaabb(ex_aabbmin.y, vpos.y, lightglobalposition.y, aabbblend);
				attenuation *= blendaabb(ex_aabbmin.x, vpos.x, lightglobalposition.x, aabbblend);
				attenuation = clamp(attenuation, 0.0, 1.0); 
												
				vec3 n 				= camerainversenormalmatrix * normalize(normaldata.xyz*2.0-1.0);	
				vec3 l 				= normalize(-n);	
				vec3 h 				= normalize(l + screennormal);
				
				float n_dot_l 		= clamp(-dot(l, n), 0.0, 1.0);
				float n_dot_v 		= clamp(-dot(n, screennormal), 0.0, 1.0);
				float n_dot_h 		= clamp(-dot(n, h), 0.0, 1.0);
				float l_dot_h 		= clamp( dot(l, h), 0.0, 1.0);
			
			//	Specular - BRDF
				l 					= -normalize(reflect(screencoord, n));
				shadowcoord 		= lightnormalmatrix * -l;
#if PARALLAX_CUBEMAP==1
				shadowcoord=LocalCorrect(shadowcoord,ex_aabbmin,ex_aabbmax,vpos,vec3(lightglobalposition),0.0f);
#endif
				h 					= normalize(l + screennormal);				
				l_dot_h 			= clamp( dot(l, h), 0.0, 1.0);
								
				vec4 D 				= textureLod(texture5, shadowcoord, mip);				
				//float V 			= V_SmithsGGX(alpha, n_dot_l, n_dot_v); // no noticeable effect on final image								
				vec4  F  			= F_Schlick_Roughness(speccolor, 1.0f, 1-gloss, l_dot_h);				
				vec4  Fr			= D * F;
			
			
			// Diffuse - BRDF
				vec4 Kd 			= vec4(1.0) - F;
				vec4 ambient 		= textureLod(texture5, lightnormalmatrix * n, AMBIENT_ROUGHNESS);
				vec4 Fd 			= Fd_DisneyDiffuse(ambient * lightcolor, n_dot_l, n_dot_v, l_dot_h, gloss);
					 Fd 			*= Kd * albedo * metalness;	
				
				fragData0 	+= (Fd + Fr) * attenuation;				
			}
#if SAMPLES<2
			else
			{
				discard;
			}
#endif
		}
	}
	fragData0 /= max(1,SAMPLES);	
}
