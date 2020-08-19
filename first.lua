local radio = require('radio')
local ffi = require('ffi')

ffi.cdef "int pipe(int fildes[2]);"

top = radio.CompositeBlock()
fds = ffi.new('int[2]')
source = love.audio.newQueueableSource(44100, 16, 1)
buffer = love.sound.newSoundData(1024, 44100, 16, 1)

function love.load()
	assert(ffi.C.pipe(fds) == 0)
	local src = radio.SignalSource('triangle', 440, 44100)
	local snk = radio.RealFileSink(fds[1], 's16le')
	top:connect(src, snk)
	top:start()
end

function love.update()
	if source:getFreeBufferCount() == 0 then
		return
	end
	local pollfds = ffi.new("struct pollfd[1]")
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

function love.quit()
	ffi.C.close(fds[0])
	top:stop()
	top:wait()
end