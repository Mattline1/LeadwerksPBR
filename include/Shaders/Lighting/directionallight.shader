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
#define PIRECIPROCAL 0.3183098861837697
#define HALFPI PI/2.0
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

#if SAMPLES==0
	uniform sampler2D texture0;//depth
	uniform sampler2D texture1;//diffuse.rgba
	uniform sampler2D texture2;//normal.xyz, diffuse.a
	uniform sampler2D texture3;//specular, ao, flags, diffuse.a
	uniform sampler2D texture4;//emission.rgb, diffuse.a
#else
	uniform sampler2DMS texture0;//depth
	uniform sampler2DMS texture1;//diffuse.rgba
	uniform sampler2DMS texture2;//normal.xyz, diffuse.a
	uniform sampler2DMS texture3;//specular, ao, flags, diffuse.a
	uniform sampler2DMS texture4;//emission.rgb, diffuse.a
#endif

uniform sampler2DShadow texture5;//shadowmap

/* Possible future optimization:
uniform sampler2DMS texture0;//depth
uniform sampler2DMS texture1;//diffuse.rgba
uniform sampler2DMS texture2;//normal.xyz, specular
uniform sampler2DMS texture4;//emission.rgb, flags
*/

uniform mat3 cameranormalmatrix;
uniform mat3 camerainversenormalmatrix;
uniform vec2[4] shadowstagepositon;
uniform vec2 shadowstagescale;
uniform vec4 ambientlight;
uniform vec2 buffersize;
uniform vec3 lightdirection;
uniform vec4 lightcolor;
uniform vec4 lightspecular;
uniform vec2 camerarange;
uniform float camerazoom;
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

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
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

vec4 F_Schlick(vec4 f0, float fd90, float u ) 
{
	return f0 + ( fd90 - f0 ) * pow (1.0f - u , 5.0f);
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
	
	float depth;	
	vec3 normal;	
	vec4 stagecolor;
	vec3 screencoord;
	vec3 screennormal;
	float attenuation;		
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
	vec4 surfacedata;		
	float specular;
	float metalness;
	float gloss;
	float roughnessmip;
	float specular_power;	
	vec4 speccolor;
		
	vec4 sample_out;	
	fragData0 = vec4(0.0);

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
			specular 	= surfacedata.b;				
			gloss 		= 1 - surfacedata.r;
			metalness 	= 1 - surfacedata.g;				
			speccolor 	= mix(albedo, vec4(specular), metalness) * lightcolor;
			
			float alpha = max(0.001, gloss*gloss);	
			
			/////
			
			vec3 n 				= camerainversenormalmatrix * normalize(normaldata.xyz*2.0-1.0);	
			vec3 l 				= normalize(lightdirection);	
			vec3 h 				= normalize(l + screennormal);
			
			float n_dot_l 		= clamp(-dot(l, n), 0.0, 1.0);
			float n_dot_v 		= clamp(-dot(n, screennormal), 0.0, 1.0);
			float n_dot_h 		= clamp(-dot(n, h), 0.0, 1.0);
			float l_dot_h 		= clamp( dot(l, h), 0.0, 1.0);
			
			attenuation 		= n_dot_l;
					
		// Diffuse - BRDF
			vec4 Fd 			= Fd_DisneyDiffuse(lightcolor, n_dot_l, n_dot_v, l_dot_h, gloss);
				 Fd 			*= albedo * metalness;				
							
		//Specular - BRDF
			float D 			= D_GGX(alpha, n_dot_h);
			float V 			= V_SmithsGGX(alpha, n_dot_l, n_dot_v);
			vec4  F  			= F_Schlick(speccolor, 1.0f, l_dot_h);						
			vec4  Fr			= F * D * V;

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
					attenuation = attenuation * fade + attenuation * shadowLookup(texture5,shadowcoord,1.0/shadowmapsize) * (1.0-fade);
				}
			}
#endif		
		// Energy conservation, TODO look into a more physically correct method
			Fd 			= (lightcolor - Fr) * Fd; 			
			sample_out 	= (Fd + Fr) * attenuation;	
			
		}		
		fragData0 += vec4(sample_out.xyz, 1.0);	
	}
	
	fragData0 /= float(max(1,SAMPLES));
	fragData0 = max(fragData0,0.0);
	gl_FragDepth = depth;	
}
