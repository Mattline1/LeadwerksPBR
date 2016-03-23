SHADER version 1
@OpenGL2.Vertex
#version 400

uniform mat4 projectioncameramatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec3 lightglobalposition;
uniform vec2 lightrange;

in vec3 vertex_position;

void main(void)
{	
	gl_Position = projectioncameramatrix * vec4(lightglobalposition + vertex_position * lightrange.y * 2.0,1.0);
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

in vec3 vertex_position;

void main(void)
{	
	gl_Position = projectioncameramatrix * vec4(lightglobalposition + vertex_position * lightrange.y * 2.0,1.0);
}
@OpenGL4.Fragment
#version 400
#ifndef SAMPLES
	#define SAMPLES 1
#endif
#define LOWERLIGHTTHRESHHOLD 0.001
#define PI 3.14159265359
#define PIRECIPROCAL 0.31830988618
#define HALFPI PI/2.0
#define QUARTPI PI/4.0

#ifndef KERNEL
	#define KERNEL 3
#endif
#define KERNELF float(KERNEL)
#define GLOSS 10.0

uniform sampler2DMS texture0; 
uniform sampler2DMS texture1; // Albedo + alpha
uniform sampler2DMS texture2; // Normal + flags
uniform sampler2DMS texture3; // Spec, Metallic, Roughness,
uniform sampler2DMS texture4;
uniform samplerCubeShadow texture5;//shadowmap
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

uniform int isReflection;
uniform int showType;

out vec4 fragData0;

float shadowLookup(in samplerCubeShadow shadowmap, in vec4 shadowcoord, in vec3 sampleroffsetx, in vec3 sampleroffsety)
{
	
	float f=0.0;
	const float cornerdamping = 0.7071067;
	vec3 shadowcoord3 = shadowcoord.xyz;
	int x,y;
	vec2 sampleoffset;

	for (x=0; x<KERNEL; ++x)
	{
		sampleoffset.x = float(x) - KERNELF*0.5 + 0.5;
		for (y=0; y<KERNEL; ++y)
		{
			sampleoffset.y = float(y) - KERNELF*0.5 + 0.5;
			f += texture(shadowmap,vec4(shadowcoord3+sampleoffset.x*sampleroffsetx+sampleoffset.y*sampleroffsety,shadowcoord.w));
		}
	}
	return f/(KERNEL*KERNEL);
}

float depthToPosition(in float depth, in vec2 depthrange)
{
	return depthrange.x / (depthrange.y - depth * (depthrange.y - depthrange.x)) * depthrange.y;
}

float positionToDepth(in float z, in vec2 depthrange) {
	return (depthrange.x / (z / depthrange.y) - depthrange.y) / -(depthrange.y - depthrange.x);
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
		
	for (int i=0; i<SAMPLES; i++)
	{
		diffuse_out = 		vec4(0.0f);		
		specular_out = 		vec4(0.0f);	
	
		depth = 			texelFetch(texture0,icoord,i).x;
		albedo = 			texelFetch(texture1,icoord,i);
		samplenormal =		texelFetch(texture2,icoord,i);
		normal = 			normalize(samplenormal.xyz*2.0-1.0);	
		
		materialflags = 	int(samplenormal.a * 255.0 + 0.5);
					
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
			attenuation = n_dot_l * (1 / (lightdistance*lightdistance));
			attenuation *= min(1.0, lightrange.y-lightdistance); //not physically correct but needed for performance		
			
			if (isReflection == 0)
			{
			
				ambientlighting =	texelFetch(texture3,icoord,i);
				specular =			0.04;				
				gloss =				ambientlighting.a;	
				
				bool[4] mBits;
				mBits[0] = bool(16 & materialflags);	
				mBits[1] = bool(32 & materialflags);	
				mBits[2] = bool(64 & materialflags);	
				mBits[3] = bool(128 & materialflags);				
				metalness = 1 - Bit4GrayToFloat(mBits);
					
				roughnessmip = 		7 - (gloss * gloss * 7);		
				specular_power = 	exp2(10 * gloss + 1); 
			
				specular_colour = mix(albedo, vec4(specular), metalness) * PIlightcolor;
			
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
				vec4 shadowcoord = vec4(lightnormalmatrix*lightvector,1.0);
				
				vec3 sampleroffsetx,sampleroffsety;
				switch (getMajorAxis(shadowcoord.xyz))
				{
				case 0:
					shadowcoord.w = abs(shadowcoord.x);
					sampleroffsetx = vec3(0.0,0.0,shadowcoord.x*2.0/shadowmapsize);
					sampleroffsety = vec3(0.0,shadowcoord.x*2.0/shadowmapsize,0.0);
					break;
				case 1:
					shadowcoord.w = abs(shadowcoord.y);
					sampleroffsetx = vec3(shadowcoord.y*2.0/shadowmapsize,0.0,0.0);
					sampleroffsety = vec3(0.0,0.0,shadowcoord.y*2.0/shadowmapsize);
					break;
				default:
					shadowcoord.w = abs(shadowcoord.z);
					sampleroffsetx = vec3(shadowcoord.z*2.0/shadowmapsize,0.0,0.0);
					sampleroffsety = vec3(0.0,shadowcoord.z*2.0/shadowmapsize,0.0);
					break;
				}
				shadowcoord.w = positionToDepth(shadowcoord.w * lightshadowmapoffset.y*0.98 - lightshadowmapoffset.x,lightrange);
				attenuation *= shadowLookup(texture5,shadowcoord,sampleroffsetx,sampleroffsety);	
	#endif		
			}
			//diffuse_out = albedo*lightcolor*metalness; 
			//fragData0 += (diffuse_out + specular_out)*attenuation;	
			
			diffuse_out = lightcolor*metalness;
			
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

	fragData0 /= SAMPLES;
	//fragData0=vec4(1.0,0.0,0.0,1.0);
}
