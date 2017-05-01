SHADER version 1
@OpenGL2.Vertex
#version 400

uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec2 texcoords[4];

in vec3 vertex_position;
in vec2 vertex_texcoords0;

out vec2 vTexCoords0;

void main(void)
{
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[gl_VertexID], 0.0, 1.0));
	vTexCoords0 = texcoords[gl_VertexID];
}
@OpenGLES2.Vertex

@OpenGLES2.Fragment

@OpenGL4.Vertex
#version 400

uniform mat4 projectionmatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec2 texcoords[4];

in vec3 vertex_position;
in vec2 vertex_texcoords0;

out vec2 vTexCoords0;

void main(void)
{
	gl_Position = projectionmatrix * (drawmatrix * vec4(position[gl_VertexID], 0.0, 1.0));
	vTexCoords0 = texcoords[gl_VertexID];
}
@OpenGL4.Fragment
#version 400

uniform int samples;
uniform float seed;
uniform float threshold;

uniform sampler2D texture0;
uniform sampler2D texture1;

in vec2 vTexCoords0;

out vec4 fragData0;

float rand(vec2 co){
    return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

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

float lin_to_srgb(float val, float _gamma)
{
        float a = 0.055;
        return (1 + a) * pow(val, 1.0/_gamma) - a;
} 

float flatten(vec4 tex){
	return tex.r*0.3 + tex.g*0.59 + tex.b*0.11;
}

// this is a heavy shader! only run it on a small number of pixels
void main(void)
{
	float accumulate;
	for (int i = 0 ; i < samples; i++)
	{		
		float a = 1/(i*seed);
		float x = rand(vec2(a, 1-a));
		float y = rand(vec2(1-a, a));
		accumulate += flatten(texture( texture0, vec2(x,y)));			
	}
	accumulate /= samples;
	
	float previous = flatten(texture( texture1, vec2(0.5)));	
	
	float gamma = 2.2;	
	accumulate  = lin_to_srgb(accumulate, gamma);	
	
	float dif = accumulate - previous;
	
	if (abs(dif) > threshold){
		dif = sign(dif)*0.01;	
		fragData0 = previous + vec4(dif);	
	}else{
		fragData0 = vec4(previous);	
	}
}
