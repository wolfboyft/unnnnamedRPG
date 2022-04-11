local util = require("util")

local function updateEntities(world, player, dt, commandDone)
	for entity in world.entities:elements() do
		local entityType = entity.type
		entity.prev = setmetatable({}, getmetatable(entity.prev) or {__index = entity})
		entity.prev.drawX, entity.prev.drawY = entity.drawX, entity.drawY
		-- if we're moving, do movement
		if entity.moveProgress then
			entity.moveProgress = entity.moveProgress + dt / entityType.moveTime
			if entity.moveProgress >= 1 then
				entity.x, entity.y = util.translateByDirection(entity.x, entity.y, entity.moveDirection)
				entity.moveProgress = nil
				entity.moveDirection = nil
				entity.nextWalkCycleStartPos = (not entityType.alternateWalkCycleStartPos) and 0 or entity.nextWalkCycleStartPos == 0 and 0.5 or 0
			end
		end
		-- if we're not moving, see if we are to move
		if entity.moveProgress == nil then
			local up, down, left, right
			if entity == player then
				up = commandDone.up
				down = commandDone.down
				left = commandDone.left
				right = commandDone.right
				if up and down then
					up, down = false, false
				end
				if left and right then
					left, right = false, false
				end
				local vertical = up or down
				local horizontal = left or right
				if vertical and horizontal then
					if inputPriority == "vertical" then
						left, right = false, false
					else
						up, down = false, false
					end
				else
					inputPriority = vertical and "horizontal" or "vertical"
				end
			end
			if up then
				if entity.direction ~= "up" then
					entity.turnMovementDelayTimer = entity.type.turnMovementDelay
				end
				entity.direction = "up"
				if not entity.turnMovementDelayTimer then
					if not util.checkCollision(world, entity.x, entity.y - 1) then
						entity.moveDirection = "up"
					end
				end
			elseif down then
				if entity.direction ~= "down" then
					entity.turnMovementDelayTimer = entity.type.turnMovementDelay
				end
				entity.direction = "down"
				if not entity.turnMovementDelayTimer then
					if not util.checkCollision(world, entity.x, entity.y + 1) then
						entity.moveDirection = "down"
					end
				end
			elseif left then
				if entity.direction ~= "left" then
					entity.turnMovementDelayTimer = entity.type.turnMovementDelay
				end
				entity.direction = "left"
				if not entity.turnMovementDelayTimer then
					if not util.checkCollision(world, entity.x - 1, entity.y) then
						entity.moveDirection = "left"
					end
				end
			elseif right then
				if entity.direction ~= "right" then
					entity.turnMovementDelayTimer = entity.type.turnMovementDelay
				end
				entity.direction = "right"
				if not entity.turnMovementDelayTimer then
					if not util.checkCollision(world, entity.x + 1, entity.y) then
						entity.moveDirection = "right"
					end
				end
			end
			if entity.moveDirection then
				entity.moveProgress = 0
			end
		end
		-- timers
		if entity.turnMovementDelayTimer then
			entity.turnMovementDelayTimer = entity.turnMovementDelayTimer - dt
			if entity.turnMovementDelayTimer <= 0 then
				entity.turnMovementDelayTimer = nil
			end
		end
		-- do walk cycle
		if entity.moveProgress == nil then
			entity.walkCyclePos = nil
		else
			entity.walkCyclePos = entity.walkCyclePos or entity.nextWalkCycleStartPos
			entity.walkCyclePos = (entity.walkCyclePos + dt / entityType.walkCycleTime) % 1
		end
		-- try interaction
		if entity == player then
			if entity.moveProgress == nil and commandDone.interact then
				util.tryInteraction(entity)
			end
		end
		-- get draw pos
		entity.drawX, entity.drawY = util.translateByDirection(entity.x, entity.y, entity.moveDirection, entity.moveProgress)
	end
end

return updateEntities
