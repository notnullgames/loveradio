-- run with luaradio simpletest.lua

local radio = require('radio')

radio.CompositeBlock():connect(
    radio.RtlSdrSource(90.7e6 - 250e3, 1102500), -- RTL-SDR source, offset-tuned to 88.5MHz-250kHz
    radio.TunerBlock(-250e3, 200e3, 5),          -- Translate -250 kHz, filter 200 kHz, decimate by 5
    radio.FrequencyDiscriminatorBlock(1.25),     -- Frequency demodulate with 1.25 modulation index
    radio.LowpassFilterBlock(128, 15e3),         -- Low-pass filter 15 kHz for L+R audio
    radio.FMDeemphasisFilterBlock(75e-6),        -- FM de-emphasis filter with 75 uS time constant
    radio.DownsamplerBlock(5),                   -- Downsample by 5
    radio.PulseAudioSink(1)                      -- Play to system audio with PulseAudio
):run()