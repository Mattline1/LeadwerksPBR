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
#version 400

uniform sampler2D texture0;
uniform sampler2D texture1;
uniform bool isbackbuffer;
uniform vec2 buffersize;
uniform float currenttime;

uniform float ExposureBias;

out vec4 fragData0;

// abberation

const vec2 offset = vec2(0.000, 0.000);
//const vec2 offset = vec2(0.000, 0.000);

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

float flatten(vec4 tex){
	return tex.r*0.3 + tex.g*0.59 + tex.b*0.11;
}

void main(void) {
	vec2 texcoord = vec2(gl_FragCoord.xy/buffersize);
	if (isbackbuffer) texcoord.y = 1.0 - texcoord.y;
		
	vec4 scene = texture(texture0, texcoord);	
	vec4 exposurecolor = texture(texture1,texcoord);	
	
	scene /= flatten(exposurecolor);
	
	vec3 curr = Uncharted2Tonemap(ExposureBias*scene.rgb);	
	vec3 whiteScale = 1.0/Uncharted2Tonemap(vec3(W));
	vec3 color = curr*whiteScale;	
	
    fragData0 = vec4(lin_to_srgb(vec4(color, 1.0), 2.2).rgb, 1.0);	
}
