# LeadwerksPBR
A PBR system developed for the Leadwerks engine

(This was orginally created to support a dissertation, for marking purposes a release is included which includes a snapshot of the repository as it was prior to the hand-in date)


---- using PBR ---- 

Copy the shaders into your project, overwriting the current files.

to use PBR:

- Make sure Gamma correction is the first shader in the post process stack 
- Use the PBR specific shaders for materials, the material slots correspond to the following textures 
	diffuse = albedo
	normal = normal
	specular = roughness
	texture4 = metalness
	


THIS IS STILL A WIP, currently only directional lights are supported. more lights and a decent tutorial should be added soon.


---- DEMO ----

Download the folder and run PBR.exe 

---- Demo Troubleshooting ----

Requires an OpenGL 4.0 compliant video card 
Requires OpenAL 32 bit to be installed 

if you have problems running the executable, please submit an issue.

