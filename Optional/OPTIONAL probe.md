
This shader replaces how reflections are rendered. These modifications change default leadwerks editor behaviour hence why they are optional



Disables Parralax correction:

Parallax correction maps the reflection to a box, this produces good results if the box volume matches the surrounding geometry, however it can cause quite ugly artifacts and weird reflection distortions when it does not.


Changes edge Blending:

The specular intensity slider no longer modifes the strength of the probes specular reflections, instead it modifies the falloff of the probe, with this you can create sharp boxy reflection areas or softer more spherical reflections. 




(To note; since this system is Physically based, modifying specular intensity would cause your materials to become physically implausible anyway :) )