local json = require("lib.json")

local consts = require("consts")

local function serialise(world, player)
	-- backup and remove info that is serialised into other files
	do
		local entities = world.entities
		local tileInventories = world.tileInventories
		local backgroundTiles = world.backgroundTiles
		local foregroundTiles = world.foregroundTiles
		local tileTypesById = world.tileTypesById
		local warps = world.warps
		world.entities = nil
		world.tileInventories = nil
		world.backgroundTiles = nil
		world.foregroundTiles = nil
		world.tileTypesById = nil
		world.warps = nil
		-- serialise
		info = json.encode(world)
		-- restore
		world.entities = entities
		world.tileInventories = tileInventories
		world.backgroundTiles = backgroundTiles
		world.foregroundTiles = foregroundTiles
		world.tileTypesById = tileTypesById
		world.warps = warps
	end
	
	if player then player.player = true end -- temporary
	for entity in world.entities:elements() do
		if entity.inventory then
			local capacity = entity.inventory.capacity
			local equippedItemIndex
			if entity.inventory.equippedItem then
				for i, item in ipairs(entity.inventory) do
					if item == entity.inventory.equippedItem then
						equippedItemIndex = i
						break
					end
				end
				assert(equippedItemIndex, "Could not find equipped item in inventory")
			end
			local canEquip = entity.inventory.canEquip
			entity.inventory.capacity = nil -- temporary
			entity.inventory.equippedItem = nil
			entity.inventory.canEquip = nil
			entity.inventory = {
				capacity = capacity,
				equippedItemIndex = equippedItemIndex,
				canEquip = canEquip,
				items = entity.inventory
			}
		end
	end
	entities = json.encode(world.entities.objects)
	if player then player.player = nil end
	for entity in world.entities:elements() do
		if entity.inventory then
			local capacity = entity.inventory.capacity
			local equippedItem = entity.inventory.items[entity.inventory.equippedItemIndex]
			local canEquip = entity.inventory.canEquip
			entity.inventory = entity.inventory.items
			entity.inventory.capacity = capacity
			entity.inventory.equippedItem = equippedItem
			entity.inventory.canEquip = canEquip
		end
	end
	
	local tileInventoriesToSerialise = {}
	for x = 0, world.tileMapWidth - 1 do
		for y = 0, world.tileMapHeight - 1 do
			local tileInventory = world.tileInventories[x][y]
			if #tileInventory > 0 then
				tileInventoriesToSerialise[#tileInventoriesToSerialise+1] = {x = x, y = y, items = tileInventory}
				tileInventory.capacity = nil -- temporary
			end
		end
	end
	tileInventories = json.encode(tileInventoriesToSerialise)
	for _, tileInventoryEntry in ipairs(tileInventoriesToSerialise) do
		tileInventoryEntry.items.capacity = consts.tileInventoryCapacity
	end
	
	local tileIdsByType = {} -- for serialising tile data
	local tileIds = ""
	for i = 0, #world.tileTypesById do
		local tileType = world.tileTypesById[i]
		if tileType ~= "dummy" then
			tileIds = tileIds .. tileType.name .. "\n"
			tileIdsByType[world.tileTypesById[i].name] = i
		else
			tileIds = tileIds .. "dummy\n"
		end
	end
	
	-- TODO: Those are tile type names, not tile types
	backgroundTileDataTable = {}
	foregroundTileDataTable = {}
	for y = 0, world.tileMapHeight - 1 do
		for x = 0, world.tileMapWidth - 1 do
			backgroundTileDataTable[#backgroundTileDataTable+1] = string.char(tileIdsByType[world.backgroundTiles[x][y].name])
			foregroundTileDataTable[#foregroundTileDataTable+1] = string.char(tileIdsByType[world.foregroundTiles[x][y].name])
		end
	end
	backgroundTileData = table.concat(backgroundTileDataTable)
	foregroundTileData = table.concat(foregroundTileDataTable)
	
	warps = json.encode(world.warps)
	
	return info, entities, tileInventories, tileIds, backgroundTileData, foregroundTileData, warps
end

return serialise
