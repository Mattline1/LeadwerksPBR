function Script:Start()
	
	self.shader_tonemap 	= Shader:Load("Shaders/PostEffects/Utility/Tonemap.shader")		
	self.shader_luminance 	= Shader:Load("Shaders/PostEffects/Utility/LuminanceSample.shader")	
	
	self.fstops = 2
		
end

function Script:Render(camera,context,buffer,depth,diffuse,normals,emission)
	local index,o,image,w,h
	
	--local image = diffuse -- lit scene
		
	if self.buffer == nil then
		self.buffer={}
		self.buffer[0]=Buffer:Create(1,1,1,0)
		self.buffer[0]:GetColorTexture():SetFilter(Texture.Smooth)		
		
	else	
		self.shader_luminance:SetInt("samples", 64)
		self.shader_luminance:SetFloat("seed", Time:GetSpeed())
		
		self.buffer[0]:Enable()		
		if self.shader_luminance then self.shader_luminance:Enable() end
		
		diffuse:Bind(0)
		self.buffer[0]:GetColorTexture():Bind(1)		
		context:DrawRect(0, 0, self.buffer[0]:GetWidth(), self.buffer[0]:GetHeight())
	end
	
	--Enable the shader and draw the diffuse image onscreen
	buffer:Enable()
	diffuse:Bind(0)
	self.buffer[0]:GetColorTexture():Bind(1)
	
	if self.shader_tonemap then self.shader_tonemap:Enable() end
	self.shader_tonemap:SetFloat("fstopmax", self.fstops*self.fstops)
	self.shader_tonemap:SetFloat("fstopmin", 1/self.fstops)
	
	context:DrawRect(0, 0, buffer:GetWidth(), buffer:GetHeight())
end

--Called when the effect is detached or the camera is deleted
function Script:Detach()
	local index,o
	
	--Release shaders
	if self.shader~=nil then
		self.shader:Release()
		self.shader = nil
	end
	
	--Release buffers
	if self.buffer~=nil then
		for index,o in pairs(self.buffer) do
			o:Release()
		end
		self.buffer = nil
	end
end