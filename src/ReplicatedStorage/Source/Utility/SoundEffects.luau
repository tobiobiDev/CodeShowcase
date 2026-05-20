--!strict
local SoundEffects = {}

SoundEffects.SFXSetting = 100
local originalVolumes: { [Sound]: number } = {}
local activeSounds: { [Sound]: boolean } = {}

function SoundEffects.PlaySound(sound: Sound, part: BasePart?, volume: number?)
	if not sound then
		return
	end

	local playSound = sound

	if part then
		playSound = sound:Clone()
		playSound.Parent = part

		playSound.Ended:Once(function()
			activeSounds[playSound] = nil
			playSound:Destroy()
		end)
	end

	activeSounds[playSound] = true


	if originalVolumes[playSound] == nil or volume then
		originalVolumes[playSound] = volume or playSound.Volume
	end

	local baseVolume = originalVolumes[playSound]
	playSound.Volume = baseVolume * SoundEffects.SFXSetting / 100

	playSound:Play()
end

function SoundEffects.StopSound(sound: Sound)
	if activeSounds[sound] then
		activeSounds[sound] = nil
	end

	sound:Stop()
end

function SoundEffects.UpdateAllVolumes()
	for sound in activeSounds do
		if sound and sound.Parent then
			local baseVolume = originalVolumes[sound] or sound.Volume
			sound.Volume = baseVolume * SoundEffects.SFXSetting / 100
		else
			activeSounds[sound] = nil
		end
	end
end

return SoundEffects
