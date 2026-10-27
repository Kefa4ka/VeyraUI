from pathlib import Path
import json, re

ROOT = Path(__file__).resolve().parent
SRC = ROOT / 'src'
modules={('' if p.name=='init.luau' and p.parent==SRC else p.relative_to(SRC).with_suffix('').as_posix()):p.read_text(encoding='utf-8-sig') for p in sorted(SRC.rglob('*.luau'))}
# Validate static ModuleScript dependencies before producing distributable files.
for path,source in modules.items():
    for ref in re.findall(r'require\((script(?:\.[A-Za-z_][A-Za-z_0-9]*)+)\)',source):
        target=path
        for segment in ref.split('.')[1:]:
            if segment=='Parent': target=target.rsplit('/',1)[0] if '/' in target else ''
            else: target=target+'/'+segment if target else segment
        assert target in modules, f'{path}: unresolved {ref} -> {target}'
head='''-- Generated from src/ by build.py. Edit source modules, then rebuild.
-- This bundle contains library code only. No network requests or game-specific actions.
local factories, nodes, cache, loading = {}, {}, {}, {}
local function node(path)
    if nodes[path] then return nodes[path] end
    local value = {Path = path}
    nodes[path] = value
    return setmetatable(value,{__index = function(_,key)
        if key == 'Parent' then return node(path:match('^(.*)/[^/]+$') or '') end
        return node(path == '' and key or path..'/'..key)
    end})
end
'''
body=[]
for name,source in modules.items():
    body.append('factories['+json.dumps(name)+'] = function(script, require)\n'+source+'\nend\n')
tail='''local nativeRequire = require
local function import(target)
    if type(target) ~= 'table' or not target.Path then return nativeRequire(target) end
    local path = target.Path
    if cache[path] ~= nil then return cache[path] end
    assert(not loading[path], 'Circular module dependency: '..path)
    local factory = assert(factories[path], 'Module not found: '..path)
    loading[path] = true
    local ok, result = pcall(factory, target, import)
    loading[path] = nil
    if not ok then error(result, 2) end
    assert(result ~= nil, 'Module returned nil: '..path)
    cache[path] = result
    return result
end
return import(node(''))
'''
(ROOT/'VeyraUI.luau').write_text(head+'\n'.join(body)+tail,encoding='utf-8')
print('Built VeyraUI.luau from', len(modules), 'modules')
