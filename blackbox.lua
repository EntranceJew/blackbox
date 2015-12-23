-- A love library for recording and playing back love events.
-- TODO: this doesn't count for beans on love.keyboard.isDown() 
local blackbox = {
	-- == GENERAL
	startTime = 0, -- the time we began at, set with init
	
	originalHandlers = {}, -- a copy of love.handlers
	
	state = 'idle', -- what we're doing
	-- valid: idle, playback, recording
	
	history = {}, -- the event history
	--{time=(int), name=(string), args=(...)}
	
	memory = {}, --the signals that are being sustained
	--{device={signal=(bool),...},...}
	
	-- == PLAYBACK
	nextTime = 0, -- the time to reach before pushing another event
	localStartTime = 0, -- tells us where we are relative to the beginning of a playback
	currentEvent = 0, -- the event we're currently emulating
	
	-- == RECORDING
	recordTime = 0, -- the time to queue events from
	popLast = false, -- if, when we're done recording, we pop the last action (if recording is triggered by a keypress, for example)
}

local function anonymousHandler(name, ...)
	blackbox.originalHandlers[name](unpack({...}))
end

function blackbox.init(popLast)
	blackbox.startTime = love.timer.getTime()
	blackbox.popLast = popLast
end

-- == GENERAL

function blackbox.update(dt)
	if blackbox.state == 'playback' then
		local now = love.timer.getTime() - blackbox.localStartTime
		if now >= blackbox.nextTime then
			local theEvent = blackbox.history[blackbox.currentEvent]
			--@DEBUG:
			--print("doing", theEvent.name, "with", unpack(theEvent.args), "at", now, "late by", blackbox.nextTime - now)
			love.event.push(theEvent.name, unpack(theEvent.args))
			blackbox.currentEvent = blackbox.currentEvent + 1
			local nextEvent = blackbox.history[blackbox.currentEvent]
			if not nextEvent then
				blackbox.stopPlayBack()
			else
				blackbox.nextTime = nextEvent.time
			end
		end
	end
end

-- == PLAYBACK
function blackbox.startPlayBack()
	if blackbox.state == 'idle' then
		blackbox.state = 'playback'
		blackbox.currentEvent = 1
		blackbox.localStartTime = love.timer.getTime()
		blackbox.nextTime = blackbox.history[1].time
		return true
	else
		return false
	end
end

function blackbox.stopPlayBack()
	if blackbox.state == 'playback' then
		blackbox.state = 'idle'
		return true
	else
		return false
	end
end

-- == RECORDING
function blackbox.startRecord()
	if blackbox.state == 'idle' then
		blackbox.state = 'recording'
		for name, func in pairs(love.handlers) do
			-- store the original function
			blackbox.originalHandlers[name] = func
			
			-- wrap it
			love.handlers[name] = function(...)
				local vargs = {...}
				local now = love.timer.getTime()
				if blackbox.state == 'recording' then
					table.insert(blackbox.history, {
						time=now - blackbox.startTime,
						name = name,
						args = vargs
					})
				end
				--@DEBUG
				--print("inside", name, "with", unpack(vargs), "at", now - blackbox.startTime)
				blackbox.originalHandlers[name](unpack(vargs))
			end
		end
		return true
	else
		return false
	end
end

function blackbox.stopRecord()
	if blackbox.state == 'recording' then
		blackbox.state = 'idle'
		for name, func in pairs(blackbox.originalHandlers) do
			-- unwrap it like it's christmas, baby
			love.handlers[name] = func
			blackbox.originalHandlers[name] = nil
		end
		if blackbox.popLast then
			table.remove(blackbox.history, #blackbox.history)
		end
		return true
	else
		return false
	end
end

return blackbox