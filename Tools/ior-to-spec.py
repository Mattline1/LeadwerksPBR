ior = input("ior:")  

while (ior != ""):
	spec = pow((1.0-float(ior))/(1.0+float(ior)), 2)
	print( spec )
	ior = input("ior:") 
