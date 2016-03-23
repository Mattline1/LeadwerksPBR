SHADER version 1
@OpenGL2.Vertex
#version 400

uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];

in vec3 vertex_position;

void main(void)
{
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[gl_VertexID], 0.0, 1.0));
}
@OpenGLES2.Vertex

@OpenGLES2.Fragment

@OpenGL4.Vertex
#version 400

uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];

in vec3 vertex_position;

void main(void)
{
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[gl_VertexID], 0.0, 1.0));
}
@OpenGL4.Fragment
#version 400
#define PI 3.14159265359
#define PIRECIPROCAL 0.31830988618
#define HALFPI PI/2.0
#define QUARTPI PI/4.0
#define LOWERLIGHTTHRESHHOLD 0.001
#ifndef SHADOWSTAGES
	#define SHADOWSTAGES 4
#endif
#ifndef SAMPLES
	#define SAMPLES 1
#endif
#ifndef KERNEL
	#define KERNEL 3
#endif
#define KERNELF float(KERNEL)
#define GLOSS 10.0

uniform sampler2DMS texture0; 
uniform sampler2DMS texture1; // Albedo + alpha
uniform sampler2DMS texture2; // Normal + flags
uniform sampler2DMS texture3; 
uniform sampler2DMS texture4;
uniform sampler2DShadow texture5; //shadowmap
uniform samplerCube texture14; // Reflection Map 

/* Possible future optimization:
uniform sampler2DMS texture0;//depth
uniform sampler2DMS texture1;//diffuse.rgba
uniform sampler2DMS texture2;//normal.xyz, specular
uniform sampler2DMS texture4;//emission.rgb, flags
*/

uniform vec2[4] shadowstagepositon;
uniform vec2 shadowstagescale;
uniform vec4 ambientlight;
uniform vec2 buffersize;
uniform vec3 lightdirection;
uniform vec4 lightcolor;
uniform vec4 lightspecular;

uniform vec2 camerarange;
uniform float camerazoom;
uniform mat3 cameranormalmatrix;

uniform vec2[SHADOWSTAGES] lightshadowmapoffset;
uniform mat4 lightmatrix;
uniform mat3 lightnormalmatrix0;
uniform mat3 lightnormalmatrix1;
uniform mat3 lightnormalmatrix2;
uniform mat3 lightnormalmatrix3;
uniform vec2 shadowmapsize;
uniform vec2 lightrange;
uniform vec3[SHADOWSTAGES] lightposition;
//uniform vec3 lightposition0;
//uniform vec3 lightposition1;
//uniform vec3 lightposition2;
//uniform vec3 lightposition3;
uniform float[SHADOWSTAGES] shadowstagearea;
uniform float[SHADOWSTAGES] shadowstagerange;
uniform bool isbackbuffer;

uniform float gamma = 2.2;
uniform int isReflection;
uniform int mipLevels;
uniform int showType;

out vec4 fragData0;

vec4 srgb_to_lin(vec4 val, float _gamma)
{
        float a = 0.055;
        vec3 n_val = (val.xyz + a) * (1.0 / (1 + a));
        return vec4(pow(n_val, vec3(_gamma)), val.a);
}   

vec4 lin_to_srgb(vec4 val, float _gamma)
{
        float a = 0.055;
        vec3 ret_val = (1 + a) * pow(val.xyz, vec3(1.0/ _gamma)) - a;
		return vec4(ret_val, val.a);
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

float depthToPosition(in float depth, in vec2 depthrange)
{
	return depthrange.x / (depthrange.y - depth * (depthrange.y - depthrange.x)) * depthrange.y;
}

float shadowLookup(in sampler2DShadow shadowmap, in vec3 shadowcoord, in vec2 offset)
{
	if (shadowcoord.y<0.0) return 0.5;
	if (shadowcoord.y>1.0) return 0.5;
	if (shadowcoord.x<0.0) return 0.5;
	if (shadowcoord.x>1.0) return 0.5;
	
	float f=0.0;
	int x,y;
	vec2 sampleoffset;

	for (x=0; x<KERNEL; ++x)
	{
		sampleoffset.x = float(x) - KERNELF*0.5 + 0.5;
		for (y=0; y<KERNEL; ++y)
		{
			sampleoffset.y = float(y) - KERNELF*0.5 + 0.5;
			f += texture(shadowmap,vec3(shadowcoord.x+sampleoffset.x*offset.x,shadowcoord.y+sampleoffset.y*offset.y,shadowcoord.z));
		}
	}
	return f/(KERNEL*KERNEL);
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
	mat3 lightnormalmatrix;
	vec2 sampleoffset;
	vec3 lp;
	vec4 normaldata;
	int materialflags;	
	
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
		
	vec4 diffuse_out;	
    vec4 specular_out;
	vec4 ambient_diffuse_out;
	vec4 ambient_specular_out;
	fragData0 = vec4(0.0);

	for (int i=0; i<SAMPLES; i++)
	{		
		diffuse_out = 			vec4(0.0f);		
		specular_out = 			vec4(0.0f);
		ambient_diffuse_out = 	vec4(0.0f);	
		ambient_specular_out = 	vec4(0.0f);	
	
		depth = 			texelFetch(texture0,icoord,i).x;
		albedo = 			texelFetch(texture1,icoord,i);
		samplenormal =		texelFetch(texture2,icoord,i);	
		ambientlight =		texelFetch(texture3,icoord,i);		
		
		materialflags = 	int(samplenormal.a * 255.0 + 0.5);	
		diffuse_out = albedo;
				
		screencoord = vec3(((gl_FragCoord.x/buffersize.x)-0.5) * 2.0 * (buffersize.x/buffersize.y),((-gl_FragCoord.y/buffersize.y)+0.5) * 2.0,depthToPosition(depth,camerarange));
		screencoord.x *= screencoord.z / camerazoom;
		screencoord.y *= -screencoord.z / camerazoom;		
		screennormal = normalize(screencoord) * flipcoord;		
		screencoord *= flipcoord;		
			
		if ((1 & materialflags)!=0) {			
			normal = normalize(samplenormal.xyz*2.0-1.0);
			
			if (isReflection==1) // is this a reflection rendering?
			{			
				diffuse_out = albedo*lightcolor*clamp(-dot(normalize(lightdirection), normal), 0.0, 1.0)*PIRECIPROCAL; 
				ambientlight = srgb_to_lin(ambientlight, gamma);
			}			
			else
			{					
				specular =			0.04;				
				gloss =				ambientlight.a;		
				
				bool[4] mBits;
				mBits[0] = bool(16 & materialflags);	
				mBits[1] = bool(32 & materialflags);	
				mBits[2] = bool(64 & materialflags);	
				mBits[3] = bool(128 & materialflags);				
				metalness = 1 - Bit4GrayToFloat(mBits);
				
				//normal * flipcoord;						
				specular_power  = exp2(10 * gloss + 1); //from remember me implementation
				specular_colour = mix(albedo, vec4(specular), metalness) * lightcolor;
							
				vec3 lightnormal = normalize(lightdirection);				
				float n_dot_l = clamp(-dot(lightnormal, normal), 0.0, 1.0);
				attenuation = n_dot_l;							
					
				vec3 half_vector = normalize( lightnormal + screennormal);				
				
				float h_dot_n = clamp(-dot(half_vector, normal), 0.0, 1.0);	
				float n_dot_v = clamp(-dot(normal, screennormal), 0.0, 1.0);
				float h_dot_l = dot(half_vector, screennormal);		
								
				float blinn_phong = pow(h_dot_n, specular_power);        
				float normalise_term = (specular_power + 2.0f) / 8.0;  
				float specular_term = normalise_term * blinn_phong;       
					  
				float exponent = pow((1.0f - h_dot_l), 5.0f);		
				vec4 fresnel_term = specular_colour + ((1.0f - specular_colour) * exponent);	
								 
				float alpha = 1.0f / ( sqrt( QUARTPI * specular_power + HALFPI ) );
				float visibility_term = ( n_dot_l * ( 1.0f - alpha ) + alpha ) * (n_dot_v * ( 1.0f - alpha ) + alpha );
				visibility_term = 1.0f / visibility_term;	
				
				specular_out += specular_term * fresnel_term * visibility_term;	
				
	#ifdef USESHADOW
				fade=1.0;
				if (attenuation>LOWERLIGHTTHRESHHOLD)
				{
					//----------------------------------------------------------------------
					//Shadow lookup
					//----------------------------------------------------------------------
					dist = clamp(length(screencoord)/shadowstagerange[0],0.0,1.0);
					offset = vec3(0.0);
					//vec3 lightposition;
					lightnormalmatrix = mat3(0);
					sampleoffset = shadowstagepositon[0];
					fade=1.0;
					lp = vec3(0);
					
					if (dist<1.0)
					{
						//offset.x = 0.0;
						offset.z = -lightshadowmapoffset[0].x;
						lp = lightposition[0];
						lightnormalmatrix = lightnormalmatrix0;
						fade=0.0;
						stagecolor=vec4(1.0,0.0,0.0,1.0);
					}
					else
					{
						//fade=0.0;
						dist = clamp(length(screencoord)/shadowstagerange[1],0.0,1.0);
						if (dist<1.0)
						{
							//offset.x = 1.0;
							offset.z = -lightshadowmapoffset[1].x;
							lp = lightposition[1];
							lightnormalmatrix = lightnormalmatrix1;
							fade=0.0;
							sampleoffset = shadowstagepositon[1];
							stagecolor=vec4(0.0,1.0,0.0,1.0);
		#if SHADOWSTAGES==2
							fade = clamp((dist-0.75)/0.25,0.0,1.0);// gradually fade out the last shadow stage
		#endif
						}
		#if SHADOWSTAGES>2
						else
						{	
							dist = clamp(length(screencoord)/shadowstagerange[2],0.0,1.0);
							if (dist<1.0)
							{
								//offset.x = 2.0;
								offset.z = -lightshadowmapoffset[2].x;
								lp = lightposition[2];
								lightnormalmatrix = lightnormalmatrix2;
								stagecolor=vec4(0.0,0.0,1.0,1.0);
								fade=0.0;
								sampleoffset = shadowstagepositon[2];
			#if SHADOWSTAGES==3
								fade = clamp((dist-0.75)/0.25,0.0,1.0);// gradually fade out the last shadow stage
			#endif
							}
			#if SHADOWSTAGES==4
							else
							{
								dist = clamp(length(screencoord)/shadowstagerange[3],0.0,1.0);
								if (dist<1.0)
								{
									stagecolor=vec4(0.0,1.0,1.0,1.0);
									//offset.x = 3.0;
									offset.z = -lightshadowmapoffset[3].x;
									lp = lightposition[3];
									lightnormalmatrix = lightnormalmatrix3;
									fade = clamp((dist-0.75)/0.25,0.0,1.0);// gradually fade out the last shadow stage
									sampleoffset = shadowstagepositon[3];
								}
								else
								{
									fade = 1.0;
								}
							}
			#endif
						}
		#endif
					}
					if (fade<1.0)
					{
						shadowcoord = lightnormalmatrix * (screencoord - lp);
						shadowcoord += offset;
						shadowcoord.z = (shadowcoord.z - lightrange.x) / (lightrange.y-lightrange.x);	
						shadowcoord.xy += 0.5;
						shadowcoord.xy *= shadowstagescale;
						shadowcoord.xy += sampleoffset;
						attenuation = attenuation*fade + attenuation*shadowLookup(texture5,shadowcoord,1.0/shadowmapsize) * (1.0-fade);
					}
				}
	#endif						
				diffuse_out = albedo*lightcolor*attenuation*metalness;
				specular_out *= attenuation;
			}
		}	
								
		if (showType == 1 ) {
			fragData0 += albedo;
		}				
		
		else if (showType == 2 ) {
			fragData0 += diffuse_out + specular_out;
		}		
		
		else if (showType == 3 ) {
			fragData0 += diffuse_out;
		}	
		
		else if (showType == 4 ) {
			fragData0 += specular_out;
		}	
		
		else if (showType == 5 ) {
			fragData0 += ambientlight;
		}
		
		else {
			fragData0 += diffuse_out + specular_out + ambientlight;
		}	
		
		fragData0.a = albedo.a;
	}	
	fragData0 /= float(SAMPLES);
	gl_FragDepth = depth;
}
