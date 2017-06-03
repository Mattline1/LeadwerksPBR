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
#define HALFPI PI/2.0
#ifndef KERNEL
	#define KERNEL 3
#endif
#define KERNELF float(KERNEL)
#define GLOSS 10.0

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

uniform mat3 camerainversenormalmatrix;
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

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

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

vec4 F_Schlick(vec4 f0, float fd90, float u ) 
{
	return f0 + ( fd90 - f0 ) * pow (1.0f - u , 5.0f);
}

float V_SmithsGGX(float alpha, float n_dot_l, float n_dot_v)
{
	float k = alpha/2.f;
	float G_l = 1.0/(n_dot_l * (1.0f - k) + k);
	float G_v = 1.0/(n_dot_v * (1.0f - k) + k);
	
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
	vec3 screencoord;
	vec3 screennormal;
	float attenuation;
	float distanceattenuation;
	int materialflags;
			
	float specular;
	float metalness;
	float gloss;
			
	vec3 normal;			
	vec4 albedo;
	vec4 normaldata;
	vec4 samplenormal;		
	vec4 surfacedata;
	vec4 speccolor;
		
	float lightdistance;
	vec3 lightvector;
	vec3 lightnormal;
	vec4 lightPower = lightcolor*PI; 
		
	vec4 sample_out;	
	fragData0 = vec4(0.0);
	
	
	
	for (int i=0; i<max(1,SAMPLES); i++)
	{
	
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
		
		if ((1 & materialflags)!=0) // if use lighting
		{						
			specular 	= surfacedata.b;				
			gloss 		= 1 - surfacedata.r;
			metalness 	= 1 - surfacedata.g;				
			speccolor 	= mix(albedo, vec4(specular), metalness) * lightcolor;
			
			float alpha = max(0.001, gloss*gloss);	
			
			/////
			
			vec3  n 			= camerainversenormalmatrix * normalize(normaldata.xyz*2.0-1.0);	
			vec3  lv 			= (screencoord - lightposition);
			float ld 			= length(lv);			
			vec3  l 			= normalize(lv);	
			vec3  h 			= normalize(l + screennormal);
			
			float n_dot_l 		= clamp(-dot(l, n), 0.0, 1.0);
			float n_dot_v 		= clamp(-dot(n, screennormal), 0.0, 1.0);
			float n_dot_h 		= clamp(-dot(n, h), 0.0, 1.0);
			float l_dot_h 		= clamp( dot(l, h), 0.0, 1.0);
				
			attenuation 		= n_dot_l * (1 / (ld*ld));
			attenuation 		*= lightrange.y*0.1;
			attenuation 		*= min(1.0, lightrange.y-ld);
									
		//Specular - BRDF
			vec4  F  			= F_Schlick(speccolor, 1.0f, l_dot_h);
			float D 			= D_GGX(alpha, n_dot_h);
			float V 			= V_SmithsGGX(alpha, n_dot_l, n_dot_v);									
			vec4  Fr			= F * D * V * lightPower;
			
		// Diffuse - BRDF
			vec4 Kd 			= vec4(1.0) - F;
			vec4 Fd 			= Fd_DisneyDiffuse(lightPower, n_dot_l, n_dot_v, l_dot_h, gloss);
				 Fd 			*= Kd * albedo * metalness;	
			
#ifdef USESHADOW
	vec4 shadowcoord = vec4(lightnormalmatrix*lv,1.0);
	
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
	
	
			//Fd 			= (lightcolor - Fr) * Fd;
			fragData0 	+= ( Fd + Fr ) * attenuation;
		}	
	}	

	fragData0 /= max(1,SAMPLES);
	fragData0 = max(fragData0,0.0);
}
