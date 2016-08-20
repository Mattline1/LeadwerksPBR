# LeadwerksPBR
A PBR system developed for the Leadwerks engine

---- using PBR ---- 

Copy the shaders into your project, overwriting the current files.

to use PBR:

- Make sure Gamma correction is the first shader in the post process stack 
- Use the PBR specific shaders for materials, the material slots correspond to the following textures 
- 
	diffuse = albedo
	normal = normal
	specular = specular

	texture4 = metalness
	texture5 = roughness
	

---- DEMO ----

Download the folder and run PBR.exe 

---- Demo Troubleshooting ----

Requires an OpenGL 4.0 compliant video card 
Requires OpenAL 32 bit to be installed 

if you have problems running the executable, please submit an issue.

