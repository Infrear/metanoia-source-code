local Particle = {}
Particle.Emit = function(part: Part)
	for i,v in part:GetDescendants()do
		if v:IsA('ParticleEmitter') then
			task.delay(v:GetAttribute('EmitDelay')or 0.001,function()
				v:Emit(v:GetAttribute('EmitCount'))
			end)
		end
	end
end
Particle.EnableEmit =  function(part)
	task.spawn(function()
		for i,v in part:GetDescendants()do
			if v:IsA('ParticleEmitter') then
				if v:GetAttribute('EmitCount') then
					task.delay(v:GetAttribute('EmitDelay')or 0.001,function()
						v:Emit(v:GetAttribute('EmitCount'))
					end)
				end
				if v:GetAttribute('EmitDuration') then
					task.delay(v:GetAttribute('EmitDelay')or 0.001,function()
						v.Enabled = true
						task.wait(v:GetAttribute('EmitDuration'))
						v.Enabled = false
					end)
				end
			end
			if v:IsA('Trail') then
				if v:GetAttribute('EmitDuration') then
					task.delay(v:GetAttribute('EmitDelay')or 0.001,function()
						v.Enabled = true
						task.wait(v:GetAttribute('EmitDuration'))
						v.Enabled = false
					end)
				end
			end
		end
	end)
end

Particle.EmitTrail = function(v :Trail)
	if v:GetAttribute('EmitDuration') then
		task.delay(v:GetAttribute('EmitDelay')or 0.001,function()
			v.Enabled = true
			task.wait(v:GetAttribute('EmitDuration'))
			v.Enabled = false
		end)
	end
end

Particle.EnableEmitSingle =  function(v: Instance)
	task.spawn(function()
		if v:IsA('Trail') then
			if v:GetAttribute('EmitDuration') then
				task.delay(v:GetAttribute('EmitDelay')or 0.001,function()
					v.Enabled = true
					task.wait(v:GetAttribute('EmitDuration'))
					v.Enabled = false
				end)
			end
		end
		if v:IsA('ParticleEmitter') then
			if v:GetAttribute('EmitCount') then
				task.delay(v:GetAttribute('EmitDelay')or 0.001,function()
					v:Emit(v:GetAttribute('EmitCount'))
				end)
			end
			if v:GetAttribute('EmitDuration') then
				task.delay(v:GetAttribute('EmitDelay')or 0.001,function()
					v.Enabled = true
					task.wait(v:GetAttribute('EmitDuration'))
					v.Enabled = false
				end)
			end
		end
	end)
end

Particle.EnableEmitChildrenAndRepeatForAttachments =  function(part)
	task.spawn(function()
		for i,v in part:GetChildren()do
			Particle.EnableEmitSingle(v)
			if v:IsA('Attachment') then
				Particle.EnableEmitChildrenAndRepeatForAttachments(v)
			end
		end
	end)
end
return Particle
