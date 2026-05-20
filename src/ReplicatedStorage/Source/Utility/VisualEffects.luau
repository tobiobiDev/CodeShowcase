local VisualEffects = {}

local activeVFX = {}

VisualEffects.vfxSetting = true

function VisualEffects.EmitVFX(effectTemplate: Attachment | BasePart, target: BasePart?)
	if not (effectTemplate and VisualEffects.vfxSetting) then
		return
	end

	local vfxClone = effectTemplate

	if target then
		vfxClone = effectTemplate:Clone()
		vfxClone.Parent = target
	end

	activeVFX[vfxClone] = true

	for _, effect in vfxClone:GetDescendants() do
		if effect:IsA("ParticleEmitter") then
			local count = effect:GetAttribute("EmitCount") or 10
			effect:Emit(count)
		end
	end

	task.delay(5, function()
		if activeVFX[vfxClone] then
			activeVFX[vfxClone] = nil
		end

		if vfxClone and vfxClone.Parent then
			vfxClone:Destroy()
		end
	end)
end

function VisualEffects.PlayVFX(target: BasePart)
	if not (target and VisualEffects.vfxSetting) then
		return
	end

	activeVFX[target] = true

	for _, effect in target:GetDescendants() do
		if effect:IsA("ParticleEmitter") then
			effect.Enabled = true
		end
	end
end

function VisualEffects.StopVFX(vfxInstance: BasePart)
	if not vfxInstance then
		return
	end

	activeVFX[vfxInstance] = nil

	for _, effect in vfxInstance:GetDescendants() do
		if effect:IsA("ParticleEmitter") then
			effect.Enabled = false
		end
	end
end

function VisualEffects.StopAllVFX()
	for vfxInstance, _ in pairs(activeVFX) do
		if vfxInstance and vfxInstance.Parent then
			for _, effect in vfxInstance:GetDescendants() do
				if effect:IsA("ParticleEmitter") then
					effect.Enabled = false
				end
			end

			task.delay(3, function()
				if vfxInstance and vfxInstance.Parent then
					vfxInstance:Destroy()
				end
			end)
		end
	end

	table.clear(activeVFX)
end

return VisualEffects
