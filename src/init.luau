local Window = require(script.layout.Window)
local Preview = require(script.preview.Preview)
local MeshAsset = require(script.preview.MeshAsset)
local Janitor = require(script.core.Janitor)
local Library = {Version = '1.0.0'}
function Library.new(options) return Window.new(options) end
Library.CreateWindow = Library.new
function Library.LocalMesh(path) return MeshAsset.FromFile(path) end
function Library.NewScope() return Janitor.new() end
function Window:CreatePreview(options)
    if self.Preview then self.Preview:Destroy() end
    self.Preview = Preview.new(self,options)
    self:Fit()
    return self.Preview
end
return Library
