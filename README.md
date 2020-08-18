# WIP

This is a love2d wrapper for [luaradio](https://github.com/vsergeev/luaradio).

Make sure [luaradio](https://github.com/vsergeev/luaradio) is installed, and you can use it in your love2d program to listen to audio.

See [main.lua](./main.lua) for example usage.

You can also use this to synthesize sounds, and do non-radio DSP stuff, if you like.

```lua
local radio = require('radio')
local loveradio = require('loveradio')

-- build a pipe that plays a triangle wave
local top = radio.CompositeBlock()
local src = radio.SignalSource('triangle', 0.1, 100e3)
local throttle = radio.ThrottleBlock()
top:connect(src, throttle)

local myradio = loveradio(top)
myradio:play()


function love:update()
  myradio:update()
end

function love:quit()
  myradio:close()
end
```