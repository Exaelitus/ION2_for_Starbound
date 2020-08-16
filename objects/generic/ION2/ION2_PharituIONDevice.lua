
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0) license.
-- 
-- Please see the file "Copying.txt" include with this package for more details.



function init ( args )
	object.setInteractive( true )
	
	self.myPosition = entity.position()
	
	self.animationdelay = 0
	self.animationdelayDelay = 1	-- This is NOT in seconds/ticks/etc.  This is a counter for each script call (however long that is)
	
	self.powereddelay = 0
	self.powereddelayDelay = 2	-- TODO: This likely needs to be tweaked/configurable, as tje script should be called only every 3-4 secs
	self.inputnodeID = 0
	self.outputnodeID_a = 0
	self.outputnodeID_b = 1
	
	self.containerRadius = 1
	self.containerID = 0
	
	self.receiverRadius = 100

	DetermineOwnedContainerID()
	IndicatorOff()
end


function uninit ()
end


function SafeContainerSize ( entityId )
	local sizeint = 0
	if world.containerSize( entityId ) ~= nil then
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
	self.powereddelay = self.powereddelayDelay
	
	DeactivatePoweredOutputs()
	DetermineOwnedContainerID()
	
	if world.entityExists( self.containerID ) then
		OrganizePendingItems()
	end
end


function OrganizePendingItems ()
	local transferedSomething = false
	local containeritems = world.containerItems( self.containerID )
	if #containeritems > 0 then

		world.loadRegion( { self.myPosition[1]-self.receiverRadius, self.myPosition[2]-self.receiverRadius, self.myPosition[1]+self.receiverRadius, self.myPosition[2]+self.receiverRadius } )
		local receiverContainers = world.objectQuery( self.myPosition, self.receiverRadius )
		
		if #receiverContainers > 1 then
			
			IndicatorOn()

			-- transfer items
			local xferResult = {}
			for x, item in pairs(containeritems) do
				if item ~= nil then
					xferResult = item
					for r2, receiver2 in pairs(receiverContainers) do
						if receiver2 ~= nil and receiver2 ~= self.containerID then
							xferResult = TransferPendingItemTo( receiver2, xferResult )
							if xferResult == nil then
								NotifyPoweredOutputs()
								transferedSomething = true
								break
							end
						end
					end
				end
			end
		end
		
	end
	
	return transferedSomething
end


function update ( dt )
	if self.animationdelay ~= 0 then
		self.animationdelay = self.animationdelay - 1
		if self.animationdelay < 0 then
			self.animationdelay = 0
		end
	
		IndicatorOff()
	end
	
	if self.powereddelay > 0 then
		self.powereddelay = self.powereddelay - dt
		DeactivatePoweredOutputs()
	else
		if self.powereddelay == 0 then
			HandlePoweredConnections()
			self.powereddelay = self.powereddelayDelay
		else
			self.powereddelay = 0
			DeactivatePoweredOutputs()
		end
	end
end


function HandlePoweredConnections ()	-- TODO: is "self." valid syntax for "object." ?  If so, replace...
	if object.isInputNodeConnected(self.inputnodeID) then
		if object.getInputNodeLevel(self.inputnodeID) then	-- Docs say this returns a bool even though it's "Level"...
			DetermineOwnedContainerID()
			OrganizePendingItems()
		end
	end
end


function DeactivatePoweredOutputs ()
	if object.isOutputNodeConnected(self.outputnodeID_a) then
		object.setOutputNodeLevel(self.outputnodeID_a, false)
	end
	if object.isOutputNodeConnected(self.outputnodeID_b) then
		object.setOutputNodeLevel(self.outputnodeID_b, false)
	end
end


function NotifyPoweredOutputs ()
	if object.isOutputNodeConnected(self.outputnodeID_a) then
		object.setOutputNodeLevel(self.outputnodeID_a, true)
	end
	if object.isOutputNodeConnected(self.outputnodeID_b) then
		object.setOutputNodeLevel(self.outputnodeID_b, true)
	end
end


function onNodeConnectionChange ( args )
end


function die ()
	DeactivatePoweredOutputs()
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


function TransferItemsMatch ( itemLHS, itemRHS )
	local returnMatched = itemLHS.name == itemRHS.name

	if returnMatched and itemLHS.name == "sapling" then
		returnMatched = returnMatched and itemLHS.parameters.stemName == itemRHS.parameters.stemName
		returnMatched = returnMatched and itemLHS.parameters.foliageName == itemRHS.parameters.foliageName
		returnMatched = returnMatched and itemLHS.parameters.foliageHueShift == itemRHS.parameters.foliageHueShift
		returnMatched = returnMatched and itemLHS.parameters.stemHueShift == itemRHS.parameters.stemHueShift
	end

	
	-- TODO: FUTURE: figure out what IB was doing with these lines in that mod:
	-- if string.match(item2.name, "generated") then
	-- if root1.config.category == "platform" then root1.config.category = "block" end

	
	return returnMatched
end


function TransferPendingItemTo ( destContainerId, itemIn )
	local returnItem = itemIn
		
	if SafeContainerSize(destContainerId) > 1 then
		local takenItem = itemIn
		local itemsMatch = true
		local containeritems = world.containerItems( destContainerId )
		for x, itemR in pairs(containeritems) do
			if itemR ~= nil then
				itemsMatch = TransferItemsMatch( itemIn, itemR )
				if itemsMatch then
					sb.logInfo( "itemIn %s", sb.printJson(itemIn, 1) )
					sb.logInfo( "itemR %s", sb.printJson(itemR, 1) )
					returnItem = world.containerAddItems( destContainerId, returnItem )
					-- sb.logInfo( "returnItem %s", sb.printJson(returnItem, 1) )
					
					if returnItem ~= nil then
						takenItem.count = takenItem.count - returnItem.count
					end
					world.containerConsume( self.containerID, takenItem )
					
					if returnItem == nil then
						return nil
					end

				end
			end
		end

	end

	return returnItem
end
