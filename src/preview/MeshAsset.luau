local MeshAsset = {}
function MeshAsset.FromFile(path)
    assert(type(readfile) == 'function','LocalMesh requires executor readfile()')
    assert(type(getcustomasset) == 'function','LocalMesh requires executor getcustomasset()')
    local file = readfile(path)
    assert(file:sub(1,13) == 'version 2.00\n','Expected a Roblox FileMesh v2 file')
    local headerSize,vertexSize,_,count = string.unpack('<I2I1I1I4',file,14)
    assert(vertexSize == 36 or vertexSize == 40,'Unsupported mesh vertex size')
    assert(count > 0 and count <= 1000000,'Invalid vertex count')
    local start = 14+headerSize
    assert(#file >= start-1+count*vertexSize,'Truncated mesh')
    local minX,minY,minZ,maxX,maxY,maxZ = math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge
    for index = 0,count-1 do
        local x,y,z = string.unpack('<fff',file,start+index*vertexSize)
        minX = math.min(minX,x); minY = math.min(minY,y); minZ = math.min(minZ,z)
        maxX = math.max(maxX,x); maxY = math.max(maxY,y); maxZ = math.max(maxZ,z)
    end
    return {MeshId = getcustomasset(path),Size = Vector3.new(maxX-minX,maxY-minY,maxZ-minZ),
        MeshCenter = Vector3.new((maxX+minX)/2,(maxY+minY)/2,(maxZ+minZ)/2)}
end
return MeshAsset
