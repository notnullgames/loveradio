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
	sink = LoveAudioSinkMono()

	local frequency = 91.5e6
	local tune_offset = -250e3

	local top = radio.CompositeBlock()
	local source = radio.RtlSdrSource(frequency + tune_offset, 1102500)
	local tuner = radio.TunerBlock(tune_offset, 200e3, 5)
	local fm_demod = radio.FrequencyDiscriminatorBlock(1.25)
	local hilbert = radio.HilbertTransformBlock(129)
	local delay = radio.DelayBlock(129)
	local pilot_filter = radio.ComplexBandpassFilterBlock(129, {18e3, 20e3})
	local pilot_pll = radio.PLLBlock(100, 19e3-50, 19e3+50, 2)
	local mixer = radio.MultiplyConjugateBlock()
	local lpr_filter = radio.LowpassFilterBlock(128, 15e3)
	local lpr_am_demod = radio.ComplexToRealBlock()
	local lmr_filter = radio.LowpassFilterBlock(128, 15e3)
	local lmr_am_demod = radio.ComplexToRealBlock()
	local l_summer = radio.AddBlock()
	local l_af_deemphasis = radio.FMDeemphasisFilterBlock(75e-6)
	local l_downsampler = radio.DownsamplerBlock(5)
	
	top:connect(source, tuner, fm_demod, hilbert, delay)
	top:connect(hilbert, pilot_filter, pilot_pll)
	top:connect(delay, 'out', mixer, 'in1')
	top:connect(pilot_pll, 'out', mixer, 'in2')
	top:connect(delay, lpr_filter, lpr_am_demod)
	top:connect(mixer, lmr_filter, lmr_am_demod)
	top:connect(lpr_am_demod, 'out', l_summer, 'in1')
	top:connect(lmr_am_demod, 'out', l_summer, 'in2')
	top:connect(l_summer, l_af_deemphasis, l_downsampler)
	top:connect(r_downsampler, 'out', sink, 'in')

	top:start()
end

function love.update(dt)
	snk.update()
end

function love.quit()
	top:stop()
	snk:release()
	top:wait()
end