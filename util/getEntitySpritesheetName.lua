local registry = require("registry")
local assets = require("assets")

local function getEntitySpritesheetName(entity)
	local entityAsset = assets.entityTypes[entity.typeName]
	if registry.entityTypes[entity.typeName].door then
		return entity.open and entityAsset.info.openSpritesheetName or entityAsset.info.closedSpritesheetName
	elseif registry.entityTypes[entity.typeName].bush then
		return entity.hasBerries and entityAsset.info.withSpritesheetName or entityAsset.info.withoutSpritesheetName
	end
	return entityAsset.info.defaultSpritesheetName
end

return getEntitySpritesheetName
