#pragma once

#include "Leadwerks.h"

namespace PBR 
{	
	extern std::list <Leadwerks::OpenGL4Camera*> cameras;
	extern bool realtimeReflections;
	extern bool init;

	extern Leadwerks::Camera* reflectionCamera;
	extern int reflectionResolution;
	extern int mipLevel;
	extern int show;

	extern Leadwerks::Buffer* cubeBuffer;
	extern Leadwerks::Texture* cubeTexture;	

	extern Leadwerks::Vec3 faceArray[6];
	extern Leadwerks::Context* currentContext;
	
	Leadwerks::Texture* GenerateReflection(Leadwerks::Vec3 location);

	bool initialise();
	bool close();
	void Render();

	void SetShaderUniforms(std::list <Leadwerks::OpenGL4Camera*> currentCameras, int isReflection);
	void SetCameraUniforms(Leadwerks::OpenGL4Camera* currentCamera, int isReflection);
	void SetReflectionTexture(Leadwerks::Material* mat, bool isReflection);
	void SetMaterialReflections(bool isReflection);
	void FillCameraList(std::list <Leadwerks::OpenGL4Camera*>* cameras);	
	void ShowCameras(bool showCameras);
}