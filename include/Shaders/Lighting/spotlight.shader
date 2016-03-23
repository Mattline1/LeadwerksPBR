SHADER version 1
@OpenGL2.Vertex
#version 400

uniform mat4 projectioncameramatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec3 lightglobalposition;
uniform vec2 lightrange;
uniform vec2 lightconeangles;
uniform mat4 entitymatrix;

in vec3 vertex_position;

out vec4 vertexposition;

void main(void)
{
	gl_Position = projectioncameramatrix * entitymatrix * vec4(vertex_position,1.0);
	/*
	vec3 position = vertex_position;
	position.x *= lightrange.y * tan(lightconeangles[1]);
	position.y *= lightrange.y;
	position.z *= lightrange.y * tan(lightconeangles[1]);
	gl_Position = projectioncameramatrix * vec4(lightglobalposition + position,1.0);*/
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
uniform vec2 lightconeangles;
uniform mat4 entitymatrix;

in vec3 vertex_position;

out vec4 vertexposition;

void main(void)
{
	gl_Position = projectioncameramatrix * entitymatrix * vec4(vertex_position,1.0);
	/*
	vec3 position = vertex_position;
	position.x *= lightrange.y * tan(lightconeangles[1]);
	position.y *= lightrange.y;
	position.z *= lightrange.y * tan(lightconeangles[1]);
	gl_Position = projectioncameramatrix * vec4(lightglobalposition + position,1.0);*/
}
@OpenGL4.Fragment
#version 400
#ifndef SAMPLES
	#define SAMPLES 1
#endif
#define PI 3.14159265359
#define PIRECIPROCAL 0.31830988618
#define HALFPI PI/2.0
#define QUARTPI PI/4.0
#define LOWERLIGHTTHRESHHOLD 0.001
#ifndef KERNEL
	#define KERNEL 3
#endif
#define KERNELF float(KERNEL)
#define GLOSS 10.0

uniform sampler2DMS texture0;
uniform sampler2DMS texture1;
uniform sampler2DMS texture2;
uniform sampler2DMS texture3;
uniform sampler2DMS texture4;
uniform sampler2DShadow texture5;//shadowmap
uniform vec2 lightconeangles;
uniform vec2 lightconeanglescos;
uniform vec4 ambientlight;
uniform vec2 buffersize;

uniform vec3 lightposition;
uniform vec3 lightdirection;
uniform vec4 lightcolor;
uniform vec4 lightspecular;
uniform vec2 lightrange;

uniform vec2 camerarange;
uniform float camerazoom;
uniform float shadowmapsize;
uniform mat4 lightprojectioncamerainversematrix;
uniform mat3 lightnormalmatrix;
uniform vec2 lightshadowmapoffset;
uniform float shadowsoftness;
uniform bool isbackbuffer;

uniform int isReflection;
uniform int showType;

in vec4 vertexposition;

out vec4 fragData0;

float depthToPosition(in float depth, in vec2 depthrange)
{
	return depthrange.x / (depthrange.y - depth * (depthrange.y - depthrange.x)) * depthrange.y;
}

float positionToDepth(in float z, in vec2 depthrange) {
	return (depthrange.x / (z / depthrange.y) - depthrange.y) / -(depthrange.y - depthrange.x);
}

float shadowLookup(in sampler2DShadow shadowmap, in vec3 shadowcoord, in float offset)
{
	float f=0.0;
	const float cornerdamping = 0.7071067;
	int x,y;
	vec2 sampleoffset;
	
	for (x=0; x<KERNEL; ++x)
	{
		sampleoffset.x = float(x) - KERNELF*0.5 + 0.5;
		for (y=0; y<KERNEL; ++y)
		{
			sampleoffset.y = float(y) - KERNELF*0.5 + 0.5;
			f += texture(shadowmap,vec3(shadowcoord.x+x*offset,shadowcoord.y+y*offset,shadowcoord.z));
		}
	}
	return f/(KERNEL*KERNEL);
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
	
	float depth;		
	vec3 screencoord;
	vec3 screennormal;
	float attenuation;
	float distanceattenuation;
	int materialflags;	
	
	vec3 lightvector;
	vec3 lightnormal;
	float lightdistance;
	vec4 PIlightcolor = lightcolor*PI; 
	
	vec4 albedo;
	vec4 samplenormal;		
	vec4 ambientlighting;		
	vec3 normal;
	float specular;
	float metalness;
	float gloss;
	float roughnessmip;
	float specular_power;	
	vec4 specular_colour;
		
	vec4 diffuse_out;	
    vec4 specular_out;	
	fragData0 = vec4(0.0);
	
	for (int i=0; i<SAMPLES; i++)
	{
		diffuse_out = 		vec4(0.0f);		
		specular_out = 		vec4(0.0f);
	
		depth = 			texelFetch(texture0,icoord,i).x;
		albedo = 			texelFetch(texture1,icoord,i);
		samplenormal =		texelFetch(texture2,icoord,i);			
		ambientlighting =	texelFetch(texture3,icoord,i);		
		normal = 			normalize(samplenormal.xyz*2.0-1.0);	
		specular =			0.04;		
		gloss =				ambientlighting.a;	
		
		materialflags = 	int(samplenormal.a * 255.0 + 0.5);
		
		bool[4] mBits;
		mBits[0] = bool(16 & materialflags);	
		mBits[1] = bool(32 & materialflags);	
		mBits[2] = bool(64 & materialflags);	
		mBits[3] = bool(128 & materialflags);				
		metalness = 1 - Bit4GrayToFloat(mBits);
			
		roughnessmip = 		7 - (gloss * gloss * 7);		
		specular_power = 	exp2(10 * gloss + 1); 
		
		diffuse_out = 		albedo;
		specular_colour = 	mix(albedo, vec4(specular), metalness) * PIlightcolor;
					
		screencoord = vec3(((gl_FragCoord.x/buffersize.x)-0.5) * 2.0 * (buffersize.x/buffersize.y),((-gl_FragCoord.y/buffersize.y)+0.5) * 2.0,depthToPosition(depth,camerarange));
		screencoord.x *= screencoord.z / camerazoom;
		screencoord.y *= -screencoord.z / camerazoom;
		screennormal = normalize(screencoord) * flipcoord;		
		screencoord *= flipcoord;
			
		if ((1 & materialflags)!=0) {
		
			lightvector = (screencoord - lightposition);
			lightdistance = length(lightvector);	
			lightnormal = normalize(lightvector);
			
			float n_dot_l = max(-dot(lightnormal, normal), 0.0);			
			attenuation = n_dot_l * (1 / lightdistance); // linear fall off, spot lights focus light 		
			attenuation *= min(1.0, lightrange.y-lightdistance); //not physically correct but needed for performance			
			
			//Spot cone attenuation
			float denom = lightconeanglescos.y-lightconeanglescos.x;			
			float anglecos = dot(lightnormal, lightdirection);
			
			if (denom>0.0)
			{					
				attenuation *= 1.0-clamp((lightconeanglescos.y-anglecos)/denom,0.0,1.0);
			}
			else
			{
	#if SAMPLES==1
				if (anglecos<lightconeanglescos.x) discard;
	#endif
			}
			
			if (isReflection == 0)
			{							
				vec3 half_vector = normalize( lightnormal + screennormal);	
				float h_dot_n = clamp(-dot(half_vector, normal), 0.0, 1.0);		
				float n_dot_v = clamp(-dot(normal, screennormal), 0.0, 1.0);
				float h_dot_l = dot(half_vector, screennormal);		
								
				float blinn_phong = clamp(pow(h_dot_n, specular_power),0.0, 1.0);        
				float normalise_term = (specular_power + 2.0f) / 8.0;  
				float specular_term = normalise_term * blinn_phong;       
					  
				float exponent = pow((1.0f - h_dot_l), 5.0f);		
				vec4 fresnel_term = specular_colour + ((1.0f - specular_colour) * exponent);	
								 
				float alpha = 1.0f / ( sqrt( QUARTPI * specular_power + HALFPI ) );
				float visibility_term = ( n_dot_l * ( 1.0f - alpha ) + alpha ) * (n_dot_v * ( 1.0f - alpha ) + alpha );
				visibility_term = 1.0f / visibility_term;	
				
				specular_out += specular_term * fresnel_term * visibility_term;	
				
			#ifdef USESHADOW
				
				//----------------------------------------------------------------------
				//Shadow lookup
				//----------------------------------------------------------------------
				vec3 shadowcoord = lightnormalmatrix * lightvector;
				shadowcoord.x /= -shadowcoord.z/0.5;
				shadowcoord.y /= shadowcoord.z/0.5;
				shadowcoord.x += 0.5;
				shadowcoord.y += 0.5;
				shadowcoord.z = positionToDepth(shadowcoord.z * lightshadowmapoffset.y - lightshadowmapoffset.x,lightrange);
				attenuation *= shadowLookup(texture5,shadowcoord,1.0/shadowmapsize);	
				#if SAMPLES==1
				if (attenuation<LOWERLIGHTTHRESHHOLD) discard;
				#endif	
			#endif
							
				// ALBEDO*lightcolor*METALNESS*distanceattenuation*PIRECIPROCAL; <-- physically correct
				// I am increasing the strength of lights by PI in order to have a wider range of intensity values		
				// Leadwerks limits the value to 0.0 -> 8.0 in the editor
				//----------------------------------------------------------------------
			}
			
			//vec4 diffuse_out = albedo*lightcolor*metalness; 
			//fragData0 += (diffuse_out + specular_out)*attenuation;
			vec4 diffuse_out = lightcolor*metalness;
			
			if (showType == 2 ) {
				fragData0 += (diffuse_out + specular_out)*attenuation;
			}		
			
			else if (showType == 3 ) {
				fragData0 += diffuse_out*attenuation;
			}	
			
			else if (showType == 4 ) {
				fragData0 += specular_out*attenuation;
			}				
			
			else if (showType == 0 ) {
				diffuse_out *= albedo; 
				fragData0 += (diffuse_out + specular_out)*attenuation;
			}	
			
			fragData0.a = albedo.a;				
		}
	}
	
	fragData0 /= float(SAMPLES);
}
