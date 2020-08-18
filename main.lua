local radio = require('radio')
local loveradio = require('loveradio')

local snk
local top

function love.load()
  local src = radio.SignalSource('triangle', 440, 44100)
  local throttle = radio.ThrottleBlock()
  local snk = loveradio.LoveAudioSink(1, 44100)
  top = radio.CompositeBlock()
  top:connect(src, throttle, snk)
  top:start()
end

function love.quit()
  top:stop()
  top:wait()
  snk:close()
end