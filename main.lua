local radio = require('radio')

local ffi = require('ffi')
local block = require('radio.core.block')
local vector = require('radio.core.vector')
local format_utils = require('radio.utilities.format_utils')
local types = require('radio.types')

ffi.cdef "int pipe(int fildes[2]);"

function LoveAudioSinkMono()
  local fds = ffi.new('int[2]')
  local source = love.audio.newQueueableSource(44100, 16, 1)
  local buffer = love.sound.newSoundData(1024, 44100, 16, 1)
  local pollfds = ffi.new("struct pollfd[1]")
  
  assert(ffi.C.pipe(fds) == 0)
  local realsink = radio.RealFileSink(fds[1], 's16le')
  
  function realsink:update()
    if source:getFreeBufferCount() == 0 then
      return
    end
    pollfds[0].fd = fds[0]
    pollfds[0].events = ffi.C.POLLIN
    local ret = ffi.C.poll(pollfds, 1, 0)
    assert(ret >= 0)
    if ret > 0 then
      local bytes_read = ffi.C.read(fds[0], buffer:getFFIPointer(), buffer:getSize())
      assert(bytes_read > 0)
      source:queue(buffer, tonumber(bytes_read))
      source:play()
    end
  end
  
  function realsink:release()
    ffi.C.close(fds[0])
    source:release()
  end
  
  return realsink
end

---

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
  top:wait()
end