local ffi = require('ffi')
local block = require('radio.core.block')
local types = require('radio.types')

local bufferSize = 1024
local pointer = 0

local LoveAudioSink = block.factory("LoveAudioSink")

function LoveAudioSink:instantiate(num_channels, samplingRate, bitDepth)
    self.num_channels = assert(num_channels, "Missing argument #1 (num_channels)")
    samplingRate = samplingRate or 44100
    bitDepth = bitDepth or 16

    if self.num_channels == 1 then
        self:add_type_signature({block.Input("in", types.Float32)}, {})
    else
        local block_inputs = {}
        for i = 1, self.num_channels do
            block_inputs[i] = block.Input("in" .. i, types.Float32)
        end
        self:add_type_signature(block_inputs, {})
    end

    self.sd = love.sound.newSoundData(bufferSize, samplingRate, bitDepth, num_channels)
    self.qs = love.audio.newQueueableSource(samplingRate, bitDepth, num_channels)
    
    -- use this like a buffer
    self.ptr = self.sd:getFFIPointer()
end

function LoveAudioSink:initialize()
end

function LoveAudioSink:process(x)
    if self.qs:getFreeBufferCount() == 0 then return end
    self.sd:setSample( pointer, x )
    
    pointer = pointer + 1
    if pointer >= self.sd:getSampleCount() then
      pointer = 0
      self.qs:queue(self.sd)
      self.qs:play()
    end
end

function LoveAudioSink:cleanup()
end

return {
  LoveAudioSink = LoveAudioSink
}
