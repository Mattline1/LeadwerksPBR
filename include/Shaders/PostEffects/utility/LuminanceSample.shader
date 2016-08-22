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

// this is a heavy shader! only run it on a small number of pixels
void main(void)
{
	vec4 accumulate;
	for (int i = 0 ; i < samples; i++)
	{
		//i += seed;
		float a = 1/(i*seed);
		float x = rand(vec2(a, 1-a));
		float y = rand(vec2(1-a, a));
		accumulate += texture( texture0, vec2(x,y) );
		
	}
				
	vec4 previous = texture( texture1, vec2(0.5) );
	accumulate /= samples;
	
	float gamma = 2.2;
	//previous 	= pow(previous, vec4(1.0 / gamma));
	accumulate  = lin_to_srgb(accumulate, gamma);	
	
	//fragData0 = accumulate;
	vec4 dif = accumulate - previous;
	dif = sign(dif)*0.003;
	
	fragData0 = previous + dif;
	//fragData0 = mix(previous, accumulate, 0.2);
	//fragData0 = vec4(0.5);
}
