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
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[gl_VertexID]+offset, 0.0, 1.0));
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
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[gl_VertexID]+offset, 0.0, 1.0));
}
@OpenGL4.Fragment
//This shader should not be attached directly to a camera. Instead, use the bloom script effect.
#version 400

//-------------------------------------
//MODIFIABLE UNIFORMS
//-------------------------------------
uniform float cutoff=0.25;//The lower this value, the more blurry the scene will be
uniform float overdrive=1.0;//The higher this value, the brighter the bloom effect will be
//-------------------------------------
//
//-------------------------------------

uniform sampler2D texture0;//Diffuse
uniform sampler2D texture1;//Bloom
uniform bool isbackbuffer;
uniform vec2 buffersize;
uniform float currenttime;

uniform float fstopmax;
uniform float fstopmin;

out vec4 fragData0;

// Filmic Tonemapping
// source: http://filmicgames.com/archives/75

const float gamma = 2.2;
const float A = 0.15;
const float B = 0.50;
const float C = 0.10;
const float D = 0.20;
const float E = 0.02;
const float F = 0.30;
const float W = 11.2;


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


vec3 Uncharted2Tonemap(vec3 x)
{
   return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

void main(void)
{
	vec2 texcoord = vec2(gl_FragCoord.xy/buffersize);
	if (isbackbuffer) texcoord.y = 1.0 - texcoord.y;
	
	vec4 scene = texture(texture0, texcoord);
	
	vec4 exposurecolor = texture(texture1,texcoord);
	float avgLuminance = exposurecolor.r + exposurecolor.g  + exposurecolor.b ;	
	avgLuminance *= 0.3333333333;
	//avgLuminance = min(1.0, avgLuminance*1.8);
	
	//float irisadjustment = 1.0 / (avgLuminance/0.25);
	//irisadjustment = clamp(irisadjustment,1.0,2.0);
	//scene *= irisadjustment;
	
	scene *= mix(fstopmax, fstopmin, avgLuminance);		
	float ExposureBias = 2.0;
	vec3 curr = Uncharted2Tonemap(ExposureBias*scene.rgb);
	
	vec3 whiteScale = 1.0/Uncharted2Tonemap(vec3(W));
	vec3 color = curr*whiteScale;
	
	
	//color = 	texture(texture0, texcoord).rgb;
	vec3 retColor = lin_to_srgb(vec4(color, 1.0), 2.2).rgb;
	
	
	// Gamma correction 
    //vec3 mapped = pow(retColor, vec3(1.0 / 2.2));  
    fragData0 = 	vec4(retColor, 1.0);
	//fragData0 = 	texture(texture0, texcoord);
	//if (texcoord.x < 0.2 && texcoord.y < 0.2)
	//{
		//fragData0 = exposurecolor;
	//}
}
