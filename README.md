# blackbox
A LÖVE library for recording and playing back LÖVE events.

## Usage
An example usage that will initialize blackbox when the project loads and after 30 seconds replay all love events it receives.

```lua
local blackbox = require("blackbox")

-- total time elapsed
local gt = 0

function love.load()
	-- your loading code here
	
	-- initialize blackbox
	blackbox.init(true)
	blackbox.startRecord()
end

function love.update(dt)
	-- update global time
	gt = gt + dt
	
	if gt >= 30 and blackbox.state ~= 'playback' then
		blackbox.stopRecord()
		blackbox.startPlayBack()
	end
	
	blackbox.update(dt)
end
```

# API
## blackbox.init(popLast*)
* **popLast** `bool` If true, it will remove the very last signal received before being told to stop recording. This prevents getting stuck in a loop if you have any of blackbox's controls bound to buttons.
Initializes blackbox with a start time. This creates a reference point in time to the beginning of a playback session. If this isn't done at a consistent point in time (like loading a menu) then recordings may not be accurate.

## blackbox.update(dt)
* **dt** `int` The time elapsed, provided by `love.update(dt)`.
Update the internal time step for playing back events. This is **only** necessary for playback, as events automatically capture the time they were received.

## blackbox.startRecord()
Wraps all the default love event handlers and begins recording all events to a buffer. This will do nothing unless blackbox is idle (not recording or playing back).

## blackbox.stopRecord()
Unwraps all the event handlers to their original state before the recording began. **If at any point the love event handlers were modified after the recording began then the game may not return to standard behavior.** This will do nothing unless blackbox is idle (not recording or playing back).

## blackbox.startPlayBack()
Begin playing back the contents of the event buffer using the instant this is invoked as the same instant startRecord was invoked relative to `blackbox.init()`. This will do nothing unless blackbox is idle (not recording or playing back). Requires `blackbox.update()` to be called in order to step through time.

## blackbox.stopPlayBack()
End playing back of the event buffer. Does not rewind the internal time or playlist location. This will only do something if blackbox is playing back.

# Notes
- If your code or any libraries you use rely on `love.keyboard.isDown()` then this will **not** produce accurate replays, as they do not respond to keypress events.
- Love doesn't provide a precise way of scheduling events, so desyncs can happen if your game doesn't use a fixed timestep.