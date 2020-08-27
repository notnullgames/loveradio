local LoveAudioSinkMono = require 'LoveAudioSinkMono'
local radio = require('radio')

local top
local sink

function love.load()
  local src = radio.SignalSource('triangle', 440, 44100)
  sink = LoveAudioSinkMono()
  top = radio.CompositeBlock()
  top:connect(src, sink)
  top:start()
end

function love.update(dt)
  sink.update()
end

function love.quit()
  top:stop()
  sink:release()
end