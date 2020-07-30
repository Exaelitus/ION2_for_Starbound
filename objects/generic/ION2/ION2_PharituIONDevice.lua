
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0) license.
-- 
-- Please see the file "Copying.txt" include with this package for more details.



function init ( args )
	object.setInteractive( true )
	
	self.myPosition = entity.position()
	
	self.animationdelay = 0
	self.animationdelayDelay = 2
	
	self.containerRadius = 1
	self.containerID = 0
	
	self.receiverRadius = 100

	DetermineOwnedContainerID()
end


function uninit ()
end


function SafeContainerSize ( entityId )
	local sizeint = 0
	if ( world.containerSize( entityId ) ~= nil ) then
		sizeint = world.containerSize( entityId )
	end
	
	return sizeint
end


function DetermineOwnedContainerID ()
	if world.entityExists( self.containerID ) == false then
		self.containerID = 0
		world.loadRegion( { self.myPosition[1]-self.containerRadius, self.myPosition[2]-self.containerRadius, self.myPosition[1]+self.containerRadius, self.myPosition[2]+self.containerRadius } )
		local nearbyObjects = world.objectQuery( self.myPosition, self.containerRadius, {order = "nearest"} )
		for x=1, #nearbyObjects do
			if SafeContainerSize(nearbyObjects[x]) > 1 then
				self.containerID = nearbyObjects[x]
				break
			end
		end
	end
end


function onInteraction ( args )
	animator.setAnimationState( "static", "noderadius" )
	self.animationdelay = self.animationdelayDelay
	
	DetermineOwnedContainerID()
	
	if world.entityExists( self.containerID ) then
		OrganizePendingItems()
	end
end


function OrganizePendingItems ()
	local containeritems = world.containerItems( self.containerID )
	if #containeritems > 0 then
		IndicatorOn()

		world.loadRegion( { self.myPosition[1]-self.receiverRadius, self.myPosition[2]-self.receiverRadius, self.myPosition[1]+self.receiverRadius, self.myPosition[2]+self.receiverRadius } )
		local receiverContainers = world.objectQuery( self.myPosition, self.receiverRadius, {order = "nearest"} )
		
		if #receivernodes > 1 then
			local saystring = ""
			local saystringtemplate = "<name> -> <destChest>"

			-- transfer items
			for x, item in pairs(containeritems) do
				if item ~= nil then
					for r2, receiver2 in pairs(receiverContainers) do
						if ( receiver2 != self.containerID )
							if ( TransferPendingItemTo(receiver2, item) == true then
--								saystring = sb.replaceTags(saystringtemplate, {name = item.name, destChest = receiver2} )
--								object.say( saystring )
								break
							end
						end
					end
				end
			end

			
			-- log untransfered items
			saystringtemplate = "! ION2 ! - Cannot transfer item: <name> count=<count>"
			containeritems = world.containerItems( self.containerID )							
			for x2, item2 in pairs(containeritems) do
				if item2 ~= nil then
					saystring = sb.replaceTags(saystringtemplate, {name = item2.name, count = item2.count} )
					sb.logWarn( saystring )
				end
			end
		end
		
	end

		
	IndicatorOff()
end


function update ( dt )
	self.animationdelay = self.animationdelay - 1
	if self.animationdelay < 0 then
		self.animationdelay = 0
	end
	
	IndicatorOff()
end


function onNodeConnectionChange ( args )
end


function die ()
end


function IsION2SenderNode ()
	return true
end


function GetOwnedContainerID ()
	return self.containerID
end


function IndicatorOn ()
	self.animationdelay = self.animationdelayDelay
	animator.setAnimationState( "static", "sending" )
	
	local saystring = "Leeloo Minai Lekarariba-Laminai-Tchai Ekbat De Sebat Dallas"
	object.say( saystring )
end


function IndicatorOff ()
	if self.animationdelay == 0 then
		if world.entityExists( self.containerID ) then
			animator.setAnimationState( "static", "online" )
		else
			animator.setAnimationState( "static", "inert" )
		end
	
		local saystring = "Eto Akta Gamat"
		object.say( saystring )
	end
end


function TransferPendingItemTo ( entityId, sourceItemD )
	bool transferedEverything = false
		
	if SafeContainerSize(entityId) > 1 then
		local takenItem = sourceItemD
		local containeritems = world.containerItems( entityId )
		for x, item in pairs(containeritems) do
			if item ~= nil then
				if sourceItemD.matches(item) then

					-- sb.logInfo( "%s", sb.printJson(sourceItemD, 1) )
					sourceItemD = world.containerAddItems( entityId, sourceItemD )
					-- sb.logInfo( "%s", sb.printJson(sourceItemD, 1) )
					
					if ( sourceItemD ~= nil ) then
						takenItem.count = takenItem.count - sourceItemD.count
					end
					world.containerConsume( entityId, takenItem )

					if ( sourceItemD == nil ) then
						transferedEverything = true
						break
					end
				end
			end
		end

	end

	return transferedEverything
end
