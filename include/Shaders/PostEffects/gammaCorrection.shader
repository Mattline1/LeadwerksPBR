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

uniform sampler2D texture1;

uniform bool isbackbuffer;
uniform vec2 buffersize;
uniform float gamma = 2.2;

out vec4 fragData0;

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


void main(void)
{
	vec2 icoord = vec2(gl_FragCoord.xy/buffersize);
	if (isbackbuffer) icoord.y = 1.0 - icoord.y;
	
	fragData0 = lin_to_srgb(texture(texture1,icoord), gamma);
	
	//fragData0 = vec4(srgbImage);
}
