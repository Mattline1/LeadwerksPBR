SHADER version 1
@OpenGL2.Vertex
#version 400

//APPENDED_DATA

uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;

uniform vec2 offset;
uniform vec2 position[4];
uniform vec2 texcoords[4];

in vec3 vertex_position;
in vec2 vertex_texcoords0;

void main(void)

{		
	vec4 glvertex = drawmatrix * vec4(position[gl_VertexID], 0.0, 1.0);	
	gl_Position = projectionmatrix * glvertex;		
}
@OpenGLES2.Vertex

@OpenGLES2.Fragment

@OpenGL4.Vertex
#version 400

//APPENDED_DATA

uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;

uniform vec2 offset;
uniform vec2 position[4];
uniform vec2 texcoords[4];

in vec3 vertex_position;
in vec2 vertex_texcoords0;

void main(void)

{		
	vec4 glvertex = drawmatrix * vec4(position[gl_VertexID], 0.0, 1.0);	
	gl_Position = projectionmatrix * glvertex;		
}
@OpenGL4.Fragment
#version 400
#define PI 3.14159265359
#define PIRECIPROCAL 0.31830988618
#define HALFPI PI/2.0
#define QUARTPI PI/4.0

#ifndef SAMPLES
	#define SAMPLES 1
#endif

uniform sampler2DMS texture0;
uniform sampler2DMS texture1;
uniform sampler2DMS texture2;
uniform sampler2DMS texture3;
uniform sampler2DMS texture4;


uniform vec4 ambientlight;
uniform vec2 buffersize;

uniform vec2 camerarange;
uniform float camerazoom;
uniform mat3 cameranormalmatrix;

uniform bool isbackbuffer;
uniform int isReflection;
uniform int mipLevels;
uniform int showType;

in vec2 vTexCoord;
out vec4 fragData0;

float DepthToZPosition(in float depth)
{
	return camerarange.x / (camerarange.y - depth * (camerarange.y - camerarange.x)) * camerarange.y;
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
	
	//float f = float(i)/15.0; 
	float f = float(i)*0.0666667; //faster to multiply than divide
	return f;	
}

void main(void)
{
	//----------------------------------------------------------------------
	//Calculate screen texcoord
	//----------------------------------------------------------------------
	vec2 coord = gl_FragCoord.xy / buffersize;	
	if (isbackbuffer) coord.y = 1.0 - coord.y;
	
	ivec2 icoord = ivec2(gl_FragCoord.xy);
	if (isbackbuffer) icoord.y = int(buffersize.y) - icoord.y;
	
	float depth;
	vec4 albedo;
	vec4 samplenormal;		
	vec4 ambientlight;		
	vec3 normal;
	float specular;
	float metalness;
	float gloss;
	float roughnessmip;
	float specular_power;	
	vec4 specular_colour;	
	
	for (int i=0; i<SAMPLES; i++)
	{			
		vec4 diffuse_out= vec4(1.0);
					
		depth 			= texelFetch(texture0,icoord,i).x;
		albedo 			= texelFetch(texture1,icoord,i);
		samplenormal 	= texelFetch(texture2,icoord,i);	
		ambientlight 	= texelFetch(texture3,icoord,i);	
		
		normal = normalize(samplenormal.xyz*2.0-1.0);
		
		int materialflags = int(samplenormal.a * 255.0 + 0.5);
		bool uselighting = false;			 
				
		//----------------------------------------------------------------------
		//Calculate screen position and vector
		//----------------------------------------------------------------------
		vec3 screencoord = vec3(((gl_FragCoord.x/buffersize.x)-0.5) * 2.0 * (buffersize.x/buffersize.y),((-gl_FragCoord.y/buffersize.y)+0.5) * 2.0,DepthToZPosition(depth));
		screencoord.x *= screencoord.z / camerazoom;
		screencoord.y *= -screencoord.z / camerazoom;
				
		if (!isbackbuffer) screencoord.y *= -1.0;
		//----------------------------------------------------------------------
		//Calculate image based ambient term
		//----------------------------------------------------------------------
		diffuse_out = albedo;
		if ((1 & materialflags)!=0)
		{
			if (isReflection==1)
			{ 				
				float ambientattenuation = -dot(vec3(0.0, -1.0, 0.0),normal) * 0.3;
				ambientattenuation += 1;
				diffuse_out = ambientlight * ambientattenuation; 
			}
			else
			{						
				diffuse_out = vec4(ambientlight.xyz, albedo.a);
			}			
		}
		
		if (showType == 0 || showType == 5) {
			fragData0 += diffuse_out;
		}
		else if (showType == 1 ) {
			fragData0 += albedo;
		}
		
		//fragData0 += diffuse_out;		
	}	
	fragData0 /= float(SAMPLES);
	gl_FragDepth = texelFetch(texture0,icoord,0).r;
}
