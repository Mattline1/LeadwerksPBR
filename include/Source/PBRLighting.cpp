#include "PBRLighting.h"

/// these variables are stored globally, this is done so the end user doesn't need to create any objects
/// they can simply import the PBRLighting Header and call PBR::Render()

std::list <Leadwerks::OpenGL4Camera*> PBR::cameras;
bool PBR::realtimeReflections = false;
int	 PBR::reflectionResolution = 128;
int  PBR::mipLevel = 7;
int  PBR::show = 0;
bool PBR::init = false;

Leadwerks::Context* PBR::currentContext = nullptr;

Leadwerks::Camera*	PBR::reflectionCamera = nullptr;
Leadwerks::Buffer*	PBR::cubeBuffer = nullptr;
Leadwerks::Texture* PBR::cubeTexture = nullptr;

Leadwerks::Vec3		PBR::faceArray[6] =
{
	Leadwerks::Vec3(0.f, 90.f, 0.f),
	Leadwerks::Vec3(0.f, -90.f, 0.f),
	Leadwerks::Vec3(-90.f, 0.0, 0.f),
	Leadwerks::Vec3(90.f, 0.0, 0.f),
	Leadwerks::Vec3(0.f, 0.f, 0.f),
	Leadwerks::Vec3(0.f, 180.f, 0.f),
};

bool PBR::initialise()
{
	// enable seamless cube mapping
	glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);

	currentContext = Leadwerks::Context::GetCurrent();
	if (Leadwerks::World::GetCurrent() == nullptr) { return false; }

	// create the cubemap texture
	cubeTexture = Leadwerks::Texture::CubeMap(
		reflectionResolution,
		reflectionResolution,
		Leadwerks::Texture::RGBA,
		Leadwerks::Texture::Mipmaps
		);

	//create reflection camera
	reflectionCamera = Leadwerks::Camera::Create();
	reflectionCamera->SetFOV(90);
	reflectionCamera->SetMass(0);
	//reflectionCamera->SetPosition(0.0, 0.0, 0.0, true);
	reflectionCamera->ClearPostEffects();

	reflectionCamera->SetShadowMode(0);
	reflectionCamera->SetRange(0.1, 400);
	//if (!realtimeReflections) { reflectionCamera->SetRange(.1, 1); }
	reflectionCamera->Hide();

	//create cube buffer
	cubeBuffer = Leadwerks::Buffer::Create(reflectionResolution, reflectionResolution, 1, 1, 0);
	mipLevel = 7;

	// set up the texture to use mipmaps
	cubeTexture->BuildMipmaps();
	Leadwerks::OpenGL2Texture* gl2cubeTexture = dynamic_cast<Leadwerks::OpenGL2Texture*>(cubeTexture);
	glActiveTexture(gl2cubeTexture->GetGLTarget());
	glBindTexture(GL_TEXTURE_CUBE_MAP, gl2cubeTexture->gltexturehandle);
	glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);
	glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

	GenerateReflection(); //<-- generate first reflection texture
	GenerateReflection(); //<-- use initial texture to generate correct texture

						  // find all cameras in the scene and store them
	PBR::FillCameraList(&cameras);
	PBR::init = true;
	return true;
}

bool PBR::close()
{
	// clear any objects from global variables
	currentContext = nullptr;
	reflectionCamera->Release();
	cubeTexture->Release();
	cubeBuffer->Release();

	cameras.clear();
	// init set to false so next time render is called the PBR is re-initialised
	// this needs to happen on level changes
	PBR::init = false;
	return true;
}

void PBR::SetCameraUniforms(Leadwerks::OpenGL4Camera* currentCamera, int isReflection)
{
	// lighting shaders are stored in the currently active camera
	// this function sets the required uniforms for each shader
	// the 'isReflection' argument is use to lower quality during reflection renders.

	if (!currentCamera) { return; }
	int m = currentCamera->GetMultisampleMode();
	int l = Leadwerks::World::GetCurrent()->GetLightQuality();	

	for (int s = 0; s < 2; s++) // shadowmode
	{
		if (currentCamera->shader_point[m][s][l] == NULL) { continue; }
		currentCamera->shader_point[m][s][l]->SetInt("isReflection", isReflection);
		currentCamera->shader_point[m][s][l]->SetInt("showType", show);
		
		if (currentCamera->shader_spot[m][s][l] == NULL) { continue; }
		currentCamera->shader_spot[m][s][l]->SetInt("isReflection", isReflection);
		currentCamera->shader_spot[m][s][l]->SetInt("showType", show);
	}

	if (Leadwerks::World::GetCurrent()->directionallights.size() > 0) // directional shaders
	{
		for (int s = 0; s < 2; s++) // shadowmode
		{
			if (currentCamera->shader_directional[m][s][l] == NULL) { continue; }			
			currentCamera->shader_directional[m][s][l]->SetInt("isReflection", isReflection);	
			currentCamera->shader_directional[m][s][l]->SetInt("showType", show);
		}
	}
	else	// ambient shaders		
	{
		if (!currentCamera->shader_ambient[m]) { return; }
		currentCamera->shader_ambient[m]->SetInt("isReflection", isReflection);	
		currentCamera->shader_ambient[m]->SetInt("showType", show);
	}
}

void PBR::SetShaderUniforms(std::list <Leadwerks::OpenGL4Camera*> currentCameras, int isReflection)
{
	// calls the SetCameraUniforms() function in all appropriate cameras
	// usually this would only be 1 camera
	std::list <Leadwerks::OpenGL4Camera*>::iterator GL4Iter;
	for (GL4Iter = currentCameras.begin(); GL4Iter != currentCameras.end(); GL4Iter++)
	{
		Leadwerks::OpenGL4Camera* currentCamera = *GL4Iter;				
		PBR::SetCameraUniforms(currentCamera, isReflection);
	}
}

void PBR::SetReflectionTexture(Leadwerks::Material* mat, bool isReflection)
{
	// bind the reflection map texture to the supplied material shader
	if (!mat) { return; }
	mat->SetTexture(cubeTexture, 7);	
	mat->GetShader()->SetInt("mipLevels", cubeTexture->CountMipmaps());
	mat->GetShader()->SetInt("isReflection", isReflection);
}

void PBR::SetMaterialReflections(bool isReflection = 0)
{
	// iterate through the models in the scene and bind the reflection map texture to them
	// this only needs to happen once, later the texture they reference will be updated 
	// this will update the materials as well as they just store a reference not the texture itself

	std::list<Leadwerks::Model*> entities = Leadwerks::World::GetCurrent()->models;

	std::list <Leadwerks::Model*>::iterator modelIter;
	for (modelIter = entities.begin(); modelIter != entities.end(); modelIter++)
	{
		Leadwerks::Model* thisModel = *modelIter;
		for (int i = 0; i < thisModel->CountSurfaces(); i++)
		{
			PBR::SetReflectionTexture(thisModel->GetSurface(i)->GetMaterial(), isReflection);
		}		
	}
}

void PBR::FillCameraList(std::list <Leadwerks::OpenGL4Camera*>* cameras)
{
	std::list <Leadwerks::Camera*>::iterator camIter;

	// search through all cameras and store standard ones into a list
	for (camIter = Leadwerks::World::GetCurrent()->cameras.begin(); camIter != Leadwerks::World::GetCurrent()->cameras.end(); camIter++)
	{
		Leadwerks::Camera* currentCamera = *camIter;
		Leadwerks::OpenGL4Camera* castCamera = dynamic_cast<Leadwerks::OpenGL4Camera*>(currentCamera);

		if (castCamera != NULL)
		{
			std::list <Leadwerks::OpenGL4Camera*>::iterator gl4CamIter;
			bool exists = false;
			for (gl4CamIter = cameras->begin(); gl4CamIter != cameras->end(); gl4CamIter++)
			{
				if (*gl4CamIter == castCamera)
				{
					exists = true;
				}
			}
			if (!exists) { cameras->push_back(castCamera); }	
		}
	}
}

void PBR::ShowCameras(bool showCameras)
{
	std::list <Leadwerks::OpenGL4Camera*>::iterator gl4CamIter;	
	for (gl4CamIter = PBR::cameras.begin(); gl4CamIter != PBR::cameras.end(); gl4CamIter++)
	{
		Leadwerks::OpenGL4Camera* currentCamera = *gl4CamIter;
		if (showCameras) { currentCamera->Show(); }
		else { currentCamera->Hide(); }
	}

}

Leadwerks::Texture* PBR::GenerateReflection(Leadwerks::Vec3 camLocation = Leadwerks::Vec3(0.0, 0.0, 0.0))
{
	if (Leadwerks::World::GetCurrent() == nullptr)	{ return nullptr; }	

	PBR::SetMaterialReflections(1); //<-- is a reflection
	PBR::SetShaderUniforms(cameras, 0);

	// hide all non-reflection cameras
	PBR::ShowCameras(false);
	reflectionCamera->Show();
	reflectionCamera->SetPosition(camLocation, true);

	// lower quality of rendering to maintain framerate
	int lightquality = Leadwerks::World::GetCurrent()->GetLightQuality();
	Leadwerks::World::GetCurrent()->SetLightQuality(0);

	// render Cubemap faces	
	Leadwerks::OpenGL4Camera* currentCamera = dynamic_cast<Leadwerks::OpenGL4Camera*>(reflectionCamera);
	PBR::SetCameraUniforms(currentCamera, 1);
	cubeBuffer->Clear();

	//reflectionCamera->SetPosition(cameraPos, true);

	for (int face = 0; face < 6; face++) {
		reflectionCamera->SetRotation(faceArray[face], true);

		cubeBuffer->SetColorTexture(cubeTexture, 0, face, 0);
		cubeBuffer->Enable();

		reflectionCamera->Render();
		cubeBuffer->Disable();
	}

	// hide reflection camera and unhide others
	PBR::ShowCameras(true);
	reflectionCamera->Hide();

	// set quality settings back to pre-cubemap values
	Leadwerks::World::GetCurrent()->SetLightQuality(lightquality);
	Leadwerks::Context::SetCurrent(currentContext);

	// build mipmap levels for reflection
	cubeTexture = cubeBuffer->GetColorTexture();
	cubeTexture->BuildMipmaps();

	Leadwerks::OpenGL2Texture* gl2cubeTexture = dynamic_cast<Leadwerks::OpenGL2Texture*>(cubeTexture);
	glActiveTexture(gl2cubeTexture->GetGLTarget());	
	glBindTexture(GL_TEXTURE_CUBE_MAP, gl2cubeTexture->gltexturehandle);
	glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);
	glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

	PBR::SetMaterialReflections(0); //<--set new texture in material shaders	
	return cubeTexture;
}

void PBR::Render()
{	
	if (!PBR::init) { PBR::initialise(); }

	PBR::SetShaderUniforms(cameras, 0);
	Leadwerks::World::GetCurrent()->Render();	
}
