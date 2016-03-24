# LeadwerksPBR
A PBR system developed for the Leadwerks engine

(This was orginally created to support a dissertation, for marking purposes a release is included which includes a snapshot of the repository as it was prior to the hand-in date)

Drop the contents of the include folder into your projects directory

include PBRLighting.h and PBRLighting.cpp

call PBR::Render() instead of world::Render()

use GenerateReflections() at any point to create a new reflection map
- GenerateReflections takes a position as an argument, this determines where the reflection map is generated
- Whilst it could be called every frame with the camera position to generate realtime reflections this will be very slow to render.

In order to correctly display color information make sure GammaCorrection is used in the post process settings.

-Examples
includes a level with some pre-built models and materials


---- DEMO ----

Download the folder and run PBR.exe 

---- Demo Troubleshooting ----

Requires an OpenGL 4.0 compliant video card 
Requires OpenAL 32 bit to be installed 

if you have problems running the executable, please submit an issue.

